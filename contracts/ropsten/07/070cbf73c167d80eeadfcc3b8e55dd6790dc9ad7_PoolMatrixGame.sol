/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

contract PoolMatrixGame {

    address public owner;
    uint256 balance;
    uint8 level;
    address referrer;

    event ContractCreated(string msg, address indexed owner);
    event TestEvent(string msg);
    event PaymentReceived(string msg, address indexed owner, address indexed sender, uint value);
    event Widthdrawn(string msg, uint amount, address indexed destAddr);
    event PrintBalanceEvent(string msg, uint256 balance, address indexed owner);
    event Fireslot(address indexed account, uint8 indexed level, uint256 amount);

    constructor() public {
        owner = msg.sender;
        emit ContractCreated("Contract has been created", owner);
    }

    receive() payable external {
        emit PaymentReceived("Payment received!", owner, msg.sender, msg.value);
        balance += msg.value;
    }

    function test() public {
        emit TestEvent("Hello world!");
    }

    function withdraw(uint amount, address payable destAddr) public {
        destAddr.transfer(amount);
        balance -= amount;
        emit Widthdrawn("Cost has been widhdrawn", amount, destAddr);
    }

    function printBalance() public {
        emit PrintBalanceEvent("Balance is:", balance, owner);
    }

    function getOwner() public view returns(address) {
        return owner;
    }

    function getBalance() public view returns(uint256) {
        return balance;
    }

    function buyFireslot(uint8 newLevel, address newReferrer) public payable {
        payable(msg.sender).transfer(msg.value / 4);
        referrer = newReferrer;
        level = newLevel;
        emit Fireslot(msg.sender, level, 1);
    }

    function getReferrer() public view returns(address) {
        return referrer;
    }

    function getLevel() public view returns(uint256) {
        return level;
    }
}