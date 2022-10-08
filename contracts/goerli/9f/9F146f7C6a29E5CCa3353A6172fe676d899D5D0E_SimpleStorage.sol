// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; //^0.8.8, caret tells compiler that any version above the specified version is OK to use

contract SimpleStorage {
    //bool, uint, int, string, address, bytes (32, 2, 5, 22, etc)
    //uint is an unsigned integer (whole number that isn't positive or negative, it's just positive)
    //int is a positive or negative whole number
    //address is a blockchain address
    //bytes example: bytes32 favoriteBytes = "cat";
    uint256 favoriteNumber; //this gets initialized to zero
    //adding public creates a getter function for the variable
    //first variable is indexed at the 0 storage slot - like array for the whole contract
    //second variable is indexed at the 1st storage slot

    //mapping(string => uint256) is the type
    //mapping is like a dictionary
    //every string will map to a specific number
    //every possible string is initialized to have a pairing number of 0
    mapping(string => uint256) public nameToFavoriteNumber;

    //People public person = People({favoriteNumber: 2, name: "Patrick"});

    //a new type of type People
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //an array is a way to store a list or a sequence of objects
    //an array of type People
    //a dynamic array isn't given a size at initialization
    //a fixed-sized array is given a number - [3] for example
    People[] public people;

    //virtual is added to make the function overridable in a contract that inherits it
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //view and pure functions don't use gas
    //if a gas calling functions calls a view or pure function - only the will it cost gas
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //calldata and memory means that the variable will only exist temporarily during that transaction that the function is called
    //storage exists even outside of the function executing
    //uint256 favoriteNumber (the one outside the function) is automatically cast as a storage number since it ins't explicitly defined in the function
    //calldata is temp variables that can't be modified
    //memory is temp variables that can be modified
    //storage is permanent variables that can be modified
    //uint256 lives in memory already
    //a string is an array of bytes and therefore must be given a memory option (structs, mappings, and arrays) when adding them as a parameter to functions - can't be storage in function parameters because it's not being stored anywhere
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //call a push (add) function that's available on our people object
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber; //at key "name" is equal to _favoriteNumber //kinda like looking up an array by a string key instead of a number key
    }
}