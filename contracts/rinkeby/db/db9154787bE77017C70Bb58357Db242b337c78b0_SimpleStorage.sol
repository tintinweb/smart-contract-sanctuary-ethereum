/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    // public is the visibility of the data (set automatic as internal -> visible only in the source code)
    // public attribute attaches a pseudo function that allows to see the variable -> like an inner function
    uint favoriteNumber; // default value in solidity == 0

    // mapping generation
    mapping(string => uint256) public nameToFavoriteNumber; // string mapped to uint256

    // object generation
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people; // with the [] key we generate an array

    // function declaration
    // virtual keyword allows to change the meaning of this function from another .sol file
    function store(uint256 _favoriteNumber) public virtual {
        /*
        changes the state of the 'favoriteNumber' value
        */
        favoriteNumber = _favoriteNumber;
        retrieve(); // this time, altough retrieve() is set to view, we spend gas any time we run this function (that is not set to pure)
    }

    // view | pure don't have to spend gas for the visualization of the data -> no update the state
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata, memory, storage
    // memory only exists temporarly during the function running -> during the transaction and if the function is called
    // storage persists in the code even when the function is done
    // calldata temporary variables that CANNOT be modified
    // memory works for all the data type except uint|int -> treats secretly with arrays ~ strings
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        people.push(newPerson); // push stands for adding people to the array people
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}