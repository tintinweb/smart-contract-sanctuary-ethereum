/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Box {
    uint private value;

    constructor(uint initValue)  {
        value  = initValue;
    }

    function getValue() public view returns(uint) {
        return value;
    }

    function setValue(uint newValue) public {
        value = newValue;
    }
}