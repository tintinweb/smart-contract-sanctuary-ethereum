// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 faveNumber;

    struct People {
        uint256 faveNumber;
        string name;
    }

    People[] public people;
    mapping(string => uint256) public nameToFaveNumber;

    function store(uint256 _faveNumber) public {
        faveNumber = _faveNumber;
    }

    function retrieve() public view returns (uint256) {
        return faveNumber;
    } 

    function addPerson(string memory _name, uint256 _faveNumber) public {
        //  add new person with faveNumber to Person List
        people.push(People(_faveNumber, _name));
        nameToFaveNumber[_name] = _faveNumber;
    }
}