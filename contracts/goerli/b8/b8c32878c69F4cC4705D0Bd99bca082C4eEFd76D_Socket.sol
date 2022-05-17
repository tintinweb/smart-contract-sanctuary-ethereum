// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.4;

import "./interfaces/ISocket.sol";
import "./interfaces/IChannel.sol";
import "./interfaces/IExecutor.sol";
import "./interfaces/IPlug.sol";
import "./interfaces/IProver.sol";

contract Socket is ISocket {
    // localPlug => remoteChain => OutboundConfig
    mapping(address => mapping(uint256 => OutboundConfig)) public outboundConfigs;

    // localPlug => remoteChain => InboundConfig
    mapping(address => mapping(uint256 => InboundConfig)) public inboundConfigs;

    // channel => chainId => root => confimations
    mapping(address => mapping(uint256 => mapping(bytes32 => uint256))) public confirmations;

    // packetId => status
    mapping(bytes32 => bool) public executeStatus;

    // localPlug => remoteChainId => nonce
    mapping(address => mapping(uint256 => uint256)) public nonces;

    // remotePlug => remoteChainId => nonce
    mapping(address => mapping(uint256 => uint256)) public nextNonceToProcess;

    uint256 immutable chainId;
    uint256 public constant RESERVE_GAS = 20000; // should be enough to make plug inbound call and handle error if needed

    constructor(uint256 _chainId) {
        chainId = _chainId;
    }

    function setInboundConfig(
        uint256 remoteChainId,
        address channel,
        address executor,
        address prover,
        uint256 requiredConfs,
        bool isBlocking
    ) external override {
        InboundConfig storage config = inboundConfigs[msg.sender][remoteChainId];
        config.channel = channel;
        config.executor = executor;
        config.prover = prover;
        config.requiredConfs = requiredConfs;
        config.isBlocking = isBlocking;
    }

    function setOutboundConfig(
        uint256 remoteChainId,
        address channel,
        address executor,
        address prover
    ) external override {
        OutboundConfig storage config = outboundConfigs[msg.sender][remoteChainId];
        config.channel = channel;
        config.executor = executor;
        config.prover = prover;
    }

    function outbound(
        uint256 remoteChainId,
        address remotePlug,
        bytes calldata payload
    ) external override {
        uint256 nonce = nonces[msg.sender][remoteChainId]++;
        OutboundConfig memory config = outboundConfigs[msg.sender][remoteChainId];

        Packet memory p = Packet(chainId, msg.sender, address(this), remotePlug, remoteChainId, nonce, payload);
        IProver(config.prover).addPacket(p);

        emit Transmit(p);
        IChannel(config.channel).notify(p);
        IExecutor(config.executor).notify(p);
    }

    function sync(
        bytes32 root,
        uint256 _confirmations,
        uint256 remoteChainId
    ) external override {
        require(confirmations[msg.sender][remoteChainId][root] < _confirmations, "Socket: invalid confirmations");
        confirmations[msg.sender][remoteChainId][root] = _confirmations;
        emit Sync(root, _confirmations, remoteChainId);
    }

    function execute(
        bytes calldata proof,
        Packet calldata packet,
        bytes32 root
    ) external override {
        address plug = packet.dstPlug;
        uint256 remoteChainId = packet.srcChainId;
        InboundConfig memory config = inboundConfigs[plug][remoteChainId];

        require(
            confirmations[config.channel][remoteChainId][root] >= config.requiredConfs,
            "Socket: Need confirmations"
        );
        require(config.executor == msg.sender, "Socket: Invalid executor");

        require(IProver(config.prover).validatePacket(root, packet, proof), "Socket: INVALID_PROOF");

        if (config.isBlocking) {
            require(nextNonceToProcess[packet.srcPlug][packet.srcChainId]++ == packet.nonce, "Socket: INVALID_NONCE");
        }

        bytes32 packetId = keccak256(abi.encode(packet));
        require(!executeStatus[packetId], "Socket: PROCESSED");
        executeStatus[packetId] = true;
        emit Executing(packet);

        try IPlug(plug).inbound{ gas: gasleft() - RESERVE_GAS }(packet.payload) {
            emit ExecutionSuccess(packetId);
        } catch (bytes memory) {
            executeStatus[packetId] = false;
            emit ExecutionFailure(packetId);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.4;

interface ISocket {
    // Transmit is emitted when a packet is ready for transmission
    event Transmit(Packet _packet);

    event Sync(bytes32 root, uint256 confirmations, uint256 chainId);

    event Executing(Packet _packet);
    event ExecutionSuccess(bytes32 packetId);
    event ExecutionFailure(bytes32 packetId);

    // Packet is sent across-layers via Socket
    // its encoded on the local Socket
    // and decoded on the remote Socket
    // to execute there
    struct Packet {
        uint256 srcChainId;
        address srcPlug;
        address srcSocket;
        address dstPlug;
        uint256 dstChainId;
        uint256 nonce;
        bytes payload;
    }

    struct InboundConfig {
        address channel;
        address executor;
        address prover;
        uint256 requiredConfs;
        bool isBlocking;
    }

    struct OutboundConfig {
        address channel;
        address executor;
        address prover;
    }

    function setInboundConfig(
        uint256 remoteChainId,
        address channel,
        address executor,
        address prover,
        uint256 requiredConfs,
        bool isBlocking
    ) external;

    function setOutboundConfig(
        uint256 remoteChainId,
        address channel,
        address executor,
        address prover
    ) external;

    // plug
    function outbound(
        uint256 remoteChainId,
        address remotePlug,
        bytes calldata payload
    ) external;

    // channel
    function sync(
        bytes32 root,
        uint256 confs,
        uint256 chainID
    ) external;

    // executor
    // NOTICE
    // relayer will prove payload exits in root
    function execute(
        bytes memory proof,
        Packet memory packet,
        bytes32 root
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.4;

import "./ISocket.sol";

interface IChannel {
    function notify(ISocket.Packet calldata packet) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.4;

import "./ISocket.sol";

interface IExecutor {
    function notify(ISocket.Packet calldata packet) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.4;

interface IPlug {
    function inbound(bytes calldata payload) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.4;
pragma abicoder v2;

import { ISocket } from "./ISocket.sol";

interface IProver {
    //     function validateProof(bytes32 blockData, bytes calldata _data, uint _remoteAddressSize) external returns (Packet memory packet);
    function validatePacket(
        bytes32 root,
        ISocket.Packet calldata packet,
        bytes calldata proof
    ) external returns (bool);

    function addPacket(ISocket.Packet calldata packet) external;
}