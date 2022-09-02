// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract SimpleStorage {
    uint256 favouriteNumber;

    mapping(string => uint256) public nameToFavouriteNumber;

    // Creating an array to assign people to number we can use struct

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    // uint256 [] public favouriteNumbersLists;
    People[] public people;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    // two states: view, pure
    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}