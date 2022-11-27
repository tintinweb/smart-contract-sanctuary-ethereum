/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Helloworld {
    uint256 public age = 20;
    string public name = "Proud"; //ถ้าไม่ใส่public จะเป็นprivate, internal
    // ไม่ใส่ถูกเก็บในBlock chainแล้ว นึกแม้จะยังไม่public
    address public deployer ;

    constructor(){
        deployer = msg.sender;
    }
    function setName(string memory newName) public{
        require(msg.sender == deployer,"You're not authorized");
        name = newName ;
    }
    

    // function setName(string memory newName) public{ //(string memory newName, uint256 newAge) 
    //     name = newName; 
    //     // age = newAge;
    // }
    // function setAge(uint256 newAge) public{
    //     age = newAge;

    // }
}