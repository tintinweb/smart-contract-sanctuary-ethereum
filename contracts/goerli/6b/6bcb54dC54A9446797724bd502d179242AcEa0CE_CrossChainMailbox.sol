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

pragma solidity ^0.8.0;

import {ITelepathyHandler} from "./ITelepathy.sol";

abstract contract TelepathyHandler is ITelepathyHandler {
    error NotFromTelepathyReceiever(address sender);

    address private _telepathyReceiever;

    constructor(address telepathyReceiever) {
        _telepathyReceiever = telepathyReceiever;
    }

    function handleTelepathy(uint32 _sourceChainId, address _senderAddress, bytes memory _data)
        external
        override
        returns (bytes4)
    {
        if (msg.sender != _telepathyReceiever) {
            revert NotFromTelepathyReceiever(msg.sender);
        }
        handleTelepathyImpl(_sourceChainId, _senderAddress, _data);
        return ITelepathyHandler.handleTelepathy.selector;
    }

    function handleTelepathyImpl(uint32 _sourceChainId, address _senderAddress, bytes memory _data)
        internal
        virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {TelepathyHandler} from "telepathy/amb/interfaces/TelepathyHandler.sol";

contract CrossChainMailbox is TelepathyHandler {
    event MessageReceived(uint32 indexed sourceChain, address indexed sender, string message);

    string[] public messages;

    constructor(address _telepathy) TelepathyHandler(_telepathy) {}

    function handleTelepathyImpl(uint32 _sourceChainId, address _sender, bytes memory _message) internal override {
        messages.push(string(_message));
        emit MessageReceived(_sourceChainId, _sender, string(_message));
    }

    function messagesLength() external view returns (uint256) {
        return messages.length;
    }
}