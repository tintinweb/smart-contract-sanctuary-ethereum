// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (crosschain/arbitrum/LibArbitrumL1.sol)

pragma solidity ^0.8.4;

import {IBridge as ArbitrumL1_Bridge} from "../../vendor/arbitrum/IBridge.sol";
import {IOutbox as ArbitrumL1_Outbox} from "../../vendor/arbitrum/IOutbox.sol";
import "../errors.sol";

/**
 * @dev Primitives for cross-chain aware contracts for
 * https://arbitrum.io/[Arbitrum].
 *
 * This version should only be used on L1 to process cross-chain messages
 * originating from L2. For the other side, use {LibArbitrumL2}.
 */
library LibArbitrumL1 {
    /**
     * @dev Returns whether the current function call is the result of a
     * cross-chain message relayed by the `bridge`.
     */
    function isCrossChain(address bridge) internal view returns (bool) {
        return msg.sender == bridge;
    }

    /**
     * @dev Returns the address of the sender that triggered the current
     * cross-chain message through the `bridge`.
     *
     * NOTE: {isCrossChain} should be checked before trying to recover the
     * sender, as it will revert with `NotCrossChainCall` if the current
     * function call is not the result of a cross-chain message.
     */
    function crossChainSender(address bridge) internal view returns (address) {
        if (!isCrossChain(bridge)) revert NotCrossChainCall();

        address sender = ArbitrumL1_Outbox(ArbitrumL1_Bridge(bridge).activeOutbox()).l2ToL1Sender();
        require(sender != address(0), "LibArbitrumL1: system messages without sender");

        return sender;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (crosschain/errors.sol)

pragma solidity ^0.8.4;

error NotCrossChainCall();
error InvalidCrossChainSender(address actual, address expected);

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1
// OpenZeppelin Contracts (last updated v4.8.0) (vendor/arbitrum/IBridge.sol)

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface IBridge {
    event MessageDelivered(
        uint256 indexed messageIndex,
        bytes32 indexed beforeInboxAcc,
        address inbox,
        uint8 kind,
        address sender,
        bytes32 messageDataHash,
        uint256 baseFeeL1,
        uint64 timestamp
    );

    event BridgeCallTriggered(address indexed outbox, address indexed to, uint256 value, bytes data);

    event InboxToggle(address indexed inbox, bool enabled);

    event OutboxToggle(address indexed outbox, bool enabled);

    event SequencerInboxUpdated(address newSequencerInbox);

    function allowedDelayedInboxList(uint256) external returns (address);

    function allowedOutboxList(uint256) external returns (address);

    /// @dev Accumulator for delayed inbox messages; tail represents hash of the current state; each element represents the inclusion of a new message.
    function delayedInboxAccs(uint256) external view returns (bytes32);

    /// @dev Accumulator for sequencer inbox messages; tail represents hash of the current state; each element represents the inclusion of a new message.
    function sequencerInboxAccs(uint256) external view returns (bytes32);

    // OpenZeppelin: changed return type from IOwnable
    function rollup() external view returns (address);

    function sequencerInbox() external view returns (address);

    function activeOutbox() external view returns (address);

    function allowedDelayedInboxes(address inbox) external view returns (bool);

    function allowedOutboxes(address outbox) external view returns (bool);

    function sequencerReportedSubMessageCount() external view returns (uint256);

    /**
     * @dev Enqueue a message in the delayed inbox accumulator.
     *      These messages are later sequenced in the SequencerInbox, either
     *      by the sequencer as part of a normal batch, or by force inclusion.
     */
    function enqueueDelayedMessage(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) external payable returns (uint256);

    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success, bytes memory returnData);

    function delayedMessageCount() external view returns (uint256);

    function sequencerMessageCount() external view returns (uint256);

    // ---------- onlySequencerInbox functions ----------

    function enqueueSequencerMessage(
        bytes32 dataHash,
        uint256 afterDelayedMessagesRead,
        uint256 prevMessageCount,
        uint256 newMessageCount
    )
        external
        returns (
            uint256 seqMessageIndex,
            bytes32 beforeAcc,
            bytes32 delayedAcc,
            bytes32 acc
        );

    /**
     * @dev Allows the sequencer inbox to submit a delayed message of the batchPostingReport type
     *      This is done through a separate function entrypoint instead of allowing the sequencer inbox
     *      to call `enqueueDelayedMessage` to avoid the gas overhead of an extra SLOAD in either
     *      every delayed inbox or every sequencer inbox call.
     */
    function submitBatchSpendingReport(address batchPoster, bytes32 dataHash) external returns (uint256 msgNum);

    // ---------- onlyRollupOrOwner functions ----------

    function setSequencerInbox(address _sequencerInbox) external;

    function setDelayedInbox(address inbox, bool enabled) external;

    function setOutbox(address inbox, bool enabled) external;

    // ---------- initializer ----------

    // OpenZeppelin: changed rollup_ type from IOwnable
    function initialize(address rollup_) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1
// OpenZeppelin Contracts (last updated v4.8.0) (vendor/arbitrum/IOutbox.sol)

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "./IBridge.sol";

interface IOutbox {
    event SendRootUpdated(bytes32 indexed blockHash, bytes32 indexed outputRoot);
    event OutBoxTransactionExecuted(
        address indexed to,
        address indexed l2Sender,
        uint256 indexed zero,
        uint256 transactionIndex
    );

    function rollup() external view returns (address); // the rollup contract

    function bridge() external view returns (IBridge); // the bridge contract

    function spent(uint256) external view returns (bytes32); // packed spent bitmap

    function roots(bytes32) external view returns (bytes32); // maps root hashes => L2 block hash

    // solhint-disable-next-line func-name-mixedcase
    function OUTBOX_VERSION() external view returns (uint128); // the outbox version

    function updateSendRoot(bytes32 sendRoot, bytes32 l2BlockHash) external;

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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {ProposedOwnable} from "../../shared/ProposedOwnable.sol";
import {IConnector} from "../interfaces/IConnector.sol";

/**
 * @title Connector
 * @author Connext Labs, Inc.
 * @notice This contract has the messaging interface functions used by all connectors.
 *
 * @dev This contract stores information about mirror connectors, but can be used as a
 * base for contracts that do not have a mirror (i.e. the connector handling messaging on
 * mainnet). In this case, the `mirrorConnector` and `MIRROR_DOMAIN`
 * will be empty
 *
 * @dev If ownership is renounced, this contract will be unable to update its `mirrorConnector`
 * or `mirrorGas`
 */
abstract contract Connector is ProposedOwnable, IConnector {
  // ========== Custom Errors ===========

  error Connector__processMessage_notUsed();

  // ============ Events ============

  event NewConnector(
    uint32 indexed domain,
    uint32 indexed mirrorDomain,
    address amb,
    address rootManager,
    address mirrorConnector
  );

  event MirrorConnectorUpdated(address previous, address current);

  // ============ Public Storage ============

  /**
   * @notice The domain of this Messaging (i.e. Connector) contract.
   */
  uint32 public immutable DOMAIN;

  /**
   * @notice Address of the AMB on this domain.
   */
  address public immutable AMB;

  /**
   * @notice RootManager contract address.
   */
  address public immutable ROOT_MANAGER;

  /**
   * @notice The domain of the corresponding messaging (i.e. Connector) contract.
   */
  uint32 public immutable MIRROR_DOMAIN;

  /**
   * @notice Connector on L2 for L1 connectors, and vice versa.
   */
  address public mirrorConnector;

  // ============ Modifiers ============

  /**
   * @notice Errors if the msg.sender is not the registered AMB
   */
  modifier onlyAMB() {
    require(msg.sender == AMB, "!AMB");
    _;
  }

  /**
   * @notice Errors if the msg.sender is not the registered ROOT_MANAGER
   */
  modifier onlyRootManager() {
    // NOTE: RootManager will be zero address for spoke connectors.
    // Only root manager can dispatch a message to spokes/L2s via the hub connector.
    require(msg.sender == ROOT_MANAGER, "!rootManager");
    _;
  }

  // ============ Constructor ============

  /**
   * @notice Creates a new HubConnector instance
   * @dev The connectors are deployed such that there is one on each side of an AMB (i.e.
   * for optimism, there is one connector on optimism and one connector on mainnet)
   * @param _domain The domain this connector lives on
   * @param _mirrorDomain The spoke domain
   * @param _amb The address of the amb on the domain this connector lives on
   * @param _rootManager The address of the RootManager on mainnet
   * @param _mirrorConnector The address of the spoke connector
   */
  constructor(
    uint32 _domain,
    uint32 _mirrorDomain,
    address _amb,
    address _rootManager,
    address _mirrorConnector
  ) ProposedOwnable() {
    // set the owner
    _setOwner(msg.sender);

    // sanity checks on values
    require(_domain != 0, "empty domain");
    require(_rootManager != address(0), "empty rootManager");
    // see note at top of contract on why the mirror values are not sanity checked

    // set immutables
    DOMAIN = _domain;
    AMB = _amb;
    ROOT_MANAGER = _rootManager;
    MIRROR_DOMAIN = _mirrorDomain;
    // set mutables if defined
    if (_mirrorConnector != address(0)) {
      _setMirrorConnector(_mirrorConnector);
    }

    emit NewConnector(_domain, _mirrorDomain, _amb, _rootManager, _mirrorConnector);
  }

  // ============ Receivable ============
  /**
   * @notice Connectors may need to receive native asset to handle fees when sending a
   * message
   */
  receive() external payable {}

  // ============ Admin Functions ============

  /**
   * @notice Sets the address of the l2Connector for this domain
   */
  function setMirrorConnector(address _mirrorConnector) public onlyOwner {
    _setMirrorConnector(_mirrorConnector);
  }

  // ============ Public Functions ============

  /**
   * @notice Processes a message received by an AMB
   * @dev This is called by AMBs to process messages originating from mirror connector
   */
  function processMessage(bytes memory _data) external virtual onlyAMB {
    _processMessage(_data);
    emit MessageProcessed(_data, msg.sender);
  }

  /**
   * @notice Checks the cross domain sender for a given address
   */
  function verifySender(address _expected) external returns (bool) {
    return _verifySender(_expected);
  }

  // ============ Virtual Functions ============

  /**
   * @notice This function is used by the Connext contract on the l2 domain to send a message to the
   * l1 domain (i.e. called by Connext on optimism to send a message to mainnet with roots)
   * @param _data The contents of the message
   * @param _encodedData Data used to send the message; specific to connector
   */
  function _sendMessage(bytes memory _data, bytes memory _encodedData) internal virtual;

  /**
   * @notice This function is used by the AMBs to handle incoming messages. Should store the latest
   * root generated on the l2 domain.
   */
  function _processMessage(
    bytes memory /* _data */
  ) internal virtual {
    // By default, reverts. This is to ensure the call path is not used unless this function is
    // overridden by the inheriting class
    revert Connector__processMessage_notUsed();
  }

  /**
   * @notice Verify that the msg.sender is the correct AMB contract, and that the message's origin sender
   * is the expected address.
   * @dev Should be overridden by the implementing Connector contract.
   */
  function _verifySender(address _expected) internal virtual returns (bool);

  // ============ Private Functions ============

  function _setMirrorConnector(address _mirrorConnector) internal virtual {
    emit MirrorConnectorUpdated(mirrorConnector, _mirrorConnector);
    mirrorConnector = _mirrorConnector;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {Connector} from "./Connector.sol";

/**
 * @title HubConnector
 * @author Connext Labs, Inc.
 * @notice This contract implements the messaging functions needed on the hub-side of a given AMB.
 * The HubConnector has a limited set of functionality compared to the SpokeConnector, namely that
 * it contains no logic to store or prove messages.
 *
 * @dev This contract should be deployed on the hub-side of an AMB (i.e. on L1), and contracts
 * which extend this should implement the virtual functions defined in the BaseConnector class
 */
abstract contract HubConnector is Connector {
  /**
   * @notice Creates a new HubConnector instance
   * @dev The connectors are deployed such that there is one on each side of an AMB (i.e.
   * for optimism, there is one connector on optimism and one connector on mainnet)
   * @param _domain The domain this connector lives on
   * @param _mirrorDomain The spoke domain
   * @param _amb The address of the amb on the domain this connector lives on
   * @param _rootManager The address of the RootManager on mainnet
   * @param _mirrorConnector The address of the spoke connector
   */
  constructor(
    uint32 _domain,
    uint32 _mirrorDomain,
    address _amb,
    address _rootManager,
    address _mirrorConnector
  ) Connector(_domain, _mirrorDomain, _amb, _rootManager, _mirrorConnector) {}

  // ============ Public fns ============
  /**
   * @notice Sends a message over the amb
   * @dev This is called by the root manager *only* on mainnet to propagate the aggregate root
   */
  function sendMessage(bytes memory _data, bytes memory _encodedData) external payable onlyRootManager {
    _sendMessage(_data, _encodedData);
    emit MessageSent(_data, _encodedData, msg.sender);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {LibArbitrumL1} from "@openzeppelin/contracts/crosschain/arbitrum/LibArbitrumL1.sol";

import {TypedMemView} from "../../../shared/libraries/TypedMemView.sol";

import {IRootManager} from "../../interfaces/IRootManager.sol";
import {IArbitrumInbox} from "../../interfaces/ambs/arbitrum/IArbitrumInbox.sol";
import {IArbitrumOutbox} from "../../interfaces/ambs/arbitrum/IArbitrumOutbox.sol";
import {IArbitrumRollup, Node} from "../../interfaces/ambs/arbitrum/IArbitrumRollup.sol";

import {HubConnector} from "../HubConnector.sol";
import {Connector} from "../Connector.sol";

struct L2Message {
  address l2Sender;
  address to;
  uint256 l2Block;
  uint256 l1Block;
  uint256 l2Timestamp;
  uint256 value;
  bytes callData;
}

contract ArbitrumHubConnector is HubConnector {
  // ============ Libraries ============
  using TypedMemView for bytes;
  using TypedMemView for bytes29;

  // ============ Storage ============

  IArbitrumOutbox public outbox;
  IArbitrumRollup public rollup;

  /**
   * @notice Sets cap on maxSubmissionCost used in `createRetryableTicket`
   * @dev The value used in `createRetryableTicket` is the lesser of the cap or
   * a value passed in via `_encodedData` in `_sendMessage`.
   *
   * This value represents amount of ETH allocated to pay for the base submission fee
   */
  uint256 public maxSubmissionCostCap;

  /**
   * @notice Sets cap on maxGas used in `createRetryableTicket`
   * @dev The value used in `createRetryableTicket` is the lesser of the cap or
   * a value passed in via `_encodedData` in `_sendMessage`.
   *
   * This value represents gas limit for immediate L2 execution attempt
   */
  uint256 public maxGasCap;

  /**
   * @notice Sets cap on gasPrice used in `createRetryableTicket`
   * @dev The value used in `createRetryableTicket` is the lesser of the cap or
   * a value passed in via `_encodedData` in `_sendMessage`.
   *
   * This value represents L2 gas price bid for immediate L2 execution attempt
   */
  uint256 public gasPriceCap;

  /**
   * @notice Tracks which messages have been processed from bridge
   */
  mapping(uint256 => bool) public processed;

  // ============ Events ============
  // TODO: do we need any other information from the ticket to link to message?
  event RetryableTicketCreated(uint256 indexed ticketId);

  /**
   * @notice Emitted when admin updates the maxSubmissionCap
   * @param _previous The starting value
   * @param _updated The final value
   */
  event MaxSubmissionCapUpdated(uint256 _previous, uint256 _updated);

  /**
   * @notice Emitted when admin updates the maxGasCap
   * @param _previous The starting value
   * @param _updated The final value
   */
  event MaxGasCapUpdated(uint256 _previous, uint256 _updated);

  /**
   * @notice Emitted when admin updates the gasPriceCap
   * @param _previous The starting value
   * @param _updated The final value
   */
  event GasPriceCapUpdated(uint256 _previous, uint256 _updated);

  // ============ Constructor ============
  constructor(
    uint32 _domain,
    uint32 _mirrorDomain,
    address _amb,
    address _rootManager,
    address _mirrorConnector,
    address _outbox,
    uint256 _maxSubmissionCostCap,
    uint256 _maxGasCap,
    uint256 _gasPriceCap
  ) HubConnector(_domain, _mirrorDomain, _amb, _rootManager, _mirrorConnector) {
    outbox = IArbitrumOutbox(_outbox);
    rollup = IArbitrumRollup(outbox.rollup());

    // Set initial caps for L1 -> L2 messages
    maxSubmissionCostCap = _maxSubmissionCostCap;
    maxGasCap = _maxGasCap;
    gasPriceCap = _gasPriceCap;
  }

  // ============ Admin fns ============

  /**
   * @notice Used (by admin) to update the maxSubmissionCostCap
   * @param _updated The new value
   */
  function setMaxSubmissionCostCap(uint256 _updated) public onlyOwner {
    emit MaxSubmissionCapUpdated(maxSubmissionCostCap, _updated);
    maxSubmissionCostCap = _updated;
  }

  /**
   * @notice Used (by admin) to update the maxGasCap
   * @param _updated The new value
   */
  function setMaxGasCap(uint256 _updated) public onlyOwner {
    emit MaxGasCapUpdated(maxGasCap, _updated);
    maxGasCap = _updated;
  }

  /**
   * @notice Used (by admin) to update the gasPriceCap
   * @param _updated The new value
   */
  function setGasPriceCap(uint256 _updated) public onlyOwner {
    emit GasPriceCapUpdated(maxSubmissionCostCap, _updated);
    gasPriceCap = _updated;
  }

  // ============ Private fns ============

  function _verifySender(address _expected) internal view override returns (bool) {
    return _expected == LibArbitrumL1.crossChainSender(AMB);
  }

  /**
   * @notice Helper to return the lesser of two values
   * @param _a Some number
   * @param _b Some number
   */
  function _lesserOf(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a < _b ? _a : _b;
  }

  function _sendMessage(bytes memory _data, bytes memory _encodedData) internal override {
    // Should always be dispatching the aggregate root
    require(_data.length == 32, "!length");
    // Get the calldata
    bytes memory _calldata = abi.encodeWithSelector(Connector.processMessage.selector, _data);

    // Should include specialized calldata
    require(_encodedData.length == (32 * 3), "!data length");

    // Decode all of the gas-related parameters
    (uint256 maxSubmissionCost, uint256 maxGas, uint256 gasPrice) = abi.decode(
      _encodedData,
      (uint256, uint256, uint256)
    );

    // dispatch to l2
    uint256 ticketID = IArbitrumInbox(AMB).createRetryableTicket{value: msg.value}(
      mirrorConnector, // destAddr
      0, // arbTxCallValue
      _lesserOf(maxSubmissionCost, maxSubmissionCostCap), // maxSubmissionCost: Amount of ETH allocated to pay for the base submission fee
      mirrorConnector, // submissionRefundAddress: Address to which all excess gas is credited on L2
      mirrorConnector, // valueRefundAddress: Address to which CallValue will be credited to on L2 if the retryable ticket times out or is cancelled
      _lesserOf(maxGas, maxGasCap), // maxGas: Gas limit for immediate L2 execution attempt
      _lesserOf(gasPrice, gasPriceCap), // gasPriceBid: L2 Gas price bid for immediate L2 execution attempt
      _calldata // data
    );
    emit RetryableTicketCreated(ticketID);
  }

  // DO NOT override _processMessage, should revert from `Connector` class. All messages must use the
  // `processMessageFromRoot` flow.

  function processMessageFromRoot(
    uint64 _nodeNum,
    bytes32 _sendRoot,
    bytes32 _blockHash,
    bytes32[] calldata _proof,
    uint256 _index,
    L2Message calldata _message
  ) external {
    // Ensure the send root corresponds to an arbitrum node that exists onchain
    _validateSendRoot(_nodeNum, _sendRoot, _blockHash);

    // Ensure the given l2 message is included in the send root
    _validateMessage(_sendRoot, _proof, _index, _message);

    // Message has been proven within the send root, process the message
    // data itself. The message data is defined in the spoke connector as:
    //
    // `abi.encodeWithSelector(Connector.processMessage.selector, _data);`
    //
    // so to get the root data, we need to decode the _calldata. we can do this
    // by dropping the 4-byte selector, then using the rest as the raw _data.
    require(_message.callData.length == 100, "!length");

    // NOTE: TypedMemView only loads 32-byte chunks onto stack, which is fine in this case
    // the calldata is 100 bytes long, the last 32 bytes represent the root to be aggregated.
    bytes32 _data = _message.callData.ref(0).index(68, 32);

    // Update root manager
    IRootManager(ROOT_MANAGER).aggregate(MIRROR_DOMAIN, _data);

    // Emit event
    emit MessageProcessed(abi.encode(_data), msg.sender);
  }

  function _validateSendRoot(
    uint64 _nodeNum,
    bytes32 _sendRoot,
    bytes32 _blockHash
  ) internal view {
    // Get the confirm data to ensure the node has been put on L1 with
    // the given block hash and send root
    bytes32 confirmData = _confirmHash(_blockHash, _sendRoot);

    // Validate inputs by checking against the stored none confirm data
    Node memory node = rollup.getNode(_nodeNum);
    require(node.confirmData == confirmData, "!confirmData");

    // Validate the node is staked / not in dispute
    // NOTE: a dispute can happen at any point within the timeout window, so the closest
    // we can get is to ensure the staker count > 0 and that there have been stakes on child
    // nodes as well, meaning the node is less likely to be staked incorrectly (and thus less
    // likely to be disputed)
    require(node.stakerCount > 0 && node.childStakerCount > 0, "!staked");
  }

  // prove the message was included in the given send root
  function _validateMessage(
    bytes32 _sendRoot,
    bytes32[] calldata _proof,
    uint256 _index,
    L2Message calldata _msg
  ) internal {
    // Check that the l2sender is the mirror connector
    require(_msg.l2Sender == mirrorConnector, "!mirrorConnector");

    // Generate the message sent through from L2 (included in sendRoot)
    bytes32 userTx = outbox.calculateItemHash(
      _msg.l2Sender,
      _msg.to,
      _msg.l2Block,
      _msg.l1Block,
      _msg.l2Timestamp,
      _msg.value,
      _msg.callData
    );

    // Prove message is included in the send root
    _recordOutputAsSpent(_proof, _index, userTx, _sendRoot);
  }

  // taken from: https://github.com/OffchainLabs/nitro/blob/208d9d50f250e9b4948f867d3795548256583b17/contracts/src/rollup/RollupLib.sol#L128-L130
  function _confirmHash(bytes32 _blockHash, bytes32 _sendRoot) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_blockHash, _sendRoot));
  }

  // modified from: https://github.com/OffchainLabs/nitro/blob/fbaa96d6d6246b427629be176499e1d5c5013d89/contracts/src/bridge/Outbox.sol#L219-L235
  function _recordOutputAsSpent(
    bytes32[] memory _proof,
    uint256 _index,
    bytes32 _item,
    bytes32 _sendRoot
  ) internal {
    require(_proof.length < 256, "proof length");
    require((_index >> _proof.length) == 0, "!minimal proof");

    // NOTE: in the arbitrum contracts, they check that the message index is not yet spent
    // Because the spoke connector calls `processMessage`, which does nothing, it is important
    // to check out own internal mapping to ensure the message is not played twice. this forces
    // all messages from l2 to be processed using the `processMessageFromRoot` fn path.
    require(!processed[_index], "spent");

    // Calculate the root
    bytes32 calcRoot = outbox.calculateMerkleRoot(_proof, _index, _item);

    // Assert the sendRoot is correct
    // NOTE: this send root will *not* yet be stored on the `Outbox`
    // contract (fraud period has not yet elapsed);
    require(calcRoot == _sendRoot, "!proof");

    // Mark as spent
    processed[_index] = true;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {IProposedOwnable} from "../../shared/interfaces/IProposedOwnable.sol";

/**
 * @notice This interface is what the Connext contract will send and receive messages through.
 * The messaging layer should conform to this interface, and should be interchangeable (i.e.
 * could be Nomad or a generic AMB under the hood).
 *
 * @dev This uses the nomad format to ensure nomad can be added in as it comes back online.
 *
 * Flow from transfer from polygon to optimism:
 * 1. User calls `xcall` with destination specified
 * 2. This will swap in to the bridge assets
 * 3. The swapped assets will get burned
 * 4. The Connext contract will call `dispatch` on the messaging contract to add the transfer
 *    to the root
 * 5. [At some time interval] Relayers call `send` to send the current root from polygon to
 *    mainnet. This is done on all "spoke" domains.
 * 6. [At some time interval] Relayers call `propagate` [better name] on mainnet, this generates a new merkle
 *    root from all of the AMBs
 *    - This function must be able to read root data from all AMBs and aggregate them into a single merkle
 *      tree root
 *    - Will send the mixed root from all chains back through the respective AMBs to all other chains
 * 7. AMB will call `update` to update the latest root on the messaging contract on spoke domains
 * 8. [At any point] Relayers can call `proveAndProcess` to prove inclusion of dispatched message, and call
 *    process on the `Connext` contract
 * 9. Takes minted bridge tokens and credits the LP
 *
 * AMB requirements:
 * - Access `msg.sender` both from mainnet -> spoke and vice versa
 * - Ability to read *our root* from the AMB
 *
 * AMBs:
 * - PoS bridge from polygon
 * - arbitrum bridge
 * - optimism bridge
 * - gnosis chain
 * - bsc (use multichain for messaging)
 */
interface IConnector is IProposedOwnable {
  // ============ Events ============
  /**
   * @notice Emitted whenever a message is successfully sent over an AMB
   * @param data The contents of the message
   * @param encodedData Data used to send the message; specific to connector
   * @param caller Who called the function (sent the message)
   */
  event MessageSent(bytes data, bytes encodedData, address caller);

  /**
   * @notice Emitted whenever a message is successfully received over an AMB
   * @param data The contents of the message
   * @param caller Who called the function
   */
  event MessageProcessed(bytes data, address caller);

  // ============ Public fns ============

  function processMessage(bytes memory _data) external;

  function verifySender(address _expected) external returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

interface IRootManager {
  /**
   * @notice This is called by relayers to generate + send the mixed root from mainnet via AMB to
   * spoke domains.
   * @dev This must read information for the root from the registered AMBs.
   */
  function propagate(
    address[] calldata _connectors,
    uint256[] calldata _fees,
    bytes[] memory _encodedData
  ) external payable;

  /**
   * @notice Called by the connectors for various domains on the hub to aggregate their latest
   * inbound root.
   * @dev This must read information for the root from the registered AMBs
   */
  function aggregate(uint32 _domain, bytes32 _outbound) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

/**
 * @notice Interface for sending L1 -> L2 messagesto Arbitrum.
 * @dev Arbitrum uses an inbox to aggregate messages going from L1 -> L2, source:
 * https://github.com/OffchainLabs/nitro/blob/master/contracts/src/bridge/Inbox.sol
 *
 */
interface IArbitrumInbox {
  function createRetryableTicket(
    address destAddr,
    uint256 arbTxCallValue,
    uint256 maxSubmissionCost,
    address submissionRefundAddress,
    address valueRefundAddress,
    uint256 maxGas,
    uint256 gasPriceBid,
    bytes calldata data
  ) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

/**
 * @notice Interface for sending L1 -> L2 messagesto Arbitrum.
 * @dev Arbitrum uses an inbox to aggregate messages going from L1 -> L2, source:
 * https://github.com/OffchainLabs/nitro/blob/master/contracts/src/bridge/Inbox.sol
 *
 */
interface IArbitrumOutbox {
  event SendRootUpdated(bytes32 indexed blockHash, bytes32 indexed outputRoot);
  event OutBoxTransactionExecuted(
    address indexed to,
    address indexed l2Sender,
    uint256 indexed zero,
    uint256 transactionIndex
  );

  function rollup() external view returns (address); // the rollup contract

  // function bridge() external view returns (IBridge); // the bridge contract

  function spent(uint256) external view returns (bytes32); // packed spent bitmap

  function roots(bytes32) external view returns (bytes32); // maps root hashes => L2 block hash

  // solhint-disable-next-line func-name-mixedcase
  function OUTBOX_VERSION() external view returns (uint128); // the outbox version

  function updateSendRoot(bytes32 sendRoot, bytes32 l2BlockHash) external;

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
   *       to confirm a pending merkle root, but that would be less pratical for integrating with tooling.
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

pragma solidity 0.8.17;

// modified from: https://github.com/OffchainLabs/nitro/blob/master/contracts/src/rollup/Node.sol
struct Node {
  // Hash of the state of the chain as of this node
  bytes32 stateHash;
  // Hash of the data that can be challenged
  bytes32 challengeHash;
  // Hash of the data that will be committed if this node is confirmed
  bytes32 confirmData;
  // Index of the node previous to this one
  uint64 prevNum;
  // Deadline at which this node can be confirmed
  uint64 deadlineBlock;
  // Deadline at which a child of this node can be confirmed
  uint64 noChildConfirmedBeforeBlock;
  // Number of stakers staked on this node. This includes real stakers and zombies
  uint64 stakerCount;
  // Number of stakers staked on a child node. This includes real stakers and zombies
  uint64 childStakerCount;
  // This value starts at zero and is set to a value when the first child is created. After that it is constant until the node is destroyed or the owner destroys pending nodes
  uint64 firstChildBlock;
  // The number of the latest child of this node to be created
  uint64 latestChildNumber;
  // The block number when this node was created
  uint64 createdAtBlock;
  // A hash of all the data needed to determine this node's validity, to protect against reorgs
  bytes32 nodeHash;
}

// modified from: https://github.com/OffchainLabs/nitro/blob/master/contracts/src/rollup/IRollupCore.sol
interface IArbitrumRollup {
  /**
   * @notice Get the Node for the given index.
   */
  function getNode(uint64 nodeNum) external view returns (Node memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {IProposedOwnable} from "./interfaces/IProposedOwnable.sol";

/**
 * @title ProposedOwnable
 * @notice Contract module which provides a basic access control mechanism,
 * where there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed via a two step process:
 * 1. Call `proposeOwner`
 * 2. Wait out the delay period
 * 3. Call `acceptOwner`
 *
 * @dev This module is used through inheritance. It will make available the
 * modifier `onlyOwner`, which can be applied to your functions to restrict
 * their use to the owner.
 *
 * @dev The majority of this code was taken from the openzeppelin Ownable
 * contract
 *
 */
abstract contract ProposedOwnable is IProposedOwnable {
  // ========== Custom Errors ===========

  error ProposedOwnable__onlyOwner_notOwner();
  error ProposedOwnable__onlyProposed_notProposedOwner();
  error ProposedOwnable__ownershipDelayElapsed_delayNotElapsed();
  error ProposedOwnable__proposeNewOwner_invalidProposal();
  error ProposedOwnable__proposeNewOwner_noOwnershipChange();
  error ProposedOwnable__renounceOwnership_noProposal();
  error ProposedOwnable__renounceOwnership_invalidProposal();

  // ============ Properties ============

  address private _owner;

  address private _proposed;
  uint256 private _proposedOwnershipTimestamp;

  uint256 private constant _delay = 7 days;

  // ======== Getters =========

  /**
   * @notice Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @notice Returns the address of the proposed owner.
   */
  function proposed() public view virtual returns (address) {
    return _proposed;
  }

  /**
   * @notice Returns the address of the proposed owner.
   */
  function proposedTimestamp() public view virtual returns (uint256) {
    return _proposedOwnershipTimestamp;
  }

  /**
   * @notice Returns the delay period before a new owner can be accepted.
   */
  function delay() public view virtual returns (uint256) {
    return _delay;
  }

  /**
   * @notice Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    if (_owner != msg.sender) revert ProposedOwnable__onlyOwner_notOwner();
    _;
  }

  /**
   * @notice Throws if called by any account other than the proposed owner.
   */
  modifier onlyProposed() {
    if (_proposed != msg.sender) revert ProposedOwnable__onlyProposed_notProposedOwner();
    _;
  }

  /**
   * @notice Throws if the ownership delay has not elapsed
   */
  modifier ownershipDelayElapsed() {
    // Ensure delay has elapsed
    if ((block.timestamp - _proposedOwnershipTimestamp) <= _delay)
      revert ProposedOwnable__ownershipDelayElapsed_delayNotElapsed();
    _;
  }

  /**
   * @notice Indicates if the ownership has been renounced() by
   * checking if current owner is address(0)
   */
  function renounced() public view returns (bool) {
    return _owner == address(0);
  }

  // ======== External =========

  /**
   * @notice Sets the timestamp for an owner to be proposed, and sets the
   * newly proposed owner as step 1 in a 2-step process
   */
  function proposeNewOwner(address newlyProposed) public virtual onlyOwner {
    // Contract as source of truth
    if (_proposed == newlyProposed && _proposedOwnershipTimestamp != 0)
      revert ProposedOwnable__proposeNewOwner_invalidProposal();

    // Sanity check: reasonable proposal
    if (_owner == newlyProposed) revert ProposedOwnable__proposeNewOwner_noOwnershipChange();

    _setProposed(newlyProposed);
  }

  /**
   * @notice Renounces ownership of the contract after a delay
   */
  function renounceOwnership() public virtual onlyOwner ownershipDelayElapsed {
    // Ensure there has been a proposal cycle started
    if (_proposedOwnershipTimestamp == 0) revert ProposedOwnable__renounceOwnership_noProposal();

    // Require proposed is set to 0
    if (_proposed != address(0)) revert ProposedOwnable__renounceOwnership_invalidProposal();

    // Emit event, set new owner, reset timestamp
    _setOwner(address(0));
  }

  /**
   * @notice Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function acceptProposedOwner() public virtual onlyProposed ownershipDelayElapsed {
    // NOTE: no need to check if _owner == _proposed, because the _proposed
    // is 0-d out and this check is implicitly enforced by modifier

    // NOTE: no need to check if _proposedOwnershipTimestamp > 0 because
    // the only time this would happen is if the _proposed was never
    // set (will fail from modifier) or if the owner == _proposed (checked
    // above)

    // Emit event, set new owner, reset timestamp
    _setOwner(_proposed);
  }

  // ======== Internal =========

  function _setOwner(address newOwner) internal {
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
    delete _proposedOwnershipTimestamp;
    delete _proposed;
  }

  function _setProposed(address newlyProposed) private {
    _proposedOwnershipTimestamp = block.timestamp;
    _proposed = newlyProposed;
    emit OwnershipProposed(newlyProposed);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IProposedOwnable
 * @notice Defines a minimal interface for ownership with a two step proposal and acceptance
 * process
 */
interface IProposedOwnable {
  /**
   * @dev This emits when change in ownership of a contract is proposed.
   */
  event OwnershipProposed(address indexed proposedOwner);

  /**
   * @dev This emits when ownership of a contract changes.
   */
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @notice Get the address of the owner
   * @return owner_ The address of the owner.
   */
  function owner() external view returns (address owner_);

  /**
   * @notice Get the address of the proposed owner
   * @return proposed_ The address of the proposed.
   */
  function proposed() external view returns (address proposed_);

  /**
   * @notice Set the address of the proposed owner of the contract
   * @param newlyProposed The proposed new owner of the contract
   */
  function proposeNewOwner(address newlyProposed) external;

  /**
   * @notice Set the address of the proposed owner of the contract
   */
  function acceptProposedOwner() external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

library TypedMemView {
  // Why does this exist?
  // the solidity `bytes memory` type has a few weaknesses.
  // 1. You can't index ranges effectively
  // 2. You can't slice without copying
  // 3. The underlying data may represent any type
  // 4. Solidity never deallocates memory, and memory costs grow
  //    superlinearly

  // By using a memory view instead of a `bytes memory` we get the following
  // advantages:
  // 1. Slices are done on the stack, by manipulating the pointer
  // 2. We can index arbitrary ranges and quickly convert them to stack types
  // 3. We can insert type info into the pointer, and typecheck at runtime

  // This makes `TypedMemView` a useful tool for efficient zero-copy
  // algorithms.

  // Why bytes29?
  // We want to avoid confusion between views, digests, and other common
  // types so we chose a large and uncommonly used odd number of bytes
  //
  // Note that while bytes are left-aligned in a word, integers and addresses
  // are right-aligned. This means when working in assembly we have to
  // account for the 3 unused bytes on the righthand side
  //
  // First 5 bytes are a type flag.
  // - ff_ffff_fffe is reserved for unknown type.
  // - ff_ffff_ffff is reserved for invalid types/errors.
  // next 12 are memory address
  // next 12 are len
  // bottom 3 bytes are empty

  // Assumptions:
  // - non-modification of memory.
  // - No Solidity updates
  // - - wrt free mem point
  // - - wrt bytes representation in memory
  // - - wrt memory addressing in general

  // Usage:
  // - create type constants
  // - use `assertType` for runtime type assertions
  // - - unfortunately we can't do this at compile time yet :(
  // - recommended: implement modifiers that perform type checking
  // - - e.g.
  // - - `uint40 constant MY_TYPE = 3;`
  // - - ` modifer onlyMyType(bytes29 myView) { myView.assertType(MY_TYPE); }`
  // - instantiate a typed view from a bytearray using `ref`
  // - use `index` to inspect the contents of the view
  // - use `slice` to create smaller views into the same memory
  // - - `slice` can increase the offset
  // - - `slice can decrease the length`
  // - - must specify the output type of `slice`
  // - - `slice` will return a null view if you try to overrun
  // - - make sure to explicitly check for this with `notNull` or `assertType`
  // - use `equal` for typed comparisons.

  // The null view
  bytes29 public constant NULL = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
  uint256 constant LOW_12_MASK = 0xffffffffffffffffffffffff;
  uint256 constant TWENTY_SEVEN_BYTES = 8 * 27;
  uint256 private constant _27_BYTES_IN_BITS = 8 * 27; // <--- also used this named constant where ever 216 is used.
  uint256 private constant LOW_27_BYTES_MASK = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffff; // (1 << _27_BYTES_IN_BITS) - 1;

  // ========== Custom Errors ===========

  error TypedMemView__assertType_typeAssertionFailed(uint256 actual, uint256 expected);
  error TypedMemView__index_overrun(uint256 loc, uint256 len, uint256 index, uint256 slice);
  error TypedMemView__index_indexMoreThan32Bytes();
  error TypedMemView__unsafeCopyTo_nullPointer();
  error TypedMemView__unsafeCopyTo_invalidPointer();
  error TypedMemView__unsafeCopyTo_identityOOG();
  error TypedMemView__assertValid_validityAssertionFailed();

  /**
   * @notice          Changes the endianness of a uint256.
   * @dev             https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel
   * @param _b        The unsigned integer to reverse
   * @return          v - The reversed value
   */
  function reverseUint256(uint256 _b) internal pure returns (uint256 v) {
    v = _b;

    // swap bytes
    v =
      ((v >> 8) & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) |
      ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);
    // swap 2-byte long pairs
    v =
      ((v >> 16) & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) |
      ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);
    // swap 4-byte long pairs
    v =
      ((v >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) |
      ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);
    // swap 8-byte long pairs
    v =
      ((v >> 64) & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) |
      ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);
    // swap 16-byte long pairs
    v = (v >> 128) | (v << 128);
  }

  /**
   * @notice      Create a mask with the highest `_len` bits set.
   * @param _len  The length
   * @return      mask - The mask
   */
  function leftMask(uint8 _len) private pure returns (uint256 mask) {
    // ugly. redo without assembly?
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      mask := sar(sub(_len, 1), 0x8000000000000000000000000000000000000000000000000000000000000000)
    }
  }

  /**
   * @notice      Return the null view.
   * @return      bytes29 - The null view
   */
  function nullView() internal pure returns (bytes29) {
    return NULL;
  }

  /**
   * @notice      Check if the view is null.
   * @return      bool - True if the view is null
   */
  function isNull(bytes29 memView) internal pure returns (bool) {
    return memView == NULL;
  }

  /**
   * @notice      Check if the view is not null.
   * @return      bool - True if the view is not null
   */
  function notNull(bytes29 memView) internal pure returns (bool) {
    return !isNull(memView);
  }

  /**
   * @notice          Check if the view is of a invalid type and points to a valid location
   *                  in memory.
   * @dev             We perform this check by examining solidity's unallocated memory
   *                  pointer and ensuring that the view's upper bound is less than that.
   * @param memView   The view
   * @return          ret - True if the view is invalid
   */
  function isNotValid(bytes29 memView) internal pure returns (bool ret) {
    if (typeOf(memView) == 0xffffffffff) {
      return true;
    }
    uint256 _end = end(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ret := gt(_end, mload(0x40))
    }
  }

  /**
   * @notice          Require that a typed memory view be valid.
   * @dev             Returns the view for easy chaining.
   * @param memView   The view
   * @return          bytes29 - The validated view
   */
  function assertValid(bytes29 memView) internal pure returns (bytes29) {
    if (isNotValid(memView)) revert TypedMemView__assertValid_validityAssertionFailed();
    return memView;
  }

  /**
   * @notice          Return true if the memview is of the expected type. Otherwise false.
   * @param memView   The view
   * @param _expected The expected type
   * @return          bool - True if the memview is of the expected type
   */
  function isType(bytes29 memView, uint40 _expected) internal pure returns (bool) {
    return typeOf(memView) == _expected;
  }

  /**
   * @notice          Require that a typed memory view has a specific type.
   * @dev             Returns the view for easy chaining.
   * @param memView   The view
   * @param _expected The expected type
   * @return          bytes29 - The view with validated type
   */
  function assertType(bytes29 memView, uint40 _expected) internal pure returns (bytes29) {
    if (!isType(memView, _expected)) {
      revert TypedMemView__assertType_typeAssertionFailed(uint256(typeOf(memView)), uint256(_expected));
    }
    return memView;
  }

  /**
   * @notice          Return an identical view with a different type.
   * @param memView   The view
   * @param _newType  The new type
   * @return          newView - The new view with the specified type
   */
  function castTo(bytes29 memView, uint40 _newType) internal pure returns (bytes29 newView) {
    // then | in the new type
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      // shift off the top 5 bytes
      newView := or(and(memView, LOW_27_BYTES_MASK), shl(_27_BYTES_IN_BITS, _newType))
    }
  }

  /**
   * @notice          Unsafe raw pointer construction. This should generally not be called
   *                  directly. Prefer `ref` wherever possible.
   * @dev             Unsafe raw pointer construction. This should generally not be called
   *                  directly. Prefer `ref` wherever possible.
   * @param _type     The type
   * @param _loc      The memory address
   * @param _len      The length
   * @return          newView - The new view with the specified type, location and length
   */
  function unsafeBuildUnchecked(
    uint256 _type,
    uint256 _loc,
    uint256 _len
  ) private pure returns (bytes29 newView) {
    uint256 _uint96Bits = 96;
    uint256 _emptyBits = 24;

    // Cast params to ensure input is of correct length
    uint96 len_ = uint96(_len);
    uint96 loc_ = uint96(_loc);
    require(len_ == _len && loc_ == _loc, "!truncated");

    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      newView := shl(_uint96Bits, _type) // insert type
      newView := shl(_uint96Bits, or(newView, loc_)) // insert loc
      newView := shl(_emptyBits, or(newView, len_)) // empty bottom 3 bytes
    }
  }

  /**
   * @notice          Instantiate a new memory view. This should generally not be called
   *                  directly. Prefer `ref` wherever possible.
   * @dev             Instantiate a new memory view. This should generally not be called
   *                  directly. Prefer `ref` wherever possible.
   * @param _type     The type
   * @param _loc      The memory address
   * @param _len      The length
   * @return          newView - The new view with the specified type, location and length
   */
  function build(
    uint256 _type,
    uint256 _loc,
    uint256 _len
  ) internal pure returns (bytes29 newView) {
    uint256 _end = _loc + _len;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      if gt(_end, mload(0x40)) {
        _end := 0
      }
    }
    if (_end == 0) {
      return NULL;
    }
    newView = unsafeBuildUnchecked(_type, _loc, _len);
  }

  /**
   * @notice          Instantiate a memory view from a byte array.
   * @dev             Note that due to Solidity memory representation, it is not possible to
   *                  implement a deref, as the `bytes` type stores its len in memory.
   * @param arr       The byte array
   * @param newType   The type
   * @return          bytes29 - The memory view
   */
  function ref(bytes memory arr, uint40 newType) internal pure returns (bytes29) {
    uint256 _len = arr.length;

    uint256 _loc;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      _loc := add(arr, 0x20) // our view is of the data, not the struct
    }

    return build(newType, _loc, _len);
  }

  /**
   * @notice          Return the associated type information.
   * @param memView   The memory view
   * @return          _type - The type associated with the view
   */
  function typeOf(bytes29 memView) internal pure returns (uint40 _type) {
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      // 216 == 256 - 40
      _type := shr(_27_BYTES_IN_BITS, memView) // shift out lower 24 bytes
    }
  }

  /**
   * @notice          Return the memory address of the underlying bytes.
   * @param memView   The view
   * @return          _loc - The memory address
   */
  function loc(bytes29 memView) internal pure returns (uint96 _loc) {
    uint256 _mask = LOW_12_MASK; // assembly can't use globals
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      // 120 bits = 12 bytes (the encoded loc) + 3 bytes (empty low space)
      _loc := and(shr(120, memView), _mask)
    }
  }

  /**
   * @notice          The number of memory words this memory view occupies, rounded up.
   * @param memView   The view
   * @return          uint256 - The number of memory words
   */
  function words(bytes29 memView) internal pure returns (uint256) {
    return (uint256(len(memView)) + 31) / 32;
  }

  /**
   * @notice          The in-memory footprint of a fresh copy of the view.
   * @param memView   The view
   * @return          uint256 - The in-memory footprint of a fresh copy of the view.
   */
  function footprint(bytes29 memView) internal pure returns (uint256) {
    return words(memView) * 32;
  }

  /**
   * @notice          The number of bytes of the view.
   * @param memView   The view
   * @return          _len - The length of the view
   */
  function len(bytes29 memView) internal pure returns (uint96 _len) {
    uint256 _mask = LOW_12_MASK; // assembly can't use globals
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      _len := and(shr(24, memView), _mask)
    }
  }

  /**
   * @notice          Returns the endpoint of `memView`.
   * @param memView   The view
   * @return          uint256 - The endpoint of `memView`
   */
  function end(bytes29 memView) internal pure returns (uint256) {
    unchecked {
      return loc(memView) + len(memView);
    }
  }

  /**
   * @notice          Safe slicing without memory modification.
   * @param memView   The view
   * @param _index    The start index
   * @param _len      The length
   * @param newType   The new type
   * @return          bytes29 - The new view
   */
  function slice(
    bytes29 memView,
    uint256 _index,
    uint256 _len,
    uint40 newType
  ) internal pure returns (bytes29) {
    uint256 _loc = loc(memView);

    // Ensure it doesn't overrun the view
    if (_loc + _index + _len > end(memView)) {
      return NULL;
    }

    _loc = _loc + _index;
    return build(newType, _loc, _len);
  }

  /**
   * @notice          Shortcut to `slice`. Gets a view representing the first `_len` bytes.
   * @param memView   The view
   * @param _len      The length
   * @param newType   The new type
   * @return          bytes29 - The new view
   */
  function prefix(
    bytes29 memView,
    uint256 _len,
    uint40 newType
  ) internal pure returns (bytes29) {
    return slice(memView, 0, _len, newType);
  }

  /**
   * @notice          Shortcut to `slice`. Gets a view representing the last `_len` byte.
   * @param memView   The view
   * @param _len      The length
   * @param newType   The new type
   * @return          bytes29 - The new view
   */
  function postfix(
    bytes29 memView,
    uint256 _len,
    uint40 newType
  ) internal pure returns (bytes29) {
    return slice(memView, uint256(len(memView)) - _len, _len, newType);
  }

  /**
   * @notice          Load up to 32 bytes from the view onto the stack.
   * @dev             Returns a bytes32 with only the `_bytes` highest bytes set.
   *                  This can be immediately cast to a smaller fixed-length byte array.
   *                  To automatically cast to an integer, use `indexUint`.
   * @param memView   The view
   * @param _index    The index
   * @param _bytes    The bytes
   * @return          result - The 32 byte result
   */
  function index(
    bytes29 memView,
    uint256 _index,
    uint8 _bytes
  ) internal pure returns (bytes32 result) {
    if (_bytes == 0) {
      return bytes32(0);
    }
    if (_index + _bytes > len(memView)) {
      // "TypedMemView/index - Overran the view. Slice is at {loc} with length {len}. Attempted to index at offset {index} with length {slice},
      revert TypedMemView__index_overrun(loc(memView), len(memView), _index, uint256(_bytes));
    }
    if (_bytes > 32) revert TypedMemView__index_indexMoreThan32Bytes();

    uint8 bitLength;
    unchecked {
      bitLength = _bytes * 8;
    }
    uint256 _loc = loc(memView);
    uint256 _mask = leftMask(bitLength);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      result := and(mload(add(_loc, _index)), _mask)
    }
  }

  /**
   * @notice          Parse an unsigned integer from the view at `_index`.
   * @dev             Requires that the view have >= `_bytes` bytes following that index.
   * @param memView   The view
   * @param _index    The index
   * @param _bytes    The bytes
   * @return          result - The unsigned integer
   */
  function indexUint(
    bytes29 memView,
    uint256 _index,
    uint8 _bytes
  ) internal pure returns (uint256 result) {
    return uint256(index(memView, _index, _bytes)) >> ((32 - _bytes) * 8);
  }

  /**
   * @notice          Parse an unsigned integer from LE bytes.
   * @param memView   The view
   * @param _index    The index
   * @param _bytes    The bytes
   * @return          result - The unsigned integer
   */
  function indexLEUint(
    bytes29 memView,
    uint256 _index,
    uint8 _bytes
  ) internal pure returns (uint256 result) {
    return reverseUint256(uint256(index(memView, _index, _bytes)));
  }

  /**
   * @notice          Parse an address from the view at `_index`. Requires that the view have >= 20 bytes
   *                  following that index.
   * @param memView   The view
   * @param _index    The index
   * @return          address - The address
   */
  function indexAddress(bytes29 memView, uint256 _index) internal pure returns (address) {
    return address(uint160(indexUint(memView, _index, 20)));
  }

  /**
   * @notice          Return the keccak256 hash of the underlying memory
   * @param memView   The view
   * @return          digest - The keccak256 hash of the underlying memory
   */
  function keccak(bytes29 memView) internal pure returns (bytes32 digest) {
    uint256 _loc = loc(memView);
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      digest := keccak256(_loc, _len)
    }
  }

  /**
   * @notice          Return true if the underlying memory is equal. Else false.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - True if the underlying memory is equal
   */
  function untypedEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
    return (loc(left) == loc(right) && len(left) == len(right)) || keccak(left) == keccak(right);
  }

  /**
   * @notice          Return false if the underlying memory is equal. Else true.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - False if the underlying memory is equal
   */
  function untypedNotEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
    return !untypedEqual(left, right);
  }

  /**
   * @notice          Compares type equality.
   * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - True if the types are the same
   */
  function equal(bytes29 left, bytes29 right) internal pure returns (bool) {
    return left == right || (typeOf(left) == typeOf(right) && keccak(left) == keccak(right));
  }

  /**
   * @notice          Compares type inequality.
   * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - True if the types are not the same
   */
  function notEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
    return !equal(left, right);
  }

  /**
   * @notice          Copy the view to a location, return an unsafe memory reference
   * @dev             Super Dangerous direct memory access.
   *
   *                  This reference can be overwritten if anything else modifies memory (!!!).
   *                  As such it MUST be consumed IMMEDIATELY.
   *                  This function is private to prevent unsafe usage by callers.
   * @param memView   The view
   * @param _newLoc   The new location
   * @return          written - the unsafe memory reference
   */
  function unsafeCopyTo(bytes29 memView, uint256 _newLoc) private view returns (bytes29 written) {
    if (isNull(memView)) revert TypedMemView__unsafeCopyTo_nullPointer();
    if (isNotValid(memView)) revert TypedMemView__unsafeCopyTo_invalidPointer();

    uint256 _len = len(memView);
    uint256 _oldLoc = loc(memView);

    uint256 ptr;
    bool res;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40)
      // revert if we're writing in occupied memory
      if gt(ptr, _newLoc) {
        revert(0x60, 0x20) // empty revert message
      }

      // use the identity precompile to copy
      // guaranteed not to fail, so pop the success
      res := staticcall(gas(), 4, _oldLoc, _len, _newLoc, _len)
    }
    if (!res) revert TypedMemView__unsafeCopyTo_identityOOG();
    written = unsafeBuildUnchecked(typeOf(memView), _newLoc, _len);
  }

  /**
   * @notice          Copies the referenced memory to a new loc in memory, returning a `bytes` pointing to
   *                  the new memory
   * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
   * @param memView   The view
   * @return          ret - The view pointing to the new memory
   */
  function clone(bytes29 memView) internal view returns (bytes memory ret) {
    uint256 ptr;
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
      ret := ptr
    }
    unchecked {
      unsafeCopyTo(memView, ptr + 0x20);
    }
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      mstore(0x40, add(add(ptr, _len), 0x20)) // write new unused pointer
      mstore(ptr, _len) // write len of new array (in bytes)
    }
  }

  /**
   * @notice          Join the views in memory, return an unsafe reference to the memory.
   * @dev             Super Dangerous direct memory access.
   *
   *                  This reference can be overwritten if anything else modifies memory (!!!).
   *                  As such it MUST be consumed IMMEDIATELY.
   *                  This function is private to prevent unsafe usage by callers.
   * @param memViews  The views
   * @return          unsafeView - The conjoined view pointing to the new memory
   */
  function unsafeJoin(bytes29[] memory memViews, uint256 _location) private view returns (bytes29 unsafeView) {
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      let ptr := mload(0x40)
      // revert if we're writing in occupied memory
      if gt(ptr, _location) {
        revert(0x60, 0x20) // empty revert message
      }
    }

    uint256 _offset = 0;
    uint256 _len = memViews.length;
    for (uint256 i = 0; i < _len; ) {
      bytes29 memView = memViews[i];
      unchecked {
        unsafeCopyTo(memView, _location + _offset);
        _offset += len(memView);
        ++i;
      }
    }
    unsafeView = unsafeBuildUnchecked(0, _location, _offset);
  }

  /**
   * @notice          Produce the keccak256 digest of the concatenated contents of multiple views.
   * @param memViews  The views
   * @return          bytes32 - The keccak256 digest
   */
  function joinKeccak(bytes29[] memory memViews) internal view returns (bytes32) {
    uint256 ptr;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
    }
    return keccak(unsafeJoin(memViews, ptr));
  }

  /**
   * @notice          copies all views, joins them into a new bytearray.
   * @param memViews  The views
   * @return          ret - The new byte array
   */
  function join(bytes29[] memory memViews) internal view returns (bytes memory ret) {
    uint256 ptr;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
    }

    bytes29 _newView;
    unchecked {
      _newView = unsafeJoin(memViews, ptr + 0x20);
    }
    uint256 _written = len(_newView);
    uint256 _footprint = footprint(_newView);

    assembly {
      // solhint-disable-previous-line no-inline-assembly
      // store the legnth
      mstore(ptr, _written)
      // new pointer is old + 0x20 + the footprint of the body
      mstore(0x40, add(add(ptr, _footprint), 0x20))
      ret := ptr
    }
  }
}