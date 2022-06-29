// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    uint256 favNumber; //init to 0

    mapping(string => uint256) public nameToFavNumber;
    People[] public people;

    struct People {
        uint256 favNumber;
        string name;
    }

    function store(uint256 _favNumber) public virtual {
        favNumber = _favNumber;
    }

    function retreive() public view returns (uint256) {
        return favNumber;
    }

    function addPerson(string calldata _name, uint256 _favNumber) public {
        people.push(People(_favNumber, _name));
        nameToFavNumber[_name] = _favNumber;
    }
}