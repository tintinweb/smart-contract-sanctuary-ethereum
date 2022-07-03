// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    uint256 favNumber;

    mapping(string => uint256) public nameToFavNumber;

    struct People {
        uint256 favNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favNumber) public virtual {
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