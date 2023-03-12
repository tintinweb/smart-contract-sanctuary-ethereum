// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Counter {
    uint public counter;

    function add1() public returns(uint){
        counter += 1;
        return counter;
    }

    function addx(uint x) public returns(uint){
        counter = counter + x;
        return counter;
    }
}