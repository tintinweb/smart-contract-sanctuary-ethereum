/**
 *Submitted for verification at Etherscan.io on 2022-10-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; // version of solidity to be used but we can use higher versions

contract SimpleStorage {
    // default value is zero when no number is stated
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    //uint256[] public favoriteNumberList;
    People[] public people;

    //to enable a function to be overriden in another contract we need to add the virtual keyword
    function store(uint256 _favouriteNumber) public virtual {
        favoriteNumber = _favouriteNumber;
    }

    // view function allows read from state(to read from the contract) but you cant update the contract with a view function
    // view and pure functions when called dont use gas
    // pure function also dont allow modification of state, you also can not read from the block chain
    // the returns keyword states what would be retrived when the function is called
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata, memory, storage
    // calldata and memory means that the data will exist tempoary, if the name of the parameter is not going to be modified then it can be calldata or memory
    // calldata is tempory data that cant be modified
    // memory is tempoary data that can be modified
    // storage exist outside the function like the favoriteNumber above
    // struct, mappings and arrays need to have either calldata or memory when adding them to different functions
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavoriteNumber[_name] = _favouriteNumber;
    }
}