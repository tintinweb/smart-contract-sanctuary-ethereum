// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./IBridge.sol";
import "./ISequencerInbox.sol";
import "./Messages.sol";

import {GasRefundEnabled, IGasRefunder} from "../libraries/IGasRefunder.sol";
import "../libraries/DelegateCallAware.sol";
import {MAX_DATA_SIZE} from "../libraries/Constants.sol";

/**
 * @title Accepts batches from the sequencer and adds them to the rollup inbox.
 * @notice Contains the inbox accumulator which is the ordering of all data and transactions to be processed by the rollup.
 * As part of submitting a batch the sequencer is also expected to include items enqueued
 * in the delayed inbox (Bridge.sol). If items in the delayed inbox are not included by a
 * sequencer within a time limit they can be force included into the rollup inbox by anyone.
 */
contract SequencerInbox is DelegateCallAware, GasRefundEnabled, ISequencerInbox {
    bytes32[] public override inboxAccs;
    uint256 public totalDelayedMessagesRead;

    IBridge public delayedBridge;

    /// @dev The size of the batch header
    uint256 public constant HEADER_LENGTH = 40;
    /// @dev If the first batch data byte after the header has this bit set,
    /// the sequencer inbox has authenticated the data. Currently not used.
    bytes1 public constant DATA_AUTHENTICATED_FLAG = 0x40;

    address public rollup;
    mapping(address => bool) public isBatchPoster;
    ISequencerInbox.MaxTimeVariation public maxTimeVariation;

    function initialize(
        IBridge delayedBridge_,
        address rollup_,
        ISequencerInbox.MaxTimeVariation calldata maxTimeVariation_
    ) external onlyDelegated {
        if (delayedBridge != IBridge(address(0))) revert AlreadyInit();
        if (delayedBridge_ == IBridge(address(0))) revert HadZeroInit();
        delayedBridge = delayedBridge_;
        rollup = rollup_;
        maxTimeVariation = maxTimeVariation_;
    }

    function getTimeBounds() internal view virtual returns (TimeBounds memory) {
        TimeBounds memory bounds;
        if (block.timestamp > maxTimeVariation.delaySeconds) {
            bounds.minTimestamp = uint64(block.timestamp - maxTimeVariation.delaySeconds);
        }
        bounds.maxTimestamp = uint64(block.timestamp + maxTimeVariation.futureSeconds);
        if (block.number > maxTimeVariation.delayBlocks) {
            bounds.minBlockNumber = uint64(block.number - maxTimeVariation.delayBlocks);
        }
        bounds.maxBlockNumber = uint64(block.number + maxTimeVariation.futureBlocks);
        return bounds;
    }

    /// @notice Force messages from the delayed inbox to be included in the chain
    /// Callable by any address, but message can only be force-included after maxTimeVariation.delayBlocks and maxTimeVariation.delaySeconds
    /// has elapsed. As part of normal behaviour the sequencer will include these messages
    /// so it's only necessary to call this if the sequencer is down, or not including
    /// any delayed messages.
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
    ) external {
        if (_totalDelayedMessagesRead <= totalDelayedMessagesRead) revert DelayedBackwards();
        bytes32 messageHash = Messages.messageHash(
            kind,
            sender,
            l1BlockAndTime[0],
            l1BlockAndTime[1],
            _totalDelayedMessagesRead - 1,
            baseFeeL1,
            messageDataHash
        );
        // Can only force-include after the Sequencer-only window has expired.
        if (l1BlockAndTime[0] + maxTimeVariation.delayBlocks >= block.number)
            revert ForceIncludeBlockTooSoon();
        if (l1BlockAndTime[1] + maxTimeVariation.delaySeconds >= block.timestamp)
            revert ForceIncludeTimeTooSoon();

        // Verify that message hash represents the last message sequence of delayed message to be included
        bytes32 prevDelayedAcc = 0;
        if (_totalDelayedMessagesRead > 1) {
            prevDelayedAcc = delayedBridge.inboxAccs(_totalDelayedMessagesRead - 2);
        }
        if (
            delayedBridge.inboxAccs(_totalDelayedMessagesRead - 1) !=
            Messages.accumulateInboxMessage(prevDelayedAcc, messageHash)
        ) revert IncorrectMessagePreimage();

        (bytes32 dataHash, TimeBounds memory timeBounds) = formEmptyDataHash(
            _totalDelayedMessagesRead
        );
        (bytes32 beforeAcc, bytes32 delayedAcc, bytes32 afterAcc) = addSequencerL2BatchImpl(
            dataHash,
            _totalDelayedMessagesRead
        );
        emit SequencerBatchDelivered(
            inboxAccs.length - 1,
            beforeAcc,
            afterAcc,
            delayedAcc,
            totalDelayedMessagesRead,
            timeBounds,
            BatchDataLocation.NoData
        );
    }

    function addSequencerL2BatchFromOrigin(
        uint256 sequenceNumber,
        bytes calldata data,
        uint256 afterDelayedMessagesRead,
        IGasRefunder gasRefunder
    ) external refundsGasWithCalldata(gasRefunder, payable(msg.sender)) {
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender != tx.origin) revert NotOrigin();
        if (!isBatchPoster[msg.sender]) revert NotBatchPoster();
        if (inboxAccs.length != sequenceNumber) revert BadSequencerNumber();
        (bytes32 dataHash, TimeBounds memory timeBounds) = formDataHash(
            data,
            afterDelayedMessagesRead
        );
        (bytes32 beforeAcc, bytes32 delayedAcc, bytes32 afterAcc) = addSequencerL2BatchImpl(
            dataHash,
            afterDelayedMessagesRead
        );
        emit SequencerBatchDelivered(
            inboxAccs.length - 1,
            beforeAcc,
            afterAcc,
            delayedAcc,
            totalDelayedMessagesRead,
            timeBounds,
            BatchDataLocation.TxInput
        );
    }

    function addSequencerL2Batch(
        uint256 sequenceNumber,
        bytes calldata data,
        uint256 afterDelayedMessagesRead,
        IGasRefunder gasRefunder
    ) external override refundsGasNoCalldata(gasRefunder, payable(msg.sender)) {
        if (!isBatchPoster[msg.sender] && msg.sender != rollup) revert NotBatchPoster();
        if (inboxAccs.length != sequenceNumber) revert BadSequencerNumber();

        (bytes32 dataHash, TimeBounds memory timeBounds) = formDataHash(
            data,
            afterDelayedMessagesRead
        );
        (bytes32 beforeAcc, bytes32 delayedAcc, bytes32 afterAcc) = addSequencerL2BatchImpl(
            dataHash,
            afterDelayedMessagesRead
        );
        emit SequencerBatchDelivered(
            sequenceNumber,
            beforeAcc,
            afterAcc,
            delayedAcc,
            afterDelayedMessagesRead,
            timeBounds,
            BatchDataLocation.SeparateBatchEvent
        );
        emit SequencerBatchData(sequenceNumber, data);
    }

    function packHeader(uint256 afterDelayedMessagesRead)
        internal
        view
        returns (bytes memory, TimeBounds memory)
    {
        TimeBounds memory timeBounds = getTimeBounds();
        bytes memory header = abi.encodePacked(
            timeBounds.minTimestamp,
            timeBounds.maxTimestamp,
            timeBounds.minBlockNumber,
            timeBounds.maxBlockNumber,
            uint64(afterDelayedMessagesRead)
        );
        // This must always be true from the packed encoding
        assert(header.length == HEADER_LENGTH);
        return (header, timeBounds);
    }

    function formDataHash(bytes calldata data, uint256 afterDelayedMessagesRead)
        internal
        view
        returns (bytes32, TimeBounds memory)
    {
        uint256 fullDataLen = HEADER_LENGTH + data.length;
        if (fullDataLen < HEADER_LENGTH) revert DataLengthOverflow();
        if (fullDataLen > MAX_DATA_SIZE) revert DataTooLarge(fullDataLen, MAX_DATA_SIZE);
        bytes memory fullData = new bytes(fullDataLen);
        (bytes memory header, TimeBounds memory timeBounds) = packHeader(afterDelayedMessagesRead);

        for (uint256 i = 0; i < HEADER_LENGTH; i++) {
            fullData[i] = header[i];
        }
        if (data.length > 0 && (data[0] & DATA_AUTHENTICATED_FLAG) == DATA_AUTHENTICATED_FLAG) {
            revert DataNotAuthenticated();
        }
        // copy data into fullData at offset of HEADER_LENGTH (the extra 32 offset is because solidity puts the array len first)
        assembly {
            calldatacopy(add(fullData, add(HEADER_LENGTH, 32)), data.offset, data.length)
        }
        return (keccak256(fullData), timeBounds);
    }

    function formEmptyDataHash(uint256 afterDelayedMessagesRead)
        internal
        view
        returns (bytes32, TimeBounds memory)
    {
        (bytes memory header, TimeBounds memory timeBounds) = packHeader(afterDelayedMessagesRead);
        return (keccak256(header), timeBounds);
    }

    function addSequencerL2BatchImpl(bytes32 dataHash, uint256 afterDelayedMessagesRead)
        internal
        returns (
            bytes32 beforeAcc,
            bytes32 delayedAcc,
            bytes32 acc
        )
    {
        if (afterDelayedMessagesRead < totalDelayedMessagesRead) revert DelayedBackwards();
        if (afterDelayedMessagesRead > delayedBridge.messageCount()) revert DelayedTooFar();

        if (inboxAccs.length > 0) {
            beforeAcc = inboxAccs[inboxAccs.length - 1];
        }
        if (afterDelayedMessagesRead > 0) {
            delayedAcc = delayedBridge.inboxAccs(afterDelayedMessagesRead - 1);
        }

        acc = keccak256(abi.encodePacked(beforeAcc, dataHash, delayedAcc));
        inboxAccs.push(acc);
        totalDelayedMessagesRead = afterDelayedMessagesRead;
    }

    function batchCount() external view override returns (uint256) {
        return inboxAccs.length;
    }

    function setMaxTimeVariation(ISequencerInbox.MaxTimeVariation memory maxTimeVariation_)
        external
        override
    {
        if (msg.sender != rollup) revert NotRollup(msg.sender, rollup);
        maxTimeVariation = maxTimeVariation_;
    }

    function setIsBatchPoster(address addr, bool isBatchPoster_) external override {
        if (msg.sender != rollup) revert NotRollup(msg.sender, rollup);
        isBatchPoster[addr] = isBatchPoster_;
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import {NotContract} from "../libraries/Error.sol";

/// @dev Thrown when an un-authorized address tries to access an only-inbox function
/// @param sender The un-authorized sender
error NotInbox(address sender);

/// @dev Thrown when an un-authorized address tries to access an only-outbox function
/// @param sender The un-authorized sender
error NotOutbox(address sender);

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

    // These are only callable by the admin
    function setInbox(address inbox, bool enabled) external;

    function setOutbox(address inbox, bool enabled) external;

    // View functions

    function activeOutbox() external view returns (address);

    function allowedInboxes(address inbox) external view returns (bool);

    function allowedOutboxes(address outbox) external view returns (bool);

    function inboxAccs(uint256 index) external view returns (bytes32);

    function messageCount() external view returns (uint256);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../libraries/IGasRefunder.sol";
import {AlreadyInit, HadZeroInit, NotOrigin, DataTooLarge, NotRollup} from "../libraries/Error.sol";

interface ISequencerInbox {
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

    /// @dev a separate event that emits batch data when this isn't easily accessible in the tx.input
    event SequencerBatchData(uint256 indexed batchSequenceNumber, bytes data);

    /// @dev Thrown when someone attempts to read fewer messages than have already been read
    error DelayedBackwards();

    /// @dev Thrown when someone attempts to read more messages than exist
    error DelayedTooFar();

    /// @dev Thrown if the length of the header plus the length of the batch overflows
    error DataLengthOverflow();

    /// @dev Force include can only read messages more blocks old than the delay period
    error ForceIncludeBlockTooSoon();

    /// @dev Force include can only read messages more seconds old than the delay period
    error ForceIncludeTimeTooSoon();

    /// @dev The message provided did not match the hash in the delayed inbox
    error IncorrectMessagePreimage();

    /// @dev This can only be called by the batch poster
    error NotBatchPoster();

    /// @dev The sequence number provided to this message was inconsistent with the number of batches already included
    error BadSequencerNumber();

    /// @dev The batch data has the inbox authenticated bit set, but the batch data was not authenticated by the inbox
    error DataNotAuthenticated();

    function inboxAccs(uint256 index) external view returns (bytes32);

    function batchCount() external view returns (uint256);

    function setMaxTimeVariation(MaxTimeVariation memory timeVariation) external;

    function setIsBatchPoster(address addr, bool isBatchPoster_) external;

    function addSequencerL2Batch(
        uint256 sequenceNumber,
        bytes calldata data,
        uint256 afterDelayedMessagesRead,
        IGasRefunder gasRefunder
    ) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library Messages {
    function messageHash(
        uint8 kind,
        address sender,
        uint64 blockNumber,
        uint64 timestamp,
        uint256 inboxSeqNum,
        uint256 baseFeeL1,
        bytes32 messageDataHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    kind,
                    sender,
                    blockNumber,
                    timestamp,
                    inboxSeqNum,
                    baseFeeL1,
                    messageDataHash
                )
            );
    }

    function accumulateInboxMessage(bytes32 prevAcc, bytes32 message)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(prevAcc, message));
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.6.11 <0.9.0;

