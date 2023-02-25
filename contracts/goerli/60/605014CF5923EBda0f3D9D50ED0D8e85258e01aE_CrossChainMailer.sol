pragma solidity ^0.8.0;

enum MessageStatus {
    NOT_EXECUTED,
    EXECUTION_FAILED,
    EXECUTION_SUCCEEDED
}

struct Message {
    uint8 version;
    uint64 nonce;
    uint32 sourceChainId;
    address senderAddress;
    uint32 recipientChainId;
    bytes32 recipientAddress;
    bytes data;
}

interface ITelepathyBroadcaster {
    event SentMessage(uint64 indexed nonce, bytes32 indexed msgHash, bytes message);

    function send(uint32 recipientChainId, bytes32 recipientAddress, bytes calldata data)
        external
        returns (bytes32);

    function send(uint32 recipientChainId, address recipientAddress, bytes calldata data)
        external
        returns (bytes32);

    function sendViaStorage(uint32 recipientChainId, bytes32 recipientAddress, bytes calldata data)
        external
        returns (bytes32);

    function sendViaStorage(uint32 recipientChainId, address recipientAddress, bytes calldata data)
        external
        returns (bytes32);
}

interface ITelepathyReceiver {
    event ExecutedMessage(
        uint32 indexed sourceChainId,
        uint64 indexed nonce,
        bytes32 indexed msgHash,
        bytes message,
        bool status
    );

    function executeMessage(
        uint64 slot,
        bytes calldata message,
        bytes[] calldata accountProof,
        bytes[] calldata storageProof
    ) external;

    function executeMessageFromLog(
        bytes calldata srcSlotTxSlotPack,
        bytes calldata messageBytes,
        bytes32[] calldata receiptsRootProof,
        bytes32 receiptsRoot,
        bytes[] calldata receiptProof, // receipt proof against receipt root
        bytes memory txIndexRLPEncoded,
        uint256 logIndex
    ) external;
}

interface ITelepathyHandler {
    function handleTelepathy(uint32 _sourceChainId, address _senderAddress, bytes memory _data)
        external
        returns (bytes4);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ITelepathyBroadcaster} from "telepathy/amb/interfaces/ITelepathy.sol";

contract CrossChainMailer {
    address public telepathy;
    uint96 nextNonce = 1;

    event MessageSent(
        address indexed mailbox, uint96 indexed nonce, address indexed sender, uint32 targetChain, string message
    );

    constructor(address _telepathy) {
        telepathy = _telepathy;
    }

    function sendMessage(address _mailbox, uint32 _targetChain, string calldata _message) external returns (uint96) {
        emit MessageSent(_mailbox, nextNonce, msg.sender, _targetChain, _message);
        ITelepathyBroadcaster(telepathy).send(_targetChain, _mailbox, abi.encode(nextNonce, msg.sender, _message));
        return nextNonce++;
    }
}