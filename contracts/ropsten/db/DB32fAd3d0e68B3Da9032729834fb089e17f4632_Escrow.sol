/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Escrow {

    address owner;
    uint public txnId;

    struct Transaction {
        address payable creator;
        address authorisor;
        address payable recipient;
        uint amount;
    }
    mapping (uint => Transaction) public escrowed_txn;
    Transaction transaction;

    constructor() {
        owner = msg.sender;
    }

    function createTransaction(address manager, address payable recipient) public payable {
        transaction = Transaction(payable(msg.sender),
                                  manager,
                                  recipient,
                                  msg.value);
        escrowed_txn[txnId++] = transaction;
    }

    function executeTransaction(uint _txnId, bool isValid) public {
        require(msg.sender == escrowed_txn[_txnId].authorisor);
        if (isValid) {
            escrowed_txn[_txnId].recipient.transfer(escrowed_txn[_txnId].amount);
        }
        else {
            escrowed_txn[_txnId].creator.transfer(escrowed_txn[_txnId].amount);
        }
    }
}