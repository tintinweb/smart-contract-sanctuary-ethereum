/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract SimpleStorage {
    // this will get initialized to 0!
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }


    People[] public people;
    mapping(string => uint256) public nameToFavoriteNumer;
    mapping(uint256 => string) public favoriteNumerToName;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));

        nameToFavoriteNumer[_name] = _favoriteNumber;
        favoriteNumerToName[_favoriteNumber] = _name;
    }
}