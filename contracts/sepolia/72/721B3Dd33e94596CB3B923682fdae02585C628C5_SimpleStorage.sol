// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage{
    
    uint256 index;

    struct Person {
        string name;
        uint256 age;
    }

    mapping (uint256 => string) indexToName;

    Person[] public personArray;

    address public owner;

    address public contractAddress = address(this);

    constructor () {
        owner = msg.sender;
    }

    function getContractAddress() public view returns(address) {
        return contractAddress;
    }

    function createPerson(string memory _name, uint256 _age) public {
        personArray.push(Person({name:_name, age:_age}));
        indexToName[personArray.length - 1] = _name;
    }

}