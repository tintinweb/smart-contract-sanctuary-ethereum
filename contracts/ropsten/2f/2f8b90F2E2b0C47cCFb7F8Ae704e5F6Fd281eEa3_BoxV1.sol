// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract BoxV1{
    uint public val;

    function initialize(uint _val) public{
        val = _val;
    }
}