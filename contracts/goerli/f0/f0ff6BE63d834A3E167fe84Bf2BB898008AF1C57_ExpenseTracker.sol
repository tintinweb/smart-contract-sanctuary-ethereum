// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ExpenseTracker {
    enum TransactionType {
        INCOME,
        EXPENSE
    }
    struct Transaction {
        TransactionType t_type;
        string t_disc;
        uint256 t_amount;
        uint256 t_date;
    }
    mapping(address => Transaction[]) private transactions;

    function addExpense(
        uint256 amount,
        string memory desc,
        uint256 date
    ) public {
        transactions[msg.sender].push(Transaction(TransactionType.EXPENSE, desc, amount, date));
    }

    function addIncome(
        uint256 amount,
        string memory desc,
        uint256 date
    ) public {
        transactions[msg.sender].push(Transaction(TransactionType.INCOME, desc, amount, date));
    }

    function getUserTransactions() public view returns (Transaction[] memory) {
        return transactions[msg.sender];
    }

    function getUserTransactionsLen() public view returns (uint256) {
        return transactions[msg.sender].length;
    }
}