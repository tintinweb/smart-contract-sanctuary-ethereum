// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lock {
    string name;
    uint age;
    
    constructor() payable {
        name = "Prashant";
        age = 23;
    }

    function getName() public view returns (string memory){
        return name;
    }

    function getAge() public view returns (uint){
        return age;
    }

    function setAge() public {
        age = age +1;
    }
    
}