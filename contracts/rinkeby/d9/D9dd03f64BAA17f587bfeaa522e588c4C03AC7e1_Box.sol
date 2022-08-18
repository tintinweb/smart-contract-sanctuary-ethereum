// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Box {
    uint public cval;

    function initialize(uint _val) external {
        cval = _val + 0;
    }
}