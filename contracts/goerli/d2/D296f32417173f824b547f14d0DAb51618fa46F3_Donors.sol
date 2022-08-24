// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

//A smart contract that accepts donations from people along with a withdrawal mechanism.

contract Donors {
    mapping (address => uint256) public _paymentsOf;
    mapping (address => uint256) public donationsBy;

    address payable public owner;
    uint256 public _balance;
    uint256 public withdrawn;
    uint256 public totalDonations = 0;
    uint256 public totalWithdrawal = 0;

    event Donation(uint256 id, address indexed to, address indexed from, uint256 amount, uint256 timestamp);

    event Withdrawal(uint256 id, address indexed to, address indexed from, uint256 amount, uint256 timestamp);

    constructor() {
        owner = payable(msg.sender);
    }

    function donate() payable public {
        require(msg.value > 0, "Your Donation cannot be zero!");

        _paymentsOf[msg.sender] += msg.value;
        donationsBy[msg.sender] += 1;
        _balance += msg.value;
        totalDonations++;

        emit Donation(totalDonations, address(this), msg.sender, msg.value, block.timestamp);
    }

    function withdraw(uint256 amount) external returns (bool) {
        require(msg.sender == owner, "Unauthorized! Get out of here!");
        require(_balance >= amount, "Insufficient balance.");

        _balance -= amount;
        withdrawn += amount;
        owner.transfer(amount);
        totalWithdrawal++;

        emit Withdrawal(totalWithdrawal, msg.sender, address(this), amount, block.timestamp);
        return true;
    }
}