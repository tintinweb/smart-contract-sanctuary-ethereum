/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// This contract is modified from the tutorial Remix LearnEth tutorial, specifically
// "10.3 Transactions - Sending Ether"

// The Remix LearnEth tutorial can be found at
// https://remix.ethereum.org/?#activate=udapp,solidity,LearnEth&optimize=false&runs=200&evmVersion=null

contract Charity {
    // This allows the caller to send money to the smart contract, despite not actually having any
    // arguments or a function body.
    function donate() public payable { }

    // This allows the caller to withdraw the entire balance of the smart contract into their account.
    function withdraw() public {
        (bool sent,) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send ether.");
    }
    
    // This function doesn't need to exist, as you can just view the smart contract's balance directly.
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}