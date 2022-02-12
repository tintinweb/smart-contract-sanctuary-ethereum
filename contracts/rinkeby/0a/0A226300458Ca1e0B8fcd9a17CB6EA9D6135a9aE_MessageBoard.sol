/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract MessageBoard {
    string private _message;
    string private _name;

    event newMessage(address indexed from, string name, string message);

    function setMessage(string memory name, string memory message)
        public
        returns (bool)
    {
        _message = message;
        _name = name;
        emit newMessage(msg.sender, name, message);
        return true;
    }

    function getMessage() public view returns (string memory) {
        return string(abi.encodePacked(_name, ": ", _message));
    }
}