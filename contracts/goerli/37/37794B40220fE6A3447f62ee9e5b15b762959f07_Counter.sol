// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Counter {
    uint public total;

    function add1() public returns(uint){
        total += 1;
        return total;
    }

    function addx(uint x) public returns(uint){
        total = total + x;
        return total;
    }
}