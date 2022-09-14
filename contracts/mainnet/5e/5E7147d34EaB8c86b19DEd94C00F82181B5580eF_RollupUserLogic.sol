// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import {
    NotContract,
    NotRollupOrOwner,
    NotDelayedInbox,
    NotSequencerInbox,
    NotOutbox,
    InvalidOutboxSet,
    BadSequencerMessageNumber
} from "../libraries/Error.sol";
import "./IBridge.sol";
import "./Messages.sol";
import "../libraries/DelegateCallAware.sol";

import {L1MessageType_batchPostingReport} from "../libraries/MessageTypes.sol";

/**
 * @title Staging ground for incoming and outgoing messages
 * @notice Holds the inbox accumulator for sequenced and delayed messages.
 * It is also the ETH escrow for value sent with these messages.
 * Since the escrow is held here, this contract also contains a list of allowed
 * outboxes that can make calls from here and withdraw this escrow.
 */
contract Bridge is Initializable, DelegateCallAware, IBridge {
    using AddressUpgradeable for address;

    struct InOutInfo {
        uint256 index;
        bool allowed;
    }

    mapping(address => InOutInfo) private allowedDelayedInboxesMap;
    mapping(address => InOutInfo) private allowedOutboxesMap;

    address[] public allowedDelayedInboxList;
    address[] public allowedOutboxList;

    address private _activeOutbox;

    /// @inheritdoc IBridge
    bytes32[] public delayedInboxAccs;

    /// @inheritdoc IBridge
    bytes32[] public sequencerInboxAccs;

    IOwnable public rollup;
    address public sequencerInbox;

    uint256 public override sequencerReportedSubMessageCount;

    address private constant EMPTY_ACTIVEOUTBOX = address(type(uint160).max);

    function initialize(IOwnable rollup_) external initializer onlyDelegated {
        _activeOutbox = EMPTY_ACTIVEOUTBOX;
        rollup = rollup_;
    }

    modifier onlyRollupOrOwner() {
        if (msg.sender != address(rollup)) {
            address rollupOwner = rollup.owner();
            if (msg.sender != rollupOwner) {
                revert NotRollupOrOwner(msg.sender, address(rollup), rollupOwner);
            }
        }
        _;
    }

    /// @dev returns the address of current active Outbox, or zero if no outbox is active
    function activeOutbox() public view returns (address) {
        address outbox = _activeOutbox;
        // address zero is returned if no outbox is set, but the value used in storage
        // is non-zero to save users some gas (as storage refunds are usually maxed out)
        // EIP-1153 would help here.
        // we don't return `EMPTY_ACTIVEOUTBOX` to avoid a breaking change on the current api
        if (outbox == EMPTY_ACTIVEOUTBOX) return address(0);
        return outbox;
    }

    function allowedDelayedInboxes(address inbox) external view returns (bool) {
        return allowedDelayedInboxesMap[inbox].allowed;
    }

    function allowedOutboxes(address outbox) external view returns (bool) {
        return allowedOutboxesMap[outbox].allowed;
    }

    modifier onlySequencerInbox() {
        if (msg.sender != sequencerInbox) revert NotSequencerInbox(msg.sender);
        _;
    }

    function enqueueSequencerMessage(
        bytes32 dataHash,
        uint256 afterDelayedMessagesRead,
        uint256 prevMessageCount,
        uint256 newMessageCount
    )
        external
        onlySequencerInbox
        returns (
            uint256 seqMessageIndex,
            bytes32 beforeAcc,
            bytes32 delayedAcc,
            bytes32 acc
        )
    {
        if (
            sequencerReportedSubMessageCount != prevMessageCount &&
            prevMessageCount != 0 &&
            sequencerReportedSubMessageCount != 0
        ) {
            revert BadSequencerMessageNumber(sequencerReportedSubMessageCount, prevMessageCount);
        }
        sequencerReportedSubMessageCount = newMessageCount;
        seqMessageIndex = sequencerInboxAccs.length;
        if (sequencerInboxAccs.length > 0) {
            beforeAcc = sequencerInboxAccs[sequencerInboxAccs.length - 1];
        }
        if (afterDelayedMessagesRead > 0) {
            delayedAcc = delayedInboxAccs[afterDelayedMessagesRead - 1];
        }
        acc = keccak256(abi.encodePacked(beforeAcc, dataHash, delayedAcc));
        sequencerInboxAccs.push(acc);
    }

    /// @inheritdoc IBridge
    function submitBatchSpendingReport(address sender, bytes32 messageDataHash)
        external
        onlySequencerInbox
        returns (uint256)
    {
        return
            addMessageToDelayedAccumulator(
                L1MessageType_batchPostingReport,
                sender,
                uint64(block.number),
                uint64(block.timestamp), // solhint-disable-line not-rely-on-time,
                block.basefee,
                messageDataHash
            );
    }

    /// @inheritdoc IBridge
    function enqueueDelayedMessage(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) external payable returns (uint256) {
        if (!allowedDelayedInboxesMap[msg.sender].allowed) revert NotDelayedInbox(msg.sender);
        return
            addMessageToDelayedAccumulator(
                kind,
                sender,
                uint64(block.number),
                uint64(block.timestamp), // solhint-disable-line not-rely-on-time
                block.basefee,
                messageDataHash
            );
    }

    function addMessageToDelayedAccumulator(
        uint8 kind,
        address sender,
        uint64 blockNumber,
        uint64 blockTimestamp,
        uint256 baseFeeL1,
        bytes32 messageDataHash
    ) internal returns (uint256) {
        uint256 count = delayedInboxAccs.length;
        bytes32 messageHash = Messages.messageHash(
            kind,
            sender,
            blockNumber,
            blockTimestamp,
            count,
            baseFeeL1,
            messageDataHash
        );
        bytes32 prevAcc = 0;
        if (count > 0) {
            prevAcc = delayedInboxAccs[count - 1];
        }
        delayedInboxAccs.push(Messages.accumulateInboxMessage(prevAcc, messageHash));
        emit MessageDelivered(
            count,
            prevAcc,
            msg.sender,
            kind,
            sender,
            messageDataHash,
            baseFeeL1,
            blockTimestamp
        );
        return count;
    }

    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success, bytes memory returnData) {
        if (!allowedOutboxesMap[msg.sender].allowed) revert NotOutbox(msg.sender);
        if (data.length > 0 && !to.isContract()) revert NotContract(to);
        address prevOutbox = _activeOutbox;
        _activeOutbox = msg.sender;
        // We set and reset active outbox around external call so activeOutbox remains valid during call

        // We use a low level call here since we want to bubble up whether it succeeded or failed to the caller
        // rather than reverting on failure as well as allow contract and non-contract calls
        // solhint-disable-next-line avoid-low-level-calls
        (success, returnData) = to.call{value: value}(data);
        _activeOutbox = prevOutbox;
        emit BridgeCallTriggered(msg.sender, to, value, data);
    }

    function setSequencerInbox(address _sequencerInbox) external onlyRollupOrOwner {
        sequencerInbox = _sequencerInbox;
        emit SequencerInboxUpdated(_sequencerInbox);
    }

    function setDelayedInbox(address inbox, bool enabled) external onlyRollupOrOwner {
        InOutInfo storage info = allowedDelayedInboxesMap[inbox];
        bool alreadyEnabled = info.allowed;
        emit InboxToggle(inbox, enabled);
        if ((alreadyEnabled && enabled) || (!alreadyEnabled && !enabled)) {
            return;
        }
        if (enabled) {
            allowedDelayedInboxesMap[inbox] = InOutInfo(allowedDelayedInboxList.length, true);
            allowedDelayedInboxList.push(inbox);
        } else {
            allowedDelayedInboxList[info.index] = allowedDelayedInboxList[
                allowedDelayedInboxList.length - 1
            ];
            allowedDelayedInboxesMap[allowedDelayedInboxList[info.index]].index = info.index;
            allowedDelayedInboxList.pop();
            delete allowedDelayedInboxesMap[inbox];
        }
    }

    function setOutbox(address outbox, bool enabled) external onlyRollupOrOwner {
        if (outbox == EMPTY_ACTIVEOUTBOX) revert InvalidOutboxSet(outbox);

        InOutInfo storage info = allowedOutboxesMap[outbox];
        bool alreadyEnabled = info.allowed;
        emit OutboxToggle(outbox, enabled);
        if ((alreadyEnabled && enabled) || (!alreadyEnabled && !enabled)) {
            return;
        }
        if (enabled) {
            allowedOutboxesMap[outbox] = InOutInfo(allowedOutboxList.length, true);
            allowedOutboxList.push(outbox);
        } else {
            allowedOutboxList[info.index] = allowedOutboxList[allowedOutboxList.length - 1];
            allowedOutboxesMap[allowedOutboxList[info.index]].index = info.index;
            allowedOutboxList.pop();
            delete allowedOutboxesMap[outbox];
        }
    }

    function setSequencerReportedSubMessageCount(uint256 newMsgCount) external onlyRollupOrOwner {
        sequencerReportedSubMessageCount = newMsgCount;
    }

    function delayedMessageCount() external view override returns (uint256) {
        return delayedInboxAccs.length;
    }

    function sequencerMessageCount() external view returns (uint256) {
        return sequencerInboxAccs.length;
    }

    /// @dev For the classic -> nitro migration. TODO: remove post-migration.
    function acceptFundsFromOldBridge() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

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

/// @dev Thrown when an un-authorized address tries to access an admin function
/// @param sender The un-authorized sender
/// @param rollup The rollup, which would be authorized
/// @param owner The rollup's owner, which would be authorized
error NotRollupOrOwner(address sender, address rollup, address owner);

// Bridge Errors

/// @dev Thrown when an un-authorized address tries to access an only-inbox function
/// @param sender The un-authorized sender
error NotDelayedInbox(address sender);

/// @dev Thrown when an un-authorized address tries to access an only-sequencer-inbox function
/// @param sender The un-authorized sender
error NotSequencerInbox(address sender);

/// @dev Thrown when an un-authorized address tries to access an only-outbox function
/// @param sender The un-authorized sender
error NotOutbox(address sender);

/// @dev the provided outbox address isn't valid
/// @param outbox address of outbox being set
error InvalidOutboxSet(address outbox);

// Inbox Errors

/// @dev The contract is paused, so cannot be paused
error AlreadyPaused();

/// @dev The contract is unpaused, so cannot be unpaused
error AlreadyUnpaused();

/// @dev The contract is paused
error Paused();

/// @dev msg.value sent to the inbox isn't high enough
error InsufficientValue(uint256 expected, uint256 actual);

/// @dev submission cost provided isn't enough to create retryable ticket
error InsufficientSubmissionCost(uint256 expected, uint256 actual);

/// @dev address not allowed to interact with the given contract
error NotAllowedOrigin(address origin);

/// @dev used to convey retryable tx data in eth calls without requiring a tx trace
/// this follows a pattern similar to EIP-3668 where reverts surface call information
error RetryableData(
    address from,
    address to,
    uint256 l2CallValue,
    uint256 deposit,
    uint256 maxSubmissionCost,
    address excessFeeRefundAddress,
    address callValueRefundAddress,
    uint256 gasLimit,
    uint256 maxFeePerGas,
    bytes data
);

/// @dev Thrown when a L1 chainId fork is detected
error L1Forked();

/// @dev Thrown when a L1 chainId fork is not detected
error NotForked();

// Outbox Errors

/// @dev The provided proof was too long
/// @param proofLength The length of the too-long proof
error ProofTooLong(uint256 proofLength);

/// @dev The output index was greater than the maximum
/// @param index The output index
/// @param maxIndex The max the index could be
error PathNotMinimal(uint256 index, uint256 maxIndex);

/// @dev The calculated root does not exist
/// @param root The calculated root
error UnknownRoot(bytes32 root);

/// @dev The record has already been spent
/// @param index The index of the spent record
error AlreadySpent(uint256 index);

/// @dev A call to the bridge failed with no return data
error BridgeCallFailed();

// Sequencer Inbox Errors

/// @dev Thrown when someone attempts to read fewer messages than have already been read
error DelayedBackwards();

/// @dev Thrown when someone attempts to read more messages than exist
error DelayedTooFar();

/// @dev Force include can only read messages more blocks old than the delay period
error ForceIncludeBlockTooSoon();

/// @dev Force include can only read messages more seconds old than the delay period
error ForceIncludeTimeTooSoon();

/// @dev The message provided did not match the hash in the delayed inbox
error IncorrectMessagePreimage();

/// @dev This can only be called by the batch poster
error NotBatchPoster();

/// @dev The sequence number provided to this message was inconsistent with the number of batches already included
error BadSequencerNumber(uint256 stored, uint256 received);

/// @dev The sequence message number provided to this message was inconsistent with the previous one
error BadSequencerMessageNumber(uint256 stored, uint256 received);

/// @dev The batch data has the inbox authenticated bit set, but the batch data was not authenticated by the inbox
error DataNotAuthenticated();

/// @dev Tried to create an already valid Data Availability Service keyset
error AlreadyValidDASKeyset(bytes32);

/// @dev Tried to use or invalidate an already invalid Data Availability Service keyset
error NoSuchKeyset(bytes32);

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

uint8 constant L2_MSG = 3;
uint8 constant L1MessageType_L2FundedByL1 = 7;
uint8 constant L1MessageType_submitRetryableTx = 9;
uint8 constant L1MessageType_ethDeposit = 12;
uint8 constant L1MessageType_batchPostingReport = 13;
uint8 constant L2MessageType_unsignedEOATx = 0;
uint8 constant L2MessageType_unsignedContractTx = 1;

uint8 constant ROLLUP_PROTOCOL_EVENT_TYPE = 8;
uint8 constant INITIALIZATION_MSG_TYPE = 11;

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

pragma solidity ^0.8.0;

import "../bridge/Bridge.sol";
import "../bridge/SequencerInbox.sol";
import "../bridge/ISequencerInbox.sol";
import "../bridge/Inbox.sol";
import "../bridge/Outbox.sol";
import "./RollupEventInbox.sol";

import "../bridge/IBridge.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract BridgeCreator is Ownable {
    Bridge public bridgeTemplate;
    SequencerInbox public sequencerInboxTemplate;
    Inbox public inboxTemplate;
    RollupEventInbox public rollupEventInboxTemplate;
    Outbox public outboxTemplate;

    event TemplatesUpdated();

    constructor() Ownable() {
        bridgeTemplate = new Bridge();
        sequencerInboxTemplate = new SequencerInbox();
        inboxTemplate = new Inbox();
        rollupEventInboxTemplate = new RollupEventInbox();
        outboxTemplate = new Outbox();
    }

    function updateTemplates(
        address _bridgeTemplate,
        address _sequencerInboxTemplate,
        address _inboxTemplate,
        address _rollupEventInboxTemplate,
        address _outboxTemplate
    ) external onlyOwner {
        bridgeTemplate = Bridge(_bridgeTemplate);
        sequencerInboxTemplate = SequencerInbox(_sequencerInboxTemplate);
        inboxTemplate = Inbox(_inboxTemplate);
        rollupEventInboxTemplate = RollupEventInbox(_rollupEventInboxTemplate);
        outboxTemplate = Outbox(_outboxTemplate);

        emit TemplatesUpdated();
    }

    struct CreateBridgeFrame {
        ProxyAdmin admin;
        Bridge bridge;
        SequencerInbox sequencerInbox;
        Inbox inbox;
        RollupEventInbox rollupEventInbox;
        Outbox outbox;
    }

    function createBridge(
        address adminProxy,
        address rollup,
        ISequencerInbox.MaxTimeVariation memory maxTimeVariation
    )
        external
        returns (
            Bridge,
            SequencerInbox,
            Inbox,
            RollupEventInbox,
            Outbox
        )
    {
        CreateBridgeFrame memory frame;
        {
            frame.bridge = Bridge(
                address(new TransparentUpgradeableProxy(address(bridgeTemplate), adminProxy, ""))
            );
            frame.sequencerInbox = SequencerInbox(
                address(
                    new TransparentUpgradeableProxy(address(sequencerInboxTemplate), adminProxy, "")
                )
            );
            frame.inbox = Inbox(
                address(new TransparentUpgradeableProxy(address(inboxTemplate), adminProxy, ""))
            );
            frame.rollupEventInbox = RollupEventInbox(
                address(
                    new TransparentUpgradeableProxy(
                        address(rollupEventInboxTemplate),
                        adminProxy,
                        ""
                    )
                )
            );
            frame.outbox = Outbox(
                address(new TransparentUpgradeableProxy(address(outboxTemplate), adminProxy, ""))
            );
        }

        frame.bridge.initialize(IOwnable(rollup));
        frame.sequencerInbox.initialize(IBridge(frame.bridge), maxTimeVariation);
        frame.inbox.initialize(IBridge(frame.bridge), ISequencerInbox(frame.sequencerInbox));
        frame.rollupEventInbox.initialize(IBridge(frame.bridge));
        frame.outbox.initialize(IBridge(frame.bridge));

        return (
            frame.bridge,
            frame.sequencerInbox,
            frame.inbox,
            frame.rollupEventInbox,
            frame.outbox
        );
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import {
    AlreadyInit,
    HadZeroInit,
    NotOrigin,
    DataTooLarge,
    NotRollup,
    DelayedBackwards,
    DelayedTooFar,
    ForceIncludeBlockTooSoon,
    ForceIncludeTimeTooSoon,
    IncorrectMessagePreimage,
    NotBatchPoster,
    BadSequencerNumber,
    DataNotAuthenticated,
    AlreadyValidDASKeyset,
    NoSuchKeyset,
    NotForked
} from "../libraries/Error.sol";
import "./IBridge.sol";
import "./IInbox.sol";
import "./ISequencerInbox.sol";
import "../rollup/IRollupLogic.sol";
import "./Messages.sol";

import {L1MessageType_batchPostingReport} from "../libraries/MessageTypes.sol";
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
    uint256 public totalDelayedMessagesRead;

    IBridge public bridge;

    /// @inheritdoc ISequencerInbox
    uint256 public constant HEADER_LENGTH = 40;

    /// @inheritdoc ISequencerInbox
    bytes1 public constant DATA_AUTHENTICATED_FLAG = 0x40;

    IOwnable public rollup;
    mapping(address => bool) public isBatchPoster;
    ISequencerInbox.MaxTimeVariation public maxTimeVariation;

    mapping(bytes32 => DasKeySetInfo) public dasKeySetInfo;

    modifier onlyRollupOwner() {
        if (msg.sender != rollup.owner()) revert NotOwner(msg.sender, address(rollup));
        _;
    }

    uint256 internal immutable deployTimeChainId = block.chainid;

    function _chainIdChanged() internal view returns (bool) {
        return deployTimeChainId != block.chainid;
    }

    function initialize(
        IBridge bridge_,
        ISequencerInbox.MaxTimeVariation calldata maxTimeVariation_
    ) external onlyDelegated {
        if (bridge != IBridge(address(0))) revert AlreadyInit();
        if (bridge_ == IBridge(address(0))) revert HadZeroInit();
        bridge = bridge_;
        rollup = bridge_.rollup();
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

    /// @inheritdoc ISequencerInbox
    function removeDelayAfterFork() external {
        if (!_chainIdChanged()) revert NotForked();
        maxTimeVariation = ISequencerInbox.MaxTimeVariation({
            delayBlocks: 1,
            futureBlocks: 1,
            delaySeconds: 1,
            futureSeconds: 1
        });
    }

    /// @inheritdoc ISequencerInbox
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
            prevDelayedAcc = bridge.delayedInboxAccs(_totalDelayedMessagesRead - 2);
        }
        if (
            bridge.delayedInboxAccs(_totalDelayedMessagesRead - 1) !=
            Messages.accumulateInboxMessage(prevDelayedAcc, messageHash)
        ) revert IncorrectMessagePreimage();

        (bytes32 dataHash, TimeBounds memory timeBounds) = formEmptyDataHash(
            _totalDelayedMessagesRead
        );
        uint256 __totalDelayedMessagesRead = _totalDelayedMessagesRead;
        uint256 prevSeqMsgCount = bridge.sequencerReportedSubMessageCount();
        uint256 newSeqMsgCount = prevSeqMsgCount +
            _totalDelayedMessagesRead -
            totalDelayedMessagesRead;
        (
            uint256 seqMessageIndex,
            bytes32 beforeAcc,
            bytes32 delayedAcc,
            bytes32 afterAcc
        ) = addSequencerL2BatchImpl(
                dataHash,
                __totalDelayedMessagesRead,
                0,
                prevSeqMsgCount,
                newSeqMsgCount
            );
        emit SequencerBatchDelivered(
            seqMessageIndex,
            beforeAcc,
            afterAcc,
            delayedAcc,
            totalDelayedMessagesRead,
            timeBounds,
            BatchDataLocation.NoData
        );
    }

    /// @dev Deprecated in favor of the variant specifying message counts for consistency
    function addSequencerL2BatchFromOrigin(
        uint256 sequenceNumber,
        bytes calldata data,
        uint256 afterDelayedMessagesRead,
        IGasRefunder gasRefunder
    ) external refundsGas(gasRefunder) {
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender != tx.origin) revert NotOrigin();
        if (!isBatchPoster[msg.sender]) revert NotBatchPoster();

        (bytes32 dataHash, TimeBounds memory timeBounds) = formDataHash(
            data,
            afterDelayedMessagesRead
        );
        (
            uint256 seqMessageIndex,
            bytes32 beforeAcc,
            bytes32 delayedAcc,
            bytes32 afterAcc
        ) = addSequencerL2BatchImpl(dataHash, afterDelayedMessagesRead, data.length, 0, 0);
        if (seqMessageIndex != sequenceNumber)
            revert BadSequencerNumber(seqMessageIndex, sequenceNumber);
        emit SequencerBatchDelivered(
            sequenceNumber,
            beforeAcc,
            afterAcc,
            delayedAcc,
            totalDelayedMessagesRead,
            timeBounds,
            BatchDataLocation.TxInput
        );
    }

    function addSequencerL2BatchFromOrigin(
        uint256 sequenceNumber,
        bytes calldata data,
        uint256 afterDelayedMessagesRead,
        IGasRefunder gasRefunder,
        uint256 prevMessageCount,
        uint256 newMessageCount
    ) external refundsGas(gasRefunder) {
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender != tx.origin) revert NotOrigin();
        if (!isBatchPoster[msg.sender]) revert NotBatchPoster();
        (bytes32 dataHash, TimeBounds memory timeBounds) = formDataHash(
            data,
            afterDelayedMessagesRead
        );
        // Reformat the stack to prevent "Stack too deep"
        uint256 sequenceNumber_ = sequenceNumber;
        TimeBounds memory timeBounds_ = timeBounds;
        bytes32 dataHash_ = dataHash;
        uint256 dataLength = data.length;
        uint256 afterDelayedMessagesRead_ = afterDelayedMessagesRead;
        uint256 prevMessageCount_ = prevMessageCount;
        uint256 newMessageCount_ = newMessageCount;
        (
            uint256 seqMessageIndex,
            bytes32 beforeAcc,
            bytes32 delayedAcc,
            bytes32 afterAcc
        ) = addSequencerL2BatchImpl(
                dataHash_,
                afterDelayedMessagesRead_,
                dataLength,
                prevMessageCount_,
                newMessageCount_
            );
        if (seqMessageIndex != sequenceNumber_ && sequenceNumber_ != ~uint256(0))
            revert BadSequencerNumber(seqMessageIndex, sequenceNumber_);
        emit SequencerBatchDelivered(
            seqMessageIndex,
            beforeAcc,
            afterAcc,
            delayedAcc,
            totalDelayedMessagesRead,
            timeBounds_,
            BatchDataLocation.TxInput
        );
    }

    function addSequencerL2Batch(
        uint256 sequenceNumber,
        bytes calldata data,
        uint256 afterDelayedMessagesRead,
        IGasRefunder gasRefunder,
        uint256 prevMessageCount,
        uint256 newMessageCount
    ) external override refundsGas(gasRefunder) {
        if (!isBatchPoster[msg.sender] && msg.sender != address(rollup)) revert NotBatchPoster();
        (bytes32 dataHash, TimeBounds memory timeBounds) = formDataHash(
            data,
            afterDelayedMessagesRead
        );
        uint256 seqMessageIndex;
        {
            // Reformat the stack to prevent "Stack too deep"
            uint256 sequenceNumber_ = sequenceNumber;
            TimeBounds memory timeBounds_ = timeBounds;
            bytes32 dataHash_ = dataHash;
            uint256 afterDelayedMessagesRead_ = afterDelayedMessagesRead;
            uint256 prevMessageCount_ = prevMessageCount;
            uint256 newMessageCount_ = newMessageCount;
            // we set the calldata length posted to 0 here since the caller isn't the origin
            // of the tx, so they might have not paid tx input cost for the calldata
            bytes32 beforeAcc;
            bytes32 delayedAcc;
            bytes32 afterAcc;
            (seqMessageIndex, beforeAcc, delayedAcc, afterAcc) = addSequencerL2BatchImpl(
                dataHash_,
                afterDelayedMessagesRead_,
                0,
                prevMessageCount_,
                newMessageCount_
            );
            if (seqMessageIndex != sequenceNumber_ && sequenceNumber_ != ~uint256(0))
                revert BadSequencerNumber(seqMessageIndex, sequenceNumber_);
            emit SequencerBatchDelivered(
                seqMessageIndex,
                beforeAcc,
                afterAcc,
                delayedAcc,
                totalDelayedMessagesRead,
                timeBounds_,
                BatchDataLocation.SeparateBatchEvent
            );
        }
        emit SequencerBatchData(seqMessageIndex, data);
    }

    modifier validateBatchData(bytes calldata data) {
        uint256 fullDataLen = HEADER_LENGTH + data.length;
        if (fullDataLen > MAX_DATA_SIZE) revert DataTooLarge(fullDataLen, MAX_DATA_SIZE);
        if (data.length > 0 && (data[0] & DATA_AUTHENTICATED_FLAG) == DATA_AUTHENTICATED_FLAG) {
            revert DataNotAuthenticated();
        }
        // the first byte is used to identify the type of batch data
        // das batches expect to have the type byte set, followed by the keyset (so they should have at least 33 bytes)
        if (data.length >= 33 && data[0] & 0x80 != 0) {
            // we skip the first byte, then read the next 32 bytes for the keyset
            bytes32 dasKeysetHash = bytes32(data[1:33]);
            if (!dasKeySetInfo[dasKeysetHash].isValidKeyset) revert NoSuchKeyset(dasKeysetHash);
        }
        _;
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
        validateBatchData(data)
        returns (bytes32, TimeBounds memory)
    {
        (bytes memory header, TimeBounds memory timeBounds) = packHeader(afterDelayedMessagesRead);
        bytes32 dataHash = keccak256(bytes.concat(header, data));
        return (dataHash, timeBounds);
    }

    function formEmptyDataHash(uint256 afterDelayedMessagesRead)
        internal
        view
        returns (bytes32, TimeBounds memory)
    {
        (bytes memory header, TimeBounds memory timeBounds) = packHeader(afterDelayedMessagesRead);
        return (keccak256(header), timeBounds);
    }

    function addSequencerL2BatchImpl(
        bytes32 dataHash,
        uint256 afterDelayedMessagesRead,
        uint256 calldataLengthPosted,
        uint256 prevMessageCount,
        uint256 newMessageCount
    )
        internal
        returns (
            uint256 seqMessageIndex,
            bytes32 beforeAcc,
            bytes32 delayedAcc,
            bytes32 acc
        )
    {
        if (afterDelayedMessagesRead < totalDelayedMessagesRead) revert DelayedBackwards();
        if (afterDelayedMessagesRead > bridge.delayedMessageCount()) revert DelayedTooFar();

        (seqMessageIndex, beforeAcc, delayedAcc, acc) = bridge.enqueueSequencerMessage(
            dataHash,
            afterDelayedMessagesRead,
            prevMessageCount,
            newMessageCount
        );

        totalDelayedMessagesRead = afterDelayedMessagesRead;

        if (calldataLengthPosted > 0) {
            // this msg isn't included in the current sequencer batch, but instead added to
            // the delayed messages queue that is yet to be included
            address batchPoster = msg.sender;
            bytes memory spendingReportMsg = abi.encodePacked(
                block.timestamp,
                batchPoster,
                dataHash,
                seqMessageIndex,
                block.basefee
            );
            uint256 msgNum = bridge.submitBatchSpendingReport(
                batchPoster,
                keccak256(spendingReportMsg)
            );
            // this is the same event used by Inbox.sol after including a message to the delayed message accumulator
            emit InboxMessageDelivered(msgNum, spendingReportMsg);
        }
    }

    function inboxAccs(uint256 index) external view returns (bytes32) {
        return bridge.sequencerInboxAccs(index);
    }

    function batchCount() external view returns (uint256) {
        return bridge.sequencerMessageCount();
    }

    /// @inheritdoc ISequencerInbox
    function setMaxTimeVariation(ISequencerInbox.MaxTimeVariation memory maxTimeVariation_)
        external
        onlyRollupOwner
    {
        maxTimeVariation = maxTimeVariation_;
        emit OwnerFunctionCalled(0);
    }

    /// @inheritdoc ISequencerInbox
    function setIsBatchPoster(address addr, bool isBatchPoster_) external onlyRollupOwner {
        isBatchPoster[addr] = isBatchPoster_;
        emit OwnerFunctionCalled(1);
    }

    /// @inheritdoc ISequencerInbox
    function setValidKeyset(bytes calldata keysetBytes) external onlyRollupOwner {
        uint256 ksWord = uint256(keccak256(bytes.concat(hex"fe", keccak256(keysetBytes))));
        bytes32 ksHash = bytes32(ksWord ^ (1 << 255));
        require(keysetBytes.length < 64 * 1024, "keyset is too large");

        if (dasKeySetInfo[ksHash].isValidKeyset) revert AlreadyValidDASKeyset(ksHash);
        dasKeySetInfo[ksHash] = DasKeySetInfo({
            isValidKeyset: true,
            creationBlock: uint64(block.number)
        });
        emit SetValidKeyset(ksHash, keysetBytes);
        emit OwnerFunctionCalled(2);
    }

    /// @inheritdoc ISequencerInbox
    function invalidateKeysetHash(bytes32 ksHash) external onlyRollupOwner {
        if (!dasKeySetInfo[ksHash].isValidKeyset) revert NoSuchKeyset(ksHash);
        // we don't delete the block creation value since its used to fetch the SetValidKeyset
        // event efficiently. The event provides the hash preimage of the key.
        // this is still needed when syncing the chain after a keyset is invalidated.
        dasKeySetInfo[ksHash].isValidKeyset = false;
        emit InvalidateKeyset(ksHash);
        emit OwnerFunctionCalled(3);
    }

    function isValidKeysetHash(bytes32 ksHash) external view returns (bool) {
        return dasKeySetInfo[ksHash].isValidKeyset;
    }

    /// @inheritdoc ISequencerInbox
    function getKeysetCreationBlock(bytes32 ksHash) external view returns (uint256) {
        DasKeySetInfo memory ksInfo = dasKeySetInfo[ksHash];
        if (ksInfo.creationBlock == 0) revert NoSuchKeyset(ksHash);
        return uint256(ksInfo.creationBlock);
    }
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

pragma solidity ^0.8.4;

import {
    AlreadyInit,
    NotOrigin,
    DataTooLarge,
    AlreadyPaused,
    AlreadyUnpaused,
    Paused,
    InsufficientValue,
    InsufficientSubmissionCost,
    NotAllowedOrigin,
    RetryableData,
    NotRollupOrOwner,
    L1Forked,
    NotForked
} from "../libraries/Error.sol";
import "./IInbox.sol";
import "./ISequencerInbox.sol";
import "./IBridge.sol";

import "./Messages.sol";
import "../libraries/AddressAliasHelper.sol";
import "../libraries/DelegateCallAware.sol";
import {
    L2_MSG,
    L1MessageType_L2FundedByL1,
    L1MessageType_submitRetryableTx,
    L1MessageType_ethDeposit,
    L2MessageType_unsignedEOATx,
    L2MessageType_unsignedContractTx
} from "../libraries/MessageTypes.sol";
import {MAX_DATA_SIZE} from "../libraries/Constants.sol";
import "../precompiles/ArbSys.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @title Inbox for user and contract originated messages
 * @notice Messages created via this inbox are enqueued in the delayed accumulator
 * to await inclusion in the SequencerInbox
 */
contract Inbox is DelegateCallAware, PausableUpgradeable, IInbox {
    IBridge public bridge;
    ISequencerInbox public sequencerInbox;

    /// ------------------------------------ allow list start ------------------------------------ ///

    bool public allowListEnabled;
    mapping(address => bool) public isAllowed;

    event AllowListAddressSet(address indexed user, bool val);
    event AllowListEnabledUpdated(bool isEnabled);

    function setAllowList(address[] memory user, bool[] memory val) external onlyRollupOrOwner {
        require(user.length == val.length, "INVALID_INPUT");

        for (uint256 i = 0; i < user.length; i++) {
            isAllowed[user[i]] = val[i];
            emit AllowListAddressSet(user[i], val[i]);
        }
    }

    function setAllowListEnabled(bool _allowListEnabled) external onlyRollupOrOwner {
        require(_allowListEnabled != allowListEnabled, "ALREADY_SET");
        allowListEnabled = _allowListEnabled;
        emit AllowListEnabledUpdated(_allowListEnabled);
    }

    /// @dev this modifier checks the tx.origin instead of msg.sender for convenience (ie it allows
    /// allowed users to interact with the token bridge without needing the token bridge to be allowList aware).
    /// this modifier is not intended to use to be used for security (since this opens the allowList to
    /// a smart contract phishing risk).
    modifier onlyAllowed() {
        // solhint-disable-next-line avoid-tx-origin
        if (allowListEnabled && !isAllowed[tx.origin]) revert NotAllowedOrigin(tx.origin);
        _;
    }

    /// ------------------------------------ allow list end ------------------------------------ ///

    modifier onlyRollupOrOwner() {
        IOwnable rollup = bridge.rollup();
        if (msg.sender != address(rollup)) {
            address rollupOwner = rollup.owner();
            if (msg.sender != rollupOwner) {
                revert NotRollupOrOwner(msg.sender, address(rollup), rollupOwner);
            }
        }
        _;
    }

    uint256 internal immutable deployTimeChainId = block.chainid;

    function _chainIdChanged() internal view returns (bool) {
        return deployTimeChainId != block.chainid;
    }

    /// @inheritdoc IInbox
    function pause() external onlyRollupOrOwner {
        _pause();
    }

    /// @inheritdoc IInbox
    function unpause() external onlyRollupOrOwner {
        _unpause();
    }

    function initialize(IBridge _bridge, ISequencerInbox _sequencerInbox)
        external
        initializer
        onlyDelegated
    {
        bridge = _bridge;
        sequencerInbox = _sequencerInbox;
        allowListEnabled = false;
        __Pausable_init();
    }

    /// @inheritdoc IInbox
    function postUpgradeInit(IBridge) external onlyDelegated onlyProxyOwner {}

    /// @inheritdoc IInbox
    function sendL2MessageFromOrigin(bytes calldata messageData)
        external
        whenNotPaused
        onlyAllowed
        returns (uint256)
    {
        if (_chainIdChanged()) revert L1Forked();
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender != tx.origin) revert NotOrigin();
        if (messageData.length > MAX_DATA_SIZE)
            revert DataTooLarge(messageData.length, MAX_DATA_SIZE);
        uint256 msgNum = deliverToBridge(L2_MSG, msg.sender, keccak256(messageData));
        emit InboxMessageDeliveredFromOrigin(msgNum);
        return msgNum;
    }

    /// @inheritdoc IInbox
    function sendL2Message(bytes calldata messageData)
        external
        whenNotPaused
        onlyAllowed
        returns (uint256)
    {
        if (_chainIdChanged()) revert L1Forked();
        return _deliverMessage(L2_MSG, msg.sender, messageData);
    }

    function sendL1FundedUnsignedTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        address to,
        bytes calldata data
    ) external payable whenNotPaused onlyAllowed returns (uint256) {
        return
            _deliverMessage(
                L1MessageType_L2FundedByL1,
                msg.sender,
                abi.encodePacked(
                    L2MessageType_unsignedEOATx,
                    gasLimit,
                    maxFeePerGas,
                    nonce,
                    uint256(uint160(to)),
                    msg.value,
                    data
                )
            );
    }

    function sendL1FundedContractTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        address to,
        bytes calldata data
    ) external payable whenNotPaused onlyAllowed returns (uint256) {
        return
            _deliverMessage(
                L1MessageType_L2FundedByL1,
                msg.sender,
                abi.encodePacked(
                    L2MessageType_unsignedContractTx,
                    gasLimit,
                    maxFeePerGas,
                    uint256(uint160(to)),
                    msg.value,
                    data
                )
            );
    }

    function sendUnsignedTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        address to,
        uint256 value,
        bytes calldata data
    ) external whenNotPaused onlyAllowed returns (uint256) {
        return
            _deliverMessage(
                L2_MSG,
                msg.sender,
                abi.encodePacked(
                    L2MessageType_unsignedEOATx,
                    gasLimit,
                    maxFeePerGas,
                    nonce,
                    uint256(uint160(to)),
                    value,
                    data
                )
            );
    }

    function sendContractTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        address to,
        uint256 value,
        bytes calldata data
    ) external whenNotPaused onlyAllowed returns (uint256) {
        return
            _deliverMessage(
                L2_MSG,
                msg.sender,
                abi.encodePacked(
                    L2MessageType_unsignedContractTx,
                    gasLimit,
                    maxFeePerGas,
                    uint256(uint160(to)),
                    value,
                    data
                )
            );
    }

    /// @inheritdoc IInbox
    function sendL1FundedUnsignedTransactionToFork(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        address to,
        bytes calldata data
    ) external payable whenNotPaused onlyAllowed returns (uint256) {
        if (!_chainIdChanged()) revert NotForked();
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender != tx.origin) revert NotOrigin();
        return
            _deliverMessage(
                L1MessageType_L2FundedByL1,
                // undoing sender alias here to cancel out the aliasing
                AddressAliasHelper.undoL1ToL2Alias(msg.sender),
                abi.encodePacked(
                    L2MessageType_unsignedEOATx,
                    gasLimit,
                    maxFeePerGas,
                    nonce,
                    uint256(uint160(to)),
                    msg.value,
                    data
                )
            );
    }

    /// @inheritdoc IInbox
    function sendUnsignedTransactionToFork(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        address to,
        uint256 value,
        bytes calldata data
    ) external whenNotPaused onlyAllowed returns (uint256) {
        if (!_chainIdChanged()) revert NotForked();
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender != tx.origin) revert NotOrigin();
        return
            _deliverMessage(
                L2_MSG,
                // undoing sender alias here to cancel out the aliasing
                AddressAliasHelper.undoL1ToL2Alias(msg.sender),
                abi.encodePacked(
                    L2MessageType_unsignedEOATx,
                    gasLimit,
                    maxFeePerGas,
                    nonce,
                    uint256(uint160(to)),
                    value,
                    data
                )
            );
    }

    /// @inheritdoc IInbox
    function sendWithdrawEthToFork(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        uint256 value,
        address withdrawTo
    ) external whenNotPaused onlyAllowed returns (uint256) {
        if (!_chainIdChanged()) revert NotForked();
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender != tx.origin) revert NotOrigin();
        return
            _deliverMessage(
                L2_MSG,
                // undoing sender alias here to cancel out the aliasing
                AddressAliasHelper.undoL1ToL2Alias(msg.sender),
                abi.encodePacked(
                    L2MessageType_unsignedEOATx,
                    gasLimit,
                    maxFeePerGas,
                    nonce,
                    uint256(uint160(address(100))), // ArbSys address
                    value,
                    abi.encode(ArbSys.withdrawEth.selector, withdrawTo)
                )
            );
    }

    /// @inheritdoc IInbox
    function calculateRetryableSubmissionFee(uint256 dataLength, uint256 baseFee)
        public
        view
        returns (uint256)
    {
        // Use current block basefee if baseFee parameter is 0
        return (1400 + 6 * dataLength) * (baseFee == 0 ? block.basefee : baseFee);
    }

    /// @inheritdoc IInbox
    function depositEth() public payable whenNotPaused onlyAllowed returns (uint256) {
        address dest = msg.sender;

        // solhint-disable-next-line avoid-tx-origin
        if (AddressUpgradeable.isContract(msg.sender) || tx.origin != msg.sender) {
            // isContract check fails if this function is called during a contract's constructor.
            dest = AddressAliasHelper.applyL1ToL2Alias(msg.sender);
        }

        return
            _deliverMessage(
                L1MessageType_ethDeposit,
                msg.sender,
                abi.encodePacked(dest, msg.value)
            );
    }

    /// @notice deprecated in favour of depositEth with no parameters
    function depositEth(uint256) external payable whenNotPaused onlyAllowed returns (uint256) {
        return depositEth();
    }

    /**
     * @notice deprecated in favour of unsafeCreateRetryableTicket
     * @dev deprecated in favour of unsafeCreateRetryableTicket
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
    function createRetryableTicketNoRefundAliasRewrite(
        address to,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        bytes calldata data
    ) external payable whenNotPaused onlyAllowed returns (uint256) {
        return
            unsafeCreateRetryableTicket(
                to,
                l2CallValue,
                maxSubmissionCost,
                excessFeeRefundAddress,
                callValueRefundAddress,
                gasLimit,
                maxFeePerGas,
                data
            );
    }

    /// @inheritdoc IInbox
    function createRetryableTicket(
        address to,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        bytes calldata data
    ) external payable whenNotPaused onlyAllowed returns (uint256) {
        // ensure the user's deposit alone will make submission succeed
        if (msg.value < (maxSubmissionCost + l2CallValue + gasLimit * maxFeePerGas)) {
            revert InsufficientValue(
                maxSubmissionCost + l2CallValue + gasLimit * maxFeePerGas,
                msg.value
            );
        }

        // if a refund address is a contract, we apply the alias to it
        // so that it can access its funds on the L2
        // since the beneficiary and other refund addresses don't get rewritten by arb-os
        if (AddressUpgradeable.isContract(excessFeeRefundAddress)) {
            excessFeeRefundAddress = AddressAliasHelper.applyL1ToL2Alias(excessFeeRefundAddress);
        }
        if (AddressUpgradeable.isContract(callValueRefundAddress)) {
            // this is the beneficiary. be careful since this is the address that can cancel the retryable in the L2
            callValueRefundAddress = AddressAliasHelper.applyL1ToL2Alias(callValueRefundAddress);
        }

        return
            unsafeCreateRetryableTicket(
                to,
                l2CallValue,
                maxSubmissionCost,
                excessFeeRefundAddress,
                callValueRefundAddress,
                gasLimit,
                maxFeePerGas,
                data
            );
    }

    /// @inheritdoc IInbox
    function unsafeCreateRetryableTicket(
        address to,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        bytes calldata data
    ) public payable whenNotPaused onlyAllowed returns (uint256) {
        // gas price and limit of 1 should never be a valid input, so instead they are used as
        // magic values to trigger a revert in eth calls that surface data without requiring a tx trace
        if (gasLimit == 1 || maxFeePerGas == 1)
            revert RetryableData(
                msg.sender,
                to,
                l2CallValue,
                msg.value,
                maxSubmissionCost,
                excessFeeRefundAddress,
                callValueRefundAddress,
                gasLimit,
                maxFeePerGas,
                data
            );

        uint256 submissionFee = calculateRetryableSubmissionFee(data.length, block.basefee);
        if (maxSubmissionCost < submissionFee)
            revert InsufficientSubmissionCost(submissionFee, maxSubmissionCost);

        return
            _deliverMessage(
                L1MessageType_submitRetryableTx,
                msg.sender,
                abi.encodePacked(
                    uint256(uint160(to)),
                    l2CallValue,
                    msg.value,
                    maxSubmissionCost,
                    uint256(uint160(excessFeeRefundAddress)),
                    uint256(uint160(callValueRefundAddress)),
                    gasLimit,
                    maxFeePerGas,
                    data.length,
                    data
                )
            );
    }

    function _deliverMessage(
        uint8 _kind,
        address _sender,
        bytes memory _messageData
    ) internal returns (uint256) {
        if (_messageData.length > MAX_DATA_SIZE)
            revert DataTooLarge(_messageData.length, MAX_DATA_SIZE);
        uint256 msgNum = deliverToBridge(_kind, _sender, keccak256(_messageData));
        emit InboxMessageDelivered(msgNum, _messageData);
        return msgNum;
    }

    function deliverToBridge(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) internal returns (uint256) {
        return
            bridge.enqueueDelayedMessage{value: msg.value}(
                kind,
                AddressAliasHelper.applyL1ToL2Alias(sender),
                messageDataHash
            );
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import {
    AlreadyInit,
    NotRollup,
    ProofTooLong,
    PathNotMinimal,
    UnknownRoot,
    AlreadySpent,
    BridgeCallFailed,
    HadZeroInit
} from "../libraries/Error.sol";
import "./IBridge.sol";
import "./IOutbox.sol";
import "../libraries/MerkleLib.sol";
import "../libraries/DelegateCallAware.sol";

/// @dev this error is thrown since certain functions are only expected to be used in simulations, not in actual txs
error SimulationOnlyEntrypoint();

contract Outbox is DelegateCallAware, IOutbox {
    address public rollup; // the rollup contract
    IBridge public bridge; // the bridge contract

    mapping(uint256 => bytes32) public spent; // packed spent bitmap
    mapping(bytes32 => bytes32) public roots; // maps root hashes => L2 block hash

    struct L2ToL1Context {
        uint128 l2Block;
        uint128 l1Block;
        uint128 timestamp;
        bytes32 outputId;
        address sender;
    }
    // Note, these variables are set and then wiped during a single transaction.
    // Therefore their values don't need to be maintained, and their slots will
    // be empty outside of transactions
    L2ToL1Context internal context;

    // default context values to be used in storage instead of zero, to save on storage refunds
    // it is assumed that arb-os never assigns these values to a valid leaf to be redeemed
    uint128 private constant L2BLOCK_DEFAULT_CONTEXT = type(uint128).max;
    uint128 private constant L1BLOCK_DEFAULT_CONTEXT = type(uint128).max;
    uint128 private constant TIMESTAMP_DEFAULT_CONTEXT = type(uint128).max;
    bytes32 private constant OUTPUTID_DEFAULT_CONTEXT = bytes32(type(uint256).max);
    address private constant SENDER_DEFAULT_CONTEXT = address(type(uint160).max);

    uint128 public constant OUTBOX_VERSION = 2;

    function initialize(IBridge _bridge) external onlyDelegated {
        if (address(_bridge) == address(0)) revert HadZeroInit();
        if (address(bridge) != address(0)) revert AlreadyInit();
        // address zero is returned if no context is set, but the values used in storage
        // are non-zero to save users some gas (as storage refunds are usually maxed out)
        // EIP-1153 would help here
        context = L2ToL1Context({
            l2Block: L2BLOCK_DEFAULT_CONTEXT,
            l1Block: L1BLOCK_DEFAULT_CONTEXT,
            timestamp: TIMESTAMP_DEFAULT_CONTEXT,
            outputId: OUTPUTID_DEFAULT_CONTEXT,
            sender: SENDER_DEFAULT_CONTEXT
        });
        bridge = _bridge;
        rollup = address(_bridge.rollup());
    }

    function updateSendRoot(bytes32 root, bytes32 l2BlockHash) external {
        if (msg.sender != rollup) revert NotRollup(msg.sender, rollup);
        roots[root] = l2BlockHash;
        emit SendRootUpdated(root, l2BlockHash);
    }

    /// @inheritdoc IOutbox
    function l2ToL1Sender() external view returns (address) {
        address sender = context.sender;
        // we don't return the default context value to avoid a breaking change in the API
        if (sender == SENDER_DEFAULT_CONTEXT) return address(0);
        return sender;
    }

    /// @inheritdoc IOutbox
    function l2ToL1Block() external view returns (uint256) {
        uint128 l2Block = context.l2Block;
        // we don't return the default context value to avoid a breaking change in the API
        if (l2Block == L1BLOCK_DEFAULT_CONTEXT) return uint256(0);
        return uint256(l2Block);
    }

    /// @inheritdoc IOutbox
    function l2ToL1EthBlock() external view returns (uint256) {
        uint128 l1Block = context.l1Block;
        // we don't return the default context value to avoid a breaking change in the API
        if (l1Block == L1BLOCK_DEFAULT_CONTEXT) return uint256(0);
        return uint256(l1Block);
    }

    /// @inheritdoc IOutbox
    function l2ToL1Timestamp() external view returns (uint256) {
        uint128 timestamp = context.timestamp;
        // we don't return the default context value to avoid a breaking change in the API
        if (timestamp == TIMESTAMP_DEFAULT_CONTEXT) return uint256(0);
        return uint256(timestamp);
    }

    /// @notice batch number is deprecated and now always returns 0
    function l2ToL1BatchNum() external pure returns (uint256) {
        return 0;
    }

    /// @inheritdoc IOutbox
    function l2ToL1OutputId() external view returns (bytes32) {
        bytes32 outputId = context.outputId;
        // we don't return the default context value to avoid a breaking change in the API
        if (outputId == OUTPUTID_DEFAULT_CONTEXT) return bytes32(0);
        return outputId;
    }

    /// @inheritdoc IOutbox
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
    ) external {
        bytes32 userTx = calculateItemHash(
            l2Sender,
            to,
            l2Block,
            l1Block,
            l2Timestamp,
            value,
            data
        );

        recordOutputAsSpent(proof, index, userTx);

        executeTransactionImpl(index, l2Sender, to, l2Block, l1Block, l2Timestamp, value, data);
    }

    /// @inheritdoc IOutbox
    function executeTransactionSimulation(
        uint256 index,
        address l2Sender,
        address to,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 value,
        bytes calldata data
    ) external {
        if (msg.sender != address(0)) revert SimulationOnlyEntrypoint();
        executeTransactionImpl(index, l2Sender, to, l2Block, l1Block, l2Timestamp, value, data);
    }

    function executeTransactionImpl(
        uint256 outputId,
        address l2Sender,
        address to,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 value,
        bytes calldata data
    ) internal {
        emit OutBoxTransactionExecuted(to, l2Sender, 0, outputId);

        // we temporarily store the previous values so the outbox can naturally
        // unwind itself when there are nested calls to `executeTransaction`
        L2ToL1Context memory prevContext = context;

        context = L2ToL1Context({
            sender: l2Sender,
            l2Block: uint128(l2Block),
            l1Block: uint128(l1Block),
            timestamp: uint128(l2Timestamp),
            outputId: bytes32(outputId)
        });

        // set and reset vars around execution so they remain valid during call
        executeBridgeCall(to, value, data);

        context = prevContext;
    }

    function _calcSpentIndexOffset(uint256 index)
        internal
        view
        returns (
            uint256,
            uint256,
            bytes32
        )
    {
        uint256 spentIndex = index / 255; // Note: Reserves the MSB.
        uint256 bitOffset = index % 255;
        bytes32 replay = spent[spentIndex];
        return (spentIndex, bitOffset, replay);
    }

    function _isSpent(uint256 bitOffset, bytes32 replay) internal pure returns (bool) {
        return ((replay >> bitOffset) & bytes32(uint256(1))) != bytes32(0);
    }

    /// @inheritdoc IOutbox
    function isSpent(uint256 index) external view returns (bool) {
        (, uint256 bitOffset, bytes32 replay) = _calcSpentIndexOffset(index);
        return _isSpent(bitOffset, replay);
    }

    function recordOutputAsSpent(
        bytes32[] memory proof,
        uint256 index,
        bytes32 item
    ) internal {
        if (proof.length >= 256) revert ProofTooLong(proof.length);
        if (index >= 2**proof.length) revert PathNotMinimal(index, 2**proof.length);

        // Hash the leaf an extra time to prove it's a leaf
        bytes32 calcRoot = calculateMerkleRoot(proof, index, item);
        if (roots[calcRoot] == bytes32(0)) revert UnknownRoot(calcRoot);

        (uint256 spentIndex, uint256 bitOffset, bytes32 replay) = _calcSpentIndexOffset(index);

        if (_isSpent(bitOffset, replay)) revert AlreadySpent(index);
        spent[spentIndex] = (replay | bytes32(1 << bitOffset));
    }

    function executeBridgeCall(
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        (bool success, bytes memory returndata) = bridge.executeCall(to, value, data);
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert BridgeCallFailed();
            }
        }
    }

    function calculateItemHash(
        address l2Sender,
        address to,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 value,
        bytes calldata data
    ) public pure returns (bytes32) {
        return
            keccak256(abi.encodePacked(l2Sender, to, l2Block, l1Block, l2Timestamp, value, data));
    }

    function calculateMerkleRoot(
        bytes32[] memory proof,
        uint256 path,
        bytes32 item
    ) public pure returns (bytes32) {
        return MerkleLib.calculateRoot(proof, path, keccak256(abi.encodePacked(item)));
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./IRollupEventInbox.sol";
import "../bridge/IBridge.sol";
import "../bridge/IDelayedMessageProvider.sol";
import "../libraries/DelegateCallAware.sol";
import {INITIALIZATION_MSG_TYPE} from "../libraries/MessageTypes.sol";
import {AlreadyInit, HadZeroInit} from "../libraries/Error.sol";

/**
 * @title The inbox for rollup protocol events
 */
