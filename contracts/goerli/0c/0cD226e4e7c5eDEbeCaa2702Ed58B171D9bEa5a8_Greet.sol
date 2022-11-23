/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Greet {
    string greet = "hello";

    function setGreetBye() external {
        greet = "bye";
    }

    function setGreetHello() external {
        greet = "hello";
    }

    function getGreet() external view returns (string memory) {
        return greet;
    }
}