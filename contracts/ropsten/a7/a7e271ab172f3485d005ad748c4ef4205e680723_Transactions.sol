/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Transactions {
    //number variable that is going to hold the number of transactions
  uint256 transactionCount;

    //function that will be called
  event Transfer(address from, address receiver, uint amount, string message, uint timestamop, string keyword);

    //similiar to an object. here i will be specifying the attributes or properties of the object.
  struct TransferStruct {
      //type &  name
      address sender;
      address receiver;
      uint amount;
      string message;
      uint256 timestamp;
      string keyword;
  }

  /*I can also define an array of different trasactions because I want to install of them.
    Here the transactions varible is going to be an array of transfer structures (TransferStruct)*/
  TransferStruct[] transactions;

  function addToBlockChain(address payable receiver, uint amount, string memory message, string memory keyword) public {
      transactionCount +=1;
      //to store all the transaction that come thtough use code line 30.
      transactions.push(TransferStruct(msg.sender, receiver, amount, message, block.timestamp, keyword));

      //'msg.sender' something you get immediately whenever you call a espicific function in the blockchain.'block.timestamp' is the time stamp of a specific block that was being executed on the blockchain.

        //to make the transfer use the code in line 34.
      emit Transfer(msg.sender, receiver, amount, message, block.timestamp, keyword);
  }
  
    function getAllTransactions() public view returns(TransferStruct[] memory){
       return transactions;
  }

    function getTransactionCount() public view returns(uint256){
        return transactionCount;  
      
  }

}