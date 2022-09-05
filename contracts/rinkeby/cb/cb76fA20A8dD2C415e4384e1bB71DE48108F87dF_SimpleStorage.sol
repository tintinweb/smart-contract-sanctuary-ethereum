// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 Favoritenum;
    mapping(string => uint256) public nameToFavoriteNum;

    struct People {
        string name;
        uint256 Favoritenum;
    }

    People[] public people; //dynamic array

    function csd(uint256 num) public virtual {
        Favoritenum = num;
    }

    function addperson(string memory _name, uint256 num) public {
        people.push(People(_name, num));
        nameToFavoriteNum[_name] = num;
    }

    function retrieve() public view returns (uint256) {
        return Favoritenum;
    }
}