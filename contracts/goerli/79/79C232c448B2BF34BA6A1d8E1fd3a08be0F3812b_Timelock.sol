// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.9;

////////////////////////////////////////////////////////////////////////////////
///				 ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// This file is under the copyright license: Copyright 2020 Compound Labs, Inc.
/// 
/// Timelock.sol is a modification of Nouns DAO's NounsDAOExecutor.sol:
/// https://github.com/nounsDAO/nouns-monorepo/blob/master/packages/nouns-contracts/contracts/governance/NounsDAOExecutor.sol
///
/// Copyright licensing is under the BSD-3-Clause license, as the above contract
/// is a rework of Compound Lab's Timelock.sol (3-Clause BSD Licensed).
/// 
/// The following major changes were made from the original Nouns DAO contract:
/// - `executeTransaction` was changed to only accept calls with the `data`
///   parameter defined as the abi-encoded function calldata with the function 
///   selector included. This differs from the Nouns DAO variant which accepted
///   either the above or `data` as only the abi-encoded function parameters.
/// - An explicit check was added to ensure that the abi-encoded signature in
///   `executeTransaction` matches the function selector provded in calldata.
 
import "../errors.sol";
import {ITimelock} from "../interfaces/ITimelock.sol";

/// @title Timelock Contract & Dopamine DAO Treasury
/// @notice The timelock is an administrative contract responsible for ensuring
///  passed proposals from the DAO have their execution calls succesfully queued
///  with enough time to marinade before execution in case of any issues.
contract Timelock is ITimelock {

    /// @notice Extra time in seconds added to delay before call becomes stale.
	uint256 public constant GRACE_PERIOD = 14 days;

    /// @notice Minimum settable timelock delay, in seconds.
	uint256 public constant MIN_TIMELOCK_DELAY = 2 days;

    /// @notice Maximum settable timelock delay, in seconds.
	uint256 public constant MAX_TIMELOCK_DELAY = 30 days;

    /// @notice The address responsible for configuring the timelock.
	address public admin;

    /// @notice Address of temporary admin that will become admin once accepted.
    address public pendingAdmin;

    /// @notice Time in seconds for how long a call must be queued for.
    uint256 public timelockDelay;

    /// @notice Mapping of execution call hashes to whether they've been queued.
    mapping (bytes32 => bool) public queuedTransactions;

    /// @notice Modifier to restrict calls to admin only.
	modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert AdminOnly();
        }
		_;
	}

    /// @notice Instantiates the timelock contract.
    /// @param admin_ Address of the admin, who controls the timelock.
    /// @param timelockDelay_ Time in seconds for which executions remain queued.
    /// @dev For integration with the DAO, `admin_` should be the DAO address.
    constructor(address admin_, uint256 timelockDelay_) {
        admin = admin_;
        if (
            timelockDelay_ < MIN_TIMELOCK_DELAY || 
            timelockDelay_ > MAX_TIMELOCK_DELAY
        ) 
        {
            revert TimelockDelayInvalid();
        }
        timelockDelay = timelockDelay_;
        emit TimelockDelaySet(timelockDelay);
    }

    /// @notice Allows timelock to receive Ether on calls with empty calldata.
	receive() external payable {}

    /// @notice Allows timelock to receive Ether through the fallback mechanism.
	fallback() external payable {}

    /// @inheritdoc ITimelock
    function queueTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta) public onlyAdmin returns (bytes32) {
        if (eta < block.timestamp + timelockDelay) {
            revert TransactionPremature();
        }
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit TransactionQueued(txHash, target, value, signature, data, eta);
        return txHash;
    }
    
    /// @inheritdoc ITimelock
    function cancelTransaction(address target, uint value, string memory signature, bytes memory data, uint256 eta) public onlyAdmin {
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit TransactionCanceled(txHash, target, value, signature, data, eta);
    }

    /// @inheritdoc ITimelock
    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public onlyAdmin returns (bytes memory) {
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        if (!queuedTransactions[txHash]) {
            revert TransactionNotYetQueued();
        }
        if (block.timestamp < eta) {
            revert TransactionPremature();
        }
        if (block.timestamp > eta + GRACE_PERIOD) {
            revert TransactionStale();
        }
        queuedTransactions[txHash] = false;

        bytes4 selector;
        assembly {
            selector := mload(add(data, 32))
        }
        if (bytes4(keccak256(abi.encodePacked(signature))) != selector) {
            revert SignatureInvalid();
        }
		
		(bool ok, bytes memory returnData) = target.call{ value: value }(data);
        if (!ok) {
            revert TransactionReverted();
        }
		emit TransactionExecuted(txHash, target, value, signature, data, eta);
		return returnData;
    }

    /// @inheritdoc ITimelock
    function setTimelockDelay(uint256 newTimelockDelay) public {
        if (msg.sender != address(this)) {
            revert TimelockOnly();
        }
        if (
            newTimelockDelay < MIN_TIMELOCK_DELAY || 
            newTimelockDelay > MAX_TIMELOCK_DELAY
        ) 
        {
            revert TimelockDelayInvalid();
        }
        timelockDelay = newTimelockDelay;
        emit TimelockDelaySet(timelockDelay);
    }

    /// @inheritdoc ITimelock
	function setPendingAdmin(address newPendingAdmin) public override {
        if (msg.sender != address(this)) {
            revert TimelockOnly();
        }
		pendingAdmin = newPendingAdmin;
		emit PendingAdminSet(pendingAdmin);
	}

    /// @inheritdoc ITimelock
	function acceptAdmin() public override {
        if (msg.sender != pendingAdmin) {
            revert PendingAdminOnly();
        }

		emit AdminChanged(admin, pendingAdmin);
		admin = pendingAdmin;
        pendingAdmin = address(0);
	}


}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

