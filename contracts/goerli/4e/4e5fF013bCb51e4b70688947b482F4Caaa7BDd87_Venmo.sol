// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Venmo {
    uint private transactionCount;
    uint private baseAmount;
    event TransactionMade(
        address from,
        address recipient,
        uint amount,
        string message,
        uint timestamp
    );

    struct Transaction {
        address from;
        address recipient;
        uint amount;
        string message;
        uint timestamp;
    }
    // array of transaction
    Transaction[] public transactions;

    constructor() {
        baseAmount = 0.01 ether;
        transactionCount = 0;
    }

    // create a transaction
    function createTransaction(
        address payable recipient,
        uint amount,
        string memory message
    ) public {
        require(amount >= baseAmount, "The amount is less than expected");
        transactionCount += 1;
        transactions.push(
            Transaction(msg.sender, recipient, amount, message, block.timestamp)
        );

        // emit transaction event
        emit TransactionMade(
            msg.sender,
            recipient,
            amount,
            message,
            block.timestamp
        );
    }

    // get All transactions
    function getAllTransactions() public view returns (Transaction[] memory) {
        return transactions;
    }

    // get number of transaction
    function getTransactionCount() public view returns (uint) {
        return transactionCount;
    }
}