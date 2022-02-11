// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Time {
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function conpareTime(uint256 min) public view returns (bool) {
        return getTime() <= block.timestamp + min * 1 minutes;
    }

    function checkAddTime(uint256 min) public view returns (uint256) {
        return block.timestamp + min * 1 minutes;
    }
}