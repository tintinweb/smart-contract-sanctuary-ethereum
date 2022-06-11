// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract EnhancerContract {
    event EnhanceToken(uint256 indexed tokenId, address indexed walletAddress);
    function upgrade(uint256 _tokenId) external {
        emit EnhanceToken(_tokenId, msg.sender);
        // Check if the token is owned by the same owner
        // need the metadata
    }
}