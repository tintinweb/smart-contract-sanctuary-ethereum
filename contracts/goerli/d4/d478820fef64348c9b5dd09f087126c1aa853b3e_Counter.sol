/**
 *Submitted for verification at Etherscan.io on 2023-01-31
*/

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
     * @notice emits when a msg is retried with updated fees
     * @param msgId_ msg id to be retried
     * @param newMsgGasLimit_ new gas limit to execute a message
     * @param fees_ additional fees sent
     */
    event MessageRetried(
        uint256 msgId_,
        uint256 newMsgGasLimit_,
        uint256 fees_
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

    struct VerificationParams {
        uint256 remoteChainSlug;
        uint256 packetId;
        bytes decapacitorProof;
    }

    struct ExecutionParams {
        uint256 executionFee;
        uint256 msgGasLimit;
        bytes payload;
    }

    /**
     * @notice executes a message
     * @param msgId message id packed with remoteChainSlug and nonce
     * @param localPlug local plug address
     * @param verifyParams_ the details needed for message verification
     */
    function execute(
        uint256 msgId,
        address localPlug,
        ISocket.VerificationParams calldata verifyParams_,
        ISocket.ExecutionParams calldata executeParams_
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