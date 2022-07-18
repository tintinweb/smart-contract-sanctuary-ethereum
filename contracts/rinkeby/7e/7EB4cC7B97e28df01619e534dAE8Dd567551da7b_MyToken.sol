// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract MyToken  {

    uint private age;

    constructor(uint _age){
        age = _age;
    }

    function setAge(uint _age) public {
        age = _age;
    }

    function getAge() public view returns(uint){
        return age;
    }
     
}