//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Box {
    uint public val;

    // no constructors for upgradable contracts
    // constructor(uint _val) external {
    //     val = _val;
    // }
    

    function initialize(uint _val) external {
        val = _val;
    }
}