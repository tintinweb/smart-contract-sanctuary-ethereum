/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// On-Chain Directory (Solana) by 0xInuarashi.eth
// Discord: 0xInuarashi#1234 | Twitter: https://twitter.com/0xInuarashi
// For use with Martian Market, and any other open interfaces built by anyone.

contract onChainSolanaDirectory {

    // On Chain Solana Directory
    mapping(address => string) public addressToSolana;
    function setSolanaIdentity(string calldata solana_) external {
        addressToSolana[msg.sender] = solana_;
    }
}