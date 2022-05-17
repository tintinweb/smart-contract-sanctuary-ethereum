/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface TokenTransfer { 
	function transferFrom(address from, address to, uint256 value) external returns (bool);
    function name() external returns (string memory);
    function symbol() external returns (string memory);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract ContractTransfer {
    address payable public owner;
    mapping (address => uint) supportTokens;
    mapping (address => mapping (address => uint)) accountAmounts;

    event Log(address from, string operation, string name, string symbol, uint256 amount);

    constructor() {
        owner = payable(msg.sender);
        address token = 0x13512979ADE267AB5100878E2e0f485B568328a4; // USDT
        supportTokens[token] = 1;
    }

    receive() external payable {}

    function deposit(address token, uint256 amount) external payable {
        require(supportTokens[token] == 1, "Token is not support");
        TokenTransfer tt = TokenTransfer(token);
        bool result = tt.transferFrom(msg.sender, address(this), amount);
        require(result, "Allowance or balance is not enough");
        accountAmounts[msg.sender][token] += amount;
        string memory name = tt.name();
        string memory symbol = tt.symbol();
        emit Log(msg.sender, "deposit", name, symbol, amount);
    }

    function withdraw(address token, uint256 amount) external payable {
        require(supportTokens[token] == 1, "Token is not support");
        require(accountAmounts[msg.sender][token] >= amount, "Balance is not enough");
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, amount));
        require(success, "Withdraw failed");
        accountAmounts[msg.sender][token] -= amount;
        TokenTransfer tt = TokenTransfer(token);
        string memory name = tt.name();
        string memory symbol = tt.symbol();
        emit Log(msg.sender, "withdraw", name, symbol, amount);
    }

    function getBalance(address sender, address token) external view returns (uint256) {
        return accountAmounts[sender][token];
    }
}