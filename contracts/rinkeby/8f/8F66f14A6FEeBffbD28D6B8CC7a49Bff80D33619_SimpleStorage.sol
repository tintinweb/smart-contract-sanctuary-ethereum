// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    //There are different types of Data within Solidity including booleans, uint, int, address, bytes
    //boolean is obvious true false
    //uint is an integer that is not positive or negative
    //int is an integer that is either positive or negative
    //address is the account address
    //bytes is well... bytes

    //Some Examples of use include:
    // bool hasFavoriteNumber = true;
    // uint256 favoriteNumber = 5;
    // string favoriteNumberInText = "five";
    // int256 favoriteInt = -5;
    // address myAddress = 0x10...Aaabb
    // bytes32 favoriteBytes = "cat"

    uint256 public favoriteNumber;
    //if favoriteNumber is not defined it will have a default null value which in solidity is 0.
    //in order to access favoriteNumber the word public must be placed otherwise it will be private and inaccessible.

    //mapping is sort of like a dicitionary. its a set of keys where each key returns a certain value associate with the key.
    mapping(string => uint256) public nameToFavoriteNumber;
    //now we have a dicitionary where every single name is going to map to a number

    People public person = People({favoriteNumber: 2, name: "Patrick"}); //This is like creating a new instance or new person based on the object that already exists.

    //A better way to create multiple people is to use an Array. This way we dont need to statically type in every instance of a person.
    People[] public people;

    struct People {
        //We have now created a new type called people. This is essentially an object.
        uint256 favoriteNumber; //index of 0
        string name; //index of 1
    }

    function store(uint256 _favNumber) public virtual {
        favoriteNumber = _favNumber;
        retrieve(); //Will now cost gas to call.
    }

    //Returns keyword means what is this function going to give us after we call it.
    function retrieve() public view returns (uint256) {
        //Free of cost
        return favoriteNumber;
    }

    //View and pure functions when called alone don't spend gas.
    //Views and pures are free unless you calling them inside of a function that costs gas (which is typically a function that can update the state.)
    //View functions means it will just read something off the contract
    //With a view function you cannot modifiy the state - meaning you cant update the blockchain.
    //Pure functions in addition to not being able to modify the state also dont allow you to read from the blockchain.
    //Pure functions could be used for something like this:
    function add() public pure returns (uint256) {
        return (1 + 1);
        //So with pure functions there might be some math that you might want to use over and over again or implement some algorithm that doesnt need to read any storage/state.
    }

    //Anytime you change something onchain including making a new contract, it happens in a transaction. Meaning there is an associated cost.
    //4 types of visibility specifiers - public: anyone who interacts with the contract can see it, private: only this specific contract can call the function, external: people from outside can call the function & internal: only contract and its children can call the function

    //Running complex functions will cost more gas as it is more computationally expensive.

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //2 Ways to add a person to the array:
        //1:
        // People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        // people.push(newPerson);

        //2:
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
    //There are 6 places you can store data in solidity:
    //Stack, Memory, Storage, Calldata, Code, Logs
    //Calldata and Memory mean that the variable is only going to exist temporarily
    //Calldata is temporary variables that cannot be modified
    //Memory is temporary variables that can be modified.
    //Storage is permanent variables that can be modified.
    //Storage variables exist even outside the function thats executing it.
    //Solidity knows that uint256 is going to live just in memory but isnt sure about what string is going to be.
    //Strings is an array of bytes thus we need to tell solidity
}