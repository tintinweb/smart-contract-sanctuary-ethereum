/**
 *Submitted for verification at Etherscan.io on 2023-01-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10; 

contract SimpleStorage {

    uint256 favoriteNumber;

   
    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrive() public view returns(uint256){
        return favoriteNumber;
    }

}