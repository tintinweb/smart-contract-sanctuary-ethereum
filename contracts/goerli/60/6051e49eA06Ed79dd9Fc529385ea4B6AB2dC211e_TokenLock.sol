/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenLock {
    mapping(address => uint256) public lockedTokens;
    mapping(address => uint256) public lockTimestamp;

    function lockTokens(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(lockedTokens[msg.sender] == 0, "Tokens are already locked");

        // Lock the tokens for 1 day
        lockedTokens[msg.sender] = amount;
        lockTimestamp[msg.sender] = block.timestamp;
    }

    function claimTokens() external {
        require(lockedTokens[msg.sender] > 0, "No tokens to claim");
        require(block.timestamp >= lockTimestamp[msg.sender] + 1 days, "Tokens are still locked");

        uint256 amount = lockedTokens[msg.sender];
        lockedTokens[msg.sender] = 0;
        lockTimestamp[msg.sender] = 0;

        // Perform the transfer or any other action with the tokens
        // ...
    }
}