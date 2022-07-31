// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// Creating the contract object, and naming the contract
contract SimpleStorage {
    // this gets initialized to zero!
    // uint256 is a datatype: there is also bool, string, bytes32 etc.
    uint256 favoriteNumber;

    // this is a dictionary / mapping - when you give it a key (the string) it spits out the value (uint256)
    mapping(string => uint256) public nameToFavoriteNumber;

    // a new datatype we can create
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // an array
    People[] public people;

    // this function modifies the state of the blockchain
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view and pure functions don't modify the state of the blockchain
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata, memory, storage: different data locations in our functions
    // calldata and memory are temporary and only exist for the duration of the function
    // storage variables are permanent
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}