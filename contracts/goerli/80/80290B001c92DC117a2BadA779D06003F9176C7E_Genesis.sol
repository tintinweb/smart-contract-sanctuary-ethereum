// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Genesis {
    address[] public owners;
    uint public transactionCount;
    uint public required;

    struct Transaction {
        address payable destination;
        uint value;
        bool executed;
    }

    mapping(uint => Transaction) public transactions;
    mapping(uint => mapping(address => bool)) public confirmations;

    receive() payable external { }

    function getOwnerCount() public view returns (uint) {
        return owners.length;
    }

    function getTxDestination(uint transactionId) public view returns (address) {
        Transaction storage _tx = transactions[transactionId - 1];
        return _tx.destination; 
    }

    function getTxValue(uint transactionId) public view returns (uint) {
        Transaction storage _tx = transactions[transactionId - 1];
        return _tx.value; 
    }

    function executeTransaction(uint transactionId) public {
        require(isConfirmed(transactionId));
        Transaction storage _tx = transactions[transactionId];
        (bool success, ) = _tx.destination.call{ value: _tx.value }("");
        require(success);
        _tx.executed = true;
    }

    function isConfirmed(uint transactionId) public view returns(bool) {
        return getConfirmationsCount(transactionId) >= required;
    }

    function getConfirmationsCount(uint transactionId) public view returns(uint) {
        uint count;
        for(uint i = 0; i < owners.length; i++) {
            if(confirmations[transactionId][owners[i]]) {
                count++;
            }
        }
        return count;
    }

    function isOwner(address addr) private view returns(bool) {
        for(uint i = 0; i < owners.length; i++) {
            if(owners[i] == addr) {
                return true;
            }
        }
        return false;
    }

    function submitTransaction(address payable dest, uint value) external returns (uint _transactionId) {
        uint id = addTransaction(dest, value);
        confirmTransaction(id);
        _transactionId = id;
    }

    function confirmTransaction(uint transactionId) public {
        require(isOwner(msg.sender));
        confirmations[transactionId][msg.sender] = true;
        if(isConfirmed(transactionId)) {
            executeTransaction(transactionId);
        }
    }

    function addTransaction(address payable destination, uint value) public returns(uint) {
        transactions[transactionCount] = Transaction(destination, value, false);
        transactionCount += 1;
        return transactionCount - 1;
    }

    constructor(address[] memory _owners, uint _confirmations) {
        require(_owners.length > 0);
        require(_owners.length <= 5, "Ownly 5 Signers Allowed");
        require(_confirmations > 0);
        require(_confirmations <= _owners.length);
        owners = _owners;
        required = _confirmations;
    }
}