/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

pragma solidity ^0.8.0;

contract MsgSender {
    event MyMessage(string message);

    function sendMessage(string memory _message) external {
        emit MyMessage(_message);
    }
}