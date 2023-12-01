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

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ISwapRouter.ExactInputSingleParams memory params) external returns (uint256 amountOut);
}

contract FlashLoanLiquidate {
    ERC20 USDC = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    ERC20 UNI = ERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);
    IPool pool = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
    ISwapRouter swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
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

        (CErc20Delegator cUSDC, CErc20Delegator cUNI, address user, uint256 repayAmount) =
            abi.decode(params, (CErc20Delegator, CErc20Delegator, address, uint256));

        USDC.approve(address(cUSDC), type(uint256).max);
        cUSDC.liquidateBorrow(user, repayAmount, cUNI);
        cUNI.redeem(cUNI.balanceOf(address(this)));

        UNI.approve(address(swapRouter), type(uint256).max);
        ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(UNI),
            tokenOut: address(USDC),
            fee: 3000, // 0.3%
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: UNI.balanceOf(address(this)),
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        swapRouter.exactInputSingle(swapParams);

        uint256 amountOwed = amount + premium;
        ERC20(asset).approve(address(pool), amountOwed);

        return true;
    }

    function withdraw() external {
        require(msg.sender == owner);
        USDC.transfer(msg.sender, USDC.balanceOf(address(this)));
    }
}
