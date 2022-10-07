/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lock {
    uint c =10;

    function add_value(uint a, uint b) public pure returns(uint){
        return a+b;
    }

    function add_value_constant(uint a) public view returns(uint){
        return a+c;
    }

}