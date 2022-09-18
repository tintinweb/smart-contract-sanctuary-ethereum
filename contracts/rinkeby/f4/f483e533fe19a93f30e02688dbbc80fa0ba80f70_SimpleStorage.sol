/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; // define solidity version

contract SimpleStorage {

    // bool hasFavoriteNumber = true;
    // uint256 favoriteNumber = 5;
    // string favoriteNumberInText = "five";
    // int256 intFavoriteInt = -5;
    // address myAddress = 0x5BA9dF9078DaA33E0bd9012DaD9CE5C8F89bb902;
    // bytes32 favoriteBytes = "cat"; // this would look like 0x3434590249 or whatever represents cat in this case
    
    // default value of uint is 0
    // public variables technically automatically have a view function created for it when deployed
    uint256 private favoriteNumber;
    // People public person = People({favoriteNumber: 2, name: "Me"});

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    mapping (string => uint256) public nameToFavoriteNumber;

    function store (uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    // view function used to return state (i.e. read) but can also alter, but wont save to chain e.g. favnumber + input
    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    // pure functions also don't write to chain, but can do basic stuff like math - doesn't read var from chain
    // function add(uint256 a, uint256 b) public pure returns(uint256) {
    //     return (a+b);
    // }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // People memory newPerson = People(_favoriteNumber, _name);
        // people.push(newPerson);
        people.push(People(_favoriteNumber, _name)); // slightly more gas efficient
        nameToFavoriteNumber[_name] = _favoriteNumber;

    }



}