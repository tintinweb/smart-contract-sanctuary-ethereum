// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
// errors
error Venmo__UnableToUpdateBaseAmount();

contract Venmo {
    uint private transactionCount;
    uint private baseAmount;
    address private owner;
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

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can interact with");
        _;
    }
    modifier notOnlyOnwner() {
        require(msg.sender != owner, "Can call not by owner");
        _;
    }

    constructor() {
        baseAmount = 0.01 ether;
        transactionCount = 0;
        owner = msg.sender;
    }

    // create a transaction
    function createTransaction(
        address payable recipient,
        uint amount,
        string memory message
    ) public notOnlyOnwner {
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

    // update baseAmount
    function setNewBaseAmount(uint256 _baseAmount) public onlyOwner {
        if (_baseAmount <= 0) {
            revert Venmo__UnableToUpdateBaseAmount();
        }
        baseAmount = _baseAmount;
    }
}