// SPDX-License-Identifier: MIT
// The above line is not mandatory but it is best practice as some complier might need it.
// It is the line for license.

pragma solidity 0.8.9; // Solidity program always start with the pragma

// If we use ^ infront that means any version above is okay.
// To give version in range we can give it like >= 0.8.7 <0.9.0

// EVM : Ethereum Virtual Machine
// Avalanche, Fantom, Polygon

contract SimpleStorage {
    // This is a contract. Everything within the curly braces is it's content.
    // Types in Solidity : https://docs.soliditylang.org/en/latest/types.html
    // boolean, uint, int, address, bytes
    // bool hasFavouriteNumber = true;
    // string favouriteNumberInText = "Five";
    // int256 favouriteInt = -5;
    // address myAddress = 0x25a2d2C7253a019487E9911d75A50316Cbbc6960;
    // bytes32 favouriteBytes = "cat";
    // Anything within the scope of contract is a global variable.

    uint256 favouriteNumber; // Default value/Get's initialise to zero
    // People public person = People({favouriteNumber: 2, name: "Saurabh"});

    // Mapping(Dictionary) will help to map the variables.
    // For Eg: In below the every string will be assigned a specific number.
    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    People[] public people; // Dynamic Array

    // EVM can access and store information in six places
    // Stack, Storage, Code, Logs, Calldata, Memory, Storage
    // Memory: Stores data temporarily and can be modified.
    // Memory needs to be given to Struct, Mapping and Array when using in different function.
    // Calldata: Temporary that can't be modified.
    // Storage: Stores the data even outside the functions.

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        // people.push(People(_favouriteNumber, _name))
        //People memory newPerson = People({favouriteNumber: _favouriteNumber, name:_name});
        //People memory newPerson = People(_favouriteNumber, _name);
        //people.push(newPerson);
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }

    function store(uint256 _favouriteNumber) public virtual {
        // Any variable within the scope of function is a local variable.
        // We have added the virtual keyword here to override it in ExtraStorage contract.
        favouriteNumber = _favouriteNumber;
    }

    // Calling view function directly is free.
    // If they are being called from the other function then it will cost gas.
    // view : Going to read state from the contract.
    // pure : Does not read or modify state.

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    // function add() public pure returns (uint256) {
    //     return(1+1);
    // }
}

// 0xd9145CCE52D386f254917e481eB44e9943F39138