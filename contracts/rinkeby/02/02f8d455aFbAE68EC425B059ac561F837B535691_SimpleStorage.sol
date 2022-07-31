// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7; // 0.8.12 is the latest version

// Rinkeby deployed contract address: 0xDEf3878B00389650654cA151DEf9Aa681673eecb
// Tx hash: https://rinkeby.etherscan.io/tx/0xb775bd7905cb0ea56445c7433757c366b503623fe6350a8aa4d53260cacef8e4

contract SimpleStorage {
    // Types: https://docs.soliditylang.org/en/v0.8.14/types.html
    // Some elementary types: boolean, uint, int, address, bytes
    // Can specify size of uints / ints in bits (8 to 256), defaults to 256
    // The null / undefined value for uints and ints is 0
    // Hence, just declaring the variable like uint favouriteNumber; would initialize its value to 0

    uint256 public favouriteNumber; // This is in the global scope

    // Structs are like JS objects
    struct People {
        uint256 favouriteNumber;
        string name;
    }

    // This is a dynamic array of type People (i.e. each element of the array will be a People struct)
    People[] public people;

    // Mappings is essentially a dictionary
    mapping(string => uint256) public nameToFavouriteNumber;

    // Functions that are view or pure don't spend gas when called by themselves (blue buttons in Remix)
    // Getter functions are view functions by default
    // View functions just read the state of the blockchain but do not make any changes to it
    // View and pure functions disallow modification of the state; pure functions also disallow reading the state
    // If a gas calling function calls a view or pure function, then it will cost gas

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber; // _favouriteNumber is in a local scope of this function
    }

    // The EVM can store and access data from six location:
    // Stack, Memory, Storage, Calldata, Code, Logs
    // You can only explicitly specify storage location to memory, storage or calldata
    // Calldata and memory mean that the variable is only going to exist temporarily
    // Memory means temporary variables that are mutable, whereas calldata means temporary variables that are not mutable
    // Below, since we do not need the name variable after the function execution, we can store it in memory
    // Storage variables are stored permanently on the blockchain that are mutable
    // Data location can only be (and needs to be specified for function parameters) for arrays, structs and mappings
    // Solidity knows by default where a uint256 variable needs to be stored, but this is not clear for the typed above
    // Strings are just arrays of bytes

    function addPerson(uint256 _favouriteNumber, string memory _name) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}