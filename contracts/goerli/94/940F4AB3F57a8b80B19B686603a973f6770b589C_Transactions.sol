// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Transactions {
    uint256 transactionCount;

    struct TransferStruct {
        address sender;
        address reciever;
        uint256 amount;
        string message;
        uint256 timestamp;
    }

    TransferStruct[] transactionsArray;

    function sendCrypto(
        address payable reciever,
        uint256 amount,
        string memory message
    ) public {
        transactionCount += 1;
        transactionsArray.push(
            TransferStruct(
                msg.sender,
                reciever,
                amount,
                message,
                block.timestamp
            )
        );
    }

    function getAllTransactions()
        public
        view
        returns (TransferStruct[] memory)
    {
        return transactionsArray;
    }

    function getTransactionCount() public view returns (uint256) {
        return transactionCount;
    }
}