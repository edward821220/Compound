// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../script/HW1.s.sol";

contract HW2Test is Test, HW1Script {
    address admin = makeAddr("Admin");
    address user1 = makeAddr("User1");
    address user2 = makeAddr("User2");
    uint256 initialBalance = 100 ether;

    function setUp() public {
        vm.startPrank(admin);
        _deploy(admin);
        vm.stopPrank();
        deal(address(tokenA), user1, initialBalance);
        deal(address(tokenA), user2, initialBalance);
        deal(address(tokenB), user1, initialBalance);
        deal(address(tokenB), user2, initialBalance);
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
        // 先用 User2 提供 tokenA 到池子裡讓 User1 有東西借
        vm.startPrank(user2);
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

        // 降低 cTokenB 的 Collateral factor (50% => 20%)
        vm.prank(admin);
        comptroller._setCollateralFactor(CToken(address(cTokenB)), 2e17);

        // 用 User2 來清算 User1
        vm.startPrank(user2);
        vm.stopPrank();
    }
}
