// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 myNum = 5;
    int256 nevNum = -5;
    bool favoriteNumber = false;
    string favoriteString = "Hello";
    bytes32 favoriteByte = "cat";
    address Address = 0xe0bf082438A37B2b3A0042973a7061eF35425402;

    uint256 Number;
    struct people {
        string name;
        uint256 age;
    }

    people[] public arrayPeople;

    people public person = people({name: "thien", age: 20});
    mapping(string => uint256) public nameToNum;

    function store(uint256 paraNum) public {
        Number = paraNum;
    }

    function retrieve() public view returns (uint256) {
        return Number;
    }

    function addPerson(string memory name, uint256 age) public {
        arrayPeople.push(people(name, age));
        nameToNum[name] = age;
    }
}