/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// This is a simple contract for storing just one number and then returning it to the requester

contract FavoriteNumber {

    // Declaring variables
    uint256 public favoriteNumber = 0;


    // This function sets favoriteNumber
    function setFavoriteNumber(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    } // end function setFavoriteNumber()


    // This function returns favoriteNumber
    function getFavoriteNumber() public view returns(uint256) {
        return favoriteNumber;
    } // end function getFavoriteNumber()
} // end contract FavoriteNumber