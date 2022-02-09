// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Box {
    uint256 public x;
    bool private initialized;

    function initialize(uint256 _x) public {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        x = _x;
    }
}