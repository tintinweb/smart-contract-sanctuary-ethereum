/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract SimpleStorage {
    mapping(address => uint256) addressToFavouriteNumber;

    function store(uint256 _favouriteNumber) public {
        addressToFavouriteNumber[msg.sender] = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return addressToFavouriteNumber[msg.sender];
    }
}