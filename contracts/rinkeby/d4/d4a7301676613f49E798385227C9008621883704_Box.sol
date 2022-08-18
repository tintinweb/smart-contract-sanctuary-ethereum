// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Box {
    uint public qval;

    function initialize(uint _val) external {
        qval = _val;
    }
}