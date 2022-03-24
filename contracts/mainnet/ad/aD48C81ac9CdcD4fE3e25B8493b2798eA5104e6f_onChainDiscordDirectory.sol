/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// On-Chain Directory by 0xInuarashi.eth
// Discord: 0xInuarashi#1234 | Twitter: https://twitter.com/0xInuarashi
// For use with Martian Market, and any other open interfaces built by anyone.

contract onChainDiscordDirectory {

    // On Chain Discord Directory
    mapping(address => string) public addressToDiscord;
    function setDiscordIdentity(string calldata discordTag_) external {
        addressToDiscord[msg.sender] = discordTag_;
    }

    // Your Twitter if you are adventurous
    mapping(address => string) public addressToTwitter;
    function setTwitterIdentity(string calldata twitterTag_) external {
        addressToTwitter[msg.sender] = twitterTag_;
    }
}