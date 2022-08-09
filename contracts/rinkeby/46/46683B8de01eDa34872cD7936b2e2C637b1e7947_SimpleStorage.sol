// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract SimpleStorage {
    //bool, uint, int, address

    uint256 public favoriteNumber;
    // bool hasFavoriteNumber = true;
    // string favoriteNumberInText = "five";
    // int favorateInt = -5
    // address = myAddress = 0xF8d81717b5cA83Dbcfc6666Cd579bb4253eFca5f



    struct People {
        uint256 favoriteNumber;
        string name;
    }
    People[] public people;

    //mapping (similar to dictionaries)
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    //view, pure do not cost gas as these functions only view the blockahin
    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    //calldata is a function variable that can't be modified
    //memory is a function variable that can be modified
    //storage is a global variable (default outside of functions).
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}