// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; // 0.8.12

// ex. also can use >=0.8.7 < 0.9.0 to allow a range

contract SimpleStorage {
    // boolean, uint, int, address, bytes
    // bool hasFavoriteNumber = true;
    //string favoriteNumberInText = "Five";
    //int256 favoriteInt = -5;
    //address myAddress = 0xc2a63C681c3446468Db3f4b7B5D34831b4E424E8;
    //bytes32 favoriteBytes = "cat";
    uint256 public favoriteNumber; //automatically initialized to 0
    //default scope is internal
    //every public contract variable has a built-in getter funciton
    //People public person = People({favoriteNumber: 2, name: "Patrick"});

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //view only reads from function
    //disallow any modification of state
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //calling view/pure functions do not cost gas unless called in a public function

    //calldata, memory, storage
    function addPerson(string calldata _name, uint256 _favoriteNumber) public {
        //People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        //people.push(newPerson);

        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    //calldata only alive for function lifetime, only if not modified
    //memory only alive for functioin lifetime
    //storage exists outside of function
}