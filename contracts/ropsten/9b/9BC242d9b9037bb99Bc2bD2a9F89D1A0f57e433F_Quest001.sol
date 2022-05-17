/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract Quest001 {
    event eventLog(string tag, string message);

    string internal message = "Hello World";

    constructor()  {
        emit eventLog("edk_event", "edk_message");
    }

    function getMessage() public view returns(string memory) {
        return message;
    }

    function setMessage(string memory _message) public {
        message = _message;
    }
}