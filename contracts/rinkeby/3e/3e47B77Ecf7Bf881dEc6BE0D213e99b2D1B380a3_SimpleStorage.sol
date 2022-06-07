//  SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract SimpleStorage {
    //works like a class on python

    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    } // this type "People" will contain favorite number of different people

    People[] public people; //declares a People type array with public visibility name people

    mapping(string => uint256) public name2FavNumber; //declares a mapping type (from string to uint256) with public visibility name name2FavNumber

    function store(uint256 _favoriteNumber) public returns (uint256) {
        favoriteNumber = _favoriteNumber;
        return favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function add_person(string memory _name, uint256 _favoriteNumber) public {
        People memory person = People(_favoriteNumber, _name); //Creating a People struct object
        people.push(person); //pushing the People object in the the people array
        name2FavNumber[_name] = _favoriteNumber;
    } //pass string memory name and uint256 to create a People object and pushes into a people array.
    //memory key means that the data will be stored during execution of the function.
}

// types of variables:
// uint256: unsigned integer of size 256bit
// bool: true / false
// string: 'string'
// int256: integer that can be possitive or negative
// address: ETH address
// bytes32: bytes object of size 32 bit i.e. "cat"

//more types can be found here https://docs.soliditylang.org/en/v0.8.11/types.html

// not defining the value, initialize will be that of a default value

// Visibility : Default = internal
// external: only external contract can call the var or fn
// public: can be call by anybody
// internal: can only be called by other fn inside the contract
// private: only sisble to contract that they are defined in, not derived contract

// more visibility can be found here https://docs.soliditylang.org/en/v0.8.11/contracts.html#visibility-and-getters

// Scope
// variables can only be accessed within the same {}

// view function only read off the blockchain - no transaction
// public variables inherently have a view function
// pure function purely calculates math

//struct a way to define new types.

//mapping dict like structure with 1 value per key

//syntax for defining the variable: Types Visibility Name
// uint256 public FavInt
//Same with array
// People[] public people