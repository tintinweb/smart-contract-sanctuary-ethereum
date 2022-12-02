pragma solidity 0.8.14;
pragma experimental ABIEncoderV2;

import "src/amb/interfaces/IAMB.sol";

contract SourceAMB is IBroadcaster {

    mapping(uint256 => bytes32) public messages;
    uint256 public nonce;

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

    function sendViaLog(
        address recipient,
        uint16 recipientChainId,
        uint256 gasLimit,
        bytes calldata data
    ) external returns (bytes32) {
        // Heavily gas optimized
        bytes memory message =
            abi.encode(nonce, msg.sender, recipient, recipientChainId, gasLimit, data);
        bytes32 messageRoot = keccak256(message);
        emit SentMessage(nonce++, messageRoot, message);
        return messageRoot;
    }
}

pragma solidity 0.8.14;

import "src/lightclient/interfaces/ILightClient.sol";

interface IBroadcaster {

    event SentMessage(uint256 indexed nonce, bytes32 indexed msgHash, bytes message);
    event ShortSentMessage(uint256 indexed nonce, bytes32 indexed msgHash);

    function send(
        address receiver,
        uint16 chainId,
        uint256 gasLimit,
        bytes calldata data
    ) external returns (bytes32);

    function sendViaLog(
        address receiver,
        uint16 chainId,
        uint256 gasLimit,
        bytes calldata data
    ) external returns (bytes32);

}    

enum MessageStatus {
    NOT_EXECUTED,
    EXECUTION_FAILED,
    EXECUTION_SUCCEEDED
}

struct Message {
    uint256 nonce;
    address sender;
    address receiver;
    uint16 chainId;
    uint256 gasLimit;
    bytes data;
}

interface IReciever {

    event ExecutedMessage(
        uint256 indexed nonce, bytes32 indexed msgHash, bytes message, bool status
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

pragma solidity 0.8.14;

interface ILightClient {
    function head() external view returns (uint256);

    function executionStateRoots(uint256 slot) external view returns (bytes32);

    function headers(uint256 slot) external view returns (bytes32);
}