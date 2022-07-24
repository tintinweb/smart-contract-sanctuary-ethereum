/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Wallet {
    address[] private approvers;
    uint private quorum;
    struct Transaction {
        uint id;
        uint amount;
        address payable to;
        uint approvals;
        bool sent;
    }
    Transaction[] private transactions;
    mapping(address => mapping(uint => bool)) private approvals;

    event Log(uint amount, uint gas);

    constructor(address[] memory _approvers, uint _quorum) {
        approvers = _approvers;
        quorum = _quorum;
    }

    function getApprovers() external view returns(address[] memory) {
        return approvers;
    }

    function getQuorum() external view returns(uint) {
        return quorum;
    }

    function getTransactions() external view returns(Transaction[] memory) {
        return transactions;
    }
	
	function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    /* 
     * For functions you only need to specify the location for dynamic data types (like arrays and bytes). 
     * Variables created in a function are by default memory.
     */
    function createTransaction(uint amount, address payable to) external onlyApprovers() {
        transactions.push(
            Transaction(
                transactions.length,
                amount,
                to,
                0,
                false
            )
        );
    }

    function approveTransaction(uint id) external payable onlyApprovers() {
        require(transactions[id].sent == false, 'Transfert has already been sent');
        require(approvals[msg.sender][id] == false, 'Cannot approve transfert twice');

        approvals[msg.sender][id] = true;
        transactions[id].approvals++;

        if(transactions[id].approvals >= quorum) {
            transactions[id].sent = true;
            address payable to = transactions[id].to;
            uint amount = transactions[id].amount;
            // The function built-in transfer define and emit the relative event automatically.
            to.transfer(amount);
        }
    }

    receive() external payable {
        emit Log(msg.value, gasleft());
    }

    modifier onlyApprovers() {
        bool allowed = false;
        for(uint i=0; i<approvers.length; i++) {
            if(msg.sender == approvers[i]) {
                allowed = true;
                break;
            }
        }

        require(allowed == true, 'Only approver allowed');
        _;
    }

}