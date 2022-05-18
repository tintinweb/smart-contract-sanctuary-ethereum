// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.4;

import "../../interfaces/IPlug.sol";
import "../../interfaces/ISocket.sol";

contract CounterMock is IPlug {
    uint256 public counter;
    address public immutable socket;
    uint256 public remoteChainId;
    address public remotePlug;

    bytes32 OP_ADD = keccak256("OP_ADD");
    bytes32 OP_SUB = keccak256("OP_SUB");

    constructor(address _socket) {
        socket = _socket;
    }

    function setSocketConfig(
        uint256 chainId,
        address plug,
        address channel,
        address executor,
        address prover,
        uint256 requiredConfs,
        bool isBlocking
    ) public {
        remoteChainId = chainId;
        remotePlug = plug;
        ISocket(socket).setInboundConfig(chainId, channel, executor, prover, requiredConfs, isBlocking);
        ISocket(socket).setOutboundConfig(chainId, channel, executor, prover);
    }

    function localAddOperation(uint256 amount) public {
        _addOperation(amount);
    }

    function localSubOperation(uint256 amount) public {
        _subOperation(amount);
    }

    function remoteAddOperation(uint256 amount) public {
        bytes memory payload = abi.encode(OP_ADD, amount);
        _outbound(payload);
    }

    function remoteSubOperation(uint256 amount) public {
        bytes memory payload = abi.encode(OP_SUB, amount);
        _outbound(payload);
    }

    function inbound(bytes calldata payload) external override {
        require(msg.sender == socket, "CounterMock: Invalid Socket");
        (bytes32 operationType, uint256 amount) = abi.decode(payload, (bytes32, uint256));

        if (operationType == OP_ADD) {
            _addOperation(amount);
        } else if (operationType == OP_SUB) {
            _subOperation(amount);
        } else {
            revert("CounterMock: Invalid Operation");
        }
    }

    function _outbound(bytes memory payload) private {
        ISocket(socket).outbound(remoteChainId, remotePlug, payload);
    }

    function _addOperation(uint256 amount) private {
        counter += amount;
    }

    function _subOperation(uint256 amount) private {
        counter -= amount;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.4;

interface IPlug {
    function inbound(bytes calldata payload) external;
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