/**
 *Submitted for verification at Etherscan.io on 2023-03-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lock {
    event Test(bytes32 amount);

    function test(bytes32 amount) public {
        emit Test(amount);
    }
}