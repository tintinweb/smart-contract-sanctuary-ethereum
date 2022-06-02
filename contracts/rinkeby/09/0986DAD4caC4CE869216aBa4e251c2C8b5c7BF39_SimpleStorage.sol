// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favoriteNumber;

    struct People {
        uint256 favNumber;
        string name;
    }

    People[] public people;

    mapping(string => uint256) public nameToFavNumber;

    function storeFavoriteNumber(uint256 _number) public virtual {
        favoriteNumber = _number;
    }

    function retrieveFavNumber() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(uint256 _favNumber, string memory _name) public {
        people.push(People(_favNumber, _name));

        nameToFavNumber[_name] = _favNumber;
    }

    function viewPeople() public view returns (People[] memory) {
        return people;
    }
}