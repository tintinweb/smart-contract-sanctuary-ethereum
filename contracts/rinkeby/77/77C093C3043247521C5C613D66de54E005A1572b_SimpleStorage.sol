// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// The first thing you do when creating a solidity file is to declare the version of solidity that you want to use.
// This is done via the pragma solidity statement.
// A ^ symbol indicates that you want to use any version selected (0.8.7) and above (ex. 0.8.12)
// Additionally you will want to put an SPDX License Identifier in your code - MIT is the least restrictive.

// contract is a keyword, letting the compiler know that we are defining a contract.
contract SimpleStorage {
    // Every line needs to end in ;
    // There are four different visibility modifiers: public, private, external, and internal.
    // public means it is visible outside of the contract
    // private means it is only visible inside of the contract
    // external means it is callable outside of the contract
    // internal means it is only callable inside of the contract or in contract's children. This is the default modifier if none is set.

    // This gets initialized to 0 if not set explicitly.
    uint256 favoriteNumber;

    //mappings are basically dictionaries that take a type (string in this example) and return another type (uint256)
    //The purpose of this specific mapping is to return the favorite number of someone, given their name.
    //You would call this mapping like so: nameToFavoriteNumber["Nathan"]. If Nathan was in the array, it would return the favorite number associated.
    //You must explicity define the mapping. See the addPerson function below where we are adding the definition for the mapping to work with our array.
    mapping(string => uint256) public nameToFavoriteNumber;

    // Structs are used to create more complex types
    struct People {
        uint256 favoriteNumber;
        string name;
    }
    // When initializing Structs, you must use ({}) notation to set the property values.
    People public person = People({favoriteNumber: 2, name: "Nathan"});

    // This is an array of the People struct. Array notation is Type[] viewModifier arrayName.
    // This is a dynamic array, if we wanted a limited array we would say [2] for a limit of two People structs.
    People[] public people;

    //function is a keyword, letting the compiler know we are defining a function.
    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    //view and pure functions don't cost gas, they are read only functions.
    //They are free (don't cost gas) because they don't modify the blockchain, they only read it.
    //These functions will cost gas if they are called inside of a function that produces a transaction.
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // This is a function that will add a new person to the people array defined above.
    // calldata, memory, storage are three basic places that data is stored.
    // memory means that the data is stored temporarily and can be modified
    // calldata can be used similar to memory except you can't modify the variable
    // storage is a permanent variable that can be modified
    // You don't have to call memory on a uint256 because it is a basic type. string is a complex type as it's actually an array.
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}