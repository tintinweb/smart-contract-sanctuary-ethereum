// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract ContractMessage {
    string private message;

    event MessageUpdated(string newMessage);

    function setMessage(string memory _message) public {
        message = _message;
        emit MessageUpdated(_message) ;
    }

    function getMessage() public view returns (string memory) {
        return message;
    }
}