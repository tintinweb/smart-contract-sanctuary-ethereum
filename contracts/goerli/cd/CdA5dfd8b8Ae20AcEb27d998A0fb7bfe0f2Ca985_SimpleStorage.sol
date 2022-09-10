/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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
/**
    lets see what are memory, storage or calldata there are different places where we can store the variables but this are common 
    1. calldata - it works like temporery we can't modify it over the course 
    2. memory - they can be modified
    3. storage - there scope is out on function also they also can be modified

    this all applicable only on arrays, mapping etc. 
    string is itself array behind the hood so here we use memory

 */
    function addPerson(uint256 _number, string memory _name) public {
        
       /* Person memory newPerson = Person({number : _number, name : _name});
        peoples.push(newPerson);*/

        peoples.push(Person(_number,_name));
        nameToNumber[_name] = _number;
    }

}

// contract address : 0xCdA5dfd8b8Ae20AcEb27d998A0fb7bfe0f2Ca985