contract RollupEventInbox is IRollupEventInbox, IDelayedMessageProvider, DelegateCallAware {
    IBridge public override bridge;
    address public override rollup;

    modifier onlyRollup() {
        require(msg.sender == rollup, "ONLY_ROLLUP");
        _;
    }

    function initialize(IBridge _bridge) external override onlyDelegated {
        if (address(bridge) != address(0)) revert AlreadyInit();
        if (address(_bridge) == address(0)) revert HadZeroInit();
        bridge = _bridge;
        rollup = address(_bridge.rollup());
    }

    function rollupInitialized(uint256 chainId) external override onlyRollup {
        bytes memory initMsg = abi.encodePacked(chainId);
        uint256 num = bridge.enqueueDelayedMessage(
            INITIALIZATION_MSG_TYPE,
            address(0),
            keccak256(initMsg)
        );
        emit InboxMessageDelivered(num, initMsg);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/transparent/ProxyAdmin.sol)

pragma solidity ^0.8.0;

import "./TransparentUpgradeableProxy.sol";
import "../../access/Ownable.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {
    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        TransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
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

pragma solidity ^0.8.0;

import "./RollupLib.sol";
import "./IRollupCore.sol";
import "../bridge/ISequencerInbox.sol";
import "../bridge/IOutbox.sol";
import "../bridge/IOwnable.sol";

interface IRollupUserAbs is IRollupCore, IOwnable {
    /// @dev the user logic just validated configuration and shouldn't write to state during init
    /// this allows the admin logic to ensure consistency on parameters.
    function initialize(address stakeToken) external view;

    function removeWhitelistAfterFork() external;

    function removeWhitelistAfterValidatorAfk() external;

    function isERC20Enabled() external view returns (bool);

    function rejectNextNode(address stakerAddress) external;

    function confirmNextNode(bytes32 blockHash, bytes32 sendRoot) external;

    function stakeOnExistingNode(uint64 nodeNum, bytes32 nodeHash) external;

    function stakeOnNewNode(
        RollupLib.Assertion memory assertion,
        bytes32 expectedNodeHash,
        uint256 prevNodeInboxMaxCount
    ) external;

    function returnOldDeposit(address stakerAddress) external;

    function reduceDeposit(uint256 target) external;

    function removeZombie(uint256 zombieNum, uint256 maxNodes) external;

    function removeOldZombies(uint256 startIndex) external;

    function requiredStake(
        uint256 blockNumber,
        uint64 firstUnresolvedNodeNum,
        uint64 latestCreatedNode
    ) external view returns (uint256);

    function currentRequiredStake() external view returns (uint256);

    function countStakedZombies(uint64 nodeNum) external view returns (uint256);

    function countZombiesStakedOnChildren(uint64 nodeNum) external view returns (uint256);

    function requireUnresolvedExists() external view;

    function requireUnresolved(uint256 nodeNum) external view;

    function withdrawStakerFunds() external returns (uint256);

    function createChallenge(
        address[2] calldata stakers,
        uint64[2] calldata nodeNums,
        MachineStatus[2] calldata machineStatuses,
        GlobalState[2] calldata globalStates,
        uint64 numBlocks,
        bytes32 secondExecutionHash,
        uint256[2] calldata proposedTimes,
        bytes32[2] calldata wasmModuleRoots
    ) external;
}

interface IRollupUser is IRollupUserAbs {
    function newStakeOnExistingNode(uint64 nodeNum, bytes32 nodeHash) external payable;

    function newStakeOnNewNode(
        RollupLib.Assertion calldata assertion,
        bytes32 expectedNodeHash,
        uint256 prevNodeInboxMaxCount
    ) external payable;

    function addToDeposit(address stakerAddress) external payable;
}

interface IRollupUserERC20 is IRollupUserAbs {
    function newStakeOnExistingNode(
        uint256 tokenAmount,
        uint64 nodeNum,
        bytes32 nodeHash
    ) external;

    function newStakeOnNewNode(
        uint256 tokenAmount,
        RollupLib.Assertion calldata assertion,
        bytes32 expectedNodeHash,
        uint256 prevNodeInboxMaxCount
    ) external;

    function addToDeposit(address stakerAddress, uint256 tokenAmount) external;
}

interface IRollupAdmin {
    event OwnerFunctionCalled(uint256 indexed id);

    function initialize(Config calldata config, ContractDependencies calldata connectedContracts)
        external;

    /**
     * @notice Add a contract authorized to put messages into this rollup's inbox
     * @param _outbox Outbox contract to add
     */
    function setOutbox(IOutbox _outbox) external;

    /**
     * @notice Disable an old outbox from interacting with the bridge
     * @param _outbox Outbox contract to remove
     */
    function removeOldOutbox(address _outbox) external;

    /**
     * @notice Enable or disable an inbox contract
     * @param _inbox Inbox contract to add or remove
     * @param _enabled New status of inbox
     */
    function setDelayedInbox(address _inbox, bool _enabled) external;

    /**
     * @notice Pause interaction with the rollup contract
     */
    function pause() external;

    /**
     * @notice Resume interaction with the rollup contract
     */
    function resume() external;

    /**
     * @notice Set the addresses of the validator whitelist
     * @dev It is expected that both arrays are same length, and validator at
     * position i corresponds to the value at position i
     * @param _validator addresses to set in the whitelist
     * @param _val value to set in the whitelist for corresponding address
     */
    function setValidator(address[] memory _validator, bool[] memory _val) external;

    /**
     * @notice Set a new owner address for the rollup proxy
     * @param newOwner address of new rollup owner
     */
    function setOwner(address newOwner) external;

    /**
     * @notice Set minimum assertion period for the rollup
     * @param newPeriod new minimum period for assertions
     */
    function setMinimumAssertionPeriod(uint256 newPeriod) external;

    /**
     * @notice Set number of blocks until a node is considered confirmed
     * @param newConfirmPeriod new number of blocks until a node is confirmed
     */
    function setConfirmPeriodBlocks(uint64 newConfirmPeriod) external;

    /**
     * @notice Set number of extra blocks after a challenge
     * @param newExtraTimeBlocks new number of blocks
     */
    function setExtraChallengeTimeBlocks(uint64 newExtraTimeBlocks) external;

    /**
     * @notice Set base stake required for an assertion
     * @param newBaseStake maximum avmgas to be used per block
     */
    function setBaseStake(uint256 newBaseStake) external;

    /**
     * @notice Set the token used for stake, where address(0) == eth
     * @dev Before changing the base stake token, you might need to change the
     * implementation of the Rollup User logic!
     * @param newStakeToken address of token used for staking
     */
    function setStakeToken(address newStakeToken) external;

    /**
     * @notice Upgrades the implementation of a beacon controlled by the rollup
     * @param beacon address of beacon to be upgraded
     * @param newImplementation new address of implementation
     */
    function upgradeBeacon(address beacon, address newImplementation) external;

    function forceResolveChallenge(address[] memory stackerA, address[] memory stackerB) external;

    function forceRefundStaker(address[] memory stacker) external;

    function forceCreateNode(
        uint64 prevNode,
        uint256 prevNodeInboxMaxCount,
        RollupLib.Assertion memory assertion,
        bytes32 expectedNodeHash
    ) external;

    function forceConfirmNode(
        uint64 nodeNum,
        bytes32 blockHash,
        bytes32 sendRoot
    ) external;

    function setLoserStakeEscrow(address newLoserStakerEscrow) external;

    /**
     * @notice Set the proving WASM module root
     * @param newWasmModuleRoot new module root
     */
    function setWasmModuleRoot(bytes32 newWasmModuleRoot) external;

    /**
     * @notice set a new sequencer inbox contract
     * @param _sequencerInbox new address of sequencer inbox
     */
    function setSequencerInbox(address _sequencerInbox) external;

    /**
     * @notice set the validatorWhitelistDisabled flag
     * @param _validatorWhitelistDisabled new value of validatorWhitelistDisabled, i.e. true = disabled
     */
    function setValidatorWhitelistDisabled(bool _validatorWhitelistDisabled) external;
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
            uint256 calldataSize = 0;
            // if triggered in a contract call, the spender may be overrefunded by appending dummy data to the call
            // so we check if it is a top level call, which would mean the sender paid calldata as part of tx.input
            // solhint-disable-next-line avoid-tx-origin
            if (msg.sender == tx.origin) {
                assembly {
                    calldataSize := calldatasize()
                }
            }
            gasRefunder.onGasSpent(payable(msg.sender), startGasLeft - gasleft(), calldataSize);
        }
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

pragma solidity ^0.8.0;

import "../challenge/IChallengeManager.sol";
import "../challenge/ChallengeLib.sol";
import "../state/GlobalState.sol";
import "../bridge/ISequencerInbox.sol";

import "../bridge/IBridge.sol";
import "../bridge/IOutbox.sol";
import "../bridge/IInbox.sol";
import "./IRollupEventInbox.sol";
import "./IRollupLogic.sol";

struct Config {
    uint64 confirmPeriodBlocks;
    uint64 extraChallengeTimeBlocks;
    address stakeToken;
    uint256 baseStake;
    bytes32 wasmModuleRoot;
    address owner;
    address loserStakeEscrow;
    uint256 chainId;
    uint64 genesisBlockNum;
    ISequencerInbox.MaxTimeVariation sequencerInboxMaxTimeVariation;
}

struct ContractDependencies {
    IBridge bridge;
    ISequencerInbox sequencerInbox;
    IInbox inbox;
    IOutbox outbox;
    IRollupEventInbox rollupEventInbox;
    IChallengeManager challengeManager;
    IRollupAdmin rollupAdminLogic;
    IRollupUser rollupUserLogic;
    // misc contracts that are useful when interacting with the rollup
    address validatorUtils;
    address validatorWalletCreator;
}

library RollupLib {
    using GlobalStateLib for GlobalState;

    struct ExecutionState {
        GlobalState globalState;
        MachineStatus machineStatus;
    }

    function stateHash(ExecutionState calldata execState, uint256 inboxMaxCount)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    execState.globalState.hash(),
                    inboxMaxCount,
                    execState.machineStatus
                )
            );
    }

    /// @dev same as stateHash but expects execState in memory instead of calldata
    function stateHashMem(ExecutionState memory execState, uint256 inboxMaxCount)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    execState.globalState.hash(),
                    inboxMaxCount,
                    execState.machineStatus
                )
            );
    }

    struct Assertion {
        ExecutionState beforeState;
        ExecutionState afterState;
        uint64 numBlocks;
    }

    function executionHash(Assertion memory assertion) internal pure returns (bytes32) {
        MachineStatus[2] memory statuses;
        statuses[0] = assertion.beforeState.machineStatus;
        statuses[1] = assertion.afterState.machineStatus;
        GlobalState[2] memory globalStates;
        globalStates[0] = assertion.beforeState.globalState;
        globalStates[1] = assertion.afterState.globalState;
        // TODO: benchmark how much this abstraction adds of gas overhead
        return executionHash(statuses, globalStates, assertion.numBlocks);
    }

    function executionHash(
        MachineStatus[2] memory statuses,
        GlobalState[2] memory globalStates,
        uint64 numBlocks
    ) internal pure returns (bytes32) {
        bytes32[] memory segments = new bytes32[](2);
        segments[0] = ChallengeLib.blockStateHash(statuses[0], globalStates[0].hash());
        segments[1] = ChallengeLib.blockStateHash(statuses[1], globalStates[1].hash());
        return ChallengeLib.hashChallengeState(0, numBlocks, segments);
    }

    function challengeRootHash(
        bytes32 execution,
        uint256 proposedTime,
        bytes32 wasmModuleRoot
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(execution, proposedTime, wasmModuleRoot));
    }

    function confirmHash(Assertion memory assertion) internal pure returns (bytes32) {
        return
            confirmHash(
                assertion.afterState.globalState.getBlockHash(),
                assertion.afterState.globalState.getSendRoot()
            );
    }

    function confirmHash(bytes32 blockHash, bytes32 sendRoot) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(blockHash, sendRoot));
    }

    function nodeHash(
        bool hasSibling,
        bytes32 lastHash,
        bytes32 assertionExecHash,
        bytes32 inboxAcc,
        bytes32 wasmModuleRoot
    ) internal pure returns (bytes32) {
        uint8 hasSiblingInt = hasSibling ? 1 : 0;
        return
            keccak256(
                abi.encodePacked(
                    hasSiblingInt,
                    lastHash,
                    assertionExecHash,
                    inboxAcc,
                    wasmModuleRoot
                )
            );
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./Node.sol";
import "./RollupLib.sol";

interface IRollupCore {
    struct Staker {
        uint256 amountStaked;
        uint64 index;
        uint64 latestStakedNode;
        // currentChallenge is 0 if staker is not in a challenge
        uint64 currentChallenge;
        bool isStaked;
    }

    event RollupInitialized(bytes32 machineHash, uint256 chainId);

    event NodeCreated(
        uint64 indexed nodeNum,
        bytes32 indexed parentNodeHash,
        bytes32 indexed nodeHash,
        bytes32 executionHash,
        RollupLib.Assertion assertion,
        bytes32 afterInboxBatchAcc,
        bytes32 wasmModuleRoot,
        uint256 inboxMaxCount
    );

    event NodeConfirmed(uint64 indexed nodeNum, bytes32 blockHash, bytes32 sendRoot);

    event NodeRejected(uint64 indexed nodeNum);

    event RollupChallengeStarted(
        uint64 indexed challengeIndex,
        address asserter,
        address challenger,
        uint64 challengedNode
    );

    event UserStakeUpdated(address indexed user, uint256 initialBalance, uint256 finalBalance);

    event UserWithdrawableFundsUpdated(
        address indexed user,
        uint256 initialBalance,
        uint256 finalBalance
    );

    function confirmPeriodBlocks() external view returns (uint64);

    function extraChallengeTimeBlocks() external view returns (uint64);

    function chainId() external view returns (uint256);

    function baseStake() external view returns (uint256);

    function wasmModuleRoot() external view returns (bytes32);

    function bridge() external view returns (IBridge);

    function sequencerInbox() external view returns (ISequencerInbox);

    function outbox() external view returns (IOutbox);

    function rollupEventInbox() external view returns (IRollupEventInbox);

    function challengeManager() external view returns (IChallengeManager);

    function loserStakeEscrow() external view returns (address);

    function stakeToken() external view returns (address);

    function minimumAssertionPeriod() external view returns (uint256);

    function isValidator(address) external view returns (bool);

    function validatorWhitelistDisabled() external view returns (bool);

    /**
     * @notice Get the Node for the given index.
     */
    function getNode(uint64 nodeNum) external view returns (Node memory);

    /**
     * @notice Check if the specified node has been staked on by the provided staker.
     * Only accurate at the latest confirmed node and afterwards.
     */
    function nodeHasStaker(uint64 nodeNum, address staker) external view returns (bool);

    /**
     * @notice Get the address of the staker at the given index
     * @param stakerNum Index of the staker
     * @return Address of the staker
     */
    function getStakerAddress(uint64 stakerNum) external view returns (address);

    /**
     * @notice Check whether the given staker is staked
     * @param staker Staker address to check
     * @return True or False for whether the staker was staked
     */
    function isStaked(address staker) external view returns (bool);

    /**
     * @notice Get the latest staked node of the given staker
     * @param staker Staker address to lookup
     * @return Latest node staked of the staker
     */
    function latestStakedNode(address staker) external view returns (uint64);

    /**
     * @notice Get the current challenge of the given staker
     * @param staker Staker address to lookup
     * @return Current challenge of the staker
     */
    function currentChallenge(address staker) external view returns (uint64);

    /**
     * @notice Get the amount staked of the given staker
     * @param staker Staker address to lookup
     * @return Amount staked of the staker
     */
    function amountStaked(address staker) external view returns (uint256);

    /**
     * @notice Retrieves stored information about a requested staker
     * @param staker Staker address to retrieve
     * @return A structure with information about the requested staker
     */
    function getStaker(address staker) external view returns (Staker memory);

    /**
     * @notice Get the original staker address of the zombie at the given index
     * @param zombieNum Index of the zombie to lookup
     * @return Original staker address of the zombie
     */
    function zombieAddress(uint256 zombieNum) external view returns (address);

    /**
     * @notice Get Latest node that the given zombie at the given index is staked on
     * @param zombieNum Index of the zombie to lookup
     * @return Latest node that the given zombie is staked on
     */
    function zombieLatestStakedNode(uint256 zombieNum) external view returns (uint64);

    /// @return Current number of un-removed zombies
    function zombieCount() external view returns (uint256);

    function isZombie(address staker) external view returns (bool);

    /**
     * @notice Get the amount of funds withdrawable by the given address
     * @param owner Address to check the funds of
     * @return Amount of funds withdrawable by owner
     */
    function withdrawableFunds(address owner) external view returns (uint256);

    /**
     * @return Index of the first unresolved node
     * @dev If all nodes have been resolved, this will be latestNodeCreated + 1
     */
    function firstUnresolvedNode() external view returns (uint64);

    /// @return Index of the latest confirmed node
    function latestConfirmed() external view returns (uint64);

    /// @return Index of the latest rollup node created
    function latestNodeCreated() external view returns (uint64);

    /// @return Ethereum block that the most recent stake was created
    function lastStakeBlock() external view returns (uint64);

    /// @return Number of active stakers currently staked
    function stakerCount() external view returns (uint64);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

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

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../state/Machine.sol";
import "../bridge/IBridge.sol";
import "../bridge/ISequencerInbox.sol";
import "../osp/IOneStepProofEntry.sol";

import "./IChallengeResultReceiver.sol";

import "./ChallengeLib.sol";

interface IChallengeManager {
    enum ChallengeTerminationType {
        TIMEOUT,
        BLOCK_PROOF,
        EXECUTION_PROOF,
        CLEARED
    }

    event InitiatedChallenge(
        uint64 indexed challengeIndex,
        GlobalState startState,
        GlobalState endState
    );

    event Bisected(
        uint64 indexed challengeIndex,
        bytes32 indexed challengeRoot,
        uint256 challengedSegmentStart,
        uint256 challengedSegmentLength,
        bytes32[] chainHashes
    );

    event ExecutionChallengeBegun(uint64 indexed challengeIndex, uint256 blockSteps);
    event OneStepProofCompleted(uint64 indexed challengeIndex);

    event ChallengeEnded(uint64 indexed challengeIndex, ChallengeTerminationType kind);

    function initialize(
        IChallengeResultReceiver resultReceiver_,
        ISequencerInbox sequencerInbox_,
        IBridge bridge_,
        IOneStepProofEntry osp_
    ) external;

    function createChallenge(
        bytes32 wasmModuleRoot_,
        MachineStatus[2] calldata startAndEndMachineStatuses_,
        GlobalState[2] calldata startAndEndGlobalStates_,
        uint64 numBlocks,
        address asserter_,
        address challenger_,
        uint256 asserterTimeLeft_,
        uint256 challengerTimeLeft_
    ) external returns (uint64);

    function challengeInfo(uint64 challengeIndex_)
        external
        view
        returns (ChallengeLib.Challenge memory);

    function currentResponder(uint64 challengeIndex) external view returns (address);

    function isTimedOut(uint64 challengeIndex) external view returns (bool);

    function currentResponderTimeLeft(uint64 challengeIndex_) external view returns (uint256);

    function clearChallenge(uint64 challengeIndex_) external;

    function timeout(uint64 challengeIndex_) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../state/Machine.sol";
import "../state/GlobalState.sol";

library ChallengeLib {
    using MachineLib for Machine;
    using ChallengeLib for Challenge;

    /// @dev It's assumed that that uninitialzed challenges have mode NONE
    enum ChallengeMode {
        NONE,
        BLOCK,
        EXECUTION
    }

    struct Participant {
        address addr;
        uint256 timeLeft;
    }

    struct Challenge {
        Participant current;
        Participant next;
        uint256 lastMoveTimestamp;
        bytes32 wasmModuleRoot;
        bytes32 challengeStateHash;
        uint64 maxInboxMessages;
        ChallengeMode mode;
    }

    struct SegmentSelection {
        uint256 oldSegmentsStart;
        uint256 oldSegmentsLength;
        bytes32[] oldSegments;
        uint256 challengePosition;
    }

    function timeUsedSinceLastMove(Challenge storage challenge) internal view returns (uint256) {
        return block.timestamp - challenge.lastMoveTimestamp;
    }

    function isTimedOut(Challenge storage challenge) internal view returns (bool) {
        return challenge.timeUsedSinceLastMove() > challenge.current.timeLeft;
    }

    function getStartMachineHash(bytes32 globalStateHash, bytes32 wasmModuleRoot)
        internal
        pure
        returns (bytes32)
    {
        // Start the value stack with the function call ABI for the entrypoint
        Value[] memory startingValues = new Value[](3);
        startingValues[0] = ValueLib.newRefNull();
        startingValues[1] = ValueLib.newI32(0);
        startingValues[2] = ValueLib.newI32(0);
        ValueArray memory valuesArray = ValueArray({inner: startingValues});
        ValueStack memory values = ValueStack({proved: valuesArray, remainingHash: 0});
        ValueStack memory internalStack;
        StackFrameWindow memory frameStack;

        Machine memory mach = Machine({
            status: MachineStatus.RUNNING,
            valueStack: values,
            internalStack: internalStack,
            frameStack: frameStack,
            globalStateHash: globalStateHash,
            moduleIdx: 0,
            functionIdx: 0,
            functionPc: 0,
            modulesRoot: wasmModuleRoot
        });
        return mach.hash();
    }

    function getEndMachineHash(MachineStatus status, bytes32 globalStateHash)
        internal
        pure
        returns (bytes32)
    {
        if (status == MachineStatus.FINISHED) {
            return keccak256(abi.encodePacked("Machine finished:", globalStateHash));
        } else if (status == MachineStatus.ERRORED) {
            return keccak256(abi.encodePacked("Machine errored:"));
        } else if (status == MachineStatus.TOO_FAR) {
            return keccak256(abi.encodePacked("Machine too far:"));
        } else {
            revert("BAD_BLOCK_STATUS");
        }
    }

    function extractChallengeSegment(SegmentSelection calldata selection)
        internal
        pure
        returns (uint256 segmentStart, uint256 segmentLength)
    {
        uint256 oldChallengeDegree = selection.oldSegments.length - 1;
        segmentLength = selection.oldSegmentsLength / oldChallengeDegree;
        // Intentionally done before challengeLength is potentially added to for the final segment
        segmentStart = selection.oldSegmentsStart + segmentLength * selection.challengePosition;
        if (selection.challengePosition == selection.oldSegments.length - 2) {
            segmentLength += selection.oldSegmentsLength % oldChallengeDegree;
        }
    }

    function hashChallengeState(
        uint256 segmentsStart,
        uint256 segmentsLength,
        bytes32[] memory segments
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(segmentsStart, segmentsLength, segments));
    }

    function blockStateHash(MachineStatus status, bytes32 globalStateHash)
        internal
        pure
        returns (bytes32)
    {
        if (status == MachineStatus.FINISHED) {
            return keccak256(abi.encodePacked("Block state:", globalStateHash));
        } else if (status == MachineStatus.ERRORED) {
            return keccak256(abi.encodePacked("Block state, errored:", globalStateHash));
        } else if (status == MachineStatus.TOO_FAR) {
            return keccak256(abi.encodePacked("Block state, too far:"));
        } else {
            revert("BAD_BLOCK_STATUS");
        }
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

struct GlobalState {
    bytes32[2] bytes32Vals;
    uint64[2] u64Vals;
}

library GlobalStateLib {
    uint16 internal constant BYTES32_VALS_NUM = 2;
    uint16 internal constant U64_VALS_NUM = 2;

    function hash(GlobalState memory state) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "Global state:",
                    state.bytes32Vals[0],
                    state.bytes32Vals[1],
                    state.u64Vals[0],
                    state.u64Vals[1]
                )
            );
    }

    function getBlockHash(GlobalState memory state) internal pure returns (bytes32) {
        return state.bytes32Vals[0];
    }

    function getSendRoot(GlobalState memory state) internal pure returns (bytes32) {
        return state.bytes32Vals[1];
    }

    function getInboxPosition(GlobalState memory state) internal pure returns (uint64) {
        return state.u64Vals[0];
    }

    function getPositionInMessage(GlobalState memory state) internal pure returns (uint64) {
        return state.u64Vals[1];
    }

    function isEmpty(GlobalState calldata state) internal pure returns (bool) {
        return (state.bytes32Vals[0] == bytes32(0) &&
            state.bytes32Vals[1] == bytes32(0) &&
            state.u64Vals[0] == 0 &&
            state.u64Vals[1] == 0);
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../bridge/IBridge.sol";

interface IRollupEventInbox {
    function bridge() external view returns (IBridge);

    function initialize(IBridge _bridge) external;

    function rollup() external view returns (address);

    function rollupInitialized(uint256 chainId) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./ValueStack.sol";
import "./Instructions.sol";
import "./StackFrame.sol";

enum MachineStatus {
    RUNNING,
    FINISHED,
    ERRORED,
    TOO_FAR
}

struct Machine {
    MachineStatus status;
    ValueStack valueStack;
    ValueStack internalStack;
    StackFrameWindow frameStack;
    bytes32 globalStateHash;
    uint32 moduleIdx;
    uint32 functionIdx;
    uint32 functionPc;
    bytes32 modulesRoot;
}

library MachineLib {
    using StackFrameLib for StackFrameWindow;
    using ValueStackLib for ValueStack;

    function hash(Machine memory mach) internal pure returns (bytes32) {
        // Warning: the non-running hashes are replicated in Challenge
        if (mach.status == MachineStatus.RUNNING) {
            return
                keccak256(
                    abi.encodePacked(
                        "Machine running:",
                        mach.valueStack.hash(),
                        mach.internalStack.hash(),
                        mach.frameStack.hash(),
                        mach.globalStateHash,
                        mach.moduleIdx,
                        mach.functionIdx,
                        mach.functionPc,
                        mach.modulesRoot
                    )
                );
        } else if (mach.status == MachineStatus.FINISHED) {
            return keccak256(abi.encodePacked("Machine finished:", mach.globalStateHash));
        } else if (mach.status == MachineStatus.ERRORED) {
            return keccak256(abi.encodePacked("Machine errored:"));
        } else if (mach.status == MachineStatus.TOO_FAR) {
            return keccak256(abi.encodePacked("Machine too far:"));
        } else {
            revert("BAD_MACH_STATUS");
        }
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./IOneStepProver.sol";

library OneStepProofEntryLib {
    uint256 internal constant MAX_STEPS = 1 << 43;
}

interface IOneStepProofEntry {
    function proveOneStep(
        ExecutionContext calldata execCtx,
        uint256 machineStep,
        bytes32 beforeHash,
        bytes calldata proof
    ) external view returns (bytes32 afterHash);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IChallengeResultReceiver {
    function completeChallenge(
        uint256 challengeIndex,
        address winner,
        address loser
    ) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./Value.sol";
import "./ValueArray.sol";

struct ValueStack {
    ValueArray proved;
    bytes32 remainingHash;
}

library ValueStackLib {
    using ValueLib for Value;
    using ValueArrayLib for ValueArray;

    function hash(ValueStack memory stack) internal pure returns (bytes32 h) {
        h = stack.remainingHash;
        uint256 len = stack.proved.length();
        for (uint256 i = 0; i < len; i++) {
            h = keccak256(abi.encodePacked("Value stack:", stack.proved.get(i).hash(), h));
        }
    }

    function peek(ValueStack memory stack) internal pure returns (Value memory) {
        uint256 len = stack.proved.length();
        return stack.proved.get(len - 1);
    }

    function pop(ValueStack memory stack) internal pure returns (Value memory) {
        return stack.proved.pop();
    }

    function push(ValueStack memory stack, Value memory val) internal pure {
        return stack.proved.push(val);
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

struct Instruction {
    uint16 opcode;
    uint256 argumentData;
}

library Instructions {
    uint16 internal constant UNREACHABLE = 0x00;
    uint16 internal constant NOP = 0x01;
    uint16 internal constant RETURN = 0x0F;
    uint16 internal constant CALL = 0x10;
    uint16 internal constant CALL_INDIRECT = 0x11;
    uint16 internal constant LOCAL_GET = 0x20;
    uint16 internal constant LOCAL_SET = 0x21;
    uint16 internal constant GLOBAL_GET = 0x23;
    uint16 internal constant GLOBAL_SET = 0x24;

    uint16 internal constant I32_LOAD = 0x28;
    uint16 internal constant I64_LOAD = 0x29;
    uint16 internal constant F32_LOAD = 0x2A;
    uint16 internal constant F64_LOAD = 0x2B;
    uint16 internal constant I32_LOAD8_S = 0x2C;
    uint16 internal constant I32_LOAD8_U = 0x2D;
    uint16 internal constant I32_LOAD16_S = 0x2E;
    uint16 internal constant I32_LOAD16_U = 0x2F;
    uint16 internal constant I64_LOAD8_S = 0x30;
    uint16 internal constant I64_LOAD8_U = 0x31;
    uint16 internal constant I64_LOAD16_S = 0x32;
    uint16 internal constant I64_LOAD16_U = 0x33;
    uint16 internal constant I64_LOAD32_S = 0x34;
    uint16 internal constant I64_LOAD32_U = 0x35;

    uint16 internal constant I32_STORE = 0x36;
    uint16 internal constant I64_STORE = 0x37;
    uint16 internal constant F32_STORE = 0x38;
    uint16 internal constant F64_STORE = 0x39;
    uint16 internal constant I32_STORE8 = 0x3A;
    uint16 internal constant I32_STORE16 = 0x3B;
    uint16 internal constant I64_STORE8 = 0x3C;
    uint16 internal constant I64_STORE16 = 0x3D;
    uint16 internal constant I64_STORE32 = 0x3E;

    uint16 internal constant MEMORY_SIZE = 0x3F;
    uint16 internal constant MEMORY_GROW = 0x40;

    uint16 internal constant DROP = 0x1A;
    uint16 internal constant SELECT = 0x1B;
    uint16 internal constant I32_CONST = 0x41;
    uint16 internal constant I64_CONST = 0x42;
    uint16 internal constant F32_CONST = 0x43;
    uint16 internal constant F64_CONST = 0x44;
    uint16 internal constant I32_EQZ = 0x45;
    uint16 internal constant I32_RELOP_BASE = 0x46;
    uint16 internal constant IRELOP_EQ = 0;
    uint16 internal constant IRELOP_NE = 1;
    uint16 internal constant IRELOP_LT_S = 2;
    uint16 internal constant IRELOP_LT_U = 3;
    uint16 internal constant IRELOP_GT_S = 4;
    uint16 internal constant IRELOP_GT_U = 5;
    uint16 internal constant IRELOP_LE_S = 6;
    uint16 internal constant IRELOP_LE_U = 7;
    uint16 internal constant IRELOP_GE_S = 8;
    uint16 internal constant IRELOP_GE_U = 9;
    uint16 internal constant IRELOP_LAST = IRELOP_GE_U;

    uint16 internal constant I64_EQZ = 0x50;
    uint16 internal constant I64_RELOP_BASE = 0x51;

    uint16 internal constant I32_UNOP_BASE = 0x67;
    uint16 internal constant IUNOP_CLZ = 0;
    uint16 internal constant IUNOP_CTZ = 1;
    uint16 internal constant IUNOP_POPCNT = 2;
    uint16 internal constant IUNOP_LAST = IUNOP_POPCNT;

    uint16 internal constant I32_ADD = 0x6A;
    uint16 internal constant I32_SUB = 0x6B;
    uint16 internal constant I32_MUL = 0x6C;
    uint16 internal constant I32_DIV_S = 0x6D;
    uint16 internal constant I32_DIV_U = 0x6E;
    uint16 internal constant I32_REM_S = 0x6F;
    uint16 internal constant I32_REM_U = 0x70;
    uint16 internal constant I32_AND = 0x71;
    uint16 internal constant I32_OR = 0x72;
    uint16 internal constant I32_XOR = 0x73;
    uint16 internal constant I32_SHL = 0x74;
    uint16 internal constant I32_SHR_S = 0x75;
    uint16 internal constant I32_SHR_U = 0x76;
    uint16 internal constant I32_ROTL = 0x77;
    uint16 internal constant I32_ROTR = 0x78;

    uint16 internal constant I64_UNOP_BASE = 0x79;

    uint16 internal constant I64_ADD = 0x7C;
    uint16 internal constant I64_SUB = 0x7D;
    uint16 internal constant I64_MUL = 0x7E;
    uint16 internal constant I64_DIV_S = 0x7F;
    uint16 internal constant I64_DIV_U = 0x80;
    uint16 internal constant I64_REM_S = 0x81;
    uint16 internal constant I64_REM_U = 0x82;
    uint16 internal constant I64_AND = 0x83;
    uint16 internal constant I64_OR = 0x84;
    uint16 internal constant I64_XOR = 0x85;
    uint16 internal constant I64_SHL = 0x86;
    uint16 internal constant I64_SHR_S = 0x87;
    uint16 internal constant I64_SHR_U = 0x88;
    uint16 internal constant I64_ROTL = 0x89;
    uint16 internal constant I64_ROTR = 0x8A;

    uint16 internal constant I32_WRAP_I64 = 0xA7;
    uint16 internal constant I64_EXTEND_I32_S = 0xAC;
    uint16 internal constant I64_EXTEND_I32_U = 0xAD;

    uint16 internal constant I32_REINTERPRET_F32 = 0xBC;
    uint16 internal constant I64_REINTERPRET_F64 = 0xBD;
    uint16 internal constant F32_REINTERPRET_I32 = 0xBE;
    uint16 internal constant F64_REINTERPRET_I64 = 0xBF;

    uint16 internal constant I32_EXTEND_8S = 0xC0;
    uint16 internal constant I32_EXTEND_16S = 0xC1;
    uint16 internal constant I64_EXTEND_8S = 0xC2;
    uint16 internal constant I64_EXTEND_16S = 0xC3;
    uint16 internal constant I64_EXTEND_32S = 0xC4;

    uint16 internal constant INIT_FRAME = 0x8002;
    uint16 internal constant ARBITRARY_JUMP = 0x8003;
    uint16 internal constant ARBITRARY_JUMP_IF = 0x8004;
    uint16 internal constant MOVE_FROM_STACK_TO_INTERNAL = 0x8005;
    uint16 internal constant MOVE_FROM_INTERNAL_TO_STACK = 0x8006;
    uint16 internal constant DUP = 0x8008;
    uint16 internal constant CROSS_MODULE_CALL = 0x8009;
    uint16 internal constant CALLER_MODULE_INTERNAL_CALL = 0x800A;

    uint16 internal constant GET_GLOBAL_STATE_BYTES32 = 0x8010;
    uint16 internal constant SET_GLOBAL_STATE_BYTES32 = 0x8011;
    uint16 internal constant GET_GLOBAL_STATE_U64 = 0x8012;
    uint16 internal constant SET_GLOBAL_STATE_U64 = 0x8013;

    uint16 internal constant READ_PRE_IMAGE = 0x8020;
    uint16 internal constant READ_INBOX_MESSAGE = 0x8021;
    uint16 internal constant HALT_AND_SET_FINISHED = 0x8022;

    uint256 internal constant INBOX_INDEX_SEQUENCER = 0;
    uint256 internal constant INBOX_INDEX_DELAYED = 1;

    function hash(Instruction memory inst) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("Instruction:", inst.opcode, inst.argumentData));
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./Value.sol";

struct StackFrame {
    Value returnPc;
    bytes32 localsMerkleRoot;
    uint32 callerModule;
    uint32 callerModuleInternals;
}

struct StackFrameWindow {
    StackFrame[] proved;
    bytes32 remainingHash;
}

library StackFrameLib {
    using ValueLib for Value;

    function hash(StackFrame memory frame) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "Stack frame:",
                    frame.returnPc.hash(),
                    frame.localsMerkleRoot,
                    frame.callerModule,
                    frame.callerModuleInternals
                )
            );
    }

    function hash(StackFrameWindow memory window) internal pure returns (bytes32 h) {
        h = window.remainingHash;
        for (uint256 i = 0; i < window.proved.length; i++) {
            h = keccak256(abi.encodePacked("Stack frame stack:", hash(window.proved[i]), h));
        }
    }

    function peek(StackFrameWindow memory window) internal pure returns (StackFrame memory) {
        require(window.proved.length == 1, "BAD_WINDOW_LENGTH");
        return window.proved[0];
    }

    function pop(StackFrameWindow memory window) internal pure returns (StackFrame memory frame) {
        require(window.proved.length == 1, "BAD_WINDOW_LENGTH");
        frame = window.proved[0];
        window.proved = new StackFrame[](0);
    }

    function push(StackFrameWindow memory window, StackFrame memory frame) internal pure {
        StackFrame[] memory newProved = new StackFrame[](window.proved.length + 1);
        for (uint256 i = 0; i < window.proved.length; i++) {
            newProved[i] = window.proved[i];
        }
        newProved[window.proved.length] = frame;
        window.proved = newProved;
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

enum ValueType {
    I32,
    I64,
    F32,
    F64,
    REF_NULL,
    FUNC_REF,
    INTERNAL_REF
}

struct Value {
    ValueType valueType;
    uint256 contents;
}

library ValueLib {
    function hash(Value memory val) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("Value:", val.valueType, val.contents));
    }

    function maxValueType() internal pure returns (ValueType) {
        return ValueType.INTERNAL_REF;
    }

    function assumeI32(Value memory val) internal pure returns (uint32) {
        uint256 uintval = uint256(val.contents);
        require(val.valueType == ValueType.I32, "NOT_I32");
        require(uintval < (1 << 32), "BAD_I32");
        return uint32(uintval);
    }

    function assumeI64(Value memory val) internal pure returns (uint64) {
        uint256 uintval = uint256(val.contents);
        require(val.valueType == ValueType.I64, "NOT_I64");
        require(uintval < (1 << 64), "BAD_I64");
        return uint64(uintval);
    }

    function newRefNull() internal pure returns (Value memory) {
        return Value({valueType: ValueType.REF_NULL, contents: 0});
    }

    function newI32(uint32 x) internal pure returns (Value memory) {
        return Value({valueType: ValueType.I32, contents: uint256(x)});
    }

    function newI64(uint64 x) internal pure returns (Value memory) {
        return Value({valueType: ValueType.I64, contents: uint256(x)});
    }

    function newBoolean(bool x) internal pure returns (Value memory) {
        if (x) {
            return newI32(uint32(1));
        } else {
            return newI32(uint32(0));
        }
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./Value.sol";

struct ValueArray {
    Value[] inner;
}

library ValueArrayLib {
    function get(ValueArray memory arr, uint256 index) internal pure returns (Value memory) {
        return arr.inner[index];
    }

    function set(
        ValueArray memory arr,
        uint256 index,
        Value memory val
    ) internal pure {
        arr.inner[index] = val;
    }

    function length(ValueArray memory arr) internal pure returns (uint256) {
        return arr.inner.length;
    }

    function push(ValueArray memory arr, Value memory val) internal pure {
        Value[] memory newInner = new Value[](arr.inner.length + 1);
        for (uint256 i = 0; i < arr.inner.length; i++) {
            newInner[i] = arr.inner[i];
        }
        newInner[arr.inner.length] = val;
        arr.inner = newInner;
    }

    function pop(ValueArray memory arr) internal pure returns (Value memory popped) {
        popped = arr.inner[arr.inner.length - 1];
        Value[] memory newInner = new Value[](arr.inner.length - 1);
        for (uint256 i = 0; i < newInner.length; i++) {
            newInner[i] = arr.inner[i];
        }
        arr.inner = newInner;
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../state/Machine.sol";
import "../state/Module.sol";
import "../state/Instructions.sol";
import "../bridge/ISequencerInbox.sol";
import "../bridge/IBridge.sol";

struct ExecutionContext {
    uint256 maxInboxMessagesRead;
    IBridge bridge;
}

abstract contract IOneStepProver {
    function executeOneStep(
        ExecutionContext memory execCtx,
        Machine calldata mach,
        Module calldata mod,
        Instruction calldata instruction,
        bytes calldata proof
    ) external view virtual returns (Machine memory result, Module memory resultMod);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./ModuleMemory.sol";

struct Module {
    bytes32 globalsMerkleRoot;
    ModuleMemory moduleMemory;
    bytes32 tablesMerkleRoot;
    bytes32 functionsMerkleRoot;
    uint32 internalsOffset;
}

library ModuleLib {
    using ModuleMemoryLib for ModuleMemory;

    function hash(Module memory mod) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "Module:",
                    mod.globalsMerkleRoot,
                    mod.moduleMemory.hash(),
                    mod.tablesMerkleRoot,
                    mod.functionsMerkleRoot,
                    mod.internalsOffset
                )
            );
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./Deserialize.sol";

struct ModuleMemory {
    uint64 size;
    uint64 maxSize;
    bytes32 merkleRoot;
}

library ModuleMemoryLib {
    using MerkleProofLib for MerkleProof;

    function hash(ModuleMemory memory mem) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("Memory:", mem.size, mem.maxSize, mem.merkleRoot));
    }

    function proveLeaf(
        ModuleMemory memory mem,
        uint256 leafIdx,
        bytes calldata proof,
        uint256 startOffset
    )
        internal
        pure
        returns (
            bytes32 contents,
            uint256 offset,
            MerkleProof memory merkle
        )
    {
        offset = startOffset;
        (contents, offset) = Deserialize.b32(proof, offset);
        (merkle, offset) = Deserialize.merkleProof(proof, offset);
        bytes32 recomputedRoot = merkle.computeRootFromMemory(leafIdx, contents);
        require(recomputedRoot == mem.merkleRoot, "WRONG_MEM_ROOT");
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./Value.sol";
import "./Instructions.sol";
import "./Module.sol";

struct MerkleProof {
    bytes32[] counterparts;
}

library MerkleProofLib {
    using ModuleLib for Module;
    using ValueLib for Value;

    function computeRootFromValue(
        MerkleProof memory proof,
        uint256 index,
        Value memory leaf
    ) internal pure returns (bytes32) {
        return computeRootUnsafe(proof, index, leaf.hash(), "Value merkle tree:");
    }

    function computeRootFromInstruction(
        MerkleProof memory proof,
        uint256 index,
        Instruction memory inst
    ) internal pure returns (bytes32) {
        return computeRootUnsafe(proof, index, Instructions.hash(inst), "Instruction merkle tree:");
    }

    function computeRootFromFunction(
        MerkleProof memory proof,
        uint256 index,
        bytes32 codeRoot
    ) internal pure returns (bytes32) {
        bytes32 h = keccak256(abi.encodePacked("Function:", codeRoot));
        return computeRootUnsafe(proof, index, h, "Function merkle tree:");
    }

    function computeRootFromMemory(
        MerkleProof memory proof,
        uint256 index,
        bytes32 contents
    ) internal pure returns (bytes32) {
        bytes32 h = keccak256(abi.encodePacked("Memory leaf:", contents));
        return computeRootUnsafe(proof, index, h, "Memory merkle tree:");
    }

    function computeRootFromElement(
        MerkleProof memory proof,
        uint256 index,
        bytes32 funcTypeHash,
        Value memory val
    ) internal pure returns (bytes32) {
        bytes32 h = keccak256(abi.encodePacked("Table element:", funcTypeHash, val.hash()));
        return computeRootUnsafe(proof, index, h, "Table element merkle tree:");
    }

    function computeRootFromTable(
        MerkleProof memory proof,
        uint256 index,
        uint8 tableType,
        uint64 tableSize,
        bytes32 elementsRoot
    ) internal pure returns (bytes32) {
        bytes32 h = keccak256(abi.encodePacked("Table:", tableType, tableSize, elementsRoot));
        return computeRootUnsafe(proof, index, h, "Table merkle tree:");
    }

    function computeRootFromModule(
        MerkleProof memory proof,
        uint256 index,
        Module memory mod
    ) internal pure returns (bytes32) {
        return computeRootUnsafe(proof, index, mod.hash(), "Module merkle tree:");
    }

    // WARNING: leafHash must be computed in such a way that it cannot be a non-leaf hash.
    function computeRootUnsafe(
        MerkleProof memory proof,
        uint256 index,
        bytes32 leafHash,
        string memory prefix
    ) internal pure returns (bytes32 h) {
        h = leafHash;
        for (uint256 layer = 0; layer < proof.counterparts.length; layer++) {
            if (index & 1 == 0) {
                h = keccak256(abi.encodePacked(prefix, h, proof.counterparts[layer]));
            } else {
                h = keccak256(abi.encodePacked(prefix, proof.counterparts[layer], h));
            }
            index >>= 1;
        }
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./Value.sol";
import "./ValueStack.sol";
import "./Machine.sol";
import "./Instructions.sol";
import "./StackFrame.sol";
import "./MerkleProof.sol";
import "./ModuleMemory.sol";
import "./Module.sol";
import "./GlobalState.sol";

library Deserialize {
    function u8(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (uint8 ret, uint256 offset)
    {
        offset = startOffset;
        ret = uint8(proof[offset]);
        offset++;
    }

    function u16(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (uint16 ret, uint256 offset)
    {
        offset = startOffset;
        for (uint256 i = 0; i < 16 / 8; i++) {
            ret <<= 8;
            ret |= uint8(proof[offset]);
            offset++;
        }
    }

    function u32(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (uint32 ret, uint256 offset)
    {
        offset = startOffset;
        for (uint256 i = 0; i < 32 / 8; i++) {
            ret <<= 8;
            ret |= uint8(proof[offset]);
            offset++;
        }
    }

    function u64(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (uint64 ret, uint256 offset)
    {
        offset = startOffset;
        for (uint256 i = 0; i < 64 / 8; i++) {
            ret <<= 8;
            ret |= uint8(proof[offset]);
            offset++;
        }
    }

    function u256(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (uint256 ret, uint256 offset)
    {
        offset = startOffset;
        for (uint256 i = 0; i < 256 / 8; i++) {
            ret <<= 8;
            ret |= uint8(proof[offset]);
            offset++;
        }
    }

    function b32(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (bytes32 ret, uint256 offset)
    {
        offset = startOffset;
        uint256 retInt;
        (retInt, offset) = u256(proof, offset);
        ret = bytes32(retInt);
    }

    function value(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (Value memory val, uint256 offset)
    {
        offset = startOffset;
        uint8 typeInt = uint8(proof[offset]);
        offset++;
        require(typeInt <= uint8(ValueLib.maxValueType()), "BAD_VALUE_TYPE");
        uint256 contents;
        (contents, offset) = u256(proof, offset);
        val = Value({valueType: ValueType(typeInt), contents: contents});
    }

    function valueStack(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (ValueStack memory stack, uint256 offset)
    {
        offset = startOffset;
        bytes32 remainingHash;
        (remainingHash, offset) = b32(proof, offset);
        uint256 provedLength;
        (provedLength, offset) = u256(proof, offset);
        Value[] memory proved = new Value[](provedLength);
        for (uint256 i = 0; i < proved.length; i++) {
            (proved[i], offset) = value(proof, offset);
        }
        stack = ValueStack({proved: ValueArray(proved), remainingHash: remainingHash});
    }

    function instruction(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (Instruction memory inst, uint256 offset)
    {
        offset = startOffset;
        uint16 opcode;
        uint256 data;
        (opcode, offset) = u16(proof, offset);
        (data, offset) = u256(proof, offset);
        inst = Instruction({opcode: opcode, argumentData: data});
    }

    function stackFrame(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (StackFrame memory window, uint256 offset)
    {
        offset = startOffset;
        Value memory returnPc;
        bytes32 localsMerkleRoot;
        uint32 callerModule;
        uint32 callerModuleInternals;
        (returnPc, offset) = value(proof, offset);
        (localsMerkleRoot, offset) = b32(proof, offset);
        (callerModule, offset) = u32(proof, offset);
        (callerModuleInternals, offset) = u32(proof, offset);
        window = StackFrame({
            returnPc: returnPc,
            localsMerkleRoot: localsMerkleRoot,
            callerModule: callerModule,
            callerModuleInternals: callerModuleInternals
        });
    }

    function stackFrameWindow(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (StackFrameWindow memory window, uint256 offset)
    {
        offset = startOffset;
        bytes32 remainingHash;
        (remainingHash, offset) = b32(proof, offset);
        StackFrame[] memory proved;
        if (proof[offset] != 0) {
            offset++;
            proved = new StackFrame[](1);
            (proved[0], offset) = stackFrame(proof, offset);
        } else {
            offset++;
            proved = new StackFrame[](0);
        }
        window = StackFrameWindow({proved: proved, remainingHash: remainingHash});
    }

    function moduleMemory(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (ModuleMemory memory mem, uint256 offset)
    {
        offset = startOffset;
        uint64 size;
        uint64 maxSize;
        bytes32 root;
        (size, offset) = u64(proof, offset);
        (maxSize, offset) = u64(proof, offset);
        (root, offset) = b32(proof, offset);
        mem = ModuleMemory({size: size, maxSize: maxSize, merkleRoot: root});
    }

    function module(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (Module memory mod, uint256 offset)
    {
        offset = startOffset;
        bytes32 globalsMerkleRoot;
        ModuleMemory memory mem;
        bytes32 tablesMerkleRoot;
        bytes32 functionsMerkleRoot;
        uint32 internalsOffset;
        (globalsMerkleRoot, offset) = b32(proof, offset);
        (mem, offset) = moduleMemory(proof, offset);
        (tablesMerkleRoot, offset) = b32(proof, offset);
        (functionsMerkleRoot, offset) = b32(proof, offset);
        (internalsOffset, offset) = u32(proof, offset);
        mod = Module({
            globalsMerkleRoot: globalsMerkleRoot,
            moduleMemory: mem,
            tablesMerkleRoot: tablesMerkleRoot,
            functionsMerkleRoot: functionsMerkleRoot,
            internalsOffset: internalsOffset
        });
    }

    function globalState(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (GlobalState memory state, uint256 offset)
    {
        offset = startOffset;

        // using constant ints for array size requires newer solidity
        bytes32[2] memory bytes32Vals;
        uint64[2] memory u64Vals;

        for (uint8 i = 0; i < GlobalStateLib.BYTES32_VALS_NUM; i++) {
            (bytes32Vals[i], offset) = b32(proof, offset);
        }
        for (uint8 i = 0; i < GlobalStateLib.U64_VALS_NUM; i++) {
            (u64Vals[i], offset) = u64(proof, offset);
        }
        state = GlobalState({bytes32Vals: bytes32Vals, u64Vals: u64Vals});
    }

    function machine(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (Machine memory mach, uint256 offset)
    {
        offset = startOffset;
        MachineStatus status;
        {
            uint8 statusU8;
            (statusU8, offset) = u8(proof, offset);
            if (statusU8 == 0) {
                status = MachineStatus.RUNNING;
            } else if (statusU8 == 1) {
                status = MachineStatus.FINISHED;
            } else if (statusU8 == 2) {
                status = MachineStatus.ERRORED;
            } else if (statusU8 == 3) {
                status = MachineStatus.TOO_FAR;
            } else {
                revert("UNKNOWN_MACH_STATUS");
            }
        }
        ValueStack memory values;
        ValueStack memory internalStack;
        bytes32 globalStateHash;
        uint32 moduleIdx;
        uint32 functionIdx;
        uint32 functionPc;
        StackFrameWindow memory frameStack;
        bytes32 modulesRoot;
        (values, offset) = valueStack(proof, offset);
        (internalStack, offset) = valueStack(proof, offset);
        (frameStack, offset) = stackFrameWindow(proof, offset);
        (globalStateHash, offset) = b32(proof, offset);
        (moduleIdx, offset) = u32(proof, offset);
        (functionIdx, offset) = u32(proof, offset);
        (functionPc, offset) = u32(proof, offset);
        (modulesRoot, offset) = b32(proof, offset);
        mach = Machine({
            status: status,
            valueStack: values,
            internalStack: internalStack,
            frameStack: frameStack,
            globalStateHash: globalStateHash,
            moduleIdx: moduleIdx,
            functionIdx: functionIdx,
            functionPc: functionPc,
            modulesRoot: modulesRoot
        });
    }

    function merkleProof(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (MerkleProof memory merkle, uint256 offset)
    {
        offset = startOffset;
        uint8 length;
        (length, offset) = u8(proof, offset);
        bytes32[] memory counterparts = new bytes32[](length);
        for (uint8 i = 0; i < length; i++) {
            (counterparts[i], offset) = b32(proof, offset);
        }
        merkle = MerkleProof(counterparts);
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

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

/**
 * @notice Utility functions for Node
 */
library NodeLib {
    /**
     * @notice Initialize a Node
     * @param _stateHash Initial value of stateHash
     * @param _challengeHash Initial value of challengeHash
     * @param _confirmData Initial value of confirmData
     * @param _prevNum Initial value of prevNum
     * @param _deadlineBlock Initial value of deadlineBlock
     * @param _nodeHash Initial value of nodeHash
     */
    function createNode(
        bytes32 _stateHash,
        bytes32 _challengeHash,
        bytes32 _confirmData,
        uint64 _prevNum,
        uint64 _deadlineBlock,
        bytes32 _nodeHash
    ) internal view returns (Node memory) {
        Node memory node;
        node.stateHash = _stateHash;
        node.challengeHash = _challengeHash;
        node.confirmData = _confirmData;
        node.prevNum = _prevNum;
        node.deadlineBlock = _deadlineBlock;
        node.noChildConfirmedBeforeBlock = _deadlineBlock;
        node.createdAtBlock = uint64(block.number);
        node.nodeHash = _nodeHash;
        return node;
    }

    /**
     * @notice Update child properties
     * @param number The child number to set
     */
    function childCreated(Node storage self, uint64 number) internal {
        if (self.firstChildBlock == 0) {
            self.firstChildBlock = uint64(block.number);
        }
        self.latestChildNumber = number;
    }

    /**
     * @notice Update the child confirmed deadline
     * @param deadline The new deadline to set
     */
    function newChildConfirmDeadline(Node storage self, uint64 deadline) internal {
        self.noChildConfirmedBeforeBlock = deadline;
    }

    /**
     * @notice Check whether the current block number has met or passed the node's deadline
     */
    function requirePastDeadline(Node memory self) internal view {
        require(block.number >= self.deadlineBlock, "BEFORE_DEADLINE");
    }

    /**
     * @notice Check whether the current block number has met or passed deadline for children of this node to be confirmed
     */
    function requirePastChildConfirmDeadline(Node memory self) internal view {
        require(block.number >= self.noChildConfirmedBeforeBlock, "CHILD_TOO_RECENT");
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library AddressAliasHelper {
    uint160 internal constant OFFSET = uint160(0x1111000000000000000000000000000000001111);

    /// @notice Utility function that converts the address in the L1 that submitted a tx to
    /// the inbox to the msg.sender viewed in the L2
    /// @param l1Address the address in the L1 that triggered the tx to L2
    /// @return l2Address L2 address as viewed in msg.sender
    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        unchecked {
            l2Address = address(uint160(l1Address) + OFFSET);
        }
    }

    /// @notice Utility function that converts the msg.sender viewed in the L2 to the
    /// address in the L1 that submitted a tx to the inbox
    /// @param l2Address L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(address l2Address) internal pure returns (address l1Address) {
        unchecked {
            l1Address = address(uint160(l2Address) - OFFSET);
        }
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface ArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

    /**
     * @notice Gets the rollup's unique chain identifier
     * @return Chain identifier as int
     */
    function arbChainID() external view returns (uint256);

    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external view returns (uint256);

    /**
     * @notice Returns 0 since Nitro has no concept of storage gas
     * @return uint 0
     */
    function getStorageGasAvailable() external view returns (uint256);

    /**
     * @notice (deprecated) check if current call is top level (meaning it was triggered by an EoA or a L1 contract)
     * @dev this call has been deprecated and may be removed in a future release
     * @return true if current execution frame is not a call by another L2 contract
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param unused argument no longer used
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address unused)
        external
        pure
        returns (address);

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
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination) external payable returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
     * to a contract address without any code (as enforced by the Bridge contract).
     * @param destination recipient address on L1
     * @param data (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata data)
        external
        payable
        returns (uint256);

    /**
     * @notice Get send Merkle tree state
     * @return size number of sends in the history
     * @return root root hash of the send history
     * @return partials hashes of partial subtrees in the send history tree
     */
    function sendMerkleTreeState()
        external
        view
        returns (
            uint256 size,
            bytes32 root,
            bytes32[] memory partials
        );

    /**
     * @notice creates a send txn from L2 to L1
     * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
     */
    event L2ToL1Tx(
        address caller,
        address indexed destination,
        uint256 indexed hash,
        uint256 indexed position,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /// @dev DEPRECATED in favour of the new L2ToL1Tx event above after the nitro upgrade
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

    /**
     * @notice logs a merkle branch for proof synthesis
     * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
     * @param hash the merkle hash
     * @param position = (level << 192) + leaf
     */
    event SendMerkleUpdate(
        uint256 indexed reserved,
        bytes32 indexed hash,
        uint256 indexed position
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import {MerkleProofTooLong} from "./Error.sol";

library MerkleLib {
    function generateRoot(bytes32[] memory _hashes) internal pure returns (bytes32) {
        bytes32[] memory prevLayer = _hashes;
        while (prevLayer.length > 1) {
            bytes32[] memory nextLayer = new bytes32[]((prevLayer.length + 1) / 2);
            for (uint256 i = 0; i < nextLayer.length; i++) {
                if (2 * i + 1 < prevLayer.length) {
                    nextLayer[i] = keccak256(
                        abi.encodePacked(prevLayer[2 * i], prevLayer[2 * i + 1])
                    );
                } else {
                    nextLayer[i] = prevLayer[2 * i];
                }
            }
            prevLayer = nextLayer;
        }
        return prevLayer[0];
    }

    function calculateRoot(
        bytes32[] memory nodes,
        uint256 route,
        bytes32 item
    ) internal pure returns (bytes32) {
        uint256 proofItems = nodes.length;
        if (proofItems > 256) revert MerkleProofTooLong(proofItems, 256);
        bytes32 h = item;
        for (uint256 i = 0; i < proofItems; ) {
            bytes32 node = nodes[i];
            if ((route & (1 << i)) == 0) {
                assembly {
                    mstore(0x00, h)
                    mstore(0x20, node)
                    h := keccak256(0x00, 0x40)
                }
            } else {
                assembly {
                    mstore(0x00, node)
                    mstore(0x20, h)
                    h := keccak256(0x00, 0x40)
                }
            }
            unchecked {
                ++i;
            }
        }
        return h;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./BridgeCreator.sol";

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./RollupProxy.sol";

contract RollupCreator is Ownable {
    event RollupCreated(
        address indexed rollupAddress,
        address inboxAddress,
        address adminProxy,
        address sequencerInbox,
        address bridge
    );
    event TemplatesUpdated();

    BridgeCreator public bridgeCreator;
    IOneStepProofEntry public osp;
    IChallengeManager public challengeManagerTemplate;
    IRollupAdmin public rollupAdminLogic;
    IRollupUser public rollupUserLogic;

    address public validatorUtils;
    address public validatorWalletCreator;

    constructor() Ownable() {}

    function setTemplates(
        BridgeCreator _bridgeCreator,
        IOneStepProofEntry _osp,
        IChallengeManager _challengeManagerLogic,
        IRollupAdmin _rollupAdminLogic,
        IRollupUser _rollupUserLogic,
        address _validatorUtils,
        address _validatorWalletCreator
    ) external onlyOwner {
        bridgeCreator = _bridgeCreator;
        osp = _osp;
        challengeManagerTemplate = _challengeManagerLogic;
        rollupAdminLogic = _rollupAdminLogic;
        rollupUserLogic = _rollupUserLogic;
        validatorUtils = _validatorUtils;
        validatorWalletCreator = _validatorWalletCreator;
        emit TemplatesUpdated();
    }

    struct CreateRollupFrame {
        ProxyAdmin admin;
        IBridge bridge;
        ISequencerInbox sequencerInbox;
        IInbox inbox;
        IRollupEventInbox rollupEventInbox;
        IOutbox outbox;
        RollupProxy rollup;
    }

    // After this setup:
    // Rollup should be the owner of bridge
    // RollupOwner should be the owner of Rollup's ProxyAdmin
    // RollupOwner should be the owner of Rollup
    // Bridge should have a single inbox and outbox
    function createRollup(Config memory config, address expectedRollupAddr)
        external
        returns (address)
    {
        CreateRollupFrame memory frame;
        frame.admin = new ProxyAdmin();

        (
            frame.bridge,
            frame.sequencerInbox,
            frame.inbox,
            frame.rollupEventInbox,
            frame.outbox
        ) = bridgeCreator.createBridge(
            address(frame.admin),
            expectedRollupAddr,
            config.sequencerInboxMaxTimeVariation
        );

        frame.admin.transferOwnership(config.owner);

        IChallengeManager challengeManager = IChallengeManager(
            address(
                new TransparentUpgradeableProxy(
                    address(challengeManagerTemplate),
                    address(frame.admin),
                    ""
                )
            )
        );
        challengeManager.initialize(
            IChallengeResultReceiver(expectedRollupAddr),
            frame.sequencerInbox,
            frame.bridge,
            osp
        );

        frame.rollup = new RollupProxy(
            config,
            ContractDependencies({
                bridge: frame.bridge,
                sequencerInbox: frame.sequencerInbox,
                inbox: frame.inbox,
                outbox: frame.outbox,
                rollupEventInbox: frame.rollupEventInbox,
                challengeManager: challengeManager,
                rollupAdminLogic: rollupAdminLogic,
                rollupUserLogic: rollupUserLogic,
                validatorUtils: validatorUtils,
                validatorWalletCreator: validatorWalletCreator
            })
        );
        require(address(frame.rollup) == expectedRollupAddr, "WRONG_ROLLUP_ADDR");

        emit RollupCreated(
            address(frame.rollup),
            address(frame.inbox),
            address(frame.admin),
            address(frame.sequencerInbox),
            address(frame.bridge)
        );
        return address(frame.rollup);
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../libraries/AdminFallbackProxy.sol";
import "./IRollupLogic.sol";

contract RollupProxy is AdminFallbackProxy {
    constructor(Config memory config, ContractDependencies memory connectedContracts)
        AdminFallbackProxy(
            address(connectedContracts.rollupAdminLogic),
            abi.encodeWithSelector(IRollupAdmin.initialize.selector, config, connectedContracts),
            address(connectedContracts.rollupUserLogic),
            abi.encodeWithSelector(IRollupUserAbs.initialize.selector, config.stakeToken),
            config.owner
        )
    {}
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

/// @notice An extension to OZ's ERC1967Upgrade implementation to support two logic contracts
abstract contract DoubleLogicERC1967Upgrade is ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.implementation.secondary" subtracted by 1
    bytes32 internal constant _IMPLEMENTATION_SECONDARY_SLOT =
        0x2b1dbce74324248c222f0ec2d5ed7bd323cfc425b336f0253c5ccfda7265546d;

    // This is the keccak-256 hash of "eip1967.proxy.rollback.secondary" subtracted by 1
    bytes32 private constant _ROLLBACK_SECONDARY_SLOT =
        0x49bd798cd84788856140a4cd5030756b4d08a9e4d55db725ec195f232d262a89;

    /**
     * @dev Emitted when the secondary implementation is upgraded.
     */
    event UpgradedSecondary(address indexed implementation);

    /**
     * @dev Returns the current secondary implementation address.
     */
    function _getSecondaryImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SECONDARY_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setSecondaryImplementation(address newImplementation) private {
        require(
            Address.isContract(newImplementation),
            "ERC1967: new secondary implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SECONDARY_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform secondary implementation upgrade
     *
     * Emits an {UpgradedSecondary} event.
     */
    function _upgradeSecondaryTo(address newImplementation) internal {
        _setSecondaryImplementation(newImplementation);
        emit UpgradedSecondary(newImplementation);
    }

    /**
     * @dev Perform secondary implementation upgrade with additional setup call.
     *
     * Emits an {UpgradedSecondary} event.
     */
    function _upgradeSecondaryToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeSecondaryTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform secondary implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {UpgradedSecondary} event.
     */
    function _upgradeSecondaryToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SECONDARY_SLOT).value) {
            _setSecondaryImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(
                    slot == _IMPLEMENTATION_SECONDARY_SLOT,
                    "ERC1967Upgrade: unsupported secondary proxiableUUID"
                );
            } catch {
                revert("ERC1967Upgrade: new secondary implementation is not UUPS");
            }
            _upgradeSecondaryToAndCall(newImplementation, data, forceCall);
        }
    }
}

/// @notice similar to TransparentUpgradeableProxy but allows the admin to fallback to a separate logic contract using DoubleLogicERC1967Upgrade
/// @dev this follows the UUPS pattern for upgradeability - read more at https://github.com/OpenZeppelin/openzeppelin-contracts/tree/v4.5.0/contracts/proxy#transparent-vs-uups-proxies
contract AdminFallbackProxy is Proxy, DoubleLogicERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `adminLogic` and a secondary
     * logic implementation specified by `userLogic`
     *
     * Only the `adminAddr` is able to use the `adminLogic` functions
     * All other addresses can interact with the `userLogic` functions
     */
    constructor(
        address adminLogic,
        bytes memory adminData,
        address userLogic,
        bytes memory userData,
        address adminAddr
    ) payable {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        assert(
            _IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
        );
        assert(
            _IMPLEMENTATION_SECONDARY_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.implementation.secondary")) - 1)
        );
        _changeAdmin(adminAddr);
        _upgradeToAndCall(adminLogic, adminData, false);
        _upgradeSecondaryToAndCall(userLogic, userData, false);
    }

    /// @inheritdoc Proxy
    function _implementation() internal view override returns (address) {
        require(msg.data.length >= 4, "NO_FUNC_SIG");
        // if the sender is the proxy's admin, delegate to admin logic
        // if the admin is disabled, all calls will be forwarded to user logic
        // admin affordances can be disabled by setting to a no-op smart contract
        // since there is a check for contract code before updating the value
        address target = _getAdmin() != msg.sender
            ? DoubleLogicERC1967Upgrade._getSecondaryImplementation()
            : ERC1967Upgrade._getImplementation();
        // implementation setters do an existence check, but we protect against selfdestructs this way
        require(Address.isContract(target), "TARGET_NOT_CONTRACT");
        return target;
    }

    /**
     * @dev unlike transparent upgradeable proxies, this does allow the admin to fallback to a logic contract
     * the admin is expected to interact only with the primary logic contract, which handles contract
     * upgrades using the UUPS approach
     */
    function _beforeFallback() internal override {
        super._beforeFallback();
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {IRollupUser} from "./IRollupLogic.sol";
import "../libraries/UUPSNotUpgradeable.sol";
import "./RollupCore.sol";

abstract contract AbsRollupUserLogic is
    RollupCore,
    UUPSNotUpgradeable,
    IRollupUserAbs,
    IChallengeResultReceiver
{
    using NodeLib for Node;
    using GlobalStateLib for GlobalState;

    modifier onlyValidator() {
        require(isValidator[msg.sender] || validatorWhitelistDisabled, "NOT_VALIDATOR");
        _;
    }

    uint256 internal immutable deployTimeChainId = block.chainid;

    function _chainIdChanged() internal view returns (bool) {
        return deployTimeChainId != block.chainid;
    }

    /**
     * @notice Extra number of blocks the validator can remain inactive before considered inactive
     *         This is 7 days assuming a 13.2 seconds block time
     */
    uint256 public constant VALIDATOR_AFK_BLOCKS = 45818;

    function _validatorIsAfk() internal view returns (bool) {
        Node memory latestNode = getNodeStorage(latestNodeCreated());
        if (latestNode.createdAtBlock == 0) return false;
        if (latestNode.createdAtBlock + confirmPeriodBlocks + VALIDATOR_AFK_BLOCKS < block.number) {
            return true;
        }
        return false;
    }

    function removeWhitelistAfterFork() external {
        require(!validatorWhitelistDisabled, "WHITELIST_DISABLED");
        require(_chainIdChanged(), "CHAIN_ID_NOT_CHANGED");
        validatorWhitelistDisabled = true;
    }

    function removeWhitelistAfterValidatorAfk() external {
        require(!validatorWhitelistDisabled, "WHITELIST_DISABLED");
        require(_validatorIsAfk(), "VALIDATOR_NOT_AFK");
        validatorWhitelistDisabled = true;
    }

    function isERC20Enabled() public view override returns (bool) {
        return stakeToken != address(0);
    }

    /**
     * @notice Reject the next unresolved node
     * @param stakerAddress Example staker staked on sibling, used to prove a node is on an unconfirmable branch and can be rejected
     */
    function rejectNextNode(address stakerAddress) external onlyValidator whenNotPaused {
        requireUnresolvedExists();
        uint64 latestConfirmedNodeNum = latestConfirmed();
        uint64 firstUnresolvedNodeNum = firstUnresolvedNode();
        Node storage firstUnresolvedNode_ = getNodeStorage(firstUnresolvedNodeNum);

        if (firstUnresolvedNode_.prevNum == latestConfirmedNodeNum) {
            /**If the first unresolved node is a child of the latest confirmed node, to prove it can be rejected, we show:
             * a) Its deadline has expired
             * b) *Some* staker is staked on a sibling

             * The following three checks are sufficient to prove b:
            */

            // 1.  StakerAddress is indeed a staker
            require(isStakedOnLatestConfirmed(stakerAddress), "NOT_STAKED");

            // 2. Staker's latest staked node hasn't been resolved; this proves that staker's latest staked node can't be a parent of firstUnresolvedNode
            requireUnresolved(latestStakedNode(stakerAddress));

            // 3. staker isn't staked on first unresolved node; this proves staker's latest staked can't be a child of firstUnresolvedNode (recall staking on node requires staking on all of its parents)
            require(!nodeHasStaker(firstUnresolvedNodeNum, stakerAddress), "STAKED_ON_TARGET");
            // If a staker is staked on a node that is neither a child nor a parent of firstUnresolvedNode, it must be a sibling, QED

            // Verify the block's deadline has passed
            firstUnresolvedNode_.requirePastDeadline();

            getNodeStorage(latestConfirmedNodeNum).requirePastChildConfirmDeadline();

            removeOldZombies(0);

            // Verify that no staker is staked on this node
            require(
                firstUnresolvedNode_.stakerCount == countStakedZombies(firstUnresolvedNodeNum),
                "HAS_STAKERS"
            );
        }
        // Simpler case: if the first unreseolved node doesn't point to the last confirmed node, another branch was confirmed and can simply reject it outright
        _rejectNextNode();

        emit NodeRejected(firstUnresolvedNodeNum);
    }

    /**
     * @notice Confirm the next unresolved node
     * @param blockHash The block hash at the end of the assertion
     * @param sendRoot The send root at the end of the assertion
     */
    function confirmNextNode(bytes32 blockHash, bytes32 sendRoot)
        external
        onlyValidator
        whenNotPaused
    {
        requireUnresolvedExists();

        uint64 nodeNum = firstUnresolvedNode();
        Node storage node = getNodeStorage(nodeNum);

        // Verify the block's deadline has passed
        node.requirePastDeadline();

        // Check that prev is latest confirmed
        assert(node.prevNum == latestConfirmed());

        Node storage prevNode = getNodeStorage(node.prevNum);
        prevNode.requirePastChildConfirmDeadline();

        removeOldZombies(0);

        // Require only zombies are staked on siblings to this node, and there's at least one non-zombie staked on this node
        uint256 stakedZombies = countStakedZombies(nodeNum);
        uint256 zombiesStakedOnOtherChildren = countZombiesStakedOnChildren(node.prevNum) -
            stakedZombies;
        require(node.stakerCount > stakedZombies, "NO_STAKERS");
        require(
            prevNode.childStakerCount == node.stakerCount + zombiesStakedOnOtherChildren,
            "NOT_ALL_STAKED"
        );

        confirmNode(nodeNum, blockHash, sendRoot);
    }

    /**
     * @notice Create a new stake
     * @param depositAmount The amount of either eth or tokens staked
     */
    function _newStake(uint256 depositAmount) internal onlyValidator whenNotPaused {
        // Verify that sender is not already a staker
        require(!isStaked(msg.sender), "ALREADY_STAKED");
        require(!isZombie(msg.sender), "STAKER_IS_ZOMBIE");
        require(depositAmount >= currentRequiredStake(), "NOT_ENOUGH_STAKE");

        createNewStake(msg.sender, depositAmount);
    }

    /**
     * @notice Move stake onto existing child node
     * @param nodeNum Index of the node to move stake to. This must by a child of the node the staker is currently staked on
     * @param nodeHash Node hash of nodeNum (protects against reorgs)
     */
    function stakeOnExistingNode(uint64 nodeNum, bytes32 nodeHash)
        public
        onlyValidator
        whenNotPaused
    {
        require(isStakedOnLatestConfirmed(msg.sender), "NOT_STAKED");

        require(
            nodeNum >= firstUnresolvedNode() && nodeNum <= latestNodeCreated(),
            "NODE_NUM_OUT_OF_RANGE"
        );
        Node storage node = getNodeStorage(nodeNum);
        require(node.nodeHash == nodeHash, "NODE_REORG");
        require(latestStakedNode(msg.sender) == node.prevNum, "NOT_STAKED_PREV");
        stakeOnNode(msg.sender, nodeNum);
    }

    /**
     * @notice Create a new node and move stake onto it
     * @param assertion The assertion data
     * @param expectedNodeHash The hash of the node being created (protects against reorgs)
     */
    function stakeOnNewNode(
        RollupLib.Assertion calldata assertion,
        bytes32 expectedNodeHash,
        uint256 prevNodeInboxMaxCount
    ) public onlyValidator whenNotPaused {
        require(isStakedOnLatestConfirmed(msg.sender), "NOT_STAKED");
        // Ensure staker is staked on the previous node
        uint64 prevNode = latestStakedNode(msg.sender);

        {
            uint256 timeSinceLastNode = block.number - getNode(prevNode).createdAtBlock;
            // Verify that assertion meets the minimum Delta time requirement
            require(timeSinceLastNode >= minimumAssertionPeriod, "TIME_DELTA");

            // Minimum size requirement: any assertion must consume at least all inbox messages
            // put into L1 inbox before the prev node’s L1 blocknum.
            // We make an exception if the machine enters the errored state,
            // as it can't consume future batches.
            require(
                assertion.afterState.machineStatus == MachineStatus.ERRORED ||
                    assertion.afterState.globalState.getInboxPosition() >= prevNodeInboxMaxCount,
                "TOO_SMALL"
            );
            // Minimum size requirement: any assertion must contain at least one block
            require(assertion.numBlocks > 0, "EMPTY_ASSERTION");

            // The rollup cannot advance normally from an errored state
            require(
                assertion.beforeState.machineStatus == MachineStatus.FINISHED,
                "BAD_PREV_STATUS"
            );
        }
        createNewNode(assertion, prevNode, prevNodeInboxMaxCount, expectedNodeHash);

        stakeOnNode(msg.sender, latestNodeCreated());
    }

    /**
     * @notice Refund a staker that is currently staked on or before the latest confirmed node
     * @dev Since a staker is initially placed in the latest confirmed node, if they don't move it
     * a griefer can remove their stake. It is recomended to batch together the txs to place a stake
     * and move it to the desired node.
     * @param stakerAddress Address of the staker whose stake is refunded
     */
    function returnOldDeposit(address stakerAddress) external override onlyValidator whenNotPaused {
        require(latestStakedNode(stakerAddress) <= latestConfirmed(), "TOO_RECENT");
        requireUnchallengedStaker(stakerAddress);
        withdrawStaker(stakerAddress);
    }

    /**
     * @notice Increase the amount staked for the given staker
     * @param stakerAddress Address of the staker whose stake is increased
     * @param depositAmount The amount of either eth or tokens deposited
     */
    function _addToDeposit(address stakerAddress, uint256 depositAmount)
        internal
        onlyValidator
        whenNotPaused
    {
        requireUnchallengedStaker(stakerAddress);
        increaseStakeBy(stakerAddress, depositAmount);
    }

    /**
     * @notice Reduce the amount staked for the sender (difference between initial amount staked and target is creditted back to the sender).
     * @param target Target amount of stake for the staker. If this is below the current minimum, it will be set to minimum instead
     */
    function reduceDeposit(uint256 target) external onlyValidator whenNotPaused {
        requireUnchallengedStaker(msg.sender);
        uint256 currentRequired = currentRequiredStake();
        if (target < currentRequired) {
            target = currentRequired;
        }
        reduceStakeTo(msg.sender, target);
    }

    /**
     * @notice Start a challenge between the given stakers over the node created by the first staker assuming that the two are staked on conflicting nodes. N.B.: challenge creator does not necessarily need to be one of the two asserters.
     * @param stakers Stakers engaged in the challenge. The first staker should be staked on the first node
     * @param nodeNums Nodes of the stakers engaged in the challenge. The first node should be the earliest and is the one challenged
     * @param machineStatuses The before and after machine status for the first assertion
     * @param globalStates The before and after global state for the first assertion
     * @param numBlocks The number of L2 blocks contained in the first assertion
     * @param secondExecutionHash The execution hash of the second assertion
     * @param proposedTimes Times that the two nodes were proposed
     * @param wasmModuleRoots The wasm module roots at the time of the creation of each assertion
     */
    function createChallenge(
        address[2] calldata stakers,
        uint64[2] calldata nodeNums,
        MachineStatus[2] calldata machineStatuses,
        GlobalState[2] calldata globalStates,
        uint64 numBlocks,
        bytes32 secondExecutionHash,
        uint256[2] calldata proposedTimes,
        bytes32[2] calldata wasmModuleRoots
    ) external onlyValidator whenNotPaused {
        require(nodeNums[0] < nodeNums[1], "WRONG_ORDER");
        require(nodeNums[1] <= latestNodeCreated(), "NOT_PROPOSED");
        require(latestConfirmed() < nodeNums[0], "ALREADY_CONFIRMED");

        Node storage node1 = getNodeStorage(nodeNums[0]);
        Node storage node2 = getNodeStorage(nodeNums[1]);

        // ensure nodes staked on the same parent (and thus in conflict)
        require(node1.prevNum == node2.prevNum, "DIFF_PREV");

        // ensure both stakers aren't currently in challenge
        requireUnchallengedStaker(stakers[0]);
        requireUnchallengedStaker(stakers[1]);

        require(nodeHasStaker(nodeNums[0], stakers[0]), "STAKER1_NOT_STAKED");
        require(nodeHasStaker(nodeNums[1], stakers[1]), "STAKER2_NOT_STAKED");

        // Check param data against challenge hash
        require(
            node1.challengeHash ==
                RollupLib.challengeRootHash(
                    RollupLib.executionHash(machineStatuses, globalStates, numBlocks),
                    proposedTimes[0],
                    wasmModuleRoots[0]
                ),
            "CHAL_HASH1"
        );

        require(
            node2.challengeHash ==
                RollupLib.challengeRootHash(
                    secondExecutionHash,
                    proposedTimes[1],
                    wasmModuleRoots[1]
                ),
            "CHAL_HASH2"
        );

        // Calculate upper limit for allowed node proposal time:
        uint256 commonEndTime = getNodeStorage(node1.prevNum).firstChildBlock +
            // Dispute start: dispute timer for a node starts when its first child is created
            (node1.deadlineBlock - proposedTimes[0]) +
            extraChallengeTimeBlocks; // add dispute window to dispute start time
        if (commonEndTime < proposedTimes[1]) {
            // The 2nd node was created too late; loses challenge automatically.
            completeChallengeImpl(stakers[0], stakers[1]);
            return;
        }
        // Start a challenge between staker1 and staker2. Staker1 will defend the correctness of node1, and staker2 will challenge it.
        uint64 challengeIndex = createChallengeHelper(
            stakers,
            machineStatuses,
            globalStates,
            numBlocks,
            wasmModuleRoots,
            commonEndTime - proposedTimes[0],
            commonEndTime - proposedTimes[1]
        ); // trusted external call

        challengeStarted(stakers[0], stakers[1], challengeIndex);

        emit RollupChallengeStarted(challengeIndex, stakers[0], stakers[1], nodeNums[0]);
    }

    function createChallengeHelper(
        address[2] calldata stakers,
        MachineStatus[2] calldata machineStatuses,
        GlobalState[2] calldata globalStates,
        uint64 numBlocks,
        bytes32[2] calldata wasmModuleRoots,
        uint256 asserterTimeLeft,
        uint256 challengerTimeLeft
    ) internal returns (uint64) {
        return
            challengeManager.createChallenge(
                wasmModuleRoots[0],
                machineStatuses,
                globalStates,
                numBlocks,
                stakers[0],
                stakers[1],
                asserterTimeLeft,
                challengerTimeLeft
            );
    }

    /**
     * @notice Inform the rollup that the challenge between the given stakers is completed
     * @param winningStaker Address of the winning staker
     * @param losingStaker Address of the losing staker
     */
    function completeChallenge(
        uint256 challengeIndex,
        address winningStaker,
        address losingStaker
    ) external override whenNotPaused {
        // Only the challenge manager contract can call this to declare the winner and loser
        require(msg.sender == address(challengeManager), "WRONG_SENDER");
        require(challengeIndex == inChallenge(winningStaker, losingStaker), "NOT_IN_CHAL");
        completeChallengeImpl(winningStaker, losingStaker);
    }

    function completeChallengeImpl(address winningStaker, address losingStaker) private {
        uint256 remainingLoserStake = amountStaked(losingStaker);
        uint256 winnerStake = amountStaked(winningStaker);
        if (remainingLoserStake > winnerStake) {
            // If loser has a higher stake than the winner, refund the difference
            remainingLoserStake -= reduceStakeTo(losingStaker, winnerStake);
        }

        // Reward the winner with half the remaining stake
        uint256 amountWon = remainingLoserStake / 2;
        increaseStakeBy(winningStaker, amountWon);
        remainingLoserStake -= amountWon;
        // We deliberately leave loser in challenge state to prevent them from
        // doing certain thing that are allowed only to parties not in a challenge
        clearChallenge(winningStaker);
        // Credit the other half to the loserStakeEscrow address
        increaseWithdrawableFunds(loserStakeEscrow, remainingLoserStake);
        // Turning loser into zombie renders the loser's remaining stake inaccessible
        turnIntoZombie(losingStaker);
    }

    /**
     * @notice Remove the given zombie from nodes it is staked on, moving backwords from the latest node it is staked on
     * @param zombieNum Index of the zombie to remove
     * @param maxNodes Maximum number of nodes to remove the zombie from (to limit the cost of this transaction)
     */
    function removeZombie(uint256 zombieNum, uint256 maxNodes)
        external
        onlyValidator
        whenNotPaused
    {
        require(zombieNum < zombieCount(), "NO_SUCH_ZOMBIE");
        address zombieStakerAddress = zombieAddress(zombieNum);
        uint64 latestNodeStaked = zombieLatestStakedNode(zombieNum);
        uint256 nodesRemoved = 0;
        uint256 latestConfirmedNum = latestConfirmed();
        while (latestNodeStaked >= latestConfirmedNum && nodesRemoved < maxNodes) {
            Node storage node = getNodeStorage(latestNodeStaked);
            removeStaker(latestNodeStaked, zombieStakerAddress);
            latestNodeStaked = node.prevNum;
            nodesRemoved++;
        }
        if (latestNodeStaked < latestConfirmedNum) {
            removeZombie(zombieNum);
        } else {
            zombieUpdateLatestStakedNode(zombieNum, latestNodeStaked);
        }
    }

    /**
     * @notice Remove any zombies whose latest stake is earlier than the latest confirmed node
     * @param startIndex Index in the zombie list to start removing zombies from (to limit the cost of this transaction)
     */
    function removeOldZombies(uint256 startIndex) public onlyValidator whenNotPaused {
        uint256 currentZombieCount = zombieCount();
        uint256 latestConfirmedNum = latestConfirmed();
        for (uint256 i = startIndex; i < currentZombieCount; i++) {
            while (zombieLatestStakedNode(i) < latestConfirmedNum) {
                removeZombie(i);
                currentZombieCount--;
                if (i >= currentZombieCount) {
                    return;
                }
            }
        }
    }

    /**
     * @notice Calculate the current amount of funds required to place a new stake in the rollup
     * @dev If the stake requirement get's too high, this function may start reverting due to overflow, but
     * that only blocks operations that should be blocked anyway
     * @return The current minimum stake requirement
     */
    function currentRequiredStake(
        uint256 _blockNumber,
        uint64 _firstUnresolvedNodeNum,
        uint256 _latestCreatedNode
    ) internal view returns (uint256) {
        // If there are no unresolved nodes, then you can use the base stake
        if (_firstUnresolvedNodeNum - 1 == _latestCreatedNode) {
            return baseStake;
        }
        uint256 firstUnresolvedDeadline = getNodeStorage(_firstUnresolvedNodeNum).deadlineBlock;
        if (_blockNumber < firstUnresolvedDeadline) {
            return baseStake;
        }
        uint24[10] memory numerators = [
            1,
            122971,
            128977,
            80017,
            207329,
            114243,
            314252,
            129988,
            224562,
            162163
        ];
        uint24[10] memory denominators = [
            1,
            114736,
            112281,
            64994,
            157126,
            80782,
            207329,
            80017,
            128977,
            86901
        ];
        uint256 firstUnresolvedAge = _blockNumber - firstUnresolvedDeadline;
        uint256 periodsPassed = (firstUnresolvedAge * 10) / confirmPeriodBlocks;
        uint256 baseMultiplier = 2**(periodsPassed / 10);
        uint256 withNumerator = baseMultiplier * numerators[periodsPassed % 10];
        uint256 multiplier = withNumerator / denominators[periodsPassed % 10];
        if (multiplier == 0) {
            multiplier = 1;
        }
        return baseStake * multiplier;
    }

    /**
     * @notice Calculate the current amount of funds required to place a new stake in the rollup
     * @dev If the stake requirement get's too high, this function may start reverting due to overflow, but
     * that only blocks operations that should be blocked anyway
     * @return The current minimum stake requirement
     */
    function requiredStake(
        uint256 blockNumber,
        uint64 firstUnresolvedNodeNum,
        uint64 latestCreatedNode
    ) external view returns (uint256) {
        return currentRequiredStake(blockNumber, firstUnresolvedNodeNum, latestCreatedNode);
    }

    function owner() external view returns (address) {
        return _getAdmin();
    }

    function currentRequiredStake() public view returns (uint256) {
        uint64 firstUnresolvedNodeNum = firstUnresolvedNode();

        return currentRequiredStake(block.number, firstUnresolvedNodeNum, latestNodeCreated());
    }

    /**
     * @notice Calculate the number of zombies staked on the given node
     *
     * @dev This function could be uncallable if there are too many zombies. However,
     * removeZombie and removeOldZombies can be used to remove any zombies that exist
     * so that this will then be callable
     *
     * @param nodeNum The node on which to count staked zombies
     * @return The number of zombies staked on the node
     */
    function countStakedZombies(uint64 nodeNum) public view override returns (uint256) {
        uint256 currentZombieCount = zombieCount();
        uint256 stakedZombieCount = 0;
        for (uint256 i = 0; i < currentZombieCount; i++) {
            if (nodeHasStaker(nodeNum, zombieAddress(i))) {
                stakedZombieCount++;
            }
        }
        return stakedZombieCount;
    }

    /**
     * @notice Calculate the number of zombies staked on a child of the given node
     *
     * @dev This function could be uncallable if there are too many zombies. However,
     * removeZombie and removeOldZombies can be used to remove any zombies that exist
     * so that this will then be callable
     *
     * @param nodeNum The parent node on which to count zombies staked on children
     * @return The number of zombies staked on children of the node
     */
    function countZombiesStakedOnChildren(uint64 nodeNum) public view override returns (uint256) {
        uint256 currentZombieCount = zombieCount();
        uint256 stakedZombieCount = 0;
        for (uint256 i = 0; i < currentZombieCount; i++) {
            Zombie storage zombie = getZombieStorage(i);
            // If this zombie is staked on this node, but its _latest_ staked node isn't this node,
            // then it must be staked on a child of this node.
            if (
                zombie.latestStakedNode != nodeNum && nodeHasStaker(nodeNum, zombie.stakerAddress)
            ) {
                stakedZombieCount++;
            }
        }
        return stakedZombieCount;
    }

    /**
     * @notice Verify that there are some number of nodes still unresolved
     */
    function requireUnresolvedExists() public view override {
        uint256 firstUnresolved = firstUnresolvedNode();
        require(
            firstUnresolved > latestConfirmed() && firstUnresolved <= latestNodeCreated(),
            "NO_UNRESOLVED"
        );
    }

    function requireUnresolved(uint256 nodeNum) public view override {
        require(nodeNum >= firstUnresolvedNode(), "ALREADY_DECIDED");
        require(nodeNum <= latestNodeCreated(), "DOESNT_EXIST");
    }

    /**
     * @notice Verify that the given address is staked and not actively in a challenge
     * @param stakerAddress Address to check
     */
    function requireUnchallengedStaker(address stakerAddress) private view {
        require(isStaked(stakerAddress), "NOT_STAKED");
        require(currentChallenge(stakerAddress) == NO_CHAL_INDEX, "IN_CHAL");
    }
}

contract RollupUserLogic is AbsRollupUserLogic, IRollupUser {
    /// @dev the user logic just validated configuration and shouldn't write to state during init
    /// this allows the admin logic to ensure consistency on parameters.
    function initialize(address _stakeToken) external view override onlyProxy {
        require(_stakeToken == address(0), "NO_TOKEN_ALLOWED");
        require(!isERC20Enabled(), "FACET_NOT_ERC20");
    }

    /**
     * @notice Create a new stake on an existing node
     * @param nodeNum Number of the node your stake will be place one
     * @param nodeHash Node hash of the node with the given nodeNum
     */
    function newStakeOnExistingNode(uint64 nodeNum, bytes32 nodeHash) external payable override {
        _newStake(msg.value);
        stakeOnExistingNode(nodeNum, nodeHash);
    }

    /**
     * @notice Create a new stake on a new node
     * @param assertion Assertion describing the state change between the old node and the new one
     * @param expectedNodeHash Node hash of the node that will be created
     * @param prevNodeInboxMaxCount Total of messages in the inbox as of the previous node
     */
    function newStakeOnNewNode(
        RollupLib.Assertion calldata assertion,
        bytes32 expectedNodeHash,
        uint256 prevNodeInboxMaxCount
    ) external payable override {
        _newStake(msg.value);
        stakeOnNewNode(assertion, expectedNodeHash, prevNodeInboxMaxCount);
    }

    /**
     * @notice Increase the amount staked eth for the given staker
     * @param stakerAddress Address of the staker whose stake is increased
     */
    function addToDeposit(address stakerAddress)
        external
        payable
        override
        onlyValidator
        whenNotPaused
    {
        _addToDeposit(stakerAddress, msg.value);
    }

    /**
     * @notice Withdraw uncommitted funds owned by sender from the rollup chain
     */
    function withdrawStakerFunds() external override onlyValidator whenNotPaused returns (uint256) {
        uint256 amount = withdrawFunds(msg.sender);
        // This is safe because it occurs after all checks and effects
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "TRANSFER_FAILED");
        return amount;
    }
}

contract ERC20RollupUserLogic is AbsRollupUserLogic, IRollupUserERC20 {
    /// @dev the user logic just validated configuration and shouldn't write to state during init
    /// this allows the admin logic to ensure consistency on parameters.
    function initialize(address _stakeToken) external view override onlyProxy {
        require(_stakeToken != address(0), "NEED_STAKE_TOKEN");
        require(isERC20Enabled(), "FACET_NOT_ERC20");
    }

    /**
     * @notice Create a new stake on an existing node
     * @param tokenAmount Amount of the rollups staking token to stake
     * @param nodeNum Number of the node your stake will be place one
     * @param nodeHash Node hash of the node with the given nodeNum
     */
    function newStakeOnExistingNode(
        uint256 tokenAmount,
        uint64 nodeNum,
        bytes32 nodeHash
    ) external override {
        _newStake(tokenAmount);
        stakeOnExistingNode(nodeNum, nodeHash);
        /// @dev This is an external call, safe because it's at the end of the function
        receiveTokens(tokenAmount);
    }

    /**
     * @notice Create a new stake on a new node
     * @param tokenAmount Amount of the rollups staking token to stake
     * @param assertion Assertion describing the state change between the old node and the new one
     * @param expectedNodeHash Node hash of the node that will be created
     * @param prevNodeInboxMaxCount Total of messages in the inbox as of the previous node
     */
    function newStakeOnNewNode(
        uint256 tokenAmount,
        RollupLib.Assertion calldata assertion,
        bytes32 expectedNodeHash,
        uint256 prevNodeInboxMaxCount
    ) external override {
        _newStake(tokenAmount);
        stakeOnNewNode(assertion, expectedNodeHash, prevNodeInboxMaxCount);
        /// @dev This is an external call, safe because it's at the end of the function
        receiveTokens(tokenAmount);
    }

    /**
     * @notice Increase the amount staked tokens for the given staker
     * @param stakerAddress Address of the staker whose stake is increased
     * @param tokenAmount the amount of tokens staked
     */
    function addToDeposit(address stakerAddress, uint256 tokenAmount)
        external
        onlyValidator
        whenNotPaused
    {
        _addToDeposit(stakerAddress, tokenAmount);
        /// @dev This is an external call, safe because it's at the end of the function
        receiveTokens(tokenAmount);
    }

    /**
     * @notice Withdraw uncommitted funds owned by sender from the rollup chain
     */
    function withdrawStakerFunds() external override onlyValidator whenNotPaused returns (uint256) {
        uint256 amount = withdrawFunds(msg.sender);
        // This is safe because it occurs after all checks and effects
        require(IERC20Upgradeable(stakeToken).transfer(msg.sender, amount), "TRANSFER_FAILED");
        return amount;
    }

    function receiveTokens(uint256 tokenAmount) private {
        require(
            IERC20Upgradeable(stakeToken).transferFrom(msg.sender, address(this), tokenAmount),
            "TRANSFER_FAIL"
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/draft-IERC1822.sol";
import {DoubleLogicERC1967Upgrade} from "./AdminFallbackProxy.sol";

/**
 * @dev UUPSUpgradeable by OpenZeppelin but not upgradeable. This is expected to be used on the secondary
 * logic slot behind a DoubleLogicERC1967Upgrade proxy
 */
abstract contract UUPSNotUpgradeable is IERC1822Proxiable, DoubleLogicERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(
            _getSecondaryImplementation() == __self,
            "Function must be called through active proxy"
        );
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(
            address(this) == __self,
            "UUPSNotUpgradeable: must not be called through delegatecall"
        );
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SECONDARY_SLOT;
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./Node.sol";
import "./IRollupCore.sol";
import "./RollupLib.sol";
import "./IRollupEventInbox.sol";
import "./IRollupCore.sol";

import "../challenge/IChallengeManager.sol";

import "../bridge/ISequencerInbox.sol";
import "../bridge/IBridge.sol";
import "../bridge/IOutbox.sol";

import {NO_CHAL_INDEX} from "../libraries/Constants.sol";

abstract contract RollupCore is IRollupCore, PausableUpgradeable {
    using NodeLib for Node;
    using GlobalStateLib for GlobalState;

    // Rollup Config
    uint64 public confirmPeriodBlocks;
    uint64 public extraChallengeTimeBlocks;
    uint256 public chainId;
    uint256 public baseStake;
    bytes32 public wasmModuleRoot;

    IInbox public inbox;
    IBridge public bridge;
    IOutbox public outbox;
    ISequencerInbox public sequencerInbox;
    IRollupEventInbox public rollupEventInbox;
    IChallengeManager public override challengeManager;

    // misc useful contracts when interacting with the rollup
    address public validatorUtils;
    address public validatorWalletCreator;

    // when a staker loses a challenge, half of their funds get escrowed in this address
    address public loserStakeEscrow;
    address public stakeToken;
    uint256 public minimumAssertionPeriod;

    mapping(address => bool) public isValidator;

    // Stakers become Zombies after losing a challenge
    struct Zombie {
        address stakerAddress;
        uint64 latestStakedNode;
    }

    uint64 private _latestConfirmed;
    uint64 private _firstUnresolvedNode;
    uint64 private _latestNodeCreated;
    uint64 private _lastStakeBlock;
    mapping(uint64 => Node) private _nodes;
    mapping(uint64 => mapping(address => bool)) private _nodeStakers;

    address[] private _stakerList;
    mapping(address => Staker) public _stakerMap;

    Zombie[] private _zombies;

    mapping(address => uint256) private _withdrawableFunds;
    uint256 public totalWithdrawableFunds;
    uint256 public rollupDeploymentBlock;

    // The node number of the initial node
    uint64 internal constant GENESIS_NODE = 0;

    bool public validatorWhitelistDisabled;

    /**
     * @notice Get a storage reference to the Node for the given node index
     * @param nodeNum Index of the node
     * @return Node struct
     */
    function getNodeStorage(uint64 nodeNum) internal view returns (Node storage) {
        return _nodes[nodeNum];
    }

    /**
     * @notice Get the Node for the given index.
     */
    function getNode(uint64 nodeNum) public view override returns (Node memory) {
        return getNodeStorage(nodeNum);
    }

    /**
     * @notice Check if the specified node has been staked on by the provided staker.
     * Only accurate at the latest confirmed node and afterwards.
     */
    function nodeHasStaker(uint64 nodeNum, address staker) public view override returns (bool) {
        return _nodeStakers[nodeNum][staker];
    }

    /**
     * @notice Get the address of the staker at the given index
     * @param stakerNum Index of the staker
     * @return Address of the staker
     */
    function getStakerAddress(uint64 stakerNum) external view override returns (address) {
        return _stakerList[stakerNum];
    }

    /**
     * @notice Check whether the given staker is staked
     * @param staker Staker address to check
     * @return True or False for whether the staker was staked
     */
    function isStaked(address staker) public view override returns (bool) {
        return _stakerMap[staker].isStaked;
    }

    /**
     * @notice Check whether the given staker is staked on the latest confirmed node,
     * which includes if the staker is staked on a descendent of the latest confirmed node.
     * @param staker Staker address to check
     * @return True or False for whether the staker was staked
     */
    function isStakedOnLatestConfirmed(address staker) public view returns (bool) {
        return _stakerMap[staker].isStaked && nodeHasStaker(_latestConfirmed, staker);
    }

    /**
     * @notice Get the latest staked node of the given staker
     * @param staker Staker address to lookup
     * @return Latest node staked of the staker
     */
    function latestStakedNode(address staker) public view override returns (uint64) {
        return _stakerMap[staker].latestStakedNode;
    }

    /**
     * @notice Get the current challenge of the given staker
     * @param staker Staker address to lookup
     * @return Current challenge of the staker
     */
    function currentChallenge(address staker) public view override returns (uint64) {
        return _stakerMap[staker].currentChallenge;
    }

    /**
     * @notice Get the amount staked of the given staker
     * @param staker Staker address to lookup
     * @return Amount staked of the staker
     */
    function amountStaked(address staker) public view override returns (uint256) {
        return _stakerMap[staker].amountStaked;
    }

    /**
     * @notice Retrieves stored information about a requested staker
     * @param staker Staker address to retrieve
     * @return A structure with information about the requested staker
     */
    function getStaker(address staker) external view override returns (Staker memory) {
        return _stakerMap[staker];
    }

    /**
     * @notice Get the original staker address of the zombie at the given index
     * @param zombieNum Index of the zombie to lookup
     * @return Original staker address of the zombie
     */
    function zombieAddress(uint256 zombieNum) public view override returns (address) {
        return _zombies[zombieNum].stakerAddress;
    }

    /**
     * @notice Get Latest node that the given zombie at the given index is staked on
     * @param zombieNum Index of the zombie to lookup
     * @return Latest node that the given zombie is staked on
     */
    function zombieLatestStakedNode(uint256 zombieNum) public view override returns (uint64) {
        return _zombies[zombieNum].latestStakedNode;
    }

    /**
     * @notice Retrieves stored information about a requested zombie
     * @param zombieNum Index of the zombie to lookup
     * @return A structure with information about the requested staker
     */
    function getZombieStorage(uint256 zombieNum) internal view returns (Zombie storage) {
        return _zombies[zombieNum];
    }

    /// @return Current number of un-removed zombies
    function zombieCount() public view override returns (uint256) {
        return _zombies.length;
    }

    function isZombie(address staker) public view override returns (bool) {
        for (uint256 i = 0; i < _zombies.length; i++) {
            if (staker == _zombies[i].stakerAddress) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Get the amount of funds withdrawable by the given address
     * @param user Address to check the funds of
     * @return Amount of funds withdrawable by user
     */
    function withdrawableFunds(address user) external view override returns (uint256) {
        return _withdrawableFunds[user];
    }

    /**
     * @return Index of the first unresolved node
     * @dev If all nodes have been resolved, this will be latestNodeCreated + 1
     */
    function firstUnresolvedNode() public view override returns (uint64) {
        return _firstUnresolvedNode;
    }

    /// @return Index of the latest confirmed node
    function latestConfirmed() public view override returns (uint64) {
        return _latestConfirmed;
    }

    /// @return Index of the latest rollup node created
    function latestNodeCreated() public view override returns (uint64) {
        return _latestNodeCreated;
    }

    /// @return Ethereum block that the most recent stake was created
    function lastStakeBlock() external view override returns (uint64) {
        return _lastStakeBlock;
    }

    /// @return Number of active stakers currently staked
    function stakerCount() public view override returns (uint64) {
        return uint64(_stakerList.length);
    }

    /**
     * @notice Initialize the core with an initial node
     * @param initialNode Initial node to start the chain with
     */
    function initializeCore(Node memory initialNode) internal {
        __Pausable_init();
        _nodes[GENESIS_NODE] = initialNode;
        _firstUnresolvedNode = GENESIS_NODE + 1;
    }

    /**
     * @notice React to a new node being created by storing it an incrementing the latest node counter
     * @param node Node that was newly created
     */
    function nodeCreated(Node memory node) internal {
        _latestNodeCreated++;
        _nodes[_latestNodeCreated] = node;
    }

    /// @notice Reject the next unresolved node
    function _rejectNextNode() internal {
        _firstUnresolvedNode++;
    }

    function confirmNode(
        uint64 nodeNum,
        bytes32 blockHash,
        bytes32 sendRoot
    ) internal {
        Node storage node = getNodeStorage(nodeNum);
        // Authenticate data against node's confirm data pre-image
        require(node.confirmData == RollupLib.confirmHash(blockHash, sendRoot), "CONFIRM_DATA");

        // trusted external call to outbox
        outbox.updateSendRoot(sendRoot, blockHash);

        _latestConfirmed = nodeNum;
        _firstUnresolvedNode = nodeNum + 1;

        emit NodeConfirmed(nodeNum, blockHash, sendRoot);
    }

    /**
     * @notice Create a new stake at latest confirmed node
     * @param stakerAddress Address of the new staker
     * @param depositAmount Stake amount of the new staker
     */
    function createNewStake(address stakerAddress, uint256 depositAmount) internal {
        uint64 stakerIndex = uint64(_stakerList.length);
        _stakerList.push(stakerAddress);
        _stakerMap[stakerAddress] = Staker(
            depositAmount,
            stakerIndex,
            _latestConfirmed,
            NO_CHAL_INDEX, // new staker is not in challenge
            true
        );
        _nodeStakers[_latestConfirmed][stakerAddress] = true;
        _lastStakeBlock = uint64(block.number);
        emit UserStakeUpdated(stakerAddress, 0, depositAmount);
    }

    /**
     * @notice Check to see whether the two stakers are in the same challenge
     * @param stakerAddress1 Address of the first staker
     * @param stakerAddress2 Address of the second staker
     * @return Address of the challenge that the two stakers are in
     */
    function inChallenge(address stakerAddress1, address stakerAddress2)
        internal
        view
        returns (uint64)
    {
        Staker storage staker1 = _stakerMap[stakerAddress1];
        Staker storage staker2 = _stakerMap[stakerAddress2];
        uint64 challenge = staker1.currentChallenge;
        require(challenge != NO_CHAL_INDEX, "NO_CHAL");
        require(challenge == staker2.currentChallenge, "DIFF_IN_CHAL");
        return challenge;
    }

    /**
     * @notice Make the given staker as not being in a challenge
     * @param stakerAddress Address of the staker to remove from a challenge
     */
    function clearChallenge(address stakerAddress) internal {
        Staker storage staker = _stakerMap[stakerAddress];
        staker.currentChallenge = NO_CHAL_INDEX;
    }

    /**
     * @notice Mark both the given stakers as engaged in the challenge
     * @param staker1 Address of the first staker
     * @param staker2 Address of the second staker
     * @param challenge Address of the challenge both stakers are now in
     */
    function challengeStarted(
        address staker1,
        address staker2,
        uint64 challenge
    ) internal {
        _stakerMap[staker1].currentChallenge = challenge;
        _stakerMap[staker2].currentChallenge = challenge;
    }

    /**
     * @notice Add to the stake of the given staker by the given amount
     * @param stakerAddress Address of the staker to increase the stake of
     * @param amountAdded Amount of stake to add to the staker
     */
    function increaseStakeBy(address stakerAddress, uint256 amountAdded) internal {
        Staker storage staker = _stakerMap[stakerAddress];
        uint256 initialStaked = staker.amountStaked;
        uint256 finalStaked = initialStaked + amountAdded;
        staker.amountStaked = finalStaked;
        emit UserStakeUpdated(stakerAddress, initialStaked, finalStaked);
    }

    /**
     * @notice Reduce the stake of the given staker to the given target
     * @param stakerAddress Address of the staker to reduce the stake of
     * @param target Amount of stake to leave with the staker
     * @return Amount of value released from the stake
     */
    function reduceStakeTo(address stakerAddress, uint256 target) internal returns (uint256) {
        Staker storage staker = _stakerMap[stakerAddress];
        uint256 current = staker.amountStaked;
        require(target <= current, "TOO_LITTLE_STAKE");
        uint256 amountWithdrawn = current - target;
        staker.amountStaked = target;
        increaseWithdrawableFunds(stakerAddress, amountWithdrawn);
        emit UserStakeUpdated(stakerAddress, current, target);
        return amountWithdrawn;
    }

    /**
     * @notice Remove the given staker and turn them into a zombie
     * @param stakerAddress Address of the staker to remove
     */
    function turnIntoZombie(address stakerAddress) internal {
        Staker storage staker = _stakerMap[stakerAddress];
        _zombies.push(Zombie(stakerAddress, staker.latestStakedNode));
        deleteStaker(stakerAddress);
    }

    /**
     * @notice Update the latest staked node of the zombie at the given index
     * @param zombieNum Index of the zombie to move
     * @param latest New latest node the zombie is staked on
     */
    function zombieUpdateLatestStakedNode(uint256 zombieNum, uint64 latest) internal {
        _zombies[zombieNum].latestStakedNode = latest;
    }

    /**
     * @notice Remove the zombie at the given index
     * @param zombieNum Index of the zombie to remove
     */
    function removeZombie(uint256 zombieNum) internal {
        _zombies[zombieNum] = _zombies[_zombies.length - 1];
        _zombies.pop();
    }

    /**
     * @notice Mark the given staker as staked on this node
     * @param staker Address of the staker to mark
     */
    function addStaker(uint64 nodeNum, address staker) internal {
        require(!_nodeStakers[nodeNum][staker], "ALREADY_STAKED");
        _nodeStakers[nodeNum][staker] = true;
        Node storage node = getNodeStorage(nodeNum);
        require(node.deadlineBlock != 0, "NO_NODE");

        uint64 prevCount = node.stakerCount;
        node.stakerCount = prevCount + 1;

        if (nodeNum > GENESIS_NODE) {
            Node storage parent = getNodeStorage(node.prevNum);
            parent.childStakerCount++;
            if (prevCount == 0) {
                parent.newChildConfirmDeadline(uint64(block.number) + confirmPeriodBlocks);
            }
        }
    }

    /**
     * @notice Remove the given staker from this node
     * @param staker Address of the staker to remove
     */
    function removeStaker(uint64 nodeNum, address staker) internal {
        require(_nodeStakers[nodeNum][staker], "NOT_STAKED");
        _nodeStakers[nodeNum][staker] = false;

        Node storage node = getNodeStorage(nodeNum);
        node.stakerCount--;

        if (nodeNum > GENESIS_NODE) {
            getNodeStorage(node.prevNum).childStakerCount--;
        }
    }

    /**
     * @notice Remove the given staker and return their stake
     * This should not be called if the staker is staked on a descendent of the latest confirmed node
     * @param stakerAddress Address of the staker withdrawing their stake
     */
    function withdrawStaker(address stakerAddress) internal {
        Staker storage staker = _stakerMap[stakerAddress];
        uint64 latestConfirmedNum = latestConfirmed();
        if (nodeHasStaker(latestConfirmedNum, stakerAddress)) {
            // Withdrawing a staker whose latest staked node isn't resolved should be impossible
            assert(staker.latestStakedNode == latestConfirmedNum);
            removeStaker(latestConfirmedNum, stakerAddress);
        }
        uint256 initialStaked = staker.amountStaked;
        increaseWithdrawableFunds(stakerAddress, initialStaked);
        deleteStaker(stakerAddress);
        emit UserStakeUpdated(stakerAddress, initialStaked, 0);
    }

    /**
     * @notice Advance the given staker to the given node
     * @param stakerAddress Address of the staker adding their stake
     * @param nodeNum Index of the node to stake on
     */
    function stakeOnNode(address stakerAddress, uint64 nodeNum) internal {
        Staker storage staker = _stakerMap[stakerAddress];
        addStaker(nodeNum, stakerAddress);
        staker.latestStakedNode = nodeNum;
    }

    /**
     * @notice Clear the withdrawable funds for the given address
     * @param account Address of the account to remove funds from
     * @return Amount of funds removed from account
     */
    function withdrawFunds(address account) internal returns (uint256) {
        uint256 amount = _withdrawableFunds[account];
        _withdrawableFunds[account] = 0;
        totalWithdrawableFunds -= amount;
        emit UserWithdrawableFundsUpdated(account, amount, 0);
        return amount;
    }

    /**
     * @notice Increase the withdrawable funds for the given address
     * @param account Address of the account to add withdrawable funds to
     */
    function increaseWithdrawableFunds(address account, uint256 amount) internal {
        uint256 initialWithdrawable = _withdrawableFunds[account];
        uint256 finalWithdrawable = initialWithdrawable + amount;
        _withdrawableFunds[account] = finalWithdrawable;
        totalWithdrawableFunds += amount;
        emit UserWithdrawableFundsUpdated(account, initialWithdrawable, finalWithdrawable);
    }

    /**
     * @notice Remove the given staker
     * @param stakerAddress Address of the staker to remove
     */
    function deleteStaker(address stakerAddress) private {
        Staker storage staker = _stakerMap[stakerAddress];
        require(staker.isStaked, "NOT_STAKED");
        uint64 stakerIndex = staker.index;
        _stakerList[stakerIndex] = _stakerList[_stakerList.length - 1];
        _stakerMap[_stakerList[stakerIndex]].index = stakerIndex;
        _stakerList.pop();
        delete _stakerMap[stakerAddress];
    }

    struct StakeOnNewNodeFrame {
        uint256 currentInboxSize;
        Node node;
        bytes32 executionHash;
        Node prevNode;
        bytes32 lastHash;
        bool hasSibling;
        uint64 deadlineBlock;
        bytes32 sequencerBatchAcc;
    }

    function createNewNode(
        RollupLib.Assertion calldata assertion,
        uint64 prevNodeNum,
        uint256 prevNodeInboxMaxCount,
        bytes32 expectedNodeHash
    ) internal returns (bytes32 newNodeHash) {
        require(
            assertion.afterState.machineStatus == MachineStatus.FINISHED ||
                assertion.afterState.machineStatus == MachineStatus.ERRORED,
            "BAD_AFTER_STATUS"
        );

        StakeOnNewNodeFrame memory memoryFrame;
        {
            // validate data
            memoryFrame.prevNode = getNode(prevNodeNum);
            memoryFrame.currentInboxSize = bridge.sequencerMessageCount();

            // Make sure the previous state is correct against the node being built on
            require(
                RollupLib.stateHash(assertion.beforeState, prevNodeInboxMaxCount) ==
                    memoryFrame.prevNode.stateHash,
                "PREV_STATE_HASH"
            );

            // Ensure that the assertion doesn't read past the end of the current inbox
            uint64 afterInboxCount = assertion.afterState.globalState.getInboxPosition();
            uint64 prevInboxPosition = assertion.beforeState.globalState.getInboxPosition();
            require(afterInboxCount >= prevInboxPosition, "INBOX_BACKWARDS");
            if (afterInboxCount == prevInboxPosition) {
                require(
                    assertion.afterState.globalState.getPositionInMessage() >=
                        assertion.beforeState.globalState.getPositionInMessage(),
                    "INBOX_POS_IN_MSG_BACKWARDS"
                );
            }
            // See validator/assertion.go ExecutionState RequiredBatches() for reasoning
            if (
                assertion.afterState.machineStatus == MachineStatus.ERRORED ||
                assertion.afterState.globalState.getPositionInMessage() > 0
            ) {
                // The current inbox message was read
                afterInboxCount++;
            }
            require(afterInboxCount <= memoryFrame.currentInboxSize, "INBOX_PAST_END");
            // This gives replay protection against the state of the inbox
            if (afterInboxCount > 0) {
                memoryFrame.sequencerBatchAcc = bridge.sequencerInboxAccs(afterInboxCount - 1);
            }
        }

        {
            memoryFrame.executionHash = RollupLib.executionHash(assertion);

            memoryFrame.deadlineBlock = uint64(block.number) + confirmPeriodBlocks;

            memoryFrame.hasSibling = memoryFrame.prevNode.latestChildNumber > 0;
            // here we don't use ternacy operator to remain compatible with slither
            if (memoryFrame.hasSibling) {
                memoryFrame.lastHash = getNodeStorage(memoryFrame.prevNode.latestChildNumber)
                    .nodeHash;
            } else {
                memoryFrame.lastHash = memoryFrame.prevNode.nodeHash;
            }

            newNodeHash = RollupLib.nodeHash(
                memoryFrame.hasSibling,
                memoryFrame.lastHash,
                memoryFrame.executionHash,
                memoryFrame.sequencerBatchAcc,
                wasmModuleRoot
            );
            require(
                newNodeHash == expectedNodeHash || expectedNodeHash == bytes32(0),
                "UNEXPECTED_NODE_HASH"
            );

            memoryFrame.node = NodeLib.createNode(
                RollupLib.stateHash(assertion.afterState, memoryFrame.currentInboxSize),
                RollupLib.challengeRootHash(
                    memoryFrame.executionHash,
                    block.number,
                    wasmModuleRoot
                ),
                RollupLib.confirmHash(assertion),
                prevNodeNum,
                memoryFrame.deadlineBlock,
                newNodeHash
            );
        }

        {
            uint64 nodeNum = latestNodeCreated() + 1;

            // Fetch a storage reference to prevNode since we copied our other one into memory
            // and we don't have enough stack available to keep to keep the previous storage reference around
            Node storage prevNode = getNodeStorage(prevNodeNum);
            prevNode.childCreated(nodeNum);

            nodeCreated(memoryFrame.node);
        }

        emit NodeCreated(
            latestNodeCreated(),
            memoryFrame.prevNode.nodeHash,
            newNodeHash,
            memoryFrame.executionHash,
            assertion,
            memoryFrame.sequencerBatchAcc,
            wasmModuleRoot,
            memoryFrame.currentInboxSize
        );

        return newNodeHash;
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

pragma experimental ABIEncoderV2;

import "../rollup/IRollupCore.sol";
import "../challenge/IChallengeManager.sol";

import {NO_CHAL_INDEX} from "../libraries/Constants.sol";

contract ValidatorUtils {
    using NodeLib for Node;

    enum ConfirmType {
        NONE,
        VALID,
        INVALID
    }

    enum NodeConflictType {
        NONE,
        FOUND,
        INDETERMINATE,
        INCOMPLETE
    }

    struct NodeConflict {
        NodeConflictType ty;
        uint64 node1;
        uint64 node2;
    }

    function findStakerConflict(
        IRollupCore rollup,
        address staker1,
        address staker2,
        uint256 maxDepth
    ) external view returns (NodeConflict memory) {
        uint64 staker1NodeNum = rollup.latestStakedNode(staker1);
        uint64 staker2NodeNum = rollup.latestStakedNode(staker2);
        return findNodeConflict(rollup, staker1NodeNum, staker2NodeNum, maxDepth);
    }

    function checkDecidableNextNode(IRollupUserAbs rollup) external view returns (ConfirmType) {
        try ValidatorUtils(address(this)).requireConfirmable(rollup) {
            return ConfirmType.VALID;
        } catch {}

        try ValidatorUtils(address(this)).requireRejectable(rollup) {
            return ConfirmType.INVALID;
        } catch {
            return ConfirmType.NONE;
        }
    }

    function requireRejectable(IRollupCore rollup) external view {
        IRollupUser(address(rollup)).requireUnresolvedExists();
        uint64 firstUnresolvedNode = rollup.firstUnresolvedNode();
        Node memory node = rollup.getNode(firstUnresolvedNode);
        if (node.prevNum == rollup.latestConfirmed()) {
            // Verify the block's deadline has passed
            require(block.number >= node.deadlineBlock, "BEFORE_DEADLINE");
            rollup.getNode(node.prevNum).requirePastChildConfirmDeadline();

            // Verify that no staker is staked on this node
            require(
                node.stakerCount ==
                    IRollupUser(address(rollup)).countStakedZombies(firstUnresolvedNode),
                "HAS_STAKERS"
            );
        }
    }

    function requireConfirmable(IRollupUserAbs rollup) external view {
        rollup.requireUnresolvedExists();

        uint256 stakerCount = rollup.stakerCount();
        // There is at least one non-zombie staker
        require(stakerCount > 0, "NO_STAKERS");

        uint64 firstUnresolved = rollup.firstUnresolvedNode();
        Node memory node = rollup.getNode(firstUnresolved);

        // Verify the block's deadline has passed
        node.requirePastDeadline();

        // Check that prev is latest confirmed
        assert(node.prevNum == rollup.latestConfirmed());

        Node memory prevNode = rollup.getNode(node.prevNum);
        prevNode.requirePastChildConfirmDeadline();

        uint256 zombiesStakedOnOtherChildren = rollup.countZombiesStakedOnChildren(node.prevNum) -
            rollup.countStakedZombies(firstUnresolved);
        require(
            prevNode.childStakerCount == node.stakerCount + zombiesStakedOnOtherChildren,
            "NOT_ALL_STAKED"
        );
    }

    function refundableStakers(IRollupCore rollup) external view returns (address[] memory) {
        uint256 stakerCount = rollup.stakerCount();
        address[] memory stakers = new address[](stakerCount);
        uint256 latestConfirmed = rollup.latestConfirmed();
        uint256 index = 0;
        for (uint64 i = 0; i < stakerCount; i++) {
            address staker = rollup.getStakerAddress(i);
            uint256 latestStakedNode = rollup.latestStakedNode(staker);
            if (latestStakedNode <= latestConfirmed && rollup.currentChallenge(staker) == 0) {
                stakers[index] = staker;
                index++;
            }
        }
        assembly {
            mstore(stakers, index)
        }
        return stakers;
    }

    function latestStaked(IRollupCore rollup, address staker)
        external
        view
        returns (uint64, Node memory)
    {
        uint64 num = rollup.latestStakedNode(staker);
        if (num == 0) {
            num = rollup.latestConfirmed();
        }
        Node memory node = rollup.getNode(num);
        return (num, node);
    }

    function stakedNodes(IRollupCore rollup, address staker)
        external
        view
        returns (uint64[] memory)
    {
        uint64[] memory nodes = new uint64[](100000);
        uint256 index = 0;
        for (uint64 i = rollup.latestConfirmed(); i <= rollup.latestNodeCreated(); i++) {
            if (rollup.nodeHasStaker(i, staker)) {
                nodes[index] = i;
                index++;
            }
        }
        // Shrink array down to real size
        assembly {
            mstore(nodes, index)
        }
        return nodes;
    }

    function findNodeConflict(
        IRollupCore rollup,
        uint64 node1,
        uint64 node2,
        uint256 maxDepth
    ) public view returns (NodeConflict memory) {
        uint64 firstUnresolvedNode = rollup.firstUnresolvedNode();
        uint64 node1Prev = rollup.getNode(node1).prevNum;
        uint64 node2Prev = rollup.getNode(node2).prevNum;

        for (uint256 i = 0; i < maxDepth; i++) {
            if (node1 == node2) {
                return NodeConflict(NodeConflictType.NONE, node1, node2);
            }
            if (node1Prev == node2Prev) {
                return NodeConflict(NodeConflictType.FOUND, node1, node2);
            }
            if (node1Prev < firstUnresolvedNode && node2Prev < firstUnresolvedNode) {
                return NodeConflict(NodeConflictType.INDETERMINATE, 0, 0);
            }
            if (node1Prev < node2Prev) {
                node2 = node2Prev;
                node2Prev = rollup.getNode(node2).prevNum;
            } else {
                node1 = node1Prev;
                node1Prev = rollup.getNode(node1).prevNum;
            }
        }
        return NodeConflict(NodeConflictType.INCOMPLETE, 0, 0);
    }

    function getStakers(
        IRollupCore rollup,
        uint64 startIndex,
        uint64 max
    ) public view returns (address[] memory, bool hasMore) {
        uint256 maxStakers = rollup.stakerCount();
        if (startIndex + max <= maxStakers) {
            maxStakers = startIndex + max;
            hasMore = true;
        }

        address[] memory stakers = new address[](maxStakers);
        for (uint64 i = 0; i < maxStakers; i++) {
            stakers[i] = rollup.getStakerAddress(startIndex + i);
        }
        return (stakers, hasMore);
    }

    function timedOutChallenges(
        IRollupCore rollup,
        uint64 startIndex,
        uint64 max
    ) external view returns (uint64[] memory, bool hasMore) {
        (address[] memory stakers, bool hasMoreStakers) = getStakers(rollup, startIndex, max);
        uint64[] memory challenges = new uint64[](stakers.length);
        uint256 index = 0;
        IChallengeManager challengeManager = rollup.challengeManager();
        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            uint64 challengeIndex = rollup.currentChallenge(staker);
            if (
                challengeIndex != NO_CHAL_INDEX &&
                challengeManager.isTimedOut(challengeIndex) &&
                challengeManager.currentResponder(challengeIndex) == staker
            ) {
                challenges[index++] = challengeIndex;
            }
        }
        // Shrink array down to real size
        assembly {
            mstore(challenges, index)
        }
        return (challenges, hasMoreStakers);
    }

    // Worst case runtime of O(depth), as it terminates if it switches paths.
    function areUnresolvedNodesLinear(IRollupCore rollup) external view returns (bool) {
        uint256 end = rollup.latestNodeCreated();
        for (uint64 i = rollup.firstUnresolvedNode(); i <= end; i++) {
            if (i > 0 && rollup.getNode(i).prevNum != i - 1) {
                return false;
            }
        }
        return true;
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../challenge/IChallengeManager.sol";
import "../libraries/DelegateCallAware.sol";
import "../libraries/IGasRefunder.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @dev thrown when arrays provided don't have the expected length
error BadArrayLength(uint256 expected, uint256 actual);

/// @dev thrown when a function is called by an address that isn't the owner nor a executor
error NotExecutorOrOwner(address actual);

/// @dev thrown when the particular address can't be called by an executor
error OnlyOwnerDestination(address expected, address actual, address destination);

/// @dev thrown when eth withdrawal tx fails
error WithdrawEthFail(address destination);

contract ValidatorWallet is OwnableUpgradeable, DelegateCallAware, GasRefundEnabled {
    using Address for address;

    /// @dev a executor is allowed to call only certain contracts
    mapping(address => bool) public executors;

    /// @dev allowed addresses which can be called by an executor
    mapping(address => bool) public allowedExecutorDestinations;

    modifier onlyExecutorOrOwner() {
        if (!executors[_msgSender()] && owner() != _msgSender())
            revert NotExecutorOrOwner(_msgSender());
        _;
    }

    event ExecutorUpdated(address indexed executor, bool isExecutor);

    /// @dev updates the executor addresses
    function setExecutor(address[] calldata newExecutors, bool[] calldata isExecutor)
        external
        onlyOwner
    {
        if (newExecutors.length != isExecutor.length)
            revert BadArrayLength(newExecutors.length, isExecutor.length);
        unchecked {
            for (uint64 i = 0; i < newExecutors.length; ++i) {
                executors[newExecutors[i]] = isExecutor[i];
                emit ExecutorUpdated(newExecutors[i], isExecutor[i]);
            }
        }
    }

    function initialize(
        address _executor,
        address _owner,
        address[] calldata initialExecutorAllowedDests
    ) external initializer onlyDelegated {
        __Ownable_init();
        transferOwnership(_owner);

        executors[_executor] = true;
        emit ExecutorUpdated(_executor, true);

        unchecked {
            for (uint64 i = 0; i < initialExecutorAllowedDests.length; ++i) {
                allowedExecutorDestinations[initialExecutorAllowedDests[i]] = true;
                emit AllowedExecutorDestinationsUpdated(initialExecutorAllowedDests[i], true);
            }
        }
    }

    event AllowedExecutorDestinationsUpdated(address indexed destination, bool isSet);

    /// @notice updates the destination addresses which executors are allowed to call
    function setAllowedExecutorDestinations(address[] calldata destinations, bool[] calldata isSet)
        external
        onlyOwner
    {
        if (destinations.length != isSet.length)
            revert BadArrayLength(destinations.length, isSet.length);
        unchecked {
            for (uint256 i = 0; i < destinations.length; ++i) {
                allowedExecutorDestinations[destinations[i]] = isSet[i];
                emit AllowedExecutorDestinationsUpdated(destinations[i], isSet[i]);
            }
        }
    }

    /// @dev reverts if the current function can't be called
    function validateExecuteTransaction(address destination) public view {
        if (!allowedExecutorDestinations[destination] && owner() != _msgSender())
            revert OnlyOwnerDestination(owner(), _msgSender(), destination);
    }

    function executeTransactions(
        bytes[] calldata data,
        address[] calldata destination,
        uint256[] calldata amount
    ) external payable {
        executeTransactionsWithGasRefunder(IGasRefunder(address(0)), data, destination, amount);
    }

    function executeTransactionsWithGasRefunder(
        IGasRefunder gasRefunder,
        bytes[] calldata data,
        address[] calldata destination,
        uint256[] calldata amount
    ) public payable onlyExecutorOrOwner refundsGas(gasRefunder) {
        uint256 numTxes = data.length;
        if (numTxes != destination.length) revert BadArrayLength(numTxes, destination.length);
        if (numTxes != amount.length) revert BadArrayLength(numTxes, amount.length);

        for (uint256 i = 0; i < numTxes; i++) {
            if (data[i].length > 0) require(destination[i].isContract(), "NO_CODE_AT_ADDR");
            validateExecuteTransaction(destination[i]);
            // We use a low level call here to allow for contract and non-contract calls
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = address(destination[i]).call{value: amount[i]}(data[i]);
            if (!success) {
                assembly {
                    let ptr := mload(0x40)
                    let size := returndatasize()
                    returndatacopy(ptr, 0, size)
                    revert(ptr, size)
                }
            }
        }
    }

    function executeTransaction(
        bytes calldata data,
        address destination,
        uint256 amount
    ) external payable {
        executeTransactionWithGasRefunder(IGasRefunder(address(0)), data, destination, amount);
    }

    function executeTransactionWithGasRefunder(
        IGasRefunder gasRefunder,
        bytes calldata data,
        address destination,
        uint256 amount
    ) public payable onlyExecutorOrOwner refundsGas(gasRefunder) {
        if (data.length > 0) require(destination.isContract(), "NO_CODE_AT_ADDR");
        validateExecuteTransaction(destination);
        // We use a low level call here to allow for contract and non-contract calls
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = destination.call{value: amount}(data);
        if (!success) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }

    function timeoutChallenges(IChallengeManager manager, uint64[] calldata challenges) external {
        timeoutChallengesWithGasRefunder(IGasRefunder(address(0)), manager, challenges);
    }

    function timeoutChallengesWithGasRefunder(
        IGasRefunder gasRefunder,
        IChallengeManager manager,
        uint64[] calldata challenges
    ) public onlyExecutorOrOwner refundsGas(gasRefunder) {
        uint256 challengesCount = challenges.length;
        for (uint256 i = 0; i < challengesCount; i++) {
            try manager.timeout(challenges[i]) {} catch (bytes memory error) {
                if (error.length == 0) {
                    // Assume out of gas
                    // We need to revert here so gas estimation works
                    require(false, "GAS");
                }
            }
        }
    }

    receive() external payable {}

    /// @dev allows the owner to withdraw eth held by this contract
    function withdrawEth(uint256 amount, address destination) external onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = destination.call{value: amount}("");
        if (!success) revert WithdrawEthFail(destination);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ValidatorWallet.sol";

contract ValidatorWalletCreator is Ownable {
    event WalletCreated(
        address indexed walletAddress,
        address indexed executorAddress,
        address indexed ownerAddress,
        address adminProxy
    );
    event TemplateUpdated();

    address public template;

    constructor() Ownable() {
        template = address(new ValidatorWallet());
    }

    function setTemplate(address _template) external onlyOwner {
        template = _template;
        emit TemplateUpdated();
    }

    function createWallet(address[] calldata initialExecutorAllowedDests)
        external
        returns (address)
    {
        address _executor = msg.sender;
        address _owner = msg.sender;
        ProxyAdmin admin = new ProxyAdmin();
        address proxy = address(
            new TransparentUpgradeableProxy(address(template), address(admin), "")
        );
        admin.transferOwnership(_owner);
        ValidatorWallet(payable(proxy)).initialize(_executor, _owner, initialExecutorAllowedDests);
        emit WalletCreated(proxy, _executor, _owner, address(admin));
        return proxy;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/UpgradeableBeacon.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../../access/Ownable.sol";
import "../../utils/Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Proxy.sol";

contract SimpleProxy is Proxy {
    address private immutable impl;

    constructor(address impl_) {
        impl = impl_;
    }

    function _implementation() internal view override returns (address) {
        return impl;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import {DoubleLogicERC1967Upgrade} from "./AdminFallbackProxy.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

/// @notice An extension to OZ's UUPSUpgradeable contract to be used for handling UUPS upgrades with a DoubleLogicERC1967Upgrade proxy
///         The should be used in the primary implementation slot of the DoubleLogicUUPS proxy
/// @dev upgrades should be handles by the primary logic contract in order to pass the `onlyProxy` check
abstract contract DoubleLogicUUPSUpgradeable is UUPSUpgradeable, DoubleLogicERC1967Upgrade {
    /// @inheritdoc UUPSUpgradeable
    function proxiableUUID() external view override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the secondary contract. Called by
     * {upgradeSecondaryTo} and {upgradeSecondaryToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeSecondaryUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeSecondaryUpgrade(address newImplementation) internal virtual;

    /**
     * @dev Upgrade the secondary implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeSecondaryUpgrade}.
     *
     * Emits an {UpgradedSecondary} event.
     */
    function upgradeSecondaryTo(address newImplementation) external onlyProxy {
        _authorizeSecondaryUpgrade(newImplementation);
        _upgradeSecondaryToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the secondary implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeSecondaryUpgrade}.
     *
     * Emits an {UpgradedSecondary} event.
     */
    function upgradeSecondaryToAndCall(address newImplementation, bytes memory data)
        external
        payable
        onlyProxy
    {
        _authorizeSecondaryUpgrade(newImplementation);
        _upgradeSecondaryToAndCallUUPS(newImplementation, data, true);
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import {IRollupAdmin, IRollupUser} from "./IRollupLogic.sol";
import "./RollupCore.sol";
import "../bridge/IOutbox.sol";
import "../bridge/ISequencerInbox.sol";
import "../challenge/IChallengeManager.sol";
import "../libraries/DoubleLogicUUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import {NO_CHAL_INDEX} from "../libraries/Constants.sol";

contract RollupAdminLogic is RollupCore, IRollupAdmin, DoubleLogicUUPSUpgradeable {
    function initialize(Config calldata config, ContractDependencies calldata connectedContracts)
        external
        override
        onlyProxy
        initializer
    {
        rollupDeploymentBlock = block.number;
        bridge = connectedContracts.bridge;
        sequencerInbox = connectedContracts.sequencerInbox;
        connectedContracts.bridge.setDelayedInbox(address(connectedContracts.inbox), true);
        connectedContracts.bridge.setSequencerInbox(address(connectedContracts.sequencerInbox));

        inbox = connectedContracts.inbox;
        outbox = connectedContracts.outbox;
        connectedContracts.bridge.setOutbox(address(connectedContracts.outbox), true);
        rollupEventInbox = connectedContracts.rollupEventInbox;
        connectedContracts.bridge.setDelayedInbox(
            address(connectedContracts.rollupEventInbox),
            true
        );

        connectedContracts.rollupEventInbox.rollupInitialized(config.chainId);
        connectedContracts.sequencerInbox.addSequencerL2Batch(
            0,
            "",
            1,
            IGasRefunder(address(0)),
            0,
            1
        );

        validatorUtils = connectedContracts.validatorUtils;
        validatorWalletCreator = connectedContracts.validatorWalletCreator;
        challengeManager = connectedContracts.challengeManager;

        Node memory node = createInitialNode();
        initializeCore(node);

        confirmPeriodBlocks = config.confirmPeriodBlocks;
        extraChallengeTimeBlocks = config.extraChallengeTimeBlocks;
        chainId = config.chainId;
        baseStake = config.baseStake;
        wasmModuleRoot = config.wasmModuleRoot;
        // A little over 15 minutes
        minimumAssertionPeriod = 75;

        // the owner can't access the rollup user facet where escrow is redeemable
        require(config.loserStakeEscrow != _getAdmin(), "INVALID_ESCROW_ADMIN");
        // this next check shouldn't be an issue if the owner controls an AdminProxy
        // that accesses the admin facet, but still seems like a good extra precaution
        require(config.loserStakeEscrow != config.owner, "INVALID_ESCROW_OWNER");
        loserStakeEscrow = config.loserStakeEscrow;

        stakeToken = config.stakeToken;

        emit RollupInitialized(config.wasmModuleRoot, config.chainId);
    }

    function createInitialNode() private view returns (Node memory) {
        GlobalState memory emptyGlobalState;
        bytes32 state = RollupLib.stateHashMem(
            RollupLib.ExecutionState(emptyGlobalState, MachineStatus.FINISHED),
            1 // inboxMaxCount - force the first assertion to read a message
        );
        return
            NodeLib.createNode(
                state,
                0, // challenge hash (not challengeable)
                0, // confirm data
                0, // prev node
                uint64(block.number), // deadline block (not challengeable)
                0 // initial node has a node hash of 0
            );
    }

    /**
     * Functions are only to reach this logic contract if the caller is the owner
     * so there is no need for a redundant onlyOwner check
     */

    /**
     * @notice Add a contract authorized to put messages into this rollup's inbox
     * @param _outbox Outbox contract to add
     */
    function setOutbox(IOutbox _outbox) external override {
        outbox = _outbox;
        bridge.setOutbox(address(_outbox), true);
        emit OwnerFunctionCalled(0);
    }

    /**
     * @notice Disable an old outbox from interacting with the bridge
     * @param _outbox Outbox contract to remove
     */
    function removeOldOutbox(address _outbox) external override {
        require(_outbox != address(outbox), "CUR_OUTBOX");
        bridge.setOutbox(_outbox, false);
        emit OwnerFunctionCalled(1);
    }

    /**
     * @notice Enable or disable an inbox contract
     * @param _inbox Inbox contract to add or remove
     * @param _enabled New status of inbox
     */
    function setDelayedInbox(address _inbox, bool _enabled) external override {
        bridge.setDelayedInbox(address(_inbox), _enabled);
        emit OwnerFunctionCalled(2);
    }

    /**
     * @notice Pause interaction with the rollup contract.
     * The time spent paused is not incremented in the rollup's timing for node validation.
     * @dev this function may be frontrun by a validator (ie to create a node before the system is paused).
     * The pause should be called atomically with required checks to be sure the system is paused in a consistent state.
     * The RollupAdmin may execute a check against the Rollup's latest node num or the ChallengeManager, then execute this function atomically with it.
     */
    function pause() external override {
        _pause();
        emit OwnerFunctionCalled(3);
    }

    /**
     * @notice Resume interaction with the rollup contract
     */
    function resume() external override {
        _unpause();
        emit OwnerFunctionCalled(4);
    }

    /// @notice allows the admin to upgrade the primary logic contract (ie rollup admin logic, aka this)
    /// @dev this function doesn't revert as this primary logic contract is only
    /// reachable by the proxy's admin
    function _authorizeUpgrade(address newImplementation) internal override {}

    /// @notice allows the admin to upgrade the secondary logic contract (ie rollup user logic)
    /// @dev this function doesn't revert as this primary logic contract is only
    /// reachable by the proxy's admin
    function _authorizeSecondaryUpgrade(address newImplementation) internal override {}

    /**
     * @notice Set the addresses of the validator whitelist
     * @dev It is expected that both arrays are same length, and validator at
     * position i corresponds to the value at position i
     * @param _validator addresses to set in the whitelist
     * @param _val value to set in the whitelist for corresponding address
     */
    function setValidator(address[] calldata _validator, bool[] calldata _val) external override {
        require(_validator.length > 0, "EMPTY_ARRAY");
        require(_validator.length == _val.length, "WRONG_LENGTH");

        for (uint256 i = 0; i < _validator.length; i++) {
            isValidator[_validator[i]] = _val[i];
        }
        emit OwnerFunctionCalled(6);
    }

    /**
     * @notice Set a new owner address for the rollup
     * @dev it is expected that only the rollup admin can use this facet to set a new owner
     * @param newOwner address of new rollup owner
     */
    function setOwner(address newOwner) external override {
        _changeAdmin(newOwner);
        emit OwnerFunctionCalled(7);
    }

    /**
     * @notice Set minimum assertion period for the rollup
     * @param newPeriod new minimum period for assertions
     */
    function setMinimumAssertionPeriod(uint256 newPeriod) external override {
        minimumAssertionPeriod = newPeriod;
        emit OwnerFunctionCalled(8);
    }

    /**
     * @notice Set number of blocks until a node is considered confirmed
     * @param newConfirmPeriod new number of blocks
     */
    function setConfirmPeriodBlocks(uint64 newConfirmPeriod) external override {
        require(newConfirmPeriod > 0, "INVALID_CONFIRM_PERIOD");
        confirmPeriodBlocks = newConfirmPeriod;
        emit OwnerFunctionCalled(9);
    }

    /**
     * @notice Set number of extra blocks after a challenge
     * @param newExtraTimeBlocks new number of blocks
     */
    function setExtraChallengeTimeBlocks(uint64 newExtraTimeBlocks) external override {
        extraChallengeTimeBlocks = newExtraTimeBlocks;
        emit OwnerFunctionCalled(10);
    }

    /**
     * @notice Set base stake required for an assertion
     * @param newBaseStake minimum amount of stake required
     */
    function setBaseStake(uint256 newBaseStake) external override {
        baseStake = newBaseStake;
        emit OwnerFunctionCalled(12);
    }

    /**
     * @notice Set the token used for stake, where address(0) == eth
     * @dev Before changing the base stake token, you might need to change the
     * implementation of the Rollup User facet!
     * @param newStakeToken address of token used for staking
     */
    function setStakeToken(address newStakeToken) external override whenPaused {
        /*
         * To change the stake token without breaking consistency one would need to:
         * Pause the system, have all stakers remove their funds,
         * update the user logic to handle ERC20s, change the stake token, then resume.
         *
         * Note: To avoid loss of funds stakers must remove their funds and claim all the
         * available withdrawable funds before the system is paused.
         */
        bool expectERC20Support = newStakeToken != address(0);
        // this assumes the rollup isn't its own admin. if needed, instead use a ProxyAdmin by OZ!
        bool actualERC20Support = IRollupUser(address(this)).isERC20Enabled();
        require(actualERC20Support == expectERC20Support, "NO_USER_LOGIC_SUPPORT");
        require(stakerCount() == 0, "NO_ACTIVE_STAKERS");
        require(totalWithdrawableFunds == 0, "NO_PENDING_WITHDRAW");
        stakeToken = newStakeToken;
        emit OwnerFunctionCalled(13);
    }

    /**
     * @notice Upgrades the implementation of a beacon controlled by the rollup
     * @param beacon address of beacon to be upgraded
     * @param newImplementation new address of implementation
     */
    function upgradeBeacon(address beacon, address newImplementation) external override {
        UpgradeableBeacon(beacon).upgradeTo(newImplementation);
        emit OwnerFunctionCalled(20);
    }

    function forceResolveChallenge(address[] calldata stakerA, address[] calldata stakerB)
        external
        override
        whenPaused
    {
        require(stakerA.length > 0, "EMPTY_ARRAY");
        require(stakerA.length == stakerB.length, "WRONG_LENGTH");
        for (uint256 i = 0; i < stakerA.length; i++) {
            uint64 chall = inChallenge(stakerA[i], stakerB[i]);

            require(chall != NO_CHAL_INDEX, "NOT_IN_CHALL");
            clearChallenge(stakerA[i]);
            clearChallenge(stakerB[i]);
            challengeManager.clearChallenge(chall);
        }
        emit OwnerFunctionCalled(21);
    }

    function forceRefundStaker(address[] calldata staker) external override whenPaused {
        require(staker.length > 0, "EMPTY_ARRAY");
        for (uint256 i = 0; i < staker.length; i++) {
            require(_stakerMap[staker[i]].currentChallenge == NO_CHAL_INDEX, "STAKER_IN_CHALL");
            reduceStakeTo(staker[i], 0);
            turnIntoZombie(staker[i]);
        }
        emit OwnerFunctionCalled(22);
    }

    function forceCreateNode(
        uint64 prevNode,
        uint256 prevNodeInboxMaxCount,
        RollupLib.Assertion calldata assertion,
        bytes32 expectedNodeHash
    ) external override whenPaused {
        require(prevNode == latestConfirmed(), "ONLY_LATEST_CONFIRMED");

        createNewNode(assertion, prevNode, prevNodeInboxMaxCount, expectedNodeHash);

        emit OwnerFunctionCalled(23);
    }

    function forceConfirmNode(
        uint64 nodeNum,
        bytes32 blockHash,
        bytes32 sendRoot
    ) external override whenPaused {
        // this skips deadline, staker and zombie validation
        confirmNode(nodeNum, blockHash, sendRoot);
        emit OwnerFunctionCalled(24);
    }

    function setLoserStakeEscrow(address newLoserStakerEscrow) external override {
        // escrow holder can't be proxy admin, since escrow is only redeemable through
        // the primary user logic contract
        require(newLoserStakerEscrow != _getAdmin(), "INVALID_ESCROW");
        loserStakeEscrow = newLoserStakerEscrow;
        emit OwnerFunctionCalled(25);
    }

    /**
     * @notice Set the proving WASM module root
     * @param newWasmModuleRoot new module root
     */
    function setWasmModuleRoot(bytes32 newWasmModuleRoot) external override {
        wasmModuleRoot = newWasmModuleRoot;
        emit OwnerFunctionCalled(26);
    }

    /**
     * @notice set a new sequencer inbox contract
     * @param _sequencerInbox new address of sequencer inbox
     */
    function setSequencerInbox(address _sequencerInbox) external override {
        bridge.setSequencerInbox(_sequencerInbox);
        emit OwnerFunctionCalled(27);
    }

    /**
     * @notice sets the rollup's inbox reference. Does not update the bridge's view.
     * @param newInbox new address of inbox
     */
    function setInbox(IInbox newInbox) external {
        inbox = newInbox;
        emit OwnerFunctionCalled(28);
    }

    function createNitroMigrationGenesis(RollupLib.Assertion calldata assertion)
        external
        whenPaused
    {
        bytes32 expectedSendRoot = bytes32(0);
        uint64 expectedInboxCount = 1;

        require(latestNodeCreated() == 0, "NON_GENESIS_NODES_EXIST");
        require(GlobalStateLib.isEmpty(assertion.beforeState.globalState), "NOT_EMPTY_BEFORE");
        require(
            assertion.beforeState.machineStatus == MachineStatus.FINISHED,
            "BEFORE_MACHINE_NOT_FINISHED"
        );
        // accessors such as state.getSendRoot not available for calldata structs, only memory
        require(
            assertion.afterState.globalState.bytes32Vals[1] == expectedSendRoot,
            "NOT_ZERO_SENDROOT"
        );
        require(
            assertion.afterState.globalState.u64Vals[0] == expectedInboxCount,
            "INBOX_NOT_AT_ONE"
        );
        require(assertion.afterState.globalState.u64Vals[1] == 0, "POSITION_IN_MESSAGE_NOT_ZERO");
        require(
            assertion.afterState.machineStatus == MachineStatus.FINISHED,
            "AFTER_MACHINE_NOT_FINISHED"
        );
        bytes32 genesisBlockHash = assertion.afterState.globalState.bytes32Vals[0];
        createNewNode(assertion, 0, expectedInboxCount, bytes32(0));
        confirmNode(1, genesisBlockHash, expectedSendRoot);
        emit OwnerFunctionCalled(29);
    }

    /**
     * @notice set the validatorWhitelistDisabled flag
     * @param _validatorWhitelistDisabled new value of validatorWhitelistDisabled, i.e. true = disabled
     */
    function setValidatorWhitelistDisabled(bool _validatorWhitelistDisabled) external {
        validatorWhitelistDisabled = _validatorWhitelistDisabled;
        emit OwnerFunctionCalled(30);
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "../bridge/IBridge.sol";
import "../bridge/IOutbox.sol";
import "../bridge/IInbox.sol";
import "../bridge/ISequencerInbox.sol";

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../bridge/IInbox.sol";
import "../bridge/IBridge.sol";

import "../bridge/Messages.sol";
import "./BridgeStub.sol";
import {
    L2_MSG,
    L1MessageType_L2FundedByL1,
    L1MessageType_submitRetryableTx,
    L2MessageType_unsignedEOATx,
    L2MessageType_unsignedContractTx
} from "../libraries/MessageTypes.sol";

contract InboxStub is IInbox {
    IBridge public override bridge;
    ISequencerInbox public override sequencerInbox;

    bool public paused;

    function pause() external pure {
        revert("NOT IMPLEMENTED");
    }

    function unpause() external pure {
        revert("NOT IMPLEMENTED");
    }

    function initialize(IBridge _bridge, ISequencerInbox) external {
        require(address(bridge) == address(0), "ALREADY_INIT");
        bridge = _bridge;
    }

    /**
     * @notice Send a generic L2 message to the chain
     * @dev This method is an optimization to avoid having to emit the entirety of the messageData in a log. Instead validators are expected to be able to parse the data from the transaction's input
     * @param messageData Data of the message being sent
     */
    function sendL2MessageFromOrigin(bytes calldata messageData) external returns (uint256) {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender == tx.origin, "origin only");
        uint256 msgNum = deliverToBridge(L2_MSG, msg.sender, keccak256(messageData));
        emit InboxMessageDeliveredFromOrigin(msgNum);
        return msgNum;
    }

    /**
     * @notice Send a generic L2 message to the chain
     * @dev This method can be used to send any type of message that doesn't require L1 validation
     * @param messageData Data of the message being sent
     */
    function sendL2Message(bytes calldata messageData) external override returns (uint256) {
        uint256 msgNum = deliverToBridge(L2_MSG, msg.sender, keccak256(messageData));
        emit InboxMessageDelivered(msgNum, messageData);
        return msgNum;
    }

    function deliverToBridge(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) internal returns (uint256) {
        return bridge.enqueueDelayedMessage{value: msg.value}(kind, sender, messageDataHash);
    }

    function sendUnsignedTransaction(
        uint256,
        uint256,
        uint256,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (uint256) {
        revert("NOT_IMPLEMENTED");
    }

    function sendContractTransaction(
        uint256,
        uint256,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (uint256) {
        revert("NOT_IMPLEMENTED");
    }

    function sendL1FundedUnsignedTransaction(
        uint256,
        uint256,
        uint256,
        address,
        bytes calldata
    ) external payable override returns (uint256) {
        revert("NOT_IMPLEMENTED");
    }

    function sendL1FundedContractTransaction(
        uint256,
        uint256,
        address,
        bytes calldata
    ) external payable override returns (uint256) {
        revert("NOT_IMPLEMENTED");
    }

    function createRetryableTicket(
        address,
        uint256,
        uint256,
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external payable override returns (uint256) {
        revert("NOT_IMPLEMENTED");
    }

    function unsafeCreateRetryableTicket(
        address,
        uint256,
        uint256,
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external payable override returns (uint256) {
        revert("NOT_IMPLEMENTED");
    }

    function sendL1FundedUnsignedTransactionToFork(
        uint256,
        uint256,
        uint256,
        address,
        bytes calldata
    ) external payable returns (uint256) {
        revert("NOT_IMPLEMENTED");
    }

    function sendUnsignedTransactionToFork(
        uint256,
        uint256,
        uint256,
        address,
        uint256,
        bytes calldata
    ) external returns (uint256) {
        revert("NOT_IMPLEMENTED");
    }

    function sendWithdrawEthToFork(
        uint256,
        uint256,
        uint256,
        uint256,
        address
    ) external returns (uint256) {
        revert("NOT_IMPLEMENTED");
    }

    function depositEth() external payable override returns (uint256) {
        revert("NOT_IMPLEMENTED");
    }

    function postUpgradeInit(IBridge _bridge) external {}

    function calculateRetryableSubmissionFee(uint256, uint256)
        external
        pure
        override
        returns (uint256)
    {
        revert("NOT_IMPLEMENTED");
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./InboxStub.sol";
import {BadSequencerMessageNumber} from "../libraries/Error.sol";

import "../bridge/IBridge.sol";

contract BridgeStub is IBridge {
    struct InOutInfo {
        uint256 index;
        bool allowed;
    }

    mapping(address => InOutInfo) private allowedDelayedInboxesMap;
    //mapping(address => InOutInfo) private allowedOutboxesMap;

    address[] public allowedDelayedInboxList;
    address[] public allowedOutboxList;

    address public override activeOutbox;

    // Accumulator for delayed inbox; tail represents hash of the current state; each element represents the inclusion of a new message.
    bytes32[] public override delayedInboxAccs;

    bytes32[] public override sequencerInboxAccs;

    address public sequencerInbox;
    uint256 public override sequencerReportedSubMessageCount;

    function setSequencerInbox(address _sequencerInbox) external override {
        sequencerInbox = _sequencerInbox;
        emit SequencerInboxUpdated(_sequencerInbox);
    }

    function allowedDelayedInboxes(address inbox) external view override returns (bool) {
        return allowedDelayedInboxesMap[inbox].allowed;
    }

    function allowedOutboxes(address) external pure override returns (bool) {
        revert("NOT_IMPLEMENTED");
    }

    function enqueueDelayedMessage(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) external payable override returns (uint256) {
        require(allowedDelayedInboxesMap[msg.sender].allowed, "NOT_FROM_INBOX");
        return
            addMessageToDelayedAccumulator(
                kind,
                sender,
                block.number,
                block.timestamp, // solhint-disable-line not-rely-on-time
                block.basefee,
                messageDataHash
            );
    }

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
        )
    {
        if (
            sequencerReportedSubMessageCount != prevMessageCount &&
            prevMessageCount != 0 &&
            sequencerReportedSubMessageCount != 0
        ) {
            revert BadSequencerMessageNumber(sequencerReportedSubMessageCount, prevMessageCount);
        }
        sequencerReportedSubMessageCount = newMessageCount;
        seqMessageIndex = sequencerInboxAccs.length;
        if (sequencerInboxAccs.length > 0) {
            beforeAcc = sequencerInboxAccs[sequencerInboxAccs.length - 1];
        }
        if (afterDelayedMessagesRead > 0) {
            delayedAcc = delayedInboxAccs[afterDelayedMessagesRead - 1];
        }
        acc = keccak256(abi.encodePacked(beforeAcc, dataHash, delayedAcc));
        sequencerInboxAccs.push(acc);
    }

    function submitBatchSpendingReport(address batchPoster, bytes32 dataHash)
        external
        returns (uint256)
    {
        // TODO: implement stub
    }

    function addMessageToDelayedAccumulator(
        uint8,
        address,
        uint256,
        uint256,
        uint256,
        bytes32 messageDataHash
    ) internal returns (uint256) {
        uint256 count = delayedInboxAccs.length;
        bytes32 messageHash = Messages.messageHash(
            0,
            address(uint160(0)),
            0,
            0,
            0,
            0,
            messageDataHash
        );
        bytes32 prevAcc = 0;
        if (count > 0) {
            prevAcc = delayedInboxAccs[count - 1];
        }
        delayedInboxAccs.push(Messages.accumulateInboxMessage(prevAcc, messageHash));
        return count;
    }

    function executeCall(
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bool, bytes memory) {
        revert("NOT_IMPLEMENTED");
    }

    function setDelayedInbox(address inbox, bool enabled) external override {
        InOutInfo storage info = allowedDelayedInboxesMap[inbox];
        bool alreadyEnabled = info.allowed;
        emit InboxToggle(inbox, enabled);
        if ((alreadyEnabled && enabled) || (!alreadyEnabled && !enabled)) {
            return;
        }
        if (enabled) {
            allowedDelayedInboxesMap[inbox] = InOutInfo(allowedDelayedInboxList.length, true);
            allowedDelayedInboxList.push(inbox);
        } else {
            allowedDelayedInboxList[info.index] = allowedDelayedInboxList[
                allowedDelayedInboxList.length - 1
            ];
            allowedDelayedInboxesMap[allowedDelayedInboxList[info.index]].index = info.index;
            allowedDelayedInboxList.pop();
            delete allowedDelayedInboxesMap[inbox];
        }
    }

    function setOutbox(
        address, /* outbox */
        bool /* enabled*/
    ) external pure override {
        revert("NOT_IMPLEMENTED");
    }

    function delayedMessageCount() external view override returns (uint256) {
        return delayedInboxAccs.length;
    }

    function sequencerMessageCount() external view override returns (uint256) {
        return sequencerInboxAccs.length;
    }

    function rollup() external pure override returns (IOwnable) {
        revert("NOT_IMPLEMENTED");
    }

    function acceptFundsFromOldBridge() external payable {}

    function initialize(IOwnable) external pure {
        revert("NOT_IMPLEMENTED");
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import {
    AlreadyInit,
    NotRollup,
    ProofTooLong,
    PathNotMinimal,
    UnknownRoot,
    AlreadySpent,
    BridgeCallFailed
} from "../libraries/Error.sol";
import "../bridge/IBridge.sol";
import "../bridge/IOutbox.sol";
import "../libraries/MerkleLib.sol";
import "../libraries/DelegateCallAware.sol";

contract OutboxWithoutOptTester is DelegateCallAware, IOutbox {
    address public rollup; // the rollup contract
    IBridge public bridge; // the bridge contract

    function spent(uint256) external pure override returns (bytes32) {
        revert("NOT_IMPLEMETED");
    }

    mapping(uint256 => bool) public isSpent; // maps leaf number => if spent
    mapping(bytes32 => bytes32) public roots; // maps root hashes => L2 block hash

    struct L2ToL1Context {
        uint128 l2Block;
        uint128 l1Block;
        uint128 timestamp;
        bytes32 outputId;
        address sender;
    }
    // Note, these variables are set and then wiped during a single transaction.
    // Therefore their values don't need to be maintained, and their slots will
    // be empty outside of transactions
    L2ToL1Context internal context;
    uint128 public constant OUTBOX_VERSION = 2;

    function initialize(IBridge _bridge) external {
        if (address(bridge) != address(0)) revert AlreadyInit();
        bridge = _bridge;
        rollup = address(_bridge.rollup());
    }

    function updateSendRoot(bytes32 root, bytes32 l2BlockHash) external override {
        //if (msg.sender != rollup) revert NotRollup(msg.sender, rollup);  //test only!!!
        roots[root] = l2BlockHash;
        emit SendRootUpdated(root, l2BlockHash);
    }

    /// @notice When l2ToL1Sender returns a nonzero address, the message was originated by an L2 account
    /// When the return value is zero, that means this is a system message
    /// @dev the l2ToL1Sender behaves as the tx.origin, the msg.sender should be validated to protect against reentrancies
    function l2ToL1Sender() external view override returns (address) {
        return context.sender;
    }

    function l2ToL1Block() external view override returns (uint256) {
        return uint256(context.l2Block);
    }

    function l2ToL1EthBlock() external view override returns (uint256) {
        return uint256(context.l1Block);
    }

    function l2ToL1Timestamp() external view override returns (uint256) {
        return uint256(context.timestamp);
    }

    // @deprecated batch number is now always 0
    function l2ToL1BatchNum() external pure returns (uint256) {
        return 0;
    }

    function l2ToL1OutputId() external view override returns (bytes32) {
        return context.outputId;
    }

    /**
     * @notice Executes a messages in an Outbox entry.
     * @dev Reverts if dispute period hasn't expired, since the outbox entry
     * is only created once the rollup confirms the respective assertion.
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
    ) external virtual override {
        bytes32 outputId;
        {
            bytes32 userTx = calculateItemHash(
                l2Sender,
                to,
                l2Block,
                l1Block,
                l2Timestamp,
                value,
                data
            );

            outputId = recordOutputAsSpent(proof, index, userTx);
            emit OutBoxTransactionExecuted(to, l2Sender, 0, index);
        }

        // we temporarily store the previous values so the outbox can naturally
        // unwind itself when there are nested calls to `executeTransaction`
        L2ToL1Context memory prevContext = context;

        context = L2ToL1Context({
            sender: l2Sender,
            l2Block: uint128(l2Block),
            l1Block: uint128(l1Block),
            timestamp: uint128(l2Timestamp),
            outputId: outputId
        });

        // set and reset vars around execution so they remain valid during call
        executeBridgeCall(to, value, data);

        context = prevContext;
    }

    function executeTransactionSimulation(
        uint256,
        address,
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        bytes calldata
    ) external pure override {
        revert("Not implemented");
    }

    function recordOutputAsSpent(
        bytes32[] memory proof,
        uint256 index,
        bytes32 item
    ) internal returns (bytes32) {
        if (proof.length >= 256) revert ProofTooLong(proof.length);
        if (index >= 2**proof.length) revert PathNotMinimal(index, 2**proof.length);

        // Hash the leaf an extra time to prove it's a leaf
        bytes32 calcRoot = calculateMerkleRoot(proof, index, item);
        if (roots[calcRoot] == bytes32(0)) revert UnknownRoot(calcRoot);

        if (isSpent[index]) revert AlreadySpent(index);
        isSpent[index] = true;

        return bytes32(index);
    }

    function executeBridgeCall(
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        (bool success, bytes memory returndata) = bridge.executeCall(to, value, data);
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert BridgeCallFailed();
            }
        }
    }

    function calculateItemHash(
        address l2Sender,
        address to,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 value,
        bytes calldata data
    ) public pure override returns (bytes32) {
        return
            keccak256(abi.encodePacked(l2Sender, to, l2Block, l1Block, l2Timestamp, value, data));
    }

    function calculateMerkleRoot(
        bytes32[] memory proof,
        uint256 path,
        bytes32 item
    ) public pure override returns (bytes32) {
        return MerkleLib.calculateRoot(proof, path, keccak256(abi.encodePacked(item)));
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import {
    NotContract,
    NotRollupOrOwner,
    NotDelayedInbox,
    NotSequencerInbox,
    NotOutbox,
    InvalidOutboxSet
} from "../libraries/Error.sol";
import "../bridge/IBridge.sol";
import "../bridge/Messages.sol";
import "../libraries/DelegateCallAware.sol";

/**
 * @title Staging ground for incoming and outgoing messages
 * @notice Holds the inbox accumulator for delayed messages, and is the ETH escrow
 * for value sent with these messages.
 * Since the escrow is held here, this contract also contains a list of allowed
 * outboxes that can make calls from here and withdraw this escrow.
 */
contract BridgeTester is Initializable, DelegateCallAware, IBridge {
    using AddressUpgradeable for address;

    struct InOutInfo {
        uint256 index;
        bool allowed;
    }

    mapping(address => InOutInfo) private allowedInboxesMap;
    mapping(address => InOutInfo) private allowedOutboxesMap;

    address[] public allowedDelayedInboxList;
    address[] public allowedOutboxList;

    address private _activeOutbox;

    IOwnable public rollup;
    address public sequencerInbox;

    modifier onlyRollupOrOwner() {
        if (msg.sender != address(rollup)) {
            address rollupOwner = rollup.owner();
            if (msg.sender != rollupOwner) {
                revert NotRollupOrOwner(msg.sender, address(rollup), rollupOwner);
            }
        }
        _;
    }

    function setSequencerInbox(address _sequencerInbox) external override onlyRollupOrOwner {
        sequencerInbox = _sequencerInbox;
        emit SequencerInboxUpdated(_sequencerInbox);
    }

    /// @dev Accumulator for delayed inbox messages; tail represents hash of the current state; each element represents the inclusion of a new message.
    bytes32[] public override delayedInboxAccs;

    bytes32[] public override sequencerInboxAccs;
    uint256 public override sequencerReportedSubMessageCount;

    address private constant EMPTY_ACTIVEOUTBOX = address(type(uint160).max);

    function initialize(IOwnable rollup_) external initializer {
        _activeOutbox = EMPTY_ACTIVEOUTBOX;
        rollup = rollup_;
    }

    function activeOutbox() public view returns (address) {
        if (_activeOutbox == EMPTY_ACTIVEOUTBOX) return address(uint160(0));
        return _activeOutbox;
    }

    function allowedDelayedInboxes(address inbox) external view override returns (bool) {
        return allowedInboxesMap[inbox].allowed;
    }

    function allowedOutboxes(address outbox) external view override returns (bool) {
        return allowedOutboxesMap[outbox].allowed;
    }

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
        )
    {
        // TODO: implement stub logic
    }

    function submitBatchSpendingReport(address batchPoster, bytes32 dataHash)
        external
        returns (uint256)
    {
        // TODO: implement stub
    }

    /**
     * @dev Enqueue a message in the delayed inbox accumulator.
     * These messages are later sequenced in the SequencerInbox, either by the sequencer as
     * part of a normal batch, or by force inclusion.
     */
    function enqueueDelayedMessage(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) external payable override returns (uint256) {
        if (!allowedInboxesMap[msg.sender].allowed) revert NotDelayedInbox(msg.sender);
        return
            addMessageToDelayedAccumulator(
                kind,
                sender,
                uint64(block.number),
                uint64(block.timestamp), // solhint-disable-line not-rely-on-time
                block.basefee,
                messageDataHash
            );
    }

    function addMessageToDelayedAccumulator(
        uint8 kind,
        address sender,
        uint64 blockNumber,
        uint64 blockTimestamp,
        uint256 baseFeeL1,
        bytes32 messageDataHash
    ) internal returns (uint256) {
        uint256 count = delayedInboxAccs.length;
        bytes32 messageHash = Messages.messageHash(
            kind,
            sender,
            blockNumber,
            blockTimestamp,
            count,
            baseFeeL1,
            messageDataHash
        );
        bytes32 prevAcc = 0;
        if (count > 0) {
            prevAcc = delayedInboxAccs[count - 1];
        }
        delayedInboxAccs.push(Messages.accumulateInboxMessage(prevAcc, messageHash));
        emit MessageDelivered(
            count,
            prevAcc,
            msg.sender,
            kind,
            sender,
            messageDataHash,
            baseFeeL1,
            blockTimestamp
        );
        return count;
    }

    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external override returns (bool success, bytes memory returnData) {
        if (!allowedOutboxesMap[msg.sender].allowed) revert NotOutbox(msg.sender);
        if (data.length > 0 && !to.isContract()) revert NotContract(to);
        address prevOutbox = _activeOutbox;
        _activeOutbox = msg.sender;
        // We set and reset active outbox around external call so activeOutbox remains valid during call

        // We use a low level call here since we want to bubble up whether it succeeded or failed to the caller
        // rather than reverting on failure as well as allow contract and non-contract calls
        // solhint-disable-next-line avoid-low-level-calls
        (success, returnData) = to.call{value: value}(data);
        _activeOutbox = prevOutbox;
        emit BridgeCallTriggered(msg.sender, to, value, data);
    }

    function setDelayedInbox(address inbox, bool enabled) external override onlyRollupOrOwner {
        InOutInfo storage info = allowedInboxesMap[inbox];
        bool alreadyEnabled = info.allowed;
        emit InboxToggle(inbox, enabled);
        if ((alreadyEnabled && enabled) || (!alreadyEnabled && !enabled)) {
            return;
        }
        if (enabled) {
            allowedInboxesMap[inbox] = InOutInfo(allowedDelayedInboxList.length, true);
            allowedDelayedInboxList.push(inbox);
        } else {
            allowedDelayedInboxList[info.index] = allowedDelayedInboxList[
                allowedDelayedInboxList.length - 1
            ];
            allowedInboxesMap[allowedDelayedInboxList[info.index]].index = info.index;
            allowedDelayedInboxList.pop();
            delete allowedInboxesMap[inbox];
        }
    }

    function setOutbox(address outbox, bool enabled) external override onlyRollupOrOwner {
        InOutInfo storage info = allowedOutboxesMap[outbox];
        bool alreadyEnabled = info.allowed;
        emit OutboxToggle(outbox, enabled);
        if ((alreadyEnabled && enabled) || (!alreadyEnabled && !enabled)) {
            return;
        }
        if (enabled) {
            allowedOutboxesMap[outbox] = InOutInfo(allowedOutboxList.length, true);
            allowedOutboxList.push(outbox);
        } else {
            allowedOutboxList[info.index] = allowedOutboxList[allowedOutboxList.length - 1];
            allowedOutboxesMap[allowedOutboxList[info.index]].index = info.index;
            allowedOutboxList.pop();
            delete allowedOutboxesMap[outbox];
        }
    }

    function delayedMessageCount() external view override returns (uint256) {
        return delayedInboxAccs.length;
    }

    function sequencerMessageCount() external view override returns (uint256) {
        return sequencerInboxAccs.length;
    }

    receive() external payable {}

    function acceptFundsFromOldBridge() external payable {}
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../bridge/Messages.sol";

contract MessageTester {
    function messageHash(
        uint8 messageType,
        address sender,
        uint64 blockNumber,
        uint64 timestamp,
        uint256 inboxSeqNum,
        uint256 gasPriceL1,
        bytes32 messageDataHash
    ) public pure returns (bytes32) {
        return
            Messages.messageHash(
                messageType,
                sender,
                blockNumber,
                timestamp,
                inboxSeqNum,
                gasPriceL1,
                messageDataHash
            );
    }

    function accumulateInboxMessage(bytes32 inbox, bytes32 message) public pure returns (bytes32) {
        return Messages.accumulateInboxMessage(inbox, message);
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../state/Value.sol";
import "../state/Machine.sol";
import "../state/Deserialize.sol";
import "./IOneStepProver.sol";
import "../bridge/Messages.sol";
import "../bridge/IBridge.sol";

contract OneStepProverHostIo is IOneStepProver {
    using GlobalStateLib for GlobalState;
    using MerkleProofLib for MerkleProof;
    using ModuleMemoryLib for ModuleMemory;
    using ValueLib for Value;
    using ValueStackLib for ValueStack;

    uint256 private constant LEAF_SIZE = 32;
    uint256 private constant INBOX_NUM = 2;
    uint64 private constant INBOX_HEADER_LEN = 40;
    uint64 private constant DELAYED_HEADER_LEN = 112 + 1;

    function setLeafByte(
        bytes32 oldLeaf,
        uint256 idx,
        uint8 val
    ) internal pure returns (bytes32) {
        require(idx < LEAF_SIZE, "BAD_SET_LEAF_BYTE_IDX");
        // Take into account that we are casting the leaf to a big-endian integer
        uint256 leafShift = (LEAF_SIZE - 1 - idx) * 8;
        uint256 newLeaf = uint256(oldLeaf);
        newLeaf &= ~(0xFF << leafShift);
        newLeaf |= uint256(val) << leafShift;
        return bytes32(newLeaf);
    }

    function executeGetOrSetBytes32(
        Machine memory mach,
        Module memory mod,
        GlobalState memory state,
        Instruction calldata inst,
        bytes calldata proof
    ) internal pure {
        uint256 ptr = mach.valueStack.pop().assumeI32();
        uint32 idx = mach.valueStack.pop().assumeI32();

        if (idx >= GlobalStateLib.BYTES32_VALS_NUM) {
            mach.status = MachineStatus.ERRORED;
            return;
        }
        if (ptr + 32 > mod.moduleMemory.size || ptr % LEAF_SIZE != 0) {
            mach.status = MachineStatus.ERRORED;
            return;
        }

        uint256 leafIdx = ptr / LEAF_SIZE;
        uint256 proofOffset = 0;
        bytes32 startLeafContents;
        MerkleProof memory merkleProof;
        (startLeafContents, proofOffset, merkleProof) = mod.moduleMemory.proveLeaf(
            leafIdx,
            proof,
            proofOffset
        );

        if (inst.opcode == Instructions.GET_GLOBAL_STATE_BYTES32) {
            mod.moduleMemory.merkleRoot = merkleProof.computeRootFromMemory(
                leafIdx,
                state.bytes32Vals[idx]
            );
        } else if (inst.opcode == Instructions.SET_GLOBAL_STATE_BYTES32) {
            state.bytes32Vals[idx] = startLeafContents;
        } else {
            revert("BAD_GLOBAL_STATE_OPCODE");
        }
    }

    function executeGetU64(Machine memory mach, GlobalState memory state) internal pure {
        uint32 idx = mach.valueStack.pop().assumeI32();

        if (idx >= GlobalStateLib.U64_VALS_NUM) {
            mach.status = MachineStatus.ERRORED;
            return;
        }

        mach.valueStack.push(ValueLib.newI64(state.u64Vals[idx]));
    }

    function executeSetU64(Machine memory mach, GlobalState memory state) internal pure {
        uint64 val = mach.valueStack.pop().assumeI64();
        uint32 idx = mach.valueStack.pop().assumeI32();

        if (idx >= GlobalStateLib.U64_VALS_NUM) {
            mach.status = MachineStatus.ERRORED;
            return;
        }
        state.u64Vals[idx] = val;
    }

    function executeReadPreImage(
        ExecutionContext calldata,
        Machine memory mach,
        Module memory mod,
        Instruction calldata,
        bytes calldata proof
    ) internal pure {
        uint256 preimageOffset = mach.valueStack.pop().assumeI32();
        uint256 ptr = mach.valueStack.pop().assumeI32();
        if (ptr + 32 > mod.moduleMemory.size || ptr % LEAF_SIZE != 0) {
            mach.status = MachineStatus.ERRORED;
            return;
        }

        uint256 leafIdx = ptr / LEAF_SIZE;
        uint256 proofOffset = 0;
        bytes32 leafContents;
        MerkleProof memory merkleProof;
        (leafContents, proofOffset, merkleProof) = mod.moduleMemory.proveLeaf(
            leafIdx,
            proof,
            proofOffset
        );

        bytes memory extracted;
        uint8 proofType = uint8(proof[proofOffset]);
        proofOffset++;
        if (proofType == 0) {
            bytes calldata preimage = proof[proofOffset:];
            require(keccak256(preimage) == leafContents, "BAD_PREIMAGE");

            uint256 preimageEnd = preimageOffset + 32;
            if (preimageEnd > preimage.length) {
                preimageEnd = preimage.length;
            }
            extracted = preimage[preimageOffset:preimageEnd];
        } else {
            // TODO: support proving via an authenticated contract
            revert("UNKNOWN_PREIMAGE_PROOF");
        }

        for (uint256 i = 0; i < extracted.length; i++) {
            leafContents = setLeafByte(leafContents, i, uint8(extracted[i]));
        }

        mod.moduleMemory.merkleRoot = merkleProof.computeRootFromMemory(leafIdx, leafContents);

        mach.valueStack.push(ValueLib.newI32(uint32(extracted.length)));
    }

    function validateSequencerInbox(
        ExecutionContext calldata execCtx,
        uint64 msgIndex,
        bytes calldata message
    ) internal view returns (bool) {
        require(message.length >= INBOX_HEADER_LEN, "BAD_SEQINBOX_PROOF");

        uint64 afterDelayedMsg;
        (afterDelayedMsg, ) = Deserialize.u64(message, 32);
        bytes32 messageHash = keccak256(message);
        bytes32 beforeAcc;
        bytes32 delayedAcc;

        if (msgIndex > 0) {
            beforeAcc = execCtx.bridge.sequencerInboxAccs(msgIndex - 1);
        }
        if (afterDelayedMsg > 0) {
            delayedAcc = execCtx.bridge.delayedInboxAccs(afterDelayedMsg - 1);
        }
        bytes32 acc = keccak256(abi.encodePacked(beforeAcc, messageHash, delayedAcc));
        require(acc == execCtx.bridge.sequencerInboxAccs(msgIndex), "BAD_SEQINBOX_MESSAGE");
        return true;
    }

    function validateDelayedInbox(
        ExecutionContext calldata execCtx,
        uint64 msgIndex,
        bytes calldata message
    ) internal view returns (bool) {
        require(message.length >= DELAYED_HEADER_LEN, "BAD_DELAYED_PROOF");

        bytes32 beforeAcc;

        if (msgIndex > 0) {
            beforeAcc = execCtx.bridge.delayedInboxAccs(msgIndex - 1);
        }

        bytes32 messageDataHash = keccak256(message[DELAYED_HEADER_LEN:]);
        bytes1 kind = message[0];
        uint256 sender;
        (sender, ) = Deserialize.u256(message, 1);

        bytes32 messageHash = keccak256(
            abi.encodePacked(kind, uint160(sender), message[33:DELAYED_HEADER_LEN], messageDataHash)
        );
        bytes32 acc = Messages.accumulateInboxMessage(beforeAcc, messageHash);

        require(acc == execCtx.bridge.delayedInboxAccs(msgIndex), "BAD_DELAYED_MESSAGE");
        return true;
    }

    function executeReadInboxMessage(
        ExecutionContext calldata execCtx,
        Machine memory mach,
        Module memory mod,
        Instruction calldata inst,
        bytes calldata proof
    ) internal view {
        uint256 messageOffset = mach.valueStack.pop().assumeI32();
        uint256 ptr = mach.valueStack.pop().assumeI32();
        uint256 msgIndex = mach.valueStack.pop().assumeI64();
        if (
            inst.argumentData == Instructions.INBOX_INDEX_SEQUENCER &&
            msgIndex >= execCtx.maxInboxMessagesRead
        ) {
            mach.status = MachineStatus.TOO_FAR;
            return;
        }

        if (ptr + 32 > mod.moduleMemory.size || ptr % LEAF_SIZE != 0) {
            mach.status = MachineStatus.ERRORED;
            return;
        }

        uint256 leafIdx = ptr / LEAF_SIZE;
        uint256 proofOffset = 0;
        bytes32 leafContents;
        MerkleProof memory merkleProof;
        (leafContents, proofOffset, merkleProof) = mod.moduleMemory.proveLeaf(
            leafIdx,
            proof,
            proofOffset
        );

        {
            // TODO: support proving via an authenticated contract
            require(proof[proofOffset] == 0, "UNKNOWN_INBOX_PROOF");
            proofOffset++;

            function(ExecutionContext calldata, uint64, bytes calldata)
                internal
                view
                returns (bool) inboxValidate;

            bool success;
            if (inst.argumentData == Instructions.INBOX_INDEX_SEQUENCER) {
                inboxValidate = validateSequencerInbox;
            } else if (inst.argumentData == Instructions.INBOX_INDEX_DELAYED) {
                inboxValidate = validateDelayedInbox;
            } else {
                mach.status = MachineStatus.ERRORED;
                return;
            }
            success = inboxValidate(execCtx, uint64(msgIndex), proof[proofOffset:]);
            if (!success) {
                mach.status = MachineStatus.ERRORED;
                return;
            }
        }

        require(proof.length >= proofOffset, "BAD_MESSAGE_PROOF");
        uint256 messageLength = proof.length - proofOffset;

        uint32 i = 0;
        for (; i < 32 && messageOffset + i < messageLength; i++) {
            leafContents = setLeafByte(
                leafContents,
                i,
                uint8(proof[proofOffset + messageOffset + i])
            );
        }

        mod.moduleMemory.merkleRoot = merkleProof.computeRootFromMemory(leafIdx, leafContents);
        mach.valueStack.push(ValueLib.newI32(i));
    }

    function executeHaltAndSetFinished(
        ExecutionContext calldata,
        Machine memory mach,
        Module memory,
        Instruction calldata,
        bytes calldata
    ) internal pure {
        mach.status = MachineStatus.FINISHED;
    }

    function executeGlobalStateAccess(
        ExecutionContext calldata,
        Machine memory mach,
        Module memory mod,
        Instruction calldata inst,
        bytes calldata proof
    ) internal pure {
        uint16 opcode = inst.opcode;

        GlobalState memory state;
        uint256 proofOffset = 0;
        (state, proofOffset) = Deserialize.globalState(proof, proofOffset);
        require(state.hash() == mach.globalStateHash, "BAD_GLOBAL_STATE");

        if (
            opcode == Instructions.GET_GLOBAL_STATE_BYTES32 ||
            opcode == Instructions.SET_GLOBAL_STATE_BYTES32
        ) {
            executeGetOrSetBytes32(mach, mod, state, inst, proof[proofOffset:]);
        } else if (opcode == Instructions.GET_GLOBAL_STATE_U64) {
            executeGetU64(mach, state);
        } else if (opcode == Instructions.SET_GLOBAL_STATE_U64) {
            executeSetU64(mach, state);
        } else {
            revert("INVALID_GLOBALSTATE_OPCODE");
        }

        mach.globalStateHash = state.hash();
    }

    function executeOneStep(
        ExecutionContext calldata execCtx,
        Machine calldata startMach,
        Module calldata startMod,
        Instruction calldata inst,
        bytes calldata proof
    ) external view override returns (Machine memory mach, Module memory mod) {
        mach = startMach;
        mod = startMod;

        uint16 opcode = inst.opcode;

        function(
            ExecutionContext calldata,
            Machine memory,
            Module memory,
            Instruction calldata,
            bytes calldata
        ) internal view impl;

        if (
            opcode >= Instructions.GET_GLOBAL_STATE_BYTES32 &&
            opcode <= Instructions.SET_GLOBAL_STATE_U64
        ) {
            impl = executeGlobalStateAccess;
        } else if (opcode == Instructions.READ_PRE_IMAGE) {
            impl = executeReadPreImage;
        } else if (opcode == Instructions.READ_INBOX_MESSAGE) {
            impl = executeReadInboxMessage;
        } else if (opcode == Instructions.HALT_AND_SET_FINISHED) {
            impl = executeHaltAndSetFinished;
        } else {
            revert("INVALID_MEMORY_OPCODE");
        }

        impl(execCtx, mach, mod, inst, proof);
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../libraries/DelegateCallAware.sol";
import "../osp/IOneStepProofEntry.sol";
import "../state/GlobalState.sol";
import "./IChallengeResultReceiver.sol";
import "./ChallengeLib.sol";
import "./IChallengeManager.sol";

import {NO_CHAL_INDEX} from "../libraries/Constants.sol";

contract ChallengeManager is DelegateCallAware, IChallengeManager {
    using GlobalStateLib for GlobalState;
    using MachineLib for Machine;
    using ChallengeLib for ChallengeLib.Challenge;

    enum ChallengeModeRequirement {
        ANY,
        BLOCK,
        EXECUTION
    }

    string private constant NO_CHAL = "NO_CHAL";
    uint256 private constant MAX_CHALLENGE_DEGREE = 40;

    uint64 public totalChallengesCreated;
    mapping(uint256 => ChallengeLib.Challenge) public challenges;

    IChallengeResultReceiver public resultReceiver;

    ISequencerInbox public sequencerInbox;
    IBridge public bridge;
    IOneStepProofEntry public osp;

    function challengeInfo(uint64 challengeIndex)
        external
        view
        override
        returns (ChallengeLib.Challenge memory)
    {
        return challenges[challengeIndex];
    }

    modifier takeTurn(
        uint64 challengeIndex,
        ChallengeLib.SegmentSelection calldata selection,
        ChallengeModeRequirement expectedMode
    ) {
        ChallengeLib.Challenge storage challenge = challenges[challengeIndex];
        require(msg.sender == currentResponder(challengeIndex), "CHAL_SENDER");
        require(!isTimedOut(challengeIndex), "CHAL_DEADLINE");

        if (expectedMode == ChallengeModeRequirement.ANY) {
            require(challenge.mode != ChallengeLib.ChallengeMode.NONE, NO_CHAL);
        } else if (expectedMode == ChallengeModeRequirement.BLOCK) {
            require(challenge.mode == ChallengeLib.ChallengeMode.BLOCK, "CHAL_NOT_BLOCK");
        } else if (expectedMode == ChallengeModeRequirement.EXECUTION) {
            require(challenge.mode == ChallengeLib.ChallengeMode.EXECUTION, "CHAL_NOT_EXECUTION");
        } else {
            assert(false);
        }

        require(
            challenge.challengeStateHash ==
                ChallengeLib.hashChallengeState(
                    selection.oldSegmentsStart,
                    selection.oldSegmentsLength,
                    selection.oldSegments
                ),
            "BIS_STATE"
        );
        if (
            selection.oldSegments.length < 2 ||
            selection.challengePosition >= selection.oldSegments.length - 1
        ) {
            revert("BAD_CHALLENGE_POS");
        }

        _;

        if (challenge.mode == ChallengeLib.ChallengeMode.NONE) {
            // Early return since challenge must have terminated
            return;
        }

        ChallengeLib.Participant memory current = challenge.current;
        current.timeLeft -= block.timestamp - challenge.lastMoveTimestamp;

        challenge.current = challenge.next;
        challenge.next = current;

        challenge.lastMoveTimestamp = block.timestamp;
    }

    function initialize(
        IChallengeResultReceiver resultReceiver_,
        ISequencerInbox sequencerInbox_,
        IBridge bridge_,
        IOneStepProofEntry osp_
    ) external override onlyDelegated {
        require(address(resultReceiver) == address(0), "ALREADY_INIT");
        require(address(resultReceiver_) != address(0), "NO_RESULT_RECEIVER");
        resultReceiver = resultReceiver_;
        sequencerInbox = sequencerInbox_;
        bridge = bridge_;
        osp = osp_;
    }

    function createChallenge(
        bytes32 wasmModuleRoot_,
        MachineStatus[2] calldata startAndEndMachineStatuses_,
        GlobalState[2] calldata startAndEndGlobalStates_,
        uint64 numBlocks,
        address asserter_,
        address challenger_,
        uint256 asserterTimeLeft_,
        uint256 challengerTimeLeft_
    ) external override returns (uint64) {
        require(msg.sender == address(resultReceiver), "ONLY_ROLLUP_CHAL");
        bytes32[] memory segments = new bytes32[](2);
        segments[0] = ChallengeLib.blockStateHash(
            startAndEndMachineStatuses_[0],
            startAndEndGlobalStates_[0].hash()
        );
        segments[1] = ChallengeLib.blockStateHash(
            startAndEndMachineStatuses_[1],
            startAndEndGlobalStates_[1].hash()
        );

        uint64 challengeIndex = ++totalChallengesCreated;
        // The following is an assertion since it should never be possible, but it's an important invariant
        assert(challengeIndex != NO_CHAL_INDEX);
        ChallengeLib.Challenge storage challenge = challenges[challengeIndex];
        challenge.wasmModuleRoot = wasmModuleRoot_;

        // See validator/assertion.go ExecutionState RequiredBatches() for reasoning
        uint64 maxInboxMessagesRead = startAndEndGlobalStates_[1].getInboxPosition();
        if (
            startAndEndMachineStatuses_[1] == MachineStatus.ERRORED ||
            startAndEndGlobalStates_[1].getPositionInMessage() > 0
        ) {
            maxInboxMessagesRead++;
        }
        challenge.maxInboxMessages = maxInboxMessagesRead;
        challenge.next = ChallengeLib.Participant({addr: asserter_, timeLeft: asserterTimeLeft_});
        challenge.current = ChallengeLib.Participant({
            addr: challenger_,
            timeLeft: challengerTimeLeft_
        });
        challenge.lastMoveTimestamp = block.timestamp;
        challenge.mode = ChallengeLib.ChallengeMode.BLOCK;

        emit InitiatedChallenge(
            challengeIndex,
            startAndEndGlobalStates_[0],
            startAndEndGlobalStates_[1]
        );
        completeBisection(challengeIndex, 0, numBlocks, segments);
        return challengeIndex;
    }

    /**
     * @notice Initiate the next round in the bisection by objecting to execution correctness with a bisection
     * of an execution segment with the same length but a different endpoint. This is either the initial move
     * or follows another execution objection
     */
    function bisectExecution(
        uint64 challengeIndex,
        ChallengeLib.SegmentSelection calldata selection,
        bytes32[] calldata newSegments
    ) external takeTurn(challengeIndex, selection, ChallengeModeRequirement.ANY) {
        (uint256 challengeStart, uint256 challengeLength) = ChallengeLib.extractChallengeSegment(
            selection
        );
        require(challengeLength > 1, "TOO_SHORT");
        {
            uint256 expectedDegree = challengeLength;
            if (expectedDegree > MAX_CHALLENGE_DEGREE) {
                expectedDegree = MAX_CHALLENGE_DEGREE;
            }
            require(newSegments.length == expectedDegree + 1, "WRONG_DEGREE");
        }

        requireValidBisection(selection, newSegments[0], newSegments[newSegments.length - 1]);

        completeBisection(challengeIndex, challengeStart, challengeLength, newSegments);
    }

    function challengeExecution(
        uint64 challengeIndex,
        ChallengeLib.SegmentSelection calldata selection,
        MachineStatus[2] calldata machineStatuses,
        bytes32[2] calldata globalStateHashes,
        uint256 numSteps
    ) external takeTurn(challengeIndex, selection, ChallengeModeRequirement.BLOCK) {
        require(numSteps >= 1, "CHALLENGE_TOO_SHORT");
        require(numSteps <= OneStepProofEntryLib.MAX_STEPS, "CHALLENGE_TOO_LONG");
        requireValidBisection(
            selection,
            ChallengeLib.blockStateHash(machineStatuses[0], globalStateHashes[0]),
            ChallengeLib.blockStateHash(machineStatuses[1], globalStateHashes[1])
        );

        ChallengeLib.Challenge storage challenge = challenges[challengeIndex];
        (uint256 executionChallengeAtSteps, uint256 challengeLength) = ChallengeLib
            .extractChallengeSegment(selection);
        require(challengeLength == 1, "TOO_LONG");

        if (machineStatuses[0] != MachineStatus.FINISHED) {
            // If the machine is in a halted state, it can't change
            require(
                machineStatuses[0] == machineStatuses[1] &&
                    globalStateHashes[0] == globalStateHashes[1],
                "HALTED_CHANGE"
            );
            _currentWin(challengeIndex, ChallengeTerminationType.BLOCK_PROOF);
            return;
        }

        if (machineStatuses[1] == MachineStatus.ERRORED) {
            // If the machine errors, it must return to the previous global state
            require(globalStateHashes[0] == globalStateHashes[1], "ERROR_CHANGE");
        }

        bytes32[] memory segments = new bytes32[](2);
        segments[0] = ChallengeLib.getStartMachineHash(
            globalStateHashes[0],
            challenge.wasmModuleRoot
        );
        segments[1] = ChallengeLib.getEndMachineHash(machineStatuses[1], globalStateHashes[1]);

        challenge.mode = ChallengeLib.ChallengeMode.EXECUTION;

        completeBisection(challengeIndex, 0, numSteps, segments);

        emit ExecutionChallengeBegun(challengeIndex, executionChallengeAtSteps);
    }

    function oneStepProveExecution(
        uint64 challengeIndex,
        ChallengeLib.SegmentSelection calldata selection,
        bytes calldata proof
    ) external takeTurn(challengeIndex, selection, ChallengeModeRequirement.EXECUTION) {
        ChallengeLib.Challenge storage challenge = challenges[challengeIndex];
        uint256 challengeStart;
        {
            uint256 challengeLength;
            (challengeStart, challengeLength) = ChallengeLib.extractChallengeSegment(selection);
            require(challengeLength == 1, "TOO_LONG");
        }

        bytes32 afterHash = osp.proveOneStep(
            ExecutionContext({maxInboxMessagesRead: challenge.maxInboxMessages, bridge: bridge}),
            challengeStart,
            selection.oldSegments[selection.challengePosition],
            proof
        );
        require(
            afterHash != selection.oldSegments[selection.challengePosition + 1],
            "SAME_OSP_END"
        );

        emit OneStepProofCompleted(challengeIndex);
        _currentWin(challengeIndex, ChallengeTerminationType.EXECUTION_PROOF);
    }

    function timeout(uint64 challengeIndex) external override {
        require(challenges[challengeIndex].mode != ChallengeLib.ChallengeMode.NONE, NO_CHAL);
        require(isTimedOut(challengeIndex), "TIMEOUT_DEADLINE");
        _nextWin(challengeIndex, ChallengeTerminationType.TIMEOUT);
    }

    function clearChallenge(uint64 challengeIndex) external override {
        require(msg.sender == address(resultReceiver), "NOT_RES_RECEIVER");
        require(challenges[challengeIndex].mode != ChallengeLib.ChallengeMode.NONE, NO_CHAL);
        delete challenges[challengeIndex];
        emit ChallengeEnded(challengeIndex, ChallengeTerminationType.CLEARED);
    }

    function currentResponder(uint64 challengeIndex) public view override returns (address) {
        return challenges[challengeIndex].current.addr;
    }

    function currentResponderTimeLeft(uint64 challengeIndex)
        public
        view
        override
        returns (uint256)
    {
        return challenges[challengeIndex].current.timeLeft;
    }

    function isTimedOut(uint64 challengeIndex) public view override returns (bool) {
        return challenges[challengeIndex].isTimedOut();
    }

    function requireValidBisection(
        ChallengeLib.SegmentSelection calldata selection,
        bytes32 startHash,
        bytes32 endHash
    ) private pure {
        require(selection.oldSegments[selection.challengePosition] == startHash, "WRONG_START");
        require(selection.oldSegments[selection.challengePosition + 1] != endHash, "SAME_END");
    }

    function completeBisection(
        uint64 challengeIndex,
        uint256 challengeStart,
        uint256 challengeLength,
        bytes32[] memory newSegments
    ) private {
        assert(challengeLength >= 1);
        assert(newSegments.length >= 2);

        bytes32 challengeStateHash = ChallengeLib.hashChallengeState(
            challengeStart,
            challengeLength,
            newSegments
        );
        challenges[challengeIndex].challengeStateHash = challengeStateHash;

        emit Bisected(
            challengeIndex,
            challengeStateHash,
            challengeStart,
            challengeLength,
            newSegments
        );
    }

    /// @dev This function causes the mode of the challenge to be set to NONE by deleting the challenge
    function _nextWin(uint64 challengeIndex, ChallengeTerminationType reason) private {
        ChallengeLib.Challenge storage challenge = challenges[challengeIndex];
        address next = challenge.next.addr;
        address current = challenge.current.addr;
        delete challenges[challengeIndex];
        resultReceiver.completeChallenge(challengeIndex, next, current);
        emit ChallengeEnded(challengeIndex, reason);
    }

    /**
     * @dev this currently sets a challenge hash of 0 - no move is possible for the next participant to progress the
     * state. It is assumed that wherever this function is consumed, the turn is then adjusted for the opposite party
     * to timeout. This is done as a safety measure so challenges can only be resolved by timeouts during mainnet beta.
     */
    function _currentWin(
        uint64 challengeIndex,
        ChallengeTerminationType /* reason */
    ) private {
        ChallengeLib.Challenge storage challenge = challenges[challengeIndex];
        challenge.challengeStateHash = bytes32(0);

        //        address next = challenge.next.addr;
        //        address current = challenge.current.addr;
        //        delete challenges[challengeIndex];
        //        resultReceiver.completeChallenge(challengeIndex, current, next);
        //        emit ChallengeEnded(challengeIndex, reason);
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../challenge/ChallengeManager.sol";

contract SingleExecutionChallenge is ChallengeManager {
    constructor(
        IOneStepProofEntry osp_,
        IChallengeResultReceiver resultReceiver_,
        uint64 maxInboxMessagesRead_,
        bytes32[2] memory startAndEndHashes,
        uint256 numSteps_,
        address asserter_,
        address challenger_,
        uint256 asserterTimeLeft_,
        uint256 challengerTimeLeft_
    ) {
        osp = osp_;
        resultReceiver = resultReceiver_;
        uint64 challengeIndex = ++totalChallengesCreated;
        ChallengeLib.Challenge storage challenge = challenges[challengeIndex];
        challenge.maxInboxMessages = maxInboxMessagesRead_;
        bytes32[] memory segments = new bytes32[](2);
        segments[0] = startAndEndHashes[0];
        segments[1] = startAndEndHashes[1];
        bytes32 challengeStateHash = ChallengeLib.hashChallengeState(0, numSteps_, segments);
        challenge.challengeStateHash = challengeStateHash;
        challenge.next = ChallengeLib.Participant({addr: asserter_, timeLeft: asserterTimeLeft_});
        challenge.current = ChallengeLib.Participant({
            addr: challenger_,
            timeLeft: challengerTimeLeft_
        });
        challenge.lastMoveTimestamp = block.timestamp;
        challenge.mode = ChallengeLib.ChallengeMode.EXECUTION;

        emit Bisected(challengeIndex, challengeStateHash, 0, numSteps_, segments);
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../state/Value.sol";
import "../state/Machine.sol";
import "../state/Deserialize.sol";
import "./IOneStepProver.sol";

contract OneStepProverMemory is IOneStepProver {
    using MerkleProofLib for MerkleProof;
    using ModuleMemoryLib for ModuleMemory;
    using ValueLib for Value;
    using ValueStackLib for ValueStack;

    uint256 private constant LEAF_SIZE = 32;
    uint64 private constant PAGE_SIZE = 65536;

    function pullLeafByte(bytes32 leaf, uint256 idx) internal pure returns (uint8) {
        require(idx < LEAF_SIZE, "BAD_PULL_LEAF_BYTE_IDX");
        // Take into account that we are casting the leaf to a big-endian integer
        uint256 leafShift = (LEAF_SIZE - 1 - idx) * 8;
        return uint8(uint256(leaf) >> leafShift);
    }

    function setLeafByte(
        bytes32 oldLeaf,
        uint256 idx,
        uint8 val
    ) internal pure returns (bytes32) {
        require(idx < LEAF_SIZE, "BAD_SET_LEAF_BYTE_IDX");
        // Take into account that we are casting the leaf to a big-endian integer
        uint256 leafShift = (LEAF_SIZE - 1 - idx) * 8;
        uint256 newLeaf = uint256(oldLeaf);
        newLeaf &= ~(0xFF << leafShift);
        newLeaf |= uint256(val) << leafShift;
        return bytes32(newLeaf);
    }

    function executeMemoryLoad(
        Machine memory mach,
        Module memory mod,
        Instruction calldata inst,
        bytes calldata proof
    ) internal pure {
        ValueType ty;
        uint256 readBytes;
        bool signed;
        if (inst.opcode == Instructions.I32_LOAD) {
            ty = ValueType.I32;
            readBytes = 4;
            signed = false;
        } else if (inst.opcode == Instructions.I64_LOAD) {
            ty = ValueType.I64;
            readBytes = 8;
            signed = false;
        } else if (inst.opcode == Instructions.F32_LOAD) {
            ty = ValueType.F32;
            readBytes = 4;
            signed = false;
        } else if (inst.opcode == Instructions.F64_LOAD) {
            ty = ValueType.F64;
            readBytes = 8;
            signed = false;
        } else if (inst.opcode == Instructions.I32_LOAD8_S) {
            ty = ValueType.I32;
            readBytes = 1;
            signed = true;
        } else if (inst.opcode == Instructions.I32_LOAD8_U) {
            ty = ValueType.I32;
            readBytes = 1;
            signed = false;
        } else if (inst.opcode == Instructions.I32_LOAD16_S) {
            ty = ValueType.I32;
            readBytes = 2;
            signed = true;
        } else if (inst.opcode == Instructions.I32_LOAD16_U) {
            ty = ValueType.I32;
            readBytes = 2;
            signed = false;
        } else if (inst.opcode == Instructions.I64_LOAD8_S) {
            ty = ValueType.I64;
            readBytes = 1;
            signed = true;
        } else if (inst.opcode == Instructions.I64_LOAD8_U) {
            ty = ValueType.I64;
            readBytes = 1;
            signed = false;
        } else if (inst.opcode == Instructions.I64_LOAD16_S) {
            ty = ValueType.I64;
            readBytes = 2;
            signed = true;
        } else if (inst.opcode == Instructions.I64_LOAD16_U) {
            ty = ValueType.I64;
            readBytes = 2;
            signed = false;
        } else if (inst.opcode == Instructions.I64_LOAD32_S) {
            ty = ValueType.I64;
            readBytes = 4;
            signed = true;
        } else if (inst.opcode == Instructions.I64_LOAD32_U) {
            ty = ValueType.I64;
            readBytes = 4;
            signed = false;
        } else {
            revert("INVALID_MEMORY_LOAD_OPCODE");
        }

        // Neither of these can overflow as they're computed with much less than 256 bit integers.
        uint256 startIdx = inst.argumentData + mach.valueStack.pop().assumeI32();
        if (startIdx + readBytes > mod.moduleMemory.size) {
            mach.status = MachineStatus.ERRORED;
            return;
        }

        uint256 proofOffset = 0;
        uint256 lastProvedLeafIdx = ~uint256(0);
        bytes32 lastProvedLeafContents;
        uint64 readValue;
        for (uint256 i = 0; i < readBytes; i++) {
            uint256 idx = startIdx + i;
            uint256 leafIdx = idx / LEAF_SIZE;
            if (leafIdx != lastProvedLeafIdx) {
                // This hits the stack size if we phrase it as mod.moduleMemory.proveLeaf(...)
                (lastProvedLeafContents, proofOffset, ) = ModuleMemoryLib.proveLeaf(
                    mod.moduleMemory,
                    leafIdx,
                    proof,
                    proofOffset
                );
                lastProvedLeafIdx = leafIdx;
            }
            uint256 indexWithinLeaf = idx % LEAF_SIZE;
            readValue |=
                uint64(pullLeafByte(lastProvedLeafContents, indexWithinLeaf)) <<
                uint64(i * 8);
        }

        if (signed) {
            // Go down to the original uint size, change to signed, go up to correct size, convert back to unsigned
            if (readBytes == 1 && ty == ValueType.I32) {
                readValue = uint32(int32(int8(uint8(readValue))));
            } else if (readBytes == 1 && ty == ValueType.I64) {
                readValue = uint64(int64(int8(uint8(readValue))));
            } else if (readBytes == 2 && ty == ValueType.I32) {
                readValue = uint32(int32(int16(uint16(readValue))));
            } else if (readBytes == 2 && ty == ValueType.I64) {
                readValue = uint64(int64(int16(uint16(readValue))));
            } else if (readBytes == 4 && ty == ValueType.I64) {
                readValue = uint64(int64(int32(uint32(readValue))));
            } else {
                revert("BAD_READ_BYTES_SIGNED");
            }
        }

        mach.valueStack.push(Value({valueType: ty, contents: readValue}));
    }

    function executeMemoryStore(
        Machine memory mach,
        Module memory mod,
        Instruction calldata inst,
        bytes calldata proof
    ) internal pure {
        uint64 writeBytes;
        uint64 toWrite;
        {
            ValueType ty;
            if (inst.opcode == Instructions.I32_STORE) {
                ty = ValueType.I32;
                writeBytes = 4;
            } else if (inst.opcode == Instructions.I64_STORE) {
                ty = ValueType.I64;
                writeBytes = 8;
            } else if (inst.opcode == Instructions.F32_STORE) {
                ty = ValueType.F32;
                writeBytes = 4;
            } else if (inst.opcode == Instructions.F64_STORE) {
                ty = ValueType.F64;
                writeBytes = 8;
            } else if (inst.opcode == Instructions.I32_STORE8) {
                ty = ValueType.I32;
                writeBytes = 1;
            } else if (inst.opcode == Instructions.I32_STORE16) {
                ty = ValueType.I32;
                writeBytes = 2;
            } else if (inst.opcode == Instructions.I64_STORE8) {
                ty = ValueType.I64;
                writeBytes = 1;
            } else if (inst.opcode == Instructions.I64_STORE16) {
                ty = ValueType.I64;
                writeBytes = 2;
            } else if (inst.opcode == Instructions.I64_STORE32) {
                ty = ValueType.I64;
                writeBytes = 4;
            } else {
                revert("INVALID_MEMORY_STORE_OPCODE");
            }

            Value memory writingVal = mach.valueStack.pop();
            require(writingVal.valueType == ty, "BAD_STORE_TYPE");
            toWrite = uint64(writingVal.contents);
            if (writeBytes < 8) {
                toWrite &= (uint64(1) << (writeBytes * 8)) - 1;
            }
        }

        // Neither of these can overflow as they're computed with much less than 256 bit integers.
        uint256 startIdx = inst.argumentData + mach.valueStack.pop().assumeI32();
        if (startIdx + writeBytes > mod.moduleMemory.size) {
            mach.status = MachineStatus.ERRORED;
            return;
        }

        uint256 proofOffset = 0;
        uint256 lastProvedLeafIdx = ~uint256(0);
        MerkleProof memory lastProvedMerkle;
        bytes32 lastProvedLeafContents;
        for (uint256 i = 0; i < writeBytes; i++) {
            uint256 idx = startIdx + i;
            uint256 leafIdx = idx / LEAF_SIZE;
            if (leafIdx != lastProvedLeafIdx) {
                if (lastProvedLeafIdx != ~uint256(0)) {
                    // Apply the last leaf update
                    mod.moduleMemory.merkleRoot = lastProvedMerkle.computeRootFromMemory(
                        lastProvedLeafIdx,
                        lastProvedLeafContents
                    );
                }
                // This hits the stack size if we phrase it as mod.moduleMemory.proveLeaf(...)
                (lastProvedLeafContents, proofOffset, lastProvedMerkle) = ModuleMemoryLib.proveLeaf(
                    mod.moduleMemory,
                    leafIdx,
                    proof,
                    proofOffset
                );
                lastProvedLeafIdx = leafIdx;
            }
            uint256 indexWithinLeaf = idx % LEAF_SIZE;
            lastProvedLeafContents = setLeafByte(
                lastProvedLeafContents,
                indexWithinLeaf,
                uint8(toWrite)
            );
            toWrite >>= 8;
        }
        mod.moduleMemory.merkleRoot = lastProvedMerkle.computeRootFromMemory(
            lastProvedLeafIdx,
            lastProvedLeafContents
        );
    }

    function executeMemorySize(
        Machine memory mach,
        Module memory mod,
        Instruction calldata,
        bytes calldata
    ) internal pure {
        uint32 pages = uint32(mod.moduleMemory.size / PAGE_SIZE);
        mach.valueStack.push(ValueLib.newI32(pages));
    }

    function executeMemoryGrow(
        Machine memory mach,
        Module memory mod,
        Instruction calldata,
        bytes calldata
    ) internal pure {
        uint32 oldPages = uint32(mod.moduleMemory.size / PAGE_SIZE);
        uint32 growingPages = mach.valueStack.pop().assumeI32();
        // Safe as the input integers are too small to overflow a uint256
        uint256 newSize = uint256(oldPages) + uint256(growingPages);
        if (newSize <= mod.moduleMemory.maxSize) {
            mod.moduleMemory.size = uint64(newSize * PAGE_SIZE);
            mach.valueStack.push(ValueLib.newI32(oldPages));
        } else {
            mach.valueStack.push(ValueLib.newI32(~uint32(0)));
        }
    }

    function executeOneStep(
        ExecutionContext calldata,
        Machine calldata startMach,
        Module calldata startMod,
        Instruction calldata inst,
        bytes calldata proof
    ) external pure override returns (Machine memory mach, Module memory mod) {
        mach = startMach;
        mod = startMod;

        uint16 opcode = inst.opcode;

        function(Machine memory, Module memory, Instruction calldata, bytes calldata)
            internal
            pure impl;
        if (opcode >= Instructions.I32_LOAD && opcode <= Instructions.I64_LOAD32_U) {
            impl = executeMemoryLoad;
        } else if (opcode >= Instructions.I32_STORE && opcode <= Instructions.I64_STORE32) {
            impl = executeMemoryStore;
        } else if (opcode == Instructions.MEMORY_SIZE) {
            impl = executeMemorySize;
        } else if (opcode == Instructions.MEMORY_GROW) {
            impl = executeMemoryGrow;
        } else {
            revert("INVALID_MEMORY_OPCODE");
        }

        impl(mach, mod, inst, proof);
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../state/Value.sol";
import "../state/Machine.sol";
import "../state/Module.sol";
import "../state/Deserialize.sol";
import "./IOneStepProver.sol";

contract OneStepProverMath is IOneStepProver {
    using ValueLib for Value;
    using ValueStackLib for ValueStack;

    function executeEqz(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        Value memory v = mach.valueStack.pop();
        if (inst.opcode == Instructions.I32_EQZ) {
            require(v.valueType == ValueType.I32, "NOT_I32");
        } else if (inst.opcode == Instructions.I64_EQZ) {
            require(v.valueType == ValueType.I64, "NOT_I64");
        } else {
            revert("BAD_EQZ");
        }

        uint32 output;
        if (v.contents == 0) {
            output = 1;
        } else {
            output = 0;
        }

        mach.valueStack.push(ValueLib.newI32(output));
    }

    function signExtend(uint32 a) internal pure returns (uint64) {
        if (a & (1 << 31) != 0) {
            return uint64(a) | uint64(0xffffffff00000000);
        }
        return uint64(a);
    }

    function i64RelOp(
        uint64 a,
        uint64 b,
        uint16 relop
    ) internal pure returns (bool) {
        if (relop == Instructions.IRELOP_EQ) {
            return (a == b);
        } else if (relop == Instructions.IRELOP_NE) {
            return (a != b);
        } else if (relop == Instructions.IRELOP_LT_S) {
            return (int64(a) < int64(b));
        } else if (relop == Instructions.IRELOP_LT_U) {
            return (a < b);
        } else if (relop == Instructions.IRELOP_GT_S) {
            return (int64(a) > int64(b));
        } else if (relop == Instructions.IRELOP_GT_U) {
            return (a > b);
        } else if (relop == Instructions.IRELOP_LE_S) {
            return (int64(a) <= int64(b));
        } else if (relop == Instructions.IRELOP_LE_U) {
            return (a <= b);
        } else if (relop == Instructions.IRELOP_GE_S) {
            return (int64(a) >= int64(b));
        } else if (relop == Instructions.IRELOP_GE_U) {
            return (a >= b);
        } else {
            revert("BAD IRELOP");
        }
    }

    function executeI32RelOp(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        uint32 b = mach.valueStack.pop().assumeI32();
        uint32 a = mach.valueStack.pop().assumeI32();

        uint16 relop = inst.opcode - Instructions.I32_RELOP_BASE;
        uint64 a64;
        uint64 b64;

        if (
            relop == Instructions.IRELOP_LT_S ||
            relop == Instructions.IRELOP_GT_S ||
            relop == Instructions.IRELOP_LE_S ||
            relop == Instructions.IRELOP_GE_S
        ) {
            a64 = signExtend(a);
            b64 = signExtend(b);
        } else {
            a64 = uint64(a);
            b64 = uint64(b);
        }

        bool res = i64RelOp(a64, b64, relop);

        mach.valueStack.push(ValueLib.newBoolean(res));
    }

    function executeI64RelOp(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        uint64 b = mach.valueStack.pop().assumeI64();
        uint64 a = mach.valueStack.pop().assumeI64();

        uint16 relop = inst.opcode - Instructions.I64_RELOP_BASE;

        bool res = i64RelOp(a, b, relop);

        mach.valueStack.push(ValueLib.newBoolean(res));
    }

    function genericIUnOp(
        uint64 a,
        uint16 unop,
        uint16 bits
    ) internal pure returns (uint32) {
        require(bits == 32 || bits == 64, "WRONG USE OF genericUnOp");
        if (unop == Instructions.IUNOP_CLZ) {
            /* curbits is one-based to keep with unsigned mathematics */
            uint32 curbit = bits;
            while (curbit > 0 && (a & (1 << (curbit - 1)) == 0)) {
                curbit -= 1;
            }
            return (bits - curbit);
        } else if (unop == Instructions.IUNOP_CTZ) {
            uint32 curbit = 0;
            while (curbit < bits && ((a & (1 << curbit)) == 0)) {
                curbit += 1;
            }
            return curbit;
        } else if (unop == Instructions.IUNOP_POPCNT) {
            uint32 curbit = 0;
            uint32 res = 0;
            while (curbit < bits) {
                if ((a & (1 << curbit)) != 0) {
                    res += 1;
                }
                curbit++;
            }
            return res;
        }
        revert("BAD IUnOp");
    }

    function executeI32UnOp(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        uint32 a = mach.valueStack.pop().assumeI32();

        uint16 unop = inst.opcode - Instructions.I32_UNOP_BASE;

        uint32 res = genericIUnOp(a, unop, 32);

        mach.valueStack.push(ValueLib.newI32(res));
    }

    function executeI64UnOp(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        uint64 a = mach.valueStack.pop().assumeI64();

        uint16 unop = inst.opcode - Instructions.I64_UNOP_BASE;

        uint64 res = uint64(genericIUnOp(a, unop, 64));

        mach.valueStack.push(ValueLib.newI64(res));
    }

    function rotl32(uint32 a, uint32 b) internal pure returns (uint32) {
        b %= 32;
        return (a << b) | (a >> (32 - b));
    }

    function rotl64(uint64 a, uint64 b) internal pure returns (uint64) {
        b %= 64;
        return (a << b) | (a >> (64 - b));
    }

    function rotr32(uint32 a, uint32 b) internal pure returns (uint32) {
        b %= 32;
        return (a >> b) | (a << (32 - b));
    }

    function rotr64(uint64 a, uint64 b) internal pure returns (uint64) {
        b %= 64;
        return (a >> b) | (a << (64 - b));
    }

    function genericBinOp(
        uint64 a,
        uint64 b,
        uint16 opcodeOffset
    ) internal pure returns (uint64, bool) {
        unchecked {
            if (opcodeOffset == 0) {
                // add
                return (a + b, false);
            } else if (opcodeOffset == 1) {
                // sub
                return (a - b, false);
            } else if (opcodeOffset == 2) {
                // mul
                return (a * b, false);
            } else if (opcodeOffset == 4) {
                // div_u
                if (b == 0) {
                    return (0, true);
                }
                return (a / b, false);
            } else if (opcodeOffset == 6) {
                // rem_u
                if (b == 0) {
                    return (0, true);
                }
                return (a % b, false);
            } else if (opcodeOffset == 7) {
                // and
                return (a & b, false);
            } else if (opcodeOffset == 8) {
                // or
                return (a | b, false);
            } else if (opcodeOffset == 9) {
                // xor
                return (a ^ b, false);
            } else {
                revert("INVALID_GENERIC_BIN_OP");
            }
        }
    }

    function executeI32BinOp(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        uint32 b = mach.valueStack.pop().assumeI32();
        uint32 a = mach.valueStack.pop().assumeI32();
        uint32 res;

        uint16 opcodeOffset = inst.opcode - Instructions.I32_ADD;

        unchecked {
            if (opcodeOffset == 3) {
                // div_s
                if (b == 0 || (int32(a) == -2147483648 && int32(b) == -1)) {
                    mach.status = MachineStatus.ERRORED;
                    return;
                }
                res = uint32(int32(a) / int32(b));
            } else if (opcodeOffset == 5) {
                // rem_s
                if (b == 0) {
                    mach.status = MachineStatus.ERRORED;
                    return;
                }
                res = uint32(int32(a) % int32(b));
            } else if (opcodeOffset == 10) {
                // shl
                res = a << (b % 32);
            } else if (opcodeOffset == 12) {
                // shr_u
                res = a >> (b % 32);
            } else if (opcodeOffset == 11) {
                // shr_s
                res = uint32(int32(a) >> (b % 32));
            } else if (opcodeOffset == 13) {
                // rotl
                res = rotl32(a, b);
            } else if (opcodeOffset == 14) {
                // rotr
                res = rotr32(a, b);
            } else {
                (uint64 computed, bool err) = genericBinOp(a, b, opcodeOffset);
                if (err) {
                    mach.status = MachineStatus.ERRORED;
                    return;
                }
                res = uint32(computed);
            }
        }

        mach.valueStack.push(ValueLib.newI32(res));
    }

    function executeI64BinOp(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        uint64 b = mach.valueStack.pop().assumeI64();
        uint64 a = mach.valueStack.pop().assumeI64();
        uint64 res;

        uint16 opcodeOffset = inst.opcode - Instructions.I64_ADD;

        unchecked {
            if (opcodeOffset == 3) {
                // div_s
                if (b == 0 || (int64(a) == -9223372036854775808 && int64(b) == -1)) {
                    mach.status = MachineStatus.ERRORED;
                    return;
                }
                res = uint64(int64(a) / int64(b));
            } else if (opcodeOffset == 5) {
                // rem_s
                if (b == 0) {
                    mach.status = MachineStatus.ERRORED;
                    return;
                }
                res = uint64(int64(a) % int64(b));
            } else if (opcodeOffset == 10) {
                // shl
                res = a << (b % 64);
            } else if (opcodeOffset == 12) {
                // shr_u
                res = a >> (b % 64);
            } else if (opcodeOffset == 11) {
                // shr_s
                res = uint64(int64(a) >> (b % 64));
            } else if (opcodeOffset == 13) {
                // rotl
                res = rotl64(a, b);
            } else if (opcodeOffset == 14) {
                // rotr
                res = rotr64(a, b);
            } else {
                bool err;
                (res, err) = genericBinOp(a, b, opcodeOffset);
                if (err) {
                    mach.status = MachineStatus.ERRORED;
                    return;
                }
            }
        }

        mach.valueStack.push(ValueLib.newI64(res));
    }

    function executeI32WrapI64(
        Machine memory mach,
        Module memory,
        Instruction calldata,
        bytes calldata
    ) internal pure {
        uint64 a = mach.valueStack.pop().assumeI64();

        uint32 a32 = uint32(a);

        mach.valueStack.push(ValueLib.newI32(a32));
    }

    function executeI64ExtendI32(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        uint32 a = mach.valueStack.pop().assumeI32();

        uint64 a64;

        if (inst.opcode == Instructions.I64_EXTEND_I32_S) {
            a64 = signExtend(a);
        } else {
            a64 = uint64(a);
        }

        mach.valueStack.push(ValueLib.newI64(a64));
    }

    function executeExtendSameType(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        ValueType ty;
        uint8 sourceBits;
        if (inst.opcode == Instructions.I32_EXTEND_8S) {
            ty = ValueType.I32;
            sourceBits = 8;
        } else if (inst.opcode == Instructions.I32_EXTEND_16S) {
            ty = ValueType.I32;
            sourceBits = 16;
        } else if (inst.opcode == Instructions.I64_EXTEND_8S) {
            ty = ValueType.I64;
            sourceBits = 8;
        } else if (inst.opcode == Instructions.I64_EXTEND_16S) {
            ty = ValueType.I64;
            sourceBits = 16;
        } else if (inst.opcode == Instructions.I64_EXTEND_32S) {
            ty = ValueType.I64;
            sourceBits = 32;
        } else {
            revert("INVALID_EXTEND_SAME_TYPE");
        }
        uint256 resultMask;
        if (ty == ValueType.I32) {
            resultMask = (1 << 32) - 1;
        } else {
            resultMask = (1 << 64) - 1;
        }
        Value memory val = mach.valueStack.pop();
        require(val.valueType == ty, "BAD_EXTEND_SAME_TYPE_TYPE");
        uint256 sourceMask = (1 << sourceBits) - 1;
        val.contents &= sourceMask;
        if (val.contents & (1 << (sourceBits - 1)) != 0) {
            // Extend sign flag
            val.contents |= resultMask & ~sourceMask;
        }
        mach.valueStack.push(val);
    }

    function executeReinterpret(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        ValueType destTy;
        ValueType sourceTy;
        if (inst.opcode == Instructions.I32_REINTERPRET_F32) {
            destTy = ValueType.I32;
            sourceTy = ValueType.F32;
        } else if (inst.opcode == Instructions.I64_REINTERPRET_F64) {
            destTy = ValueType.I64;
            sourceTy = ValueType.F64;
        } else if (inst.opcode == Instructions.F32_REINTERPRET_I32) {
            destTy = ValueType.F32;
            sourceTy = ValueType.I32;
        } else if (inst.opcode == Instructions.F64_REINTERPRET_I64) {
            destTy = ValueType.F64;
            sourceTy = ValueType.I64;
        } else {
            revert("INVALID_REINTERPRET");
        }
        Value memory val = mach.valueStack.pop();
        require(val.valueType == sourceTy, "INVALID_REINTERPRET_TYPE");
        val.valueType = destTy;
        mach.valueStack.push(val);
    }

    function executeOneStep(
        ExecutionContext calldata,
        Machine calldata startMach,
        Module calldata startMod,
        Instruction calldata inst,
        bytes calldata proof
    ) external pure override returns (Machine memory mach, Module memory mod) {
        mach = startMach;
        mod = startMod;

        uint16 opcode = inst.opcode;

        function(Machine memory, Module memory, Instruction calldata, bytes calldata)
            internal
            pure impl;
        if (opcode == Instructions.I32_EQZ || opcode == Instructions.I64_EQZ) {
            impl = executeEqz;
        } else if (
            opcode >= Instructions.I32_RELOP_BASE &&
            opcode <= Instructions.I32_RELOP_BASE + Instructions.IRELOP_LAST
        ) {
            impl = executeI32RelOp;
        } else if (
            opcode >= Instructions.I32_UNOP_BASE &&
            opcode <= Instructions.I32_UNOP_BASE + Instructions.IUNOP_LAST
        ) {
            impl = executeI32UnOp;
        } else if (opcode >= Instructions.I32_ADD && opcode <= Instructions.I32_ROTR) {
            impl = executeI32BinOp;
        } else if (
            opcode >= Instructions.I64_RELOP_BASE &&
            opcode <= Instructions.I64_RELOP_BASE + Instructions.IRELOP_LAST
        ) {
            impl = executeI64RelOp;
        } else if (
            opcode >= Instructions.I64_UNOP_BASE &&
            opcode <= Instructions.I64_UNOP_BASE + Instructions.IUNOP_LAST
        ) {
            impl = executeI64UnOp;
        } else if (opcode >= Instructions.I64_ADD && opcode <= Instructions.I64_ROTR) {
            impl = executeI64BinOp;
        } else if (opcode == Instructions.I32_WRAP_I64) {
            impl = executeI32WrapI64;
        } else if (
            opcode == Instructions.I64_EXTEND_I32_S || opcode == Instructions.I64_EXTEND_I32_U
        ) {
            impl = executeI64ExtendI32;
        } else if (opcode >= Instructions.I32_EXTEND_8S && opcode <= Instructions.I64_EXTEND_32S) {
            impl = executeExtendSameType;
        } else if (
            opcode >= Instructions.I32_REINTERPRET_F32 && opcode <= Instructions.F64_REINTERPRET_I64
        ) {
            impl = executeReinterpret;
        } else {
            revert("INVALID_OPCODE");
        }

        impl(mach, mod, inst, proof);
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../state/Value.sol";
import "../state/Machine.sol";
import "../state/Module.sol";
import "../state/Deserialize.sol";
import "./IOneStepProver.sol";

contract OneStepProver0 is IOneStepProver {
    using MerkleProofLib for MerkleProof;
    using StackFrameLib for StackFrameWindow;
    using ValueLib for Value;
    using ValueStackLib for ValueStack;

    function executeUnreachable(
        Machine memory mach,
        Module memory,
        Instruction calldata,
        bytes calldata
    ) internal pure {
        mach.status = MachineStatus.ERRORED;
    }

    function executeNop(
        Machine memory mach,
        Module memory,
        Instruction calldata,
        bytes calldata
    ) internal pure {
        // :)
    }

    function executeConstPush(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        uint16 opcode = inst.opcode;
        ValueType ty;
        if (opcode == Instructions.I32_CONST) {
            ty = ValueType.I32;
        } else if (opcode == Instructions.I64_CONST) {
            ty = ValueType.I64;
        } else if (opcode == Instructions.F32_CONST) {
            ty = ValueType.F32;
        } else if (opcode == Instructions.F64_CONST) {
            ty = ValueType.F64;
        } else {
            revert("CONST_PUSH_INVALID_OPCODE");
        }

        mach.valueStack.push(Value({valueType: ty, contents: uint64(inst.argumentData)}));
    }

    function executeDrop(
        Machine memory mach,
        Module memory,
        Instruction calldata,
        bytes calldata
    ) internal pure {
        mach.valueStack.pop();
    }

    function executeSelect(
        Machine memory mach,
        Module memory,
        Instruction calldata,
        bytes calldata
    ) internal pure {
        uint32 selector = mach.valueStack.pop().assumeI32();
        Value memory b = mach.valueStack.pop();
        Value memory a = mach.valueStack.pop();

        if (selector != 0) {
            mach.valueStack.push(a);
        } else {
            mach.valueStack.push(b);
        }
    }

    function executeReturn(
        Machine memory mach,
        Module memory,
        Instruction calldata,
        bytes calldata
    ) internal pure {
        StackFrame memory frame = mach.frameStack.pop();
        if (frame.returnPc.valueType == ValueType.REF_NULL) {
            mach.status = MachineStatus.ERRORED;
            return;
        } else if (frame.returnPc.valueType != ValueType.INTERNAL_REF) {
            revert("INVALID_RETURN_PC_TYPE");
        }
        uint256 data = frame.returnPc.contents;
        uint32 pc = uint32(data);
        uint32 func = uint32(data >> 32);
        uint32 mod = uint32(data >> 64);
        require(data >> 96 == 0, "INVALID_RETURN_PC_DATA");
        mach.functionPc = pc;
        mach.functionIdx = func;
        mach.moduleIdx = mod;
    }

    function createReturnValue(Machine memory mach) internal pure returns (Value memory) {
        uint256 returnData = 0;
        returnData |= mach.functionPc;
        returnData |= uint256(mach.functionIdx) << 32;
        returnData |= uint256(mach.moduleIdx) << 64;
        return Value({valueType: ValueType.INTERNAL_REF, contents: returnData});
    }

    function executeCall(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        // Push the return pc to the stack
        mach.valueStack.push(createReturnValue(mach));

        // Push caller module info to the stack
        StackFrame memory frame = mach.frameStack.peek();
        mach.valueStack.push(ValueLib.newI32(frame.callerModule));
        mach.valueStack.push(ValueLib.newI32(frame.callerModuleInternals));

        // Jump to the target
        uint32 idx = uint32(inst.argumentData);
        require(idx == inst.argumentData, "BAD_CALL_DATA");
        mach.functionIdx = idx;
        mach.functionPc = 0;
    }

    function executeCrossModuleCall(
        Machine memory mach,
        Module memory mod,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        // Push the return pc to the stack
        mach.valueStack.push(createReturnValue(mach));

        // Push caller module info to the stack
        mach.valueStack.push(ValueLib.newI32(mach.moduleIdx));
        mach.valueStack.push(ValueLib.newI32(mod.internalsOffset));

        // Jump to the target
        uint32 func = uint32(inst.argumentData);
        uint32 module = uint32(inst.argumentData >> 32);
        require(inst.argumentData >> 64 == 0, "BAD_CROSS_MODULE_CALL_DATA");
        mach.moduleIdx = module;
        mach.functionIdx = func;
        mach.functionPc = 0;
    }

    function executeCallerModuleInternalCall(
        Machine memory mach,
        Module memory mod,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        // Push the return pc to the stack
        mach.valueStack.push(createReturnValue(mach));

        // Push caller module info to the stack
        mach.valueStack.push(ValueLib.newI32(mach.moduleIdx));
        mach.valueStack.push(ValueLib.newI32(mod.internalsOffset));

        StackFrame memory frame = mach.frameStack.peek();
        if (frame.callerModuleInternals == 0) {
            // The caller module has no internals
            mach.status = MachineStatus.ERRORED;
            return;
        }

        // Jump to the target
        uint32 offset = uint32(inst.argumentData);
        require(offset == inst.argumentData, "BAD_CALLER_INTERNAL_CALL_DATA");
        mach.moduleIdx = frame.callerModule;
        mach.functionIdx = frame.callerModuleInternals + offset;
        mach.functionPc = 0;
    }

    function executeCallIndirect(
        Machine memory mach,
        Module memory mod,
        Instruction calldata inst,
        bytes calldata proof
    ) internal pure {
        uint32 funcIdx;
        {
            uint32 elementIdx = mach.valueStack.pop().assumeI32();

            // Prove metadata about the instruction and tables
            bytes32 elemsRoot;
            bytes32 wantedFuncTypeHash;
            uint256 offset = 0;
            {
                uint64 tableIdx;
                uint8 tableType;
                uint64 tableSize;
                MerkleProof memory tableMerkleProof;
                (tableIdx, offset) = Deserialize.u64(proof, offset);
                (wantedFuncTypeHash, offset) = Deserialize.b32(proof, offset);
                (tableType, offset) = Deserialize.u8(proof, offset);
                (tableSize, offset) = Deserialize.u64(proof, offset);
                (elemsRoot, offset) = Deserialize.b32(proof, offset);
                (tableMerkleProof, offset) = Deserialize.merkleProof(proof, offset);

                // Validate the information by recomputing known hashes
                bytes32 recomputed = keccak256(
                    abi.encodePacked("Call indirect:", tableIdx, wantedFuncTypeHash)
                );
                require(recomputed == bytes32(inst.argumentData), "BAD_CALL_INDIRECT_DATA");
                recomputed = tableMerkleProof.computeRootFromTable(
                    tableIdx,
                    tableType,
                    tableSize,
                    elemsRoot
                );
                require(recomputed == mod.tablesMerkleRoot, "BAD_TABLES_ROOT");

                // Check if the table access is out of bounds
                if (elementIdx >= tableSize) {
                    mach.status = MachineStatus.ERRORED;
                    return;
                }
            }

            bytes32 elemFuncTypeHash;
            Value memory functionPointer;
            MerkleProof memory elementMerkleProof;
            (elemFuncTypeHash, offset) = Deserialize.b32(proof, offset);
            (functionPointer, offset) = Deserialize.value(proof, offset);
            (elementMerkleProof, offset) = Deserialize.merkleProof(proof, offset);
            bytes32 recomputedElemRoot = elementMerkleProof.computeRootFromElement(
                elementIdx,
                elemFuncTypeHash,
                functionPointer
            );
            require(recomputedElemRoot == elemsRoot, "BAD_ELEMENTS_ROOT");

            if (elemFuncTypeHash != wantedFuncTypeHash) {
                mach.status = MachineStatus.ERRORED;
                return;
            }

            if (functionPointer.valueType == ValueType.REF_NULL) {
                mach.status = MachineStatus.ERRORED;
                return;
            } else if (functionPointer.valueType == ValueType.FUNC_REF) {
                funcIdx = uint32(functionPointer.contents);
                require(funcIdx == functionPointer.contents, "BAD_FUNC_REF_CONTENTS");
            } else {
                revert("BAD_ELEM_TYPE");
            }
        }

        // Push the return pc to the stack
        mach.valueStack.push(createReturnValue(mach));

        // Push caller module info to the stack
        StackFrame memory frame = mach.frameStack.peek();
        mach.valueStack.push(ValueLib.newI32(frame.callerModule));
        mach.valueStack.push(ValueLib.newI32(frame.callerModuleInternals));

        // Jump to the target
        mach.functionIdx = funcIdx;
        mach.functionPc = 0;
    }

    function executeArbitraryJump(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        // Jump to target
        uint32 pc = uint32(inst.argumentData);
        require(pc == inst.argumentData, "BAD_CALL_DATA");
        mach.functionPc = pc;
    }

    function executeArbitraryJumpIf(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        uint32 cond = mach.valueStack.pop().assumeI32();
        if (cond != 0) {
            // Jump to target
            uint32 pc = uint32(inst.argumentData);
            require(pc == inst.argumentData, "BAD_CALL_DATA");
            mach.functionPc = pc;
        }
    }

    function merkleProveGetValue(
        bytes32 merkleRoot,
        uint256 index,
        bytes calldata proof
    ) internal pure returns (Value memory) {
        uint256 offset = 0;
        Value memory proposedVal;
        MerkleProof memory merkle;
        (proposedVal, offset) = Deserialize.value(proof, offset);
        (merkle, offset) = Deserialize.merkleProof(proof, offset);
        bytes32 recomputedRoot = merkle.computeRootFromValue(index, proposedVal);
        require(recomputedRoot == merkleRoot, "WRONG_MERKLE_ROOT");
        return proposedVal;
    }

    function merkleProveSetValue(
        bytes32 merkleRoot,
        uint256 index,
        Value memory newVal,
        bytes calldata proof
    ) internal pure returns (bytes32) {
        Value memory oldVal;
        uint256 offset = 0;
        MerkleProof memory merkle;
        (oldVal, offset) = Deserialize.value(proof, offset);
        (merkle, offset) = Deserialize.merkleProof(proof, offset);
        bytes32 recomputedRoot = merkle.computeRootFromValue(index, oldVal);
        require(recomputedRoot == merkleRoot, "WRONG_MERKLE_ROOT");
        return merkle.computeRootFromValue(index, newVal);
    }

    function executeLocalGet(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata proof
    ) internal pure {
        StackFrame memory frame = mach.frameStack.peek();
        Value memory val = merkleProveGetValue(frame.localsMerkleRoot, inst.argumentData, proof);
        mach.valueStack.push(val);
    }

    function executeLocalSet(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata proof
    ) internal pure {
        Value memory newVal = mach.valueStack.pop();
        StackFrame memory frame = mach.frameStack.peek();
        frame.localsMerkleRoot = merkleProveSetValue(
            frame.localsMerkleRoot,
            inst.argumentData,
            newVal,
            proof
        );
    }

    function executeGlobalGet(
        Machine memory mach,
        Module memory mod,
        Instruction calldata inst,
        bytes calldata proof
    ) internal pure {
        Value memory val = merkleProveGetValue(mod.globalsMerkleRoot, inst.argumentData, proof);
        mach.valueStack.push(val);
    }

    function executeGlobalSet(
        Machine memory mach,
        Module memory mod,
        Instruction calldata inst,
        bytes calldata proof
    ) internal pure {
        Value memory newVal = mach.valueStack.pop();
        mod.globalsMerkleRoot = merkleProveSetValue(
            mod.globalsMerkleRoot,
            inst.argumentData,
            newVal,
            proof
        );
    }

    function executeInitFrame(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        Value memory callerModuleInternals = mach.valueStack.pop();
        Value memory callerModule = mach.valueStack.pop();
        Value memory returnPc = mach.valueStack.pop();
        StackFrame memory newFrame = StackFrame({
            returnPc: returnPc,
            localsMerkleRoot: bytes32(inst.argumentData),
            callerModule: callerModule.assumeI32(),
            callerModuleInternals: callerModuleInternals.assumeI32()
        });
        mach.frameStack.push(newFrame);
    }

    function executeMoveInternal(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        Value memory val;
        if (inst.opcode == Instructions.MOVE_FROM_STACK_TO_INTERNAL) {
            val = mach.valueStack.pop();
            mach.internalStack.push(val);
        } else if (inst.opcode == Instructions.MOVE_FROM_INTERNAL_TO_STACK) {
            val = mach.internalStack.pop();
            mach.valueStack.push(val);
        } else {
            revert("MOVE_INTERNAL_INVALID_OPCODE");
        }
    }

    function executeDup(
        Machine memory mach,
        Module memory,
        Instruction calldata,
        bytes calldata
    ) internal pure {
        Value memory val = mach.valueStack.peek();
        mach.valueStack.push(val);
    }

    function executeOneStep(
        ExecutionContext calldata,
        Machine calldata startMach,
        Module calldata startMod,
        Instruction calldata inst,
        bytes calldata proof
    ) external pure override returns (Machine memory mach, Module memory mod) {
        mach = startMach;
        mod = startMod;

        uint16 opcode = inst.opcode;

        function(Machine memory, Module memory, Instruction calldata, bytes calldata)
            internal
            pure impl;
        if (opcode == Instructions.UNREACHABLE) {
            impl = executeUnreachable;
        } else if (opcode == Instructions.NOP) {
            impl = executeNop;
        } else if (opcode == Instructions.RETURN) {
            impl = executeReturn;
        } else if (opcode == Instructions.CALL) {
            impl = executeCall;
        } else if (opcode == Instructions.CROSS_MODULE_CALL) {
            impl = executeCrossModuleCall;
        } else if (opcode == Instructions.CALLER_MODULE_INTERNAL_CALL) {
            impl = executeCallerModuleInternalCall;
        } else if (opcode == Instructions.CALL_INDIRECT) {
            impl = executeCallIndirect;
        } else if (opcode == Instructions.ARBITRARY_JUMP) {
            impl = executeArbitraryJump;
        } else if (opcode == Instructions.ARBITRARY_JUMP_IF) {
            impl = executeArbitraryJumpIf;
        } else if (opcode == Instructions.LOCAL_GET) {
            impl = executeLocalGet;
        } else if (opcode == Instructions.LOCAL_SET) {
            impl = executeLocalSet;
        } else if (opcode == Instructions.GLOBAL_GET) {
            impl = executeGlobalGet;
        } else if (opcode == Instructions.GLOBAL_SET) {
            impl = executeGlobalSet;
        } else if (opcode == Instructions.INIT_FRAME) {
            impl = executeInitFrame;
        } else if (opcode == Instructions.DROP) {
            impl = executeDrop;
        } else if (opcode == Instructions.SELECT) {
            impl = executeSelect;
        } else if (opcode >= Instructions.I32_CONST && opcode <= Instructions.F64_CONST) {
            impl = executeConstPush;
        } else if (
            opcode == Instructions.MOVE_FROM_STACK_TO_INTERNAL ||
            opcode == Instructions.MOVE_FROM_INTERNAL_TO_STACK
        ) {
            impl = executeMoveInternal;
        } else if (opcode == Instructions.DUP) {
            impl = executeDup;
        } else {
            revert("INVALID_OPCODE");
        }

        impl(mach, mod, inst, proof);
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../state/Deserialize.sol";
import "../state/Machine.sol";
import "../state/MerkleProof.sol";
import "./IOneStepProver.sol";
import "./IOneStepProofEntry.sol";

contract OneStepProofEntry is IOneStepProofEntry {
    using MerkleProofLib for MerkleProof;
    using MachineLib for Machine;

    IOneStepProver public prover0;
    IOneStepProver public proverMem;
    IOneStepProver public proverMath;
    IOneStepProver public proverHostIo;

    constructor(
        IOneStepProver prover0_,
        IOneStepProver proverMem_,
        IOneStepProver proverMath_,
        IOneStepProver proverHostIo_
    ) {
        prover0 = prover0_;
        proverMem = proverMem_;
        proverMath = proverMath_;
        proverHostIo = proverHostIo_;
    }

    function proveOneStep(
        ExecutionContext calldata execCtx,
        uint256 machineStep,
        bytes32 beforeHash,
        bytes calldata proof
    ) external view override returns (bytes32 afterHash) {
        Machine memory mach;
        Module memory mod;
        MerkleProof memory modProof;
        Instruction memory inst;

        {
            uint256 offset = 0;
            (mach, offset) = Deserialize.machine(proof, offset);
            require(mach.hash() == beforeHash, "MACHINE_BEFORE_HASH");
            if (mach.status != MachineStatus.RUNNING) {
                // Machine is halted.
                // WARNING: at this point, most machine fields are unconstrained.
                return mach.hash();
            }

            if (machineStep + 1 == OneStepProofEntryLib.MAX_STEPS) {
                mach.status = MachineStatus.ERRORED;
                return mach.hash();
            }

            (mod, offset) = Deserialize.module(proof, offset);
            (modProof, offset) = Deserialize.merkleProof(proof, offset);
            require(
                modProof.computeRootFromModule(mach.moduleIdx, mod) == mach.modulesRoot,
                "MODULES_ROOT"
            );

            {
                MerkleProof memory instProof;
                MerkleProof memory funcProof;
                (inst, offset) = Deserialize.instruction(proof, offset);
                (instProof, offset) = Deserialize.merkleProof(proof, offset);
                (funcProof, offset) = Deserialize.merkleProof(proof, offset);
                bytes32 codeHash = instProof.computeRootFromInstruction(mach.functionPc, inst);
                bytes32 recomputedRoot = funcProof.computeRootFromFunction(
                    mach.functionIdx,
                    codeHash
                );
                require(recomputedRoot == mod.functionsMerkleRoot, "BAD_FUNCTIONS_ROOT");
            }
            proof = proof[offset:];
        }

        uint256 oldModIdx = mach.moduleIdx;
        mach.functionPc += 1;
        uint16 opcode = inst.opcode;
        IOneStepProver prover;
        if (
            (opcode >= Instructions.I32_LOAD && opcode <= Instructions.I64_LOAD32_U) ||
            (opcode >= Instructions.I32_STORE && opcode <= Instructions.I64_STORE32) ||
            opcode == Instructions.MEMORY_SIZE ||
            opcode == Instructions.MEMORY_GROW
        ) {
            prover = proverMem;
        } else if (
            (opcode == Instructions.I32_EQZ || opcode == Instructions.I64_EQZ) ||
            (opcode >= Instructions.I32_RELOP_BASE &&
                opcode <= Instructions.I32_RELOP_BASE + Instructions.IRELOP_LAST) ||
            (opcode >= Instructions.I32_UNOP_BASE &&
                opcode <= Instructions.I32_UNOP_BASE + Instructions.IUNOP_LAST) ||
            (opcode >= Instructions.I32_ADD && opcode <= Instructions.I32_ROTR) ||
            (opcode >= Instructions.I64_RELOP_BASE &&
                opcode <= Instructions.I64_RELOP_BASE + Instructions.IRELOP_LAST) ||
            (opcode >= Instructions.I64_UNOP_BASE &&
                opcode <= Instructions.I64_UNOP_BASE + Instructions.IUNOP_LAST) ||
            (opcode >= Instructions.I64_ADD && opcode <= Instructions.I64_ROTR) ||
            (opcode == Instructions.I32_WRAP_I64) ||
            (opcode == Instructions.I64_EXTEND_I32_S || opcode == Instructions.I64_EXTEND_I32_U) ||
            (opcode >= Instructions.I32_EXTEND_8S && opcode <= Instructions.I64_EXTEND_32S) ||
            (opcode >= Instructions.I32_REINTERPRET_F32 &&
                opcode <= Instructions.F64_REINTERPRET_I64)
        ) {
            prover = proverMath;
        } else if (
            (opcode >= Instructions.GET_GLOBAL_STATE_BYTES32 &&
                opcode <= Instructions.SET_GLOBAL_STATE_U64) ||
            (opcode >= Instructions.READ_PRE_IMAGE && opcode <= Instructions.HALT_AND_SET_FINISHED)
        ) {
            prover = proverHostIo;
        } else {
            prover = prover0;
        }

        (mach, mod) = prover.executeOneStep(execCtx, mach, mod, inst, proof);

        mach.modulesRoot = modProof.computeRootFromModule(oldModIdx, mod);

        return mach.hash();
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../state/ValueArray.sol";

contract ValueArrayTester {
    using ValueArrayLib for ValueArray;

    function test() external pure {
        ValueArray memory arr = ValueArray(new Value[](2));
        require(arr.length() == 2, "START_LEN");
        arr.set(0, ValueLib.newI32(1));
        arr.set(1, ValueLib.newI32(2));
        arr.push(ValueLib.newI32(3));
        require(arr.length() == 3, "PUSH_LEN");
        for (uint256 i = 0; i < arr.length(); i++) {
            Value memory val = arr.get(i);
            require(val.valueType == ValueType.I32, "PUSH_VAL_TYPE");
            require(val.contents == i + 1, "PUSH_VAL_CONTENTS");
        }
        Value memory popped = arr.pop();
        require(popped.valueType == ValueType.I32, "POP_RET_TYPE");
        require(popped.contents == 3, "POP_RET_CONTENTS");
        require(arr.length() == 2, "POP_LEN");
        for (uint256 i = 0; i < arr.length(); i++) {
            Value memory val = arr.get(i);
            require(val.valueType == ValueType.I32, "POP_VAL_TYPE");
            require(val.contents == i + 1, "POP_VAL_CONTENTS");
        }
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../challenge/IChallengeResultReceiver.sol";
import "../challenge/IChallengeManager.sol";

contract MockResultReceiver is IChallengeResultReceiver {
    IChallengeManager public manager;
    address public winner;
    address public loser;
    uint256 public challengeIndex;

    event ChallengeCompleted(
        uint256 indexed challengeIndex,
        address indexed winner,
        address indexed loser
    );

    constructor(IChallengeManager manager_) {
        manager = manager_;
    }

    function createChallenge(
        bytes32 wasmModuleRoot_,
        MachineStatus[2] calldata startAndEndMachineStatuses_,
        GlobalState[2] calldata startAndEndGlobalStates_,
        uint64 numBlocks,
        address asserter_,
        address challenger_,
        uint256 asserterTimeLeft_,
        uint256 challengerTimeLeft_
    ) external returns (uint64) {
        return
            manager.createChallenge(
                wasmModuleRoot_,
                startAndEndMachineStatuses_,
                startAndEndGlobalStates_,
                numBlocks,
                asserter_,
                challenger_,
                asserterTimeLeft_,
                challengerTimeLeft_
            );
    }

    function completeChallenge(
        uint256 challengeIndex_,
        address winner_,
        address loser_
    ) external override {
        winner = winner_;
        loser = loser_;
        challengeIndex = challengeIndex_;
        emit ChallengeCompleted(challengeIndex, winner_, loser_);
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../bridge/SequencerInbox.sol";

contract SequencerInboxStub is SequencerInbox {
    constructor(
        IBridge bridge_,
        address sequencer_,
        ISequencerInbox.MaxTimeVariation memory maxTimeVariation_
    ) {
        bridge = bridge_;
        rollup = IOwnable(msg.sender);
        maxTimeVariation = maxTimeVariation_;
        isBatchPoster[sequencer_] = true;
    }

    function addInitMessage() external {
        (bytes32 dataHash, TimeBounds memory timeBounds) = formEmptyDataHash(0);
        (
            uint256 sequencerMessageCount,
            bytes32 beforeAcc,
            bytes32 delayedAcc,
            bytes32 afterAcc
        ) = addSequencerL2BatchImpl(dataHash, 0, 0, 0, 1);
        emit SequencerBatchDelivered(
            sequencerMessageCount,
            beforeAcc,
            afterAcc,
            delayedAcc,
            totalDelayedMessagesRead,
            timeBounds,
            BatchDataLocation.NoData
        );
    }

    function getTimeBounds() internal view override returns (TimeBounds memory bounds) {
        this; // silence warning about function not being view
        return bounds;
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../precompiles/ArbRetryableTx.sol";
import "../precompiles/ArbSys.sol";

contract Simple {
    uint64 public counter;

    event CounterEvent(uint64 count);
    event RedeemedEvent(address caller, address redeemer);
    event NullEvent();

    function increment() external {
        counter++;
    }

    function incrementEmit() external {
        counter++;
        emit CounterEvent(counter);
    }

    function incrementRedeem() external {
        counter++;
        emit RedeemedEvent(msg.sender, ArbRetryableTx(address(110)).getCurrentRedeemer());
    }

    function emitNullEvent() external {
        emit NullEvent();
    }

    function checkBlockHashes() external view returns (uint256) {
        require(blockhash(block.number - 1) != blockhash(block.number - 2), "SAME_BLOCK_HASH");
        return block.number;
    }

    function noop() external pure {}

    function pleaseRevert() external pure {
        revert("SOLIDITY_REVERTING");
    }

    function checkIsTopLevelOrWasAliased(bool useTopLevel, bool expected) public view {
        if (useTopLevel) {
            require(ArbSys(address(100)).isTopLevelCall() == expected, "UNEXPECTED_RESULT");
        } else {
            require(
                ArbSys(address(100)).wasMyCallersAddressAliased() == expected,
                "UNEXPECTED_RESULT"
            );
        }
    }

    function checkCalls(
        bool useTopLevel,
        bool directCase,
        bool staticCase,
        bool delegateCase,
        bool callcodeCase,
        bool callCase
    ) public {
        // DIRECT CALL
        if (useTopLevel) {
            require(ArbSys(address(100)).isTopLevelCall() == directCase, "UNEXPECTED_RESULT");
        } else {
            require(
                ArbSys(address(100)).wasMyCallersAddressAliased() == directCase,
                "UNEXPECTED_RESULT"
            );
        }

        // STATIC CALL
        this.checkIsTopLevelOrWasAliased(useTopLevel, staticCase);

        // DELEGATE CALL
        bytes memory data = abi.encodeWithSelector(
            this.checkIsTopLevelOrWasAliased.selector,
            useTopLevel,
            delegateCase
        );
        (bool success, ) = address(this).delegatecall(data);
        require(success, "DELEGATE_CALL_FAILED");

        // CALLCODE
        data = abi.encodeWithSelector(
            this.checkIsTopLevelOrWasAliased.selector,
            useTopLevel,
            callcodeCase
        );
        assembly {
            success := callcode(gas(), address(), 0, add(data, 32), mload(data), 0, 0)
        }
        require(success, "CALLCODE_FAILED");

        // CALL
        data = abi.encodeWithSelector(
            this.checkIsTopLevelOrWasAliased.selector,
            useTopLevel,
            callCase
        );
        (success, ) = address(this).call(data);
        require(success, "CALL_FAILED");
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title Methods for managing retryables.
 * @notice Precompiled contract in every Arbitrum chain for retryable transaction related data retrieval and interactions. Exists at 0x000000000000000000000000000000000000006e
 */
interface ArbRetryableTx {
    /**
     * @notice Schedule an attempt to redeem a redeemable tx, donating all of the call's gas to the redeem.
     * Revert if ticketId does not exist.
     * @param ticketId unique identifier of retryable message: keccak256(keccak256(ArbchainId, inbox-sequence-number), uint(0) )
     * @return txId that the redeem attempt will have
     */
    function redeem(bytes32 ticketId) external returns (bytes32);

    /**
     * @notice Return the minimum lifetime of redeemable txn.
     * @return lifetime in seconds
     */
    function getLifetime() external view returns (uint256);

    /**
     * @notice Return the timestamp when ticketId will age out, reverting if it does not exist
     * @param ticketId unique ticket identifier
     * @return timestamp for ticket's deadline
     */
    function getTimeout(bytes32 ticketId) external view returns (uint256);

    /**
     * @notice Adds one lifetime period to the life of ticketId.
     * Donate gas to pay for the lifetime extension.
     * If successful, emits LifetimeExtended event.
     * Revert if ticketId does not exist, or if the timeout of ticketId is already at least one lifetime period in the future.
     * @param ticketId unique ticket identifier
     * @return new timeout of ticketId
     */
    function keepalive(bytes32 ticketId) external returns (uint256);

    /**
     * @notice Return the beneficiary of ticketId.
     * Revert if ticketId doesn't exist.
     * @param ticketId unique ticket identifier
     * @return address of beneficiary for ticket
     */
    function getBeneficiary(bytes32 ticketId) external view returns (address);

    /**
     * @notice Cancel ticketId and refund its callvalue to its beneficiary.
     * Revert if ticketId doesn't exist, or if called by anyone other than ticketId's beneficiary.
     * @param ticketId unique ticket identifier
     */
    function cancel(bytes32 ticketId) external;

    /**
     * @notice Gets the redeemer of the current retryable redeem attempt.
     * Returns the zero address if the current transaction is not a retryable redeem attempt.
     * If this is an auto-redeem, returns the fee refund address of the retryable.
     */
    function getCurrentRedeemer() external view returns (address);

    /**
     * @notice Do not call. This method represents a retryable submission to aid explorers.
     * Calling it will always revert.
     */
    function submitRetryable(
        bytes32 requestId,
        uint256 l1BaseFee,
        uint256 deposit,
        uint256 callvalue,
        uint256 gasFeeCap,
        uint64 gasLimit,
        uint256 maxSubmissionFee,
        address feeRefundAddress,
        address beneficiary,
        address retryTo,
        bytes calldata retryData
    ) external;

    event TicketCreated(bytes32 indexed ticketId);
    event LifetimeExtended(bytes32 indexed ticketId, uint256 newTimeout);
    event RedeemScheduled(
        bytes32 indexed ticketId,
        bytes32 indexed retryTxHash,
        uint64 indexed sequenceNum,
        uint64 donatedGas,
        address gasDonor,
        uint256 maxRefund,
        uint256 submissionFeeRefund
    );
    event Canceled(bytes32 indexed ticketId);

    /// @dev DEPRECATED in favour of new RedeemScheduled event after the nitro upgrade
    event Redeemed(bytes32 indexed userTxHash);

    error NoTicketWithID();
    error NotCallable();
}