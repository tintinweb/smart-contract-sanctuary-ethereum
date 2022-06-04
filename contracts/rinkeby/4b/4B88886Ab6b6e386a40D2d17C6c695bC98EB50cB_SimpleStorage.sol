// SPDX-Licence-Identifier: MIT

pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 fav_number = 5;

    struct People {
        uint256 fav_number;
        string name;
    }

    People[] public people;

    mapping(string => uint256) public NameToFavoriteNumber;

    function store(uint256 passed_number) public {
        fav_number = passed_number;
    }

    function addPerson(string memory _name, uint256 _fav_number) public {
        people.push(People({fav_number: _fav_number, name: _name}));
        NameToFavoriteNumber[_name] = _fav_number;
    }

    function retrieve() public view returns (uint256) {
        return fav_number;
    }
}