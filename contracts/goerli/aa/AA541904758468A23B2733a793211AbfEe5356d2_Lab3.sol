// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lab3 {
    uint public unlockTime;
    address payable public owner;
    mapping(address => uint256) _balance;
    event Withdrawal(uint amount, uint when);

    constructor() payable {
        owner = payable(msg.sender);
        _balance[owner] = 100;
    }

    function withdraw(address token, uint256 amount) public {
        // Uncomment this line, and the import of "hardhat/console.sol", to print a log in your terminal
        // console.log("Unlock time is %o and block timestamp is %o", unlockTime, block.timestamp);
        require(_balance[token] >= amount, "You don't have enough balance.");
        _balance[token] -= amount;

    }

    function deposit(address token, uint256 amount) public {
        require(amount > 0, "You should deposit more than 0");
        _balance[token] += amount;
    }

    function checkBalance(address token) public view returns(uint256 Calldata){
        return _balance[token];
    }
}