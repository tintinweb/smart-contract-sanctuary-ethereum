/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract MyTransactionBoxV1 {
    uint256 transactionCount;
    uint256 sandeep;

    struct TransferStruct {
        address sender;
        address receiver;
        uint256 amount;
        string message;
        uint256 timestamp;
        string keyword;
    }

    TransferStruct[] transactions;

    event Transfer(
        address from,
        address receiver,
        uint256 amount,
        string message,
        uint256 timestamp,
        string keyword
    );

    function addToBlockChain(
        address payable receiver,
        uint256 amount,
        string memory message,
        string memory keyword
    ) public {
        transactionCount += 1;
        transactions.push(
            TransferStruct(
                msg.sender,
                receiver,
                amount,
                message,
                block.timestamp,
                keyword
            )
        );
        emit Transfer(
            msg.sender,
            receiver,
            amount,
            message,
            block.timestamp,
            keyword
        );
    }

    function getTransactionCount() public view returns (uint256) {
        return transactionCount;
    }

    function getAllTransaction() public view returns (TransferStruct[] memory) {
        return transactions;
    }
}