/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract Task1{
    mapping (address => uint256) favourite_numbers;
    
    function setMyFavouriteNumber(uint256 value) public {
        favourite_numbers[msg.sender] = value;
    }

    function getMyFavouriteNumber(address my_address) public view returns (uint256) {
        return favourite_numbers[my_address];
    }
}