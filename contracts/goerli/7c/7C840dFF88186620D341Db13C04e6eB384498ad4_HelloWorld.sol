// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract HelloWorld {
    event update(string OldStr, string NewStr);

    string public message;
    constructor (string memory _initMsg) {
        message = _initMsg;
    }

    function updateMsg(string memory _newMsg) public {
        string memory _oldMsg = message;
        message = _newMsg;

        emit update(_oldMsg, _newMsg);
    }
}