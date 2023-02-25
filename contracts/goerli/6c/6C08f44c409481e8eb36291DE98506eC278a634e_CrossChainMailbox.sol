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
    error NotFromMailer(address sender);

    address public mailer;

    event MessageReceived(uint96 indexed nonce, address indexed sender, uint32 indexed sourceChain, string message);

    constructor(address _telepathy, address _mailer) TelepathyHandler(_telepathy) {
        mailer = _mailer;
    }

    function handleTelepathyImpl(uint32 _sourceChainId, address mailerAddress, bytes memory _data) internal override {
        if (mailerAddress != mailer) {
            revert NotFromMailer(mailerAddress);
        }
        (uint96 nonce, address sender, string memory message) = abi.decode(_data, (uint96, address, string));
        emit MessageReceived(nonce, sender, _sourceChainId, message);
    }
}