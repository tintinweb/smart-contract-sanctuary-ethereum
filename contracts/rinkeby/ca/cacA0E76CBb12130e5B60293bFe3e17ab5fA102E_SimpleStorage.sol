// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 myNumber;
    string myString;
    // address public conAddress = address(this);
    struct Person {
        string name;
        uint256 age;
    }

    Person[] public people;
    mapping(string => uint256) public nameToAge;

    function storeNumber(uint256 _updateNumber) public {
        myNumber = _updateNumber;
    }

    function storeString(string memory _upadeString) public {
        myString = _upadeString;
    }

    function retrieveNum() public view returns (uint256) {
        return myNumber;
    }

    function retrieveString() public view returns (string memory) {
        return myString;
    }

    function addPerson(string memory _name, uint256 _age) public {
        Person memory pelumi = Person({name: _name, age: _age});
        people.push(pelumi);
        nameToAge[_name] = _age;
    }
}