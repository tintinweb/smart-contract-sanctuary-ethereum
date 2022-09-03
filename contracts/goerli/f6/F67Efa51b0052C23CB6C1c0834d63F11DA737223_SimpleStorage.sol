// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; //pragma solidity >=0.8.7 <0.9.0;

contract SimpleStorage {
    // boolean, uint, int, address, bytes
    bool hasFavoriteNumber = false;
    uint256 public favoriteNumber = 123;
    string favoriteNumberInTest = "Five";
    int256 favoriteInt = -5;
    address myAddress = 0xFAaa747A11bFb95AB44b17D3c033Fab4aDE8f8E5;
    bytes32 favoriteBytes = "cat";
    uint256 public favNo; // The default value is 0

    mapping(string => uint256) public personMap;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // Dynamic array

    People[] public peopleArray;

    People public person = People({favoriteNumber: 2, name: "Patrick"});

    // view,pure => state modifiers, they do not modify any data inside bc

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata, memory, storage

    function addPerson(uint256 _newFavNo, string calldata _newPerson) public {
        // _newPerson = "Mert"; You cannot update _nerPerson if you denifed the stored option as calldata.
        People memory newPerson = People(_newFavNo, _newPerson);
        // People memory newPerson2 = People({favoriteNumber: _newFavNo, name: _newPerson});
        peopleArray.push(newPerson);
        peopleArray.push(People(_newFavNo, _newPerson));
        personMap[_newPerson] = _newFavNo;
    }
}