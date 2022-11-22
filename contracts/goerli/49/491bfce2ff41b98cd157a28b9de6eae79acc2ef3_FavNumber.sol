/**
 *Submitted for verification at Etherscan.io on 2022-11-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract FavNumber {
    mapping (address => uint256) numbers;

    function set(uint256 number) public {
        numbers[msg.sender] = number;
    }

    function getFavNumber(address ownerAdress) public view returns (uint256){
        return numbers[ownerAdress];
    }
}