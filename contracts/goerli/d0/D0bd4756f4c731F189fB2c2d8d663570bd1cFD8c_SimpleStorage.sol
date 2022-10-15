// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage{

    uint256 favouriteNumber;

    constructor(){
        favouriteNumber = 0;
    }

    function setFavouriteNumber(uint256 number) public {
        favouriteNumber = number;
    }

    function getFavouriteNumber() public view returns(uint256){
        return favouriteNumber;
    }
}