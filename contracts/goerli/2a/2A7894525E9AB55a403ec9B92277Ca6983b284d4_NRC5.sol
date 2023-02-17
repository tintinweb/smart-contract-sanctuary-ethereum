// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./KBT721.sol";

contract NRC5 is KBT721 {
    constructor() KBT721("NTest 5", "NRC5") {}
}