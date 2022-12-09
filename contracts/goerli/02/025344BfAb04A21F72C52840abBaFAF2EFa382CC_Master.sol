// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./Storage.sol";

contract Master is Storage {
    function setX(uint _x) external {
        x = _x;
    }
}