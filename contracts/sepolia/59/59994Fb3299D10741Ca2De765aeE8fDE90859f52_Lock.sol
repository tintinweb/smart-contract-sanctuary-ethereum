// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lock {
    uint public num;


    constructor() payable {
    }
    function addNum (uint n) external returns(uint) {
        num +=n;
        return num;
    }

    function subNum (uint n) external returns(uint){
        require (num-n>0,"num > 0");
        num-=n;
        return num;
    }
}