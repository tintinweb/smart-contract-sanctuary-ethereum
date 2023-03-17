//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    struct People {
        string name;
        uint256 favoriteNumber;
    }

    mapping(string => uint256) public nameToFavoriteNum;

    People[] public person;

    uint256 favoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People(_name, _favoriteNumber);
        person.push(newPerson);
        nameToFavoriteNum[_name] = _favoriteNumber;
    }
}