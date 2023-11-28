// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import "../contracts/CErc20Delegator.sol";
import "../contracts/CErc20Delegate.sol";
import {WhitePaperInterestRateModel} from "../contracts/WhitePaperInterestRateModel.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {BearToken} from "../contracts/BearToken.sol";

contract HW1Script is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        ERC20 token = new BearToken();
        CErc20Delegate impl = new CErc20Delegate();
        WhitePaperInterestRateModel model = new WhitePaperInterestRateModel(0, 0);
        // new CErc20Delegator(address(token),,address(model),1,'Compound Bear Token','cBear',18,0x9ecE381e4d7173f9C1971Bf7797b616639EE9B42,address(impl),new bytes(0));
        vm.stopBroadcast();
    }
}
