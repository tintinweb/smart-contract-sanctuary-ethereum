// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "./IOwnable.sol";

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

    event BridgeCallTriggered(
        address indexed outbox,
        address indexed to,
        uint256 value,
        bytes data
    );

    event InboxToggle(address indexed inbox, bool enabled);

    event OutboxToggle(address indexed outbox, bool enabled);

    event SequencerInboxUpdated(address newSequencerInbox);

    function allowedDelayedInboxList(uint256) external returns (address);

    function allowedOutboxList(uint256) external returns (address);

    /// @dev Accumulator for delayed inbox messages; tail represents hash of the current state; each element represents the inclusion of a new message.
    function delayedInboxAccs(uint256) external view returns (bytes32);

    /// @dev Accumulator for sequencer inbox messages; tail represents hash of the current state; each element represents the inclusion of a new message.
    function sequencerInboxAccs(uint256) external view returns (bytes32);

    function rollup() external view returns (IOwnable);

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
    function submitBatchSpendingReport(address batchPoster, bytes32 dataHash)
        external
        returns (uint256 msgNum);

    // ---------- onlyRollupOrOwner functions ----------

    function setSequencerInbox(address _sequencerInbox) external;

    function setDelayedInbox(address inbox, bool enabled) external;

    function setOutbox(address inbox, bool enabled) external;

    // ---------- initializer ----------

    function initialize(IOwnable rollup_) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface IDelayedMessageProvider {
    /// @dev event emitted when a inbox message is added to the Bridge's delayed accumulator
    event InboxMessageDelivered(uint256 indexed messageNum, bytes data);

    /// @dev event emitted when a inbox message is added to the Bridge's delayed accumulator
    /// same as InboxMessageDelivered but the batch data is available in tx.input
    event InboxMessageDeliveredFromOrigin(uint256 indexed messageNum);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "./IBridge.sol";
import "./IDelayedMessageProvider.sol";
import "./ISequencerInbox.sol";

interface IInbox is IDelayedMessageProvider {
    function bridge() external view returns (IBridge);

    function sequencerInbox() external view returns (ISequencerInbox);

    /**
     * @notice Send a generic L2 message to the chain
     * @dev This method is an optimization to avoid having to emit the entirety of the messageData in a log. Instead validators are expected to be able to parse the data from the transaction's input
     *      This method will be disabled upon L1 fork to prevent replay attacks on L2
     * @param messageData Data of the message being sent
     */
    function sendL2MessageFromOrigin(bytes calldata messageData) external returns (uint256);

    /**
     * @notice Send a generic L2 message to the chain
     * @dev This method can be used to send any type of message that doesn't require L1 validation
     *      This method will be disabled upon L1 fork to prevent replay attacks on L2
     * @param messageData Data of the message being sent
     */
    function sendL2Message(bytes calldata messageData) external returns (uint256);

    function sendL1FundedUnsignedTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        address to,
        bytes calldata data
    ) external payable returns (uint256);

    function sendL1FundedContractTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        address to,
        bytes calldata data
    ) external payable returns (uint256);

    function sendUnsignedTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (uint256);

    function sendContractTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (uint256);

    /**
     * @dev This method can only be called upon L1 fork and will not alias the caller
     *      This method will revert if not called from origin
     */
    function sendL1FundedUnsignedTransactionToFork(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        address to,
        bytes calldata data
    ) external payable returns (uint256);

    /**
     * @dev This method can only be called upon L1 fork and will not alias the caller
     *      This method will revert if not called from origin
     */
    function sendUnsignedTransactionToFork(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (uint256);

    /**
     * @notice Send a message to initiate L2 withdrawal
     * @dev This method can only be called upon L1 fork and will not alias the caller
     *      This method will revert if not called from origin
     */
    function sendWithdrawEthToFork(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        uint256 value,
        address withdrawTo
    ) external returns (uint256);

    /**
     * @notice Get the L1 fee for submitting a retryable
     * @dev This fee can be paid by funds already in the L2 aliased address or by the current message value
     * @dev This formula may change in the future, to future proof your code query this method instead of inlining!!
     * @param dataLength The length of the retryable's calldata, in bytes
     * @param baseFee The block basefee when the retryable is included in the chain, if 0 current block.basefee will be used
     */
    function calculateRetryableSubmissionFee(uint256 dataLength, uint256 baseFee)
        external
        view
        returns (uint256);

    /**
     * @notice Deposit eth from L1 to L2 to address of the sender if sender is an EOA, and to its aliased address if the sender is a contract
     * @dev This does not trigger the fallback function when receiving in the L2 side.
     *      Look into retryable tickets if you are interested in this functionality.
     * @dev This function should not be called inside contract constructors
     */
    function depositEth() external payable returns (uint256);

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

    // ---------- onlyRollupOrOwner functions ----------

    /// @notice pauses all inbox functionality
    function pause() external;

    /// @notice unpauses all inbox functionality
    function unpause() external;

    // ---------- initializer ----------

    /**
     * @dev function to be called one time during the inbox upgrade process
     *      this is used to fix the storage slots
     */
    function postUpgradeInit(IBridge _bridge) external;

    function initialize(IBridge _bridge, ISequencerInbox _sequencerInbox) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.21 <0.9.0;

interface IOwnable {
    function owner() external view returns (address);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;
pragma experimental ABIEncoderV2;

import "../libraries/IGasRefunder.sol";
import "./IDelayedMessageProvider.sol";
import "./IBridge.sol";

interface ISequencerInbox is IDelayedMessageProvider {
    struct MaxTimeVariation {
        uint256 delayBlocks;
        uint256 futureBlocks;
        uint256 delaySeconds;
        uint256 futureSeconds;
    }

    struct TimeBounds {
        uint64 minTimestamp;
        uint64 maxTimestamp;
        uint64 minBlockNumber;
        uint64 maxBlockNumber;
    }

    enum BatchDataLocation {
        TxInput,
        SeparateBatchEvent,
        NoData
    }

    event SequencerBatchDelivered(
        uint256 indexed batchSequenceNumber,
        bytes32 indexed beforeAcc,
        bytes32 indexed afterAcc,
        bytes32 delayedAcc,
        uint256 afterDelayedMessagesRead,
        TimeBounds timeBounds,
        BatchDataLocation dataLocation
    );

    event OwnerFunctionCalled(uint256 indexed id);

    /// @dev a separate event that emits batch data when this isn't easily accessible in the tx.input
    event SequencerBatchData(uint256 indexed batchSequenceNumber, bytes data);

    /// @dev a valid keyset was added
    event SetValidKeyset(bytes32 indexed keysetHash, bytes keysetBytes);

    /// @dev a keyset was invalidated
    event InvalidateKeyset(bytes32 indexed keysetHash);

    function totalDelayedMessagesRead() external view returns (uint256);

    function bridge() external view returns (IBridge);

    /// @dev The size of the batch header
    // solhint-disable-next-line func-name-mixedcase
    function HEADER_LENGTH() external view returns (uint256);

    /// @dev If the first batch data byte after the header has this bit set,
    ///      the sequencer inbox has authenticated the data. Currently not used.
    // solhint-disable-next-line func-name-mixedcase
    function DATA_AUTHENTICATED_FLAG() external view returns (bytes1);

    function rollup() external view returns (IOwnable);

    function isBatchPoster(address) external view returns (bool);

    struct DasKeySetInfo {
        bool isValidKeyset;
        uint64 creationBlock;
    }

    // https://github.com/ethereum/solidity/issues/11826
    // function maxTimeVariation() external view returns (MaxTimeVariation calldata);
    // function dasKeySetInfo(bytes32) external view returns (DasKeySetInfo calldata);

    /// @notice Remove force inclusion delay after a L1 chainId fork
    function removeDelayAfterFork() external;

    /// @notice Force messages from the delayed inbox to be included in the chain
    ///         Callable by any address, but message can only be force-included after maxTimeVariation.delayBlocks and
    ///         maxTimeVariation.delaySeconds has elapsed. As part of normal behaviour the sequencer will include these
    ///         messages so it's only necessary to call this if the sequencer is down, or not including any delayed messages.
    /// @param _totalDelayedMessagesRead The total number of messages to read up to
    /// @param kind The kind of the last message to be included
    /// @param l1BlockAndTime The l1 block and the l1 timestamp of the last message to be included
    /// @param baseFeeL1 The l1 gas price of the last message to be included
    /// @param sender The sender of the last message to be included
    /// @param messageDataHash The messageDataHash of the last message to be included
    function forceInclusion(
        uint256 _totalDelayedMessagesRead,
        uint8 kind,
        uint64[2] calldata l1BlockAndTime,
        uint256 baseFeeL1,
        address sender,
        bytes32 messageDataHash
    ) external;

    function inboxAccs(uint256 index) external view returns (bytes32);

    function batchCount() external view returns (uint256);

    function isValidKeysetHash(bytes32 ksHash) external view returns (bool);

    /// @notice the creation block is intended to still be available after a keyset is deleted
    function getKeysetCreationBlock(bytes32 ksHash) external view returns (uint256);

    // ---------- BatchPoster functions ----------

    function addSequencerL2BatchFromOrigin(
        uint256 sequenceNumber,
        bytes calldata data,
        uint256 afterDelayedMessagesRead,
        IGasRefunder gasRefunder
    ) external;

    function addSequencerL2Batch(
        uint256 sequenceNumber,
        bytes calldata data,
        uint256 afterDelayedMessagesRead,
        IGasRefunder gasRefunder,
        uint256 prevMessageCount,
        uint256 newMessageCount
    ) external;

    // ---------- onlyRollupOrOwner functions ----------

    /**
     * @notice Set max delay for sequencer inbox
     * @param maxTimeVariation_ the maximum time variation parameters
     */
    function setMaxTimeVariation(MaxTimeVariation memory maxTimeVariation_) external;

    /**
     * @notice Updates whether an address is authorized to be a batch poster at the sequencer inbox
     * @param addr the address
     * @param isBatchPoster_ if the specified address should be authorized as a batch poster
     */
    function setIsBatchPoster(address addr, bool isBatchPoster_) external;

    /**
     * @notice Makes Data Availability Service keyset valid
     * @param keysetBytes bytes of the serialized keyset
     */
    function setValidKeyset(bytes calldata keysetBytes) external;

    /**
     * @notice Invalidates a Data Availability Service keyset
     * @param ksHash hash of the keyset
     */
    function invalidateKeysetHash(bytes32 ksHash) external;

    // ---------- initializer ----------

    function initialize(IBridge bridge_, MaxTimeVariation calldata maxTimeVariation_) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface IGasRefunder {
    function onGasSpent(
        address payable spender,
        uint256 gasUsed,
        uint256 calldataSize
    ) external returns (bool success);
}

abstract contract GasRefundEnabled {
    /// @dev this refunds the sender for execution costs of the tx
    /// calldata costs are only refunded if `msg.sender == tx.origin` to guarantee the value refunded relates to charging
    /// for the `tx.input`. this avoids a possible attack where you generate large calldata from a contract and get over-refunded
    modifier refundsGas(IGasRefunder gasRefunder) {
        uint256 startGasLeft = gasleft();
        _;
        if (address(gasRefunder) != address(0)) {
            uint256 calldataSize;
            assembly {
                calldataSize := calldatasize()
            }
            uint256 calldataWords = (calldataSize + 31) / 32;
            // account for the CALLDATACOPY cost of the proxy contract, including the memory expansion cost
            startGasLeft += calldataWords * 6 + (calldataWords**2) / 512;
            // if triggered in a contract call, the spender may be overrefunded by appending dummy data to the call
            // so we check if it is a top level call, which would mean the sender paid calldata as part of tx.input
            // solhint-disable-next-line avoid-tx-origin
            if (msg.sender != tx.origin) {
                // We can't be sure if this calldata came from the top level tx,
                // so to be safe we tell the gas refunder there was no calldata.
                calldataSize = 0;
            }
            gasRefunder.onGasSpent(payable(msg.sender), startGasLeft - gasleft(), calldataSize);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import { IInbox } from "@arbitrum/nitro-contracts/src/bridge/IInbox.sol";

import { ICrossChainExecutor } from "../interfaces/ICrossChainExecutor.sol";
import { ICrossChainRelayer } from "../interfaces/ICrossChainRelayer.sol";
import "../libraries/CallLib.sol";

/**
 * @title CrossChainRelayerArbitrum contract
 * @notice The CrossChainRelayerArbitrum contract allows a user or contract to send messages from Ethereum to Arbitrum.
 *         It lives on the Ethereum chain and communicates with the `CrossChainExecutorArbitrum` contract on the Arbitrum chain.
 */
contract CrossChainRelayerArbitrum is ICrossChainRelayer {
  /* ============ Events ============ */

  /**
   * @notice Emitted once a message has been processed and put in the Arbitrum inbox.
   * @dev Using the `ticketId`, this message can be reexecuted for some fixed amount of time if it reverts.
   * @param nonce Nonce to uniquely idenfity the batch of calls
   * @param sender Address who processed the calls
   * @param ticketId Id of the newly created retryable ticket
   */
  event ProcessedCalls(uint256 indexed nonce, address indexed sender, uint256 indexed ticketId);

  /* ============ Variables ============ */

  /// @notice Address of the Arbitrum inbox on the Ethereum chain.
  IInbox public immutable inbox;

  /// @notice Address of the executor contract on the Arbitrum chain.
  ICrossChainExecutor public executor;

  /// @notice Gas limit provided for free on Arbitrum.
  uint256 public immutable maxGasLimit;

  /// @notice Nonce to uniquely idenfity each batch of calls.
  uint256 internal nonce;

  /**
   * @notice Hash of transactions that were relayed in `relayCalls`.
   *         txHash => boolean
   * @dev Ensure that messages passed to `processCalls` have been relayed first.
   */
  mapping(bytes32 => bool) public relayed;

  /* ============ Constructor ============ */

  /**
   * @notice CrossChainRelayer constructor.
   * @param _inbox Address of the Arbitrum inbox on Ethereum
   * @param _maxGasLimit Gas limit provided for free on Arbitrum
   */
  constructor(IInbox _inbox, uint256 _maxGasLimit) {
    require(address(_inbox) != address(0), "Relayer/inbox-not-zero-address");
    require(_maxGasLimit > 0, "Relayer/max-gas-limit-gt-zero");

    inbox = _inbox;
    maxGasLimit = _maxGasLimit;
  }

  /* ============ External Functions ============ */

  /// @inheritdoc ICrossChainRelayer
  function relayCalls(CallLib.Call[] calldata _calls, uint256 _gasLimit)
    external
    payable
    returns (uint256)
  {
    uint256 _maxGasLimit = maxGasLimit;

    if (_gasLimit > _maxGasLimit) {
      revert GasLimitTooHigh(_gasLimit, _maxGasLimit);
    }

    nonce++;

    uint256 _nonce = nonce;

    relayed[_getTxHash(_nonce, _calls, msg.sender, _gasLimit)] = true;

    emit RelayedCalls(_nonce, msg.sender, _calls, _gasLimit);

    return _nonce;
  }

  /**
   * @notice Process calls that have been relayed.
   * @dev The transaction hash must match the one stored in the `relayed` mapping.
   * @dev We store `_data` in memory to avoid a stack too deep error.
   * @param _nonce Nonce of the batch of calls to process
   * @param _calls Array of calls being processed
   * @param _sender Address who relayed the `_calls`
   * @param _gasLimit Maximum amount of gas required for the `_calls` to be executed
   * @param _maxSubmissionCost Max gas deducted from user's L2 balance to cover base submission fee
   * @param _gasPriceBid Gas price bid for L2 execution
   * @return uint256 Id of the retryable ticket that was created
   */
  function processCalls(
    uint256 _nonce,
    CallLib.Call[] calldata _calls,
    address _sender,
    uint256 _gasLimit,
    uint256 _maxSubmissionCost,
    uint256 _gasPriceBid
  ) external payable returns (uint256) {
    require(relayed[_getTxHash(_nonce, _calls, _sender, _gasLimit)], "Relayer/calls-not-relayed");

    bytes memory _data = abi.encodeWithSignature(
      "executeCalls(uint256,address,(address,bytes)[])",
      _nonce,
      _sender,
      _calls
    );

    uint256 _ticketID = inbox.createRetryableTicket{ value: msg.value }(
      address(executor),
      0,
      _maxSubmissionCost,
      msg.sender,
      msg.sender,
      _gasLimit,
      _gasPriceBid,
      _data
    );

    emit ProcessedCalls(_nonce, msg.sender, _ticketID);

    return _ticketID;
  }

  /**
   * @notice Set executor contract address.
   * @dev Will revert if it has already been set.
   * @param _executor Address of the executor contract on the Arbitrum chain
   */
  function setExecutor(ICrossChainExecutor _executor) external {
    require(address(executor) == address(0), "Relayer/executor-already-set");
    executor = _executor;
  }

  /**
   * @notice Get transaction hash.
   * @dev The transaction hash is used to ensure that only calls that were relayed are processed.
   * @param _nonce Nonce uniquely identifying the batch of calls that were relayed
   * @param _calls Array of calls that were relayed
   * @param _sender Address who relayed the calls
   * @param _gasLimit Maximum amount of gas that will be consumed by the calls
   * @return bytes32 Transaction hash
   */
  function getTxHash(
    uint256 _nonce,
    CallLib.Call[] calldata _calls,
    address _sender,
    uint256 _gasLimit
  ) external view returns (bytes32) {
    return _getTxHash(_nonce, _calls, _sender, _gasLimit);
  }

  /* ============ Internal Functions ============ */

  /**
   * @notice Get transaction hash.
   * @dev The transaction hash is used to ensure that only calls that were relayed are processed.
   * @param _nonce Nonce uniquely identifying the batch of calls that were relayed
   * @param _calls Array of calls that were relayed
   * @param _sender Address who relayed the calls
   * @param _gasLimit Maximum amount of gas that will be consumed by the calls
   * @return bytes32 Transaction hash
   */
  function _getTxHash(
    uint256 _nonce,
    CallLib.Call[] calldata _calls,
    address _sender,
    uint256 _gasLimit
  ) internal view returns (bytes32) {
    return keccak256(abi.encode(address(this), _nonce, _calls, _sender, _gasLimit));
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import "./ICrossChainRelayer.sol";

import "../libraries/CallLib.sol";

/**
 * @title CrossChainExecutor interface
 * @notice CrossChainExecutor interface of the ERC-5164 standard as defined in the EIP.
 */
interface ICrossChainExecutor {
  /**
   * @notice Emitted when calls have successfully been executed.
   * @param relayer Address of the contract that relayed the calls on the origin chain
   * @param nonce Nonce to uniquely identify the batch of calls
   */
  event ExecutedCalls(ICrossChainRelayer indexed relayer, uint256 indexed nonce);

  /**
   * @notice Execute calls from the origin chain.
   * @dev Should authenticate that the call has been performed by the bridge transport layer.
   * @dev Must emit the `ExecutedCalls` event once calls have been executed.
   * @param nonce Nonce to uniquely idenfity the batch of calls
   * @param sender Address of the sender on the origin chain
   * @param calls Array of calls being executed
   */
  function executeCalls(
    uint256 nonce,
    address sender,
    CallLib.Call[] calldata calls
  ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import "../libraries/CallLib.sol";

/**
 * @title CrossChainRelayer interface
 * @notice CrossChainRelayer interface of the ERC-5164 standard as defined in the EIP.
 */
interface ICrossChainRelayer {
  /**
   * @notice Custom error emitted if the `gasLimit` passed to `relayCalls`
   *         is greater than the one provided for free on the receiving chain.
   * @param gasLimit Gas limit passed to `relayCalls`
   * @param maxGasLimit Gas limit provided for free on the receiving chain
   */
  error GasLimitTooHigh(uint256 gasLimit, uint256 maxGasLimit);

  /**
   * @notice Emitted when calls have successfully been relayed to the executor chain.
   * @param nonce Nonce to uniquely idenfity the batch of calls
   * @param sender Address of the sender
   * @param calls Array of calls being relayed
   * @param gasLimit Maximum amount of gas required for the `calls` to be executed
   */
  event RelayedCalls(
    uint256 indexed nonce,
    address indexed sender,
    CallLib.Call[] calls,
    uint256 gasLimit
  );

  /**
   * @notice Relay the calls to the receiving chain.
   * @dev Must increment a `nonce` so that the batch of calls can be uniquely identified.
   * @dev Must emit the `RelayedCalls` event when successfully called.
   * @dev May require payment. Some bridges may require payment in the native currency, so the function is payable.
   * @param calls Array of calls being relayed
   * @param gasLimit Maximum amount of gas required for the `calls` to be executed
   * @return uint256 Nonce to uniquely idenfity the batch of calls
   */
  function relayCalls(CallLib.Call[] calldata calls, uint256 gasLimit)
    external
    payable
    returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

/**
 * @title CallLib
 * @notice Library to declare and manipulate Call(s).
 */
library CallLib {
  /* ============ Structs ============ */

  /**
   * @notice Call data structure
   * @param target Address that will be called on the receiving chain
   * @param data Data that will be sent to the `target` address
   */
  struct Call {
    address target;
    bytes data;
  }

  /* ============ Custom Errors ============ */

  /**
   * @notice Custom error emitted if a call to a target contract fails.
   * @param callIndex Index of the failed call
   * @param errorData Error data returned by the failed call
   */
  error CallFailure(uint256 callIndex, bytes errorData);

  /**
   * @notice Emitted when a batch of calls has already been executed.
   * @param nonce Nonce to uniquely identify the batch of calls that were re-executed
   */
  error CallsAlreadyExecuted(uint256 nonce);

  /* ============ Internal Functions ============ */

  /**
   * @notice Execute calls from the origin chain.
   * @dev Will revert if `_calls` have already been executed.
   * @dev Will revert if a call fails.
   * @dev Must emit the `ExecutedCalls` event once calls have been executed.
   * @param _nonce Nonce to uniquely idenfity the batch of calls
   * @param _sender Address of the sender on the origin chain
   * @param _calls Array of calls being executed
   * @param _executedNonce Whether `_calls` have already been executed or not
   */
  function executeCalls(
    uint256 _nonce,
    address _sender,
    Call[] memory _calls,
    bool _executedNonce
  ) internal {
    if (_executedNonce) {
      revert CallsAlreadyExecuted(_nonce);
    }

    uint256 _callsLength = _calls.length;

    for (uint256 _callIndex; _callIndex < _callsLength; _callIndex++) {
      Call memory _call = _calls[_callIndex];

      (bool _success, bytes memory _returnData) = _call.target.call(
        abi.encodePacked(_call.data, _nonce, _sender)
      );

      if (!_success) {
        revert CallFailure(_callIndex, _returnData);
      }
    }
  }
}