/**
 *Submitted for verification at Etherscan.io on 2023-02-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lock {
    uint value;

    function initialize(uint val) external {
        value = val;
    }

    function get() external view returns(uint){
        return value *2;
    }
}