interface IGasRefunder {
    function onGasSpent(
        address payable spender,
        uint256 gasUsed,
        uint256 calldataSize
    ) external returns (bool success);
}

abstract contract GasRefundEnabled {
    modifier refundsGasWithCalldata(IGasRefunder gasRefunder, address payable spender) {
        uint256 startGasLeft = gasleft();
        _;
        if (address(gasRefunder) != address(0)) {
            uint256 calldataSize;
            assembly {
                calldataSize := calldatasize()
            }
            gasRefunder.onGasSpent(spender, startGasLeft - gasleft(), calldataSize);
        }
    }

    modifier refundsGasNoCalldata(IGasRefunder gasRefunder, address payable spender) {
        uint256 startGasLeft = gasleft();
        _;
        if (address(gasRefunder) != address(0)) {
            gasRefunder.onGasSpent(spender, startGasLeft - gasleft(), 0);
        }
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import {NotOwner} from "./Error.sol";

/// @dev A stateless contract that allows you to infer if the current call has been delegated or not
/// Pattern used here is from UUPS implementation by the OpenZeppelin team
abstract contract DelegateCallAware {
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegate call. This allows a function to be
     * callable on the proxy contract but not on the logic contract.
     */
    modifier onlyDelegated() {
        require(address(this) != __self, "Function must be called through delegatecall");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "Function must not be called through delegatecall");
        _;
    }

    /// @dev Check that msg.sender is the current EIP 1967 proxy admin
    modifier onlyProxyOwner() {
        // Storage slot with the admin of the proxy contract
        // This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1
        bytes32 slot = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
        address admin;
        assembly {
            admin := sload(slot)
        }
        if (msg.sender != admin) revert NotOwner(msg.sender, admin);
        _;
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

// 90% of Geth's 128KB tx size limit, leaving ~13KB for proving
uint256 constant MAX_DATA_SIZE = 117964;

uint64 constant NO_CHAL_INDEX = 0;

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

/// @dev Init was already called
error AlreadyInit();

/// Init was called with param set to zero that must be nonzero
error HadZeroInit();

/// @dev Thrown when non owner tries to access an only-owner function
/// @param sender The msg.sender who is not the owner
/// @param owner The owner address
error NotOwner(address sender, address owner);

/// @dev Thrown when an address that is not the rollup tries to call an only-rollup function
/// @param sender The sender who is not the rollup
/// @param rollup The rollup address authorized to call this function
error NotRollup(address sender, address rollup);

/// @dev Thrown when the contract was not called directly from the origin ie msg.sender != tx.origin
error NotOrigin();

/// @dev Provided data was too large
/// @param dataLength The length of the data that is too large
/// @param maxDataLength The max length the data can be
error DataTooLarge(uint256 dataLength, uint256 maxDataLength);

/// @dev The provided is not a contract and was expected to be
/// @param addr The adddress in question
error NotContract(address addr);

/// @dev The merkle proof provided was too long
/// @param actualLength The length of the merkle proof provided
/// @param maxProofLength The max length a merkle proof can have
error MerkleProofTooLong(uint256 actualLength, uint256 maxProofLength);