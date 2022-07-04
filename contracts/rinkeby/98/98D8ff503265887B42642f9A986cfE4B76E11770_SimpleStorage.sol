// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;
    //In this mapping, the returned value (uint256) is defaulted to 0 for any input (string)
    mapping(string => uint256) public nameToFavoriteNumber;

    // virtual specifier will make the function overridable
    function addPerson(string memory _name, uint256 _favoriteNumber)
        public
        virtual
    {
        people.push(People({favoriteNumber: _favoriteNumber, name: _name}));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function getFavoriteNumber(string memory _name)
        public
        view
        returns (uint256)
    {
        return nameToFavoriteNumber[_name];
    }
}