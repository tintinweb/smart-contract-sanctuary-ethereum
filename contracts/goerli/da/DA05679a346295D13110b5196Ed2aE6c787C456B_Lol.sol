// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lol {
    uint public number;

    constructor(uint _num) {
        number = _num;
    }

    function changeNum(uint _num) external {
        number = _num;
    }
}