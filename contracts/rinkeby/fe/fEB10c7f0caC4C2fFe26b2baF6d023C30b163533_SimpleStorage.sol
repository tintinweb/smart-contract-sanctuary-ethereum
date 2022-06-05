/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

//SPDX-License-Identifier:MIT
pragma solidity 0.7.5;

contract SimpleStorage {
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favouriteNumber) public {
        favoriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPeople(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}