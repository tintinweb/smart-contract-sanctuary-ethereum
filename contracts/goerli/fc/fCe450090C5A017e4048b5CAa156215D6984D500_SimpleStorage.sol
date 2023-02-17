// SPDX-License-Identifier: MIT
// First, I need to choose a version of Solidity
pragma solidity 0.8.14;

// contract is similar to a class
contract SimpleStorage {
    // This gets initialized to zero!
    // If I didnt set public, i wouldnt be able to see a result, cuz without public keyword, it wil be automatically set to internal
    // uint256 public favouriteNumber;

    uint256 favouriteNumber;

    // Mapping in solidity (similar to dictionary, keys with value)
    // Syntax similar to JS
    mapping(string => uint256) public nameToFavoriteNumber;

    // Struct in solidity (creating a new type), like an object in JS

    People public person = People({favouriteNumber: 2, name: "Jack"});

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    // Array in solidity (storing list or sequence of different types)
    // uint256 public favoriteNumbersList
    // Since it is public and it is variable, it is automatiaclly given a view function
    People[] public people; // this is dynamic array, cuz there is no limitation of length where as i put a number in [], [3], it becomes fixed-sized array

    // Function for adding people into an array
    // calldata, memory storage
    // calldata - temporary immutable variable
    // memory - temporary mutable variable
    // storage - permanent vars, mutable
    // String are array of bytes, and in solidity, cuz its an array (under the hood), we need memory when putting string vars in function parameters!
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        // Two ways of doing this
        //   people.push(People(_favouriteNumber, _name));
        // People memory newPerson = People(_favouriteNumber, _name);
        people.push(People(_favouriteNumber, _name));
        // add to mapping too
        // when mapping, all values are initially zero
        nameToFavoriteNumber[_name] = _favouriteNumber;
    }

    // here, adding virtual in order for this function to be modified
    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
        //    add();
    }

    // view and pure functions, when called alone, do not spend gas! They dont allow modification of state, just reading of it.
    // But, if i call a view or pure functions inside the ones that costs gas, I'll pay a gas fee for that specific function
    // returns (type) is just like in haskell, returns only specified type, or error
    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    // function add() public pure returns (uint256){
    //     return(1+1);
    // }
}

// 0xd9145CCE52D386f254917e481eB44e9943F39138