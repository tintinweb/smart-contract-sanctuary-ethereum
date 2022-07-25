/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favoriteNumber;
    // contain key-value pairs similar to maps in javascript
    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //initializing an array
    //could also be uint256[] public numArray;
    People[] public people;

    // modifies the state of the blockchain
    // 'virtual' allows this function to be modified by another contract that inherits this contract.
    function store(uint _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //doesn't modify the state of the blockchain 'view'
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        //people.push(newPerson);
        people.push(People(_favoriteNumber, _name));
        nameToFavouriteNumber[_name] = _favoriteNumber;
    }
}