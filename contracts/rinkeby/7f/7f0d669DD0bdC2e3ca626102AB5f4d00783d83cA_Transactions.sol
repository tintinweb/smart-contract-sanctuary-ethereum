/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Transactions {
    address private owner;
    uint256 transactionCounts;
    mapping (address => uint) balanceOf;

    event Transfer(address indexed sender, address indexed receiver, uint256 amount, string remark, uint256 timestamp);

    struct TransferStruct {
        address sender;
        address receiver;
        uint256 amount;
        string remark;
        uint256 timestamp;
    }
    
    TransferStruct[] transactions;

    constructor() {
        owner = msg.sender;
        balanceOf[tx.origin] = msg.sender.balance;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function sendMoney(address payable receiver, uint256 amount, string memory remark) public returns(bool success) {
        if (balanceOf[owner] < amount) return false;
        balanceOf[owner] -= amount;
        balanceOf[receiver] += amount;

        transactionCounts += 1;
        transactions.push(
            TransferStruct(
                owner,
                receiver,
                amount,
                remark,
                block.timestamp
            )
        );

        emit Transfer(msg.sender, receiver, amount, remark, block.timestamp);
        return true;
    }

    function getBalance(address addr) public view returns(uint) {
        return balanceOf[addr];
    }

    function getAllTransactions() public view returns(TransferStruct[] memory) {
        return transactions;
    }

    function getTransactionsCount() public view returns(uint256) {
        return transactionCounts;
    }
}