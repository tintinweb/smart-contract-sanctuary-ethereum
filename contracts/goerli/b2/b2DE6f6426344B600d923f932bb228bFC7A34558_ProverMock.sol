// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.4;

import "../../interfaces/ISocket.sol";
import "../../interfaces/IProver.sol";

contract ProverMock is IProver {
    function validatePacket(
        bytes32 root,
        ISocket.Packet calldata packet,
        bytes calldata proof
    ) external override returns (bool) {
      return true;
    }

    function addPacket(ISocket.Packet calldata packet) external override {}
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