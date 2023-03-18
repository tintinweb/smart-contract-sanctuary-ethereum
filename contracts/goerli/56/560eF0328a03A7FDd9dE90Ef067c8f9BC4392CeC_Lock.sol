/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lock {
   
   event Verified(address indexed sender);
   function Verify() public {
        // Todo
        emit Verified(msg.sender);
   }
}