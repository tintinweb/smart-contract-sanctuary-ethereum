//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // the ^ means any newer version will work

contract SimpleStorage {
    uint256 favoriteNumber;
    //uint is amount of bits allocated and defaults to 256 bits and a val of 0
    //making the var public lets you see the value of the uint var
    //if visibility not specified it defers to internal - this var can only be called by this contract

    mapping(string => uint256) public nameToFavoriteNumber;
    //each name will be mapped to a specific number

    struct People {
        uint256 favoriteNumber;
        string name;
        //struct = class of variable
    }

    People[] public people;

    //creates an array that calls the People function to index values

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber; //stores imported value as uint
        //this function modifies the state of the blockchain so therefore costs gas to run
        //virtual lets function be overriden in different contract
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
        //view function lets you read what is written (referencing uint var) but can't change value
        //pure doesn't allow editing or reading
        //these functions do not modify the state of the blockchain (don't cost gas)
    }

    //memory is temporary var that can be modified, calldata is temporary but can't be modified
    //storage is default, permanent variable that can be modified
    //structs/arrays need to be given keyword when being added into parameters
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        //adds to the array of the People function, click "addPerson" after making new entry
        nameToFavoriteNumber[_name] = _favoriteNumber;
        //lets you search favoriteNumber by name
    }
}