// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;


contract SimpleStorage {

    // This gets initalized to 0!
    // Pulbic creates a getter function 
    //visibility defualts as internal 
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    
    // uint256[] public favoriteNumberList;
    People[] public people;


    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view and pure don't require gas
    //if a gas calling function calls a view or pur function
    //only then will it cost gas
    function retrieve() public view returns(uint256){
        return favoriteNumber;
    }

    // calldata(temporary), memory(temporary), storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}