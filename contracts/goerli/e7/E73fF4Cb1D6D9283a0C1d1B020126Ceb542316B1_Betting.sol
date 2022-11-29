// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract Betting {
    function getBalance() external view returns (uint256) {
        return msg.sender.balance;
    }

    function getSender() external view returns (address) {
        return msg.sender;
    }
}