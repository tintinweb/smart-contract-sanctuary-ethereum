// SPDX-License-Identifier: GPL-3.0
pragma solidity  ^0.8.10;

//import "hardhat/console.sol";
contract Counter{
    address public owner;
    uint public counter;
    constructor(uint x){
        owner = msg.sender;
        counter = x;
    }
    /*
        添加owner权限校验
    */
    function add(uint x) public returns(uint){
        require(owner == msg.sender,"not owner!");
        counter = counter + x;
        return counter;
    }
    
    function count() external returns(uint){
        require(owner == msg.sender,"not owner!");
        counter = counter + 1;
        //console.log(counter);
        return counter;
    }
    

   
}