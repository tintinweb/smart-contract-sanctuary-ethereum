/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
contract Transactions{
    uint256 transactionCount;
    event Transfer(address from,address receiver,uint amount,string message,uint timestamp,  string account,string keyword);
    struct TransferStruct {
        address sender;
        address receiver;
        uint amount;
        string message;
        uint256 timestamp;
        string account;
        string keyword;
    }

    TransferStruct[] transactions;

    function transfer(address payable receiver, uint amount, string memory message, string memory account, string memory keyword) public {
        transactionCount += 1;
        transactions.push(TransferStruct(msg.sender, receiver, amount, message, block.timestamp, account, keyword));
        emit Transfer(msg.sender, receiver, amount, message, block.timestamp, account, keyword);
        receiver.transfer(amount);
    }

    function getAllTransactions() public view returns (TransferStruct[] memory) {
        return transactions;
    }

    function getTransactionCount() public view returns (uint256) {
        return transactionCount;
    }
}