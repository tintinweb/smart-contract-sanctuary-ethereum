//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    // Defining a new GLOBAL variable with the type "uint256"
    uint256 favoriteNumber;

    // Creating a new data type with the name "People"
    // The people data type has the properties "favoriteNumber" which is an uint256 and "name" which is a string
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //Creating  a new array with the data type "People" which we've just created and naming the array "people"
    People[] public people;

    //Creating a new function to retrieve, view the value of "favoriteNumber" variable
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //Creating a function to change and store the value of the variable "favoriteNumber"
    //Function is virtual in order to be suitable for override
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //Mapping = dictionary and delivers a value for the keyword given.
    //The name of the mapping is "nameToFavoriteNumber".
    mapping(string => uint256) public nameToFavoriteNumber;

    //Creating a new function to add new "People" typed elements to the people array.
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        //Binding new elements we have added with the mapping above.
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}