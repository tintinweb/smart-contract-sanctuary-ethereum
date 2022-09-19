// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Util} from "../src/Util.sol";
import "../src/interfaces/IGateway.sol";

contract Gateway is IGateway {
    using Util for *;

    /// @notice thrown when the signature is invalid
    error InvalidSignature();

    /// @notice thrown when the PayloadHash is invalid
    error InvalidPayloadHash();

    /*//////////////////////////////////////////////////////////////
                              Events
    //////////////////////////////////////////////////////////////*/

    event logNewTask(
        uint256 indexed task_id,
        string source_network,
        address user_address,
        string routing_info,
        string routing_code_hash,
        bytes payload,
        bytes32 payload_hash,
        bytes payload_signature,
        bytes user_key,
        string handle,
        bytes12 nonce
    );

    event logCompletedTask(uint256 indexed task_id, bytes32 payload_hash, bytes32 result_hash);

    /*//////////////////////////////////////////////////////////////
                             Constructor
    //////////////////////////////////////////////////////////////*/

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                             Initialization
    //////////////////////////////////////////////////////////////*/

    address public masterVerificationAddress;

    /// @notice Initialize the verification address
    /// @param _masterVerificationAddress The input address
    function initialize(address _masterVerificationAddress) public onlyOwner {
        masterVerificationAddress = _masterVerificationAddress;
    }

    /*//////////////////////////////////////////////////////////////
                             Update Routes
    //////////////////////////////////////////////////////////////*/

    /// @dev mapping of chain name string to the verification address
    mapping(string => address) public route;

    /// @notice Updating the route
    /// @param _route Route name
    /// @param _verificationAddress Address corresponding to the route
    /// @param _signature Signed hashed inputs(_route + _verificationAddress)
    function updateRoute(string memory _route, address _verificationAddress, bytes memory _signature) public onlyOwner {
        bytes32 routeHash = Util.getRouteHash(_route, _verificationAddress);
        bytes32 ethSignedMessageHash = Util.getEthSignedMessageHash(routeHash);

        bool verifySig;
        verifySig = Util.recoverSigner(ethSignedMessageHash, _signature) == masterVerificationAddress;

        if (!verifySig) {
            revert InvalidSignature();
        }

        route[_route] = _verificationAddress;
    }

    /*//////////////////////////////////////////////////////////////
                             Pre Execution
    //////////////////////////////////////////////////////////////*/

    uint256 public taskId = 1;

    /// @dev Task ID ====> Task
    mapping(uint256 => Util.Task) public tasks;

    /// @notice Pre-Execution
    /// @param _task Task struct
    /// @param _info ExecutionInfo struct
    function preExecution(Util.Task memory _task, Util.ExecutionInfo memory _info) public {
        bool verifySig;

        // Payload hash signature verification
        verifySig = true;
        verifySig = Util.recoverSigner(_task.payload_hash, _info.payload_signature) == _task.user_address;

        if (!verifySig) {
            revert InvalidSignature();
        }

        // persisting the task
        tasks[taskId] = _task;

        emit logNewTask(
            taskId,
            _task.source_network,
            _task.user_address,
            _task.routing_info,
            _info.routing_code_hash,
            _info.payload,
            _task.payload_hash,
            _info.payload_signature,
            _info.user_key,
            _info.handle,
            _info.nonce
            );

        taskId++;
    }

    /*//////////////////////////////////////////////////////////////
                             Post Execution
    //////////////////////////////////////////////////////////////*/

    /// @notice Post-Execution
    /// @param _taskId Task Id of the executed message
    /// @param _sourceNetwork Source network of the message
    /// @param _info PostExecutionInfo struct
    function postExecution(uint256 _taskId, string memory _sourceNetwork, Util.PostExecutionInfo memory _info) public {
        bool verifySig;
        address recoveredSigner;

        address checkerAddress = route[_sourceNetwork];

        // Payload signature verification
        verifySig = true;
        recoveredSigner = Util.modifiedRecoverSigner(_info.payload_hash, _info.payload_signature, checkerAddress);
        verifySig = recoveredSigner == checkerAddress;
        if (!verifySig) {
            revert InvalidSignature();
        }

        // Payload hash verification from tasks struct
        bool verifyPayloadHash;
        verifyPayloadHash = _info.payload_hash == tasks[_taskId].payload_hash;
        if (!verifyPayloadHash) {
            revert InvalidPayloadHash();
        }

        // Result signature verification
        verifySig = true;
        recoveredSigner = Util.modifiedRecoverSigner(_info.result_hash, _info.result_signature, checkerAddress);
        verifySig = recoveredSigner == checkerAddress;
        if (!verifySig) {
            revert InvalidSignature();
        }

        // Packet signature verification
        verifySig = true;
        recoveredSigner = Util.modifiedRecoverSigner(_info.packet_hash, _info.packet_signature, checkerAddress);
        verifySig = recoveredSigner == checkerAddress;
        if (!verifySig) {
            revert InvalidSignature();
        }

        (bool val,) = address(tasks[_taskId].callback_address).call(abi.encodeWithSelector(tasks[_taskId].callback_selector, _taskId, _info.result));
        require(val == true, "Callback error");

        tasks[_taskId].completed = true;

        emit logCompletedTask(_taskId, _info.payload_hash, _info.result_hash);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

library Util {
    struct Task {
        address callback_address;
        bytes4 callback_selector;
        address user_address;
        string source_network;
        string routing_info;
        bytes32 payload_hash;
        bool completed;
    }

    struct ExecutionInfo {
        bytes user_key;
        string routing_code_hash;
        string handle;
        bytes12 nonce;
        bytes payload;
        bytes payload_signature;
    }

    struct PostExecutionInfo {
        bytes32 payload_hash;
        bytes payload_signature;
        bytes result;
        bytes32 result_hash;
        bytes result_signature;
        bytes32 packet_hash;
        bytes packet_signature;
    }

    /*//////////////////////////////////////////////////////////////
                           Signature Utils
    //////////////////////////////////////////////////////////////*/

    /// @notice Splitting signature util for recovery
    /// @param _sig The signature
    function splitSignature(bytes memory _sig) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(_sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(_sig, 32))
            // second 32 bytes
            s := mload(add(_sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    /// @notice Recover the signer from message hash
    /// @param _ethSignedMessageHash The message hash from getEthSignedMessageHash()
    /// @param _signature The signature that needs to be verified
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    /// @notice Recover the signer from message hash
    /// @param _ethSignedMessageHash The message hash from getEthSignedMessageHash()
    /// @param _signature The signature that needs to be verified
    /// @param _checkingAddress address for trial/error for v value
    function modifiedRecoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature, address _checkingAddress) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        v = 27;
        if (ecrecover(_ethSignedMessageHash, v, r, s) == _checkingAddress) {
            return ecrecover(_ethSignedMessageHash, v, r, s);
        }
        v = 28;
        if (ecrecover(_ethSignedMessageHash, v, r, s) == _checkingAddress) {
            return ecrecover(_ethSignedMessageHash, v, r, s);
        } else {
            return address(0);
        }
    }

    /// @notice Hashes the encoded message hash
    /// @param _messageHash the message hash
    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    /// @notice Get the encoded hash of the inputs for signing
    /// @param _routeInput Route name
    /// @param _verificationAddressInput Address corresponding to the route
    function getRouteHash(string memory _routeInput, address _verificationAddressInput) public pure returns (bytes32) {
        return keccak256(abi.encode(_routeInput, _verificationAddressInput));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Util} from "../Util.sol";

interface IGateway {
    function initialize(address _masterVerificationAddress) external;

    function updateRoute(string memory _route, address _verificationAddress, bytes memory _signature) external;

    function preExecution(Util.Task memory _task, Util.ExecutionInfo memory _info) external;

    function postExecution(uint256 _taskId, string memory _sourceNetwork, Util.PostExecutionInfo memory _info) external;
}