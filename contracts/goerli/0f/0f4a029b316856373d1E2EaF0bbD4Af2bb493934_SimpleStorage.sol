// SPDX-License-Identifier: MIT
// Version of Solidity utilized ^0.8.0 - any version up from 0.8.0 , >=0.8.0 <0.9.0 - version greater than 0.8.0 but less than 0.9.0
pragma solidity 0.8.8;

contract SimpleStorage {
    uint256 favDigit;

    mapping(string => uint256) public nameToFavDigit;

    // Adding a type outside of the standard types
    struct People {
        uint256 favDigit;
        string name;
    }
    // uint256[] public favDigitsList;
    People[] public people;

    // Dynamic array, it is not fixed size of a list
    // Array is indexed, Dude 0: 777, Dudette 1: 42069

    // Function that will store the execution of applying a fav digit
    function store(uint256 _favDigit) public virtual {
        favDigit = _favDigit;
    }

    // view and pure are gasfree functions to read the contract
    function retrieve() public view returns (uint256) {
        return favDigit;
    }

    // calldata temporary variable no modify, memory temporary variable modify, storage perm variable modify,
    // calldata and memory are temporary to the call variable
    // storage live outside of the functions execution
    function addPerson(string memory _name, uint256 _favDigit) public {
        People memory newPerson = People({favDigit: _favDigit, name: _name});
        // People memory newPerson = People(_favDigit, _name); (adding the parameters as they are shown in the struct, same as the code above, but less explicit)
        // people.push(People(_favDigit, _name)); (dont save the variable)
        people.push(newPerson);
        // Pushed new people to the array
        nameToFavDigit[_name] = _favDigit;
    }
}