////////////////////////////////////////////////////////////////////////////////
///				 ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

// This file is a shared repository of all errors used in Dopamine's contracts.

////////////////////////////////////////////////////////////////////////////////
///                               DopamintPass                               /// 
////////////////////////////////////////////////////////////////////////////////

/// @notice Configured drop delay is invalid.
error DropDelayInvalid();

/// @notice DopamintPass drop hit allocated capacity.
error DropMaxCapacity();

/// @notice No such drop exists.
error DropNonExistent();

/// @notice Action cannot be completed as a current drop is ongoing.
error DropOngoing();

/// @notice Configured drop size is invalid.
error DropSizeInvalid();

/// @notice Insufficient time passed since last drop was created.
error DropTooEarly();

/// @notice Configured whitelist size is too large.
error DropWhitelistOverCapacity();

////////////////////////////////////////////////////////////////////////////////
///                          Dopamine Auction House                          ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Auction has already been settled.
error AuctionAlreadySettled();

/// @notice The NFT specified in the auction bid is invalid.
error AuctionBidInvalid();

/// @notice Bid placed was too low (see `reservePrice` and `MIN_BID_DIFF`).
error AuctionBidTooLow();

/// @notice Auction duration set is invalid.
error AuctionDurationInvalid();

/// @notice The auction has expired.
error AuctionExpired();

/// @notice Operation cannot be performed as auction is not suspended.
error AuctionNotSuspended();

/// @notice Operation cannot be performed as auction is already suspended.
error AuctionAlreadySuspended();

/// @notice Auction has yet to complete.
error AuctionOngoing();

/// @notice Reserve price set is invalid.
error AuctionReservePriceInvalid();

/// @notice Time buffer set is invalid.
error AuctionTimeBufferInvalid();

/// @notice Treasury split is invalid, must be in range [0, 100].
error AuctionTreasurySplitInvalid();

//////////////////////////////////////////////////////////////////////////////// 
///                              Miscellaneous                               ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Mismatch between input arrays.
error ArityMismatch();

/// @notice Block number being queried is invalid.
error BlockInvalid();

/// @notice Reentrancy vulnerability.
error FunctionReentrant();

/// @notice Number does not fit in 32 bytes.
error Uint32ConversionInvalid();

////////////////////////////////////////////////////////////////////////////////
///                                 Upgrades                                 ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Contract already initialized.
error ContractAlreadyInitialized();

/// @notice Upgrade requires either admin or vetoer privileges.
error UpgradeUnauthorized();

////////////////////////////////////////////////////////////////////////////////
///                                 EIP-712                                  ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Signature has expired and is no longer valid.
error SignatureExpired();

/// @notice Signature invalid.
error SignatureInvalid();

////////////////////////////////////////////////////////////////////////////////
///                                 EIP-721                                  ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Originating address does not own the NFT.
error OwnerInvalid();

