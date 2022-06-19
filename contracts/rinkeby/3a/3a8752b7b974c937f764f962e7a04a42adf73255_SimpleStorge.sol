/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract SimpleStorge{
    uint256 favariteNumber;
    struct People{
        uint256 favariteNumber;
        string name;
    }
    People[] public people;
    mapping(string => uint256) nameToFavarteNumber;

    function store(uint256 _favariteNumber) public{
        favariteNumber = _favariteNumber;
    }
    function retrive() public view returns(uint256){
        return favariteNumber;
    }
    function addPerson(string memory _name, uint256 _favariteNumber) public {
        people.push(People(_favariteNumber, _name));
        nameToFavarteNumber[_name] = _favariteNumber;
    }
}