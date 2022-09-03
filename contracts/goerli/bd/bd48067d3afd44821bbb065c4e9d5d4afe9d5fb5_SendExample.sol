/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract SendExample {
    event LogSend(address indexed _sender,bytes data);
    
    function sendViaTransfer(address payable _to) public payable {
        _to.transfer(msg.value);
    }

    function sendViaSend(address payable _to) public payable {
        bool sent = _to.send(msg.value);

        require(sent, "Failed to send Ether(Send)");
    }

    function sendViaCall(address payable _to, bytes calldata _data) public payable {
        (bool sent, bytes memory data) = _to.call{value: msg.value}(_data);
        emit LogSend(msg.sender, data);

        require(sent, "Failed to send Ether(Call)");
    }
}