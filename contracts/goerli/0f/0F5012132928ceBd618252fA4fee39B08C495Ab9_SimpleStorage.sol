//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favoriteNumber;

    //Create a struct to assign a favnumber to each person
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //Map each person to his favorite number
    mapping(string => uint256) public nameToFavoriteNumber;

    //Array of People
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return (favoriteNumber);
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //This adds people and a number to the array
        people.push(People(_favoriteNumber, _name));
        //mapp names to the people
        nameToFavoriteNumber[_name] = _favoriteNumber;
        /*Or we can separate them by creating the structure 
        and then push it into the array like this:
    
        People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name})
        people.push(newPerson);
        
        */
    }
}