// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {CToken} from "../contracts/CToken.sol";
import {CErc20Delegator} from "../contracts/CErc20Delegator.sol";
import {CErc20Delegate} from "../contracts/CErc20Delegate.sol";
import {WhitePaperInterestRateModel} from "../contracts/WhitePaperInterestRateModel.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ComptrollerG7} from "../contracts/ComptrollerG7.sol";
import {SimplePriceOracle} from "../contracts/SimplePriceOracle.sol";
import {Unitroller} from "../contracts/Unitroller.sol";

contract HW3Test is Test {
    // 使用 USDC 以及 UNI 代幣來作為 token A 以及 Token B
    ERC20 USDC = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    ERC20 UNI = ERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);
    ComptrollerG7 comptroller;
    CErc20Delegator cUSDC;
    CErc20Delegator cUNI;
    CErc20Delegate impl;
    WhitePaperInterestRateModel model;
    Unitroller unitroller;
    SimplePriceOracle oracle;

    address admin = makeAddr("Admin");
    address user1 = makeAddr("User1");
    address user2 = makeAddr("User2");
    address user3 = makeAddr("User3");
    uint256 initialUSDC = 5000 * 1e6;
    uint256 initialUNI = 5000 * 1e18;

    function setUp() public {
        // Fork Ethereum mainnet at block 17465000
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), 17465000);

        vm.startPrank(admin);
        impl = new CErc20Delegate();
        model = new WhitePaperInterestRateModel(0, 0);
        comptroller = new ComptrollerG7();
        unitroller = new Unitroller();
        oracle = new SimplePriceOracle();
        // cERC20 的 decimals 皆為 18，初始 exchangeRate 為 1:1
        cUSDC = new CErc20Delegator(
            address(USDC),
            comptroller,
            model,
            1e6,
            "Compound USDC",
            "cUSDC",
            18,
            payable(admin),
            address(impl),
            new bytes(0)
        );
        cUNI = new CErc20Delegator(
            address(UNI),
            comptroller,
            model,
            1e18,
            "Compound UNI",
            "cUNI",
            18,
            payable(admin),
            address(impl),
            new bytes(0)
        );
        comptroller._supportMarket(CToken(address(cUSDC)));
        comptroller._supportMarket(CToken(address(cUNI)));
        // Close factor 設定為 50%
        comptroller._setCloseFactor(5e17);
        // Liquidation incentive 設為 8%
        comptroller._setLiquidationIncentive(1.08 * 1e18);
        // 在 Oracle 中設定 USDC 的價格為 $1，UNI 的價格為 $5
        comptroller._setPriceOracle(oracle);
        oracle.setUnderlyingPrice(CToken(address(cUSDC)), 1e30);
        oracle.setUnderlyingPrice(CToken(address(cUNI)), 5e18);
        // 設定 UNI 的 collateral factor 為 50%
        comptroller._setCollateralFactor(CToken(address(cUNI)), 5e17);
        comptroller._supportMarket(CToken(address(cUSDC)));
        comptroller._supportMarket(CToken(address(cUNI)));
        vm.stopPrank();

        deal(address(USDC), user1, initialUSDC);
        deal(address(USDC), user3, initialUSDC);
        deal(address(UNI), user1, initialUNI);
        deal(address(UNI), user3, initialUNI);
    }

    function testHW3() public {
        // User3 先提供流動性讓 User1 有東東可以借
        vm.startPrank(user3);
        USDC.approve(address(cUSDC), initialUSDC);
        cUSDC.mint(initialUSDC);
        vm.stopPrank();

        // * User1 使用 1000 顆 UNI 作為抵押品借出 2500 顆 USDC
        vm.startPrank(user1);
        UNI.approve(address(cUNI), initialUNI);
        cUNI.mint(1000 * 1e18);
        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cUNI);
        comptroller.enterMarkets(cTokens);
        cUSDC.borrow(2500 * 1e6);
        assertEq(USDC.balanceOf(user1), initialUSDC + 2500 * 1e6);
        vm.stopPrank();

        // * 將 UNI 價格改為 $4 使 User1 產生 Shortfall，並讓 User2 透過 AAVE 的 Flash loan 來借錢清算 User1
        oracle.setUnderlyingPrice(CToken(address(cUNI)), 4e18);
        (,, uint256 shortfall) = comptroller.getAccountLiquidity(user1);
        console2.log(shortfall);

        vm.startPrank(user2);
        USDC.approve(address(cUSDC), type(uint256).max);

        cUSDC.liquidateBorrow(user1, shortfall / 2, cUNI);
        vm.stopPrank();

        // * 可以自行檢查清算 50% 後是不是大約可以賺 63 USDC
        console2.log(USDC.balanceOf(user2));
    }
}
