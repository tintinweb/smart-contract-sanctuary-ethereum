// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StorageFactory {
    uint256 public favouriteNumber;
    struct People {
        uint256 FavNum;
        string name;
    }

    mapping(address => People) public PeopleList;

    function store(uint256 _favNum) public {
        favouriteNumber = _favNum;
    }

    function addPeople(uint256 _favNum, string memory _name) public {
        PeopleList[msg.sender] = People(_favNum, _name);
    }

    function seeDetails() public view returns(People memory) {
        return PeopleList[msg.sender];
    }
}