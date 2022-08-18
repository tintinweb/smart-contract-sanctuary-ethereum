/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    struct Person {
        uint256 number;
        string name;
    }

    mapping(string => uint256) public peopleMap;

    Person[] public people;

    Person public peep = Person({number: 356, name: "Ankur"});

    function returnVal() public view returns (string memory) {
        return peep.name;
    }

    function returnName(string calldata _name) public view returns (uint256) {
        return peopleMap[_name];
    }

    function addPerson(uint256 _number, string calldata _name) public {
        peopleMap[_name] = _number;
        people.push(Person(_number, _name));
    }
}