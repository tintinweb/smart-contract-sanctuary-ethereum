// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint public hasFavoriteNUmber;
    struct People {
        uint number;
        string name;
    }
    People[] public people;
    mapping(string => uint256) public favnum;

    function store(uint256 _fav) public virtual {
        hasFavoriteNUmber = _fav;
    }

    function addPersion(string memory _name, uint256 _number) public {
        people.push(People(_number, _name));
        favnum[_name] = _number;
    }
}