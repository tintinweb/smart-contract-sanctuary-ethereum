//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //Defining solidity version

//EVM - Ethereum Virtual Function
//EVM compatible blockchains - Avalanche, Fantom, Polygon
//Defining Contract

contract SimpleStorage {
    // boolean, uint, int, address, bytes
    // bool hasFavouriteNumber = false; //it is going to represent true/false
    uint256 public favoriteNumber; //if we declare a variable it will initialize with 0...We can see the favorite Number with public keyword
    // string favoriteNumberInText = "Five";
    // int256 favoriteInt = -5;
    // address myAddress = 0x2741A659FfF36518de6dC945Afbd4630d0F48fc8;
    // bytes32 favoriteBytes = "cat"; //cat is converted to 32 bytes system
    // People public person = People({favoriteNumber: 2, name: "Ankush"}); //defining struct and what stores in it
    //initializing a struct
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // uint256[] public favouriteNumberList;
    People[] public people; //dynamic array as size of array is not declared initially

    // Creating a mapping or dictionary
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        //anytime we are doing anything on blockchain it is a txn
        //we are deploying the contract
        //Address of Smart Contract : 0xa131AD247055FD2e2aA8b156A11bdEc81b9eAD95
        //Now the account will have a little less value as we had to pay gas for the two txn we did
        //first txn is smart contract running and other is storing value in function
        //Every time we change the state of blockchain we are doing a txn
        favoriteNumber = _favoriteNumber;
        retrieve(); //now this will cost gas as we are calling it within store which changes the state of blockchain
    }

    //view and pure function won't update anything on blockchain
    //we only do a txn when we are modifying something on blockchain
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //making a function that can add to the array
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // Initializing a struct newPerson with inputs of favourite Number and name
        // People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        // People memory newPerson = People(_favoriteNumber, _name);
        // pushing into the array people
        // people.push(newPerson);

        people.push(People(_favoriteNumber, _name)); //good way to push something to the array

        nameToFavoriteNumber[_name] = _favoriteNumber; //storing in the mapping in which string is mapped to uint256
    }
    //view and pure are free to call until it is called within a function which changes the state of the blockchain
    // calldata, memory : variable gonna exist temporalily during the txn. Temporiry and can be changed
    // storage : exist even the function just getting executed and available after the function. They are permanent and can be changed
    // we need to tell the solidity about the memory of struct, mappings and arrays
}