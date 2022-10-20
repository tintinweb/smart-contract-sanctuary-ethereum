/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.7; // ^ ok for above 

// EVM , similar net : avalanche, fantom, polygon

contract SimpleStorage {

    uint256 favoriteNumber;

 
    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    // view ,pure function : only read state,disallow update chain, no gas spent
    function retrive() public view returns(uint256) {
        return favoriteNumber;
    }

}