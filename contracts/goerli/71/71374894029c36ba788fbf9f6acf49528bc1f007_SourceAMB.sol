pragma solidity 0.8.14;
pragma experimental ABIEncoderV2;

contract SourceAMB {
    mapping(uint256 => bytes32) public messages;
    uint256 public nonce;

    event SentMessage(uint256 indexed nonce, bytes32 indexed msgHash, bytes message);
    event ShortSentMessage(uint256 indexed nonce, bytes32 indexed msgHash);

    constructor() {
        nonce = 1; // We initialize with 1 to get accurate gas numbers during testing
        // since changing a slot from 0 is different the changing it from any other number.
    } 

    function send(address recipient, uint16 recipientChainId, uint256 gasLimit, bytes calldata data)
        external
        returns (bytes32)
    {
        bytes memory message =
            abi.encode(nonce, msg.sender, recipient, recipientChainId, gasLimit, data);
        bytes32 messageRoot = keccak256(message);
        messages[nonce] = messageRoot;
        emit SentMessage(nonce++, messageRoot, message);
        return messageRoot;
    }
    
    function sendViaLog(address recipient, uint16 recipientChainId, uint256 gasLimit, bytes calldata data)
        external
        returns (bytes32)
    {
        // Heavily gas optimized
        bytes memory message =
            abi.encode(nonce, msg.sender, recipient, recipientChainId, gasLimit, data);
        bytes32 messageRoot = keccak256(message);
        emit SentMessage(nonce++, messageRoot, message);
        return messageRoot;
    }
}