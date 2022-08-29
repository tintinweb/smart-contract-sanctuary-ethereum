// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Transactions {
    uint256 private transactionsCount;

    event Tranfer(
        address from,
        address to,
        uint amount,
        string message,
        uint256 transferTime,
        string keyword
    );

    struct Transaction {
        address sender;
        address receiver;
        uint256 amount;
        string message;
        uint256 transferTime;
        string keyword;
    }

    Transaction[] public transactions;

    function addTransaction(
        address payable _to,
        uint256 _amount,
        string calldata _message,
        string calldata _keyword
    ) public {
        transactionsCount += 1;
        transactions.push(
            Transaction(
                msg.sender,
                _to,
                _amount,
                _message,
                block.timestamp,
                _keyword
            )
        );
        emit Tranfer(
            msg.sender,
            _to,
            _amount,
            _message,
            block.timestamp,
            _keyword
        );
    }

    function getAllTransactions() external view returns (Transaction[] memory) {
        return transactions;
    }

    function getTransactionCount() external view returns (uint256) {
        return transactionsCount;
    }
}