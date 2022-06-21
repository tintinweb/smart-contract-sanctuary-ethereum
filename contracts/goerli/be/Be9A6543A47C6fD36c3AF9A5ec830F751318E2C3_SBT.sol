// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract SBT {
    struct Token {
        address owner;
        string uri;
    }

    mapping(uint256 => Token) public tokens;

    uint256 private tokenId;

    function mint(string calldata uri) external {
        uint256 currentId = tokenId++;
        Token storage token = tokens[currentId];
        token.owner = msg.sender;
        token.uri = uri;
    }
}