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
    event LogMsg(
    address sender,
    string message,
	uint time
);
    
    constructor(string memory _msg, address _sender, uint _time) {
        
        emit LogMsg(_sender, _msg, _time);

    }
}