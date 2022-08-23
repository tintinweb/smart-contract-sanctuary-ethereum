// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract TheMerge {
    function whatsTheTTD() public view returns (uint256) {
        uint256 TTD = block.difficulty;
        return TTD;
    }
}