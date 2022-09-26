/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17; // import solidity version 

contract FirstContracts {
    uint8 Value;

    function get() public view returns(uint8) {
        return Value;
    }

    function set(uint8  _value) public {
        Value = _value;
    }
   
}