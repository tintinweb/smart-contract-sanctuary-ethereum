/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    // this gets initialized to 0 by default
    // public creates a getter function for the variable automatically
    // public makes it visible in and out the contract
    // private is only accesible inside the contract
    // internal is accesible to contract and its children contracts
    // external is accesible only outside the contract
    // When no visibility keyword is set, it gets set to internal by default
    uint256 public number;

    // creating People type
    struct People {
        uint256 number;
        string name;
    }

    mapping(string => uint256) public nameToNumber;

    People[] public person;

    function store(uint256 _number) public virtual {
        number = _number;
    }

    // This fn is equivalent to the uint256 public number
    // view and pure do not cost gas. They only cost gas when called from inside a fn that cost gas.
    function retrieve() public view returns (uint256) {
        return number;
    }

    function addPerson(string memory _name, uint256 _number) public {
        person.push(People({number: _number,name: _name}));
        nameToNumber[_name] = _number;
    }

    
}