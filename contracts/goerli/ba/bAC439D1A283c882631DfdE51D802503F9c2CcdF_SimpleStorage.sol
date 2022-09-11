/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage{

    uint256 public favNumber;
    
    Person public p1 = Person({number:101, name:"Rohit"});

    struct Person{
        uint256 number;
        string name;
    }

    Person[] public peoples;

    mapping(string => uint256) public nameToNumber;

    function store(uint256 _favNumber) public virtual{
         favNumber = _favNumber;
    }

    function restore() public view returns(uint256){
        return favNumber;
    }

    function addPerson(uint256 _number, string memory _name) public {
        
       /* Person memory newPerson = Person({number : _number, name : _name});
        peoples.push(newPerson);*/

        peoples.push(Person(_number,_name));
        nameToNumber[_name] = _number;
    }

}