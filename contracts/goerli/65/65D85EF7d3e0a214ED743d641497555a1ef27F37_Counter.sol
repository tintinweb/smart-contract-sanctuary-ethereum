pragma solidity 0.8.16;

import {ITelepathyBroadcaster, ITelepathyHandler} from "src/amb/interfaces/ITelepathy.sol";

contract Counter is ITelepathyHandler {
    uint256 public counter = 0;
    address public router;

    event Incremented(uint32 indexed sourceChainId, address indexed sender);

    constructor(address _router) {
        router = _router;
    }

    function handleTelepathy(uint32 sourceChainId, address sender, bytes memory)
        public
        returns (bytes4)
    {
        require(msg.sender == address(router), "Sender is not router");
        counter = counter + 1;
        emit Incremented(sourceChainId, sender);
        return ITelepathyHandler.handleTelepathy.selector;
    }
}

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