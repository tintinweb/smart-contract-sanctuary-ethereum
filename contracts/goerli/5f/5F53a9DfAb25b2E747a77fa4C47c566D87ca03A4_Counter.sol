// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Counter {
    uint public counter;

    constructor(uint value) {
        counter = value;
    }

    function count() public {
        counter += 1;
    }

    function set(uint value) public {
        counter += value;
    }
    
    function double() public {
        counter *= 2;
    }
}