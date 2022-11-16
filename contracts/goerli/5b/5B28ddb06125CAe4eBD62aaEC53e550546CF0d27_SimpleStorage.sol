// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    uint256 favoriteNumber;

    People public person = People({age: 18, name: 'Danik'});

    uint256[] public numbers; // dynamic array
    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;
    mapping(uint256 => People) public test;

    struct People {
        uint256 age;
        string name;
    }

    // constructor()

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    // Only read
    function getFavoriteNumber() public view returns (uint256) {
        return favoriteNumber;
    }

    // Not use any state
    function sum(uint256 a, uint256 b) public pure returns (uint256) {
        return uint256(a + b);
    }

    // calldata - temp variable that cannot be modified
    // memory - temp variable that can be modified
    // storage - contract scope varitables(live after executing tx)
    function addPerson(string memory _name, uint256 _age) public {
        People memory newPerson = People(_age, _name); // People({ age: _age, name: _name })
        people.push(People(_age, _name));
        people.push(newPerson);
        nameToFavoriteNumber[_name] = _age;
    }
}