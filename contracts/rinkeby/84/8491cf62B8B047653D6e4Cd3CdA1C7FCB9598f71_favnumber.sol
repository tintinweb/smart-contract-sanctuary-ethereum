/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;



// File: keccak256.sol

contract favnumber{

    mapping (address => uint) public favoriteNumber;

    function insertNumber(uint _favoritenumber) public{
        favoriteNumber[msg.sender] = _favoritenumber;
    }

    function getNumber() public view returns (uint){
        return favoriteNumber[msg.sender];
    }
}