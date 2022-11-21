/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract FavouriteNumber {
    
    mapping(address=>uint256) favouriteNumbers;

    function get(address owner) public view returns (uint256 number) {
        return favouriteNumbers[owner];
    }

    function save(uint256 number) public {
        favouriteNumbers[msg.sender] = number;
    }

}