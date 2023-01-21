/**
 *Submitted for verification at Etherscan.io on 2023-01-21
*/

pragma solidity ^0.8.17;

contract MsgSender {
    event SentMsg(
        address sender,
        address deployedAddress,
        string message
    );

    function sendMsg(string memory paragraph) public returns (address) {
        require(bytes(paragraph).length <= 512 && bytes(paragraph).length > 0, "Message too long");

        // Create a new instance of the Message contract
        DeployMessage msgContract = new DeployMessage(paragraph, msg.sender, block.timestamp);

        // Emit the SentMsg event
        emit SentMsg(msg.sender, address(msgContract), paragraph);

        // Return the address of the deployed contract
        return address(msgContract);
    }
}

contract DeployMessage {
    string public Message;
    address public Address;
    uint public Time;

    constructor(string memory _msg, address _sender, uint _time) {
        Message = _msg; 
        Address = _sender;
        Time = _time;
    }
}