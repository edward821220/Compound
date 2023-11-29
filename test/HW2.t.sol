// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../script/HW1.s.sol";

contract HW2Test is Test, HW1Script {
    address admin = makeAddr("Admin");
    address user1 = makeAddr("User1");

    function setUp() public {
        vm.startPrank(admin);
        _deploy(admin);
        vm.stopPrank();
        deal(address(tokenA), user1, 100 ether);
    }

    function testMintAndRedeem() public {
        vm.startPrank(user1);

        tokenA.approve(address(cTokenA), type(uint256).max);
        cTokenA.mint(100 ether);
        assertEq(tokenA.balanceOf(user1), 0);
        assertEq(cTokenA.balanceOf(user1), 100 ether);

        cTokenA.redeem(100 ether);
        assertEq(tokenA.balanceOf(user1), 100 ether);
        assertEq(cTokenA.balanceOf(user1), 0);

        vm.stopPrank();
    }

    function testBorrowAndRepay() public {
        vm.startPrank(user1);

        tokenA.approve(address(cTokenA), type(uint256).max);
        cTokenA.mint(100 ether);

        vm.stopPrank();
    }
}
