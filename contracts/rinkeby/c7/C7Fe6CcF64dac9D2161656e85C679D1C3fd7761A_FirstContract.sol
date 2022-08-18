// SPDX-License-Identifier: MIT
pragma solidity 0.8.8; // version of solidity compiler used

// like class in other programming languages
contract FirstContract {
    // datatypes
    // boolean, uint, int, address, bytes, string
    bool hasFavoriteNumber = false;
    uint256 public favoriteNumber = 123;
    string favoriteNumberInText = "OneTwoThree";
    int256 favoriteInteger = -5;
    address myAddress = 0x1EbbD6c85cfF4335Ae0C182b2781A777676Ee97A;
    bytes32 favoriteBytes = "cat";

    mapping(string => uint256) public favNumMap;

    // A struct, just like struct in C++
    struct Person {
        uint256 favNum;
        string name;
    }

    Person public person = Person({favNum: 10, name: "Vedant"});
    Person[] public people; // an empty array of Person type elements

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    // view keyword, this function will just read the data
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // pure keyword, this function will only do some computation
    function compute() public pure returns (uint256) {
        return 1 + 1;
    }

    // In solidity information can be stored in 6 ways
    // main storages are -
    // calldata - make variable immutable
    // memory - persists only for function
    // storage - stays permanantly
    function addPerson(string memory _name, uint256 _favNum) public {
        // Person memory newPerson = Person({favNum: _favNum, name: _name});
        // Person memory newPerson = Person(_favNum, _name); // can also be written this way
        // people.push(newPerson);
        people.push(Person(_favNum, _name)); // can also push directly
        favNumMap[_name] = _favNum;
    }
}