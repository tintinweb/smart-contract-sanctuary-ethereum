// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract SimpleStorage {
    bool hasFavoriteNumber = false;
    uint256 public favoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retreive() public view returns (uint256) {
        return favoriteNumber;
    }

    //view and pure don't require gas for execution

    function add() public pure returns (uint256) {
        return (1 + 1);
    }

    //struc you can create a new type
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People public person = People({favoriteNumber: 2, name: "Carl"});

    People[] public personArray;
    mapping(string => uint256) public nameToFavoriteNumber;
    uint256 public index;

    function addPeople(string memory _name, uint256 _favoriteNumber) public {
        personArray.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}