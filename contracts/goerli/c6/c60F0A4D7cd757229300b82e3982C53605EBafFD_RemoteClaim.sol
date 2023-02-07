// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "./interfaces/ICapacitorFactory.sol";
import "./capacitors/SingleCapacitor.sol";
import "./capacitors/HashChainCapacitor.sol";
import "./decapacitors/SingleDecapacitor.sol";
import "./decapacitors/HashChainDecapacitor.sol";
import "./libraries/SafeTransferLib.sol";
import "./utils/Ownable.sol";

contract CapacitorFactory is ICapacitorFactory, Ownable(msg.sender) {
    using SafeTransferLib for IERC20;

    function deploy(
        uint256 capacitorType,
        uint256 /** siblingChainSlug */
    ) external override returns (ICapacitor, IDecapacitor) {
        if (capacitorType == 1) {
            return (new SingleCapacitor(msg.sender), new SingleDecapacitor());
        }
        if (capacitorType == 2) {
            return (
                new HashChainCapacitor(msg.sender),
                new HashChainDecapacitor()
            );
        }
        revert InvalidCapacitorType();
    }

    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        require(userAddress != address(0));

        if (token == address(0)) {
            (bool success, ) = userAddress.call{value: address(this).balance}(
                ""
            );
            require(success);
        } else {
            // do we need safe transfer?
            IERC20(token).transfer(userAddress, amount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/ICapacitor.sol";
import "../utils/AccessControl.sol";
import "../libraries/SafeTransferLib.sol";

abstract contract BaseCapacitor is ICapacitor, AccessControl(msg.sender) {
    using SafeTransferLib for IERC20;

    // keccak256("SOCKET_ROLE")
    bytes32 public constant SOCKET_ROLE =
        0x9626cdfde87fcc60a5069beda7850c84f848fb1b20dab826995baf7113491456;

    /// an incrementing id for each new packet created
    uint256 internal _packets;
    uint256 internal _sealedPackets;

    /// maps the packet id with the root hash generated while adding message
    mapping(uint256 => bytes32) internal _roots;

    error NoPendingPacket();

    event SocketSet(address socket_);

    /**
     * @notice initialises the contract with socket address
     */
    constructor(address socket_) {
        _setSocket(socket_);
    }

    function setSocket(address socket_) external onlyOwner {
        _setSocket(socket_);
        emit SocketSet(socket_);
    }

    function _setSocket(address socket_) private {
        _grantRole(SOCKET_ROLE, socket_);
    }

    /// returns the latest packet details to be sealed
    /// @inheritdoc ICapacitor
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
    /// @inheritdoc ICapacitor
    function getRootById(
        uint256 id
    ) external view virtual override returns (bytes32) {
        return _roots[id];
    }

    function getLatestPacketCount() external view returns (uint256) {
        return _packets == 0 ? 0 : _packets - 1;
    }

    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        require(userAddress != address(0));

        if (token == address(0)) {
            (bool success, ) = userAddress.call{value: address(this).balance}(
                ""
            );
            require(success);
        } else {
            // do we need safe transfer?
            IERC20(token).transfer(userAddress, amount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "./BaseCapacitor.sol";

contract HashChainCapacitor is BaseCapacitor {
    uint256 private _chainLength;
    uint256 private constant MAX_LEN = 10;

    /**
     * @notice initialises the contract with socket address
     */
    constructor(address socket_) BaseCapacitor(socket_) {}

    /// adds the packed message to a packet
    /// @inheritdoc ICapacitor
    function addPackedMessage(
        bytes32 packedMessage
    ) external override onlyRole(SOCKET_ROLE) {
        uint256 packetCount = _packets;

        _roots[packetCount] = keccak256(
            abi.encode(_roots[packetCount], packedMessage)
        );
        _chainLength++;

        if (_chainLength == MAX_LEN) {
            _packets++;
            _chainLength = 0;
        }

        emit MessageAdded(packedMessage, packetCount, _roots[packetCount]);
    }

    function sealPacket()
        external
        virtual
        override
        onlyRole(SOCKET_ROLE)
        returns (bytes32, uint256)
    {
        uint256 packetCount = _sealedPackets++;

        if (_roots[packetCount] == bytes32(0)) revert NoPendingPacket();
        bytes32 root = _roots[packetCount];

        emit PacketComplete(root, packetCount);
        return (root, packetCount);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "./BaseCapacitor.sol";

contract SingleCapacitor is BaseCapacitor {
    /**
     * @notice initialises the contract with socket address
     */
    constructor(address socket_) BaseCapacitor(socket_) {}

    /// adds the packed message to a packet
    /// @inheritdoc ICapacitor
    function addPackedMessage(
        bytes32 packedMessage
    ) external override onlyRole(SOCKET_ROLE) {
        uint256 packetCount = _packets;
        _roots[packetCount] = packedMessage;
        _packets++;

        emit MessageAdded(packedMessage, packetCount, packedMessage);
    }

    function sealPacket()
        external
        virtual
        override
        onlyRole(SOCKET_ROLE)
        returns (bytes32, uint256)
    {
        uint256 packetCount = _sealedPackets++;
        bytes32 root = _roots[packetCount];

        if (_roots[packetCount] == bytes32(0)) revert NoPendingPacket();

        emit PacketComplete(root, packetCount);
        return (root, packetCount);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/IDecapacitor.sol";
import "../libraries/SafeTransferLib.sol";
import "../utils/Ownable.sol";

contract HashChainDecapacitor is IDecapacitor, Ownable(msg.sender) {
    using SafeTransferLib for IERC20;

    /// returns if the packed message is the part of a merkle tree or not
    /// @inheritdoc IDecapacitor
    function verifyMessageInclusion(
        bytes32 root_,
        bytes32 packedMessage_,
        bytes calldata proof
    ) external pure override returns (bool) {
        bytes32[] memory chain = abi.decode(proof, (bytes32[]));
        uint256 len = chain.length;
        bytes32 generatedRoot;
        bool isIncluded;
        for (uint256 i = 0; i < len; i++) {
            generatedRoot = keccak256(abi.encode(generatedRoot, chain[i]));
            if (chain[i] == packedMessage_) isIncluded = true;
        }

        return root_ == generatedRoot && isIncluded;
    }

    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        require(userAddress != address(0));

        if (token == address(0)) {
            (bool success, ) = userAddress.call{value: address(this).balance}(
                ""
            );
            require(success);
        } else {
            // do we need safe transfer?
            IERC20(token).transfer(userAddress, amount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/IDecapacitor.sol";
import "../libraries/SafeTransferLib.sol";
import "../utils/Ownable.sol";

contract SingleDecapacitor is IDecapacitor, Ownable(msg.sender) {
    using SafeTransferLib for IERC20;

    /// returns if the packed message is the part of a merkle tree or not
    /// @inheritdoc IDecapacitor
    function verifyMessageInclusion(
        bytes32 root_,
        bytes32 packedMessage_,
        bytes calldata
    ) external pure override returns (bool) {
        return root_ == packedMessage_;
    }

    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        require(userAddress != address(0));

        if (token == address(0)) {
            (bool success, ) = userAddress.call{value: address(this).balance}(
                ""
            );
            require(success);
        } else {
            // do we need safe transfer?
            IERC20(token).transfer(userAddress, amount);
        }
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

    error OnlyOwner();

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
        bytes memory payload = abi.encode(OP_ADD, amount, msg.sender);
        _outbound(chainSlug, msgGasLimit, payload);
    }

    function remoteSubOperation(
        uint256 chainSlug,
        uint256 amount,
        uint256 msgGasLimit
    ) external payable {
        bytes memory payload = abi.encode(OP_SUB, amount, msg.sender);
        _outbound(chainSlug, msgGasLimit, payload);
    }

    function inbound(
        uint256,
        bytes calldata payload
    ) external payable override {
        require(msg.sender == socket, "Counter: Invalid Socket");
        (bytes32 operationType, uint256 amount, address sender) = abi.decode(
            payload,
            (bytes32, uint256, address)
        );

        if (sender != owner) revert OnlyOwner();

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
        address switchboard
    ) external onlyOwner {
        ISocket(socket).connect(
            remoteChainSlug,
            remotePlug,
            switchboard,
            switchboard
        );
    }

    function setupComplete() external {
        owner = address(0);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/IPlug.sol";
import "../interfaces/ISocket.sol";
import "../utils/Ownable.sol";

contract Messenger is IPlug, Ownable(msg.sender) {
    // immutables
    address private immutable _socket;
    uint256 private immutable _chainSlug;

    bytes32 private _message;
    uint256 public msgGasLimit;

    bytes32 private constant _PING = keccak256("PING");
    bytes32 private constant _PONG = keccak256("PONG");

    uint256 public constant SOCKET_FEE = 0.001 ether;

    error NoSocketFee();

    constructor(address socket_, uint256 chainSlug_, uint256 msgGasLimit_) {
        _socket = socket_;
        _chainSlug = chainSlug_;

        msgGasLimit = msgGasLimit_;
    }

    receive() external payable {}

    function removeGas(address payable receiver_) external onlyOwner {
        receiver_.transfer(address(this).balance);
    }

    function sendLocalMessage(bytes32 message_) external {
        _updateMessage(message_);
    }

    function sendRemoteMessage(
        uint256 remoteChainSlug_,
        bytes32 message_
    ) external payable {
        bytes memory payload = abi.encode(_chainSlug, message_);
        _outbound(remoteChainSlug_, payload);
    }

    function inbound(
        uint256,
        bytes calldata payload_
    ) external payable override {
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
        address switchboard
    ) external onlyOwner {
        ISocket(_socket).connect(
            remoteChainSlug,
            remotePlug,
            switchboard,
            switchboard
        );
    }

    function message() external view returns (bytes32) {
        return _message;
    }

    function _updateMessage(bytes32 message_) private {
        _message = message_;
    }

    function _outbound(uint256 targetChain_, bytes memory payload_) private {
        if (!(address(this).balance >= SOCKET_FEE)) revert NoSocketFee();
        ISocket(_socket).outbound{value: SOCKET_FEE}(
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

contract RemoteClaim is IPlug {
    // immutables
    address public immutable socket;

    address public owner;

    // application state
    uint256 public counter;

    // application ops
    bytes32 constant OP_ADD = keccak256("OP_ADD");
    bytes32 constant OP_SUB = keccak256("OP_SUB");

    error OnlyOwner();

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
        bytes memory payload = abi.encode(OP_ADD, amount, msg.sender);
        _outbound(chainSlug, msgGasLimit, payload);
    }

    function remoteSubOperation(
        uint256 chainSlug,
        uint256 amount,
        uint256 msgGasLimit
    ) external payable {
        bytes memory payload = abi.encode(OP_SUB, amount, msg.sender);
        _outbound(chainSlug, msgGasLimit, payload);
    }

    function inbound(
        uint256,
        bytes calldata payload
    ) external payable override {
        require(msg.sender == socket, "Counter: Invalid Socket");
        (bytes32 operationType, uint256 amount, address sender) = abi.decode(
            payload,
            (bytes32, uint256, address)
        );

        if (sender != owner) revert OnlyOwner();

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
        address switchboard
    ) external onlyOwner {
        ISocket(socket).connect(
            remoteChainSlug,
            remotePlug,
            switchboard,
            switchboard
        );
    }

    function setupComplete() external {
        owner = address(0);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./interfaces/IExecutionManager.sol";
import "./interfaces/IOracle.sol";
import "./utils/AccessControl.sol";
import "./libraries/SafeTransferLib.sol";

contract ExecutionManager is IExecutionManager, AccessControl {
    using SafeTransferLib for IERC20;

    IOracle public oracle;

    // keccak256("EXECUTOR")
    bytes32 private constant EXECUTOR_ROLE =
        0x9cf85f95575c3af1e116e3d37fd41e7f36a8a373623f51ffaaa87fdd032fa767;

    error TransferFailed();
    error InsufficientExecutionFees();

    constructor(IOracle oracle_, address owner_) AccessControl(owner_) {
        oracle = IOracle(oracle_);
    }

    function isExecutor(
        address executor_
    ) external view override returns (bool) {
        return _hasRole(EXECUTOR_ROLE, executor_);
    }

    function payFees(
        uint256 msgGasLimit_,
        uint256 siblingChainSlug_
    ) external payable override {
        if (msg.value < _getExecutionFees(msgGasLimit_, siblingChainSlug_))
            revert InsufficientExecutionFees();
    }

    function getMinFees(
        uint256 msgGasLimit_,
        uint256 siblingChainSlug_
    ) external view override returns (uint256) {
        return _getExecutionFees(msgGasLimit_, siblingChainSlug_);
    }

    function _getExecutionFees(
        uint256 msgGasLimit,
        uint256 dstChainSlug
    ) internal view returns (uint256) {
        uint256 dstRelativeGasPrice = oracle.relativeGasPrice(dstChainSlug);
        return msgGasLimit * dstRelativeGasPrice;
    }

    // TODO: to support fee distribution
    /**
     * @notice transfers the fees collected to `account_`
     * @param account_ address to transfer ETH
     */
    function withdrawFees(address account_) external onlyOwner {
        require(account_ != address(0));
        (bool success, ) = account_.call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
    }

    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        if (token == address(0)) {
            payable(userAddress).transfer(amount);
        } else {
            // do we need safe transfer?
            IERC20(token).transfer(userAddress, amount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "./interfaces/IOracle.sol";
import "./interfaces/ITransmitManager.sol";
import "./utils/AccessControl.sol";
import "./libraries/SafeTransferLib.sol";

contract GasPriceOracle is IOracle, Ownable {
    using SafeTransferLib for IERC20;

    ITransmitManager public transmitManager;

    // plugs/switchboards/transmitter can use it to ensure prices are updated
    mapping(uint256 => uint256) public updatedAt;
    // chain slug => relative gas price
    mapping(uint256 => uint256) public override relativeGasPrice;

    event GasPriceUpdated(uint256 dstChainSlug_, uint256 relativeGasPrice_);
    event TransmitManagerUpdated(address transmitManager);

    error TransmitterNotFound();

    constructor(address owner_) Ownable(owner_) {}

    /**
     * @dev the relative prices are calculated as:
     * relativeGasPrice = (dstGasPrice * dstGasUSDPrice)/srcGasUSDPrice
     * It is assumed that precision of relative gas price will be same as src native tokens
     * So that when it is multiplied with gas limits at other contracts, we get correct values.
     */
    function setRelativeGasPrice(
        uint256 dstChainSlug_,
        uint256 relativeGasPrice_
    ) external {
        if (!transmitManager.isTransmitter(msg.sender, dstChainSlug_))
            revert TransmitterNotFound();

        relativeGasPrice[dstChainSlug_] = relativeGasPrice_;
        updatedAt[dstChainSlug_] = block.timestamp;

        emit GasPriceUpdated(dstChainSlug_, relativeGasPrice_);
    }

    function setTransmitManager(
        ITransmitManager transmitManager_
    ) external onlyOwner {
        transmitManager = transmitManager_;
        emit TransmitManagerUpdated(address(transmitManager_));
    }

    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        require(userAddress != address(0));

        if (token == address(0)) {
            (bool success, ) = userAddress.call{value: address(this).balance}(
                ""
            );
            require(success);
        } else {
            // do we need safe transfer?
            IERC20(token).transfer(userAddress, amount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface ICapacitor {
    /**
     * @notice emits the message details when it arrives
     * @param packedMessage the message packed with payload, fees and config
     * @param packetCount an incremental id assigned to each new packet
     * @param newRootHash the packed message hash (to be replaced with the root hash of the merkle tree)
     */
    event MessageAdded(
        bytes32 packedMessage,
        uint256 packetCount,
        bytes32 newRootHash
    );

    /**
     * @notice emits when the packet is sealed and indicates it can be send to remote
     * @param rootHash the packed message hash (to be replaced with the root hash of the merkle tree)
     * @param packetCount an incremental id assigned to each new packet
     */
    event PacketComplete(bytes32 rootHash, uint256 packetCount);

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
     * @return packetCount latest packet id which is not yet sealed
     */
    function getNextPacketToBeSealed()
        external
        view
        returns (bytes32 root, uint256 packetCount);

    /**
     * @notice returns the root of packet for given id
     * @param id the id assigned to packet
     * @return root root hash corresponding to given id
     */
    function getRootById(uint256 id) external view returns (bytes32 root);

    /**
     * @notice seals the packet
     * @dev also indicates the packet is ready to be shipped and no more messages can be added now.
     * @dev this should be executable by socket only
     * @return root root hash of the packet
     * @return packetCount id of the packed sealed
     */
    function sealPacket() external returns (bytes32 root, uint256 packetCount);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "./ICapacitor.sol";
import "./IDecapacitor.sol";

interface ICapacitorFactory {
    error InvalidCapacitorType();

    function deploy(
        uint256 capacitorType,
        uint256 siblingChainSlug
    ) external returns (ICapacitor, IDecapacitor);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface IDecapacitor {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface IExecutionManager {
    function isExecutor(address user) external view returns (bool);

    function payFees(uint256 msgGasLimit, uint256 dstSlug) external payable;

    function getMinFees(
        uint256 msgGasLimit,
        uint256 dstSlug
    ) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface IHasher {
    /**
     * @notice returns the bytes32 hash of the message packed
     * @param srcChainSlug src chain slug
     * @param srcPlug address of plug at source
     * @param dstChainSlug remote chain slug
     * @param dstPlug address of plug at remote
     * @param msgId message id assigned at outbound
     * @param msgGasLimit gas limit which is expected to be consumed by the inbound transaction on plug
     * @param executionFee msg value which is expected to be sent with inbound transaction to plug
     * @param payload the data packed which is used by inbound for execution
     */
    function packMessage(
        uint256 srcChainSlug,
        address srcPlug,
        uint256 dstChainSlug,
        address dstPlug,
        uint256 msgId,
        uint256 msgGasLimit,
        uint256 executionFee,
        bytes calldata payload
    ) external returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface IOracle {
    function relativeGasPrice(
        uint256 dstChainSlug
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface IPlug {
    /**
     * @notice executes the message received from source chain
     * @dev this should be only executable by socket
     * @param srcChainSlug_ chain slug of source
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function inbound(
        uint256 srcChainSlug_,
        bytes calldata payload_
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface ISignatureVerifier {
    /**
     * @notice returns the address of signer recovered from input signature
     * @param dstChainSlug_ remote chain slug
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface ISocket {
    /**
     * @notice emits the message details when a new message arrives at outbound
     * @param localChainSlug local chain slug
     * @param localPlug local plug address
     * @param dstChainSlug remote chain slug
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
        uint256 executionFee,
        uint256 fees,
        bytes payload
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

    /**
     * @notice emits the config set by a plug for a remoteChainSlug
     * @param plug address of plug on current chain
     * @param siblingChainSlug sibling chain slug
     * @param siblingPlug address of plug on sibling chain
     * @param inboundSwitchboard inbound switchboard (select from registered options)
     * @param outboundSwitchboard outbound switchboard (select from registered options)
     * @param capacitor capacitor selected based on outbound switchboard
     * @param decapacitor decapacitor selected based on inbound switchboard
     */
    event PlugConnected(
        address plug,
        uint256 siblingChainSlug,
        address siblingPlug,
        address inboundSwitchboard,
        address outboundSwitchboard,
        address capacitor,
        address decapacitor
    );

    /**
     * @notice emits when a new transmitManager contract is set
     * @param transmitManager_ address of new transmitManager contract
     */
    event TransmitManagerSet(address transmitManager_);

    /**
     * @notice registers a message
     * @dev Packs the message and includes it in a packet with capacitor
     * @param remoteChainSlug_ the remote chain slug
     * @param msgGasLimit_ the gas limit needed to execute the payload on remote
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function outbound(
        uint256 remoteChainSlug_,
        uint256 msgGasLimit_,
        bytes calldata payload_
    ) external payable returns (uint256 msgId);

    struct MessageDetails {
        uint256 msgId;
        uint256 executionFee;
        uint256 msgGasLimit;
        bytes payload;
        bytes decapacitorProof;
    }

    /**
     * @notice executes a message
     * @param packetId packet id
     * @param localPlug local plug address
     * @param messageDetails_ the details needed for message verification
     */
    function execute(
        uint256 packetId,
        address localPlug,
        ISocket.MessageDetails calldata messageDetails_
    ) external;

    /**
     * @notice sets the config specific to the plug
     * @param siblingChainSlug_ the sibling chain slug
     * @param siblingPlug_ address of plug present at sibling chain to call inbound
     * @param inboundSwitchboard_ the address of switchboard to use for receiving messages
     * @param outboundSwitchboard_ the address of switchboard to use for sending messages
     */
    function connect(
        uint256 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external;

    function remoteRoots(uint256 packetId_) external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface ISwitchboard {
    function allowPacket(
        bytes32 root,
        uint256 packetId,
        uint256 srcChainSlug,
        uint256 proposeTime
    ) external view returns (bool);

    function payFees(uint256 dstChainSlug) external payable;

    function getMinFees(
        uint256 dstChainSlug
    ) external view returns (uint256 switchboardFee, uint256 verificationFee);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface ITransmitManager {
    function isTransmitter(
        address user,
        uint256 siblingChainSlug
    ) external view returns (bool);

    function checkTransmitter(
        uint256 chainSlugs_,
        uint256 packetId,
        bytes32 root,
        bytes calldata signature
    ) external view returns (address, bool);

    function payFees(uint256 dstSlug) external payable;

    function getMinFees(uint256 dstSlug) external view returns (uint256);
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
    function withdrawEth(
        address destination
    ) external payable returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @param destination recipient address on L1
     * @param calldataForL1 (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(
        address destination,
        bytes calldata calldataForL1
    ) external payable returns (uint256);

    /**
     * @notice get the number of transactions issued by the given external account or the account sequence number of the given contract
     * @param account target account
     * @return the number of transactions issued by the given external account or the account sequence number of the given contract
     */
    function getTransactionCount(
        address account
    ) external view returns (uint256);

    /**
     * @notice get the value of target L2 storage slot
     * This function is only callable from address 0 to prevent contracts from being able to call it
     * @param account target account
     * @param index target index of storage slot
     * @return stotage value for the given account at the given index
     */
    function getStorageAt(
        address account,
        uint256 index
    ) external view returns (uint256);

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
    function mapL1SenderContractAddressToL2Alias(
        address sender,
        address dest
    ) external pure returns (address);

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

interface IBridge {
    function activeOutbox() external view returns (address);

    function inboxAccs(uint256 index) external view returns (bytes32);

    function messageCount() external view returns (uint256);

    function isNitroReady() external view returns (uint256);
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

interface INativeReceiver {
    function receivePacket(uint256 packetId, bytes32 root) external;
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
    function applyL1ToL2Alias(
        address l1Address
    ) internal pure returns (address l2Address) {
        unchecked {
            l2Address = address(uint160(l1Address) + OFFSET);
        }
    }

    /// @notice Utility function that converts the msg.sender viewed in the L2 to the
    /// address in the L1 that submitted a tx to the inbox
    /// @param l2Address L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(
        address l2Address
    ) internal pure returns (address l1Address) {
        unchecked {
            l1Address = address(uint160(l2Address) - OFFSET);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0xa9059cbb00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }
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

import "../utils/Ownable.sol";

contract MockOwnable is Ownable {
    constructor(address owner) Ownable(owner) {}

    function ownerFunction() external onlyOwner {}

    function publicFunction() external {}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface IPlug {
    /**
     * @notice executes the message received from source chain
     * @dev this should be only executable by socket
     * @param srcChainSlug_ chain slug of source
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function inbound(
        uint256 srcChainSlug_,
        bytes calldata payload_
    ) external payable;
}

contract MockSocket {
    uint256 public immutable _chainSlug;

    error WrongRemotePlug();
    error WrongIntegrationType();

    struct PlugConfig {
        address remotePlug;
        bytes32 inboundIntegrationType;
        bytes32 outboundIntegrationType;
    }

    // integrationType => remoteChainSlug => address
    mapping(bytes32 => mapping(uint256 => bool)) public configExists;
    // plug => remoteChainSlug => config(verifiers, capacitors, decapacitors, remotePlug)
    mapping(address => mapping(uint256 => PlugConfig)) public plugConfigs;

    error InvalidIntegrationType();

    constructor() {
        _chainSlug = 1;

        configExists[keccak256(abi.encode("FAST"))][1] = true;
        configExists[keccak256(abi.encode("SLOW"))][1] = true;
        configExists[keccak256(abi.encode("NATIVE_BRIDGE"))][1] = true;

        configExists[keccak256(abi.encode("FAST"))][2] = true;
        configExists[keccak256(abi.encode("SLOW"))][2] = true;
        configExists[keccak256(abi.encode("NATIVE_BRIDGE"))][2] = true;
    }

    function setPlugConfig(
        uint256 remoteChainSlug_,
        address remotePlug_,
        string memory inboundIntegrationType_,
        string memory outboundIntegrationType_
    ) external {
        bytes32 inboundIntegrationType = keccak256(
            abi.encode(inboundIntegrationType_)
        );
        bytes32 outboundIntegrationType = keccak256(
            abi.encode(outboundIntegrationType_)
        );
        if (
            !configExists[inboundIntegrationType][remoteChainSlug_] ||
            !configExists[outboundIntegrationType][remoteChainSlug_]
        ) revert InvalidIntegrationType();

        PlugConfig storage plugConfig = plugConfigs[msg.sender][
            remoteChainSlug_
        ];

        plugConfig.remotePlug = remotePlug_;
        plugConfig.inboundIntegrationType = inboundIntegrationType;
        plugConfig.outboundIntegrationType = outboundIntegrationType;
    }

    function getPlugConfig(
        uint256 remoteChainSlug_,
        address plug_
    )
        external
        view
        returns (
            address capacitor,
            address decapacitor,
            address verifier,
            address remotePlug,
            bytes32 outboundIntegrationType,
            bytes32 inboundIntegrationType
        )
    {
        PlugConfig memory plugConfig = plugConfigs[plug_][remoteChainSlug_];
        return (
            address(0),
            address(0),
            address(0),
            plugConfig.remotePlug,
            plugConfig.outboundIntegrationType,
            plugConfig.inboundIntegrationType
        );
    }

    function outbound(
        uint256 remoteChainSlug_,
        uint256 msgGasLimit_,
        bytes calldata payload_
    ) external payable returns (uint256) {
        PlugConfig memory srcPlugConfig = plugConfigs[msg.sender][
            remoteChainSlug_
        ];

        PlugConfig memory dstPlugConfig = plugConfigs[srcPlugConfig.remotePlug][
            _chainSlug
        ];

        if (dstPlugConfig.remotePlug != msg.sender) revert WrongRemotePlug();
        if (
            srcPlugConfig.outboundIntegrationType !=
            dstPlugConfig.inboundIntegrationType &&
            srcPlugConfig.inboundIntegrationType !=
            dstPlugConfig.outboundIntegrationType
        ) revert WrongIntegrationType();

        IPlug(srcPlugConfig.remotePlug).inbound{gas: msgGasLimit_}(
            _chainSlug,
            payload_
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import {SocketSrc} from "./SocketSrc.sol";
import "./SocketDst.sol";
import "../libraries/SafeTransferLib.sol";

contract Socket is SocketSrc, SocketDst {
    using SafeTransferLib for IERC20;

    constructor(
        uint32 chainSlug_,
        address hasher_,
        address transmitManager_,
        address executionManager_,
        address capacitorFactory_
    ) {
        _chainSlug = chainSlug_;
        _hasher__ = IHasher(hasher_);
        _transmitManager__ = ITransmitManager(transmitManager_);
        _executionManager__ = IExecutionManager(executionManager_);
        _capacitorFactory__ = ICapacitorFactory(capacitorFactory_);
    }

    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        require(userAddress != address(0));

        if (token == address(0)) {
            (bool success, ) = userAddress.call{value: address(this).balance}(
                ""
            );
            require(success);
        } else {
            // do we need safe transfer?
            IERC20(token).transfer(userAddress, amount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/IHasher.sol";
import "../interfaces/ITransmitManager.sol";
import "../interfaces/IExecutionManager.sol";

import "../utils/ReentrancyGuard.sol";
import "./SocketConfig.sol";

abstract contract SocketBase is SocketConfig, ReentrancyGuard {
    IHasher public _hasher__;
    ITransmitManager public _transmitManager__;
    IExecutionManager public _executionManager__;

    uint256 public _chainSlug;

    error InvalidAttester();

    event HasherSet(address hasher_);

    function setHasher(address hasher_) external onlyOwner {
        _hasher__ = IHasher(hasher_);
        emit HasherSet(hasher_);
    }

    // TODO: in discussion
    /**
     * @notice updates transmitManager_
     * @param transmitManager_ address of Transmit Manager
     */
    function setTransmitManager(address transmitManager_) external onlyOwner {
        _transmitManager__ = ITransmitManager(transmitManager_);
        emit TransmitManagerSet(transmitManager_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/ISocket.sol";
import "../utils/Ownable.sol";
import "../interfaces/ICapacitorFactory.sol";
import "../interfaces/ISwitchboard.sol";
import {AccessControl} from "../utils/AccessControl.sol";

abstract contract SocketConfig is ISocket, Ownable(msg.sender) {
    struct PlugConfig {
        address siblingPlug;
        ICapacitor capacitor__;
        IDecapacitor decapacitor__;
        ISwitchboard inboundSwitchboard__;
        ISwitchboard outboundSwitchboard__;
    }

    ICapacitorFactory public _capacitorFactory__;

    // siblingChainSlug => capacitor address
    mapping(address => uint256) public _capacitorToSlug;

    // switchboard => siblingChainSlug => ICapacitor
    mapping(address => mapping(uint256 => ICapacitor)) public _capacitors__;
    // switchboard => siblingChainSlug => IDecapacitor
    mapping(address => mapping(uint256 => IDecapacitor)) public _decapacitors__;

    // plug | remoteChainSlug => (siblingPlug, capacitor__, decapacitor__, inboundSwitchboard__, outboundSwitchboard__)
    mapping(uint256 => PlugConfig) internal _plugConfigs;

    event SwitchboardAdded(
        address switchboard,
        uint256 siblingChainSlug,
        address capacitor,
        address decapacitor
    );
    event CapacitorFactorySet(address capacitorFactory_);

    error SwitchboardExists();
    error InvalidConnection();

    // todo: need event, check for other such functions.
    function setCapacitorFactory(address capacitorFactory_) external onlyOwner {
        _capacitorFactory__ = ICapacitorFactory(capacitorFactory_);
        emit CapacitorFactorySet(capacitorFactory_);
    }

    function registerSwitchBoard(
        address switchBoardAddress_,
        uint32 siblingChainSlug_,
        uint32 capacitorType_
    ) external {
        // only capacitor checked, decapacitor assumed will exist if capacitor does
        if (
            address(_capacitors__[switchBoardAddress_][siblingChainSlug_]) !=
            address(0)
        ) revert SwitchboardExists();

        (
            ICapacitor capacitor__,
            IDecapacitor decapacitor__
        ) = _capacitorFactory__.deploy(capacitorType_, siblingChainSlug_);

        _capacitorToSlug[address(capacitor__)] = siblingChainSlug_;
        _capacitors__[switchBoardAddress_][siblingChainSlug_] = capacitor__;
        _decapacitors__[switchBoardAddress_][siblingChainSlug_] = decapacitor__;

        emit SwitchboardAdded(
            switchBoardAddress_,
            siblingChainSlug_,
            address(capacitor__),
            address(decapacitor__)
        );
    }

    function connect(
        uint256 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external override {
        if (
            address(_capacitors__[inboundSwitchboard_][siblingChainSlug_]) ==
            address(0) ||
            address(_capacitors__[outboundSwitchboard_][siblingChainSlug_]) ==
            address(0)
        ) revert InvalidConnection();

        PlugConfig storage _plugConfig = _plugConfigs[
            (uint256(uint160(msg.sender)) << 96) | siblingChainSlug_
        ];

        _plugConfig.siblingPlug = siblingPlug_;
        _plugConfig.capacitor__ = _capacitors__[outboundSwitchboard_][
            siblingChainSlug_
        ];
        _plugConfig.decapacitor__ = _decapacitors__[inboundSwitchboard_][
            siblingChainSlug_
        ];
        _plugConfig.inboundSwitchboard__ = ISwitchboard(inboundSwitchboard_);
        _plugConfig.outboundSwitchboard__ = ISwitchboard(outboundSwitchboard_);

        emit PlugConnected(
            msg.sender,
            siblingChainSlug_,
            _plugConfig.siblingPlug,
            address(_plugConfig.inboundSwitchboard__),
            address(_plugConfig.outboundSwitchboard__),
            address(_plugConfig.capacitor__),
            address(_plugConfig.decapacitor__)
        );
    }

    function getPlugConfig(
        address plugAddress_,
        uint256 siblingChainSlug_
    )
        external
        view
        returns (
            address siblingPlug,
            address inboundSwitchboard__,
            address outboundSwitchboard__,
            address capacitor__,
            address decapacitor__
        )
    {
        PlugConfig memory _plugConfig = _plugConfigs[
            (uint256(uint160(plugAddress_)) << 96) | siblingChainSlug_
        ];

        return (
            _plugConfig.siblingPlug,
            address(_plugConfig.inboundSwitchboard__),
            address(_plugConfig.outboundSwitchboard__),
            address(_plugConfig.capacitor__),
            address(_plugConfig.decapacitor__)
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/IDecapacitor.sol";
import "../interfaces/IPlug.sol";

import "./SocketBase.sol";

abstract contract SocketDst is SocketBase {
    error AlreadyAttested();
    error InvalidProof();
    error InvalidRetry();
    error MessageAlreadyExecuted();
    error NotExecutor();
    error VerificationFailed();

    // srcChainSlug => switchboardAddress => executorAddress => fees
    mapping(uint256 => mapping(address => mapping(address => uint256)))
        public feesEarned;
    // msgId => message status
    mapping(uint256 => bool) public messageExecuted;
    // capacitorAddr|chainSlug|packetId
    mapping(uint256 => bytes32) public override remoteRoots;
    mapping(uint256 => uint256) public rootProposedAt;

    /**
     * @notice emits the packet details when proposed at remote
     * @param attester address of attester
     * @param packetId packet id
     * @param root packet root
     */
    event PacketAttested(
        address indexed attester,
        uint256 indexed packetId,
        bytes32 root
    );

    /**
     * @notice emits the root details when root is replaced by owner
     * @param packetId packet id
     * @param oldRoot old root
     * @param newRoot old root
     */
    event PacketRootUpdated(uint256 packetId, bytes32 oldRoot, bytes32 newRoot);

    function propose(
        uint256 packetId_,
        bytes32 root_,
        bytes calldata signature_
    ) external {
        if (remoteRoots[packetId_] != bytes32(0)) revert AlreadyAttested();
        (address transmitter, bool isTransmitter) = _transmitManager__
            .checkTransmitter(
                (_getChainSlug(packetId_) << 128) | _chainSlug,
                packetId_,
                root_,
                signature_
            );
        if (!isTransmitter) revert InvalidAttester();

        remoteRoots[packetId_] = root_;
        rootProposedAt[packetId_] = block.timestamp;

        emit PacketAttested(transmitter, packetId_, root_);
    }

    /**
     * @notice executes a message
     * @param packetId packet id
     * @param localPlug remote plug address
     * @param messageDetails_ the details needed for message verification
     */
    function execute(
        uint256 packetId,
        address localPlug,
        ISocket.MessageDetails calldata messageDetails_
    ) external override {
        if (!_executionManager__.isExecutor(msg.sender)) revert NotExecutor();
        if (messageExecuted[messageDetails_.msgId])
            revert MessageAlreadyExecuted();
        messageExecuted[messageDetails_.msgId] = true;

        uint256 remoteSlug = uint256(messageDetails_.msgId >> 224);

        PlugConfig storage plugConfig = _plugConfigs[
            (uint256(uint160(localPlug)) << 96) | remoteSlug
        ];

        feesEarned[remoteSlug][address(plugConfig.inboundSwitchboard__)][
            msg.sender
        ] += messageDetails_.executionFee;

        bytes32 packedMessage = _hasher__.packMessage(
            remoteSlug,
            plugConfig.siblingPlug,
            _chainSlug,
            localPlug,
            messageDetails_.msgId,
            messageDetails_.msgGasLimit,
            messageDetails_.executionFee,
            messageDetails_.payload
        );

        _verify(
            packetId,
            remoteSlug,
            packedMessage,
            plugConfig,
            messageDetails_.decapacitorProof
        );
        _execute(
            localPlug,
            remoteSlug,
            messageDetails_.msgGasLimit,
            messageDetails_.msgId,
            messageDetails_.payload
        );
    }

    function _verify(
        uint256 packetId,
        uint256 remoteChainSlug,
        bytes32 packedMessage,
        PlugConfig storage plugConfig,
        bytes memory decapacitorProof
    ) internal view {
        if (
            !ISwitchboard(plugConfig.inboundSwitchboard__).allowPacket(
                remoteRoots[packetId],
                packetId,
                remoteChainSlug,
                rootProposedAt[packetId]
            )
        ) revert VerificationFailed();

        if (
            !plugConfig.decapacitor__.verifyMessageInclusion(
                remoteRoots[packetId],
                packedMessage,
                decapacitorProof
            )
        ) revert InvalidProof();
    }

    function _execute(
        address localPlug,
        uint256 remoteChainSlug,
        uint256 msgGasLimit,
        uint256 msgId,
        bytes calldata payload
    ) internal {
        try
            IPlug(localPlug).inbound{gas: msgGasLimit}(remoteChainSlug, payload)
        {
            emit ExecutionSuccess(msgId);
        } catch Error(string memory reason) {
            // catch failing revert() and require()
            messageExecuted[msgId] = false;
            emit ExecutionFailed(msgId, reason);
        } catch (bytes memory reason) {
            // catch failing assert()
            messageExecuted[msgId] = false;
            emit ExecutionFailedBytes(msgId, reason);
        }
    }

    /**
     * @notice updates root for given packet id
     * @param packetId_ id of packet to be updated
     * @param newRoot_ new root
     */
    function updatePacketRoot(
        uint256 packetId_,
        bytes32 newRoot_
    ) external onlyOwner {
        bytes32 oldRoot = remoteRoots[packetId_];
        remoteRoots[packetId_] = newRoot_;

        emit PacketRootUpdated(packetId_, oldRoot, newRoot_);
    }

    function isPacketProposed(uint256 packetId_) external view returns (bool) {
        return remoteRoots[packetId_] == bytes32(0) ? false : true;
    }

    function _getChainSlug(
        uint256 packetId_
    ) internal pure returns (uint256 chainSlug_) {
        chainSlug_ = uint32(packetId_ >> 224);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/ICapacitor.sol";
import "./SocketBase.sol";

abstract contract SocketSrc is SocketBase {
    // incrementing nonce, should be handled in next socket version.
    uint256 public _messageCount;

    error InsufficientFees();

    /**
     * @notice emits the verification and seal confirmation of a packet
     * @param transmitter address of transmitter recovered from sig
     * @param packetId packed id
     * @param signature signature of attester
     */
    event PacketVerifiedAndSealed(
        address indexed transmitter,
        uint256 indexed packetId,
        bytes signature
    );

    /**
     * @notice registers a message
     * @dev Packs the message and includes it in a packet with capacitor
     * @param remoteChainSlug_ the remote chain slug
     * @param msgGasLimit_ the gas limit needed to execute the payload on remote
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function outbound(
        uint256 remoteChainSlug_,
        uint256 msgGasLimit_,
        bytes calldata payload_
    ) external payable override returns (uint256 msgId) {
        PlugConfig storage plugConfig = _plugConfigs[
            (uint256(uint160(msg.sender)) << 96) | remoteChainSlug_
        ];
        uint256 localChainSlug = _chainSlug;

        // Packs the local plug, local chain slug, remote chain slug and nonce
        // _messageCount++ will take care of msg id overflow as well
        // msgId(256) = localChainSlug(32) | nonce(224)
        msgId = (uint256(uint32(localChainSlug)) << 224) | _messageCount++;

        uint256 executionFee = _deductFees(
            msgGasLimit_,
            remoteChainSlug_,
            plugConfig.outboundSwitchboard__
        );

        bytes32 packedMessage = _hasher__.packMessage(
            localChainSlug,
            msg.sender,
            remoteChainSlug_,
            plugConfig.siblingPlug,
            msgId,
            msgGasLimit_,
            executionFee,
            payload_
        );

        plugConfig.capacitor__.addPackedMessage(packedMessage);
        emit MessageTransmitted(
            localChainSlug,
            msg.sender,
            remoteChainSlug_,
            plugConfig.siblingPlug,
            msgId,
            msgGasLimit_,
            executionFee,
            msg.value,
            payload_
        );
    }

    function _deductFees(
        uint256 msgGasLimit_,
        uint256 remoteChainSlug_,
        ISwitchboard switchboard__
    ) internal returns (uint256 executionFee) {
        uint256 transmitFees = _transmitManager__.getMinFees(remoteChainSlug_);
        (uint256 switchboardFees, uint256 verificationFee) = switchboard__
            .getMinFees(remoteChainSlug_);
        uint256 msgExecutionFee = _executionManager__.getMinFees(
            msgGasLimit_,
            remoteChainSlug_
        );

        if (
            msg.value <
            transmitFees + switchboardFees + verificationFee + msgExecutionFee
        ) revert InsufficientFees();

        unchecked {
            // any extra fee is considered as executionFee
            executionFee = msg.value - transmitFees - switchboardFees;

            _transmitManager__.payFees{value: transmitFees}(remoteChainSlug_);
            switchboard__.payFees{value: switchboardFees}(remoteChainSlug_);
            _executionManager__.payFees{value: executionFee}(
                msgGasLimit_,
                remoteChainSlug_
            );
        }
    }

    function seal(
        address capacitorAddress_,
        bytes calldata signature_
    ) external payable nonReentrant {
        (bytes32 root, uint256 packetCount) = ICapacitor(capacitorAddress_)
            .sealPacket();

        uint256 packetId = (_chainSlug << 224) |
            (uint256(uint160(capacitorAddress_)) << 64) |
            packetCount;

        uint256 siblingChainSlug = _capacitorToSlug[capacitorAddress_];

        (address transmitter, bool isTransmitter) = _transmitManager__
            .checkTransmitter(
                (siblingChainSlug << 128) | siblingChainSlug,
                packetId,
                root,
                signature_
            );

        if (!isTransmitter) revert InvalidAttester();

        emit PacketVerifiedAndSealed(transmitter, packetId, signature_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "./SwitchboardBase.sol";

contract FastSwitchboard is SwitchboardBase {
    uint256 public immutable timeoutInSeconds;

    // dst chain slug => total watchers registered
    mapping(uint256 => uint256) public totalWatchers;

    // dst chain slug => attest gas limit
    mapping(uint256 => uint256) public attestGasLimit;

    // attester => packetId => is attested
    mapping(address => mapping(uint256 => bool)) public isAttested;

    // packetId => total attestations
    mapping(uint256 => uint256) public attestations;

    event SocketSet(address newSocket_);
    event PacketAttested(uint256 packetId, address attester);
    event AttestGasLimitSet(uint256 dstChainSlug_, uint256 attestGasLimit_);

    error WatcherFound();
    error WatcherNotFound();
    error AlreadyAttested();
    error InvalidSigLength();

    constructor(
        address owner_,
        address oracle_,
        uint256 timeoutInSeconds_
    ) AccessControl(owner_) {
        oracle = IOracle(oracle_);
        timeoutInSeconds = timeoutInSeconds_;
    }

    function attest(
        uint256 packetId,
        uint256 srcChainSlug,
        bytes calldata signature
    ) external {
        address watcher = _recoverSigner(srcChainSlug, packetId, signature);

        if (isAttested[watcher][packetId]) revert AlreadyAttested();
        if (!_hasRole(_watcherRole(srcChainSlug), watcher))
            revert WatcherNotFound();

        isAttested[watcher][packetId] = true;
        attestations[packetId]++;

        emit PacketAttested(packetId, watcher);
    }

    /**
     * @notice verifies if the packet satisfies needed checks before execution
     * @param packetId packetId
     * @param proposeTime time at which packet was proposed
     */
    function allowPacket(
        bytes32,
        uint256 packetId,
        uint256 srcChainSlug,
        uint256 proposeTime
    ) external view override returns (bool) {
        if (tripGlobalFuse) return false;

        if (attestations[packetId] < totalWatchers[srcChainSlug]) {
            if (block.timestamp - proposeTime < timeoutInSeconds) return false;
        }

        return true;
    }

    function _getSwitchboardFees(
        uint256 dstChainSlug,
        uint256 dstRelativeGasPrice
    ) internal view override returns (uint256) {
        // assumption: number of watchers are going to be same on all chains for particular chain slug?
        return
            totalWatchers[dstChainSlug] *
            attestGasLimit[dstChainSlug] *
            dstRelativeGasPrice;
    }

    /**
     * @notice updates attest gas limit for given chain slug
     * @param dstChainSlug_ destination chain
     * @param attestGasLimit_ average gas limit needed for attest function call
     */
    function setAttestGasLimit(
        uint256 dstChainSlug_,
        uint256 attestGasLimit_
    ) external onlyOwner {
        attestGasLimit[dstChainSlug_] = attestGasLimit_;
        emit AttestGasLimitSet(dstChainSlug_, attestGasLimit_);
    }

    // TODO: watchers are chain specific hence letting them act globally seems weird, need to rethink
    /**
     * @notice pause execution
     * @dev this function can only be called by watchers for pausing the global execution
     */
    function trip(
        uint256 srcChainSlug_
    ) external onlyRole(_watcherRole(srcChainSlug_)) {
        tripGlobalFuse = false;
        emit SwitchboardTripped(false);
    }

    /**
     * @notice pause/unpause execution
     * @param tripGlobalFuse_ bool indicating verification is active or not
     */
    function trip(bool tripGlobalFuse_) external onlyOwner {
        tripGlobalFuse = tripGlobalFuse_;
        emit SwitchboardTripped(tripGlobalFuse_);
    }

    /**
     * @notice adds a watcher for `srcChainSlug_` chain
     * @param watcher_ watcher address
     */
    function grantWatcherRole(
        uint256 srcChainSlug_,
        address watcher_
    ) external onlyOwner {
        if (_hasRole(_watcherRole(srcChainSlug_), watcher_))
            revert WatcherFound();

        _grantRole(_watcherRole(srcChainSlug_), watcher_);
        totalWatchers[srcChainSlug_]++;
    }

    /**
     * @notice removes a watcher from `srcChainSlug_` chain list
     * @param watcher_ watcher address
     */
    function revokeWatcherRole(
        uint256 srcChainSlug_,
        address watcher_
    ) external onlyOwner {
        if (!_hasRole(_watcherRole(srcChainSlug_), watcher_))
            revert WatcherNotFound();

        _revokeRole(_watcherRole(srcChainSlug_), watcher_);
        totalWatchers[srcChainSlug_]--;
    }

    function _watcherRole(uint256 chainSlug_) internal pure returns (bytes32) {
        return bytes32(chainSlug_);
    }

    /**
     * @notice returns the address of signer recovered from input signature
     */
    function _recoverSigner(
        uint256 srcChainSlug_,
        uint256 packetId_,
        bytes memory signature_
    ) private pure returns (address signer) {
        bytes32 digest = keccak256(abi.encode(srcChainSlug_, packetId_));
        digest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", digest)
        );
        (bytes32 sigR, bytes32 sigS, uint8 sigV) = _splitSignature(signature_);

        // recovered signer is checked for the valid roles later
        signer = ecrecover(digest, sigV, sigR, sigS);
    }

    /**
     * @notice splits the signature into v, r and s.
     */
    function _splitSignature(
        bytes memory signature_
    ) private pure returns (bytes32 r, bytes32 s, uint8 v) {
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

import "./SwitchboardBase.sol";

contract OptimisticSwitchboard is SwitchboardBase {
    uint256 public immutable timeoutInSeconds;

    // packetId => isPaused
    mapping(uint256 => bool) public tripSingleFuse;

    event PacketTripped(uint256 packetId_, bool tripSingleFuse_);
    error WatcherNotFound();

    constructor(
        address owner_,
        address oracle_,
        uint256 timeoutInSeconds_
    ) AccessControl(owner_) {
        oracle = IOracle(oracle_);
        timeoutInSeconds = timeoutInSeconds_;
    }

    /**
     * @notice verifies if the packet satisfies needed checks before execution
     * @param packetId packet id
     * @param proposeTime time at which packet was proposed
     */
    function allowPacket(
        bytes32,
        uint256 packetId,
        uint256,
        uint256 proposeTime
    ) external view override returns (bool) {
        if (tripGlobalFuse || tripSingleFuse[packetId]) return false;
        if (block.timestamp - proposeTime < timeoutInSeconds) return false;
        return true;
    }

    /**
     * @notice pause execution
     */
    function tripGlobal(
        uint256 srcChainSlug_
    ) external onlyRole(_watcherRole(srcChainSlug_)) {
        tripGlobalFuse = false;
        emit SwitchboardTripped(false);
    }

    /**
     * @notice pause a packet
     */
    function tripSingle(
        uint256 packetId_,
        uint256 srcChainSlug_
    ) external onlyRole(_watcherRole(srcChainSlug_)) {
        tripSingleFuse[packetId_] = false;
        emit PacketTripped(packetId_, false);
    }

    /**
     * @notice pause/unpause execution
     */
    function tripGlobal(bool trip_) external onlyOwner {
        tripGlobalFuse = trip_;
        emit SwitchboardTripped(trip_);
    }

    /**
     * @notice pause/unpause a packet
     */
    function tripSingle(uint256 packetId_, bool trip_) external onlyOwner {
        tripSingleFuse[packetId_] = trip_;
        emit PacketTripped(packetId_, trip_);
    }

    /**
     * @notice adds an watcher for `remoteChainSlug_` chain
     * @param remoteChainSlug_ remote chain slug
     * @param watcher_ watcher address
     */
    function grantWatcherRole(
        uint256 remoteChainSlug_,
        address watcher_
    ) external onlyOwner {
        _grantRole(_watcherRole(remoteChainSlug_), watcher_);
    }

    /**
     * @notice removes an watcher from `remoteChainSlug_` chain list
     * @param remoteChainSlug_ remote chain slug
     * @param watcher_ watcher address
     */
    function revokeWatcherRole(
        uint256 remoteChainSlug_,
        address watcher_
    ) external onlyOwner {
        _revokeRole(_watcherRole(remoteChainSlug_), watcher_);
    }

    function _watcherRole(uint256 chainSlug_) internal pure returns (bytes32) {
        return bytes32(chainSlug_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../../interfaces/ISwitchboard.sol";
import "../../interfaces/IOracle.sol";
import "../../utils/AccessControl.sol";

import "../../libraries/SafeTransferLib.sol";

abstract contract SwitchboardBase is ISwitchboard, AccessControl {
    using SafeTransferLib for IERC20;

    IOracle public oracle;
    bool public tripGlobalFuse;
    mapping(uint256 => uint256) public executionOverhead;

    event SwitchboardTripped(bool tripGlobalFuse_);
    event ExecutionOverheadSet(
        uint256 dstChainSlug_,
        uint256 executionOverhead_
    );
    event OracleSet(address oracle_);
    event FeesWithdrawn(address account_, uint256 value_);

    error TransferFailed();
    error FeesNotEnough();

    function payFees(uint256 dstChainSlug) external payable override {
        (uint256 expectedFees, ) = _calculateFees(dstChainSlug);
        if (msg.value < expectedFees) revert FeesNotEnough();
    }

    function getMinFees(
        uint256 dstChainSlug
    ) external view override returns (uint256, uint256) {
        return _calculateFees(dstChainSlug);
    }

    function _calculateFees(
        uint256 dstChainSlug
    ) internal view returns (uint256 switchboardFee, uint256 verificationFee) {
        uint256 dstRelativeGasPrice = oracle.relativeGasPrice(dstChainSlug);

        switchboardFee = _getSwitchboardFees(dstChainSlug, dstRelativeGasPrice);
        verificationFee = executionOverhead[dstChainSlug] * dstRelativeGasPrice;
    }

    function _getSwitchboardFees(
        uint256 dstChainSlug,
        uint256 dstRelativeGasPrice
    ) internal view virtual returns (uint256) {}

    /**
     * @notice updates execution overhead
     * @param executionOverhead_ new execution overhead cost
     */
    function setExecutionOverhead(
        uint256 dstChainSlug_,
        uint256 executionOverhead_
    ) external onlyOwner {
        executionOverhead[dstChainSlug_] = executionOverhead_;
        emit ExecutionOverheadSet(dstChainSlug_, executionOverhead_);
    }

    /**
     * @notice updates oracle address
     * @param oracle_ new oracle
     */
    function setOracle(address oracle_) external onlyOwner {
        oracle = IOracle(oracle_);
        emit OracleSet(oracle_);
    }

    // TODO: to support fee distribution
    /**
     * @notice transfers the fees collected to `account_`
     * @param account_ address to transfer ETH
     */
    function withdrawFees(address account_) external onlyOwner {
        require(account_ != address(0));

        uint256 value = address(this).balance;
        (bool success, ) = account_.call{value: value}("");
        if (!success) revert TransferFailed();

        emit FeesWithdrawn(account_, value);
    }

    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        require(userAddress != address(0));

        if (token == address(0)) {
            (bool success, ) = userAddress.call{value: address(this).balance}(
                ""
            );
            require(success);
        } else {
            // do we need safe transfer?
            IERC20(token).transfer(userAddress, amount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../../interfaces/native-bridge/IInbox.sol";
import "../../interfaces/native-bridge/IOutbox.sol";
import "../../interfaces/native-bridge/IBridge.sol";
import "../../interfaces/native-bridge/INativeReceiver.sol";

import "./NativeSwitchboardBase.sol";

contract ArbitrumL1Switchboard is NativeSwitchboardBase, INativeReceiver {
    address public remoteRefundAddress;
    address public callValueRefundAddress;
    address public remoteNativeSwitchboard;
    uint256 public dynamicFees;

    IInbox public inbox;

    // stores the roots received from native bridge
    mapping(uint256 => bytes32) public roots;

    event UpdatedInboxAddress(address inbox_);
    event UpdatedRefundAddresses(
        address remoteRefundAddress_,
        address callValueRefundAddress_
    );
    event UpdatedRemoteNativeSwitchboard(address remoteNativeSwitchboard_);
    event RootReceived(uint256 packetId_, bytes32 root_);
    event UpdatedDynamicFees(uint256 dynamicFees_);

    error InvalidSender();
    error NoRootFound();

    modifier onlyRemoteSwitchboard() {
        IBridge bridge = inbox.bridge();
        if (msg.sender != address(bridge)) revert InvalidSender();

        IOutbox outbox = IOutbox(bridge.activeOutbox());
        address l2Sender = outbox.l2ToL1Sender();
        if (l2Sender != remoteNativeSwitchboard) revert InvalidSender();

        _;
    }

    constructor(
        uint256 dynamicFees_,
        uint256 initialConfirmationGasLimit_,
        uint256 executionOverhead_,
        address remoteNativeSwitchboard_,
        address inbox_,
        address owner_,
        ISocket socket_,
        IOracle oracle_
    ) AccessControl(owner_) {
        dynamicFees = dynamicFees_;
        initateNativeConfirmationGasLimit = initialConfirmationGasLimit_;
        executionOverhead = executionOverhead_;

        inbox = IInbox(inbox_);
        remoteNativeSwitchboard = remoteNativeSwitchboard_;
        socket = socket_;
        oracle = oracle_;

        remoteRefundAddress = msg.sender;
        callValueRefundAddress = msg.sender;
    }

    function initateNativeConfirmation(
        uint256 packetId,
        uint256 maxSubmissionCost,
        uint256 maxGas,
        uint256 gasPriceBid
    ) external payable {
        bytes32 root = socket.remoteRoots(packetId);
        if (root == bytes32(0)) revert NoRootFound();

        bytes memory data = abi.encodeWithSelector(
            INativeReceiver.receivePacket.selector,
            packetId,
            root
        );

        // to avoid stack too deep
        address callValueRefund = callValueRefundAddress;
        address remoteRefund = remoteRefundAddress;

        inbox.createRetryableTicket{value: msg.value}(
            remoteNativeSwitchboard,
            0, // no value needed for receivePacket
            maxSubmissionCost,
            remoteRefund,
            callValueRefund,
            maxGas,
            gasPriceBid,
            data
        );

        emit InitiatedNativeConfirmation(packetId);
    }

    function receivePacket(
        uint256 packetId_,
        bytes32 root_
    ) external override onlyRemoteSwitchboard {
        roots[packetId_] = root_;
        emit RootReceived(packetId_, root_);
    }

    /**
     * @notice verifies if the packet satisfies needed checks before execution
     * @param packetId packet id
     */
    function allowPacket(
        bytes32 root,
        uint256 packetId,
        uint256,
        uint256
    ) external view override returns (bool) {
        if (tripGlobalFuse) return false;
        if (roots[packetId] != root) return false;

        return true;
    }

    function _getSwitchboardFees(
        uint256,
        uint256
    ) internal view override returns (uint256) {
        // todo: check if dynamic fees can be divided into more constants
        // arbitrum: check src contract
        return initateNativeConfirmationGasLimit * tx.gasprice + dynamicFees;
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

    function updateDynamicFees(uint256 dynamicFees_) external onlyOwner {
        dynamicFees = dynamicFees_;
        emit UpdatedDynamicFees(dynamicFees_);
    }

    function updateInboxAddresses(address inbox_) external onlyOwner {
        inbox = IInbox(inbox_);
        emit UpdatedInboxAddress(inbox_);
    }

    function updateRemoteNativeSwitchboard(
        address remoteNativeSwitchboard_
    ) external onlyOwner {
        remoteNativeSwitchboard = remoteNativeSwitchboard_;
        emit UpdatedRemoteNativeSwitchboard(remoteNativeSwitchboard_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../../interfaces/native-bridge/IArbSys.sol";
import "../../interfaces/native-bridge/INativeReceiver.sol";

import "../../libraries/AddressAliasHelper.sol";
import "./NativeSwitchboardBase.sol";

contract ArbitrumL2Switchboard is NativeSwitchboardBase, INativeReceiver {
    address public remoteNativeSwitchboard;
    uint256 public l1ReceiveGasLimit;

    IArbSys constant arbsys = IArbSys(address(100));

    // stores the roots received from native bridge
    mapping(uint256 => bytes32) public roots;

    event UpdatedRemoteNativeSwitchboard(address remoteNativeSwitchboard_);
    event RootReceived(uint256 packetId_, bytes32 root_);
    event UpdatedL1ReceiveGasLimit(uint256 l1ReceiveGasLimit_);

    error InvalidSender();
    error NoRootFound();

    modifier onlyRemoteSwitchboard() {
        if (
            msg.sender !=
            AddressAliasHelper.applyL1ToL2Alias(remoteNativeSwitchboard)
        ) revert InvalidSender();
        _;
    }

    constructor(
        uint256 l1ReceiveGasLimit_,
        uint256 initialConfirmationGasLimit_,
        uint256 executionOverhead_,
        address remoteNativeSwitchboard_,
        address owner_,
        ISocket socket_,
        IOracle oracle_
    ) AccessControl(owner_) {
        l1ReceiveGasLimit = l1ReceiveGasLimit_;
        initateNativeConfirmationGasLimit = initialConfirmationGasLimit_;
        executionOverhead = executionOverhead_;

        remoteNativeSwitchboard = remoteNativeSwitchboard_;
        socket = socket_;
        oracle = oracle_;
    }

    function initateNativeConfirmation(uint256 packetId) external {
        bytes32 root = socket.remoteRoots(packetId);
        if (root == bytes32(0)) revert NoRootFound();

        bytes memory data = abi.encodeWithSelector(
            INativeReceiver.receivePacket.selector,
            packetId,
            root
        );

        arbsys.sendTxToL1(remoteNativeSwitchboard, data);
        emit InitiatedNativeConfirmation(packetId);
    }

    function receivePacket(
        uint256 packetId_,
        bytes32 root_
    ) external override onlyRemoteSwitchboard {
        roots[packetId_] = root_;
        emit RootReceived(packetId_, root_);
    }

    /**
     * @notice verifies if the packet satisfies needed checks before execution
     * @param packetId packet id
     */
    function allowPacket(
        bytes32 root,
        uint256 packetId,
        uint256,
        uint256
    ) external view override returns (bool) {
        if (tripGlobalFuse) return false;
        if (roots[packetId] != root) return false;

        return true;
    }

    function _getSwitchboardFees(
        uint256,
        uint256 dstRelativeGasPrice
    ) internal view override returns (uint256) {
        return
            initateNativeConfirmationGasLimit *
            tx.gasprice +
            l1ReceiveGasLimit *
            dstRelativeGasPrice;
    }

    function updateL2ReceiveGasLimit(
        uint256 l1ReceiveGasLimit_
    ) external onlyOwner {
        l1ReceiveGasLimit = l1ReceiveGasLimit_;
        emit UpdatedL1ReceiveGasLimit(l1ReceiveGasLimit_);
    }

    function updateRemoteNativeSwitchboard(
        address remoteNativeSwitchboard_
    ) external onlyOwner {
        remoteNativeSwitchboard = remoteNativeSwitchboard_;
        emit UpdatedRemoteNativeSwitchboard(remoteNativeSwitchboard_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../../interfaces/ISwitchboard.sol";
import "../../interfaces/IOracle.sol";
import "../../utils/AccessControl.sol";
import "../../interfaces/ISocket.sol";
import "../../libraries/SafeTransferLib.sol";

abstract contract NativeSwitchboardBase is ISwitchboard, AccessControl {
    IOracle public oracle;
    ISocket public socket;

    bool public tripGlobalFuse;
    uint256 public executionOverhead;
    uint256 public initateNativeConfirmationGasLimit;

    event SwitchboardTripped(bool tripGlobalFuse_);
    event ExecutionOverheadSet(uint256 executionOverhead_);
    event InitialConfirmationGasLimitSet(uint256 gasLimit_);
    event OracleSet(address oracle_);
    event SocketSet(address socket);
    event InitiatedNativeConfirmation(uint256 packetId);
    event FeesWithdrawn(address account_, uint256 value_);

    error TransferFailed();
    error FeesNotEnough();

    // assumption: natives have 18 decimals
    function payFees(uint256 dstChainSlug) external payable override {
        (uint256 expectedFees, ) = _calculateFees(dstChainSlug);
        if (msg.value < expectedFees) revert FeesNotEnough();
    }

    function getMinFees(
        uint256 dstChainSlug
    )
        external
        view
        override
        returns (uint256 switchboardFee, uint256 verificationFee)
    {
        return _calculateFees(dstChainSlug);
    }

    function _calculateFees(
        uint256 dstChainSlug
    ) internal view returns (uint256 switchboardFee, uint256 verificationFee) {
        uint256 dstRelativeGasPrice = oracle.relativeGasPrice(dstChainSlug);

        switchboardFee = _getSwitchboardFees(dstChainSlug, dstRelativeGasPrice);

        verificationFee = executionOverhead * dstRelativeGasPrice;
    }

    function _getSwitchboardFees(
        uint256 dstChainSlug,
        uint256 dstRelativeGasPrice
    ) internal view virtual returns (uint256) {}

    /**
     * @notice updates execution overhead
     * @param executionOverhead_ new execution overhead cost
     */
    function setExecutionOverhead(
        uint256 executionOverhead_
    ) external onlyOwner {
        executionOverhead = executionOverhead_;
        emit ExecutionOverheadSet(executionOverhead_);
    }

    /**
     * @notice updates initateNativeConfirmationGasLimit
     * @param gasLimit_ new gas limit for initiateNativeConfirmation
     */
    function setInitialConfirmationGasLimit(
        uint256 gasLimit_
    ) external onlyOwner {
        initateNativeConfirmationGasLimit = gasLimit_;
        emit InitialConfirmationGasLimitSet(gasLimit_);
    }

    /**
     * @notice updates oracle address
     * @param oracle_ new oracle
     */
    function setOracle(address oracle_) external onlyOwner {
        oracle = IOracle(oracle_);
        emit OracleSet(oracle_);
    }

    function setSocket(address socket_) external onlyOwner {
        socket = ISocket(socket_);
        emit SocketSet(socket_);
    }

    // TODO: to support fee distribution
    /**
     * @notice transfers the fees collected to `account_`
     * @param account_ address to transfer ETH
     */
    function withdrawFees(address account_) external onlyOwner {
        require(account_ != address(0));

        uint256 value = address(this).balance;
        (bool success, ) = account_.call{value: value}("");
        if (!success) revert TransferFailed();

        emit FeesWithdrawn(account_, value);
    }

    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        require(userAddress != address(0));

        if (token == address(0)) {
            (bool success, ) = userAddress.call{value: address(this).balance}(
                ""
            );
            require(success);
        } else {
            // do we need safe transfer?
            IERC20(token).transfer(userAddress, amount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../../interfaces/native-bridge/ICrossDomainMessenger.sol";
import "../../interfaces/native-bridge/INativeReceiver.sol";

import "./NativeSwitchboardBase.sol";

contract OptimismSwitchboard is NativeSwitchboardBase, INativeReceiver {
    uint256 public receivePacketGasLimit;
    uint256 public l2ReceiveGasLimit;

    address public remoteNativeSwitchboard;
    // stores the roots received from native bridge
    mapping(uint256 => bytes32) public roots;

    ICrossDomainMessenger public crossDomainMessenger;

    event UpdatedRemoteNativeSwitchboard(address remoteNativeSwitchboard_);
    event UpdatedReceivePacketGasLimit(uint256 receivePacketGasLimit_);
    event RootReceived(uint256 packetId_, bytes32 root_);
    event UpdatedL2ReceiveGasLimit(uint256 l2ReceiveGasLimit_);

    error InvalidSender();
    error NoRootFound();

    modifier onlyRemoteSwitchboard() {
        if (
            msg.sender != address(crossDomainMessenger) &&
            crossDomainMessenger.xDomainMessageSender() !=
            remoteNativeSwitchboard
        ) revert InvalidSender();
        _;
    }

    constructor(
        uint256 receivePacketGasLimit_,
        uint256 l2ReceiveGasLimit_,
        uint256 initialConfirmationGasLimit_,
        uint256 executionOverhead_,
        address remoteNativeSwitchboard_,
        address owner_,
        ISocket socket_,
        IOracle oracle_
    ) AccessControl(owner_) {
        receivePacketGasLimit = receivePacketGasLimit_;

        l2ReceiveGasLimit = l2ReceiveGasLimit_;
        initateNativeConfirmationGasLimit = initialConfirmationGasLimit_;
        executionOverhead = executionOverhead_;

        remoteNativeSwitchboard = remoteNativeSwitchboard_;
        socket = socket_;
        oracle = oracle_;

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

    function initateNativeConfirmation(uint256 packetId) external {
        bytes32 root = socket.remoteRoots(packetId);
        if (root == bytes32(0)) revert NoRootFound();

        bytes memory data = abi.encodeWithSelector(
            INativeReceiver.receivePacket.selector,
            packetId,
            root
        );

        crossDomainMessenger.sendMessage(
            remoteNativeSwitchboard,
            data,
            uint32(receivePacketGasLimit)
        );
        emit InitiatedNativeConfirmation(packetId);
    }

    function receivePacket(
        uint256 packetId_,
        bytes32 root_
    ) external override onlyRemoteSwitchboard {
        roots[packetId_] = root_;
        emit RootReceived(packetId_, root_);
    }

    /**
     * @notice verifies if the packet satisfies needed checks before execution
     * @param packetId packet id
     */
    function allowPacket(
        bytes32 root,
        uint256 packetId,
        uint256,
        uint256
    ) external view override returns (bool) {
        if (tripGlobalFuse) return false;
        if (roots[packetId] != root) return false;

        return true;
    }

    function _getSwitchboardFees(
        uint256,
        uint256 dstRelativeGasPrice
    ) internal view override returns (uint256) {
        // l2ReceiveGasLimit will be 0 when switchboard is deployed on L1
        return
            initateNativeConfirmationGasLimit *
            tx.gasprice +
            l2ReceiveGasLimit *
            dstRelativeGasPrice;
    }

    function updateL2ReceiveGasLimit(
        uint256 l2ReceiveGasLimit_
    ) external onlyOwner {
        l2ReceiveGasLimit = l2ReceiveGasLimit_;
        emit UpdatedL2ReceiveGasLimit(l2ReceiveGasLimit_);
    }

    function updateRemoteNativeSwitchboard(
        address remoteNativeSwitchboard_
    ) external onlyOwner {
        remoteNativeSwitchboard = remoteNativeSwitchboard_;
        emit UpdatedRemoteNativeSwitchboard(remoteNativeSwitchboard_);
    }

    function updateReceivePacketGasLimit(
        uint256 receivePacketGasLimit_
    ) external onlyOwner {
        receivePacketGasLimit = receivePacketGasLimit_;
        emit UpdatedReceivePacketGasLimit(receivePacketGasLimit_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "lib/contracts/contracts/tunnel/FxBaseRootTunnel.sol";
import "./NativeSwitchboardBase.sol";

contract PolygonL1Switchboard is NativeSwitchboardBase, FxBaseRootTunnel {
    // stores the roots received from native bridge
    mapping(uint256 => bytes32) public roots;

    event FxChildTunnelSet(address fxRootTunnel, address fxRootTunnel_);
    event RootReceived(uint256 packetId_, bytes32 root_);

    error NoRootFound();

    constructor(
        uint256 initialConfirmationGasLimit_,
        uint256 executionOverhead_,
        address checkpointManager_,
        address fxRoot_,
        address owner_,
        ISocket socket_,
        IOracle oracle_
    ) AccessControl(owner_) FxBaseRootTunnel(checkpointManager_, fxRoot_) {
        socket = socket_;
        oracle = oracle_;

        initateNativeConfirmationGasLimit = initialConfirmationGasLimit_;
        executionOverhead = executionOverhead_;
    }

    /**
     * @param packetId - packet id
     */
    function initateNativeConfirmation(uint256 packetId) external payable {
        bytes32 root = socket.remoteRoots(packetId);
        if (root == bytes32(0)) revert NoRootFound();

        bytes memory data = abi.encode(packetId, root);
        _sendMessageToChild(data);
        emit InitiatedNativeConfirmation(packetId);
    }

    function _processMessageFromChild(bytes memory message) internal override {
        (uint256 packetId, bytes32 root) = abi.decode(
            message,
            (uint256, bytes32)
        );
        roots[packetId] = root;
        emit RootReceived(packetId, root);
    }

    /**
     * @notice verifies if the packet satisfies needed checks before execution
     * @param packetId packet id
     */
    function allowPacket(
        bytes32 root,
        uint256 packetId,
        uint256,
        uint256
    ) external view override returns (bool) {
        if (tripGlobalFuse) return false;
        if (roots[packetId] != root) return false;

        return true;
    }

    function _getSwitchboardFees(
        uint256,
        uint256
    ) internal view override returns (uint256) {
        return initateNativeConfirmationGasLimit * tx.gasprice;
    }

    // set fxChildTunnel if not set already
    function updateFxChildTunnel(address fxChildTunnel_) external onlyOwner {
        emit FxChildTunnelSet(fxChildTunnel, fxChildTunnel_);
        fxChildTunnel = fxChildTunnel_;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "lib/contracts/contracts/tunnel/FxBaseChildTunnel.sol";
import "./NativeSwitchboardBase.sol";

contract PolygonL2Switchboard is NativeSwitchboardBase, FxBaseChildTunnel {
    // stores the roots received from native bridge
    mapping(uint256 => bytes32) public roots;
    uint256 public l1ReceiveGasLimit;

    event FxChildUpdate(address oldFxChild, address newFxChild);
    event FxRootTunnelSet(address fxRootTunnel, address fxRootTunnel_);
    event RootReceived(uint256 packetId_, bytes32 root_);
    event UpdatedL1ReceiveGasLimit(uint256 l1ReceiveGasLimit_);

    error NoRootFound();

    constructor(
        uint256 l1ReceiveGasLimit_,
        uint256 initialConfirmationGasLimit_,
        uint256 executionOverhead_,
        address fxChild_,
        address owner_,
        ISocket socket_,
        IOracle oracle_
    ) AccessControl(owner_) FxBaseChildTunnel(fxChild_) {
        socket = socket_;
        oracle = oracle_;

        l1ReceiveGasLimit = l1ReceiveGasLimit_;
        initateNativeConfirmationGasLimit = initialConfirmationGasLimit_;
        executionOverhead = executionOverhead_;
    }

    /**
     * @param packetId - packet id
     */
    function initateNativeConfirmation(uint256 packetId) external payable {
        bytes32 root = socket.remoteRoots(packetId);
        if (root == bytes32(0)) revert NoRootFound();

        bytes memory data = abi.encode(packetId, root);
        _sendMessageToRoot(data);
        emit InitiatedNativeConfirmation(packetId);
    }

    /**
     * validate sender verifies if `rootMessageSender` is the root contract (notary) on L1.
     */
    function _processMessageFromRoot(
        uint256,
        address rootMessageSender,
        bytes memory data
    ) internal override validateSender(rootMessageSender) {
        (uint256 packetId, bytes32 root) = abi.decode(data, (uint256, bytes32));
        roots[packetId] = root;
        emit RootReceived(packetId, root);
    }

    /**
     * @notice verifies if the packet satisfies needed checks before execution
     * @param packetId packet id
     */
    function allowPacket(
        bytes32 root,
        uint256 packetId,
        uint256,
        uint256
    ) external view override returns (bool) {
        if (tripGlobalFuse) return false;
        return roots[packetId] == root;
    }

    function _getSwitchboardFees(
        uint256,
        uint256 dstRelativeGasPrice
    ) internal view override returns (uint256) {
        return
            initateNativeConfirmationGasLimit *
            tx.gasprice +
            l1ReceiveGasLimit *
            dstRelativeGasPrice;
    }

    function updateL1ReceiveGasLimit(
        uint256 l1ReceiveGasLimit_
    ) external onlyOwner {
        l1ReceiveGasLimit = l1ReceiveGasLimit_;
        emit UpdatedL1ReceiveGasLimit(l1ReceiveGasLimit_);
    }

    /**
     * @notice Update the address of the FxChild
     * @param fxChild_ The address of the new FxChild
     **/
    function updateFxChild(address fxChild_) external onlyOwner {
        emit FxChildUpdate(fxChild, fxChild_);
        fxChild = fxChild_;
    }

    function updateFxRootTunnel(address fxRootTunnel_) external onlyOwner {
        emit FxRootTunnelSet(fxRootTunnel, fxRootTunnel_);
        fxRootTunnel = fxRootTunnel_;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./interfaces/ITransmitManager.sol";
import "./interfaces/ISignatureVerifier.sol";
import "./interfaces/IOracle.sol";

import "./utils/AccessControl.sol";
import "./libraries/SafeTransferLib.sol";

contract TransmitManager is ITransmitManager, AccessControl {
    using SafeTransferLib for IERC20;

    ISignatureVerifier public signatureVerifier;
    IOracle public oracle;

    uint256 public chainSlug;
    uint256 public sealGasLimit;
    mapping(uint256 => uint256) public proposeGasLimit;

    error TransferFailed();
    error InsufficientTransmitFees();

    event SealGasLimitSet(uint256 gasLimit_);
    event ProposeGasLimitSet(uint256 dstChainSlug_, uint256 gasLimit_);
    event FeesWithdrawn(address account_, uint256 value_);

    /**
     * @notice emits when a new signature verifier contract is set
     * @param signatureVerifier_ address of new verifier contract
     */
    event SignatureVerifierSet(address signatureVerifier_);

    constructor(
        ISignatureVerifier signatureVerifier_,
        IOracle oracle_,
        address owner_,
        uint256 chainSlug_,
        uint256 sealGasLimit_
    ) AccessControl(owner_) {
        chainSlug = chainSlug_;
        sealGasLimit = sealGasLimit_;
        signatureVerifier = signatureVerifier_;
        oracle = IOracle(oracle_);
    }

    function checkTransmitter(
        uint256 slugs_,
        uint256 packetId_,
        bytes32 root_,
        bytes calldata signature_
    ) external view override returns (address, bool) {
        address transmitter = signatureVerifier.recoverSigner(
            type(uint128).max & slugs_,
            packetId_,
            root_,
            signature_
        );

        return (
            transmitter,
            _hasRole(_transmitterRole(slugs_ >> 128), transmitter)
        );
    }

    // can be used for different checks related to oracle
    function isTransmitter(
        address transmitter_,
        uint256 siblingChainSlug_
    ) external view override returns (bool) {
        return _hasRole(_transmitterRole(siblingChainSlug_), transmitter_);
    }

    function payFees(uint256 siblingChainSlug_) external payable override {
        if (msg.value < _calculateFees(siblingChainSlug_))
            revert InsufficientTransmitFees();
    }

    function getMinFees(
        uint256 siblingChainSlug_
    ) external view override returns (uint256) {
        return _calculateFees(siblingChainSlug_);
    }

    function _calculateFees(
        uint256 siblingChainSlug_
    ) internal view returns (uint256 minTransmissionFees) {
        uint256 siblingRelativeGasPrice = oracle.relativeGasPrice(
            siblingChainSlug_
        );

        minTransmissionFees =
            sealGasLimit *
            tx.gasprice +
            proposeGasLimit[siblingChainSlug_] *
            siblingRelativeGasPrice;
    }

    // TODO: to support fee distribution
    /**
     * @notice transfers the fees collected to `account_`
     * @param account_ address to transfer ETH
     */
    function withdrawFees(address account_) external onlyOwner {
        require(account_ != address(0));

        uint256 value = address(this).balance;
        (bool success, ) = account_.call{value: value}("");
        if (!success) revert TransferFailed();

        emit FeesWithdrawn(account_, value);
    }

    /**
     * @notice updates seal gas limit
     * @param gasLimit_ new seal gas limit
     */
    function setSealGasLimit(uint256 gasLimit_) external onlyOwner {
        sealGasLimit = gasLimit_;
        emit SealGasLimitSet(gasLimit_);
    }

    /**
     * @notice updates propose gas limit for `dstChainSlug_`
     * @param gasLimit_ new propose gas limit
     */
    function setProposeGasLimit(
        uint256 dstChainSlug_,
        uint256 gasLimit_
    ) external onlyOwner {
        proposeGasLimit[dstChainSlug_] = gasLimit_;
        emit ProposeGasLimitSet(dstChainSlug_, gasLimit_);
    }

    /**
     * @notice updates signatureVerifier_
     * @param signatureVerifier_ address of Signature Verifier
     */
    function setSignatureVerifier(
        address signatureVerifier_
    ) external onlyOwner {
        signatureVerifier = ISignatureVerifier(signatureVerifier_);
        emit SignatureVerifierSet(signatureVerifier_);
    }

    /**
     * @notice adds a transmitter for `remoteChainSlug_` chain
     * @param remoteChainSlug_ remote chain slug
     * @param transmitter_ transmitter address
     */
    function grantTransmitterRole(
        uint256 remoteChainSlug_,
        address transmitter_
    ) external onlyOwner {
        _grantRole(_transmitterRole(remoteChainSlug_), transmitter_);
    }

    /**
     * @notice removes an transmitter from `remoteChainSlug_` chain list
     * @param remoteChainSlug_ remote chain slug
     * @param transmitter_ transmitter address
     */
    function revokeTransmitterRole(
        uint256 remoteChainSlug_,
        address transmitter_
    ) external onlyOwner {
        _revokeRole(_transmitterRole(remoteChainSlug_), transmitter_);
    }

    function _transmitterRole(
        uint256 chainSlug_
    ) internal pure returns (bytes32) {
        return bytes32(chainSlug_);
    }

    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        require(userAddress != address(0));

        if (token == address(0)) {
            (bool success, ) = userAddress.call{value: address(this).balance}(
                ""
            );
            require(success);
        } else {
            // do we need safe transfer?
            IERC20(token).transfer(userAddress, amount);
        }
    }
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

    function grantRole(
        bytes32 role,
        address grantee
    ) external virtual onlyOwner {
        _grantRole(role, grantee);
    }

    function revokeRole(
        bytes32 role,
        address revokee
    ) external virtual onlyOwner {
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

    function hasRole(
        bytes32 role,
        address _address
    ) external view returns (bool) {
        return _hasRole(role, _address);
    }

    function _hasRole(
        bytes32 role,
        address _address
    ) internal view returns (bool) {
        return _permits[role][_address];
    }
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
        uint256 executionFee,
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
                    executionFee,
                    payload
                )
            );
    }
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
    function _recoverSigner(
        bytes32 hash_,
        bytes memory signature_
    ) private pure returns (address signer) {
        (bytes32 sigR, bytes32 sigS, uint8 sigV) = _splitSignature(signature_);

        // recovered signer is checked for the valid roles later
        signer = ecrecover(hash_, sigV, sigR, sigS);
    }

    /**
     * @notice splits the signature into v, r and s.
     */
    function _splitSignature(
        bytes memory signature_
    ) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        if (signature_.length != 65) revert InvalidSigLength();
        assembly {
            r := mload(add(signature_, 0x20))
            s := mload(add(signature_, 0x40))
            v := byte(0, mload(add(signature_, 0x60)))
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}