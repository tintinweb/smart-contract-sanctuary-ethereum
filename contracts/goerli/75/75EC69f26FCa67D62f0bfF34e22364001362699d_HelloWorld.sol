// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract HelloWorld{
    string Hello;
    constructor(){
        Hello = "nasilsin";
    }
    
    function helloWorld() public view returns(string memory) {
        return Hello;
    }
}