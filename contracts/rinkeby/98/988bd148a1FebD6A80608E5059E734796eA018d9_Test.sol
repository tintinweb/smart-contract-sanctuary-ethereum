// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Test {    
    function curretTimestamp() external view returns (uint256) {
        return block.timestamp;
    }
}