// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8; // ^ means above that verison

contract SimpleStorage {
    //this is just 0 becasue we didnt assign it a value
    uint256 favoriteNumber;

    //mapping is a key that works like dictonarry
    mapping(string => uint256) public nameToFavoriteNumber;

    //we created a struct that has people that has uint and a string
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //uint256[] public favoriteNumbersList;
    //syntax: uint256[] public "NameOfArray";
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view , pure
    function reterive() public view returns (uint256) {
        return favoriteNumber;
    }

    // types of places where evm stores and acsess data : calldata , memory , storage
    function addperson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}

//0xd9145CCE52D386f254917e481eB44e9943F39138