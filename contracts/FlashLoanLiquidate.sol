// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {CToken} from "./CToken.sol";
import {CErc20Delegator} from "./CErc20Delegator.sol";

interface IPool {
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;
}

contract FlashLoanLiquidate {
    ERC20 USDC = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IPool pool = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
    address owner;

    constructor() {
        owner = msg.sender;
    }

    function requestFlashLoan(address token, uint256 amount, bytes calldata params) public {
        pool.flashLoanSimple(address(this), token, amount, params, 0);
    }

    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata params)
        external
        returns (bool)
    {
        require(initiator == address(this), "FlashLoanLiquidate: invalid initiator");
        require(msg.sender == address(pool), "FlashLoanLiquidate: invalid sender");

        (CErc20Delegator cUSDC, CErc20Delegator cUNI, address user, uint256 shortfall) =
            abi.decode(params, (CErc20Delegator, CErc20Delegator, address, uint256));

        USDC.approve(address(pool), type(uint256).max);
        cUSDC.liquidateBorrow(user, shortfall / 2, cUNI);
        console2.log(cUNI.balanceOf(address(this)));

        uint256 amountOwed = amount + premium;
        ERC20(asset).approve(address(pool), amountOwed);

        return true;
    }

    function withdraw() external {
        require(msg.sender == owner);
        USDC.transfer(msg.sender, USDC.balanceOf(address(this)));
    }
}
