// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./KBT20.sol";

contract NRC5 is KBT20 {
    uint256 private _secureAccounts = 0;
    uint256 private _secureAmount = 0;

    constructor() KBT20("NTest 5", "NRC5") {}
}