//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    bool public hasFavNum = true;
    uint256 public favoriteNum = 123;
    struct People {
        uint256 favoriteNum;
        string name;
    }

    mapping(string => uint256) public nameToFavoriteNum;
    People[] public people;

    function store(uint256 _favoriteNum) public virtual {
        favoriteNum = _favoriteNum;
    }

    function retrive() public view returns (uint256) {
        return favoriteNum;
    }

    function addPerson(string memory _name, uint256 _favoriteNum) public {
        people.push(People(_favoriteNum, _name));
        nameToFavoriteNum[_name] = _favoriteNum;
    }
}