/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Transactions {
    event Send(
        address from,
        address to,
        uint256 amount,
        string message,
        uint256 timestamp
    );

    struct Transfer {
        uint256 id;
        address sender;
        address receiver;
        uint256 amount;
        string message;
        uint256 timestamp;
    }

    Transfer[] transactions;

    function send(
        address payable receiver,
        uint256 amount,
        string memory message
    ) public {
        transactions.push(
            Transfer(
                transactions.length + 1,
                msg.sender,
                receiver,
                amount,
                message,
                block.timestamp
            )
        );

        emit Send(msg.sender, receiver, amount, message, block.timestamp);
    }

    function getAll() public view returns (Transfer[] memory) {
        return transactions;
    }

    function count() public view returns (uint256) {
        return transactions.length;
    }
}