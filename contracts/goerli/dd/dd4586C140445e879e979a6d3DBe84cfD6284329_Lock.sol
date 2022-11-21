/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// File: 1.sol


pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lock {
    uint private counter;

    constructor() {}

    function count() public {
        counter++;
    }

    function getCount() public view returns (uint) {
        return counter;
    }
}