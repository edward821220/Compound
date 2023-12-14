// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {CToken} from "../contracts/CToken.sol";
import {CErc20Delegator} from "../contracts/CErc20Delegator.sol";
import {CErc20Delegate} from "../contracts/CErc20Delegate.sol";
import {WhitePaperInterestRateModel} from "../contracts/WhitePaperInterestRateModel.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {BearTokenA, BearTokenB} from "../contracts/BearToken.sol";
import {ComptrollerG7} from "../contracts/ComptrollerG7.sol";
import {SimplePriceOracle} from "../contracts/SimplePriceOracle.sol";
import {Unitroller} from "../contracts/Unitroller.sol";

contract HW1Script is Script {
    ERC20 tokenA;
    ERC20 tokenB;
    ComptrollerG7 comptroller;
    CErc20Delegator cTokenA;
    CErc20Delegator cTokenB;
    CErc20Delegate impl;
    WhitePaperInterestRateModel model;
    Unitroller unitroller;
    SimplePriceOracle oracle;

    function run() public {
        vm.startBroadcast();
        _deploy(0x9ecE381e4d7173f9C1971Bf7797b616639EE9B42);
        vm.stopBroadcast();
    }

    function _deploy(address defaultSender) internal {
        tokenA = new BearTokenA();
        tokenB = new BearTokenB();
        impl = new CErc20Delegate();
        model = new WhitePaperInterestRateModel(0, 0);
        comptroller = new ComptrollerG7();
        unitroller = new Unitroller();
        oracle = new SimplePriceOracle();

        unitroller._setPendingImplementation(address(comptroller));

        comptroller._become(unitroller);

        ComptrollerG7 comptrollerProxy = ComptrollerG7(address(unitroller));

        cTokenA = new CErc20Delegator(
            address(tokenA),
            comptrollerProxy,
            model,
            1e18,
            "Compound Bear TokenA",
            "cBearA",
            18,
            payable(defaultSender),
            address(impl),
            new bytes(0)
        );

        cTokenB = new CErc20Delegator(
            address(tokenB),
            comptrollerProxy,
            model,
            1e18,
            "Compound Bear TokenB",
            "cBearB",
            18,
            payable(defaultSender),
            address(impl),
            new bytes(0)
        );

        comptrollerProxy._supportMarket(CToken(address(cTokenA)));
        comptrollerProxy._supportMarket(CToken(address(cTokenB)));

        // Compound V2 文件上面寫：The price of the asset in USD as an unsigned integer scaled up by 10 ^ (36 - underlying asset decimals). E.g. WBTC has 8 decimal places, so the return value is scaled up by 1e28.
        comptrollerProxy._setPriceOracle(oracle);
        // 設定 cTokenA 為 1 USD
        oracle.setUnderlyingPrice(CToken(address(cTokenA)), 1e18);
        // 設定 cTokenB 為 100 USD
        oracle.setUnderlyingPrice(CToken(address(cTokenB)), 1e20);

        comptrollerProxy._setCollateralFactor(CToken(address(cTokenB)), 5e17);
        comptrollerProxy._setCloseFactor(5e17);
        comptrollerProxy._setLiquidationIncentive(1.08 * 1e18);
    }
}
