// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; // it means that only this version and above are ok

contract SimpleStorage {

    uint256 favoriteNumber; 
    bool favBool;

    struct People
    {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;
    
    // It will map user name to his number -> we search for name we get number
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 favNumber) public
    {
        favoriteNumber = favNumber;
    }

    function retrieve() public view returns(uint256)
    {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 favNumber) public
    {
        // people.push(People({favoriteNumber: favNumber, name: _name})); -> other way of passing arguments to function
        people.push(People(favNumber, _name));  // adding new values to the array
        nameToFavoriteNumber[_name] = favNumber;  // mapping name with favorite number
    }
}