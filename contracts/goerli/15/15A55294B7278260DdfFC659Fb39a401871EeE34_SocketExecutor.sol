// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.4;

import "../../interfaces/ISocket.sol";
import "../../interfaces/IExecutor.sol";

contract SocketExecutor is IExecutor {
    event ExecutorNotifyPacket(ISocket.Packet packet);
    address immutable socket;
    address immutable owner;

    constructor(address _socket) {
        socket = _socket;
        owner = msg.sender;
    }

    function notify(ISocket.Packet calldata packet) external override {
        require(msg.sender == socket, "SocketExecutor: Only Socket");
        emit ExecutorNotifyPacket(packet);
    }

    function execute(
        bytes calldata proof,
        ISocket.Packet calldata packet,
        bytes32 root
    ) external {
        require(msg.sender == owner, "SocketExecutor: Only owner");
        ISocket(socket).execute(proof, packet, root);
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

interface IExecutor {
    function notify(ISocket.Packet calldata packet) external;
}