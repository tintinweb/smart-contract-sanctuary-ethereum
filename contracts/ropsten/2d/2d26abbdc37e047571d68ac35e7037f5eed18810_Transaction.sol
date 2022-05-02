/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract Transaction{
  struct transactionInformation {
    uint transactionNumber;
    uint registerNumber;
    string sellerId;
    string buyerId;
    string completeTime;
  }

  // key : transactionNumber
  mapping(uint => transactionInformation) transactionInfo;

  // Setting Transaction informations when transaction is completed
  function setTransactionInfo(uint _transactionNumber, uint _registerNumber, string memory _sellerId, string memory _buyerId, string memory _completeTime) public {
    
    transactionInformation storage trans = transactionInfo[_transactionNumber];

    trans.transactionNumber = _transactionNumber;
    trans.registerNumber = _registerNumber;
    trans.sellerId = _sellerId;
    trans.buyerId = _buyerId;
    trans.completeTime = _completeTime;

  }
  
  // Getting Transaction information when transaction require
  function getTransactionInfo(uint _transactionNumber) public view returns(uint, uint, string memory, string memory, string memory){
  
    return (transactionInfo[_transactionNumber].transactionNumber, transactionInfo[_transactionNumber].registerNumber, transactionInfo[_transactionNumber].sellerId, transactionInfo[_transactionNumber].buyerId, transactionInfo[_transactionNumber].completeTime);

  }
}