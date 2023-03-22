// SPDX-License-Identifier: MIT

pragma solidity  ^0.8.0;

contract Transaction{
    uint transactioncounter=0;

    event Transfer(address from,address to,uint amount,string message,uint timestamp,string keyword);

    
    struct TransferStruct{
        address sender;
        address recivever;
        uint amount;
        string message;
        uint timestamp;
        string keyword;
    }
    TransferStruct[] tsa;

    function addToBlockchain(address reciever,uint amount,string memory message,uint timestamp,string memory keyword)public{
         transactioncounter++;
         tsa.push(TransferStruct(msg.sender,reciever,amount,message,timestamp,keyword));
         emit Transfer(msg.sender,reciever,amount,message,timestamp,keyword);
    }
    function getAllTransaction()public view returns(TransferStruct[] memory){
        return tsa;
    }
    function getTransactionCount()public view returns(uint){
        return transactioncounter;
    }
}