/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.7; // 0.8.12 ^ is anything greater than0.8.7 would work 


//contract is like a class
contract simpleStorage {
    // boolean, uint, int, address, byte -> data types 
    // uint256 favoriteNumber; is initializing it as 0 

    // string is mapped to number
    mapping(string => uint256) public nameToAge;
    mapping(uint256 => string) public ageToName;

    struct People {
        string name;
        uint256 age;
    }

    // call uint 256 is the numbering of list
    // [3] -> fixed amount 
    // set it as public for it to be visible as a getter function
    People[] public person; 

    // change value of favoriteNumber
    // local variables can only be viewed in the scope of function
    // store info: stack, memory, storage, calldata, code, logs
    // calldata: temporarily variable cannot be modified 
    // memory: temporarily variable can be modified 
    // storage: permanent variable can be modified
    function addPerson(string memory _name, uint _age) public {
        person.push(People(_name, _age));
        nameToAge[_name] = _age; // map name to age
        ageToName[_age] = _name;
    }
    
    // view, pure -> no gas just viewing
    // function getAllName() external view returns(People[]) {
    //     return person;

    // }
}