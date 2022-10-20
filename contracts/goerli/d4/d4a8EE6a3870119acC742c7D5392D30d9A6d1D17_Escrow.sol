/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Escrow {
    mapping(address => uint256) public deposits;

    function lend() external payable {
        deposits[msg.sender] += msg.value;
    }
}