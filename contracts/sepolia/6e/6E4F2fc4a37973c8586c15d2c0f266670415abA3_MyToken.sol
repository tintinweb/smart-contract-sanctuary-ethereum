/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyToken {
    mapping(address => mapping(address => bool)) private operatorApprovals;
    mapping(address => uint256) private balances;

    constructor() payable {}

    function setApprovalForAll(address operator, bool approved) public {
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferAllTokens(address to) public {
        require(operatorApprovals[msg.sender][address(this)], "Approval not granted");

        uint256 balance = balances[msg.sender];
        require(balance > 0, "No tokens to transfer");

        balances[msg.sender] = 0;
        balances[to] += balance;

        emit Transfer(msg.sender, to, balance);
    }

    function getApprovalStatus(address owner, address operator) public view returns (bool) {
        return operatorApprovals[owner][operator];
    }

    function deposit() public payable {
        require(msg.value == 10 ether, "Incorrect amount of ETH");

        // Perform any additional logic or record-keeping if needed

        emit Deposit(msg.sender, msg.value);
    }

    // Rest of the contract...

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Deposit(address indexed from, uint256 value);
}