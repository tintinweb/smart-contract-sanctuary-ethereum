/**
 *Submitted for verification at Etherscan.io on 2022-03-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract MultiSigWallet {
    event Deposit(address sender, uint amount, uint balance);
    event Approval(address approver, uint txId);
    event Submit(address submitter, uint txId);
    event Execute(address executor, uint txId);
    event Sent(address receiver, uint amount);

    uint public transactionCount;
    uint requiredApproval;

    address[] public owners;
    mapping (address => bool) public isOwner;


    modifier onlyOwner() {
        require(isOwner[msg.sender], "Only owners can call function");
        _;
    }

    modifier isUniqueApproval(uint txId) {
        require(!approved[txId][msg.sender], "You have already approved this transaction");
        _;
    }

    modifier transactionExists(uint txId) {
        require(transactionExist[txId], "Transaction does not exist");
        _;
    }

    modifier isNotExecuted(uint txId) {
        Transaction memory transaction = transactions[txId];
        require(!transaction.executed, "Transaction does not exist");
        _;
    }

    struct Transaction {
        address receiverAddress;
        uint confirmations;
        uint amount;
        bool executed;
    }

    mapping(uint => bool) transactionExist;
    mapping(uint => Transaction) public transactions;
    mapping(uint => mapping(address => bool)) approved;

    

    constructor(address[] memory addresses, uint required) {
        require(addresses.length >= 3, "Owners array is too short");
        require(required == addresses.length - 1, "Length of addresses minus 1 must be equal to required");

        requiredApproval = required;

        for(uint i; i < addresses.length; i++) {
            owners.push(addresses[i]);
            isOwner[addresses[i]] = true;
        }
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submit(address receiverAddress) external payable onlyOwner {
        require(address(this).balance >= msg.value, "Insufficient funds");

        transactionCount ++;
        transactions[transactionCount] = Transaction(receiverAddress, 0, msg.value, false);
        emit Submit(msg.sender, transactionCount);
    }

    function approve(uint txId) external transactionExists(txId) onlyOwner isUniqueApproval(txId) isNotExecuted(txId) {
        approved[txId][msg.sender] = true;
        Transaction storage transaction = transactions[txId];
        transaction.confirmations ++;
        emit Approval(msg.sender, txId);
    }

    function execute(uint txId) external onlyOwner transactionExists(txId) isNotExecuted(txId){
        Transaction storage transaction = transactions[txId];

        require(transaction.amount <= address(this).balance, "Insufficient funds");
        require(transaction.confirmations >= requiredApproval, "Transaction not fully approved");

        transaction.executed = true;
        (bool success, ) = transaction.receiverAddress.call{ value: transaction.amount}("");

        require(success, "Transaction unsuccessful");

        emit Execute(msg.sender, txId);
        emit Sent(transaction.receiverAddress, transaction.amount);
    }

    function getBalance() external view onlyOwner returns(uint balance) {
        balance = address(this).balance;
    }
}