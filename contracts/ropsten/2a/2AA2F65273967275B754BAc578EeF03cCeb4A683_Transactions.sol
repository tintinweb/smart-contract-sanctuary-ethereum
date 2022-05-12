// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

contract  Transactions{
    constructor() {
    }

    uint256 transactionCounter;

    event Transfer(address from, address receiver, uint amount, string message, uint256 timestamp, string keyword);

    struct TransferStruct{
        address sender;
        address receiver;
        uint Amount;
        string Message;
        uint256 Timestamp;
        string keyword;
    }

    TransferStruct[] transactions;

    function sendToBlockchain(address payable receiver, uint amount, string memory message, string memory keyword) public{
        transactionCounter += 1;
        transactions.push(TransferStruct(msg.sender, receiver, amount,message, block.timestamp, keyword));

        emit Transfer(msg.sender, receiver, amount,message, block.timestamp, keyword);
    }

    function Getall_Transactions() public view returns (TransferStruct[] memory){
        //return transactions
        return transactions;
    }

    function Transactions_Count() public view returns (uint256){
        return transactionCounter;
    }
}