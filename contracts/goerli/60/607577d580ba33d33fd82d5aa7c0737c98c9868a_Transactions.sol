/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title venmo 交易平台
/// @author Azure
/// @notice venmo交易平台交易处理合约
/// @dev 无
contract Transactions {
    //交易数量
    uint256 transactionCount;

    event Transfer(
        address from,
        address receiver,
        uint256 amount,
        string message,
        uint256 timestamp
    );

    // 我们将存储在链上的交易的结构
    struct Transaction {
        address sender;
        address receiver;
        uint256 amount;
        string message;
        uint256 timestamp;
    }

    //Array of transactions
    Transaction[] transactions;

    // Function to add a transaction to the blockchain with our struct.
    function addToBlockchain(
        address payable receiver,
        uint256 amount,
        string memory message
    ) public {
        require(receiver != address(0), "address invalid");
        transactions.push(
            Transaction(msg.sender, receiver, amount, message, block.timestamp)
        );
        transactionCount = transactionCount + 1;
        emit Transfer(msg.sender, receiver, amount, message, block.timestamp);
    }

    // function to get the number of transactions
    function getTransactionCount() public view returns (uint256) {
        return transactionCount;
    }

    //constructor
}