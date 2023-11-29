// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../script/HW1.s.sol";

contract HW2Test is Test, HW1Script {
    address user1 = makeAddr("User1");

    function setUp() public {
        super.run();
        deal(address(token), user1, 100 ether);
    }

    function testMintAndRedeem() public {
        vm.startPrank(user1);
        token.approve(address(cToken), type(uint256).max);
        cToken.mint(100 ether);
        assertEq(cToken.balanceOf(user1), 100 ether);
    }
}
