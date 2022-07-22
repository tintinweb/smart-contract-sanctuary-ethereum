/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


// import "hardhat/console.sol";

contract Transactions {
    uint transactionCount;

    event Transfer(address from, address receiver, uint amount, string message, uint timestamp, string keyword);
  
    struct TransferStruct {
        address sender;
        address receiver;
        uint amount;
        string message;
        uint timestamp;
        string keyword;
    }

    TransferStruct[] transactions;
      uint  ConvertInEither = 1000000000000000000;

    function addToBlockchain(address receiver, uint amount, string memory message, string memory keyword) public {
        transactionCount += 1;
        amount = amount*ConvertInEither;
        transactions.push(TransferStruct(msg.sender, receiver, amount, message, block.timestamp, keyword));

        emit Transfer(msg.sender, receiver, amount, message, block.timestamp, keyword);
    }

    function getAllTransactions() public view returns (TransferStruct[] memory) {
        return transactions;
    }

    function getTransactionCount() public view returns (uint) {
        return transactionCount;
    }
}