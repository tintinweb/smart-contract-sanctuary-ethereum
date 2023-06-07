/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SimpleStorage.sol
// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
    // similar to Class
    uint256 favoriteNumber;
    // initialize favoriteNumber, is actually in storage
    // default is 0 if value is not declared
    // same as
    // function retrieve() public view returns(uint256){
    //  return favoriteNumber;
    // }
    // returns(what value)

    struct People {
        uint256 favoriteNumber; // index 0
        string name; // index 1
    }
    // similar to models
    // uint256[] public anArray;

    // People public person = People({favoriteNumber: 2, name: 'ABC'});

    People[] public people;
    // creates an dynamic array, fixed-size will be People[3]

    mapping(string => uint256) public nameToFavoriteNumber;

    // dictionary with string as key and uint256 as value

    function store(uint256 _favoriteNumber) public virtual {
        // virtual added to be overriden in ExtraStorage
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        // adds to array
        nameToFavoriteNumber[_name] = _favoriteNumber;
        // adds to mapping
    }
}