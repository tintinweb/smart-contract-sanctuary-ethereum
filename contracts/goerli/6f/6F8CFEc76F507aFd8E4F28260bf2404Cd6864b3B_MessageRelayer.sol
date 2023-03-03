/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

pragma solidity ^0.8.0;

contract MessageRelayer {
    
    struct Message {
        uint32 nonce;
        bytes payload;
        uint8 consistencyLevel;
    }
    
    address public relayAddress;
    Message[] public messages;
    
    constructor(address _relayAddress) {
        relayAddress = _relayAddress;
    }
    
    function addMessage(uint32 nonce, bytes memory payload, uint8 consistencyLevel) public {
        messages.push(Message(nonce, payload, consistencyLevel));
    }
    
    function relayMessages() public {
        for (uint256 i = 0; i < messages.length; i++) {
            (bool success, bytes memory result) = relayAddress.call(abi.encodeWithSignature("publishMessage(uint32,bytes,uint8)", messages[i].nonce, messages[i].payload, messages[i].consistencyLevel));
            require(success, "Failed to relay message");
        }
        delete messages;
    }
}