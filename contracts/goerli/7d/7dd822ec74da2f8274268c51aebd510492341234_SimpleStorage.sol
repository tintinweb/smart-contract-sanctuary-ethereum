/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract SimpleStorage {
    mapping(address => uint256) public favoriteNumbers;

    function setFavorite(uint x) public {
        favoriteNumbers[msg.sender] = x;
    }

    function getFavorite() public view returns (uint256) {
        return favoriteNumbers[msg.sender];
    }
}