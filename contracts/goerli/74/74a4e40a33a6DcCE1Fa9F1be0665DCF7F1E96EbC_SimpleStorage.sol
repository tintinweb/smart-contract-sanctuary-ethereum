// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract SimpleStorage {
    mapping(address => uint256) addressToFavouriteNumber;

    function store(uint256 _favouriteNumber) public {
        addressToFavouriteNumber[msg.sender] = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return addressToFavouriteNumber[msg.sender];
    }
}