/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

contract Deneme {
    uint256 public myValue;


    function setValue(uint256 _value) public {
        myValue = _value;
    }

    function getValue() public view returns(uint256) {
        return myValue;
    }
    
}