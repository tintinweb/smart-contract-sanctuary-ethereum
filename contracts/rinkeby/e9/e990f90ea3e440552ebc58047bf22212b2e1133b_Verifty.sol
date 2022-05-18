/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Verifty{
    uint256 private value;

    constructor(uint256 _value){
        value = _value;
    }

    function setValue(uint256 _value)public{
        value = _value;
    }
    
    function getValue()public view returns(uint256){
        return value;
    }
}