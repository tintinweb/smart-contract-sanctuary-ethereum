/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Import this file to use console.log
// import "hardhat/console.sol";

contract Transaction {
  uint256 transactionCount;

  event Transfer(address from, address receiver, uint256 amount, string message, uint256 timestamp, string keyword);

  struct TranferStruct {
    address sender;
    address receiver;
    uint256 amount;
    string message;
    uint256 timestamp;
    string keyword;
  }
  TranferStruct[] transactions;

  function addToBlockchain(
    address payable receiver,
    uint256 amount,
    string memory message,
    string memory keyword
  ) public {
    transactionCount += 1;
    transactions.push(TranferStruct(msg.sender, receiver, amount, message, block.timestamp, keyword));

    emit Transfer(msg.sender, receiver, amount, message, block.timestamp, keyword);
  }

  function getAllTransactions() public view returns (TranferStruct[] memory) {
    return transactions;
  }

  function getTransactionCount() public view returns (uint256) {
    return transactionCount;
  }
}