// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract HelloWorld {
    event update(string oldStr, string newStr);

    string public message;

    constructor(string memory _initMsg) {
        message = _initMsg;
    }

    function updateMsg(string memory _newMsg) public {
        string memory _oldMsg = message;

        message = _newMsg;

        emit update(_oldMsg, _newMsg);
    }
}