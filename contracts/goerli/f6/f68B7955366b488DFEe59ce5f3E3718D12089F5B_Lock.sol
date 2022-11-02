// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lock {
    // Your balance
    uint256 public balance = 0;

    // This function gives you 10 dollar =)
    function getMoney() public {
        balance += 10;
    }
}