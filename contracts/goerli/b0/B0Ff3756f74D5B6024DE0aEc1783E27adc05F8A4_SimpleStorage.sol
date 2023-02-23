// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract SimpleStorage {
    // the variable gets initialised as 0
    uint256 num;
    Person[] public people;

    // creating a mapping to map every name to a number
    mapping(string => uint256) public nameToFavoriteNumber;

    // defining a custom data type to bundle up several data
    struct Person {
        string name;
        uint256 favNum;
    }

    function store(uint256 newNum) public virtual {
        num = newNum;
    }

    // Retrieving the stored variable
    function retrieve() public view returns (uint256) {
        return num;
    }

    // get the list of people
    function getPeople() public view returns (Person[] memory) {
        return people;
    }

    function addPerson(string memory _name, uint256 number) public {
        people.push(Person(_name, number));
        nameToFavoriteNumber[_name] = number;
    }
}