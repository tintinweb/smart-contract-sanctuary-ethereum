/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract Bank {
    struct Deposit {
        uint256 blockNumber;
        uint256 amount;
    }

    uint256 private bankBalance = 100000000000000000000;
    address private owner;
    mapping(address => Deposit) private deposits;
    mapping(address => uint256) private balances;
    uint256 RATE;

    constructor(uint256 rate) {
        owner = msg.sender;

        RATE = rate;
    }

    function setBalance(address member, uint256 amount) public {
        require(msg.sender == owner, "invalid user");

        balances[member] = amount;
    }

    function deposit(uint256 amount) external {
        require(deposits[msg.sender].amount == 0, "you have deposit already");
        require(balances[msg.sender] >= amount, "you dont have enough money");

        bankBalance += amount;
        balances[msg.sender] -= amount;
        deposits[msg.sender] = Deposit(block.number, amount);
    }

    function withdraw() external {
        require(deposits[msg.sender].amount > 0);
        
        uint256 amount = deposits[msg.sender].amount * (1 + RATE / 100 / 100 / 100 * (block.number - deposits[msg.sender].blockNumber));

        bankBalance -= amount;
        balances[msg.sender] += amount;
        deposits[msg.sender] = Deposit(0, 0);
    }

    function getMyBalance() external view returns(uint256) {
        return balances[msg.sender];
    }

    function getMyDepositAmount() external view returns(uint256) {
        return deposits[msg.sender].amount;
    }

    function getAnyDepositAmount(address member) external view returns(uint256) {
        require(msg.sender == owner, "invalid user");

        return deposits[member].amount;
    }

    function getAnyBalance(address member) external view returns(uint256) {
        require(msg.sender == owner, "invalid user");

        return balances[member];
    }

    function getBlockNumber() external view returns(uint256) {
        return block.number;
    }
}