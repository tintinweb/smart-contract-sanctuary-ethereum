//SPDX-License-Identifier: MIT
pragma solidity >=0.8.8; //stable version, I am told

contract SimpleStorage {
    uint256 favoriteNumber;

    uint256 test;

    mapping(string => uint256) public NametoFavoriteNumbner;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function storePeople(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        NametoFavoriteNumbner[_name] = _favoriteNumber;
    }
}

//0x3CB2b7eAbF087eB620F0B9a8Ae3641c271E4EaA0