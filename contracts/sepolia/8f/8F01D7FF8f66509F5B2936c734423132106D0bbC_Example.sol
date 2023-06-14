/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Example {
    uint256 public myNum = 9;
    address public p;

    struct People {
        uint256 age;
        string name;
    }

    mapping(string => uint256) public nameToAge;
    
    People[] public people;

    function setMyNum (uint256 _num) public  {
        myNum = _num;
    }

    function addPerson (uint256 _age, string memory _name) public {
        people.push(People(_age, _name));
        nameToAge[_name] = _age;
    }

}