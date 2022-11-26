/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract SimpleStorage {
    uint256 example; //private number
    uint256 public number; //public number
    // Defining Struct
    struct People {
        uint256 age;
        string name;
    }
    People public person = People({name: "shivang", age: 25});

    // ARRAY In Solidity
    People[] public persons;
    uint256[] public numbers;
    People[3] public admin;

    // add People Funtion;
    function addPerson(string memory _name, uint256 _age) public {
        persons.push(People(_age, _name));
        // nameToAge[_name] = _age;
    }

    function store(uint256 _example) public virtual {
        example = _example;
    }

    function retrive() public view returns (uint256) {
        return example;
    }
    // pure and view function cost is null untill calling in a transaction.
}