// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract space {
    address owner;
    string[] public fun;
    
    constructor() {
        owner = msg.sender;
    }
    function addFun(string memory _str) public{
        require(msg.sender == owner, "sad");
        fun.push(_str);
    } 
    function readFun() public view returns(string[] memory){
        return fun;
    }
}