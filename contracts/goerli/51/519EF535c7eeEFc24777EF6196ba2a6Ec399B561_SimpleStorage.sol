/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    // public variables create getter fxns - meaning it creates fxns with view status
    uint favouriteNumber;
    People public person = People({_favouriteNumber: 2, _name: "Patrick"});
    mapping(string => uint) public findingFavouriteNumbers;

    // We use the struct keyword, to create a new data type in solidity
    // The below example creates a new type (object) which holds two values (name, and favouriteNumber)
    // We then use the People object manually in the variables section above
    struct People {
        uint _favouriteNumber;
        string _name;
    }

    //creating arrays - a data type that is used to hold a sequence of objects
    // uint256[] favouriteNumbersList
    People[] public people;

    //People[3] - means our array will be fixed with 3 items. So leave it empty to get a dynamic array instead of a fixed-size array.

    // most important Ethereum EVM storages - calldata, memory, and storage
    // memory vars can be modified
    // calldata vars can also be modified
    // storage vars can also be modified, but they have global scope.
    function addPerson(string memory _userName, uint256 _userFavouriteNumber)
        public
    {
        People memory newPerson = People({
            _favouriteNumber: _userFavouriteNumber,
            _name: _userName
        });
        people.push(newPerson);
        findingFavouriteNumbers[_userName] = _userFavouriteNumber;
        // people.push(People(_favouriteNumber, _name);
    }

    // solidity mapping

    function store(uint _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    // view, pure keywords help us to only read state.
    // you cannot update the blockchain with a view function it diallows any modification of state.
    // pure functions do same, but also disallows reading other vars from the blockchain.
    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }
}

// 0xd9145CCE52D386f254917e481eB44e9943F39138

// warnings won't stop your code from working