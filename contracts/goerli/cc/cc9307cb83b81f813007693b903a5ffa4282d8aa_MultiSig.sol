/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title MultiSig
*/
contract MultiSig {
    address[] public owners;
    mapping(address=>bool) isOwner;
    
    mapping(uint=>Transaction) transactions;
    uint numTransactions;


    struct Transaction{
        address destination;
        uint value;
        bool executed;
        uint confirmCount;
        mapping(address=>bool) confirmedBy;
    }

    struct TransactionView{
        address destination;
        uint value;
        bool executed;
        uint confirmCount;
    }

    event TransactionRequest(address owner);
    event TransactionConfirm(address owner);
    event TransactionExecuted(uint transactionId);

    modifier ownerExists() {
        require(isOwner[msg.sender], "Caller is not owner");
        _;
    }
    
    modifier ownerDoesNotExists() {
        require(!isOwner[msg.sender], "Owner already exists");
        _;
    }

    modifier transactionExist(uint transactionId) {
        require(transactionId < numTransactions);
        _;
    }

    modifier notConfirmed(uint transactionId) {
        require(!transactions[transactionId].confirmedBy[msg.sender]);
        _;
    }

    constructor(address[] memory _owners) {
        owners = _owners;
        for(uint i =0; i < owners.length; i++) {
            isOwner[owners[i]] = true;
        }
    }

    function requestTransaction(address destination, uint value)
        public
        ownerExists
    {
        Transaction storage t = transactions[numTransactions++];
        t.destination = destination;
        t.value = value;
        t.executed = false;
        t.confirmCount = 0;
        emit TransactionRequest(msg.sender);
        confirmTransaction(numTransactions-1);
    }

    function confirmTransaction(uint transactionId)
        public 
        ownerExists
        notConfirmed(transactionId)
    {
        require(transactionId < numTransactions, "Transaction does not exist");
        transactions[transactionId].confirmCount++;
        transactions[transactionId].confirmedBy[msg.sender] = true;
        emit TransactionConfirm(msg.sender);
        executeTransaction(transactionId);
    }

    function executeTransaction(uint transactionId)
        public
        ownerExists
        transactionExist(transactionId)
    {
        require(!transactions[transactionId].executed);
        if(transactions[transactionId].confirmCount >= (owners.length+1)/2) {
            payable(transactions[transactionId].destination).transfer(transactions[transactionId].value);
            transactions[transactionId].executed = true;
            emit TransactionExecuted(transactionId);
        }
    }


    function getOwners() public view returns(address[] memory){
        return owners;
    }

    function getTransaction(uint transactionId)
        public
        view
        transactionExist(transactionId)
        returns(TransactionView memory)
    {
        Transaction storage t = transactions[transactionId];
        return TransactionView({destination:t.destination, value:t.value, executed:t.executed, confirmCount:t.confirmCount});
    }

    receive() external payable{}
}