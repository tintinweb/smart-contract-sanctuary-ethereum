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

    function sendViaCall(address payable _to, string calldata _msg) public payable {
        (bool sent, bytes memory data) = _to.call{value: msg.value, gas: 3000000}(abi.encodeWithSignature("greet(string)", _msg));
        emit LogSend(msg.sender, data);

        require(sent, "Failed to send Ether(Call)");
    }

    function testFallback(address payable _to, string calldata _msg) public payable {
        (bool sent, bytes memory data) = _to.call{value: msg.value}(abi.encodeWithSignature("foo(string)", _msg));
        emit LogSend(msg.sender, data);

        require(sent, "Failed to send Ether(Call fallback)");
    }

    

}