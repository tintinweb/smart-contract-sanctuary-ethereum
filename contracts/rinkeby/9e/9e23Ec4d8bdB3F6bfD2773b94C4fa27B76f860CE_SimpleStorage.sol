// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; // Their are many versions, but we should select stable version. We can create a range of versions we want to use

contract SimpleStorage {
    // We declare a contract
    // Types: boolean, uint(unisgned integer), int, address, bytes
    // bool hasFavoriteNumber = false;
    // uint256 favoriteNumber = 5; // unit you have to specify amount of memory to allocate
    // string favoriteNumbeInText = "Five";
    // int256 favoriteInt = -5;
    // address myAddress = 0xe128aaef909929A763E7a664cA922ab77ec8a067;
    // bytes32 favoriteBytes = "cat"; // these are normally in a different format

    // make public to make it visible to the public and turns it into a getter function
    // internal means only the contract has access to that function or variable, example: unint256 internal favoriteNumber;
    uint256 favoriteNumber; // this gets initialized at zero, this is also a storage evm

    // name will map favorite number
    mapping(string => uint256) public nameToFavoriteNumber;

    // People public person = People({P
    //     favoriteNumber: 2,
    //     name: 'Victor'
    // });

    // Object
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // uint256[] public favoriteNumbersList;
    // Dynamic Array add number to [], to give it an amount.
    People[] public people;

    // virtual is used so the funciton can be overriden
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view, pure helps us not spend gas becuase we just view
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata(calldata is unmtuable), memory(only exist temporary), storage(exist outside of just the function)
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    // Every single smart contract belongs to a unique address once uploaded to the network.
    // 0xd9145CCE52D386f254917e481eB44e9943F39138
    // each contract when deployed you must spend money because you are changing the blockchain.
}

// Notes:
// The more stuff you do the more expensive it becomes.
// if your call view functions with in a function it will then cost gas

// Where to store data in solidity
// 1. Stack
// 2. Memory
// 3. Storage
// 4. Calldata
// 5. Code
// 6. Logs