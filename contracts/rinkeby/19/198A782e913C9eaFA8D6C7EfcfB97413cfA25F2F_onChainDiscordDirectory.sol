/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract onChainDiscordDirectory {

    mapping(address => string) public addressToDiscord;
    function setDiscordIdentity(string calldata discordTag_) external {
        addressToDiscord[msg.sender] = discordTag_;
    }

    mapping(address => string) public addressToTwitter;
    function setTwitterIdentity(string calldata twitterTag_) external {
        addressToTwitter[msg.sender] = twitterTag_;
    }
}