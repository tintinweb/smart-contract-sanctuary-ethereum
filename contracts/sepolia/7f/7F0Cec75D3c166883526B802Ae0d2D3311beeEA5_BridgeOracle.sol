pragma solidity ^0.8.16;

import {BridgeHandler} from "contracts/amb/interfaces/BridgeHandler.sol";
import {IOracleCallbackReceiver} from "contracts/oracle/interfaces/IOracleCallbackReceiver.sol";

enum RequestStatus {
    UNSENT,
    PENDING,
    SUCCESS,
    FAILED
}

struct RequestData {
    uint256 nonce;
    address targetContract;
    bytes targetCalldata;
    address callbackContract;
}

contract BridgeOracle is BridgeHandler {
    event CrossChainRequestSent(
        uint256 indexed nonce,
        address targetContract,
        bytes targetCalldata,
        address callbackContract
    );

    error InvalidChainId(uint256 sourceChain);
    error NotFulfiller(address srcAddress);
    error RequestNotPending(bytes32 requestHash);

    /// @notice Maps request hashes to their status
    /// @dev The hash of a request is keccak256(abi.encode(RequestData))
    mapping(bytes32 => RequestStatus) public requests;
    /// @notice The next nonce to use when sending a cross-chain request
    uint256 public nextNonce = 1;
    /// @notice The address of the fulfiller contract on the other chain
    address public fulfiller;
    /// @notice The chain ID of the fulfiller contract
    uint32 public fulfillerChainId;

    constructor(uint32 _fulfillerChainId, address _bridgeRouter, address _fulfiller)
        BridgeHandler(_bridgeRouter)
    {
        fulfillerChainId = _fulfillerChainId;
        fulfiller = _fulfiller;
    }

    function requestCrossChain(
        address _targetContract,
        bytes calldata _targetCalldata,
        address _callbackContract
    ) external returns (uint256 nonce) {
        unchecked {
            nonce = nextNonce++;
        }
        RequestData memory requestData =
            RequestData(nonce, _targetContract, _targetCalldata, _callbackContract);
        bytes32 requestHash = keccak256(abi.encode(requestData));
        requests[requestHash] = RequestStatus.PENDING;

        emit CrossChainRequestSent(nonce, _targetContract, _targetCalldata, _callbackContract);
        return nonce;
    }

    function handleBridgeImpl(uint32 _sourceChain, address _senderAddress, bytes memory _data)
        internal
        override
    {
        if (_sourceChain != fulfillerChainId) {
            revert InvalidChainId(_sourceChain);
        }
        if (_senderAddress != fulfiller) {
            revert NotFulfiller(_senderAddress);
        }

        (
            uint256 nonce,
            bytes32 requestHash,
            address callbackContract,
            bytes memory responseData,
            bool responseSuccess
        ) = abi.decode(_data, (uint256, bytes32, address, bytes, bool));

        if (requests[requestHash] != RequestStatus.PENDING) {
            revert RequestNotPending(requestHash);
        }

        requests[requestHash] = responseSuccess ? RequestStatus.SUCCESS : RequestStatus.FAILED;

        callbackContract.call(
            abi.encodeWithSelector(
                IOracleCallbackReceiver.handleOracleResponse.selector,
                nonce,
                responseData,
                responseSuccess
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBridgeHandler} from "contracts/amb/interfaces/IBridge.sol";

abstract contract BridgeHandler is IBridgeHandler {
    error NotFromBridgeRouter(address sender);

    address public bridgeRouter;

    constructor(address _bridgeRouter) {
        bridgeRouter = _bridgeRouter;
    }

    function handleBridge(uint32 _sourceChainId, address _sourceAddress, bytes memory _data)
        external
        override
        returns (bytes4)
    {
        if (msg.sender != bridgeRouter) {
            revert NotFromBridgeRouter(msg.sender);
        }
        handleBridgeImpl(_sourceChainId, _sourceAddress, _data);
        return IBridgeHandler.handleBridge.selector;
    }

    function handleBridgeImpl(uint32 _sourceChainId, address _sourceAddress, bytes memory _data)
        internal
        virtual;
}

// SPDX-License-Identifier: MIT
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
    address sourceAddress;
    uint32 destinationChainId;
    bytes32 destinationAddress;
    bytes data;
}

interface IBridgeRouter {
    event SentMessage(uint64 indexed nonce, bytes32 indexed msgHash, bytes message);

    function send(uint32 destinationChainId, bytes32 destinationAddress, bytes calldata data)
        external
        returns (bytes32);

    function send(uint32 destinationChainId, address destinationAddress, bytes calldata data)
        external
        returns (bytes32);

    function sendViaStorage(
        uint32 destinationChainId,
        bytes32 destinationAddress,
        bytes calldata data
    ) external returns (bytes32);

    function sendViaStorage(
        uint32 destinationChainId,
        address destinationAddress,
        bytes calldata data
    ) external returns (bytes32);
}

interface IBridgeReceiver {
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
        bytes[] calldata storageProof,
        bytes32 storageRoot
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

interface IBridgeHandler {
    function handleBridge(uint32 _sourceChainId, address _sourceAddress, bytes memory _data)
        external
        returns (bytes4);
}

pragma solidity ^0.8.16;

interface IOracleCallbackReceiver {
    function handleOracleResponse(uint256 nonce, bytes memory responseData, bool responseSuccess)
        external;
}