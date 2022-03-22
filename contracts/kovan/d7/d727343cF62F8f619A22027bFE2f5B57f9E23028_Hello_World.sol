/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

pragma solidity ^0.6.0;


// SPDX-License-Identifier: MIT


contract Hello_World{
    string public greeting;

    constructor() public{
        greeting = "Hello World!";
    }

    function setGreeting(string memory _greeting) public returns(bool success){
        greeting = _greeting;
        return true;
    }

    function getGreeting()  public view returns (string memory _greeting, uint _length){
        return (greeting, bytes(greeting).length); //to test multivariable outputs
    }  

}