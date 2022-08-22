// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {BuxSwapVault} from "./BuxSwapVault.sol";

contract BuxSwap is BuxSwapVault {
    constructor(address claimer) BuxSwapVault(claimer) {}
}