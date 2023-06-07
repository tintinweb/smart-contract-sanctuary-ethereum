// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract SimpleStorage {
    uint256 public favouriteNumber;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    // People public person1 = People({favouriteNumber:6,name:'Job'});

    People[] public person;

    mapping(string => uint256) public toFavouriteNumber;

    function people(uint256 _favouriteNumber, string memory _name) public {
        person.push(People(_favouriteNumber, _name));
        toFavouriteNumber[_name] = _favouriteNumber;
    }
}