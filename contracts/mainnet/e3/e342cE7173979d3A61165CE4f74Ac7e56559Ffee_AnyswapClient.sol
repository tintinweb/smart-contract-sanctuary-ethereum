/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IAnyswapV4ERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

contract AnyswapClient {
    IAnyswapV4ERC20 private anyswapBridge;

    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    constructor(IAnyswapV4ERC20 _anyswapBridge) {
        anyswapBridge = _anyswapBridge;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        anyswapBridge.deposit{value: msg.value}();
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        anyswapBridge.withdraw(amount);
        emit Withdrawal(msg.sender, amount);
    }

    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    function totalBalance() external view returns (uint256) {
        return address(this).balance;
    }
}