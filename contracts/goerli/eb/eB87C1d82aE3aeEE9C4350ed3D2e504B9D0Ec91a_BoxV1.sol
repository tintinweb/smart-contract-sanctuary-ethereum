// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.9;

contract BoxV1 {
    uint public val;

    function initialize(uint _val) external{
        val = _val;
    }

    function suma(uint _val) public {
        val = val + _val;
    }

    function resta(uint _val) public{
        val = val-_val;
    }
}