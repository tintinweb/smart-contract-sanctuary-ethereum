// SPDX-License-Identifier:MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint public FavouriteNumber;
    mapping(string => uint256) public nameToFavouritenum;
    People[] public person;
    struct People {
        uint256 favouriteNumber;
        string name;
    }

    function store(uint _FavouriteNumber) public {
        FavouriteNumber = _FavouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return FavouriteNumber;
    }

    function add(string memory _name, uint256 _favouriteNumber) public {
        person.push(People(_favouriteNumber, _name));
        nameToFavouritenum[_name] = _favouriteNumber;
    }
}