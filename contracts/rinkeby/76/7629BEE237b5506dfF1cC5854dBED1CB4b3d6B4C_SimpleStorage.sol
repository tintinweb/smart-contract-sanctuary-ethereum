//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    mapping(string => uint256) public nameToNumber;
    People[] public people;
    uint256 favoriteNum;

    function createPerson(string memory name, uint256 favoriteNumber) public {
        People memory person = People({
            favoriteNumber: favoriteNumber,
            name: name
        });
        people.push(person);
        nameToNumber[name] = favoriteNumber;
    }

    function store(uint256 _changeFave) public virtual {
        favoriteNum = _changeFave;
    }

    function getFavoriteNum() public view returns (uint256) {
        return favoriteNum;
    }
}