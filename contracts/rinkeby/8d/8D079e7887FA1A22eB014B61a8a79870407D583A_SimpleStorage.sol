// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract SimpleStorage {
    // This is intialized to zero!
    // Public visibility will allow anyone to be able to see the value basically adding a getter function to see the value
    uint256 favoriteNumber;

    // Everyname will map to a specific number;
    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // Creates an array of People and puts it into a variable called people
    // dynamic array
    // fixed array has a number inside the brakets meaning how many items can be in the array
    People[] public people;

    // Changes stored value
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // Retrieve function
    // view + pure doesnt require gas or update the blockchain
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata - temp var that cant be modified
    // memory - temp var that can be modified
    // storage - variables that arent temp
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // Create a new struct of People and call it newPeople
        People memory newPeople = People(_favoriteNumber, _name);

        // Push new people into the array
        people.push(newPeople);

        // Adds name to array with favorite number
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}