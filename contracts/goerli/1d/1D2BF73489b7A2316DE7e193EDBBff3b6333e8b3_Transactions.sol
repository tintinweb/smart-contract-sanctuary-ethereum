/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: LICENSED
pragma solidity ^0.8.17;

contract Transactions {
    uint256 transactionCount;

    event Transfer(
        address from,
        address to,
        uint256 amount,
        string message,
        uint256 timeStamp,
        string keyword
    );

    struct TransferStruct {
        address sender;
        address receiver;
        uint256 amount;
        string message;
        uint256 timeStamp;
        string keyword;
    }

    TransferStruct[] transactions;

    function addToBlockchain(
        address payable receiver,
        uint256 amount,
        string memory message,
        string memory keyword
    ) public {
        transactionCount++;

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

    function getAllTransactions()
        public
        view
        returns (TransferStruct[] memory)
    {
        return transactions;
    }

    function getTrasactionCound() public view returns (uint256) {
        return transactionCount;
    }
}