/// @notice Receiving address cannot be the zero address.
error ReceiverInvalid();

/// @notice Receiving contract does not implement the ERC721 wallet interface.
error SafeTransferUnsupported();

/// @notice Sender is not NFT owner, approved address, or owner operator.
error SenderUnauthorized();

/// @notice NFT collection has hit maximum supply capacity.
error SupplyMaxCapacity();

/// @notice Token has already minted.
error TokenAlreadyMinted();

/// @notice NFT does not exist.
error TokenNonExistent();

////////////////////////////////////////////////////////////////////////////////
///                              Administrative                              ///
////////////////////////////////////////////////////////////////////////////////
 
/// @notice Function callable only by the admin.
error AdminOnly();

/// @notice Function callable only by the minter.
error MinterOnly();

/// @notice Function callable only by the owner.
error OwnerOnly();

/// @notice Function callable only by the pending owner.
error PendingAdminOnly();

////////////////////////////////////////////////////////////////////////////////
///                                Governance                                ///
//////////////////////////////////////////////////////////////////////////////// 

/// @notice Invalid number of actions proposed.
error ProposalActionCountInvalid();

/// @notice Proposal has already been settled.
error ProposalAlreadySettled();

/// @notice Inactive proposals may not be voted for.
error ProposalInactive();

/// @notice Proposal has failed to or has yet to be queued.
error ProposalNotYetQueued();

/// @notice Quorum threshold is invalid.
error ProposalQuorumThresholdInvalid();

/// @notice Proposal threshold is invalid.
error ProposalThresholdInvalid();

/// @notice Proposal has failed to or has yet to be successful.
error ProposalUnpassed();

/// @notice A proposal is currently running and must be settled first.
error ProposalUnsettled();

/// @notice Voting delay set is invalid.
error ProposalVotingDelayInvalid();

/// @notice Voting period set is invalid.
error ProposalVotingPeriodInvalid();

/// @notice Only the proposer may invoke this action.
error ProposerOnly();

/// @notice Function callable only by the vetoer.
error VetoerOnly();

/// @notice Veto power has been revoked.
error VetoPowerRevoked();

/// @notice Proposal already voted for.
error VoteAlreadyCast();

/// @notice Vote type is not valid.
error VoteInvalid();

/// @notice Voting power insufficient.
error VotingPowerInsufficient();

////////////////////////////////////////////////////////////////////////////////
///                                 Timelock                                 /// 
////////////////////////////////////////////////////////////////////////////////

/// @notice Invalid set timelock delay.
error TimelockDelayInvalid();

/// @notice Function callable only by the timelock itself.
error TimelockOnly();

/// @notice Duplicate transaction queued.
error TransactionAlreadyQueued();

/// @notice Transaction is not yet queued.
error TransactionNotYetQueued();

/// @notice Transaction executed prematurely.
error TransactionPremature();

/// @notice Transaction execution was reverted.
error TransactionReverted();

/// @notice Transaction is stale.
error TransactionStale();

////////////////////////////////////////////////////////////////////////////////
///                             Merkle Whitelist                             /// 
////////////////////////////////////////////////////////////////////////////////

/// @notice Proof for claim is invalid.
error ProofInvalid();

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

////////////////////////////////////////////////////////////////////////////////
///				 ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////
 
import "./ITimelockEvents.sol";

/// @title Timelock Interface
interface ITimelock is ITimelockEvents {

    /// @notice Queues a call for future execution.
    /// @dev This function is only callable by admin, and throws if `eta` is not 
    ///  a timestamp past the current block time plus the timelock delay.
    /// @param target    The address that this call will be targeted to.
    /// @param value     The eth value in wei to send along with the call.
    /// @param signature The signature of the execution call.
    /// @param data      The calldata to be passed with the call.
    /// @param eta       The timestamp at which call is eligible for execution.
    /// @return A bytes32 keccak-256 hash of the abi-encoded parameters.
    function queueTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external returns (bytes32);

    /// @notice Cancels an execution call.
    /// @param target    The address that this call was intended for.
    /// @param value     The eth value in wei that was to be sent with the call.
    /// @param signature The signature of the execution call.
    /// @param data      The calldata originally included with the call.
    /// @param eta       The timestamp at which call was eligible for execution.
    function cancelTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external;

