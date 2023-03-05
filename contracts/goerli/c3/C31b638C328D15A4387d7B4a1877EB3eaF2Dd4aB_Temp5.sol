// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Temp5{

    event Log(string message,uint val);
    event IndexedLog(address indexed addr,uint val);

    event Message(address indexed from,address indexed to,string message);

    function example() external {
        emit Log("foo",1234);
        emit IndexedLog(msg.sender,789);
    }

    function sendMessage(address  _to,string calldata _message) external {
        emit Message(msg.sender, _to, _message);
    }
}