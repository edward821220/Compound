// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BearTokenA is ERC20 {
    constructor() ERC20("Bear TokenA", "BearA") {}
}

contract BearTokenB is ERC20 {
    constructor() ERC20("Bear TokenB", "BearB") {}
}
