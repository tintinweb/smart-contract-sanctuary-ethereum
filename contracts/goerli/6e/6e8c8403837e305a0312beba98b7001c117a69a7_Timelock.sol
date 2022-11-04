// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Timelock {
     function checkLock(uint lockTimestamp) public view {
        require(lockTimestamp <= block.timestamp, "Function not yet executable");
     }
}