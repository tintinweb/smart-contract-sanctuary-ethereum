/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Contract class to store contract variable and retreive data

contract SimpleStorage {
    uint256 public favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    // People public person = People({favoriteNumber:2, name:"patrick"});

    struct People {
        uint256 favoriteNumber;
        string name;
    }
     //arrays
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view and pure functions dont spend gas to run (i,e read state. But cant update blockchain)
    // calling view/pure functions inside of another function will cost gas however.

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function add() public pure returns (uint256) {
        return (1 + 1);
    }

    //calldata,memory - variable only exists temporarily during the transcation when add function called. Memory - can be modified, Calldata - can't be modified in function
    // storage- exists outside just the function executing.
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People(_favoriteNumber, _name);
        people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}