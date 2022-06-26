/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7; // ^ means any version above will do

// pragma solidity >=0.8.7 <0.9.9; <= giving a range where would work

contract SimpleStorage {
    //default is internal
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //People[3] would mean i can only have 3 people in the array
    People[] public people;

    //virtual keyword allows overriding in child contracts
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view: just for viewing, dont cost gas
    //pure: cant read or modify state
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //calldata = temporay storage, but cant modify the variable
    //memory = temporary storage
    //strings are arrays of bytes under the hood, they need to be specified as calldata or memory storage when they are function arguments
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People(_favoriteNumber, _name);
        people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}