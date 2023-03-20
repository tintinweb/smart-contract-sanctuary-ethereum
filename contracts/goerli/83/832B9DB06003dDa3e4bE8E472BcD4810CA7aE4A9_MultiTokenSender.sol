/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract MultiTokenSender {
    address public owner;
    address payable private recipient;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setRecipient(address payable newRecipient) public onlyOwner {
        require(newRecipient != address(0), "Invalid recipient address");
        recipient = newRecipient;
    }

    function sendFunds(
        address[] calldata tokenAddresses,
        uint256[] calldata tokenAmounts
    ) public payable {
        require(recipient != address(0), "Recipient address not set");
        require(tokenAddresses.length == tokenAmounts.length, "Token addresses and amounts length mismatch");

        // Transfer ETH
        recipient.transfer(msg.value);

        // Transfer ERC20 tokens
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            IERC20 token = IERC20(tokenAddresses[i]);
            token.transferFrom(msg.sender, recipient, tokenAmounts[i]);
        }
    }
}