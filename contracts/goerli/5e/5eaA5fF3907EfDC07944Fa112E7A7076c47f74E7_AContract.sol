// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract AContract {
    event UpdatedMessages(string oldStr, string newStr);
    string public message;

    constructor(string memory initMessage) {
        message = initMessage;
    }

    function splitPayment(
        address payable _recipient1,
        address payable _recipient2,
        uint _recipient1Share,
        uint _recipient2Share
    ) external payable {
        require(
            _recipient1 != address(0) && _recipient2 != address(0),
            "Recipient addresses not set"
        );
        require(
            _recipient1Share + _recipient2Share == 100,
            "Invalid share percentages"
        );
        uint amount = msg.value;
        require(amount > 0, "Payment amount must be greater than 0");

        uint recipient1Amount = (amount * _recipient1Share) / 100;
        uint recipient2Amount = (amount * _recipient2Share) / 100;

        _recipient1.transfer(recipient1Amount);
        _recipient2.transfer(recipient2Amount);

        // If there's any excess payment, send it back to the sender
        uint256 remainingAmount = address(this).balance;
        if (remainingAmount > 0) {
            payable(msg.sender).transfer(remainingAmount);
        }
    }

    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);
    }
}