    /// @notice Executes a queued execution call.
    /// @dev The calldata `data` will be verified by ensuring that the passed in
    ///  signature `signaure` matches the function selector included in `data`.
    /// @param target    The address that this call was intended for.
    /// @param value     The eth value in wei that was to be sent with the call.
    /// @param signature The signature of the execution call.
    /// @param data      The calldata originally included with the call.
    /// @param eta       The timestamp at which call was eligible for execution.
    function executeTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external returns (bytes memory);

    /// @notice Returns the grace period, in seconds, representing the time
    ///  added to the timelock delay before a transaction call becomes stale.
    function GRACE_PERIOD() external view returns (uint256);

    /// @notice Returns the timelock delay, in seconds, representing how long
    ///  call must be queued for before being eligible for execution.
    function timelockDelay() external view returns (uint256);

    /// @notice Retrieves a boolean indicating whether a transaction was queued.
    /// @param txHash Bytes32 keccak-256 hash of Abi-encoded call parameters.
    /// @return True if the transaction has been queued, false otherwise.
    function queuedTransactions(bytes32 txHash) external view returns (bool);

    /// @notice Sets the timelock delay to `newTimelockDelay`.
    /// @dev This function is only callable by the admin, and throws if the 
    ///  timelock delay is too low or too high.
    /// @param newTimelockDelay The new timelock delay to set, in seconds.
    function setTimelockDelay(uint256 newTimelockDelay) external;

    /// @notice Sets the pending admin address to  `newPendingAdmin`.
    /// @param newPendingAdmin The address of the new pending admin.
    function setPendingAdmin(address newPendingAdmin) external;

    /// @notice Assigns the `pendingAdmin` address to the `admin` address.
    /// @dev This function is only callable by the pending admin.
    function acceptAdmin() external;

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

////////////////////////////////////////////////////////////////////////////////
///				 ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////
 
/// @title Timelock Events Interface
interface ITimelockEvents {

    /// @notice Emits when a new transaction execution call is queued.
    /// @param txHash    Sha-256 hash of abi-encoded execution call parameters.
    /// @param target    Target addresses of the call to be queued.
    /// @param value     Amount (in wei) to send with the queued transaction.
    /// @param signature The function signature of the queued transaction.
    /// @param data      Calldata to be passed with the queued transaction call.
    /// @param eta       Timestamp at which call is eligible for execution. 
	event TransactionQueued(
		bytes32 indexed txHash,
		address indexed target,
		uint256 value,
		string signature,
		bytes data,
		uint256 eta
	);

    /// @notice Emits when a new transaction execution call is canceled.
    /// @param txHash    Sha-256 hash of abi-encoded execution call parameters.
    /// @param target    Target addresses of the canceled call.
    /// @param value     Amount (in wei) that was supposed to be sent with call.
    /// @param signature The function signature of the canceled transaction.
    /// @param data      Calldata that was supposed to be sent with the call.
    /// @param eta       Timestamp at which call was eligible for execution. 
	event TransactionCanceled(
		bytes32 indexed txHash,
		address indexed target,
		uint256 value,
		string signature,
		bytes data,
		uint256 eta
	);

    /// @notice Emits when a new transaction execution call is executed.
    /// @param txHash    Sha-256 hash of abi-encoded execution call parameters.
    /// @param target    Target addresses of the executed call.
    /// @param value     Amount (in wei) that was sent with the transaction.
    /// @param signature The function signature of the executed transaction.
    /// @param data      Calldata that was passed to the executed transaction.
    /// @param eta       Timestamp at which call became eligible for execution. 
	event TransactionExecuted(
		bytes32 indexed txHash,
		address indexed target,
		uint256 value,
		string signature,
		bytes data,
		uint256 eta
	);

    /// @notice Emits when admin is changed from `oldAdmin` to `newAdmin`.
    /// @param oldAdmin The address of the previous admin.
    /// @param newAdmin The address of the new admin.
    event AdminChanged(address oldAdmin, address newAdmin);

    /// @notice Emits when a new pending admin `pendingAdmin` is set.
    /// @param pendingAdmin The address of the pending admin set.
    event PendingAdminSet(address pendingAdmin);

    /// @notice Emits when a new timelock delay `timelockDelay` is set.
    /// @param timelockDelay The new timelock delay to set, in blocks.
	event TimelockDelaySet(uint256 timelockDelay);

}