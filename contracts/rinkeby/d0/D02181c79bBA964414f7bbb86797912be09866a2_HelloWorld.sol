// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.3;

contract HelloWorld {
    event UpdatedMessages(string oldStr, string newStr);

    string public message;

    // run only once when the smart contract is deployed
    constructor(string memory initMessage) {
        message = initMessage;
    }

    function update(string memory newMsg) public {
        string memory oldMsg = message;
        message = newMsg;
        emit UpdatedMessages(oldMsg, newMsg);
    }
}