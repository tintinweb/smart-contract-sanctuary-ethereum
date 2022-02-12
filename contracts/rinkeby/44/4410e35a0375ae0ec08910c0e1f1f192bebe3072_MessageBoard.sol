/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract MessageBoard {
    string private _message;

    mapping (address => string) _lastMessage;


    event newMessage(address indexed from, string message);
   

    function setMessage(string memory message) public returns (bool) {
        _message = message;
        _lastMessage[msg.sender] = _message;
        emit newMessage(msg.sender, message);
        return true;
    }

    function getMessage() public view returns (string memory) {
        return _message;
    }

    function getLastMessageByUser(address _user) public view returns (string memory) {       
        return _lastMessage[_user];
    }
}