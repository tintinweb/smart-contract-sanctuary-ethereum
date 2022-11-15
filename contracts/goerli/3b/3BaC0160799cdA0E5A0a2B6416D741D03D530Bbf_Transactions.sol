/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File contracts/Transactions.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Transactions {
    uint256 transactionCount;
    event Transfer(
        address from,
        address receiver,
        uint amount,
        uint256 timestamp
    );
    struct TransferStruct {
        address sender;
        address receiver;
        uint amount;
        uint256 timestamp;
    }
    TransferStruct[] transactions;

    function addToBlockchain(address payable receiver, uint amount) public {
        transactionCount += 1;
        transactions.push(
            TransferStruct(msg.sender, receiver, amount, block.timestamp)
        );
        emit Transfer(msg.sender, receiver, amount, block.timestamp);
    }

    function getAllTransactions()
        public
        view
        returns (TransferStruct[] memory)
    {
        return transactions;
    }
}