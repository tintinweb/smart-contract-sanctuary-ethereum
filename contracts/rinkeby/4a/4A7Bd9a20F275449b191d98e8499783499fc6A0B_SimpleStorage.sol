//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.8;

contract SimpleStorage {

    uint256 favNum;

    struct Person {
        uint256 favNum;
        string name;
    }

    Person[] public people;

    mapping(string => uint256) public favNums;

    function store(uint256 _favNum) public {
        favNum = _favNum;
    }

    function retrieve() public view returns (uint256) {
        return favNum;
    }

    function addPerson(string memory _name, uint256 _favNum) public {
        people.push(Person(_favNum, _name));
        favNums[_name] = _favNum;
    }
}