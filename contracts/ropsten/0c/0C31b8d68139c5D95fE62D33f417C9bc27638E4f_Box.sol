// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


contract Box {
    uint public val;
    
    function initialize(uint _val) external {
        val = _val;
    }
}