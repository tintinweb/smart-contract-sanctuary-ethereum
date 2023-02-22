// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

contract SimpleStorage {
    uint256 favNumber;

    struct People {
        uint256 favNumber;
        string name;
    }

    People[] public people;

    mapping(string => uint256) public nameToFavNumber;

    function store(uint256 _favNumber) public {
        favNumber = _favNumber;
    }

    function retrieve() public view returns (uint256) {
        return favNumber;
    }

    function addPerson(string memory _name, uint256 _favNumber) public {
        people.push(People(_favNumber, _name));
        nameToFavNumber[_name] = _favNumber;
    }
}