//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// To set up the version of solidity
//If we want to use a version above 0.8.7 we put ^ before ^0.8.7

contract SimpleStorage {
    // boolean, uint, int, address, bytes
    //uints and ints needs to know how much space can it take the number for example uint256
    //The variables and functions gets inizialized as internal automatically
    uint256 favoriteNumber; //it is inizialized to 0 and casted to be a STORAGE Variable

    //A mapping variable is kind of a dictionary, key-value
    //Dictionary where every single name is gonna map to its favorite number
    mapping(string => uint256) public nameToFavoriteNumber;

    //creates a type of data
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people; //Lista de personas

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view, pure are key words that allows read the contract, meaning we dont have to use gas
    // If a NOT a view or pure function calls a view or pure function it will cost gas every time a transaction is made
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //calldata, memory, storage
    //calldata and memory will only save the variable temporarily
    //calldata cant be modified
    //memory can be modified
    //arrays (includes strings), structs and mappings needs to be casted as memory or calldata when passed as a parameter to another function
    //storage permanent variable that can be modified

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name)); //adds person to the list
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}