// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

struct TransferStruct {
    address sender;
    address payable receiver;
    uint amount;
    string message;
    uint256 timestamp;
    string keyword;
}

contract Transactions {
    uint256 transactionCount = 0;

    TransferStruct[] transactions;

    event Transfer(
        address sender,
        address payable receiver,
        uint amount,
        string message,
        uint256 timestamp,
        string keyword
    );

    function addToBlockchain(
        address payable receiver,
        uint amount,
        string memory message,
        string memory keyword
    ) public {
        transactionCount += 1;
        transactions.push(
            TransferStruct(
                msg.sender,
                receiver,
                amount,
                message,
                block.timestamp,
                keyword
            )
        );
        emit Transfer(
            msg.sender,
            receiver,
            amount,
            message,
            block.timestamp,
            keyword
        );
    }

    function getAllTransactions()
        public
        view
        returns (TransferStruct[] memory)
    {
        return transactions;
    }

    function getTransactioncount() public view returns (uint256) {
        return transactionCount;
    }
}