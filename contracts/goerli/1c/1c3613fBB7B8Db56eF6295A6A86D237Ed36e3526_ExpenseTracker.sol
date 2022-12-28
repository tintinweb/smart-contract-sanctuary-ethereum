// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ExpenseTracker {
    enum TransactionType {
        INCOME,
        EXPENSE
    }
    struct Transaction {
        string id;
        TransactionType ttype;
        string category;
        string description;
        uint256 amount;
        string date;
        bool is_deleted;
    }

    struct Tracker {
        uint total;
        uint deleted;
        string[] transactions;
    }
    mapping(address => mapping(string => Transaction)) private transactions;
    mapping(address => Tracker) private tracker;
    mapping(string => bool) private all_ids;

    function addExpense(
        string memory _id,
        uint256 _amount,
        string memory _description,
        string memory _date,
        string memory _category
    ) public {
        require(all_ids[_id] == false, "invalid id");
        transactions[msg.sender][_id] = Transaction(
            _id,
            TransactionType.EXPENSE,
            _category,
            _description,
            _amount,
            _date,
            false
        );
        tracker[msg.sender].total += 1;
        tracker[msg.sender].transactions.push(_id);
        all_ids[_id] = true;
    }

    function addIncome(
        string memory _id,
        uint256 _amount,
        string memory _description,
        string memory _date,
        string memory _category
    ) public {
        require(all_ids[_id] == false, "invalid id");
        transactions[msg.sender][_id] = Transaction(
            _id,
            TransactionType.INCOME,
            _category,
            _description,
            _amount,
            _date,
            false
        );
        tracker[msg.sender].total += 1;
        tracker[msg.sender].transactions.push(_id);
    }

    function deleteTransaction(string memory id) public {
        require(transactions[msg.sender][id].is_deleted == false, "transaction already deleted");
        transactions[msg.sender][id].is_deleted = true;
        tracker[msg.sender].deleted += 1;
    }

    function getUserTransactions() public view returns (Transaction[] memory) {
        string[] memory ids = tracker[msg.sender].transactions;

        uint total = tracker[msg.sender].total;
        uint deleted = tracker[msg.sender].deleted;
        uint n = total - deleted;

        Transaction[] memory res = new Transaction[](n);
        for (uint i = 0; i < n; i++) {
            Transaction memory t = transactions[msg.sender][ids[i]];
            if (t.is_deleted == false) {
                res[i] = t;
            }
        }
        return res;
    }

    function getUserTransactionsLen() public view returns (uint256) {
        return tracker[msg.sender].total - tracker[msg.sender].deleted;
    }
}