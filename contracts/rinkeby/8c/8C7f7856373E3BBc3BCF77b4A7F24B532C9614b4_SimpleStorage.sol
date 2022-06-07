// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    //Primitive types: boolean, uint (just positive), int, address, bytes
    bool hasFavoriteNumber = true;
    uint256 favoriteNumber = 123;
    uint256 favoriteNumberExplicit = 123;
    uint8 favoriteNumber8 = 1;
    address myAddress = 0x0506823406ec5Fa17EC597d3a7507A72E2588ade;
    string favoriteNumberString = "Five";
    bytes favoriteBytes = "cat";
    bytes32 favoriteBytesExplicit = "cat";

    // This gets initialized to Zero!
    uint256 public favoriteNumberStore;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    mapping(string => uint256) public nameToFavoriteNumber;

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumberStore = _favoriteNumber;
    }

    // View functions do not spend Gas when called, unless they are called by another contract.
    // E.g calling retrive() inside the store() function would increase the gas spent when calling the store() function
    function retrieve() public view returns (uint256) {
        return favoriteNumberStore;
    }

    // Data in EVM can be stored in different places such as CallData, Memory, Storage, etc...
    // CallData and Memory means that the variable will only exists temporarily
    // Only Structs, Maps and arrays need to specify where the storage will be (Memory or CallData)
    // Type CallData do not allow to change the valeu that is being sent, Type Memory Do!
    // Storage data is accessible even outside the scope of the function and is available for ever (permanent storage).
    // All the variables defined above are stored in Storage, even tho we didn't specify it
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}