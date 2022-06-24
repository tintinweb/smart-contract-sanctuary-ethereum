/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: GPL-3.0

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity >=0.7.0 <0.9.0;

contract HelloWorld{
    event UpdatedMessages (string oldStr, string newStr);

    string public message;

    constructor (string memory initMessage){
        message= initMessage;
    }

    function update (string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages (oldMsg, newMessage);
    }
}