// pragma solidity ^0.8.7 // more stable version // 0.8.12 // ^ for any version 0.8.7 and above will work
// pragma solidity >=0.8.7 <0.9.0 ; between these two values

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// similar to class in any OOPs language
contract SimpleStorage {
    // types---> boolean, uint , int address, btyes
    // uint -- unsigned
    // int --- signed
    // we can do uint uint256(highest) uint8(lowest) depending upon the size we are using
    // uint favoriteNumber = 123;
    // uint256 favoriteNumberin256 = 123;
    // int number = 123;
    // int256 num = 123;
    // string favoriteNumberinttext = "Five";
    // address myAddress = 0xA98fD14e97A3D37851454323C74B9F836d69125F;
    // bytes32 favoriteBytes = "cat";

    uint256 favoriteNumber; // set to default value of null value which is 0 in solidity
    // People public person = People({favoriteNumber:2,name:"person"});

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // dynamic array;
    People[] public people;
    mapping(string => uint256) public nameToFavoriteNumber;

    // fixed size array
    // People[3] public people

    // view -- allow read of state not modify
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // pure -- don't allow read and modification
    function add() public pure returns (uint256) {
        return (1 + 1);
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}