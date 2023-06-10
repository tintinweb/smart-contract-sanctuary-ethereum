// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract Messages {
    struct Message {
        uint id;
        uint valueInWei;
        uint timestamp;
        string text;
        address sender;
        address payable receiver;
    }

    mapping(address => uint) private numOfMessagesAtAddress;
    mapping(address => mapping(uint => Message)) private addressToMessage;

    event NewMessage(
        uint id,
        uint value,
        uint timestamp,
        address indexed sender,
        address indexed receiver
    );

    function sendMessage(
        address payable _receiver,
        string memory _text,
        uint _timestamp
    ) public payable {
        uint _messageId = numOfMessagesAtAddress[_receiver] + 1;
        Message storage _receiverMessage = addressToMessage[_receiver][_messageId];

        _receiverMessage.id = _messageId;
        _receiverMessage.timestamp = _timestamp;
        _receiverMessage.text = _text;
        _receiverMessage.sender = msg.sender;
        _receiverMessage.receiver = _receiver;

        if (msg.value > 0) {
            _receiverMessage.valueInWei = msg.value;
            // Send the AVAX to the receiver
            _receiver.transfer(msg.value);
        }

        numOfMessagesAtAddress[_receiver]++;

        emit NewMessage(
            _messageId,
            msg.value,
            _timestamp,
            msg.sender,
            _receiver
        );
    }

    // Function to transfer AVAX from this contract to address from input
    function sendAvax(address payable _to, uint _amount) private {
        // Note that "to" is declared as payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send AVAX");
    }

    function getNumOfMessages() public view returns (uint) {
        return numOfMessagesAtAddress[msg.sender];
    }

    function getOwnMessages(
        uint _startIndex,
        uint _count
    ) public view returns (Message[] memory) {
        Message[] memory _userMessages = new Message[](_count);

        for (; _startIndex < _count; _startIndex++) {
            _userMessages[_startIndex] = addressToMessage[msg.sender][_startIndex + 1];
        }

        return _userMessages;
    }
}