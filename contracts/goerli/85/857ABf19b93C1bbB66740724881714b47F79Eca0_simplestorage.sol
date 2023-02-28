//This below is the license
// SPDX-License-Identifier: MIT

//use solidity version 0.8.7 or above
pragma solidity ^0.8.0;

//create a contract called simplestorage
contract simplestorage {
    //declare a positive number
    uint public number;

    // store a value in the variable number
    function store(uint _number) public {
        number = _number;
    }

    //view the value stored in "number" variable
    function retrieve() public view returns (uint) {
        return number;
    }

    //create a new type
    struct Person {
        uint number;
        string name;
    }

    //create an array of Person type
    Person[] public persons;

    //create a mapping
    mapping(string => uint) public nameTonumber;

    //add an entry of type Person
    function addPerson(string memory _name, uint _number) public {
        persons.push(Person(_number, _name));

        //mapping the entry "number" and "name"
        nameTonumber[_name] = _number;
    }
}