// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

// ECM, Ethereum Virtual Machine : Avalanche, fantom, Polygon

contract SimpleStorage {
    // types : bool, uint, int, address, bytes
    bool hasFavoriteNumber = true;
    //uint favoriteNumber = 123; //unit8 for 8bits, by default it is 256
    // public secrately creates a function that returns the value of the variable
    uint256 favoriteNumber; // variable will be initizlised to null value (i.e 0 for unit)
    // by default, vatiable is set as internal
    string favoriteNumberInText = "Five";
    int256 favoriteInt = -5; // int8. int16, etcc. default 256
    //address myAddress = 0x68742340474D0123442123461234f3a123455684;
    bytes32 favoriteBytes = "cat"; // string converted into by

    // create a mapping to facilitate search
    // Below we map string to a number (i.e name to favotite number)
    mapping(string => uint256) public nametoFavoriteNumber;

    // can create structure as well and how it is initialized
    struct People {
        uint256 favoriteNumber; //will index 0 in the struct
        string name; // will be index 1 in the struct
    }
    //define a array of people to have a list
    People[] public people;

    // People[3] - means max 3 people in the list
    //index 0: Jeremy, 1: Wenny

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // View and pure function does not modify the state of blockchain
    // Therefore it will not cost gas if called
    // Unless it is called from another function that is changing the state of blockchain
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // add new data in the list People[]
        // memory is needed to avoid compilation error
        // evm store data in memory, calldata and storage
        // calldata and memory are temparory data and only exisint for duration of the function
        // storage means data are permanent
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        people.push(newPerson);

        //create the mapping between name and number
        nametoFavoriteNumber[_name] = _favoriteNumber;
    }
}

// 0xd9145CCE52D386f254917e481eB44e9943F39138