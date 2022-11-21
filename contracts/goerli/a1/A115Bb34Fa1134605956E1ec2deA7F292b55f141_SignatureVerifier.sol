// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "./interfaces/IAccumulator.sol";
import "./interfaces/IDeaccumulator.sol";
import "./interfaces/IVerifier.sol";
import "./interfaces/IPlug.sol";
import "./interfaces/IHasher.sol";
import "./utils/ReentrancyGuard.sol";

import "./SocketConfig.sol";

contract Socket is SocketConfig, ReentrancyGuard {
    enum MessageStatus {
        NOT_EXECUTED,
        SUCCESS,
        FAILED
    }

    uint256 private immutable _chainSlug;

    bytes32 private constant EXECUTOR_ROLE = keccak256("EXECUTOR");

    // incrementing nonce, should be handled in next socket version.
    uint256 private _messageCount;

    // msgId => executorAddress
    mapping(uint256 => address) private executor;

    // msgId => message status
    mapping(uint256 => MessageStatus) private _messagesStatus;

    IHasher public hasher;
    IVault public override vault;

    /**
     * @param chainSlug_ socket chain slug (should not be more than uint32)
     */
    constructor(
        uint32 chainSlug_,
        address hasher_,
        address vault_
    ) {
        _setHasher(hasher_);
        _setVault(vault_);

        _chainSlug = chainSlug_;
    }

    function setHasher(address hasher_) external onlyOwner {
        _setHasher(hasher_);
    }

    function setVault(address vault_) external onlyOwner {
        _setVault(vault_);
    }

    /**
     * @notice registers a message
     * @dev Packs the message and includes it in a packet with accumulator
     * @param remoteChainSlug_ the remote chain id
     * @param msgGasLimit_ the gas limit needed to execute the payload on remote
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function outbound(
        uint256 remoteChainSlug_,
        uint256 msgGasLimit_,
        bytes calldata payload_
    ) external payable override {
        PlugConfig memory plugConfig = plugConfigs[msg.sender][
            remoteChainSlug_
        ];

        // Packs the local plug, local chain id, remote chain id and nonce
        // _messageCount++ will take care of msg id overflow as well
        // msgId(256) = localChainSlug(32) | nonce(224)
        uint256 msgId = (uint256(uint32(_chainSlug)) << 224) | _messageCount++;

        vault.deductFee{value: msg.value}(
            remoteChainSlug_,
            plugConfig.integrationType
        );

        bytes32 packedMessage = hasher.packMessage(
            _chainSlug,
            msg.sender,
            remoteChainSlug_,
            plugConfig.remotePlug,
            msgId,
            msgGasLimit_,
            payload_
        );

        IAccumulator(plugConfig.accum).addPackedMessage(packedMessage);
        emit MessageTransmitted(
            _chainSlug,
            msg.sender,
            remoteChainSlug_,
            plugConfig.remotePlug,
            msgId,
            msgGasLimit_,
            msg.value,
            payload_
        );
    }

    /**
     * @notice executes a message
     * @param msgGasLimit gas limit needed to execute the inbound at remote
     * @param msgId message id packed with local plug, local chainSlug, remote ChainSlug and nonce
     * @param localPlug remote plug address
     * @param payload the data which is needed by plug at inbound call on remote
     * @param verifyParams_ the details needed for message verification
     */
    function execute(
        uint256 msgGasLimit,
        uint256 msgId,
        address localPlug,
        bytes calldata payload,
        ISocket.VerificationParams calldata verifyParams_
    ) external override nonReentrant {
        if (!_hasRole(EXECUTOR_ROLE, msg.sender)) revert ExecutorNotFound();
        if (executor[msgId] != address(0)) revert MessageAlreadyExecuted();
        executor[msgId] = msg.sender;

        PlugConfig memory plugConfig = plugConfigs[localPlug][
            verifyParams_.remoteChainSlug
        ];
        bytes32 packedMessage = hasher.packMessage(
            verifyParams_.remoteChainSlug,
            plugConfig.remotePlug,
            _chainSlug,
            localPlug,
            msgId,
            msgGasLimit,
            payload
        );

        _verify(packedMessage, plugConfig, verifyParams_);
        _execute(localPlug, msgGasLimit, msgId, payload);
    }

    function _verify(
        bytes32 packedMessage,
        PlugConfig memory plugConfig,
        ISocket.VerificationParams calldata verifyParams_
    ) internal view {
        (bool isVerified, bytes32 root) = IVerifier(plugConfig.verifier)
            .verifyPacket(verifyParams_.packetId, plugConfig.integrationType);

        if (!isVerified) revert VerificationFailed();

        if (
            !IDeaccumulator(plugConfig.deaccum).verifyMessageInclusion(
                root,
                packedMessage,
                verifyParams_.deaccumProof
            )
        ) revert InvalidProof();
    }

    function _execute(
        address localPlug,
        uint256 msgGasLimit,
        uint256 msgId,
        bytes calldata payload
    ) internal {
        try IPlug(localPlug).inbound{gas: msgGasLimit}(payload) {
            _messagesStatus[msgId] = MessageStatus.SUCCESS;
            emit ExecutionSuccess(msgId);
        } catch Error(string memory reason) {
            // catch failing revert() and require()
            _messagesStatus[msgId] = MessageStatus.FAILED;
            emit ExecutionFailed(msgId, reason);
        } catch (bytes memory reason) {
            // catch failing assert()
            _messagesStatus[msgId] = MessageStatus.FAILED;
            emit ExecutionFailedBytes(msgId, reason);
        }
    }

    /**
     * @notice adds an executor
     * @param executor_ executor address
     */
    function grantExecutorRole(address executor_) external onlyOwner {
        _grantRole(EXECUTOR_ROLE, executor_);
    }

    /**
     * @notice removes an executor from `remoteChainSlug_` chain list
     * @param executor_ executor address
     */
    function revokeExecutorRole(address executor_) external onlyOwner {
        _revokeRole(EXECUTOR_ROLE, executor_);
    }

    function _setHasher(address hasher_) private {
        hasher = IHasher(hasher_);
    }

    function _setVault(address vault_) private {
        vault = IVault(vault_);
    }

    function chainSlug() external view returns (uint256) {
        return _chainSlug;
    }

    function getMessageStatus(uint256 msgId_)
        external
        view
        returns (MessageStatus)
    {
        return _messagesStatus[msgId_];
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface IAccumulator {
    /**
     * @notice emits the message details when it arrives
     * @param packedMessage the message packed with payload, fees and config
     * @param packetId an incremental id assigned to each new packet
     * @param newRootHash the packed message hash (to be replaced with the root hash of the merkle tree)
     */
    event MessageAdded(
        bytes32 packedMessage,
        uint256 packetId,
        bytes32 newRootHash
    );

    /**
     * @notice emits when the packet is sealed and indicates it can be send to remote
     * @param rootHash the packed message hash (to be replaced with the root hash of the merkle tree)
     * @param packetId an incremental id assigned to each new packet
     */
    event PacketComplete(bytes32 rootHash, uint256 packetId);

    /**
     * @notice adds the packed message to a packet
     * @dev this should be only executable by socket
     * @dev it will be later replaced with a function adding each message to a merkle tree
     * @param packedMessage the message packed with payload, fees and config
     */
    function addPackedMessage(bytes32 packedMessage) external;

    /**
     * @notice returns the latest packet details which needs to be sealed
     * @return root root hash of the latest packet which is not yet sealed
     * @return packetId latest packet id which is not yet sealed
     */
    function getNextPacketToBeSealed()
        external
        view
        returns (bytes32 root, uint256 packetId);

    /**
     * @notice returns the root of packet for given id
     * @param id the id assigned to packet
     * @return root root hash corresponding to given id
     */
    function getRootById(uint256 id) external view returns (bytes32 root);

    /**
     * @notice seals the packet
     * @dev also indicates the packet is ready to be shipped and no more messages can be added now.
     * @dev this should be executable by notary only
     * @return root root hash of the packet
     * @return packetId id of the packed sealed
     * @return remoteChainSlug remote chain id for the packet sealed
     */
    function sealPacket(uint256[] calldata bridgeParams)
        external
        payable
        returns (
            bytes32 root,
            uint256 packetId,
            uint256 remoteChainSlug
        );
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface IDeaccumulator {
    /**
     * @notice returns if the packed message is the part of a merkle tree or not
     * @param root_ root hash of the merkle tree
     * @param packedMessage_ packed message which needs to be verified
     * @param proof_ proof used to determine the inclusion
     */
    function verifyMessageInclusion(
        bytes32 root_,
        bytes32 packedMessage_,
        bytes calldata proof_
    ) external pure returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface IVerifier {
    /**
     * @notice verifies if the packet satisfies needed checks before execution
     * @param packetId_ packet id
     */
    function verifyPacket(uint256 packetId_, bytes32 integrationType_)
        external
        view
        returns (bool, bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface IPlug {
    /**
     * @notice executes the message received from source chain
     * @dev this should be only executable by socket
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function inbound(bytes calldata payload_) external payable;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface IHasher {
    /**
     * @notice returns the bytes32 hash of the message packed
     * @param srcChainSlug src chain id
     * @param srcPlug address of plug at source
     * @param dstChainSlug remote chain id
     * @param dstPlug address of plug at remote
     * @param msgId message id assigned at outbound
     * @param msgGasLimit gas limit which is expected to be consumed by the inbound transaction on plug
     * @param payload the data packed which is used by inbound for execution
     */
    function packMessage(
        uint256 srcChainSlug,
        address srcPlug,
        uint256 dstChainSlug,
        address dstPlug,
        uint256 msgId,
        uint256 msgGasLimit,
        bytes calldata payload
    ) external returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "./interfaces/ISocket.sol";
import "./utils/AccessControl.sol";

abstract contract SocketConfig is ISocket, AccessControl(msg.sender) {
    // integrationType => remoteChainSlug => address
    mapping(bytes32 => mapping(uint256 => address)) public verifiers;
    mapping(bytes32 => mapping(uint256 => address)) public accums;
    mapping(bytes32 => mapping(uint256 => address)) public deaccums;
    mapping(bytes32 => mapping(uint256 => bool)) public configExists;

    // plug => remoteChainSlug => config(verifiers, accums, deaccums, remotePlug)
    mapping(address => mapping(uint256 => PlugConfig)) public plugConfigs;

    function addConfig(
        uint256 remoteChainSlug_,
        address accum_,
        address deaccum_,
        address verifier_,
        string calldata integrationType_
    ) external returns (bytes32 integrationType) {
        integrationType = keccak256(abi.encode(integrationType_));
        if (configExists[integrationType][remoteChainSlug_])
            revert ConfigExists();

        verifiers[integrationType][remoteChainSlug_] = verifier_;
        accums[integrationType][remoteChainSlug_] = accum_;
        deaccums[integrationType][remoteChainSlug_] = deaccum_;
        configExists[integrationType][remoteChainSlug_] = true;

        emit ConfigAdded(
            accum_,
            deaccum_,
            verifier_,
            remoteChainSlug_,
            integrationType
        );
    }

    /// @inheritdoc ISocket
    function setPlugConfig(
        uint256 remoteChainSlug_,
        address remotePlug_,
        string memory integrationType_
    ) external override {
        bytes32 integrationType = keccak256(abi.encode(integrationType_));
        if (!configExists[integrationType][remoteChainSlug_])
            revert InvalidIntegrationType();

        PlugConfig storage plugConfig = plugConfigs[msg.sender][
            remoteChainSlug_
        ];

        plugConfig.remotePlug = remotePlug_;
        plugConfig.accum = accums[integrationType][remoteChainSlug_];
        plugConfig.deaccum = deaccums[integrationType][remoteChainSlug_];
        plugConfig.verifier = verifiers[integrationType][remoteChainSlug_];
        plugConfig.integrationType = integrationType;

        emit PlugConfigSet(remotePlug_, remoteChainSlug_, integrationType);
    }

    function getConfigs(
        uint256 remoteChainSlug_,
        string memory integrationType_
    )
        external
        view
        returns (
            address,
            address,
            address
        )
    {
        bytes32 integrationType = keccak256(abi.encode(integrationType_));
        return (
            accums[integrationType][remoteChainSlug_],
            deaccums[integrationType][remoteChainSlug_],
            verifiers[integrationType][remoteChainSlug_]
        );
    }

    function getPlugConfig(uint256 remoteChainSlug_, address plug_)
        external
        view
        returns (
            address accum,
            address deaccum,
            address verifier,
            address remotePlug
        )
    {
        PlugConfig memory plugConfig = plugConfigs[plug_][remoteChainSlug_];
        return (
            plugConfig.accum,
            plugConfig.deaccum,
            plugConfig.verifier,
            plugConfig.remotePlug
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./IVault.sol";

interface ISocket {
    // to handle stack too deep
    struct VerificationParams {
        uint256 remoteChainSlug;
        uint256 packetId;
        bytes deaccumProof;
    }

    // TODO: add confs and blocking/non-blocking
    struct PlugConfig {
        address remotePlug;
        address accum;
        address deaccum;
        address verifier;
        bytes32 integrationType;
    }

    /**
     * @notice emits the message details when a new message arrives at outbound
     * @param localChainSlug local chain id
     * @param localPlug local plug address
     * @param dstChainSlug remote chain id
     * @param dstPlug remote plug address
     * @param msgId message id packed with remoteChainSlug and nonce
     * @param msgGasLimit gas limit needed to execute the inbound at remote
     * @param fees fees provided by msg sender
     * @param payload the data which will be used by inbound at remote
     */
    event MessageTransmitted(
        uint256 localChainSlug,
        address localPlug,
        uint256 dstChainSlug,
        address dstPlug,
        uint256 msgId,
        uint256 msgGasLimit,
        uint256 fees,
        bytes payload
    );

    event ConfigAdded(
        address accum_,
        address deaccum_,
        address verifier_,
        uint256 remoteChainSlug_,
        bytes32 integrationType_
    );

    /**
     * @notice emits the status of message after inbound call
     * @param msgId msg id which is executed
     */
    event ExecutionSuccess(uint256 msgId);

    /**
     * @notice emits the status of message after inbound call
     * @param msgId msg id which is executed
     * @param result if message reverts, returns the revert message
     */
    event ExecutionFailed(uint256 msgId, string result);

    /**
     * @notice emits the error message in bytes after inbound call
     * @param msgId msg id which is executed
     * @param result if message reverts, returns the revert message in bytes
     */
    event ExecutionFailedBytes(uint256 msgId, bytes result);

    event PlugConfigSet(
        address remotePlug,
        uint256 remoteChainSlug,
        bytes32 integrationType
    );

    error InvalidProof();

    error VerificationFailed();

    error MessageAlreadyExecuted();

    error ExecutorNotFound();

    error ConfigExists();

    error InvalidIntegrationType();

    function vault() external view returns (IVault);

    /**
     * @notice registers a message
     * @dev Packs the message and includes it in a packet with accumulator
     * @param remoteChainSlug_ the remote chain id
     * @param msgGasLimit_ the gas limit needed to execute the payload on remote
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function outbound(
        uint256 remoteChainSlug_,
        uint256 msgGasLimit_,
        bytes calldata payload_
    ) external payable;

    /**
     * @notice executes a message
     * @param msgGasLimit gas limit needed to execute the inbound at remote
     * @param msgId message id packed with remoteChainSlug and nonce
     * @param localPlug remote plug address
     * @param payload the data which is needed by plug at inbound call on remote
     * @param verifyParams_ the details needed for message verification
     */
    function execute(
        uint256 msgGasLimit,
        uint256 msgId,
        address localPlug,
        bytes calldata payload,
        ISocket.VerificationParams calldata verifyParams_
    ) external;

    /**
     * @notice sets the config specific to the plug
     * @param remoteChainSlug_ the remote chain id
     * @param remotePlug_ address of plug present at remote chain to call inbound
     * @param integrationType_ the name of accum to be used
     */
    function setPlugConfig(
        uint256 remoteChainSlug_,
        address remotePlug_,
        string memory integrationType_
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "./Ownable.sol";

abstract contract AccessControl is Ownable {
    // role => address => permit
    mapping(bytes32 => mapping(address => bool)) private _permits;

    event RoleGranted(bytes32 indexed role, address indexed grantee);

    event RoleRevoked(bytes32 indexed role, address indexed revokee);

    error NoPermit(bytes32 role);

    constructor(address owner_) Ownable(owner_) {}

    modifier onlyRole(bytes32 role) {
        if (!_permits[role][msg.sender]) revert NoPermit(role);
        _;
    }

    function grantRole(bytes32 role, address grantee)
        external
        virtual
        onlyOwner
    {
        _grantRole(role, grantee);
    }

    function revokeRole(bytes32 role, address revokee)
        external
        virtual
        onlyOwner
    {
        _revokeRole(role, revokee);
    }

    function _grantRole(bytes32 role, address grantee) internal {
        _permits[role][grantee] = true;
        emit RoleGranted(role, grantee);
    }

    function _revokeRole(bytes32 role, address revokee) internal {
        _permits[role][revokee] = false;
        emit RoleRevoked(role, revokee);
    }

    function hasRole(bytes32 role, address _address)
        external
        view
        returns (bool)
    {
        return _hasRole(role, _address);
    }

    function _hasRole(bytes32 role, address _address)
        internal
        view
        returns (bool)
    {
        return _permits[role][_address];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface IVault {
    /**
     * @notice deducts the fee required to bridge the packet using msgGasLimit
     * @param remoteChainSlug_ remote chain id
     * @param integrationType_ for the given message
     */
    function deductFee(uint256 remoteChainSlug_, bytes32 integrationType_)
        external
        payable;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

abstract contract Ownable {
    address private _owner;
    address private _nominee;

    event OwnerNominated(address indexed nominee);
    event OwnerClaimed(address indexed claimer);

    error OnlyOwner();
    error OnlyNominee();

    constructor(address owner_) {
        _claimOwner(owner_);
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) revert OnlyOwner();
        _;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function nominee() external view returns (address) {
        return _nominee;
    }

    function nominateOwner(address nominee_) external {
        if (msg.sender != _owner) revert OnlyOwner();
        _nominee = nominee_;
        emit OwnerNominated(_nominee);
    }

    function claimOwner() external {
        if (msg.sender != _nominee) revert OnlyNominee();
        _claimOwner(msg.sender);
    }

    function _claimOwner(address claimer_) internal {
        _owner = claimer_;
        _nominee = address(0);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/IVerifier.sol";
import "../interfaces/INotary.sol";

import "../utils/Ownable.sol";

contract Verifier is IVerifier, Ownable {
    INotary public notary;
    uint256 public immutable timeoutInSeconds;

    // this integration type is set for fast accum
    // it is compared against the passed accum type to decide packet verification mode
    bytes32 public immutable fastIntegrationType;

    event NotarySet(address notary_);

    constructor(
        address owner_,
        address notary_,
        uint256 timeoutInSeconds_,
        bytes32 fastIntegrationType_
    ) Ownable(owner_) {
        notary = INotary(notary_);
        fastIntegrationType = fastIntegrationType_;

        // TODO: restrict the timeout durations to a few select options
        timeoutInSeconds = timeoutInSeconds_;
    }

    /**
     * @notice updates notary
     * @param notary_ address of Notary
     */
    function setNotary(address notary_) external onlyOwner {
        notary = INotary(notary_);
        emit NotarySet(notary_);
    }

    /**
     * @notice verifies if the packet satisfies needed checks before execution
     * @param packetId_ packet id
     * @param fastIntegrationType_ integration type for plug
     */
    function verifyPacket(uint256 packetId_, bytes32 fastIntegrationType_)
        external
        view
        override
        returns (bool, bytes32)
    {
        bool isFast = fastIntegrationType == fastIntegrationType_
            ? true
            : false;

        (
            INotary.PacketStatus status,
            uint256 packetArrivedAt,
            uint256 pendingAttestations,
            bytes32 root
        ) = notary.getPacketDetails(packetId_);

        if (status != INotary.PacketStatus.PROPOSED) return (false, root);
        // if timed out, return true irrespective of fast or slow accum
        if (block.timestamp - packetArrivedAt > timeoutInSeconds)
            return (true, root);

        // if fast, check attestations
        if (isFast) {
            if (pendingAttestations == 0) return (true, root);
        }

        return (false, root);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface INotary {
    struct PacketDetails {
        bytes32 remoteRoots;
        uint256 attestations;
        uint256 timeRecord;
    }

    enum PacketStatus {
        NOT_PROPOSED,
        PROPOSED
    }

    /**
     * @notice emits when a new signature verifier contract is set
     * @param signatureVerifier_ address of new verifier contract
     */
    event SignatureVerifierSet(address signatureVerifier_);

    /**
     * @notice emits the verification and seal confirmation of a packet
     * @param attester address of attester
     * @param accumAddress address of accumulator at local
     * @param packetId packed id
     * @param signature signature of attester
     */
    event PacketVerifiedAndSealed(
        address indexed attester,
        address indexed accumAddress,
        uint256 indexed packetId,
        bytes signature
    );

    /**
     * @notice emits the packet details when proposed at remote
     * @param packetId packet id
     * @param root packet root
     */
    event PacketProposed(uint256 indexed packetId, bytes32 root);

    /**
     * @notice emits when a packet is attested by attester at remote
     * @param attester address of attester
     * @param packetId packet id
     */
    event PacketAttested(address indexed attester, uint256 indexed packetId);

    /**
     * @notice emits the root details when root is replaced by owner
     * @param packetId packet id
     * @param oldRoot old root
     * @param newRoot old root
     */
    event PacketRootUpdated(uint256 packetId, bytes32 oldRoot, bytes32 newRoot);

    error InvalidAttester();
    error AttesterExists();
    error AttesterNotFound();
    error AlreadyAttested();
    error RootNotFound();

    /**
     * @notice verifies the attester and seals a packet
     * @param accumAddress_ address of accumulator at local
     * @param signature_ signature of attester
     */
    function seal(
        address accumAddress_,
        uint256[] calldata bridgeParams,
        bytes calldata signature_
    ) external payable;

    /**
     * @notice to propose a new packet
     * @param packetId_ packet id
     * @param root_ root hash of packet
     * @param signature_ signature of proposer
     */
    function attest(
        uint256 packetId_,
        bytes32 root_,
        bytes calldata signature_
    ) external;

    /**
     * @notice returns the root of given packet
     * @param packetId_ packet id
     * @return root_ root hash
     */
    function getRemoteRoot(uint256 packetId_)
        external
        view
        returns (bytes32 root_);

    /**
     * @notice returns the packet status
     * @param packetId_ packet id
     * @return status_ status as enum PacketStatus
     */
    function getPacketStatus(uint256 packetId_)
        external
        view
        returns (PacketStatus status_);

    /**
     * @notice returns the packet details needed by verifier
     * @param packetId_ packet id
     * @return status packet status
     * @return packetArrivedAt time at which packet was proposed
     * @return pendingAttestations number of attestations remaining
     * @return root root hash
     */
    function getPacketDetails(uint256 packetId_)
        external
        view
        returns (
            PacketStatus status,
            uint256 packetArrivedAt,
            uint256 pendingAttestations,
            bytes32 root
        );
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/IVerifier.sol";
import "../interfaces/INotary.sol";

import "../utils/Ownable.sol";

contract NativeBridgeVerifier is IVerifier, Ownable {
    INotary public notary;
    event NotarySet(address notary_);

    constructor(address owner_, address notary_) Ownable(owner_) {
        notary = INotary(notary_);
    }

    /**
     * @notice updates notary
     * @param notary_ address of Notary
     */
    function setNotary(address notary_) external onlyOwner {
        notary = INotary(notary_);
        emit NotarySet(notary_);
    }

    /**
     * @notice verifies if the packet satisfies needed checks before execution
     * @param packetId_ packet id
     */
    function verifyPacket(uint256 packetId_, bytes32)
        external
        view
        override
        returns (bool, bytes32)
    {
        (INotary.PacketStatus status, , , bytes32 root) = notary
            .getPacketDetails(packetId_);

        if (status == INotary.PacketStatus.PROPOSED) return (true, root);
        return (false, root);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../../utils/AccessControl.sol";
import "../../utils/ReentrancyGuard.sol";

import "../../interfaces/INotary.sol";
import "../../interfaces/IAccumulator.sol";
import "../../interfaces/ISignatureVerifier.sol";

abstract contract NativeBridgeNotary is
    INotary,
    AccessControl,
    ReentrancyGuard
{
    address public remoteTarget;
    uint256 private immutable _chainSlug;
    ISignatureVerifier public signatureVerifier;

    // accumAddr|chainSlug|packetId
    mapping(uint256 => bytes32) private _remoteRoots;

    event UpdatedRemoteTarget(address remoteTarget);
    error InvalidSender();

    modifier onlyRemoteAccumulator() virtual {
        _;
    }

    constructor(
        address signatureVerifier_,
        uint32 chainSlug_,
        address remoteTarget_
    ) AccessControl(msg.sender) {
        _chainSlug = chainSlug_;
        signatureVerifier = ISignatureVerifier(signatureVerifier_);

        remoteTarget = remoteTarget_;
    }

    function updateRemoteTarget(address remoteTarget_) external onlyOwner {
        remoteTarget = remoteTarget_;
        emit UpdatedRemoteTarget(remoteTarget_);
    }

    /// @inheritdoc INotary
    function seal(
        address accumAddress_,
        uint256[] calldata bridgeParams,
        bytes calldata signature_
    ) external payable override nonReentrant {
        (
            bytes32 root,
            uint256 packetCount,
            uint256 remoteChainSlug
        ) = IAccumulator(accumAddress_).sealPacket{value: msg.value}(
                bridgeParams
            );

        uint256 packetId = _getPacketId(accumAddress_, _chainSlug, packetCount);

        address attester = signatureVerifier.recoverSigner(
            remoteChainSlug,
            packetId,
            root,
            signature_
        );

        if (!_hasRole(_attesterRole(remoteChainSlug), attester))
            revert InvalidAttester();
        emit PacketVerifiedAndSealed(
            attester,
            accumAddress_,
            packetId,
            signature_
        );
    }

    /// @inheritdoc INotary
    function attest(
        uint256 packetId_,
        bytes32 root_,
        bytes calldata
    ) external override onlyRemoteAccumulator {
        _attest(packetId_, root_);
    }

    function _attest(uint256 packetId_, bytes32 root_) internal {
        if (_remoteRoots[packetId_] != bytes32(0)) revert AlreadyAttested();
        _remoteRoots[packetId_] = root_;

        emit PacketProposed(packetId_, root_);
        emit PacketAttested(msg.sender, packetId_);
    }

    /**
     * @notice updates root for given packet id
     * @param packetId_ id of packet to be updated
     * @param newRoot_ new root
     */
    function updatePacketRoot(uint256 packetId_, bytes32 newRoot_)
        external
        onlyOwner
    {
        bytes32 oldRoot = _remoteRoots[packetId_];
        _remoteRoots[packetId_] = newRoot_;

        emit PacketRootUpdated(packetId_, oldRoot, newRoot_);
    }

    /// @inheritdoc INotary
    function getPacketStatus(uint256 packetId_)
        external
        view
        override
        returns (PacketStatus status)
    {
        return
            _remoteRoots[packetId_] == bytes32(0)
                ? PacketStatus.NOT_PROPOSED
                : PacketStatus.PROPOSED;
    }

    /// @inheritdoc INotary
    function getPacketDetails(uint256 packetId_)
        external
        view
        override
        returns (
            PacketStatus,
            uint256,
            uint256,
            bytes32
        )
    {
        bytes32 root = _remoteRoots[packetId_];
        PacketStatus status = root == bytes32(0)
            ? PacketStatus.NOT_PROPOSED
            : PacketStatus.PROPOSED;

        return (status, 0, 0, root);
    }

    /**
     * @notice returns the attestations received by a packet
     * @param packetId_ packed id
     */
    function getAttestationCount(uint256 packetId_)
        external
        view
        returns (uint256)
    {
        return 1;
    }

    /**
     * @notice returns the remote root for given `packetId_`
     * @param packetId_ packed id
     */
    function getRemoteRoot(uint256 packetId_)
        external
        view
        override
        returns (bytes32)
    {
        return _remoteRoots[packetId_];
    }

    /**
     * @notice adds an attester for `remoteChainSlug_` chain
     * @param remoteChainSlug_ remote chain id
     * @param attester_ attester address
     */
    function grantAttesterRole(uint256 remoteChainSlug_, address attester_)
        external
        onlyOwner
    {
        if (_hasRole(_attesterRole(remoteChainSlug_), attester_))
            revert AttesterExists();

        _grantRole(_attesterRole(remoteChainSlug_), attester_);
    }

    /**
     * @notice removes an attester from `remoteChainSlug_` chain list
     * @param remoteChainSlug_ remote chain id
     * @param attester_ attester address
     */
    function revokeAttesterRole(uint256 remoteChainSlug_, address attester_)
        external
        onlyOwner
    {
        if (!_hasRole(_attesterRole(remoteChainSlug_), attester_))
            revert AttesterNotFound();

        _revokeRole(_attesterRole(remoteChainSlug_), attester_);
    }

    function _attesterRole(uint256 chainSlug_) internal pure returns (bytes32) {
        return bytes32(chainSlug_);
    }

    /**
     * @notice returns the current chain id
     */
    function chainSlug() external view returns (uint256) {
        return _chainSlug;
    }

    /**
     * @notice updates signatureVerifier_
     * @param signatureVerifier_ address of Signature Verifier
     */
    function setSignatureVerifier(address signatureVerifier_)
        external
        onlyOwner
    {
        signatureVerifier = ISignatureVerifier(signatureVerifier_);
        emit SignatureVerifierSet(signatureVerifier_);
    }

    function _getPacketId(
        address accumAddr_,
        uint256 chainSlug_,
        uint256 packetCount_
    ) internal pure returns (uint256 packetId) {
        packetId =
            (chainSlug_ << 224) |
            (uint256(uint160(accumAddr_)) << 64) |
            packetCount_;
    }

    function _getChainSlug(uint256 packetId_)
        internal
        pure
        returns (uint256 chainSlug_)
    {
        chainSlug_ = uint32(packetId_ >> 224);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface ISignatureVerifier {
    /**
     * @notice returns the address of signer recovered from input signature
     * @param dstChainSlug_ remote chain id
     * @param packetId_ packet id
     * @param root_ root hash of merkle tree
     * @param signature_ signature
     */
    function recoverSigner(
        uint256 dstChainSlug_,
        uint256 packetId_,
        bytes32 root_,
        bytes calldata signature_
    ) external pure returns (address signer);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import {NativeBridgeNotary} from "./NativeBridgeNotary.sol";
import "lib/contracts/contracts/tunnel/FxBaseRootTunnel.sol";

contract PolygonRootReceiver is NativeBridgeNotary, FxBaseRootTunnel {
    modifier onlyRemoteAccumulator() override {
        _;
    }

    constructor(
        address checkpointManager_,
        address fxRoot_,
        address signatureVerifier_,
        uint32 chainSlug_,
        address remoteTarget_
    )
        NativeBridgeNotary(signatureVerifier_, chainSlug_, remoteTarget_)
        FxBaseRootTunnel(checkpointManager_, fxRoot_)
    {}

    function _processMessageFromChild(bytes memory data)
        internal
        override
        onlyRemoteAccumulator
    {
        (uint256 packetId, bytes32 root, ) = abi.decode(
            data,
            (uint256, bytes32, bytes)
        );
        _attest(packetId, root);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RLPReader} from "../lib/RLPReader.sol";
import {MerklePatriciaProof} from "../lib/MerklePatriciaProof.sol";
import {Merkle} from "../lib/Merkle.sol";
import "../lib/ExitPayloadReader.sol";

interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

contract ICheckpointManager {
    struct HeaderBlock {
        bytes32 root;
        uint256 start;
        uint256 end;
        uint256 createdAt;
        address proposer;
    }

    /**
     * @notice mapping of checkpoint header numbers to block details
     * @dev These checkpoints are submited by plasma contracts
     */
    mapping(uint256 => HeaderBlock) public headerBlocks;
}

abstract contract FxBaseRootTunnel {
    using RLPReader for RLPReader.RLPItem;
    using Merkle for bytes32;
    using ExitPayloadReader for bytes;
    using ExitPayloadReader for ExitPayloadReader.ExitPayload;
    using ExitPayloadReader for ExitPayloadReader.Log;
    using ExitPayloadReader for ExitPayloadReader.LogTopics;
    using ExitPayloadReader for ExitPayloadReader.Receipt;

    // keccak256(MessageSent(bytes))
    bytes32 public constant SEND_MESSAGE_EVENT_SIG = 0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036;

    // state sender contract
    IFxStateSender public fxRoot;
    // root chain manager
    ICheckpointManager public checkpointManager;
    // child tunnel contract which receives and sends messages
    address public fxChildTunnel;

    // storage to avoid duplicate exits
    mapping(bytes32 => bool) public processedExits;

    constructor(address _checkpointManager, address _fxRoot) {
        checkpointManager = ICheckpointManager(_checkpointManager);
        fxRoot = IFxStateSender(_fxRoot);
    }

    // set fxChildTunnel if not set already
    function setFxChildTunnel(address _fxChildTunnel) public virtual {
        require(fxChildTunnel == address(0x0), "FxBaseRootTunnel: CHILD_TUNNEL_ALREADY_SET");
        fxChildTunnel = _fxChildTunnel;
    }

    /**
     * @notice Send bytes message to Child Tunnel
     * @param message bytes message that will be sent to Child Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToChild(bytes memory message) internal {
        fxRoot.sendMessageToChild(fxChildTunnel, message);
    }

    function _validateAndExtractMessage(bytes memory inputData) internal returns (bytes memory) {
        ExitPayloadReader.ExitPayload memory payload = inputData.toExitPayload();

        bytes memory branchMaskBytes = payload.getBranchMaskAsBytes();
        uint256 blockNumber = payload.getBlockNumber();
        // checking if exit has already been processed
        // unique exit is identified using hash of (blockNumber, branchMask, receiptLogIndex)
        bytes32 exitHash = keccak256(
            abi.encodePacked(
                blockNumber,
                // first 2 nibbles are dropped while generating nibble array
                // this allows branch masks that are valid but bypass exitHash check (changing first 2 nibbles only)
                // so converting to nibble array and then hashing it
                MerklePatriciaProof._getNibbleArray(branchMaskBytes),
                payload.getReceiptLogIndex()
            )
        );
        require(processedExits[exitHash] == false, "FxRootTunnel: EXIT_ALREADY_PROCESSED");
        processedExits[exitHash] = true;

        ExitPayloadReader.Receipt memory receipt = payload.getReceipt();
        ExitPayloadReader.Log memory log = receipt.getLog();

        // check child tunnel
        require(fxChildTunnel == log.getEmitter(), "FxRootTunnel: INVALID_FX_CHILD_TUNNEL");

        bytes32 receiptRoot = payload.getReceiptRoot();
        // verify receipt inclusion
        require(
            MerklePatriciaProof.verify(receipt.toBytes(), branchMaskBytes, payload.getReceiptProof(), receiptRoot),
            "FxRootTunnel: INVALID_RECEIPT_PROOF"
        );

        // verify checkpoint inclusion
        _checkBlockMembershipInCheckpoint(
            blockNumber,
            payload.getBlockTime(),
            payload.getTxRoot(),
            receiptRoot,
            payload.getHeaderNumber(),
            payload.getBlockProof()
        );

        ExitPayloadReader.LogTopics memory topics = log.getTopics();

        require(
            bytes32(topics.getField(0).toUint()) == SEND_MESSAGE_EVENT_SIG, // topic0 is event sig
            "FxRootTunnel: INVALID_SIGNATURE"
        );

        // received message data
        bytes memory message = abi.decode(log.getData(), (bytes)); // event decodes params again, so decoding bytes to get message
        return message;
    }

    function _checkBlockMembershipInCheckpoint(
        uint256 blockNumber,
        uint256 blockTime,
        bytes32 txRoot,
        bytes32 receiptRoot,
        uint256 headerNumber,
        bytes memory blockProof
    ) private view {
        (bytes32 headerRoot, uint256 startBlock, , uint256 createdAt, ) = checkpointManager.headerBlocks(headerNumber);

        require(
            keccak256(abi.encodePacked(blockNumber, blockTime, txRoot, receiptRoot)).checkMembership(
                blockNumber - startBlock,
                headerRoot,
                blockProof
            ),
            "FxRootTunnel: INVALID_HEADER"
        );
    }

    /**
     * @notice receive message from  L2 to L1, validated by proof
     * @dev This function verifies if the transaction actually happened on child chain
     *
     * @param inputData RLP encoded data of the reference tx containing following list of fields
     *  0 - headerNumber - Checkpoint header block number containing the reference tx
     *  1 - blockProof - Proof that the block header (in the child chain) is a leaf in the submitted merkle root
     *  2 - blockNumber - Block number containing the reference tx on child chain
     *  3 - blockTime - Reference tx block time
     *  4 - txRoot - Transactions root of block
     *  5 - receiptRoot - Receipts root of block
     *  6 - receipt - Receipt of the reference transaction
     *  7 - receiptProof - Merkle proof of the reference receipt
     *  8 - branchMask - 32 bits denoting the path of receipt in merkle tree
     *  9 - receiptLogIndex - Log Index to read from the receipt
     */
    function receiveMessage(bytes memory inputData) public virtual {
        bytes memory message = _validateAndExtractMessage(inputData);
        _processMessageFromChild(message);
    }

    /**
     * @notice Process message received from Child Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by receiveMessage function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param message bytes message that was sent from Child Tunnel
     */
    function _processMessageFromChild(bytes memory message) internal virtual;
}

/*
 * @author Hamdi Allam [email protected]
 * Please reach out with any questions or concerns
 */
pragma solidity ^0.8.0;

library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START = 0xb8;
    uint8 constant LIST_SHORT_START = 0xc0;
    uint8 constant LIST_LONG_START = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint256 len;
        uint256 memPtr;
    }

    struct Iterator {
        RLPItem item; // Item that's being iterated over.
        uint256 nextPtr; // Position of the next item in the list.
    }

    /*
     * @dev Returns the next element in the iteration. Reverts if it has not next element.
     * @param self The iterator.
     * @return The next element in the iteration.
     */
    function next(Iterator memory self) internal pure returns (RLPItem memory) {
        require(hasNext(self));

        uint256 ptr = self.nextPtr;
        uint256 itemLength = _itemLength(ptr);
        self.nextPtr = ptr + itemLength;

        return RLPItem(itemLength, ptr);
    }

    /*
     * @dev Returns true if the iteration has more elements.
     * @param self The iterator.
     * @return true if the iteration has more elements.
     */
    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self.item;
        return self.nextPtr < item.memPtr + item.len;
    }

    /*
     * @param item RLP encoded bytes
     */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        uint256 memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
     * @dev Create an iterator. Reverts if item is not a list.
     * @param self The RLP item.
     * @return An 'Iterator' over the item.
     */
    function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
        require(isList(self));

        uint256 ptr = self.memPtr + _payloadOffset(self.memPtr);
        return Iterator(self, ptr);
    }

    /*
     * @param item RLP encoded bytes
     */
    function rlpLen(RLPItem memory item) internal pure returns (uint256) {
        return item.len;
    }

    /*
     * @param item RLP encoded bytes
     */
    function payloadLen(RLPItem memory item) internal pure returns (uint256) {
        return item.len - _payloadOffset(item.memPtr);
    }

    /*
     * @param item RLP encoded list in bytes
     */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item));

        uint256 items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);

        uint256 memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 dataLen;
        for (uint256 i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint256 memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START) return false;
        return true;
    }

    /*
     * @dev A cheaper version of keccak256(toRlpBytes(item)) that avoids copying memory.
     * @return keccak256 hash of RLP encoded bytes.
     */
    function rlpBytesKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        uint256 ptr = item.memPtr;
        uint256 len = item.len;
        bytes32 result;
        assembly {
            result := keccak256(ptr, len)
        }
        return result;
    }

    function payloadLocation(RLPItem memory item) internal pure returns (uint256, uint256) {
        uint256 offset = _payloadOffset(item.memPtr);
        uint256 memPtr = item.memPtr + offset;
        uint256 len = item.len - offset; // data length
        return (memPtr, len);
    }

    /*
     * @dev A cheaper version of keccak256(toBytes(item)) that avoids copying memory.
     * @return keccak256 hash of the item payload.
     */
    function payloadKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        (uint256 memPtr, uint256 len) = payloadLocation(item);
        bytes32 result;
        assembly {
            result := keccak256(memPtr, len)
        }
        return result;
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;

        uint256 ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    // any non-zero byte < 128 is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        uint256 result;
        uint256 memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        return result == 0 ? false : true;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        require(item.len == 21);

        return address(uint160(toUint(item)));
    }

    function toUint(RLPItem memory item) internal pure returns (uint256) {
        require(item.len > 0 && item.len <= 33);

        uint256 offset = _payloadOffset(item.memPtr);
        uint256 len = item.len - offset;

        uint256 result;
        uint256 memPtr = item.memPtr + offset;
        assembly {
            result := mload(memPtr)

            // shift to the correct location if neccesary
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint256) {
        // one byte prefix
        require(item.len == 33);

        uint256 result;
        uint256 memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0);

        uint256 offset = _payloadOffset(item.memPtr);
        uint256 len = item.len - offset; // data length
        bytes memory result = new bytes(len);

        uint256 destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(item.memPtr + offset, destPtr, len);
        return result;
    }

    /*
     * Private Helpers
     */

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) private pure returns (uint256) {
        if (item.len == 0) return 0;

        uint256 count = 0;
        uint256 currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr); // skip over an item
            count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint256 memPtr) private pure returns (uint256) {
        uint256 itemLen;
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) itemLen = 1;
        else if (byte0 < STRING_LONG_START) itemLen = byte0 - STRING_SHORT_START + 1;
        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte
                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
        } else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        } else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint256 memPtr) private pure returns (uint256) {
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)) return 1;
        else if (byte0 < LIST_SHORT_START)
            // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else return byte0 - (LIST_LONG_START - 1) + 1;
    }

    /*
     * @param src Pointer to source
     * @param dest Pointer to destination
     * @param len Amount of memory to copy from the source
     */
    function copy(
        uint256 src,
        uint256 dest,
        uint256 len
    ) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        if (len == 0) return;

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint256 mask = 256**(WORD_SIZE - len) - 1;

        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }
}

pragma solidity ^0.8.0;

import {RLPReader} from "./RLPReader.sol";

library ExitPayloadReader {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    uint8 constant WORD_SIZE = 32;

    struct ExitPayload {
        RLPReader.RLPItem[] data;
    }

    struct Receipt {
        RLPReader.RLPItem[] data;
        bytes raw;
        uint256 logIndex;
    }

    struct Log {
        RLPReader.RLPItem data;
        RLPReader.RLPItem[] list;
    }

    struct LogTopics {
        RLPReader.RLPItem[] data;
    }

    // copy paste of private copy() from RLPReader to avoid changing of existing contracts
    function copy(
        uint256 src,
        uint256 dest,
        uint256 len
    ) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        if (len == 0) return;

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint256 mask = 256**(WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }

    function toExitPayload(bytes memory data) internal pure returns (ExitPayload memory) {
        RLPReader.RLPItem[] memory payloadData = data.toRlpItem().toList();

        return ExitPayload(payloadData);
    }

    function getHeaderNumber(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[0].toUint();
    }

    function getBlockProof(ExitPayload memory payload) internal pure returns (bytes memory) {
        return payload.data[1].toBytes();
    }

    function getBlockNumber(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[2].toUint();
    }

    function getBlockTime(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[3].toUint();
    }

    function getTxRoot(ExitPayload memory payload) internal pure returns (bytes32) {
        return bytes32(payload.data[4].toUint());
    }

    function getReceiptRoot(ExitPayload memory payload) internal pure returns (bytes32) {
        return bytes32(payload.data[5].toUint());
    }

    function getReceipt(ExitPayload memory payload) internal pure returns (Receipt memory receipt) {
        receipt.raw = payload.data[6].toBytes();
        RLPReader.RLPItem memory receiptItem = receipt.raw.toRlpItem();

        if (receiptItem.isList()) {
            // legacy tx
            receipt.data = receiptItem.toList();
        } else {
            // pop first byte before parsing receipt
            bytes memory typedBytes = receipt.raw;
            bytes memory result = new bytes(typedBytes.length - 1);
            uint256 srcPtr;
            uint256 destPtr;
            assembly {
                srcPtr := add(33, typedBytes)
                destPtr := add(0x20, result)
            }

            copy(srcPtr, destPtr, result.length);
            receipt.data = result.toRlpItem().toList();
        }

        receipt.logIndex = getReceiptLogIndex(payload);
        return receipt;
    }

    function getReceiptProof(ExitPayload memory payload) internal pure returns (bytes memory) {
        return payload.data[7].toBytes();
    }

    function getBranchMaskAsBytes(ExitPayload memory payload) internal pure returns (bytes memory) {
        return payload.data[8].toBytes();
    }

    function getBranchMaskAsUint(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[8].toUint();
    }

    function getReceiptLogIndex(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[9].toUint();
    }

    // Receipt methods
    function toBytes(Receipt memory receipt) internal pure returns (bytes memory) {
        return receipt.raw;
    }

    function getLog(Receipt memory receipt) internal pure returns (Log memory) {
        RLPReader.RLPItem memory logData = receipt.data[3].toList()[receipt.logIndex];
        return Log(logData, logData.toList());
    }

    // Log methods
    function getEmitter(Log memory log) internal pure returns (address) {
        return RLPReader.toAddress(log.list[0]);
    }

    function getTopics(Log memory log) internal pure returns (LogTopics memory) {
        return LogTopics(log.list[1].toList());
    }

    function getData(Log memory log) internal pure returns (bytes memory) {
        return log.list[2].toBytes();
    }

    function toRlpBytes(Log memory log) internal pure returns (bytes memory) {
        return log.data.toRlpBytes();
    }

    // LogTopics methods
    function getField(LogTopics memory topics, uint256 index) internal pure returns (RLPReader.RLPItem memory) {
        return topics.data[index];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RLPReader} from "./RLPReader.sol";

library MerklePatriciaProof {
    /*
     * @dev Verifies a merkle patricia proof.
     * @param value The terminating value in the trie.
     * @param encodedPath The path in the trie leading to value.
     * @param rlpParentNodes The rlp encoded stack of nodes.
     * @param root The root hash of the trie.
     * @return The boolean validity of the proof.
     */
    function verify(
        bytes memory value,
        bytes memory encodedPath,
        bytes memory rlpParentNodes,
        bytes32 root
    ) internal pure returns (bool) {
        RLPReader.RLPItem memory item = RLPReader.toRlpItem(rlpParentNodes);
        RLPReader.RLPItem[] memory parentNodes = RLPReader.toList(item);

        bytes memory currentNode;
        RLPReader.RLPItem[] memory currentNodeList;

        bytes32 nodeKey = root;
        uint256 pathPtr = 0;

        bytes memory path = _getNibbleArray(encodedPath);
        if (path.length == 0) {
            return false;
        }

        for (uint256 i = 0; i < parentNodes.length; i++) {
            if (pathPtr > path.length) {
                return false;
            }

            currentNode = RLPReader.toRlpBytes(parentNodes[i]);
            if (nodeKey != keccak256(currentNode)) {
                return false;
            }
            currentNodeList = RLPReader.toList(parentNodes[i]);

            if (currentNodeList.length == 17) {
                if (pathPtr == path.length) {
                    if (keccak256(RLPReader.toBytes(currentNodeList[16])) == keccak256(value)) {
                        return true;
                    } else {
                        return false;
                    }
                }

                uint8 nextPathNibble = uint8(path[pathPtr]);
                if (nextPathNibble > 16) {
                    return false;
                }
                nodeKey = bytes32(RLPReader.toUintStrict(currentNodeList[nextPathNibble]));
                pathPtr += 1;
            } else if (currentNodeList.length == 2) {
                uint256 traversed = _nibblesToTraverse(RLPReader.toBytes(currentNodeList[0]), path, pathPtr);
                if (pathPtr + traversed == path.length) {
                    //leaf node
                    if (keccak256(RLPReader.toBytes(currentNodeList[1])) == keccak256(value)) {
                        return true;
                    } else {
                        return false;
                    }
                }

                //extension node
                if (traversed == 0) {
                    return false;
                }

                pathPtr += traversed;
                nodeKey = bytes32(RLPReader.toUintStrict(currentNodeList[1]));
            } else {
                return false;
            }
        }
    }

    function _nibblesToTraverse(
        bytes memory encodedPartialPath,
        bytes memory path,
        uint256 pathPtr
    ) private pure returns (uint256) {
        uint256 len = 0;
        // encodedPartialPath has elements that are each two hex characters (1 byte), but partialPath
        // and slicedPath have elements that are each one hex character (1 nibble)
        bytes memory partialPath = _getNibbleArray(encodedPartialPath);
        bytes memory slicedPath = new bytes(partialPath.length);

        // pathPtr counts nibbles in path
        // partialPath.length is a number of nibbles
        for (uint256 i = pathPtr; i < pathPtr + partialPath.length; i++) {
            bytes1 pathNibble = path[i];
            slicedPath[i - pathPtr] = pathNibble;
        }

        if (keccak256(partialPath) == keccak256(slicedPath)) {
            len = partialPath.length;
        } else {
            len = 0;
        }
        return len;
    }

    // bytes b must be hp encoded
    function _getNibbleArray(bytes memory b) internal pure returns (bytes memory) {
        bytes memory nibbles = "";
        if (b.length > 0) {
            uint8 offset;
            uint8 hpNibble = uint8(_getNthNibbleOfBytes(0, b));
            if (hpNibble == 1 || hpNibble == 3) {
                nibbles = new bytes(b.length * 2 - 1);
                bytes1 oddNibble = _getNthNibbleOfBytes(1, b);
                nibbles[0] = oddNibble;
                offset = 1;
            } else {
                nibbles = new bytes(b.length * 2 - 2);
                offset = 0;
            }

            for (uint256 i = offset; i < nibbles.length; i++) {
                nibbles[i] = _getNthNibbleOfBytes(i - offset + 2, b);
            }
        }
        return nibbles;
    }

    function _getNthNibbleOfBytes(uint256 n, bytes memory str) private pure returns (bytes1) {
        return bytes1(n % 2 == 0 ? uint8(str[n / 2]) / 0x10 : uint8(str[n / 2]) % 0x10);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Merkle {
    function checkMembership(
        bytes32 leaf,
        uint256 index,
        bytes32 rootHash,
        bytes memory proof
    ) internal pure returns (bool) {
        require(proof.length % 32 == 0, "Invalid proof length");
        uint256 proofHeight = proof.length / 32;
        // Proof of size n means, height of the tree is n+1.
        // In a tree of height n+1, max #leafs possible is 2 ^ n
        require(index < 2**proofHeight, "Leaf index is too big");

        bytes32 proofElement;
        bytes32 computedHash = leaf;
        for (uint256 i = 32; i <= proof.length; i += 32) {
            assembly {
                proofElement := mload(add(proof, i))
            }

            if (index % 2 == 0) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }

            index = index / 2;
        }
        return computedHash == rootHash;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../NativeBridgeAccum.sol";
import "lib/contracts/contracts/tunnel/FxBaseRootTunnel.sol";

contract PolygonRootAccum is NativeBridgeAccum, FxBaseRootTunnel {
    constructor(
        address checkpointManager_,
        address fxRoot_,
        address socket_,
        address notary_,
        uint32 remoteChainSlug_,
        uint32 chainSlug_
    )
        NativeBridgeAccum(socket_, notary_, remoteChainSlug_, chainSlug_)
        FxBaseRootTunnel(checkpointManager_, fxRoot_)
    {}

    /**
     * @param data - encoded data to be sent to remote notary
     */
    function _sendMessage(uint256[] calldata, bytes memory data)
        internal
        override
    {
        bytes memory fxData = abi.encode(address(this), remoteNotary, data);
        _sendMessageToChild(fxData);
    }

    function _processMessageFromChild(bytes memory message) internal override {
        revert("Cannot process message here!");
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../BaseAccum.sol";
import "../../interfaces/INotary.sol";

abstract contract NativeBridgeAccum is BaseAccum {
    address public remoteNotary;
    uint256 public immutable _chainSlug;

    event UpdatedNotary(address notary_);

    constructor(
        address socket_,
        address notary_,
        uint32 remoteChainSlug_,
        uint32 chainSlug_
    ) BaseAccum(socket_, notary_, remoteChainSlug_) {
        _chainSlug = chainSlug_;
    }

    function _sendMessage(uint256[] calldata bridgeParams, bytes memory data)
        internal
        virtual;

    function sealPacket(uint256[] calldata bridgeParams)
        external
        payable
        override
        onlyRole(NOTARY_ROLE)
        returns (
            bytes32,
            uint256,
            uint256
        )
    {
        uint256 packetId = _sealedPackets++;
        bytes32 root = _roots[packetId];
        if (root == bytes32(0)) revert NoPendingPacket();

        bytes memory data = abi.encodeWithSelector(
            INotary.attest.selector,
            _getPacketId(packetId),
            root,
            bytes("")
        );

        _sendMessage(bridgeParams, data);

        emit PacketComplete(root, packetId);
        return (root, packetId, remoteChainSlug);
    }

    function addPackedMessage(bytes32 packedMessage)
        external
        override
        onlyRole(SOCKET_ROLE)
    {
        uint256 packetId = _packets;
        _roots[packetId] = packedMessage;
        _packets++;

        emit MessageAdded(packedMessage, packetId, packedMessage);
    }

    function setRemoteNotary(address notary_) external onlyOwner {
        remoteNotary = notary_;
        emit UpdatedNotary(notary_);
    }

    function _getPacketId(uint256 packetCount_)
        internal
        view
        returns (uint256 packetId)
    {
        packetId =
            (_chainSlug << 224) |
            (uint256(uint160(address(this))) << 64) |
            packetCount_;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/IAccumulator.sol";
import "../utils/AccessControl.sol";

abstract contract BaseAccum is IAccumulator, AccessControl(msg.sender) {
    bytes32 public constant SOCKET_ROLE = keccak256("SOCKET_ROLE");
    bytes32 public constant NOTARY_ROLE = keccak256("NOTARY_ROLE");
    uint256 public immutable remoteChainSlug;

    /// an incrementing id for each new packet created
    uint256 internal _packets;
    uint256 internal _sealedPackets;

    /// maps the packet id with the root hash generated while adding message
    mapping(uint256 => bytes32) internal _roots;

    error NoPendingPacket();

    /**
     * @notice initialises the contract with socket and notary addresses
     */
    constructor(
        address socket_,
        address notary_,
        uint32 remoteChainSlug_
    ) {
        _setSocket(socket_);
        _setNotary(notary_);

        remoteChainSlug = remoteChainSlug_;
    }

    function setSocket(address socket_) external onlyOwner {
        _setSocket(socket_);
    }

    function setNotary(address notary_) external onlyOwner {
        _setNotary(notary_);
    }

    function _setSocket(address socket_) private {
        _grantRole(SOCKET_ROLE, socket_);
    }

    function _setNotary(address notary_) private {
        _grantRole(NOTARY_ROLE, notary_);
    }

    /// returns the latest packet details to be sealed
    /// @inheritdoc IAccumulator
    function getNextPacketToBeSealed()
        external
        view
        virtual
        override
        returns (bytes32, uint256)
    {
        uint256 toSeal = _sealedPackets;
        return (_roots[toSeal], toSeal);
    }

    /// returns the root of packet for given id
    /// @inheritdoc IAccumulator
    function getRootById(uint256 id)
        external
        view
        virtual
        override
        returns (bytes32)
    {
        return _roots[id];
    }

    function getLatestPacketId() external view returns (uint256) {
        return _packets == 0 ? 0 : _packets - 1;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../NativeBridgeAccum.sol";
import "lib/contracts/contracts/tunnel/FxBaseChildTunnel.sol";

contract PolygonChildAccum is NativeBridgeAccum, FxBaseChildTunnel {
    constructor(
        address fxChild_,
        address socket_,
        address notary_,
        uint32 remoteChainSlug_,
        uint32 chainSlug_
    )
        NativeBridgeAccum(socket_, notary_, remoteChainSlug_, chainSlug_)
        FxBaseChildTunnel(fxChild_)
    {}

    /**
     * @param data - encoded data to be sent to remote notary
     */
    function _sendMessage(uint256[] calldata, bytes memory data)
        internal
        override
    {
        bytes memory fxData = abi.encode(address(this), remoteNotary, data);
        _sendMessageToRoot(fxData);
    }

    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal override {
        revert("Cannot process message here!");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external virtual {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import {NativeBridgeNotary} from "./NativeBridgeNotary.sol";
import "lib/contracts/contracts/tunnel/FxBaseChildTunnel.sol";

contract PolygonChildReceiver is NativeBridgeNotary, FxBaseChildTunnel {
    event FxChildUpdate(address oldFxChild, address newFxChild);

    modifier onlyRemoteAccumulator() override {
        _;
    }

    constructor(
        address signatureVerifier_,
        uint32 chainSlug_,
        address remoteTarget_,
        address fxChild_
    )
        NativeBridgeNotary(signatureVerifier_, chainSlug_, remoteTarget_)
        FxBaseChildTunnel(fxChild_)
    {}

    function _processMessageFromRoot(
        uint256,
        address rootMessageSender,
        bytes calldata data
    ) internal override {
        if (rootMessageSender != remoteTarget) revert InvalidAttester();
        (uint256 packetId, bytes32 root, ) = abi.decode(
            data,
            (uint256, bytes32, bytes)
        );
        _attest(packetId, root);
    }

    /**
     * @notice Update the address of the FxChild
     * @param fxChild_ The address of the new FxChild
     **/
    function updateFxChild(address fxChild_) external onlyOwner {
        emit FxChildUpdate(fxChild, fxChild_);
        fxChild = fxChild_;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../NativeBridgeAccum.sol";
import "../../../interfaces/native-bridge/ICrossDomainMessenger.sol";

contract OptimismAccum is NativeBridgeAccum {
    ICrossDomainMessenger public crossDomainMessenger;

    constructor(
        address socket_,
        address notary_,
        uint32 remoteChainSlug_,
        uint32 chainSlug_
    ) NativeBridgeAccum(socket_, notary_, remoteChainSlug_, chainSlug_) {
        if ((block.chainid == 10 || block.chainid == 420)) {
            crossDomainMessenger = ICrossDomainMessenger(
                0x4200000000000000000000000000000000000007
            );
        } else {
            crossDomainMessenger = block.chainid == 1
                ? ICrossDomainMessenger(
                    0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1
                )
                : ICrossDomainMessenger(
                    0x5086d1eEF304eb5284A0f6720f79403b4e9bE294
                );
        }
    }

    /**
     * @param bridgeParams - only one index, gas limit needed to execute data
     * @param data - encoded data to be sent to remote notary
     */
    function _sendMessage(uint256[] calldata bridgeParams, bytes memory data)
        internal
        override
    {
        crossDomainMessenger.sendMessage(
            remoteNotary,
            data,
            uint32(bridgeParams[0])
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

/**
 * @title ICrossDomainMessenger
 */
interface ICrossDomainMessenger {
    /**********
     * Events *
     **********/

    event SentMessage(
        address indexed target,
        address sender,
        bytes message,
        uint256 messageNonce,
        uint256 gasLimit
    );
    event RelayedMessage(bytes32 indexed msgHash);
    event FailedRelayedMessage(bytes32 indexed msgHash);

    /*************
     * Variables *
     *************/

    function xDomainMessageSender() external view returns (address);

    /********************
     * Public Functions *
     ********************/

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../../interfaces/native-bridge/ICrossDomainMessenger.sol";
import {NativeBridgeNotary} from "./NativeBridgeNotary.sol";

contract OptimismReceiver is NativeBridgeNotary {
    address public OVM_L2_CROSS_DOMAIN_MESSENGER;
    bool public isL2;

    modifier onlyRemoteAccumulator() override {
        if (
            msg.sender != OVM_L2_CROSS_DOMAIN_MESSENGER &&
            ICrossDomainMessenger(OVM_L2_CROSS_DOMAIN_MESSENGER)
                .xDomainMessageSender() !=
            remoteTarget
        ) revert InvalidSender();
        _;
    }

    constructor(
        address signatureVerifier_,
        uint32 chainSlug_,
        address remoteTarget_
    ) NativeBridgeNotary(signatureVerifier_, chainSlug_, remoteTarget_) {
        if ((block.chainid == 10 || block.chainid == 420)) {
            isL2 = true;
            OVM_L2_CROSS_DOMAIN_MESSENGER = 0x4200000000000000000000000000000000000007;
        } else {
            OVM_L2_CROSS_DOMAIN_MESSENGER = block.chainid == 1
                ? 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1
                : 0x5086d1eEF304eb5284A0f6720f79403b4e9bE294;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../NativeBridgeAccum.sol";
import "../../../interfaces/INotary.sol";
import "../../../interfaces/native-bridge/IArbSys.sol";

contract ArbitrumL2Accum is NativeBridgeAccum {
    IArbSys constant arbsys = IArbSys(address(100));

    constructor(
        address socket_,
        address notary_,
        uint32 remoteChainSlug_,
        uint32 chainSlug_
    ) NativeBridgeAccum(socket_, notary_, remoteChainSlug_, chainSlug_) {}

    function _sendMessage(uint256[] calldata, bytes memory data)
        internal
        override
    {
        arbsys.sendTxToL1(remoteNotary, data);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

/**
 * @title Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface IArbSys {
    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external pure returns (uint256);

    function arbChainID() external view returns (uint256);

    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty calldataForL1.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination)
        external
        payable
        returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @param destination recipient address on L1
     * @param calldataForL1 (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata calldataForL1)
        external
        payable
        returns (uint256);

    /**
     * @notice get the number of transactions issued by the given external account or the account sequence number of the given contract
     * @param account target account
     * @return the number of transactions issued by the given external account or the account sequence number of the given contract
     */
    function getTransactionCount(address account)
        external
        view
        returns (uint256);

    /**
     * @notice get the value of target L2 storage slot
     * This function is only callable from address 0 to prevent contracts from being able to call it
     * @param account target account
     * @param index target index of storage slot
     * @return stotage value for the given account at the given index
     */
    function getStorageAt(address account, uint256 index)
        external
        view
        returns (uint256);

    /**
     * @notice check if current call is coming from l1
     * @return true if the caller of this was called directly from L1
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param dest destination address
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address dest)
        external
        pure
        returns (address);

    /**
     * @notice get the caller's amount of available storage gas
     * @return amount of storage gas available to the caller
     */
    function getStorageGasAvailable() external view returns (uint256);

    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../NativeBridgeAccum.sol";
import "../../../interfaces/native-bridge/IInbox.sol";

contract ArbitrumL1Accum is NativeBridgeAccum {
    address public remoteRefundAddress;
    address public callValueRefundAddress;
    IInbox public inbox;

    event UpdatedInboxAddress(address inbox_);
    event UpdatedRefundAddresses(
        address remoteRefundAddress_,
        address callValueRefundAddress_
    );

    constructor(
        address socket_,
        address notary_,
        address inbox_,
        uint32 remoteChainSlug_,
        uint32 chainSlug_
    ) NativeBridgeAccum(socket_, notary_, remoteChainSlug_, chainSlug_) {
        inbox = IInbox(inbox_);
        remoteRefundAddress = msg.sender;
        callValueRefundAddress = msg.sender;
    }

    function _sendMessage(uint256[] calldata bridgeParams, bytes memory data)
        internal
        override
    {
        // to avoid stack too deep
        address callValueRefund = callValueRefundAddress;
        address remoteRefund = remoteRefundAddress;

        inbox.createRetryableTicket{value: msg.value}(
            remoteNotary,
            0, // no value needed for attest
            bridgeParams[0], // maxSubmissionCost
            remoteRefund,
            callValueRefund,
            bridgeParams[1], // maxGas
            bridgeParams[2], // gasPriceBid
            data
        );
    }

    function updateRefundAddresses(
        address remoteRefundAddress_,
        address callValueRefundAddress_
    ) external onlyOwner {
        remoteRefundAddress = remoteRefundAddress_;
        callValueRefundAddress = callValueRefundAddress_;

        emit UpdatedRefundAddresses(
            remoteRefundAddress_,
            callValueRefundAddress_
        );
    }

    function updateInboxAddresses(address inbox_) external onlyOwner {
        inbox = IInbox(inbox_);

        emit UpdatedInboxAddress(inbox_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "./IBridge.sol";

interface IInbox {
    /**
     * @notice Put a message in the L2 inbox that can be reexecuted for some fixed amount of time if it reverts
     * @dev all msg.value will deposited to callValueRefundAddress on L2
     * @dev Gas limit and maxFeePerGas should not be set to 1 as that is used to trigger the RetryableData error
     * @param to destination L2 contract address
     * @param l2CallValue call value for retryable L2 message
     * @param maxSubmissionCost Max gas deducted from user's L2 balance to cover base submission fee
     * @param excessFeeRefundAddress gasLimit x maxFeePerGas - execution cost gets credited here on L2 balance
     * @param callValueRefundAddress l2Callvalue gets credited here on L2 if retryable txn times out or gets cancelled
     * @param gasLimit Max gas deducted from user's L2 balance to cover L2 execution. Should not be set to 1 (magic value used to trigger the RetryableData error)
     * @param maxFeePerGas price bid for L2 execution. Should not be set to 1 (magic value used to trigger the RetryableData error)
     * @param data ABI encoded data of L2 message
     * @return unique message number of the retryable transaction
     */
    function createRetryableTicket(
        address to,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        bytes calldata data
    ) external payable returns (uint256);

    /**
     * @notice Put a message in the L2 inbox that can be reexecuted for some fixed amount of time if it reverts
     * @dev Same as createRetryableTicket, but does not guarantee that submission will succeed by requiring the needed funds
     * come from the deposit alone, rather than falling back on the user's L2 balance
     * @dev Advanced usage only (does not rewrite aliases for excessFeeRefundAddress and callValueRefundAddress).
     * createRetryableTicket method is the recommended standard.
     * @dev Gas limit and maxFeePerGas should not be set to 1 as that is used to trigger the RetryableData error
     * @param to destination L2 contract address
     * @param l2CallValue call value for retryable L2 message
     * @param maxSubmissionCost Max gas deducted from user's L2 balance to cover base submission fee
     * @param excessFeeRefundAddress gasLimit x maxFeePerGas - execution cost gets credited here on L2 balance
     * @param callValueRefundAddress l2Callvalue gets credited here on L2 if retryable txn times out or gets cancelled
     * @param gasLimit Max gas deducted from user's L2 balance to cover L2 execution. Should not be set to 1 (magic value used to trigger the RetryableData error)
     * @param maxFeePerGas price bid for L2 execution. Should not be set to 1 (magic value used to trigger the RetryableData error)
     * @param data ABI encoded data of L2 message
     * @return unique message number of the retryable transaction
     */
    function unsafeCreateRetryableTicket(
        address to,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        bytes calldata data
    ) external payable returns (uint256);

    function bridge() external view returns (IBridge);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface IBridge {
    function activeOutbox() external view returns (address);

    function inboxAccs(uint256 index) external view returns (bytes32);

    function messageCount() external view returns (uint256);

    function isNitroReady() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../../interfaces/native-bridge/IInbox.sol";
import "../../interfaces/native-bridge/IOutbox.sol";
import "../../interfaces/native-bridge/IBridge.sol";
import "../../libraries/AddressAliasHelper.sol";
import {NativeBridgeNotary} from "./NativeBridgeNotary.sol";

contract ArbitrumReceiver is NativeBridgeNotary {
    IInbox public inbox;
    bool public isL2;

    modifier onlyRemoteAccumulator() override {
        if (isL2) {
            if (remoteTarget != AddressAliasHelper.applyL1ToL2Alias(msg.sender))
                revert InvalidAttester();
        } else {
            IBridge bridge = inbox.bridge();
            if (msg.sender != address(bridge)) revert InvalidSender();

            IOutbox outbox = IOutbox(bridge.activeOutbox());
            address l2Sender = outbox.l2ToL1Sender();
            if (l2Sender != remoteTarget) revert InvalidAttester();
        }
        _;
    }

    constructor(
        address signatureVerifier_,
        uint32 chainSlug_,
        address remoteTarget_,
        address inbox_
    ) NativeBridgeNotary(signatureVerifier_, chainSlug_, remoteTarget_) {
        isL2 = (block.chainid == 42161 || block.chainid == 421613)
            ? true
            : false;
        inbox = IInbox(inbox_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface IOutbox {
    event SendRootUpdated(
        bytes32 indexed outputRoot,
        bytes32 indexed l2BlockHash
    );
    event OutBoxTransactionExecuted(
        address indexed to,
        address indexed l2Sender,
        uint256 indexed zero,
        uint256 transactionIndex
    );

    function rollup() external view returns (address); // the rollup contract

    function bridge() external view returns (address); // the bridge contract

    function spent(uint256) external view returns (bytes32); // packed spent bitmap

    function roots(bytes32) external view returns (bytes32); // maps root hashes => L2 block hash

    // solhint-disable-next-line func-name-mixedcase
    function OUTBOX_VERSION() external view returns (uint128); // the outbox version

    /// @notice When l2ToL1Sender returns a nonzero address, the message was originated by an L2 account
    ///         When the return value is zero, that means this is a system message
    /// @dev the l2ToL1Sender behaves as the tx.origin, the msg.sender should be validated to protect against reentrancies
    function l2ToL1Sender() external view returns (address);

    /// @return l2Block return L2 block when the L2 tx was initiated or 0 if no L2 to L1 transaction is active
    function l2ToL1Block() external view returns (uint256);

    /// @return l1Block return L1 block when the L2 tx was initiated or 0 if no L2 to L1 transaction is active
    function l2ToL1EthBlock() external view returns (uint256);

    /// @return timestamp return L2 timestamp when the L2 tx was initiated or 0 if no L2 to L1 transaction is active
    function l2ToL1Timestamp() external view returns (uint256);

    /// @return outputId returns the unique output identifier of the L2 to L1 tx or 0 if no L2 to L1 transaction is active
    function l2ToL1OutputId() external view returns (bytes32);

    /**
     * @notice Executes a messages in an Outbox entry.
     * @dev Reverts if dispute period hasn't expired, since the outbox entry
     *      is only created once the rollup confirms the respective assertion.
     * @dev it is not possible to execute any L2-to-L1 transaction which contains data
     *      to a contract address without any code (as enforced by the Bridge contract).
     * @param proof Merkle proof of message inclusion in send root
     * @param index Merkle path to message
     * @param l2Sender sender if original message (i.e., caller of ArbSys.sendTxToL1)
     * @param to destination address for L1 contract call
     * @param l2Block l2 block number at which sendTxToL1 call was made
     * @param l1Block l1 block number at which sendTxToL1 call was made
     * @param l2Timestamp l2 Timestamp at which sendTxToL1 call was made
     * @param value wei in L1 message
     * @param data abi-encoded L1 message data
     */
    function executeTransaction(
        bytes32[] calldata proof,
        uint256 index,
        address l2Sender,
        address to,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 value,
        bytes calldata data
    ) external;

    /**
     *  @dev function used to simulate the result of a particular function call from the outbox
     *       it is useful for things such as gas estimates. This function includes all costs except for
     *       proof validation (which can be considered offchain as a somewhat of a fixed cost - it's
     *       not really a fixed cost, but can be treated as so with a fixed overhead for gas estimation).
     *       We can't include the cost of proof validation since this is intended to be used to simulate txs
     *       that are included in yet-to-be confirmed merkle roots. The simulation entrypoint could instead pretend
     *       to confirm a pending merkle root, but that would be less practical for integrating with tooling.
     *       It is only possible to trigger it when the msg sender is address zero, which should be impossible
     *       unless under simulation in an eth_call or eth_estimateGas
     */
    function executeTransactionSimulation(
        uint256 index,
        address l2Sender,
        address to,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 value,
        bytes calldata data
    ) external;

    /**
     * @param index Merkle path to message
     * @return true if the message has been spent
     */
    function isSpent(uint256 index) external view returns (bool);

    function calculateItemHash(
        address l2Sender,
        address to,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes32);

    function calculateMerkleRoot(
        bytes32[] memory proof,
        uint256 path,
        bytes32 item
    ) external pure returns (bytes32);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.7;

library AddressAliasHelper {
    uint160 internal constant OFFSET =
        uint160(0x1111000000000000000000000000000000001111);

    /// @notice Utility function that converts the address in the L1 that submitted a tx to
    /// the inbox to the msg.sender viewed in the L2
    /// @param l1Address the address in the L1 that triggered the tx to L2
    /// @return l2Address L2 address as viewed in msg.sender
    function applyL1ToL2Alias(address l1Address)
        internal
        pure
        returns (address l2Address)
    {
        unchecked {
            l2Address = address(uint160(l1Address) + OFFSET);
        }
    }

    /// @notice Utility function that converts the msg.sender viewed in the L2 to the
    /// address in the L1 that submitted a tx to the inbox
    /// @param l2Address L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(address l2Address)
        internal
        pure
        returns (address l1Address)
    {
        unchecked {
            l1Address = address(uint160(l2Address) - OFFSET);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "./BaseAccum.sol";

contract SingleAccum is BaseAccum {
    /**
     * @notice initialises the contract with socket and notary addresses
     */
    constructor(
        address socket_,
        address notary_,
        uint32 remoteChainSlug_
    ) BaseAccum(socket_, notary_, remoteChainSlug_) {}

    /// adds the packed message to a packet
    /// @inheritdoc IAccumulator
    function addPackedMessage(bytes32 packedMessage)
        external
        override
        onlyRole(SOCKET_ROLE)
    {
        uint256 packetId = _packets;
        _roots[packetId] = packedMessage;
        _packets++;

        emit MessageAdded(packedMessage, packetId, packedMessage);
    }

    function sealPacket(uint256[] calldata)
        external
        payable
        virtual
        override
        onlyRole(NOTARY_ROLE)
        returns (
            bytes32,
            uint256,
            uint256
        )
    {
        uint256 packetId = _sealedPackets;

        if (_roots[packetId] == bytes32(0)) revert NoPendingPacket();
        bytes32 root = _roots[packetId];
        _sealedPackets++;

        emit PacketComplete(root, packetId);
        return (root, packetId, remoteChainSlug);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

// deprecated
import "../interfaces/INotary.sol";
import "../utils/AccessControl.sol";
import "../interfaces/IAccumulator.sol";
import "../interfaces/ISignatureVerifier.sol";

// moved from interface
// function addBond() external payable;

//     function reduceBond(uint256 amount) external;

//     function unbondAttester() external;

//     function claimBond() external;

// contract BondedNotary is AccessControl(msg.sender) {
// event Unbonded(address indexed attester, uint256 amount, uint256 claimTime);

// event BondClaimed(address indexed attester, uint256 amount);

// event BondClaimDelaySet(uint256 delay);

// event MinBondAmountSet(uint256 amount);

//  error InvalidBondReduce();

// error UnbondInProgress();

// error ClaimTimeLeft();

// error InvalidBond();

//     uint256 private _minBondAmount;
//     uint256 private _bondClaimDelay;
//     uint256 private immutable _chainSlug;
//     ISignatureVerifier private _signatureVerifier;

//     // attester => bond amount
//     mapping(address => uint256) private _bonds;

//     struct UnbondData {
//         uint256 amount;
//         uint256 claimTime;
//     }
//     // attester => unbond data
//     mapping(address => UnbondData) private _unbonds;

//     // attester => accumAddress => packetId => sig hash
//     mapping(address => mapping(address => mapping(uint256 => bytes32)))
//         private _localSignatures;

//     // remoteChainSlug => accumAddress => packetId => root
//     mapping(uint256 => mapping(address => mapping(uint256 => bytes32)))
//         private _remoteRoots;

//     event BondAdded(
//          address indexed attester,
//          uint256 addAmount, // assuming native token
//          uint256 newBond
//     );

//     event BondReduced(
//          address indexed attester,
//          uint256 reduceAmount,
//          uint256 newBond
//     );

//     constructor(
//         uint256 minBondAmount_,
//         uint256 bondClaimDelay_,
//         uint256 chainSlug_,
//         address signatureVerifier_
//     ) {
//         _setMinBondAmount(minBondAmount_);
//         _setBondClaimDelay(bondClaimDelay_);
//         _setSignatureVerifier(signatureVerifier_);
//         _chainSlug = chainSlug_;
//     }

//     function addBond() external payable override {
//         _bonds[msg.sender] += msg.value;
//         emit BondAdded(msg.sender, msg.value, _bonds[msg.sender]);
//     }

//     function reduceBond(uint256 amount) external override {
//         uint256 newBond = _bonds[msg.sender] - amount;

//         if (newBond < _minBondAmount) revert InvalidBondReduce();

//         _bonds[msg.sender] = newBond;
//         emit BondReduced(msg.sender, amount, newBond);

//         payable(msg.sender).transfer(amount);
//     }

//     function unbondAttester() external override {
//         if (_unbonds[msg.sender].claimTime != 0) revert UnbondInProgress();

//         uint256 amount = _bonds[msg.sender];
//         uint256 claimTime = block.timestamp + _bondClaimDelay;

//         _bonds[msg.sender] = 0;
//         _unbonds[msg.sender] = UnbondData(amount, claimTime);

//         emit Unbonded(msg.sender, amount, claimTime);
//     }

//     function claimBond() external override {
//         if (_unbonds[msg.sender].claimTime > block.timestamp)
//             revert ClaimTimeLeft();

//         uint256 amount = _unbonds[msg.sender].amount;
//         _unbonds[msg.sender] = UnbondData(0, 0);
//         emit BondClaimed(msg.sender, amount);

//         payable(msg.sender).transfer(amount);
//     }

//     function minBondAmount() external view returns (uint256) {
//         return _minBondAmount;
//     }

//     function bondClaimDelay() external view returns (uint256) {
//         return _bondClaimDelay;
//     }

//     function signatureVerifier() external view returns (address) {
//         return address(_signatureVerifier);
//     }

//     function chainSlug() external view returns (uint256) {
//         return _chainSlug;
//     }

//     function getBond(address attester) external view returns (uint256) {
//         return _bonds[attester];
//     }

//     function isAttested(address, uint256) external view returns (bool) {
//         return true;
//     }

//     function getUnbondData(address attester)
//         external
//         view
//         returns (uint256, uint256)
//     {
//         return (_unbonds[attester].amount, _unbonds[attester].claimTime);
//     }

//     function setMinBondAmount(uint256 amount) external onlyOwner {
//         _setMinBondAmount(amount);
//     }

//     function setBondClaimDelay(uint256 delay) external onlyOwner {
//         _setBondClaimDelay(delay);
//     }

//     function setSignatureVerifier(address signatureVerifier_)
//         external
//         onlyOwner
//     {
//         _setSignatureVerifier(signatureVerifier_);
//     }

//     function seal(address accumAddress_, uint256 remoteChainSlug_, bytes calldata signature_)
//         external
//         override
//     {
//         (bytes32 root, uint256 packetId) = IAccumulator(accumAddress_)
//             .sealPacket();

//         bytes32 digest = keccak256(
//             abi.encode(_chainSlug, accumAddress_, packetId, root)
//         );
//         address attester = _signatureVerifier.recoverSigner(digest, signature_);

//         if (_bonds[attester] < _minBondAmount) revert InvalidBond();
//         _localSignatures[attester][accumAddress_][packetId] = keccak256(
//             signature_
//         );

//         emit PacketVerifiedAndSealed(attester, accumAddress_, packetId, signature_);
//     }

//     function challengeSignature(
//         address accumAddress_,
//         bytes32 root_,
//         uint256 packetId_,
//         bytes calldata signature_
//     ) external override {
//         bytes32 digest = keccak256(
//             abi.encode(_chainSlug, accumAddress_, packetId_, root_)
//         );
//         address attester = _signatureVerifier.recoverSigner(digest, signature_);
//         bytes32 oldSig = _localSignatures[attester][accumAddress_][packetId_];

//         if (oldSig != keccak256(signature_)) {
//             uint256 bond = _unbonds[attester].amount + _bonds[attester];
//             payable(msg.sender).transfer(bond);
//             emit ChallengedSuccessfully(
//                 attester,
//                 accumAddress_,
//                 packetId_,
//                 msg.sender,
//                 bond
//             );
//         }
//     }

//     function _setMinBondAmount(uint256 amount) private {
//         _minBondAmount = amount;
//         emit MinBondAmountSet(amount);
//     }

//     function _setBondClaimDelay(uint256 delay) private {
//         _bondClaimDelay = delay;
//         emit BondClaimDelaySet(delay);
//     }

//     function _setSignatureVerifier(address signatureVerifier_) private {
//         _signatureVerifier = ISignatureVerifier(signatureVerifier_);
//         emit SignatureVerifierSet(signatureVerifier_);
//     }

//     function propose(
//         uint256 remoteChainSlug_,
//         address accumAddress_,
//         uint256 packetId_,
//         bytes32 root_,
//         bytes calldata signature_
//     ) external override {
//         bytes32 digest = keccak256(
//             abi.encode(remoteChainSlug_, accumAddress_, packetId_, root_)
//         );
//         address attester = _signatureVerifier.recoverSigner(digest, signature_);

//         if (!_hasRole(_attesterRole(remoteChainSlug_), attester))
//             revert InvalidAttester();

//         if (_remoteRoots[remoteChainSlug_][accumAddress_][packetId_] != 0)
//             revert AlreadyProposed();

//         _remoteRoots[remoteChainSlug_][accumAddress_][packetId_] = root_;
//         emit Proposed(
//             remoteChainSlug_,
//             accumAddress_,
//             packetId_,
//             root_
//         );
//     }

//     function getRemoteRoot(
//         uint256 remoteChainSlug_,
//         address accumAddress_,
//         uint256 packetId_
//     ) external view override returns (bytes32) {
//         return _remoteRoots[remoteChainSlug_][accumAddress_][packetId_];
//     }

//     function grantAttesterRole(uint256 remoteChainSlug_, address attester_)
//         external
//         onlyOwner
//     {
//         _grantRole(_attesterRole(remoteChainSlug_), attester_);
//     }

//     function revokeAttesterRole(uint256 remoteChainSlug_, address attester_)
//         external
//         onlyOwner
//     {
//         _revokeRole(_attesterRole(remoteChainSlug_), attester_);
//     }

//     function _attesterRole(uint256 chainSlug_) internal pure returns (bytes32) {
//         return bytes32(chainSlug_);
//     }
// }

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;
import "../interfaces/ISignatureVerifier.sol";

contract SignatureVerifier is ISignatureVerifier {
    error InvalidSigLength();

    /// @inheritdoc ISignatureVerifier
    function recoverSigner(
        uint256 destChainSlug_,
        uint256 packetId_,
        bytes32 root_,
        bytes calldata signature_
    ) external pure override returns (address signer) {
        bytes32 digest = keccak256(
            abi.encode(destChainSlug_, packetId_, root_)
        );
        digest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", digest)
        );
        signer = _recoverSigner(digest, signature_);
    }

    /**
     * @notice returns the address of signer recovered from input signature
     */
    function _recoverSigner(bytes32 hash_, bytes memory signature_)
        private
        pure
        returns (address signer)
    {
        (bytes32 sigR, bytes32 sigS, uint8 sigV) = _splitSignature(signature_);

        // recovered signer is checked for the valid roles later
        signer = ecrecover(hash_, sigV, sigR, sigS);
    }

    /**
     * @notice splits the signature into v, r and s.
     */
    function _splitSignature(bytes memory signature_)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        if (signature_.length != 65) revert InvalidSigLength();
        assembly {
            r := mload(add(signature_, 0x20))
            s := mload(add(signature_, 0x40))
            v := byte(0, mload(add(signature_, 0x60)))
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../utils/AccessControl.sol";
import "../utils/ReentrancyGuard.sol";
import "../interfaces/INotary.sol";
import "../interfaces/IAccumulator.sol";
import "../interfaces/ISignatureVerifier.sol";

contract AdminNotary is INotary, AccessControl(msg.sender), ReentrancyGuard {
    uint256 private immutable _chainSlug;
    ISignatureVerifier public signatureVerifier;

    // attester => accumAddr|chainSlug|packetId => is attested
    mapping(address => mapping(uint256 => bool)) public isAttested;

    // chainSlug => total attesters registered
    mapping(uint256 => uint256) public totalAttestors;

    // accumAddr|chainSlug|packetId
    mapping(uint256 => PacketDetails) private _packetDetails;

    constructor(address signatureVerifier_, uint32 chainSlug_) {
        _chainSlug = chainSlug_;
        signatureVerifier = ISignatureVerifier(signatureVerifier_);
    }

    /// @inheritdoc INotary
    function seal(
        address accumAddress_,
        uint256[] calldata bridgeParams,
        bytes calldata signature_
    ) external payable override nonReentrant {
        (
            bytes32 root,
            uint256 packetCount,
            uint256 remoteChainSlug
        ) = IAccumulator(accumAddress_).sealPacket{value: msg.value}(
                bridgeParams
            );

        uint256 packetId = _getPacketId(accumAddress_, _chainSlug, packetCount);

        address attester = signatureVerifier.recoverSigner(
            remoteChainSlug,
            packetId,
            root,
            signature_
        );

        if (!_hasRole(_attesterRole(remoteChainSlug), attester))
            revert InvalidAttester();
        emit PacketVerifiedAndSealed(
            attester,
            accumAddress_,
            packetId,
            signature_
        );
    }

    /// @inheritdoc INotary
    function attest(
        uint256 packetId_,
        bytes32 root_,
        bytes calldata signature_
    ) external override {
        address attester = signatureVerifier.recoverSigner(
            _chainSlug,
            packetId_,
            root_,
            signature_
        );

        if (!_hasRole(_attesterRole(_getChainSlug(packetId_)), attester))
            revert InvalidAttester();

        _updatePacketDetails(attester, packetId_, root_);
        emit PacketAttested(attester, packetId_);
    }

    function _updatePacketDetails(
        address attester_,
        uint256 packetId_,
        bytes32 root_
    ) private {
        PacketDetails storage packedDetails = _packetDetails[packetId_];
        if (isAttested[attester_][packetId_]) revert AlreadyAttested();

        if (_packetDetails[packetId_].remoteRoots == bytes32(0)) {
            packedDetails.remoteRoots = root_;
            packedDetails.timeRecord = block.timestamp;

            emit PacketProposed(packetId_, root_);
        } else if (_packetDetails[packetId_].remoteRoots != root_)
            revert RootNotFound();

        isAttested[attester_][packetId_] = true;
        packedDetails.attestations++;
    }

    /**
     * @notice updates root for given packet id
     * @param packetId_ id of packet to be updated
     * @param newRoot_ new root
     */
    function updatePacketRoot(uint256 packetId_, bytes32 newRoot_)
        external
        onlyOwner
    {
        PacketDetails storage packedDetails = _packetDetails[packetId_];
        bytes32 oldRoot = packedDetails.remoteRoots;
        packedDetails.remoteRoots = newRoot_;

        emit PacketRootUpdated(packetId_, oldRoot, newRoot_);
    }

    /// @inheritdoc INotary
    function getPacketStatus(uint256 packetId_)
        public
        view
        override
        returns (PacketStatus status)
    {
        PacketDetails memory packet = _packetDetails[packetId_];
        uint256 packetArrivedAt = packet.timeRecord;

        if (packetArrivedAt == 0) return PacketStatus.NOT_PROPOSED;
        return PacketStatus.PROPOSED;
    }

    /// @inheritdoc INotary
    function getPacketDetails(uint256 packetId_)
        external
        view
        override
        returns (
            PacketStatus status,
            uint256 packetArrivedAt,
            uint256 pendingAttestations,
            bytes32 root
        )
    {
        status = getPacketStatus(packetId_);

        PacketDetails memory packet = _packetDetails[packetId_];
        root = packet.remoteRoots;
        packetArrivedAt = packet.timeRecord;
        pendingAttestations =
            totalAttestors[_getChainSlug(packetId_)] -
            packet.attestations;
    }

    /**
     * @notice adds an attester for `remoteChainSlug_` chain
     * @param remoteChainSlug_ remote chain id
     * @param attester_ attester address
     */
    function grantAttesterRole(uint256 remoteChainSlug_, address attester_)
        external
        onlyOwner
    {
        if (_hasRole(_attesterRole(remoteChainSlug_), attester_))
            revert AttesterExists();

        _grantRole(_attesterRole(remoteChainSlug_), attester_);
        totalAttestors[remoteChainSlug_]++;
    }

    /**
     * @notice removes an attester from `remoteChainSlug_` chain list
     * @param remoteChainSlug_ remote chain id
     * @param attester_ attester address
     */
    function revokeAttesterRole(uint256 remoteChainSlug_, address attester_)
        external
        onlyOwner
    {
        if (!_hasRole(_attesterRole(remoteChainSlug_), attester_))
            revert AttesterNotFound();

        _revokeRole(_attesterRole(remoteChainSlug_), attester_);
        totalAttestors[remoteChainSlug_]--;
    }

    function _attesterRole(uint256 chainSlug_) internal pure returns (bytes32) {
        return bytes32(chainSlug_);
    }

    /**
     * @notice returns the attestations received by a packet
     * @param packetId_ packed id
     */
    function getAttestationCount(uint256 packetId_)
        external
        view
        returns (uint256)
    {
        return _packetDetails[packetId_].attestations;
    }

    /**
     * @notice returns the remote root for given `packetId_`
     * @param packetId_ packed id
     */
    function getRemoteRoot(uint256 packetId_)
        external
        view
        override
        returns (bytes32)
    {
        return _packetDetails[packetId_].remoteRoots;
    }

    /**
     * @notice returns the current chain id
     */
    function chainSlug() external view returns (uint256) {
        return _chainSlug;
    }

    /**
     * @notice updates signatureVerifier_
     * @param signatureVerifier_ address of Signature Verifier
     */
    function setSignatureVerifier(address signatureVerifier_)
        external
        onlyOwner
    {
        signatureVerifier = ISignatureVerifier(signatureVerifier_);
        emit SignatureVerifierSet(signatureVerifier_);
    }

    function _getPacketId(
        address accumAddr_,
        uint256 chainSlug_,
        uint256 packetCount_
    ) internal pure returns (uint256 packetId) {
        packetId =
            (chainSlug_ << 224) |
            (uint256(uint160(accumAddr_)) << 64) |
            packetCount_;
    }

    function _getChainSlug(uint256 packetId_)
        internal
        pure
        returns (uint256 chainSlug_)
    {
        chainSlug_ = uint32(packetId_ >> 224);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../utils/Ownable.sol";
import "../interfaces/IVault.sol";

contract Vault is IVault, Ownable {
    // integration type from socket => remote chain slug => fees
    mapping(bytes32 => mapping(uint256 => uint256)) public minFees;

    error InsufficientFees();

    /**
     * @notice emits when fee is deducted at outbound
     * @param amount_ total fee amount
     */
    event FeeDeducted(uint256 amount_);
    event FeesSet(
        uint256 minFees_,
        uint256 remoteChainSlug_,
        bytes32 integrationType_
    );

    constructor(address owner_) Ownable(owner_) {}

    /// @inheritdoc IVault
    function deductFee(uint256 remoteChainSlug_, bytes32 integrationType_)
        external
        payable
        override
    {
        if (msg.value < minFees[integrationType_][remoteChainSlug_])
            revert InsufficientFees();
        emit FeeDeducted(msg.value);
    }

    /**
     * @notice updates the fee required to bridge a message for give chain and config
     * @param minFees_ fees
     * @param integrationType_ config for which fees is needed
     * @param integrationType_ config for which fees is needed
     */
    function setFees(
        uint256 minFees_,
        uint256 remoteChainSlug_,
        bytes32 integrationType_
    ) external onlyOwner {
        minFees[integrationType_][remoteChainSlug_] = minFees_;
        emit FeesSet(minFees_, remoteChainSlug_, integrationType_);
    }

    /**
     * @notice transfers the `amount_` ETH to `account_`
     * @param account_ address to transfer ETH
     * @param amount_ amount to transfer
     */
    function claimFee(address account_, uint256 amount_) external onlyOwner {
        require(account_ != address(0));
        (bool success, ) = account_.call{value: amount_}("");
        require(success, "Transfer failed.");
    }

    /**
     * @notice returns the fee required to bridge a message
     * @param integrationType_ config for which fees is needed
     */
    function getFees(bytes32 integrationType_, uint256 remoteChainSlug_)
        external
        view
        returns (uint256)
    {
        return minFees[integrationType_][remoteChainSlug_];
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/IPlug.sol";
import "../interfaces/ISocket.sol";

contract Messenger is IPlug {
    // immutables
    address private immutable _socket;
    uint256 private immutable _chainSlug;

    address private _owner;
    bytes32 private _message;
    uint256 public msgGasLimit;

    bytes32 private constant _PING = keccak256("PING");
    bytes32 private constant _PONG = keccak256("PONG");

    constructor(
        address socket_,
        uint256 chainSlug_,
        uint256 msgGasLimit_
    ) {
        _socket = socket_;
        _chainSlug = chainSlug_;
        _owner = msg.sender;

        msgGasLimit = msgGasLimit_;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "can only be called by owner");
        _;
    }

    function sendLocalMessage(bytes32 message_) external {
        _updateMessage(message_);
    }

    function sendRemoteMessage(uint256 remoteChainSlug_, bytes32 message_)
        external
        payable
    {
        bytes memory payload = abi.encode(_chainSlug, message_);
        _outbound(remoteChainSlug_, payload);
    }

    function inbound(bytes calldata payload_) external payable override {
        require(msg.sender == _socket, "Counter: Invalid Socket");
        (uint256 localChainSlug, bytes32 msgDecoded) = abi.decode(
            payload_,
            (uint256, bytes32)
        );

        _updateMessage(msgDecoded);

        bytes memory newPayload = abi.encode(
            _chainSlug,
            msgDecoded == _PING ? _PONG : _PING
        );
        _outbound(localChainSlug, newPayload);
    }

    // settings
    function setSocketConfig(
        uint256 remoteChainSlug,
        address remotePlug,
        string calldata integrationType
    ) external onlyOwner {
        ISocket(_socket).setPlugConfig(
            remoteChainSlug,
            remotePlug,
            integrationType
        );
    }

    function message() external view returns (bytes32) {
        return _message;
    }

    function _updateMessage(bytes32 message_) private {
        _message = message_;
    }

    function _outbound(uint256 targetChain_, bytes memory payload_) private {
        ISocket(_socket).outbound{value: msg.value}(
            targetChain_,
            msgGasLimit,
            payload_
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/IPlug.sol";
import "../interfaces/ISocket.sol";

contract Counter is IPlug {
    // immutables
    address public immutable socket;

    address public owner;

    // application state
    uint256 public counter;

    // application ops
    bytes32 constant OP_ADD = keccak256("OP_ADD");
    bytes32 constant OP_SUB = keccak256("OP_SUB");

    constructor(address _socket) {
        socket = _socket;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "can only be called by owner");
        _;
    }

    function localAddOperation(uint256 amount) external {
        _addOperation(amount);
    }

    function localSubOperation(uint256 amount) external {
        _subOperation(amount);
    }

    function remoteAddOperation(
        uint256 chainSlug,
        uint256 amount,
        uint256 msgGasLimit
    ) external payable {
        bytes memory payload = abi.encode(OP_ADD, amount);
        _outbound(chainSlug, msgGasLimit, payload);
    }

    function remoteSubOperation(
        uint256 chainSlug,
        uint256 amount,
        uint256 msgGasLimit
    ) external payable {
        bytes memory payload = abi.encode(OP_SUB, amount);
        _outbound(chainSlug, msgGasLimit, payload);
    }

    function inbound(bytes calldata payload) external payable override {
        require(msg.sender == socket, "Counter: Invalid Socket");
        (bytes32 operationType, uint256 amount) = abi.decode(
            payload,
            (bytes32, uint256)
        );

        if (operationType == OP_ADD) {
            _addOperation(amount);
        } else if (operationType == OP_SUB) {
            _subOperation(amount);
        } else {
            revert("CounterMock: Invalid Operation");
        }
    }

    function _outbound(
        uint256 targetChain,
        uint256 msgGasLimit,
        bytes memory payload
    ) private {
        ISocket(socket).outbound{value: msg.value}(
            targetChain,
            msgGasLimit,
            payload
        );
    }

    //
    // base ops
    //
    function _addOperation(uint256 amount) private {
        counter += amount;
    }

    function _subOperation(uint256 amount) private {
        require(counter > amount, "CounterMock: Subtraction Overflow");
        counter -= amount;
    }

    // settings
    function setSocketConfig(
        uint256 remoteChainSlug,
        address remotePlug,
        string calldata integrationType
    ) external onlyOwner {
        ISocket(socket).setPlugConfig(
            remoteChainSlug,
            remotePlug,
            integrationType
        );
    }

    function setupComplete() external {
        owner = address(0);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../utils/Ownable.sol";

contract MockOwnable is Ownable {
    constructor(address owner) Ownable(owner) {}

    function ownerFunction() external onlyOwner {}

    function publicFunction() external {}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../utils/AccessControl.sol";

contract MockAccessControl is AccessControl {
    bytes32 public constant ROLE_GIRAFFE = keccak256("ROLE_GIRAFFE");
    bytes32 public constant ROLE_HIPPO = keccak256("ROLE_HIPPO");

    constructor(address owner) AccessControl(owner) {}

    function giraffe() external onlyRole(ROLE_GIRAFFE) {}

    function hippo() external onlyRole(ROLE_HIPPO) {}

    function animal() external {}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/IHasher.sol";

contract Hasher is IHasher {
    /// @inheritdoc IHasher
    function packMessage(
        uint256 srcChainSlug,
        address srcPlug,
        uint256 dstChainSlug,
        address dstPlug,
        uint256 msgId,
        uint256 msgGasLimit,
        bytes calldata payload
    ) external pure override returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    srcChainSlug,
                    srcPlug,
                    dstChainSlug,
                    dstPlug,
                    msgId,
                    msgGasLimit,
                    payload
                )
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/IDeaccumulator.sol";

contract SingleDeaccum is IDeaccumulator {
    /// returns if the packed message is the part of a merkle tree or not
    /// @inheritdoc IDeaccumulator
    function verifyMessageInclusion(
        bytes32 root_,
        bytes32 packedMessage_,
        bytes calldata
    ) external pure override returns (bool) {
        return root_ == packedMessage_;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

/**
 * @title IFxMessageProcessor
 * @notice Defines the interface to process message
 */
interface IFxMessageProcessor {
    /**
     * @notice Process the cross-chain message from a FxChild contract through the Ethereum/Polygon StateSender
     * @param stateId The id of the cross-chain message created in the Ethereum/Polygon StateSender
     * @param rootMessageSender The address that initially sent this message on Ethereum
     * @param data The data from the abi-encoded cross-chain message
     **/
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}