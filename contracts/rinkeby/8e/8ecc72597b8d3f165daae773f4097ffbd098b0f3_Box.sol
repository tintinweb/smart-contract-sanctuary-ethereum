/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Box {
    uint public val;

    function initialize(uint _val)
    external 
    {
        val=_val;
    }
    function updateVal(uint _newVal)
    external
    {
        val=_newVal;
    }
}