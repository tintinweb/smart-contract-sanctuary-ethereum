//SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.9.0;

contract SimpleStorage {
    // a small function to store numbers

    uint256 number;

    // this function is to store the new number
    function storeNumber(uint256 newNumber) public {
        number = newNumber;
    }

    // this function is to view the number
    function viewNumber() public view returns (uint256) {
        return number;
    }

    struct Person {
        uint256 personId;
        string personName;
    }
    Person[] public arrayOfPerson;

    mapping(string => uint) public personMapping;

    function addPerson(uint256 id, string memory name) public {
        arrayOfPerson.push(Person({personId: id, personName: name}));
        personMapping[name] = id;
    }
}