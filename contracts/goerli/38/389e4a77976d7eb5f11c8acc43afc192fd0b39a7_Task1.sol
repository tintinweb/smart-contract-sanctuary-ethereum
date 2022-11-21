/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract Task1{
    mapping (address => uint256) favourite_number;
    
    function setFavouriteNumber(uint256 value) public {
        favourite_number[msg.sender] = value;
    }

    function getFavouriteNumber() view public returns (uint256) {
        return favourite_number[msg.sender];
    }

}