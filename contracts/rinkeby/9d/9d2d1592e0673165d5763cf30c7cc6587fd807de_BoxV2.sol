/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BoxV2 {
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
    function inc()
    external
    {
        val +=1;   
    }
}