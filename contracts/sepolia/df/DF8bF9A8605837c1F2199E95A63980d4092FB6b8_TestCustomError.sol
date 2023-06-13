/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

contract TestCustomError {

error InvalidAddressError();
    
    function checkCustom() public pure returns (bool){
        address _input = address(0); 
        if (_input == address(0)) revert InvalidAddressError();
        return true;
    }
}