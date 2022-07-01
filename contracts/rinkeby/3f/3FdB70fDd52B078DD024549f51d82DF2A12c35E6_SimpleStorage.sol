// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 public favNumber;

    mapping(string => uint256) public people;

    function enterFavNumber(string memory _name, uint256 _number) public {
        people[_name] = _number;
    }

    function store(uint256 _favNumber) public virtual {
        favNumber = _favNumber;
    }

    function retrive() public view returns (uint256) {
        return favNumber;
    }
}