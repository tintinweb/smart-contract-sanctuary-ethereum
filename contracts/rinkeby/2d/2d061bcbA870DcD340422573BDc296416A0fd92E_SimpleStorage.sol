// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; //Versions above 0.8.7 will run with ease.

contract SimpleStorage {
    bool favouriteNum = false;
    uint256 public favourriteuint = 24;
    string favouriteStr = "ABSHS";
    int256 favInt = -272;

    bytes favBytes = "CAT"; //0x2ygh44ghg3;
    uint256 favouriteNumber;
    struct People {
        string name;
        uint256 favourriteNumber;
    }

    mapping(string => uint256) public nameToFavouriteNumber;
    People[] public person;

    function favNumber(uint256 _favNumber) public {
        favouriteNumber = _favNumber;
    }

    function Display() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        People memory newPerson = People(_name, _favouriteNumber);
        person.push(newPerson);
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}