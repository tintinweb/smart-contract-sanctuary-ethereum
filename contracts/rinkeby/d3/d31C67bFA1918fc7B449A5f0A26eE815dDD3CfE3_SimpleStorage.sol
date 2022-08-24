// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favouriteNumber;

    struct People {
        string name;
        uint256 number;
    }

    People[] public people;
    mapping(string => uint256) public nameToFavouriteNumber;

    function store(uint256 _favouriteNumber) public {
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    function addNumberToName(string memory _name, uint256 _favouriteNumber)
        public
    {
        people.push(People(_name, _favouriteNumber));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}