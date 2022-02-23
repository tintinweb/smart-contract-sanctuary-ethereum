//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

contract Box {

    // state variables inside upgradeable contract are never
    // used 

    uint public val;

    // only called on first contract init 
    function initialize(uint _val) external {
        val = _val;
    } 


}