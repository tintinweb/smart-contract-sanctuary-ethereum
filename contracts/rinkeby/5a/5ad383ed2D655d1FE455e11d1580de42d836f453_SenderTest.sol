/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SenderTest {
    mapping(address => uint256) amounts;
    function getSender() external view returns (address) {
        return msg.sender;
    }

    function setAmount(uint256 _amount) external {
        amounts[msg.sender] = _amount;
    }

    function getAmount() external view returns (uint256) {
        return amounts[msg.sender];
    }
}