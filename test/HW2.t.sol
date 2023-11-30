// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../script/HW1.s.sol";

contract HW2Test is Test, HW1Script {
    address admin = makeAddr("Admin");
    address user1 = makeAddr("User1");
    address user2 = makeAddr("User2");
    address user3 = makeAddr("User3");
    uint256 initialBalance = 100 ether;

    function setUp() public {
        vm.startPrank(admin);
        _deploy(admin);
        vm.stopPrank();
        deal(address(tokenA), user1, initialBalance);
        deal(address(tokenA), user2, initialBalance);
        deal(address(tokenA), user3, initialBalance);
        deal(address(tokenB), user1, initialBalance);
        deal(address(tokenB), user2, initialBalance);
        deal(address(tokenB), user3, initialBalance);
    }

    function testMintAndRedeem() public {
        vm.startPrank(user1);

        tokenA.approve(address(cTokenA), type(uint256).max);
        cTokenA.mint(100 ether);
        assertEq(tokenA.balanceOf(user1), initialBalance - 100 ether);
        assertEq(cTokenA.balanceOf(user1), 100 ether);

        cTokenA.redeem(100 ether);
        assertEq(tokenA.balanceOf(user1), initialBalance);
        assertEq(cTokenA.balanceOf(user1), 0);

        vm.stopPrank();
    }

    function testBorrowAndRepay() public {
        _borrow();

        vm.startPrank(user1);
        tokenA.approve(address(cTokenA), type(uint256).max);
        cTokenA.repayBorrow(50 ether);
        assertEq(tokenA.balanceOf(user1), initialBalance);
        vm.stopPrank();
    }

    function testBorrowAndLiquidate1() public {
        _borrow();

        // 降低 cTokenB 的 Collateral factor (50% => 20%)
        vm.prank(admin);
        comptroller._setCollateralFactor(CToken(address(cTokenB)), 2e17);

        // 用 User2 來清算 User1
        vm.startPrank(user2);
        tokenA.approve(address(cTokenA), type(uint256).max);

        // 先看 User1 欠了多少 tokenA
        (,, uint256 shortfall) = comptroller.getAccountLiquidity(user1);
        // 因為 Close Factor 設 100%，所以可以幫他全還
        cTokenA.liquidateBorrow(user1, shortfall, cTokenB);
        assertEq(tokenA.balanceOf(user2), initialBalance - shortfall);
        // 計算可以拿到多少獎勵
        (, uint256 seizeTokens) =
            comptroller.liquidateCalculateSeizeTokens(address(cTokenA), address(cTokenB), shortfall);
        // 最後拿到的清算獎勵要扣掉給協議的部份
        assertEq(cTokenB.balanceOf(user2), seizeTokens * (1e18 - cTokenA.protocolSeizeShareMantissa()) / 1e18);
        vm.stopPrank();
    }

    function testBorrowAndLiquidate2() public {
        _borrow();

        // 降低 cTokenB 的價格 (100USD => 10USD)
        vm.prank(admin);
        oracle.setUnderlyingPrice(CToken(address(cTokenB)), 1e19);

        // 用 User2 來清算 User1
        vm.startPrank(user2);
        tokenA.approve(address(cTokenA), type(uint256).max);

        // 先看 User1 欠了多少 tokenA
        (,, uint256 shortfall) = comptroller.getAccountLiquidity(user1);
        // 因為 Close Factor 設 100%，所以可以幫他全還
        cTokenA.liquidateBorrow(user1, shortfall, cTokenB);
        assertEq(tokenA.balanceOf(user2), initialBalance - shortfall);
        // 計算可以拿到多少獎勵
        (, uint256 seizeTokens) =
            comptroller.liquidateCalculateSeizeTokens(address(cTokenA), address(cTokenB), shortfall);
        // 最後拿到的清算獎勵要扣掉給協議的部份
        assertEq(cTokenB.balanceOf(user2), seizeTokens * (1e18 - cTokenA.protocolSeizeShareMantissa()) / 1e18);
        vm.stopPrank();
    }

    function _borrow() private {
        // 先用 User3 提供 tokenA 到池子裡讓 User1 有東西借
        vm.startPrank(user3);
        tokenA.approve(address(cTokenA), type(uint256).max);
        cTokenA.mint(100 ether);
        vm.stopPrank();

        // 再用 User1 抵押 tokenB 到池子裡借 tokenA
        vm.startPrank(user1);
        tokenB.approve(address(cTokenB), type(uint256).max);
        cTokenB.mint(1 ether);
        assertEq(cTokenB.balanceOf(user1), 1 ether);

        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cTokenB);
        comptroller.enterMarkets(cTokens);
        cTokenA.borrow(50 ether);
        assertEq(tokenA.balanceOf(user1), initialBalance + 50 ether);
        vm.stopPrank();
    }
}
