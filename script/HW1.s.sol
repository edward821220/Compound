// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {CErc20Delegator} from "../contracts/CErc20Delegator.sol";
import {CErc20Delegate} from "../contracts/CErc20Delegate.sol";
import {WhitePaperInterestRateModel} from "../contracts/WhitePaperInterestRateModel.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {BearToken} from "../contracts/BearToken.sol";
import {ComptrollerG7} from "../contracts/ComptrollerG7.sol";
import {SimplePriceOracle} from "../contracts/SimplePriceOracle.sol";
import {Unitroller} from "../contracts/Unitroller.sol";

contract HW1Script is Script {
    ERC20 token;
    ComptrollerG7 comptroller;
    CErc20Delegate impl;
    WhitePaperInterestRateModel model;
    Unitroller unitroller;
    SimplePriceOracle oracle;

    function run() public {
        vm.startBroadcast();

        token = new BearToken();
        impl = new CErc20Delegate();
        model = new WhitePaperInterestRateModel(0, 0);
        comptroller = new ComptrollerG7();
        unitroller = new Unitroller();

        comptroller._setPriceOracle(oracle);

        new CErc20Delegator(
            address(token),
            comptroller,
            model,
            1e18,
            "Compound Bear Token",
            "cBear",
            18,
            payable(0x9ecE381e4d7173f9C1971Bf7797b616639EE9B42),
            address(impl),
            new bytes(0)
        );

        vm.stopBroadcast();
    }
}
