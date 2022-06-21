/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

//SPDX-License-Identifier:MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    uint256 favoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    People[] public people;

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    mapping(string => uint256) public NameToFavoriteNumber;

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        NameToFavoriteNumber[_name] = _favoriteNumber;
    }
}