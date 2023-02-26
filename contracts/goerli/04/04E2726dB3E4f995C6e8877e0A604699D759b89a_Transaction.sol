// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Transaction {
    event Transfer(address sender, address receiver, uint256 amount, string message, uint256 timestamp, string keyword);

    function publishTransaction(address payable _receiver, uint256 _amount, string memory _message, string memory _keyword) public {
        emit Transfer(msg.sender, _receiver, _amount, _message, block.timestamp, _keyword);
    }
}