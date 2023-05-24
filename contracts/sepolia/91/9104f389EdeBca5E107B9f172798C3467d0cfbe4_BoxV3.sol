// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract BoxV3 {
    uint public val;

    struct Person {
        string name;
        uint age;
    }

    Person[] public people;

    event logValue(string name, uint age);


    function inc() external {
        val += 1;
    }

    function addPerson(string memory _name, uint _age) public {
        Person memory newPerson = Person(_name, _age);
        people.push(newPerson);
        emit logValue(_name, _age);
    }

    function getPerson(uint _index) public view returns(string memory, uint) {
        require(_index < people.length, "invalid index");
        Person memory person = people[_index];
        return (person.name, person.age);
    }

}