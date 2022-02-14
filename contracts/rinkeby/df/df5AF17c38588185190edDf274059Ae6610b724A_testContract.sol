/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;



// File: testContract.sol

contract testContract{

    mapping (address => uint) public favoriteNumber;
    mapping (address => uint) numaddress;

    function insertNumber(uint _favoritenumber) public{
        require(numaddress[msg.sender] == 0);
        favoriteNumber[msg.sender] = _favoritenumber;
        numaddress[msg.sender]++;
    }

    function getNumber() public view returns (uint){
        return favoriteNumber[msg.sender];
    }
}