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

    modifier ownerExists() {
        require(isOwner[msg.sender], "Caller is not owner");
        _;
    }
    
    modifier ownerDoesNotExists() {
        require(!isOwner[msg.sender], "Caller is not owner");
        _;
    }

    modifier notConfirmed(uint transactionId) {
        require(!transactions[transactionId].confirmedBy[msg.sender]);
        _;
    }

    modifier enoughConfirmed(uint transactionId) {
        require(transactions[transactionId].confirmCount >= owners.length/2);
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    constructor(address[] memory _owners) {
        owners = _owners;
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
    }

    function confirmTransaction(uint transactionId)
        public 
        ownerExists
        notConfirmed(transactionId)
    {
        transactions[transactionId].confirmCount++;
        transactions[transactionId].confirmedBy[msg.sender] = true;
    }

    function executeTransaction(uint transactionId)
        public
        ownerExists
        enoughConfirmed(transactionId)
        notExecuted(transactionId)
    {
        payable(transactions[transactionId].destination).transfer(transactions[transactionId].value);
        transactions[transactionId].executed = true;
    }

    receive() external payable{}
}