/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

// SPDX-License-Identifier: MIT
// ^--This is contract license, recommeded is MIT cuz it's free
pragma solidity ^0.8.0; //0.8 with any third point e.g. 0.9.1-0.8.9, but if it's 0.9, this code is unusable.

// Environment = Remix VM (Virtual Machine) let you try this without gas in this fake blockchain
// Account = To pay gas
// Value = value to transfer
// Contract -- normally, we write a contract per file, but sometimes, we have import statement too

// Deployed Contracts = deploy it into blockchain (place the vending machine)
// | - We can copy contract address
// | - 

contract HelloWorld { // Contract name = HelloWorld
    string public hello = "Hello, World"; // If we don't write 'public', it's private in default
    // hello button ~~ button of vending machine
}