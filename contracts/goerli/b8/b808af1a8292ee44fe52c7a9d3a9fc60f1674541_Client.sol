// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Util} from "../src/Util.sol";
import {IGateway} from "../src/interfaces/IGateway.sol";
import "../src/interfaces/IClient.sol";

contract Client is IClient {
    using Util for *;

    /// @notice Emitted when we recieve callback for our result of the computation
    event ComputedResult(uint256 indexed taskId, bytes result);

    /*//////////////////////////////////////////////////////////////
                             Constructor
    //////////////////////////////////////////////////////////////*/

    address public GatewayAddress;

    constructor(address _gatewayAddress) {
        GatewayAddress = _gatewayAddress;
    }

    modifier onlyGateway() {
        require(msg.sender == GatewayAddress, "Only Gateway contract can call this method");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        New Task and Send Call
    //////////////////////////////////////////////////////////////*/

    function newTask(
        address _callbackAddress,
        bytes4 _callbackSelector,
        address _userAddress,
        string memory _sourceNetwork,
        string memory _routingInfo,
        bytes32 _payloadHash
    )
        internal
        pure
        returns (Util.Task memory)
    {
        return Util.Task(_callbackAddress, _callbackSelector, _userAddress, _sourceNetwork, _routingInfo, _payloadHash, false);
    }

    /// @param _userAddress  Task Id of the computation
    /// @param _sourceNetwork computed result
    /// @param _routingInfo The second stored number input
    /// @param _payloadHash The second stored number input
    /// @param _info ExecutionInfo struct
    function send(
        address _userAddress,
        string memory _sourceNetwork,
        string memory _routingInfo,
        bytes32 _payloadHash,
        Util.ExecutionInfo memory _info
    )
        public
    {
        Util.Task memory newtask;

        newtask = newTask(address(this), this.callback.selector, _userAddress, _sourceNetwork, _routingInfo, _payloadHash);

        IGateway(GatewayAddress).preExecution(newtask, _info);
    }

    /*//////////////////////////////////////////////////////////////
                               Callback
    //////////////////////////////////////////////////////////////*/

    /// @param _taskId  Task Id of the computation
    /// @param _result computed result
    /// @param _result The second stored number input
    function callback(uint256 _taskId, bytes memory _result) external onlyGateway {
        emit ComputedResult(_taskId, _result);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Util} from "../Util.sol";

interface IClient {
    function send(
        address _userAddress,
        string memory _sourceNetwork,
        string memory _routingInfo,
        bytes32 _payloadHash,
        Util.ExecutionInfo memory _info
    )
        external;

    function callback(uint256 _taskId, bytes memory _result) external;
}