/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 public FavouriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    mapping(address => People) addressToFavNum;

    function store(uint256 _favoriteNumber) public {
        FavouriteNumber = _favoriteNumber;
    }

    function addPeople(string memory _name, uint256 _favNumber) public {
        addressToFavNum[msg.sender] = People(_favNumber, _name);
    }

    function seePeople() public view returns (string memory, uint256) {
        People memory person = addressToFavNum[msg.sender];
        return (person.name, person.favoriteNumber);
    }
}