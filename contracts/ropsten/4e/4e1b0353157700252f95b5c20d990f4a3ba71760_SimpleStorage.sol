/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract SimpleStorage {
    struct People
    {
        string name;
        uint256 favoriteNumber;
    }

    People[] people;

    mapping(string => uint) peopleMapping;

    function store(string memory _name, uint256 _favoriteNumber) public 
    {
        People memory person = People({name : _name, favoriteNumber : _favoriteNumber});
        people.push(person);
        peopleMapping[_name] = _favoriteNumber;
    }

    function searchFavoriteNumberPerPerson(string memory _name) public view returns(uint256)
    {
        return peopleMapping[_name];
    }

    function retrieve(uint256 index) public view returns(People memory)
    {
        return people[index]; 
    }
}