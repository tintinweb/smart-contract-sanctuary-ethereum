/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

// SPDX-License-Identifier: MIT
// File: prabu/TransactionETH.sol


pragma solidity ^0.8.7;


contract TransactionETH {

    uint256 public transactionCount;
    event Transaction(address sender, address receiver, uint256 amount, string message, uint256 timestamp);
    //user defined type
    struct TransactionStruct{
        address sender;
        address receiver;
        uint256 amount;
        string message;
        uint256 timeStamp;
    }
    //crate state varaible
    TransactionStruct[] public transactions; //array variable for transactionStruct
    function addToBlockChain(address _receiver, uint256 _amount, string memory _message) external {

        TransactionStruct memory newTransactions = TransactionStruct ({
            sender : msg.sender,
            receiver : _receiver,
            amount : _amount,
            message : _message,
            timeStamp : block.timestamp

        });

        transactions.push(newTransactions);
        transactionCount += 1;
        //trigger the event once successfully add to the blockchain
        emit Transaction(msg.sender, _receiver, _amount, _message, block.timestamp);
    }

    function getAllTransactions() public view returns(TransactionStruct[] memory) {
        return transactions;
    }

    function getTransactionCount() public view returns(uint256 count) {
        return transactionCount;
    }

}