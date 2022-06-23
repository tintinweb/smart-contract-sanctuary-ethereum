// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

contract HMSend {
    uint256 txSentCount;

    struct Payment {
        address from;
        address to;
        uint256 amount;
        uint256 date;
        string message;
        string gif;
    }

    Payment[] payments;

    event Sent(
        address from,
        address to,
        uint256 amount,
        uint256 date,
        string message,
        string gif
    );

    function logPayment(
        address payable to,
        uint256 amount,
        string memory message,
        string memory gif
    ) public {
        txSentCount += 1;
        payments.push(
            Payment(msg.sender, to, amount, block.timestamp, message, gif)
        );

        emit Sent(msg.sender, to, amount, block.timestamp, message, gif);
    }

    function getAllPayments() public view returns (Payment[] memory) {
        return payments;
    }

    function getTxSentCount() public view returns (uint256) {
        return txSentCount;
    }
}