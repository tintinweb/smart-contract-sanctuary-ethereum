// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./RequestInfo.sol";
import "./Treatment.sol";

contract Main is Treatment, RequestInfo {
    address owner;

    constructor() {
        owner = msg.sender;
    }
}