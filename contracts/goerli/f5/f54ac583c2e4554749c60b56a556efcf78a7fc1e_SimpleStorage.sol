/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

//SPDX-License-Identifier:  MIT
pragma solidity ^0.8.8; //0.8.12 can use ^0.8.7 to use anything above 0.8.7.

contract SimpleStorage {
    //comments here
    //uint256 favoriteNumber; //initalizes to 0.

    uint256 favNum;

    mapping(string => uint256) public nameToFavNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favNum = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favNum;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavNumber[_name] = _favoriteNumber;
    }
}