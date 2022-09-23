// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

contract SimpleCounter {

    mapping (address => uint256) public currentCount;

    function IncrementCount() external  {
        currentCount[msg.sender]++;
    }

    function GetCurrentCount(address countOf) external view returns (uint256) {
        return currentCount[countOf];
    }
}