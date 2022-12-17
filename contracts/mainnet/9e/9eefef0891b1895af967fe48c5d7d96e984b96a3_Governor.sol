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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

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
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

abstract contract VersionedContract {
    function contractVersion() external pure returns (string memory) {
        return "1.1.0";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IUUPS } from "../lib/interfaces/IUUPS.sol";
import { IOwnable } from "../lib/interfaces/IOwnable.sol";
import { IPausable } from "../lib/interfaces/IPausable.sol";

/// @title IAuction
/// @author Rohan Kulkarni
/// @notice The external Auction events, errors, and functions
interface IAuction is IUUPS, IOwnable, IPausable {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when a bid is placed
    /// @param tokenId The ERC-721 token id
    /// @param bidder The address of the bidder
    /// @param amount The amount of ETH
    /// @param extended If the bid extended the auction
    /// @param endTime The end time of the auction
    event AuctionBid(uint256 tokenId, address bidder, uint256 amount, bool extended, uint256 endTime);

    /// @notice Emitted when an auction is settled
    /// @param tokenId The ERC-721 token id of the settled auction
    /// @param winner The address of the winning bidder
    /// @param amount The amount of ETH raised from the winning bid
    event AuctionSettled(uint256 tokenId, address winner, uint256 amount);

    /// @notice Emitted when an auction is created
    /// @param tokenId The ERC-721 token id of the created auction
    /// @param startTime The start time of the created auction
    /// @param endTime The end time of the created auction
    event AuctionCreated(uint256 tokenId, uint256 startTime, uint256 endTime);

    /// @notice Emitted when the auction duration is updated
    /// @param duration The new auction duration
    event DurationUpdated(uint256 duration);

    /// @notice Emitted when the reserve price is updated
    /// @param reservePrice The new reserve price
    event ReservePriceUpdated(uint256 reservePrice);

    /// @notice Emitted when the min bid increment percentage is updated
    /// @param minBidIncrementPercentage The new min bid increment percentage
    event MinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    /// @notice Emitted when the time buffer is updated
    /// @param timeBuffer The new time buffer
    event TimeBufferUpdated(uint256 timeBuffer);

    ///                                                          ///
    ///                           ERRORS                         ///
    ///                                                          ///

    /// @dev Reverts if a bid is placed for the wrong token
    error INVALID_TOKEN_ID();

    /// @dev Reverts if a bid is placed for an auction thats over
    error AUCTION_OVER();

    /// @dev Reverts if a bid is placed for an auction that hasn't started
    error AUCTION_NOT_STARTED();

    /// @dev Reverts if attempting to settle an active auction
    error AUCTION_ACTIVE();

    /// @dev Reverts if attempting to settle an auction that was already settled
    error AUCTION_SETTLED();

    /// @dev Reverts if a bid does not meet the reserve price
    error RESERVE_PRICE_NOT_MET();

    /// @dev Reverts if a bid does not meet the minimum bid
    error MINIMUM_BID_NOT_MET();

    /// @dev Error for when the bid increment is set to 0.
    error MIN_BID_INCREMENT_1_PERCENT();

    /// @dev Reverts if the contract does not have enough ETH
    error INSOLVENT();

    /// @dev Reverts if the caller was not the contract manager
    error ONLY_MANAGER();

    /// @dev Thrown if the WETH contract throws a failure on transfer
    error FAILING_WETH_TRANSFER();

    /// @dev Thrown if the auction creation failed
    error AUCTION_CREATE_FAILED_TO_LAUNCH();

    ///                                                          ///
    ///                          FUNCTIONS                       ///
    ///                                                          ///

    /// @notice Initializes a DAO's auction house
    /// @param token The ERC-721 token address
    /// @param founder The founder responsible for starting the first auction
    /// @param treasury The treasury address where ETH will be sent
    /// @param duration The duration of each auction
    /// @param reservePrice The reserve price of each auction
    function initialize(
        address token,
        address founder,
        address treasury,
        uint256 duration,
        uint256 reservePrice
    ) external;

    /// @notice Creates a bid for the current token
    /// @param tokenId The ERC-721 token id
    function createBid(uint256 tokenId) external payable;

    /// @notice Settles the current auction and creates the next one
    function settleCurrentAndCreateNewAuction() external;

    /// @notice Settles the latest auction when the contract is paused
    function settleAuction() external;

    /// @notice Pauses the auction house
    function pause() external;

    /// @notice Unpauses the auction house
    function unpause() external;

    /// @notice The time duration of each auction
    function duration() external view returns (uint256);

    /// @notice The reserve price of each auction
    function reservePrice() external view returns (uint256);

    /// @notice The minimum amount of time to place a bid during an active auction
    function timeBuffer() external view returns (uint256);

    /// @notice The minimum percentage an incoming bid must raise the highest bid
    function minBidIncrement() external view returns (uint256);

    /// @notice Updates the time duration of each auction
    /// @param duration The new time duration
    function setDuration(uint256 duration) external;

    /// @notice Updates the reserve price of each auction
    /// @param reservePrice The new reserve price
    function setReservePrice(uint256 reservePrice) external;

    /// @notice Updates the time buffer of each auction
    /// @param timeBuffer The new time buffer
    function setTimeBuffer(uint256 timeBuffer) external;

    /// @notice Updates the minimum bid increment of each subsequent bid
    /// @param percentage The new percentage
    function setMinimumBidIncrement(uint256 percentage) external;

    /// @notice Get the address of the treasury
    function treasury() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { UUPS } from "../../lib/proxy/UUPS.sol";
import { Ownable } from "../../lib/utils/Ownable.sol";
import { EIP712 } from "../../lib/utils/EIP712.sol";
import { SafeCast } from "../../lib/utils/SafeCast.sol";

import { GovernorStorageV1 } from "./storage/GovernorStorageV1.sol";
import { Token } from "../../token/Token.sol";
import { Treasury } from "../treasury/Treasury.sol";
import { IManager } from "../../manager/IManager.sol";
import { IGovernor } from "./IGovernor.sol";
import { ProposalHasher } from "./ProposalHasher.sol";
import { VersionedContract } from "../../VersionedContract.sol";

/// @title Governor
/// @author Rohan Kulkarni
/// @notice A DAO's proposal manager and transaction scheduler
/// @custom:repo github.com/ourzora/nouns-protocol 
/// Modified from:
/// - OpenZeppelin Contracts v4.7.3 (governance/extensions/GovernorTimelockControl.sol)
/// - NounsDAOLogicV1.sol commit 2cbe6c7 - licensed under the BSD-3-Clause license.
contract Governor is IGovernor, VersionedContract, UUPS, Ownable, EIP712, ProposalHasher, GovernorStorageV1 {
    ///                                                          ///
    ///                         IMMUTABLES                       ///
    ///                                                          ///

    /// @notice The EIP-712 typehash to vote with a signature
    bytes32 public immutable VOTE_TYPEHASH = keccak256("Vote(address voter,uint256 proposalId,uint256 support,uint256 nonce,uint256 deadline)");

    /// @notice The minimum proposal threshold bps setting
    uint256 public immutable MIN_PROPOSAL_THRESHOLD_BPS = 1;

    /// @notice The maximum proposal threshold bps setting
    uint256 public immutable MAX_PROPOSAL_THRESHOLD_BPS = 1000;

    /// @notice The minimum quorum threshold bps setting
    uint256 public immutable MIN_QUORUM_THRESHOLD_BPS = 200;

    /// @notice The maximum quorum threshold bps setting
    uint256 public immutable MAX_QUORUM_THRESHOLD_BPS = 2000;

    /// @notice The minimum voting delay setting
    uint256 public immutable MIN_VOTING_DELAY = 1 seconds;

    /// @notice The maximum voting delay setting
    uint256 public immutable MAX_VOTING_DELAY = 24 weeks;

    /// @notice The minimum voting period setting
    uint256 public immutable MIN_VOTING_PERIOD = 10 minutes;

    /// @notice The maximum voting period setting
    uint256 public immutable MAX_VOTING_PERIOD = 24 weeks;

    /// @notice The basis points for 100%
    uint256 private immutable BPS_PER_100_PERCENT = 10_000;

    /// @notice The contract upgrade manager
    IManager private immutable manager;

    ///                                                          ///
    ///                         CONSTRUCTOR                      ///
    ///                                                          ///

    /// @param _manager The contract upgrade manager address
    constructor(address _manager) payable initializer {
        manager = IManager(_manager);
    }

    ///                                                          ///
    ///                         INITIALIZER                      ///
    ///                                                          ///

    /// @notice Initializes a DAO's governor
    /// @param _treasury The DAO's treasury address
    /// @param _token The DAO's governance token address
    /// @param _vetoer The address eligible to veto proposals
    /// @param _votingDelay The voting delay
    /// @param _votingPeriod The voting period
    /// @param _proposalThresholdBps The proposal threshold basis points
    /// @param _quorumThresholdBps The quorum threshold basis points
    function initialize(
        address _treasury,
        address _token,
        address _vetoer,
        uint256 _votingDelay,
        uint256 _votingPeriod,
        uint256 _proposalThresholdBps,
        uint256 _quorumThresholdBps
    ) external initializer {
        // Ensure the caller is the contract manager
        if (msg.sender != address(manager)) revert ONLY_MANAGER();

        // Ensure non-zero addresses are provided
        if (_treasury == address(0)) revert ADDRESS_ZERO();
        if (_token == address(0)) revert ADDRESS_ZERO();

        // If a vetoer is specified, store its address
        if (_vetoer != address(0)) settings.vetoer = _vetoer;

        // Ensure the specified governance settings are valid
        if (_proposalThresholdBps < MIN_PROPOSAL_THRESHOLD_BPS || _proposalThresholdBps > MAX_PROPOSAL_THRESHOLD_BPS)
            revert INVALID_PROPOSAL_THRESHOLD_BPS();
        if (_quorumThresholdBps < MIN_QUORUM_THRESHOLD_BPS || _quorumThresholdBps > MAX_QUORUM_THRESHOLD_BPS) revert INVALID_QUORUM_THRESHOLD_BPS();
        if (_proposalThresholdBps >= _quorumThresholdBps) revert INVALID_PROPOSAL_THRESHOLD_BPS();
        if (_votingDelay < MIN_VOTING_DELAY || _votingDelay > MAX_VOTING_DELAY) revert INVALID_VOTING_DELAY();
        if (_votingPeriod < MIN_VOTING_PERIOD || _votingPeriod > MAX_VOTING_PERIOD) revert INVALID_VOTING_PERIOD();

        // Store the governor settings
        settings.treasury = Treasury(payable(_treasury));
        settings.token = Token(_token);
        settings.votingDelay = SafeCast.toUint48(_votingDelay);
        settings.votingPeriod = SafeCast.toUint48(_votingPeriod);
        settings.proposalThresholdBps = SafeCast.toUint16(_proposalThresholdBps);
        settings.quorumThresholdBps = SafeCast.toUint16(_quorumThresholdBps);

        // Initialize EIP-712 support
        __EIP712_init(string.concat(settings.token.symbol(), " GOV"), "1");

        // Grant ownership to the treasury
        __Ownable_init(_treasury);
    }

    ///                                                          ///
    ///                        CREATE PROPOSAL                   ///
    ///                                                          ///

    /// @notice Creates a proposal
    /// @param _targets The target addresses to call
    /// @param _values The ETH values of each call
    /// @param _calldatas The calldata of each call
    /// @param _description The proposal description
    function propose(
        address[] memory _targets,
        uint256[] memory _values,
        bytes[] memory _calldatas,
        string memory _description
    ) external returns (bytes32) {
        // Get the current proposal threshold
        uint256 currentProposalThreshold = proposalThreshold();

        // Cannot realistically underflow and `getVotes` would revert
        unchecked {
            // Ensure the caller's voting weight is greater than or equal to the threshold
            if (getVotes(msg.sender, block.timestamp - 1) <= proposalThreshold()) {
                revert BELOW_PROPOSAL_THRESHOLD();
            }
        }

        // Cache the number of targets
        uint256 numTargets = _targets.length;

        // Ensure at least one target exists
        if (numTargets == 0) revert PROPOSAL_TARGET_MISSING();

        // Ensure the number of targets matches the number of values and calldata
        if (numTargets != _values.length) revert PROPOSAL_LENGTH_MISMATCH();
        if (numTargets != _calldatas.length) revert PROPOSAL_LENGTH_MISMATCH();

        // Compute the description hash
        bytes32 descriptionHash = keccak256(bytes(_description));

        // Compute the proposal id
        bytes32 proposalId = hashProposal(_targets, _values, _calldatas, descriptionHash, msg.sender);

        // Get the pointer to store the proposal
        Proposal storage proposal = proposals[proposalId];

        // Ensure the proposal doesn't already exist
        if (proposal.voteStart != 0) revert PROPOSAL_EXISTS(proposalId);

        // Used to store the snapshot and deadline
        uint256 snapshot;
        uint256 deadline;

        // Cannot realistically overflow
        unchecked {
            // Compute the snapshot and deadline
            snapshot = block.timestamp + settings.votingDelay;
            deadline = snapshot + settings.votingPeriod;
        }

        // Store the proposal data
        proposal.voteStart = SafeCast.toUint32(snapshot);
        proposal.voteEnd = SafeCast.toUint32(deadline);
        proposal.proposalThreshold = SafeCast.toUint32(currentProposalThreshold);
        proposal.quorumVotes = SafeCast.toUint32(quorum());
        proposal.proposer = msg.sender;
        proposal.timeCreated = SafeCast.toUint32(block.timestamp);

        emit ProposalCreated(proposalId, _targets, _values, _calldatas, _description, descriptionHash, proposal);

        return proposalId;
    }

    ///                                                          ///
    ///                          CAST VOTE                       ///
    ///                                                          ///

    /// @notice Casts a vote
    /// @param _proposalId The proposal id
    /// @param _support The support value (0 = Against, 1 = For, 2 = Abstain)
    function castVote(bytes32 _proposalId, uint256 _support) external returns (uint256) {
        return _castVote(_proposalId, msg.sender, _support, "");
    }

    /// @notice Casts a vote with a reason
    /// @param _proposalId The proposal id
    /// @param _support The support value (0 = Against, 1 = For, 2 = Abstain)
    /// @param _reason The vote reason
    function castVoteWithReason(
        bytes32 _proposalId,
        uint256 _support,
        string memory _reason
    ) external returns (uint256) {
        return _castVote(_proposalId, msg.sender, _support, _reason);
    }

    /// @notice Casts a signed vote
    /// @param _voter The voter address
    /// @param _proposalId The proposal id
    /// @param _support The support value (0 = Against, 1 = For, 2 = Abstain)
    /// @param _deadline The signature deadline
    /// @param _v The 129th byte and chain id of the signature
    /// @param _r The first 64 bytes of the signature
    /// @param _s Bytes 64-128 of the signature
    function castVoteBySig(
        address _voter,
        bytes32 _proposalId,
        uint256 _support,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (uint256) {
        // Ensure the deadline has not passed
        if (block.timestamp > _deadline) revert EXPIRED_SIGNATURE();

        // Used to store the signed digest
        bytes32 digest;

        // Cannot realistically overflow
        unchecked {
            // Compute the message
            digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(VOTE_TYPEHASH, _voter, _proposalId, _support, nonces[_voter]++, _deadline))
                )
            );
        }

        // Recover the message signer
        address recoveredAddress = ecrecover(digest, _v, _r, _s);

        // Ensure the recovered signer is the given voter
        if (recoveredAddress == address(0) || recoveredAddress != _voter) revert INVALID_SIGNATURE();

        return _castVote(_proposalId, _voter, _support, "");
    }

    /// @dev Stores a vote
    /// @param _proposalId The proposal id
    /// @param _voter The voter address
    /// @param _support The vote choice
    function _castVote(
        bytes32 _proposalId,
        address _voter,
        uint256 _support,
        string memory _reason
    ) internal returns (uint256) {
        // Ensure voting is active
        if (state(_proposalId) != ProposalState.Active) revert VOTING_NOT_STARTED();

        // Ensure the voter hasn't already voted
        if (hasVoted[_proposalId][_voter]) revert ALREADY_VOTED();

        // Ensure the vote is valid
        if (_support > 2) revert INVALID_VOTE();

        // Record the voter as having voted
        hasVoted[_proposalId][_voter] = true;

        // Get the pointer to the proposal
        Proposal storage proposal = proposals[_proposalId];

        // Used to store the voter's weight
        uint256 weight;

        // Cannot realistically underflow and `getVotes` would revert
        unchecked {
            // Get the voter's weight at the time the proposal was created
            weight = getVotes(_voter, proposal.timeCreated);

            // If the vote is against:
            if (_support == 0) {
                // Update the total number of votes against
                proposal.againstVotes += SafeCast.toUint32(weight);

                // Else if the vote is for:
            } else if (_support == 1) {
                // Update the total number of votes for
                proposal.forVotes += SafeCast.toUint32(weight);

                // Else if the vote is to abstain:
            } else if (_support == 2) {
                // Update the total number of votes abstaining
                proposal.abstainVotes += SafeCast.toUint32(weight);
            }
        }

        emit VoteCast(_voter, _proposalId, _support, weight, _reason);

        return weight;
    }

    ///                                                          ///
    ///                        QUEUE PROPOSAL                    ///
    ///                                                          ///

    /// @notice Queues a proposal
    /// @param _proposalId The proposal id
    function queue(bytes32 _proposalId) external returns (uint256 eta) {
        // Ensure the proposal has succeeded
        if (state(_proposalId) != ProposalState.Succeeded) revert PROPOSAL_UNSUCCESSFUL();

        // Schedule the proposal for execution
        eta = settings.treasury.queue(_proposalId);

        emit ProposalQueued(_proposalId, eta);
    }

    ///                                                          ///
    ///                       EXECUTE PROPOSAL                   ///
    ///                                                          ///

    /// @notice Executes a proposal
    /// @param _targets The target addresses to call
    /// @param _values The ETH values of each call
    /// @param _calldatas The calldata of each call
    /// @param _descriptionHash The hash of the description
    /// @param _proposer The proposal creator
    function execute(
        address[] calldata _targets,
        uint256[] calldata _values,
        bytes[] calldata _calldatas,
        bytes32 _descriptionHash,
        address _proposer
    ) external payable returns (bytes32) {
        // Get the proposal id
        bytes32 proposalId = hashProposal(_targets, _values, _calldatas, _descriptionHash, _proposer);

        // Ensure the proposal is queued
        if (state(proposalId) != ProposalState.Queued) revert PROPOSAL_NOT_QUEUED(proposalId);

        // Mark the proposal as executed
        proposals[proposalId].executed = true;

        // Execute the proposal
        settings.treasury.execute{ value: msg.value }(_targets, _values, _calldatas, _descriptionHash, _proposer);

        emit ProposalExecuted(proposalId);

        return proposalId;
    }

    ///                                                          ///
    ///                        CANCEL PROPOSAL                   ///
    ///                                                          ///

    /// @notice Cancels a proposal
    /// @param _proposalId The proposal id
    function cancel(bytes32 _proposalId) external {
        // Ensure the proposal hasn't been executed
        if (state(_proposalId) == ProposalState.Executed) revert PROPOSAL_ALREADY_EXECUTED();

        // Get a copy of the proposal
        Proposal memory proposal = proposals[_proposalId];

        // Cannot realistically underflow and `getVotes` would revert
        unchecked {
            // Ensure the caller is the proposer or the proposer's voting weight has dropped below the proposal threshold
            if (msg.sender != proposal.proposer && getVotes(proposal.proposer, block.timestamp - 1) >= proposal.proposalThreshold)
                revert INVALID_CANCEL();
        }

        // Update the proposal as canceled
        proposals[_proposalId].canceled = true;

        // If the proposal was queued:
        if (settings.treasury.isQueued(_proposalId)) {
            // Cancel the proposal
            settings.treasury.cancel(_proposalId);
        }

        emit ProposalCanceled(_proposalId);
    }

    ///                                                          ///
    ///                        VETO PROPOSAL                     ///
    ///                                                          ///

    /// @notice Vetoes a proposal
    /// @param _proposalId The proposal id
    function veto(bytes32 _proposalId) external {
        // Ensure the caller is the vetoer
        if (msg.sender != settings.vetoer) revert ONLY_VETOER();

        // Ensure the proposal has not been executed
        if (state(_proposalId) == ProposalState.Executed) revert PROPOSAL_ALREADY_EXECUTED();

        // Get the pointer to the proposal
        Proposal storage proposal = proposals[_proposalId];

        // Update the proposal as vetoed
        proposal.vetoed = true;

        // If the proposal was queued:
        if (settings.treasury.isQueued(_proposalId)) {
            // Cancel the proposal
            settings.treasury.cancel(_proposalId);
        }

        emit ProposalVetoed(_proposalId);
    }

    ///                                                          ///
    ///                        PROPOSAL STATE                    ///
    ///                                                          ///

    /// @notice The state of a proposal
    /// @param _proposalId The proposal id
    function state(bytes32 _proposalId) public view returns (ProposalState) {
        // Get a copy of the proposal
        Proposal memory proposal = proposals[_proposalId];

        // Ensure the proposal exists
        if (proposal.voteStart == 0) revert PROPOSAL_DOES_NOT_EXIST();

        // If the proposal was executed:
        if (proposal.executed) {
            return ProposalState.Executed;

            // Else if the proposal was canceled:
        } else if (proposal.canceled) {
            return ProposalState.Canceled;

            // Else if the proposal was vetoed:
        } else if (proposal.vetoed) {
            return ProposalState.Vetoed;

            // Else if voting has not started:
        } else if (block.timestamp < proposal.voteStart) {
            return ProposalState.Pending;

            // Else if voting has not ended:
        } else if (block.timestamp < proposal.voteEnd) {
            return ProposalState.Active;

            // Else if the proposal failed (outvoted OR didn't reach quorum):
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < proposal.quorumVotes) {
            return ProposalState.Defeated;

            // Else if the proposal has not been queued:
        } else if (settings.treasury.timestamp(_proposalId) == 0) {
            return ProposalState.Succeeded;

            // Else if the proposal can no longer be executed:
        } else if (settings.treasury.isExpired(_proposalId)) {
            return ProposalState.Expired;

            // Else the proposal is queued
        } else {
            return ProposalState.Queued;
        }
    }

    /// @notice The voting weight of an account at a timestamp
    /// @param _account The account address
    /// @param _timestamp The specific timestamp
    function getVotes(address _account, uint256 _timestamp) public view returns (uint256) {
        return settings.token.getPastVotes(_account, _timestamp);
    }

    /// @notice The current number of votes required to submit a proposal
    function proposalThreshold() public view returns (uint256) {
        unchecked {
            return (settings.token.totalSupply() * settings.proposalThresholdBps) / BPS_PER_100_PERCENT;
        }
    }

    /// @notice The current number of votes required to be in favor of a proposal in order to reach quorum
    function quorum() public view returns (uint256) {
        unchecked {
            return (settings.token.totalSupply() * settings.quorumThresholdBps) / BPS_PER_100_PERCENT;
        }
    }

    /// @notice The data stored for a given proposal
    /// @param _proposalId The proposal id
    function getProposal(bytes32 _proposalId) external view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @notice The timestamp when voting starts for a proposal
    /// @param _proposalId The proposal id
    function proposalSnapshot(bytes32 _proposalId) external view returns (uint256) {
        return proposals[_proposalId].voteStart;
    }

    /// @notice The timestamp when voting ends for a proposal
    /// @param _proposalId The proposal id
    function proposalDeadline(bytes32 _proposalId) external view returns (uint256) {
        return proposals[_proposalId].voteEnd;
    }

    /// @notice The vote counts for a proposal
    /// @param _proposalId The proposal id
    function proposalVotes(bytes32 _proposalId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        Proposal memory proposal = proposals[_proposalId];

        return (proposal.againstVotes, proposal.forVotes, proposal.abstainVotes);
    }

    /// @notice The timestamp valid to execute a proposal
    /// @param _proposalId The proposal id
    function proposalEta(bytes32 _proposalId) external view returns (uint256) {
        return settings.treasury.timestamp(_proposalId);
    }

    ///                                                          ///
    ///                      GOVERNOR SETTINGS                   ///
    ///                                                          ///

    /// @notice The basis points of the token supply required to create a proposal
    function proposalThresholdBps() external view returns (uint256) {
        return settings.proposalThresholdBps;
    }

    /// @notice The basis points of the token supply required to reach quorum
    function quorumThresholdBps() external view returns (uint256) {
        return settings.quorumThresholdBps;
    }

    /// @notice The amount of time until voting begins after a proposal is created
    function votingDelay() external view returns (uint256) {
        return settings.votingDelay;
    }

    /// @notice The amount of time to vote on a proposal
    function votingPeriod() external view returns (uint256) {
        return settings.votingPeriod;
    }

    /// @notice The address eligible to veto any proposal (address(0) if burned)
    function vetoer() external view returns (address) {
        return settings.vetoer;
    }

    /// @notice The address of the governance token
    function token() external view returns (address) {
        return address(settings.token);
    }

    /// @notice The address of the treasury
    function treasury() external view returns (address) {
        return address(settings.treasury);
    }

    ///                                                          ///
    ///                       UPDATE SETTINGS                    ///
    ///                                                          ///

    /// @notice Updates the voting delay
    /// @param _newVotingDelay The new voting delay
    function updateVotingDelay(uint256 _newVotingDelay) external onlyOwner {
        if (_newVotingDelay < MIN_VOTING_DELAY || _newVotingDelay > MAX_VOTING_DELAY) revert INVALID_VOTING_DELAY();

        emit VotingDelayUpdated(settings.votingDelay, _newVotingDelay);

        settings.votingDelay = uint48(_newVotingDelay);
    }

    /// @notice Updates the voting period
    /// @param _newVotingPeriod The new voting period
    function updateVotingPeriod(uint256 _newVotingPeriod) external onlyOwner {
        if (_newVotingPeriod < MIN_VOTING_PERIOD || _newVotingPeriod > MAX_VOTING_PERIOD) revert INVALID_VOTING_PERIOD();

        emit VotingPeriodUpdated(settings.votingPeriod, _newVotingPeriod);

        settings.votingPeriod = uint48(_newVotingPeriod);
    }

    /// @notice Updates the minimum proposal threshold
    /// @param _newProposalThresholdBps The new proposal threshold basis points
    function updateProposalThresholdBps(uint256 _newProposalThresholdBps) external onlyOwner {
        if (
            _newProposalThresholdBps < MIN_PROPOSAL_THRESHOLD_BPS ||
            _newProposalThresholdBps > MAX_PROPOSAL_THRESHOLD_BPS ||
            _newProposalThresholdBps >= settings.quorumThresholdBps
        ) revert INVALID_PROPOSAL_THRESHOLD_BPS();

        emit ProposalThresholdBpsUpdated(settings.proposalThresholdBps, _newProposalThresholdBps);

        settings.proposalThresholdBps = uint16(_newProposalThresholdBps);
    }

    /// @notice Updates the minimum quorum threshold
    /// @param _newQuorumVotesBps The new quorum votes basis points
    function updateQuorumThresholdBps(uint256 _newQuorumVotesBps) external onlyOwner {
        if (
            _newQuorumVotesBps < MIN_QUORUM_THRESHOLD_BPS ||
            _newQuorumVotesBps > MAX_QUORUM_THRESHOLD_BPS ||
            settings.proposalThresholdBps >= _newQuorumVotesBps
        ) revert INVALID_QUORUM_THRESHOLD_BPS();

        emit QuorumVotesBpsUpdated(settings.quorumThresholdBps, _newQuorumVotesBps);

        settings.quorumThresholdBps = uint16(_newQuorumVotesBps);
    }

    /// @notice Updates the vetoer
    /// @param _newVetoer The new vetoer address
    function updateVetoer(address _newVetoer) external onlyOwner {
        if (_newVetoer == address(0)) revert ADDRESS_ZERO();

        emit VetoerUpdated(settings.vetoer, _newVetoer);

        settings.vetoer = _newVetoer;
    }

    /// @notice Burns the vetoer
    function burnVetoer() external onlyOwner {
        emit VetoerUpdated(settings.vetoer, address(0));

        delete settings.vetoer;
    }

    ///                                                          ///
    ///                       GOVERNOR UPGRADE                   ///
    ///                                                          ///

    /// @notice Ensures the caller is authorized to upgrade the contract and that the new implementation is valid
    /// @dev This function is called in `upgradeTo` & `upgradeToAndCall`
    /// @param _newImpl The new implementation address
    function _authorizeUpgrade(address _newImpl) internal view override onlyOwner {
        // Ensure the new implementation is a registered upgrade
        if (!manager.isRegisteredUpgrade(_getImplementation(), _newImpl)) revert INVALID_UPGRADE(_newImpl);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IUUPS } from "../../lib/interfaces/IUUPS.sol";
import { IOwnable } from "../../lib/utils/Ownable.sol";
import { IEIP712 } from "../../lib/utils/EIP712.sol";
import { GovernorTypesV1 } from "./types/GovernorTypesV1.sol";
import { IManager } from "../../manager/IManager.sol";

/// @title IGovernor
/// @author Rohan Kulkarni
/// @notice The external Governor events, errors and functions
interface IGovernor is IUUPS, IOwnable, IEIP712, GovernorTypesV1 {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when a proposal is created
    event ProposalCreated(
        bytes32 proposalId,
        address[] targets,
        uint256[] values,
        bytes[] calldatas,
        string description,
        bytes32 descriptionHash,
        Proposal proposal
    );

    /// @notice Emitted when a proposal is queued
    event ProposalQueued(bytes32 proposalId, uint256 eta);

    /// @notice Emitted when a proposal is executed
    /// @param proposalId The proposal id
    event ProposalExecuted(bytes32 proposalId);

    /// @notice Emitted when a proposal is canceled
    event ProposalCanceled(bytes32 proposalId);

    /// @notice Emitted when a proposal is vetoed
    event ProposalVetoed(bytes32 proposalId);

    /// @notice Emitted when a vote is casted for a proposal
    event VoteCast(address voter, bytes32 proposalId, uint256 support, uint256 weight, string reason);

    /// @notice Emitted when the governor's voting delay is updated
    event VotingDelayUpdated(uint256 prevVotingDelay, uint256 newVotingDelay);

    /// @notice Emitted when the governor's voting period is updated
    event VotingPeriodUpdated(uint256 prevVotingPeriod, uint256 newVotingPeriod);

    /// @notice Emitted when the basis points of the governor's proposal threshold is updated
    event ProposalThresholdBpsUpdated(uint256 prevBps, uint256 newBps);

    /// @notice Emitted when the basis points of the governor's quorum votes is updated
    event QuorumVotesBpsUpdated(uint256 prevBps, uint256 newBps);

    //// @notice Emitted when the governor's vetoer is updated
    event VetoerUpdated(address prevVetoer, address newVetoer);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    error INVALID_PROPOSAL_THRESHOLD_BPS();

    error INVALID_QUORUM_THRESHOLD_BPS();

    error INVALID_VOTING_DELAY();

    error INVALID_VOTING_PERIOD();

    /// @dev Reverts if a proposal already exists
    /// @param proposalId The proposal id
    error PROPOSAL_EXISTS(bytes32 proposalId);

    /// @dev Reverts if a proposal isn't queued
    /// @param proposalId The proposal id
    error PROPOSAL_NOT_QUEUED(bytes32 proposalId);

    /// @dev Reverts if the proposer didn't specify a target address
    error PROPOSAL_TARGET_MISSING();

    /// @dev Reverts if the number of targets, values, and calldatas does not match
    error PROPOSAL_LENGTH_MISMATCH();

    /// @dev Reverts if a proposal didn't succeed
    error PROPOSAL_UNSUCCESSFUL();

    /// @dev Reverts if a proposal was already executed
    error PROPOSAL_ALREADY_EXECUTED();

    /// @dev Reverts if a specified proposal doesn't exist
    error PROPOSAL_DOES_NOT_EXIST();

    /// @dev Reverts if the proposer's voting weight is below the proposal threshold
    error BELOW_PROPOSAL_THRESHOLD();

    /// @dev Reverts if a vote was prematurely casted
    error VOTING_NOT_STARTED();

    /// @dev Reverts if the caller wasn't the vetoer
    error ONLY_VETOER();

    /// @dev Reverts if the caller already voted
    error ALREADY_VOTED();

    /// @dev Reverts if a proposal was attempted to be canceled incorrectly
    error INVALID_CANCEL();

    /// @dev Reverts if a vote was attempted to be casted incorrectly
    error INVALID_VOTE();

    /// @dev Reverts if the caller was not the contract manager
    error ONLY_MANAGER();

    ///                                                          ///
    ///                          FUNCTIONS                       ///
    ///                                                          ///

    /// @notice Initializes a DAO's governor
    /// @param treasury The DAO's treasury address
    /// @param token The DAO's governance token address
    /// @param vetoer The address eligible to veto proposals
    /// @param votingDelay The voting delay
    /// @param votingPeriod The voting period
    /// @param proposalThresholdBps The proposal threshold basis points
    /// @param quorumThresholdBps The quorum threshold basis points
    function initialize(
        address treasury,
        address token,
        address vetoer,
        uint256 votingDelay,
        uint256 votingPeriod,
        uint256 proposalThresholdBps,
        uint256 quorumThresholdBps
    ) external;

    /// @notice Creates a proposal
    /// @param targets The target addresses to call
    /// @param values The ETH values of each call
    /// @param calldatas The calldata of each call
    /// @param description The proposal description
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external returns (bytes32);

    /// @notice Casts a vote
    /// @param proposalId The proposal id
    /// @param support The support value (0 = Against, 1 = For, 2 = Abstain)
    function castVote(bytes32 proposalId, uint256 support) external returns (uint256);

    /// @notice Casts a vote with a reason
    /// @param proposalId The proposal id
    /// @param support The support value (0 = Against, 1 = For, 2 = Abstain)
    /// @param reason The vote reason
    function castVoteWithReason(
        bytes32 proposalId,
        uint256 support,
        string memory reason
    ) external returns (uint256);

    /// @notice Casts a signed vote
    /// @param voter The voter address
    /// @param proposalId The proposal id
    /// @param support The support value (0 = Against, 1 = For, 2 = Abstain)
    /// @param deadline The signature deadline
    /// @param v The 129th byte and chain id of the signature
    /// @param r The first 64 bytes of the signature
    /// @param s Bytes 64-128 of the signature
    function castVoteBySig(
        address voter,
        bytes32 proposalId,
        uint256 support,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256);

    /// @notice Queues a proposal
    /// @param proposalId The proposal id
    function queue(bytes32 proposalId) external returns (uint256 eta);

    /// @notice Executes a proposal
    /// @param targets The target addresses to call
    /// @param values The ETH values of each call
    /// @param calldatas The calldata of each call
    /// @param descriptionHash The hash of the description
    /// @param proposer The proposal creator
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash,
        address proposer
    ) external payable returns (bytes32);

    /// @notice Cancels a proposal
    /// @param proposalId The proposal id
    function cancel(bytes32 proposalId) external;

    /// @notice Vetoes a proposal
    /// @param proposalId The proposal id
    function veto(bytes32 proposalId) external;

    /// @notice The state of a proposal
    /// @param proposalId The proposal id
    function state(bytes32 proposalId) external view returns (ProposalState);

    /// @notice The voting weight of an account at a timestamp
    /// @param account The account address
    /// @param timestamp The specific timestamp
    function getVotes(address account, uint256 timestamp) external view returns (uint256);

    /// @notice The current number of votes required to submit a proposal
    function proposalThreshold() external view returns (uint256);

    /// @notice The current number of votes required to be in favor of a proposal in order to reach quorum
    function quorum() external view returns (uint256);

    /// @notice The details of a proposal
    /// @param proposalId The proposal id
    function getProposal(bytes32 proposalId) external view returns (Proposal memory);

    /// @notice The timestamp when voting starts for a proposal
    /// @param proposalId The proposal id
    function proposalSnapshot(bytes32 proposalId) external view returns (uint256);

    /// @notice The timestamp when voting ends for a proposal
    /// @param proposalId The proposal id
    function proposalDeadline(bytes32 proposalId) external view returns (uint256);

    /// @notice The vote counts for a proposal
    /// @param proposalId The proposal id
    function proposalVotes(bytes32 proposalId)
        external
        view
        returns (
            uint256 againstVotes,
            uint256 forVotes,
            uint256 abstainVotes
        );

    /// @notice The timestamp valid to execute a proposal
    /// @param proposalId The proposal id
    function proposalEta(bytes32 proposalId) external view returns (uint256);

    /// @notice The minimum basis points of the total token supply required to submit a proposal
    function proposalThresholdBps() external view returns (uint256);

    /// @notice The minimum basis points of the total token supply required to reach quorum
    function quorumThresholdBps() external view returns (uint256);

    /// @notice The amount of time until voting begins after a proposal is created
    function votingDelay() external view returns (uint256);

    /// @notice The amount of time to vote on a proposal
    function votingPeriod() external view returns (uint256);

    /// @notice The address eligible to veto any proposal (address(0) if burned)
    function vetoer() external view returns (address);

    /// @notice The address of the governance token
    function token() external view returns (address);

    /// @notice The address of the DAO treasury
    function treasury() external view returns (address);

    /// @notice Updates the voting delay
    /// @param newVotingDelay The new voting delay
    function updateVotingDelay(uint256 newVotingDelay) external;

    /// @notice Updates the voting period
    /// @param newVotingPeriod The new voting period
    function updateVotingPeriod(uint256 newVotingPeriod) external;

    /// @notice Updates the minimum proposal threshold
    /// @param newProposalThresholdBps The new proposal threshold basis points
    function updateProposalThresholdBps(uint256 newProposalThresholdBps) external;

    /// @notice Updates the minimum quorum threshold
    /// @param newQuorumVotesBps The new quorum votes basis points
    function updateQuorumThresholdBps(uint256 newQuorumVotesBps) external;

    /// @notice Updates the vetoer
    /// @param newVetoer The new vetoer addresss
    function updateVetoer(address newVetoer) external;

    /// @notice Burns the vetoer
    function burnVetoer() external;

    /// @notice The EIP-712 typehash to vote with a signature
    function VOTE_TYPEHASH() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title ProposalHasher
/// @author tbtstl
/// @notice Helper contract to ensure proposal hashing functions are unified
abstract contract ProposalHasher {
    ///                                                          ///
    ///                         HASH PROPOSAL                    ///
    ///                                                          ///

    /// @notice Hashes a proposal's details into a proposal id
    /// @param _targets The target addresses to call
    /// @param _values The ETH values of each call
    /// @param _calldatas The calldata of each call
    /// @param _descriptionHash The hash of the description
    /// @param _proposer The original proposer of the transaction
    function hashProposal(
        address[] memory _targets,
        uint256[] memory _values,
        bytes[] memory _calldatas,
        bytes32 _descriptionHash,
        address _proposer
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_targets, _values, _calldatas, _descriptionHash, _proposer));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { GovernorTypesV1 } from "../types/GovernorTypesV1.sol";

/// @title GovernorStorageV1
/// @author Rohan Kulkarni
/// @notice The Governor storage contract
contract GovernorStorageV1 is GovernorTypesV1 {
    /// @notice The governor settings
    Settings internal settings;

    /// @notice The details of a proposal
    /// @dev Proposal Id => Proposal
    mapping(bytes32 => Proposal) internal proposals;

    /// @notice If a user has voted on a proposal
    /// @dev Proposal Id => User => Has Voted
    mapping(bytes32 => mapping(address => bool)) internal hasVoted;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Token } from "../../../token/Token.sol";
import { Treasury } from "../../treasury/Treasury.sol";

/// @title GovernorTypesV1
/// @author Rohan Kulkarni
/// @notice The Governor custom data types
interface GovernorTypesV1 {
    /// @notice The governor settings
    /// @param token The DAO governance token
    /// @param proposalThresholdBps The basis points of the token supply required to create a proposal
    /// @param quorumThresholdBps The basis points of the token supply required to reach quorum
    /// @param treasury The DAO treasury
    /// @param votingDelay The time delay to vote on a created proposal
    /// @param votingPeriod The time period to vote on a proposal
    /// @param vetoer The address with the ability to veto proposals
    struct Settings {
        Token token;
        uint16 proposalThresholdBps;
        uint16 quorumThresholdBps;
        Treasury treasury;
        uint48 votingDelay;
        uint48 votingPeriod;
        address vetoer;
    }

    /// @notice A governance proposal
    /// @param proposer The proposal creator
    /// @param timeCreated The timestamp that the proposal was created
    /// @param againstVotes The number of votes against
    /// @param forVotes The number of votes in favor
    /// @param abstainVotes The number of votes abstained
    /// @param voteStart The timestamp that voting starts
    /// @param voteEnd The timestamp that voting ends
    /// @param proposalThreshold The proposal threshold when the proposal was created
    /// @param quorumVotes The quorum threshold when the proposal was created
    /// @param executed If the proposal was executed
    /// @param canceled If the proposal was canceled
    /// @param vetoed If the proposal was vetoed
    struct Proposal {
        address proposer;
        uint32 timeCreated;
        uint32 againstVotes;
        uint32 forVotes;
        uint32 abstainVotes;
        uint32 voteStart;
        uint32 voteEnd;
        uint32 proposalThreshold;
        uint32 quorumVotes;
        bool executed;
        bool canceled;
        bool vetoed;
    }

    /// @notice The proposal state type
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed,
        Vetoed
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IOwnable } from "../../lib/utils/Ownable.sol";
import { IUUPS } from "../../lib/interfaces/IUUPS.sol";

/// @title ITreasury
/// @author Rohan Kulkarni
/// @notice The external Treasury events, errors and functions
interface ITreasury is IUUPS, IOwnable {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when a transaction is scheduled
    event TransactionScheduled(bytes32 proposalId, uint256 timestamp);

    /// @notice Emitted when a transaction is canceled
    event TransactionCanceled(bytes32 proposalId);

    /// @notice Emitted when a transaction is executed
    event TransactionExecuted(bytes32 proposalId, address[] targets, uint256[] values, bytes[] payloads);

    /// @notice Emitted when the transaction delay is updated
    event DelayUpdated(uint256 prevDelay, uint256 newDelay);

    /// @notice Emitted when the grace period is updated
    event GracePeriodUpdated(uint256 prevGracePeriod, uint256 newGracePeriod);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if tx was already queued
    error PROPOSAL_ALREADY_QUEUED();

    /// @dev Reverts if tx was not queued
    error PROPOSAL_NOT_QUEUED();

    /// @dev Reverts if a tx isn't ready to execute
    /// @param proposalId The proposal id
    error EXECUTION_NOT_READY(bytes32 proposalId);

    /// @dev Reverts if a tx failed
    /// @param txIndex The index of the tx
    error EXECUTION_FAILED(uint256 txIndex);

    /// @dev Reverts if execution was attempted after the grace period
    error EXECUTION_EXPIRED();

    /// @dev Reverts if the caller was not the treasury itself
    error ONLY_TREASURY();

    /// @dev Reverts if the caller was not the contract manager
    error ONLY_MANAGER();

    ///                                                          ///
    ///                          FUNCTIONS                       ///
    ///                                                          ///

    /// @notice Initializes a DAO's treasury
    /// @param governor The governor address
    /// @param timelockDelay The time delay to execute a queued transaction
    function initialize(address governor, uint256 timelockDelay) external;

    /// @notice The timestamp that a proposal is valid to execute
    /// @param proposalId The proposal id
    function timestamp(bytes32 proposalId) external view returns (uint256);

    /// @notice If a proposal has been queued
    /// @param proposalId The proposal ids
    function isQueued(bytes32 proposalId) external view returns (bool);

    /// @notice If a proposal is ready to execute (does not consider if a proposal has expired)
    /// @param proposalId The proposal id
    function isReady(bytes32 proposalId) external view returns (bool);

    /// @notice If a proposal has expired to execute
    /// @param proposalId The proposal id
    function isExpired(bytes32 proposalId) external view returns (bool);

    /// @notice Schedules a proposal for execution
    /// @param proposalId The proposal id
    function queue(bytes32 proposalId) external returns (uint256 eta);

    /// @notice Removes a queued proposal
    /// @param proposalId The proposal id
    function cancel(bytes32 proposalId) external;

    /// @notice Executes a queued proposal
    /// @param targets The target addresses to call
    /// @param values The ETH values of each call
    /// @param calldatas The calldata of each call
    /// @param descriptionHash The hash of the description
    /// @param proposer The proposal creator
    function execute(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata calldatas,
        bytes32 descriptionHash,
        address proposer
    ) external payable;

    /// @notice The time delay to execute a queued transaction
    function delay() external view returns (uint256);

    /// @notice The time period to execute a transaction
    function gracePeriod() external view returns (uint256);

    /// @notice Updates the time delay
    /// @param newDelay The new time delay
    function updateDelay(uint256 newDelay) external;

    /// @notice Updates the grace period
    /// @param newGracePeriod The grace period
    function updateGracePeriod(uint256 newGracePeriod) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { UUPS } from "../../lib/proxy/UUPS.sol";
import { Ownable } from "../../lib/utils/Ownable.sol";
import { ERC721TokenReceiver, ERC1155TokenReceiver } from "../../lib/utils/TokenReceiver.sol";
import { SafeCast } from "../../lib/utils/SafeCast.sol";

import { TreasuryStorageV1 } from "./storage/TreasuryStorageV1.sol";
import { ITreasury } from "./ITreasury.sol";
import { ProposalHasher } from "../governor/ProposalHasher.sol";
import { IManager } from "../../manager/IManager.sol";
import { VersionedContract } from "../../VersionedContract.sol";

/// @title Treasury
/// @author Rohan Kulkarni
/// @notice A DAO's treasury and transaction executor
/// @custom:repo github.com/ourzora/nouns-protocol 
/// Modified from:
/// - OpenZeppelin Contracts v4.7.3 (governance/TimelockController.sol)
/// - NounsDAOExecutor.sol commit 2cbe6c7 - licensed under the BSD-3-Clause license.
contract Treasury is ITreasury, VersionedContract, UUPS, Ownable, ProposalHasher, TreasuryStorageV1 {
    ///                                                          ///
    ///                         CONSTANTS                        ///
    ///                                                          ///

    /// @notice The default grace period setting
    uint128 private constant INITIAL_GRACE_PERIOD = 2 weeks;

    ///                                                          ///
    ///                         IMMUTABLES                       ///
    ///                                                          ///

    /// @notice The contract upgrade manager
    IManager private immutable manager;

    ///                                                          ///
    ///                         CONSTRUCTOR                      ///
    ///                                                          ///

    /// @param _manager The contract upgrade manager address
    constructor(address _manager) payable initializer {
        manager = IManager(_manager);
    }

    ///                                                          ///
    ///                         INITIALIZER                      ///
    ///                                                          ///

    /// @notice Initializes an instance of a DAO's treasury
    /// @param _governor The DAO's governor address
    /// @param _delay The time delay to execute a queued transaction
    function initialize(address _governor, uint256 _delay) external initializer {
        // Ensure the caller is the contract manager
        if (msg.sender != address(manager)) revert ONLY_MANAGER();

        // Ensure a governor address was provided
        if (_governor == address(0)) revert ADDRESS_ZERO();

        // Grant ownership to the governor
        __Ownable_init(_governor);

        // Store the time delay
        settings.delay = SafeCast.toUint128(_delay);

        // Set the default grace period
        settings.gracePeriod = INITIAL_GRACE_PERIOD;

        emit DelayUpdated(0, _delay);
    }

    ///                                                          ///
    ///                      TRANSACTION STATE                   ///
    ///                                                          ///

    /// @notice The timestamp that a proposal is valid to execute
    /// @param _proposalId The proposal id
    function timestamp(bytes32 _proposalId) external view returns (uint256) {
        return timestamps[_proposalId];
    }

    /// @notice If a queued proposal can no longer be executed
    /// @param _proposalId The proposal id
    function isExpired(bytes32 _proposalId) external view returns (bool) {
        unchecked {
            return block.timestamp > (timestamps[_proposalId] + settings.gracePeriod);
        }
    }

    /// @notice If a proposal is queued
    /// @param _proposalId The proposal id
    function isQueued(bytes32 _proposalId) public view returns (bool) {
        return timestamps[_proposalId] != 0;
    }

    /// @notice If a proposal is ready to execute (does not consider expiration)
    /// @param _proposalId The proposal id
    function isReady(bytes32 _proposalId) public view returns (bool) {
        return timestamps[_proposalId] != 0 && block.timestamp >= timestamps[_proposalId];
    }

    ///                                                          ///
    ///                        QUEUE PROPOSAL                    ///
    ///                                                          ///

    /// @notice Schedules a proposal for execution
    /// @param _proposalId The proposal id
    function queue(bytes32 _proposalId) external onlyOwner returns (uint256 eta) {
        // Ensure the proposal was not already queued
        if (isQueued(_proposalId)) revert PROPOSAL_ALREADY_QUEUED();

        // Cannot realistically overflow
        unchecked {
            // Compute the timestamp that the proposal will be valid to execute
            eta = block.timestamp + settings.delay;
        }

        // Store the timestamp
        timestamps[_proposalId] = eta;

        emit TransactionScheduled(_proposalId, eta);
    }

    ///                                                          ///
    ///                       EXECUTE PROPOSAL                   ///
    ///                                                          ///

    /// @notice Executes a queued proposal
    /// @param _targets The target addresses to call
    /// @param _values The ETH values of each call
    /// @param _calldatas The calldata of each call
    /// @param _descriptionHash The hash of the description
    /// @param _proposer The proposal creator
    function execute(
        address[] calldata _targets,
        uint256[] calldata _values,
        bytes[] calldata _calldatas,
        bytes32 _descriptionHash,
        address _proposer
    ) external payable onlyOwner {
        // Get the proposal id
        bytes32 proposalId = hashProposal(_targets, _values, _calldatas, _descriptionHash, _proposer);

        // Ensure the proposal is ready to execute
        if (!isReady(proposalId)) revert EXECUTION_NOT_READY(proposalId);

        // Remove the proposal from the queue
        delete timestamps[proposalId];

        // Cache the number of targets
        uint256 numTargets = _targets.length;

        // Cannot realistically overflow
        unchecked {
            // For each target:
            for (uint256 i = 0; i < numTargets; ++i) {
                // Execute the transaction
                (bool success, ) = _targets[i].call{ value: _values[i] }(_calldatas[i]);

                // Ensure the transaction succeeded
                if (!success) revert EXECUTION_FAILED(i);
            }
        }

        emit TransactionExecuted(proposalId, _targets, _values, _calldatas);
    }

    ///                                                          ///
    ///                       CANCEL PROPOSAL                    ///
    ///                                                          ///

    /// @notice Removes a queued proposal
    /// @param _proposalId The proposal id
    function cancel(bytes32 _proposalId) external onlyOwner {
        // Ensure the proposal is queued
        if (!isQueued(_proposalId)) revert PROPOSAL_NOT_QUEUED();

        // Remove the proposal from the queue
        delete timestamps[_proposalId];

        emit TransactionCanceled(_proposalId);
    }

    ///                                                          ///
    ///                      TREASURY SETTINGS                   ///
    ///                                                          ///

    /// @notice The time delay to execute a queued transaction
    function delay() external view returns (uint256) {
        return settings.delay;
    }

    /// @notice The time period to execute a proposal
    function gracePeriod() external view returns (uint256) {
        return settings.gracePeriod;
    }

    ///                                                          ///
    ///                       UPDATE SETTINGS                    ///
    ///                                                          ///

    /// @notice Updates the transaction delay
    /// @param _newDelay The new time delay
    function updateDelay(uint256 _newDelay) external {
        // Ensure the caller is the treasury itself
        if (msg.sender != address(this)) revert ONLY_TREASURY();

        emit DelayUpdated(settings.delay, _newDelay);

        // Update the delay
        settings.delay = SafeCast.toUint128(_newDelay);
    }

    /// @notice Updates the execution grace period
    /// @param _newGracePeriod The new grace period
    function updateGracePeriod(uint256 _newGracePeriod) external {
        // Ensure the caller is the treasury itself
        if (msg.sender != address(this)) revert ONLY_TREASURY();

        emit GracePeriodUpdated(settings.gracePeriod, _newGracePeriod);

        // Update the grace period
        settings.gracePeriod = SafeCast.toUint128(_newGracePeriod);
    }

    ///                                                          ///
    ///                        RECEIVE TOKENS                    ///
    ///                                                          ///

    /// @dev Accepts all ERC-721 transfers
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }

    /// @dev Accepts all ERC-1155 single id transfers
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    /// @dev Accept all ERC-1155 batch id transfers
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }

    /// @dev Accepts ETH transfers
    receive() external payable {}

    ///                                                          ///
    ///                       TREASURY UPGRADE                   ///
    ///                                                          ///

    /// @notice Ensures the caller is authorized to upgrade the contract and that the new implementation is valid
    /// @dev This function is called in `upgradeTo` & `upgradeToAndCall`
    /// @param _newImpl The new implementation address
    function _authorizeUpgrade(address _newImpl) internal view override {
        // Ensure the caller is the treasury itself
        if (msg.sender != address(this)) revert ONLY_TREASURY();

        // Ensure the new implementation is a registered upgrade
        if (!manager.isRegisteredUpgrade(_getImplementation(), _newImpl)) revert INVALID_UPGRADE(_newImpl);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { TreasuryTypesV1 } from "../types/TreasuryTypesV1.sol";

/// @notice TreasuryStorageV1
/// @author Rohan Kulkarni
/// @notice The Treasury storage contract
contract TreasuryStorageV1 is TreasuryTypesV1 {
    /// @notice The treasury settings
    Settings internal settings;

    /// @notice The timestamp that a queued proposal is ready to execute
    /// @dev Proposal Id => Timestamp
    mapping(bytes32 => uint256) internal timestamps;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @notice TreasuryTypesV1
/// @author Rohan Kulkarni
/// @notice The treasury's custom data types
contract TreasuryTypesV1 {
    /// @notice The settings type
    /// @param gracePeriod The time period to execute a proposal
    /// @param delay The time delay to execute a queued transaction
    struct Settings {
        uint128 gracePeriod;
        uint128 delay;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title IEIP712
/// @author Rohan Kulkarni
/// @notice The external EIP712 errors and functions
interface IEIP712 {
    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if the deadline has passed to submit a signature
    error EXPIRED_SIGNATURE();

    /// @dev Reverts if the recovered signature is invalid
    error INVALID_SIGNATURE();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice The sig nonce for an account
    /// @param account The account address
    function nonce(address account) external view returns (uint256);

    /// @notice The EIP-712 domain separator
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title IERC1967Upgrade
/// @author Rohan Kulkarni
/// @notice The external ERC1967Upgrade events and errors
interface IERC1967Upgrade {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when the implementation is upgraded
    /// @param impl The address of the implementation
    event Upgraded(address impl);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if an implementation is an invalid upgrade
    /// @param impl The address of the invalid implementation
    error INVALID_UPGRADE(address impl);

    /// @dev Reverts if an implementation upgrade is not stored at the storage slot of the original
    error UNSUPPORTED_UUID();

    /// @dev Reverts if an implementation does not support ERC1822 proxiableUUID()
    error ONLY_UUPS();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title IERC721
/// @author Rohan Kulkarni
/// @notice The external ERC721 events, errors, and functions
interface IERC721 {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when a token is transferred from sender to recipient
    /// @param from The sender address
    /// @param to The recipient address
    /// @param tokenId The ERC-721 token id
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /// @notice Emitted when an owner approves an account to manage a token
    /// @param owner The owner address
    /// @param approved The account address
    /// @param tokenId The ERC-721 token id
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /// @notice Emitted when an owner sets an approval for a spender to manage all tokens
    /// @param owner The owner address
    /// @param operator The spender address
    /// @param approved If the approval is being set or removed
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if a caller is not authorized to approve or transfer a token
    error INVALID_APPROVAL();

    /// @dev Reverts if a transfer is called with the incorrect token owner
    error INVALID_OWNER();

    /// @dev Reverts if a transfer is attempted to address(0)
    error INVALID_RECIPIENT();

    /// @dev Reverts if an existing token is called to be minted
    error ALREADY_MINTED();

    /// @dev Reverts if a non-existent token is called to be burned
    error NOT_MINTED();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice The number of tokens owned
    /// @param owner The owner address
    function balanceOf(address owner) external view returns (uint256);

    /// @notice The owner of a token
    /// @param tokenId The ERC-721 token id
    function ownerOf(uint256 tokenId) external view returns (address);

    /// @notice The account approved to manage a token
    /// @param tokenId The ERC-721 token id
    function getApproved(uint256 tokenId) external view returns (address);

    /// @notice If an operator is authorized to manage all of an owner's tokens
    /// @param owner The owner address
    /// @param operator The operator address
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /// @notice Authorizes an account to manage a token
    /// @param to The account address
    /// @param tokenId The ERC-721 token id
    function approve(address to, uint256 tokenId) external;

    /// @notice Authorizes an account to manage all tokens
    /// @param operator The account address
    /// @param approved If permission is being given or removed
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice Safe transfers a token from sender to recipient with additional data
    /// @param from The sender address
    /// @param to The recipient address
    /// @param tokenId The ERC-721 token id
    /// @param data The additional data sent in the call to the recipient
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /// @notice Safe transfers a token from sender to recipient
    /// @param from The sender address
    /// @param to The recipient address
    /// @param tokenId The ERC-721 token id
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /// @notice Transfers a token from sender to recipient
    /// @param from The sender address
    /// @param to The recipient address
    /// @param tokenId The ERC-721 token id
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IERC721 } from "./IERC721.sol";
import { IEIP712 } from "./IEIP712.sol";

/// @title IERC721Votes
/// @author Rohan Kulkarni
/// @notice The external ERC721Votes events, errors, and functions
interface IERC721Votes is IERC721, IEIP712 {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when an account changes their delegate
    event DelegateChanged(address indexed delegator, address indexed from, address indexed to);

    /// @notice Emitted when a delegate's number of votes is updated
    event DelegateVotesChanged(address indexed delegate, uint256 prevTotalVotes, uint256 newTotalVotes);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if the timestamp provided isn't in the past
    error INVALID_TIMESTAMP();

    ///                                                          ///
    ///                            STRUCTS                       ///
    ///                                                          ///

    /// @notice The checkpoint data type
    /// @param timestamp The recorded timestamp
    /// @param votes The voting weight
    struct Checkpoint {
        uint64 timestamp;
        uint192 votes;
    }

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice The current number of votes for an account
    /// @param account The account address
    function getVotes(address account) external view returns (uint256);

    /// @notice The number of votes for an account at a past timestamp
    /// @param account The account address
    /// @param timestamp The past timestamp
    function getPastVotes(address account, uint256 timestamp) external view returns (uint256);

    /// @notice The delegate for an account
    /// @param account The account address
    function delegates(address account) external view returns (address);

    /// @notice Delegates votes to an account
    /// @param to The address delegating votes to
    function delegate(address to) external;

    /// @notice Delegates votes from a signer to an account
    /// @param from The address delegating votes from
    /// @param to The address delegating votes to
    /// @param deadline The signature deadline
    /// @param v The 129th byte and chain id of the signature
    /// @param r The first 64 bytes of the signature
    /// @param s Bytes 64-128 of the signature
    function delegateBySig(
        address from,
        address to,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title IInitializable
/// @author Rohan Kulkarni
/// @notice The external Initializable events and errors
interface IInitializable {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when the contract has been initialized or reinitialized
    event Initialized(uint256 version);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if incorrectly initialized with address(0)
    error ADDRESS_ZERO();

    /// @dev Reverts if disabling initializers during initialization
    error INITIALIZING();

    /// @dev Reverts if calling an initialization function outside of initialization
    error NOT_INITIALIZING();

    /// @dev Reverts if reinitializing incorrectly
    error ALREADY_INITIALIZED();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title IOwnable
/// @author Rohan Kulkarni
/// @notice The external Ownable events, errors, and functions
interface IOwnable {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when ownership has been updated
    /// @param prevOwner The previous owner address
    /// @param newOwner The new owner address
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);

    /// @notice Emitted when an ownership transfer is pending
    /// @param owner The current owner address
    /// @param pendingOwner The pending new owner address
    event OwnerPending(address indexed owner, address indexed pendingOwner);

    /// @notice Emitted when a pending ownership transfer has been canceled
    /// @param owner The current owner address
    /// @param canceledOwner The canceled owner address
    event OwnerCanceled(address indexed owner, address indexed canceledOwner);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if an unauthorized user calls an owner function
    error ONLY_OWNER();

    /// @dev Reverts if an unauthorized user calls a pending owner function
    error ONLY_PENDING_OWNER();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice The address of the owner
    function owner() external view returns (address);

    /// @notice The address of the pending owner
    function pendingOwner() external view returns (address);

    /// @notice Forces an ownership transfer
    /// @param newOwner The new owner address
    function transferOwnership(address newOwner) external;

    /// @notice Initiates a two-step ownership transfer
    /// @param newOwner The new owner address
    function safeTransferOwnership(address newOwner) external;

    /// @notice Accepts an ownership transfer
    function acceptOwnership() external;

    /// @notice Cancels a pending ownership transfer
    function cancelOwnershipTransfer() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title IPausable
/// @author Rohan Kulkarni
/// @notice The external Pausable events, errors, and functions
interface IPausable {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when the contract is paused
    /// @param user The address that paused the contract
    event Paused(address user);

    /// @notice Emitted when the contract is unpaused
    /// @param user The address that unpaused the contract
    event Unpaused(address user);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if called when the contract is paused
    error PAUSED();

    /// @dev Reverts if called when the contract is unpaused
    error UNPAUSED();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice If the contract is paused
    function paused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { IERC1822Proxiable } from "@openzeppelin/contracts/interfaces/draft-IERC1822.sol";
import { IERC1967Upgrade } from "./IERC1967Upgrade.sol";

/// @title IUUPS
/// @author Rohan Kulkarni
/// @notice The external UUPS errors and functions
interface IUUPS is IERC1967Upgrade, IERC1822Proxiable {
    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if not called directly
    error ONLY_CALL();

    /// @dev Reverts if not called via delegatecall
    error ONLY_DELEGATECALL();

    /// @dev Reverts if not called via proxy
    error ONLY_PROXY();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice Upgrades to an implementation
    /// @param newImpl The new implementation address
    function upgradeTo(address newImpl) external;

    /// @notice Upgrades to an implementation with an additional function call
    /// @param newImpl The new implementation address
    /// @param data The encoded function call
    function upgradeToAndCall(address newImpl, bytes memory data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IERC1822Proxiable } from "@openzeppelin/contracts/interfaces/draft-IERC1822.sol";
import { StorageSlot } from "@openzeppelin/contracts/utils/StorageSlot.sol";

import { IERC1967Upgrade } from "../interfaces/IERC1967Upgrade.sol";
import { Address } from "../utils/Address.sol";

/// @title ERC1967Upgrade
/// @author Rohan Kulkarni
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (proxy/ERC1967/ERC1967Upgrade.sol)
/// - Uses custom errors declared in IERC1967Upgrade
/// - Removes ERC1967 admin and beacon support
abstract contract ERC1967Upgrade is IERC1967Upgrade {
    ///                                                          ///
    ///                          CONSTANTS                       ///
    ///                                                          ///

    /// @dev bytes32(uint256(keccak256('eip1967.proxy.rollback')) - 1)
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /// @dev bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    ///                                                          ///
    ///                          FUNCTIONS                       ///
    ///                                                          ///

    /// @dev Upgrades to an implementation with security checks for UUPS proxies and an additional function call
    /// @param _newImpl The new implementation address
    /// @param _data The encoded function call
    function _upgradeToAndCallUUPS(
        address _newImpl,
        bytes memory _data,
        bool _forceCall
    ) internal {
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(_newImpl);
        } else {
            try IERC1822Proxiable(_newImpl).proxiableUUID() returns (bytes32 slot) {
                if (slot != _IMPLEMENTATION_SLOT) revert UNSUPPORTED_UUID();
            } catch {
                revert ONLY_UUPS();
            }

            _upgradeToAndCall(_newImpl, _data, _forceCall);
        }
    }

    /// @dev Upgrades to an implementation with an additional function call
    /// @param _newImpl The new implementation address
    /// @param _data The encoded function call
    function _upgradeToAndCall(
        address _newImpl,
        bytes memory _data,
        bool _forceCall
    ) internal {
        _upgradeTo(_newImpl);

        if (_data.length > 0 || _forceCall) {
            Address.functionDelegateCall(_newImpl, _data);
        }
    }

    /// @dev Performs an implementation upgrade
    /// @param _newImpl The new implementation address
    function _upgradeTo(address _newImpl) internal {
        _setImplementation(_newImpl);

        emit Upgraded(_newImpl);
    }

    /// @dev Stores the address of an implementation
    /// @param _impl The implementation address
    function _setImplementation(address _impl) private {
        if (!Address.isContract(_impl)) revert INVALID_UPGRADE(_impl);

        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = _impl;
    }

    /// @dev The address of the current implementation
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IUUPS } from "../interfaces/IUUPS.sol";
import { ERC1967Upgrade } from "./ERC1967Upgrade.sol";

/// @title UUPS
/// @author Rohan Kulkarni
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (proxy/utils/UUPSUpgradeable.sol)
/// - Uses custom errors declared in IUUPS
/// - Inherits a modern, minimal ERC1967Upgrade
abstract contract UUPS is IUUPS, ERC1967Upgrade {
    ///                                                          ///
    ///                          IMMUTABLES                      ///
    ///                                                          ///

    /// @dev The address of the implementation
    address private immutable __self = address(this);

    ///                                                          ///
    ///                           MODIFIERS                      ///
    ///                                                          ///

    /// @dev Ensures that execution is via proxy delegatecall with the correct implementation
    modifier onlyProxy() {
        if (address(this) == __self) revert ONLY_DELEGATECALL();
        if (_getImplementation() != __self) revert ONLY_PROXY();
        _;
    }

    /// @dev Ensures that execution is via direct call
    modifier notDelegated() {
        if (address(this) != __self) revert ONLY_CALL();
        _;
    }

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @dev Hook to authorize an implementation upgrade
    /// @param _newImpl The new implementation address
    function _authorizeUpgrade(address _newImpl) internal virtual;

    /// @notice Upgrades to an implementation
    /// @param _newImpl The new implementation address
    function upgradeTo(address _newImpl) external onlyProxy {
        _authorizeUpgrade(_newImpl);
        _upgradeToAndCallUUPS(_newImpl, "", false);
    }

    /// @notice Upgrades to an implementation with an additional function call
    /// @param _newImpl The new implementation address
    /// @param _data The encoded function call
    function upgradeToAndCall(address _newImpl, bytes memory _data) external payable onlyProxy {
        _authorizeUpgrade(_newImpl);
        _upgradeToAndCallUUPS(_newImpl, _data, true);
    }

    /// @notice The storage slot of the implementation address
    function proxiableUUID() external view notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IERC721 } from "../interfaces/IERC721.sol";
import { Initializable } from "../utils/Initializable.sol";
import { ERC721TokenReceiver } from "../utils/TokenReceiver.sol";
import { Address } from "../utils/Address.sol";

/// @title ERC721
/// @author Rohan Kulkarni
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (token/ERC721/ERC721Upgradeable.sol)
/// - Uses custom errors declared in IERC721
abstract contract ERC721 is IERC721, Initializable {
    ///                                                          ///
    ///                            STORAGE                       ///
    ///                                                          ///

    /// @notice The token name
    string public name;

    /// @notice The token symbol
    string public symbol;

    /// @notice The token owners
    /// @dev ERC-721 token id => Owner
    mapping(uint256 => address) internal owners;

    /// @notice The owner balances
    /// @dev Owner => Balance
    mapping(address => uint256) internal balances;

    /// @notice The token approvals
    /// @dev ERC-721 token id => Manager
    mapping(uint256 => address) internal tokenApprovals;

    /// @notice The balance approvals
    /// @dev Owner => Operator => Approved
    mapping(address => mapping(address => bool)) internal operatorApprovals;

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @dev Initializes an ERC-721 token
    /// @param _name The ERC-721 token name
    /// @param _symbol The ERC-721 token symbol
    function __ERC721_init(string memory _name, string memory _symbol) internal onlyInitializing {
        name = _name;
        symbol = _symbol;
    }

    /// @notice The token URI
    /// @param _tokenId The ERC-721 token id
    function tokenURI(uint256 _tokenId) public view virtual returns (string memory) {}

    /// @notice The contract URI
    function contractURI() public view virtual returns (string memory) {}

    /// @notice If the contract implements an interface
    /// @param _interfaceId The interface id
    function supportsInterface(bytes4 _interfaceId) external pure returns (bool) {
        return
            _interfaceId == 0x01ffc9a7 || // ERC165 Interface ID
            _interfaceId == 0x80ac58cd || // ERC721 Interface ID
            _interfaceId == 0x5b5e139f; // ERC721Metadata Interface ID
    }

    /// @notice The account approved to manage a token
    /// @param _tokenId The ERC-721 token id
    function getApproved(uint256 _tokenId) external view returns (address) {
        return tokenApprovals[_tokenId];
    }

    /// @notice If an operator is authorized to manage all of an owner's tokens
    /// @param _owner The owner address
    /// @param _operator The operator address
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    /// @notice The number of tokens owned
    /// @param _owner The owner address
    function balanceOf(address _owner) public view returns (uint256) {
        if (_owner == address(0)) revert ADDRESS_ZERO();

        return balances[_owner];
    }

    /// @notice The owner of a token
    /// @param _tokenId The ERC-721 token id
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = owners[_tokenId];

        if (owner == address(0)) revert INVALID_OWNER();

        return owner;
    }

    /// @notice Authorizes an account to manage a token
    /// @param _to The account address
    /// @param _tokenId The ERC-721 token id
    function approve(address _to, uint256 _tokenId) external {
        address owner = owners[_tokenId];

        if (msg.sender != owner && !operatorApprovals[owner][msg.sender]) revert INVALID_APPROVAL();

        tokenApprovals[_tokenId] = _to;

        emit Approval(owner, _to, _tokenId);
    }

    /// @notice Authorizes an account to manage all tokens
    /// @param _operator The account address
    /// @param _approved If permission is being given or removed
    function setApprovalForAll(address _operator, bool _approved) external {
        operatorApprovals[msg.sender][_operator] = _approved;

        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @notice Transfers a token from sender to recipient
    /// @param _from The sender address
    /// @param _to The recipient address
    /// @param _tokenId The ERC-721 token id
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        if (_from != owners[_tokenId]) revert INVALID_OWNER();

        if (_to == address(0)) revert ADDRESS_ZERO();

        if (msg.sender != _from && !operatorApprovals[_from][msg.sender] && msg.sender != tokenApprovals[_tokenId]) revert INVALID_APPROVAL();

        _beforeTokenTransfer(_from, _to, _tokenId);

        unchecked {
            --balances[_from];

            ++balances[_to];
        }

        owners[_tokenId] = _to;

        delete tokenApprovals[_tokenId];

        emit Transfer(_from, _to, _tokenId);

        _afterTokenTransfer(_from, _to, _tokenId);
    }

    /// @notice Safe transfers a token from sender to recipient
    /// @param _from The sender address
    /// @param _to The recipient address
    /// @param _tokenId The ERC-721 token id
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        transferFrom(_from, _to, _tokenId);

        if (
            Address.isContract(_to) &&
            ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, "") != ERC721TokenReceiver.onERC721Received.selector
        ) revert INVALID_RECIPIENT();
    }

    /// @notice Safe transfers a token from sender to recipient with additional data
    /// @param _from The sender address
    /// @param _to The recipient address
    /// @param _tokenId The ERC-721 token id
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external {
        transferFrom(_from, _to, _tokenId);

        if (
            Address.isContract(_to) &&
            ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) != ERC721TokenReceiver.onERC721Received.selector
        ) revert INVALID_RECIPIENT();
    }

    /// @dev Mints a token to a recipient
    /// @param _to The recipient address
    /// @param _tokenId The ERC-721 token id
    function _mint(address _to, uint256 _tokenId) internal virtual {
        if (_to == address(0)) revert ADDRESS_ZERO();

        if (owners[_tokenId] != address(0)) revert ALREADY_MINTED();

        _beforeTokenTransfer(address(0), _to, _tokenId);

        unchecked {
            ++balances[_to];
        }

        owners[_tokenId] = _to;

        emit Transfer(address(0), _to, _tokenId);

        _afterTokenTransfer(address(0), _to, _tokenId);
    }

    /// @dev Burns a token to a recipient
    /// @param _tokenId The ERC-721 token id
    function _burn(uint256 _tokenId) internal virtual {
        address owner = owners[_tokenId];

        if (owner == address(0)) revert NOT_MINTED();

        _beforeTokenTransfer(owner, address(0), _tokenId);

        unchecked {
            --balances[owner];
        }

        delete owners[_tokenId];

        delete tokenApprovals[_tokenId];

        emit Transfer(owner, address(0), _tokenId);

        _afterTokenTransfer(owner, address(0), _tokenId);
    }

    /// @dev Hook called before a token transfer
    /// @param _from The sender address
    /// @param _to The recipient address
    /// @param _tokenId The ERC-721 token id
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual {}

    /// @dev Hook called after a token transfer
    /// @param _from The sender address
    /// @param _to The recipient address
    /// @param _tokenId The ERC-721 token id
    function _afterTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IERC721Votes } from "../interfaces/IERC721Votes.sol";
import { ERC721 } from "../token/ERC721.sol";
import { EIP712 } from "../utils/EIP712.sol";

/// @title ERC721Votes
/// @author Rohan Kulkarni
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (token/ERC721/extensions/draft-ERC721Votes.sol) & Nouns DAO ERC721Checkpointable.sol commit 2cbe6c7 - licensed under the BSD-3-Clause license.
/// - Uses custom errors defined in IERC721Votes
/// - Checkpoints are based on timestamps instead of block numbers
/// - Tokens are self-delegated by default
/// - The total number of votes is the token supply itself
abstract contract ERC721Votes is IERC721Votes, EIP712, ERC721 {
    ///                                                          ///
    ///                          CONSTANTS                       ///
    ///                                                          ///

    /// @dev The EIP-712 typehash to delegate with a signature
    bytes32 internal constant DELEGATION_TYPEHASH = keccak256("Delegation(address from,address to,uint256 nonce,uint256 deadline)");

    ///                                                          ///
    ///                           STORAGE                        ///
    ///                                                          ///

    /// @notice The delegate for an account
    /// @notice Account => Delegate
    mapping(address => address) internal delegation;

    /// @notice The number of checkpoints for an account
    /// @dev Account => Num Checkpoints
    mapping(address => uint256) internal numCheckpoints;

    /// @notice The checkpoint for an account
    /// @dev Account => Checkpoint Id => Checkpoint
    mapping(address => mapping(uint256 => Checkpoint)) internal checkpoints;

    ///                                                          ///
    ///                        VOTING WEIGHT                     ///
    ///                                                          ///

    /// @notice The current number of votes for an account
    /// @param _account The account address
    function getVotes(address _account) public view returns (uint256) {
        // Get the account's number of checkpoints
        uint256 nCheckpoints = numCheckpoints[_account];

        // Cannot underflow as `nCheckpoints` is ensured to be greater than 0 if reached
        unchecked {
            // Return the number of votes at the latest checkpoint if applicable
            return nCheckpoints != 0 ? checkpoints[_account][nCheckpoints - 1].votes : 0;
        }
    }

    /// @notice The number of votes for an account at a past timestamp
    /// @param _account The account address
    /// @param _timestamp The past timestamp
    function getPastVotes(address _account, uint256 _timestamp) public view returns (uint256) {
        // Ensure the given timestamp is in the past
        if (_timestamp >= block.timestamp) revert INVALID_TIMESTAMP();

        // Get the account's number of checkpoints
        uint256 nCheckpoints = numCheckpoints[_account];

        // If there are none return 0
        if (nCheckpoints == 0) return 0;

        // Get the account's checkpoints
        mapping(uint256 => Checkpoint) storage accountCheckpoints = checkpoints[_account];

        unchecked {
            // Get the latest checkpoint id
            // Cannot underflow as `nCheckpoints` is ensured to be greater than 0
            uint256 lastCheckpoint = nCheckpoints - 1;

            // If the latest checkpoint has a valid timestamp, return its number of votes
            if (accountCheckpoints[lastCheckpoint].timestamp <= _timestamp) return accountCheckpoints[lastCheckpoint].votes;

            // If the first checkpoint doesn't have a valid timestamp, return 0
            if (accountCheckpoints[0].timestamp > _timestamp) return 0;

            // Otherwise, find a checkpoint with a valid timestamp
            // Use the latest id as the initial upper bound
            uint256 high = lastCheckpoint;
            uint256 low;
            uint256 middle;

            // Used to temporarily hold a checkpoint
            Checkpoint memory cp;

            // While a valid checkpoint is to be found:
            while (high > low) {
                // Find the id of the middle checkpoint
                middle = high - (high - low) / 2;

                // Get the middle checkpoint
                cp = accountCheckpoints[middle];

                // If the timestamp is a match:
                if (cp.timestamp == _timestamp) {
                    // Return the voting weight
                    return cp.votes;

                    // Else if the timestamp is before the one looking for:
                } else if (cp.timestamp < _timestamp) {
                    // Update the lower bound
                    low = middle;

                    // Else update the upper bound
                } else {
                    high = middle - 1;
                }
            }

            return accountCheckpoints[low].votes;
        }
    }

    ///                                                          ///
    ///                          DELEGATION                      ///
    ///                                                          ///

    /// @notice The delegate for an account
    /// @param _account The account address
    function delegates(address _account) public view returns (address) {
        address current = delegation[_account];
        return current == address(0) ? _account : current;
    }

    /// @notice Delegates votes to an account
    /// @param _to The address delegating votes to
    function delegate(address _to) external {
        _delegate(msg.sender, _to);
    }

    /// @notice Delegates votes from a signer to an account
    /// @param _from The address delegating votes from
    /// @param _to The address delegating votes to
    /// @param _deadline The signature deadline
    /// @param _v The 129th byte and chain id of the signature
    /// @param _r The first 64 bytes of the signature
    /// @param _s Bytes 64-128 of the signature
    function delegateBySig(
        address _from,
        address _to,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        // Ensure the signature has not expired
        if (block.timestamp > _deadline) revert EXPIRED_SIGNATURE();

        // Used to store the digest
        bytes32 digest;

        // Cannot realistically overflow
        unchecked {
            // Compute the hash of the domain seperator with the typed delegation data
            digest = keccak256(
                abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), keccak256(abi.encode(DELEGATION_TYPEHASH, _from, _to, nonces[_from]++, _deadline)))
            );
        }

        // Recover the message signer
        address recoveredAddress = ecrecover(digest, _v, _r, _s);

        // Ensure the recovered signer is the voter
        if (recoveredAddress == address(0) || recoveredAddress != _from) revert INVALID_SIGNATURE();

        // Update the delegate
        _delegate(_from, _to);
    }

    /// @dev Updates delegate addresses
    /// @param _from The address delegating votes from
    /// @param _to The address delegating votes to
    function _delegate(address _from, address _to) internal {
        // If address(0) is being delegated to, update the op as a self-delegate
        if (_to == address(0)) _to = _from;

        // Get the previous delegate
        address prevDelegate = delegates(_from);

        // Store the new delegate
        delegation[_from] = _to;

        emit DelegateChanged(_from, prevDelegate, _to);

        // Transfer voting weight from the previous delegate to the new delegate
        _moveDelegateVotes(prevDelegate, _to, balanceOf(_from));
    }

    /// @dev Transfers voting weight
    /// @param _from The address delegating votes from
    /// @param _to The address delegating votes to
    /// @param _amount The number of votes delegating
    function _moveDelegateVotes(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        unchecked {
            // If voting weight is being transferred:
            if (_from != _to && _amount > 0) {
                // If this isn't a token mint:
                if (_from != address(0)) {
                    // Get the sender's number of checkpoints
                    uint256 newCheckpointId = numCheckpoints[_from];

                    // Used to store their previous checkpoint id
                    uint256 prevCheckpointId;

                    // Used to store their previous checkpoint's voting weight
                    uint256 prevTotalVotes;

                    // Used to store their previous checkpoint's timestamp
                    uint256 prevTimestamp;

                    // If this isn't the sender's first checkpoint:
                    if (newCheckpointId != 0) {
                        // Get their previous checkpoint's id
                        prevCheckpointId = newCheckpointId - 1;

                        // Get their previous checkpoint's voting weight
                        prevTotalVotes = checkpoints[_from][prevCheckpointId].votes;

                        // Get their previous checkpoint's timestamp
                        prevTimestamp = checkpoints[_from][prevCheckpointId].timestamp;
                    }

                    // Update their voting weight
                    _writeCheckpoint(_from, newCheckpointId, prevCheckpointId, prevTimestamp, prevTotalVotes, prevTotalVotes - _amount);
                }

                // If this isn't a token burn:
                if (_to != address(0)) {
                    // Get the recipients's number of checkpoints
                    uint256 nCheckpoints = numCheckpoints[_to];

                    // Used to store their previous checkpoint id
                    uint256 prevCheckpointId;

                    // Used to store their previous checkpoint's voting weight
                    uint256 prevTotalVotes;

                    // Used to store their previous checkpoint's timestamp
                    uint256 prevTimestamp;

                    // If this isn't the recipient's first checkpoint:
                    if (nCheckpoints != 0) {
                        // Get their previous checkpoint's id
                        prevCheckpointId = nCheckpoints - 1;

                        // Get their previous checkpoint's voting weight
                        prevTotalVotes = checkpoints[_to][prevCheckpointId].votes;

                        // Get their previous checkpoint's timestamp
                        prevTimestamp = checkpoints[_to][prevCheckpointId].timestamp;
                    }

                    // Update their voting weight
                    _writeCheckpoint(_to, nCheckpoints, prevCheckpointId, prevTimestamp, prevTotalVotes, prevTotalVotes + _amount);
                }
            }
        }
    }

    /// @dev Records a checkpoint
    /// @param _account The account address
    /// @param _newId The new checkpoint id
    /// @param _prevId The previous checkpoint id
    /// @param _prevTimestamp The previous checkpoint timestamp
    /// @param _prevTotalVotes The previous checkpoint voting weight
    /// @param _newTotalVotes The new checkpoint voting weight
    function _writeCheckpoint(
        address _account,
        uint256 _newId,
        uint256 _prevId,
        uint256 _prevTimestamp,
        uint256 _prevTotalVotes,
        uint256 _newTotalVotes
    ) private {
        unchecked {
            // If the new checkpoint is not the user's first AND has the timestamp of the previous checkpoint:
            if (_newId > 0 && _prevTimestamp == block.timestamp) {
                // Just update the previous checkpoint's votes
                checkpoints[_account][_prevId].votes = uint192(_newTotalVotes);

                // Else write a new checkpoint:
            } else {
                // Get the pointer to store the checkpoint
                Checkpoint storage checkpoint = checkpoints[_account][_newId];

                // Store the new voting weight and the current time
                checkpoint.votes = uint192(_newTotalVotes);
                checkpoint.timestamp = uint64(block.timestamp);

                // Increment the account's number of checkpoints
                ++numCheckpoints[_account];
            }

            emit DelegateVotesChanged(_account, _prevTotalVotes, _newTotalVotes);
        }
    }

    /// @dev Enables each NFT to equal 1 vote
    /// @param _from The token sender
    /// @param _to The token recipient
    /// @param _tokenId The ERC-721 token id
    function _afterTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override {
        // Transfer 1 vote from the sender to the recipient
        _moveDelegateVotes(delegates(_from), delegates(_to), 1);

        super._afterTokenTransfer(_from, _to, _tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title EIP712
/// @author Rohan Kulkarni
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (utils/Address.sol)
/// - Uses custom errors `INVALID_TARGET()` & `DELEGATE_CALL_FAILED()`
/// - Adds util converting address to bytes32
library Address {
    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if the target of a delegatecall is not a contract
    error INVALID_TARGET();

    /// @dev Reverts if a delegatecall has failed
    error DELEGATE_CALL_FAILED();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @dev Utility to convert an address to bytes32
    function toBytes32(address _account) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_account)) << 96);
    }

    /// @dev If an address is a contract
    function isContract(address _account) internal view returns (bool rv) {
        assembly {
            rv := gt(extcodesize(_account), 0)
        }
    }

    /// @dev Performs a delegatecall on an address
    function functionDelegateCall(address _target, bytes memory _data) internal returns (bytes memory) {
        if (!isContract(_target)) revert INVALID_TARGET();

        (bool success, bytes memory returndata) = _target.delegatecall(_data);

        return verifyCallResult(success, returndata);
    }

    /// @dev Verifies a delegatecall was successful
    function verifyCallResult(bool _success, bytes memory _returndata) internal pure returns (bytes memory) {
        if (_success) {
            return _returndata;
        } else {
            if (_returndata.length > 0) {
                assembly {
                    let returndata_size := mload(_returndata)

                    revert(add(32, _returndata), returndata_size)
                }
            } else {
                revert DELEGATE_CALL_FAILED();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IEIP712 } from "../interfaces/IEIP712.sol";
import { Initializable } from "../utils/Initializable.sol";

/// @title EIP712
/// @author Rohan Kulkarni
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (utils/cryptography/draft-EIP712Upgradeable.sol)
/// - Uses custom errors declared in IEIP712
/// - Caches `INITIAL_CHAIN_ID` and `INITIAL_DOMAIN_SEPARATOR` upon initialization
/// - Adds mapping for account nonces
abstract contract EIP712 is IEIP712, Initializable {
    ///                                                          ///
    ///                          CONSTANTS                       ///
    ///                                                          ///

    /// @dev The EIP-712 domain typehash
    bytes32 internal constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    ///                                                          ///
    ///                           STORAGE                        ///
    ///                                                          ///

    /// @notice The hash of the EIP-712 domain name
    bytes32 internal HASHED_NAME;

    /// @notice The hash of the EIP-712 domain version
    bytes32 internal HASHED_VERSION;

    /// @notice The domain separator computed upon initialization
    bytes32 internal INITIAL_DOMAIN_SEPARATOR;

    /// @notice The chain id upon initialization
    uint256 internal INITIAL_CHAIN_ID;

    /// @notice The account nonces
    /// @dev Account => Nonce
    mapping(address => uint256) internal nonces;

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @dev Initializes EIP-712 support
    /// @param _name The EIP-712 domain name
    /// @param _version The EIP-712 domain version
    function __EIP712_init(string memory _name, string memory _version) internal onlyInitializing {
        HASHED_NAME = keccak256(bytes(_name));
        HASHED_VERSION = keccak256(bytes(_version));

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
    }

    /// @notice The current nonce for an account
    /// @param _account The account address
    function nonce(address _account) external view returns (uint256) {
        return nonces[_account];
    }

    /// @notice The EIP-712 domain separator
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
    }

    /// @dev Computes the EIP-712 domain separator
    function _computeDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_TYPEHASH, HASHED_NAME, HASHED_VERSION, block.chainid, address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IInitializable } from "../interfaces/IInitializable.sol";
import { Address } from "../utils/Address.sol";

/// @title Initializable
/// @author Rohan Kulkarni
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (proxy/utils/Initializable.sol)
/// - Uses custom errors declared in IInitializable
abstract contract Initializable is IInitializable {
    ///                                                          ///
    ///                           STORAGE                        ///
    ///                                                          ///

    /// @dev Indicates the contract has been initialized
    uint8 internal _initialized;

    /// @dev Indicates the contract is being initialized
    bool internal _initializing;

    ///                                                          ///
    ///                          MODIFIERS                       ///
    ///                                                          ///

    /// @dev Ensures an initialization function is only called within an `initializer` or `reinitializer` function
    modifier onlyInitializing() {
        if (!_initializing) revert NOT_INITIALIZING();
        _;
    }

    /// @dev Enables initializing upgradeable contracts
    modifier initializer() {
        bool isTopLevelCall = !_initializing;

        if ((!isTopLevelCall || _initialized != 0) && (Address.isContract(address(this)) || _initialized != 1)) revert ALREADY_INITIALIZED();

        _initialized = 1;

        if (isTopLevelCall) {
            _initializing = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;

            emit Initialized(1);
        }
    }

    /// @dev Enables initializer versioning
    /// @param _version The version to set
    modifier reinitializer(uint8 _version) {
        if (_initializing || _initialized >= _version) revert ALREADY_INITIALIZED();

        _initialized = _version;

        _initializing = true;

        _;

        _initializing = false;

        emit Initialized(_version);
    }

    ///                                                          ///
    ///                          FUNCTIONS                       ///
    ///                                                          ///

    /// @dev Prevents future initialization
    function _disableInitializers() internal virtual {
        if (_initializing) revert INITIALIZING();

        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;

            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IOwnable } from "../interfaces/IOwnable.sol";
import { Initializable } from "../utils/Initializable.sol";

/// @title Ownable
/// @author Rohan Kulkarni
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (access/OwnableUpgradeable.sol)
/// - Uses custom errors declared in IOwnable
/// - Adds optional two-step ownership transfer (`safeTransferOwnership` + `acceptOwnership`)
abstract contract Ownable is IOwnable, Initializable {
    ///                                                          ///
    ///                            STORAGE                       ///
    ///                                                          ///

    /// @dev The address of the owner
    address internal _owner;

    /// @dev The address of the pending owner
    address internal _pendingOwner;

    ///                                                          ///
    ///                           MODIFIERS                      ///
    ///                                                          ///

    /// @dev Ensures the caller is the owner
    modifier onlyOwner() {
        if (msg.sender != _owner) revert ONLY_OWNER();
        _;
    }

    /// @dev Ensures the caller is the pending owner
    modifier onlyPendingOwner() {
        if (msg.sender != _pendingOwner) revert ONLY_PENDING_OWNER();
        _;
    }

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @dev Initializes contract ownership
    /// @param _initialOwner The initial owner address
    function __Ownable_init(address _initialOwner) internal onlyInitializing {
        _owner = _initialOwner;

        emit OwnerUpdated(address(0), _initialOwner);
    }

    /// @notice The address of the owner
    function owner() public virtual view returns (address) {
        return _owner;
    }

    /// @notice The address of the pending owner
    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    /// @notice Forces an ownership transfer from the last owner
    /// @param _newOwner The new owner address
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /// @notice Forces an ownership transfer from any sender
    /// @param _newOwner New owner to transfer contract to
    /// @dev Ensure is called only from trusted internal code, no access control checks.
    function _transferOwnership(address _newOwner) internal {
        emit OwnerUpdated(_owner, _newOwner);

        _owner = _newOwner;

        if (_pendingOwner != address(0)) delete _pendingOwner;
    }

    /// @notice Initiates a two-step ownership transfer
    /// @param _newOwner The new owner address
    function safeTransferOwnership(address _newOwner) public onlyOwner {
        _pendingOwner = _newOwner;

        emit OwnerPending(_owner, _newOwner);
    }

    /// @notice Accepts an ownership transfer
    function acceptOwnership() public onlyPendingOwner {
        emit OwnerUpdated(_owner, msg.sender);

        _owner = _pendingOwner;

        delete _pendingOwner;
    }

    /// @notice Cancels a pending ownership transfer
    function cancelOwnershipTransfer() public onlyOwner {
        emit OwnerCanceled(_owner, _pendingOwner);

        delete _pendingOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Initializable } from "../utils/Initializable.sol";

/// @notice Modified from OpenZeppelin Contracts v4.7.3 (security/ReentrancyGuardUpgradeable.sol)
/// - Uses custom error `REENTRANCY()`
abstract contract ReentrancyGuard is Initializable {
    ///                                                          ///
    ///                            STORAGE                       ///
    ///                                                          ///

    /// @dev Indicates a function has not been entered
    uint256 internal constant _NOT_ENTERED = 1;

    /// @dev Indicates a function has been entered
    uint256 internal constant _ENTERED = 2;

    /// @notice The reentrancy status of a function
    uint256 internal _status;

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if attempted reentrancy
    error REENTRANCY();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @dev Initializes the reentrancy guard
    function __ReentrancyGuard_init() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /// @dev Ensures a function cannot be reentered
    modifier nonReentrant() {
        if (_status == _ENTERED) revert REENTRANCY();

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @notice Modified from OpenZeppelin Contracts v4.7.3 (utils/math/SafeCast.sol)
/// - Uses custom error `UNSAFE_CAST()`
library SafeCast {
    error UNSAFE_CAST();

    function toUint128(uint256 x) internal pure returns (uint128) {
        if (x > type(uint128).max) revert UNSAFE_CAST();

        return uint128(x);
    }

    function toUint64(uint256 x) internal pure returns (uint64) {
        if (x > type(uint64).max) revert UNSAFE_CAST();

        return uint64(x);
    }

    function toUint48(uint256 x) internal pure returns (uint48) {
        if (x > type(uint48).max) revert UNSAFE_CAST();

        return uint48(x);
    }

    function toUint40(uint256 x) internal pure returns (uint40) {
        if (x > type(uint40).max) revert UNSAFE_CAST();

        return uint40(x);
    }

    function toUint32(uint256 x) internal pure returns (uint32) {
        if (x > type(uint32).max) revert UNSAFE_CAST();

        return uint32(x);
    }

    function toUint16(uint256 x) internal pure returns (uint16) {
        if (x > type(uint16).max) revert UNSAFE_CAST();

        return uint16(x);
    }

    function toUint8(uint256 x) internal pure returns (uint8) {
        if (x > type(uint8).max) revert UNSAFE_CAST();

        return uint8(x);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Modified from OpenZeppelin Contracts v4.7.3 (token/ERC721/utils/ERC721Holder.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

/// @notice Modified from OpenZeppelin Contracts v4.7.3 (token/ERC1155/utils/ERC1155Holder.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IUUPS } from "../lib/interfaces/IUUPS.sol";
import { IOwnable } from "../lib/interfaces/IOwnable.sol";

/// @title IManager
/// @author Rohan Kulkarni
/// @notice The external Manager events, errors, structs and functions
interface IManager is IUUPS, IOwnable {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when a DAO is deployed
    /// @param token The ERC-721 token address
    /// @param metadata The metadata renderer address
    /// @param auction The auction address
    /// @param treasury The treasury address
    /// @param governor The governor address
    event DAODeployed(address token, address metadata, address auction, address treasury, address governor);

    /// @notice Emitted when an upgrade is registered by the Builder DAO
    /// @param baseImpl The base implementation address
    /// @param upgradeImpl The upgrade implementation address
    event UpgradeRegistered(address baseImpl, address upgradeImpl);

    /// @notice Emitted when an upgrade is unregistered by the Builder DAO
    /// @param baseImpl The base implementation address
    /// @param upgradeImpl The upgrade implementation address
    event UpgradeRemoved(address baseImpl, address upgradeImpl);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if at least one founder is not provided upon deploy
    error FOUNDER_REQUIRED();

    ///                                                          ///
    ///                            STRUCTS                       ///
    ///                                                          ///

    /// @notice The founder parameters
    /// @param wallet The wallet address
    /// @param ownershipPct The percent ownership of the token
    /// @param vestExpiry The timestamp that vesting expires
    struct FounderParams {
        address wallet;
        uint256 ownershipPct;
        uint256 vestExpiry;
    }

    /// @notice DAO Version Information information struct
    struct DAOVersionInfo {
        string token;
        string metadata;
        string auction;
        string treasury;
        string governor; 
    }

    /// @notice The ERC-721 token parameters
    /// @param initStrings The encoded token name, symbol, collection description, collection image uri, renderer base uri
    struct TokenParams {
        bytes initStrings;
    }

    /// @notice The auction parameters
    /// @param reservePrice The reserve price of each auction
    /// @param duration The duration of each auction
    struct AuctionParams {
        uint256 reservePrice;
        uint256 duration;
    }

    /// @notice The governance parameters
    /// @param timelockDelay The time delay to execute a queued transaction
    /// @param votingDelay The time delay to vote on a created proposal
    /// @param votingPeriod The time period to vote on a proposal
    /// @param proposalThresholdBps The basis points of the token supply required to create a proposal
    /// @param quorumThresholdBps The basis points of the token supply required to reach quorum
    /// @param vetoer The address authorized to veto proposals (address(0) if none desired)
    struct GovParams {
        uint256 timelockDelay;
        uint256 votingDelay;
        uint256 votingPeriod;
        uint256 proposalThresholdBps;
        uint256 quorumThresholdBps;
        address vetoer;
    }

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice The token implementation address
    function tokenImpl() external view returns (address);

    /// @notice The metadata renderer implementation address
    function metadataImpl() external view returns (address);

    /// @notice The auction house implementation address
    function auctionImpl() external view returns (address);

    /// @notice The treasury implementation address
    function treasuryImpl() external view returns (address);

    /// @notice The governor implementation address
    function governorImpl() external view returns (address);

    /// @notice Deploys a DAO with custom token, auction, and governance settings
    /// @param founderParams The DAO founder(s)
    /// @param tokenParams The ERC-721 token settings
    /// @param auctionParams The auction settings
    /// @param govParams The governance settings
    function deploy(
        FounderParams[] calldata founderParams,
        TokenParams calldata tokenParams,
        AuctionParams calldata auctionParams,
        GovParams calldata govParams
    )
        external
        returns (
            address token,
            address metadataRenderer,
            address auction,
            address treasury,
            address governor
        );

    /// @notice A DAO's remaining contract addresses from its token address
    /// @param token The ERC-721 token address
    function getAddresses(address token)
        external
        returns (
            address metadataRenderer,
            address auction,
            address treasury,
            address governor
        );

    /// @notice If an implementation is registered by the Builder DAO as an optional upgrade
    /// @param baseImpl The base implementation address
    /// @param upgradeImpl The upgrade implementation address
    function isRegisteredUpgrade(address baseImpl, address upgradeImpl) external view returns (bool);

    /// @notice Called by the Builder DAO to offer opt-in implementation upgrades for all other DAOs
    /// @param baseImpl The base implementation address
    /// @param upgradeImpl The upgrade implementation address
    function registerUpgrade(address baseImpl, address upgradeImpl) external;

    /// @notice Called by the Builder DAO to remove an upgrade
    /// @param baseImpl The base implementation address
    /// @param upgradeImpl The upgrade implementation address
    function removeUpgrade(address baseImpl, address upgradeImpl) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IUUPS } from "../lib/interfaces/IUUPS.sol";
import { IERC721Votes } from "../lib/interfaces/IERC721Votes.sol";
import { IManager } from "../manager/IManager.sol";
import { TokenTypesV1 } from "./types/TokenTypesV1.sol";

/// @title IToken
/// @author Rohan Kulkarni
/// @notice The external Token events, errors and functions
interface IToken is IUUPS, IERC721Votes, TokenTypesV1 {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when a token is scheduled to be allocated
    /// @param baseTokenId The
    /// @param founderId The founder's id
    /// @param founder The founder's vesting details
    event MintScheduled(uint256 baseTokenId, uint256 founderId, Founder founder);

    /// @notice Emitted when a token allocation is unscheduled (removed)
    /// @param baseTokenId The token ID % 100
    /// @param founderId The founder's id
    /// @param founder The founder's vesting details
    event MintUnscheduled(uint256 baseTokenId, uint256 founderId, Founder founder);

    /// @notice Emitted when a tokens founders are deleted from storage
    /// @param newFounders the list of founders
    event FounderAllocationsCleared(IManager.FounderParams[] newFounders);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if the founder ownership exceeds 100 percent
    error INVALID_FOUNDER_OWNERSHIP();

    /// @dev Reverts if the caller was not the auction contract
    error ONLY_AUCTION();

    /// @dev Reverts if no metadata was generated upon mint
    error NO_METADATA_GENERATED();

    /// @dev Reverts if the caller was not the contract manager
    error ONLY_MANAGER();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice Initializes a DAO's ERC-721 token
    /// @param founders The founding members to receive vesting allocations
    /// @param initStrings The encoded token and metadata initialization strings
    /// @param metadataRenderer The token's metadata renderer
    /// @param auction The token's auction house
    function initialize(
        IManager.FounderParams[] calldata founders,
        bytes calldata initStrings,
        address metadataRenderer,
        address auction,
        address initialOwner
    ) external;

    /// @notice Mints tokens to the auction house for bidding and handles founder vesting
    function mint() external returns (uint256 tokenId);

    /// @notice Burns a token that did not see any bids
    /// @param tokenId The ERC-721 token id
    function burn(uint256 tokenId) external;

    /// @notice The URI for a token
    /// @param tokenId The ERC-721 token id
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /// @notice The URI for the contract
    function contractURI() external view returns (string memory);

    /// @notice The number of founders
    function totalFounders() external view returns (uint256);

    /// @notice The founders total percent ownership
    function totalFounderOwnership() external view returns (uint256);

    /// @notice The vesting details of a founder
    /// @param founderId The founder id
    function getFounder(uint256 founderId) external view returns (Founder memory);

    /// @notice The vesting details of all founders
    function getFounders() external view returns (Founder[] memory);

    /// @notice Update the list of allocation owners
    /// @param newFounders the full list of FounderParam structs
    function updateFounders(IManager.FounderParams[] calldata newFounders) external;                                                         
       

    /// @notice The founder scheduled to receive the given token id
    /// NOTE: If a founder is returned, there's no guarantee they'll receive the token as vesting expiration is not considered
    /// @param tokenId The ERC-721 token id
    function getScheduledRecipient(uint256 tokenId) external view returns (Founder memory);

    /// @notice The total supply of tokens
    function totalSupply() external view returns (uint256);

    /// @notice The token's auction house
    function auction() external view returns (address);

    /// @notice The token's metadata renderer
    function metadataRenderer() external view returns (address);

    /// @notice The owner of the token and metadata renderer
    function owner() external view returns (address);

    /// @notice Callback called by auction on first auction started to transfer ownership to treasury from founder
    function onFirstAuctionStarted() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { UUPS } from "../lib/proxy/UUPS.sol";
import { ReentrancyGuard } from "../lib/utils/ReentrancyGuard.sol";
import { ERC721Votes } from "../lib/token/ERC721Votes.sol";
import { ERC721 } from "../lib/token/ERC721.sol";
import { Ownable } from "../lib/utils/Ownable.sol";
import { TokenStorageV1 } from "./storage/TokenStorageV1.sol";
import { IBaseMetadata } from "./metadata/interfaces/IBaseMetadata.sol";
import { IManager } from "../manager/IManager.sol";
import { IAuction } from "../auction/IAuction.sol";
import { IToken } from "./IToken.sol";
import { VersionedContract } from "../VersionedContract.sol";

/// @title Token
/// @author Rohan Kulkarni
/// @custom:repo github.com/ourzora/nouns-protocol 
/// @notice A DAO's ERC-721 governance token
contract Token is IToken, VersionedContract, UUPS, Ownable, ReentrancyGuard, ERC721Votes, TokenStorageV1 {
    ///                                                          ///
    ///                         IMMUTABLES                       ///
    ///                                                          ///

    /// @notice The contract upgrade manager
    IManager private immutable manager;

    ///                                                          ///
    ///                         CONSTRUCTOR                      ///
    ///                                                          ///

    /// @param _manager The contract upgrade manager address
    constructor(address _manager) payable initializer {
        manager = IManager(_manager);
    }

    ///                                                          ///
    ///                         INITIALIZER                      ///
    ///                                                          ///

    /// @notice Initializes a DAO's ERC-721 token contract
    /// @param _founders The DAO founders
    /// @param _initStrings The encoded token and metadata initialization strings
    /// @param _metadataRenderer The token's metadata renderer
    /// @param _auction The token's auction house
    /// @param _initialOwner The initial owner of the token
    function initialize(
        IManager.FounderParams[] calldata _founders,
        bytes calldata _initStrings,
        address _metadataRenderer,
        address _auction,
        address _initialOwner
    ) external initializer {
        // Ensure the caller is the contract manager
        if (msg.sender != address(manager)) {
            revert ONLY_MANAGER();
        }

        // Initialize the reentrancy guard
        __ReentrancyGuard_init();

        // Setup ownable
        __Ownable_init(_initialOwner);

        // Store the founders and compute their allocations
        _addFounders(_founders);

        // Decode the token name and symbol
        (string memory _name, string memory _symbol, , , , ) = abi.decode(_initStrings, (string, string, string, string, string, string));

        // Initialize the ERC-721 token
        __ERC721_init(_name, _symbol);

        // Store the metadata renderer and auction house
        settings.metadataRenderer = IBaseMetadata(_metadataRenderer);
        settings.auction = _auction;
    }

    /// @notice Called by the auction upon the first unpause / token mint to transfer ownership from founder to treasury
    /// @dev Only callable by the auction contract
    function onFirstAuctionStarted() external override {
        if (msg.sender != settings.auction) {
            revert ONLY_AUCTION();
        }

        // Force transfer ownership to the treasury
        _transferOwnership(IAuction(settings.auction).treasury());
    }

    /// @notice Called upon initialization to add founders and compute their vesting allocations
    /// @dev We do this by reserving an mapping of [0-100] token indices, such that if a new token mint ID % 100 is reserved, it's sent to the appropriate founder.
    /// @param _founders The list of DAO founders
    function _addFounders(IManager.FounderParams[] calldata _founders) internal {
        // Used to store the total percent ownership among the founders
        uint256 totalOwnership;

        uint8 numFoundersAdded = 0;

        unchecked {
            // For each founder:
            for (uint256 i; i < _founders.length; ++i) {
                // Cache the percent ownership
                uint256 founderPct = _founders[i].ownershipPct;

                // Continue if no ownership is specified
                if (founderPct == 0) {
                    continue;
                }

                // Update the total ownership and ensure it's valid
                totalOwnership += founderPct;

                // Check that founders own less than 100% of tokens
                if (totalOwnership > 99) {
                    revert INVALID_FOUNDER_OWNERSHIP();
                }

                // Compute the founder's id
                uint256 founderId = numFoundersAdded++;

                // Get the pointer to store the founder
                Founder storage newFounder = founder[founderId];

                // Store the founder's vesting details
                newFounder.wallet = _founders[i].wallet;
                newFounder.vestExpiry = uint32(_founders[i].vestExpiry);
                // Total ownership cannot be above 100 so this fits safely in uint8
                newFounder.ownershipPct = uint8(founderPct);

                // Compute the vesting schedule
                uint256 schedule = 100 / founderPct;

                // Used to store the base token id the founder will recieve
                uint256 baseTokenId;

                // For each token to vest:
                for (uint256 j; j < founderPct; ++j) {
                    // Get the available token id
                    baseTokenId = _getNextTokenId(baseTokenId);

                    // Store the founder as the recipient
                    tokenRecipient[baseTokenId] = newFounder;

                    emit MintScheduled(baseTokenId, founderId, newFounder);

                    // Update the base token id
                    baseTokenId = (baseTokenId + schedule) % 100;
                }
            }

            // Store the founders' details
            settings.totalOwnership = uint8(totalOwnership);
            settings.numFounders = numFoundersAdded;
        }
    }

    /// @dev Finds the next available base token id for a founder
    /// @param _tokenId The ERC-721 token id
    function _getNextTokenId(uint256 _tokenId) internal view returns (uint256) {
        unchecked {
            while (tokenRecipient[_tokenId].wallet != address(0)) {
                _tokenId = (++_tokenId) % 100;
            }

            return _tokenId;
        }
    }

    ///                                                          ///
    ///                             MINT                         ///
    ///                                                          ///

    /// @notice Mints tokens to the auction house for bidding and handles founder vesting
    function mint() external nonReentrant returns (uint256 tokenId) {
        // Cache the auction address
        address minter = settings.auction;

        // Ensure the caller is the auction
        if (msg.sender != minter) {
            revert ONLY_AUCTION();
        }

        // Cannot realistically overflow
        unchecked {
            do {
                // Get the next token to mint
                tokenId = settings.mintCount++;

                // Lookup whether the token is for a founder, and mint accordingly if so
            } while (_isForFounder(tokenId));
        }

        // Mint the next available token to the auction house for bidding
        _mint(minter, tokenId);
    }

    /// @dev Overrides _mint to include attribute generation
    /// @param _to The token recipient
    /// @param _tokenId The ERC-721 token id
    function _mint(address _to, uint256 _tokenId) internal override {
        // Mint the token
        super._mint(_to, _tokenId);

        // Increment the total supply
        unchecked {
            ++settings.totalSupply;
        }

        // Generate the token attributes
        if (!settings.metadataRenderer.onMinted(_tokenId)) revert NO_METADATA_GENERATED();
    }

    /// @dev Checks if a given token is for a founder and mints accordingly
    /// @param _tokenId The ERC-721 token id
    function _isForFounder(uint256 _tokenId) private returns (bool) {
        // Get the base token id
        uint256 baseTokenId = _tokenId % 100;

        // If there is no scheduled recipient:
        if (tokenRecipient[baseTokenId].wallet == address(0)) {
            return false;

            // Else if the founder is still vesting:
        } else if (block.timestamp < tokenRecipient[baseTokenId].vestExpiry) {
            // Mint the token to the founder
            _mint(tokenRecipient[baseTokenId].wallet, _tokenId);

            return true;

            // Else the founder has finished vesting:
        } else {
            // Remove them from future lookups
            delete tokenRecipient[baseTokenId];

            return false;
        }
    }

    ///                                                          ///
    ///                             BURN                         ///
    ///                                                          ///

    /// @notice Burns a token that did not see any bids
    /// @param _tokenId The ERC-721 token id
    function burn(uint256 _tokenId) external {
        // Ensure the caller is the auction house
        if (msg.sender != settings.auction) {
            revert ONLY_AUCTION();
        }

        // Burn the token
        _burn(_tokenId);
    }

    function _burn(uint256 _tokenId) internal override {
        super._burn(_tokenId);

        unchecked {
            --settings.totalSupply;
        }
    }

    ///                                                          ///
    ///                           METADATA                       ///
    ///                                                          ///

    /// @notice The URI for a token
    /// @param _tokenId The ERC-721 token id
    function tokenURI(uint256 _tokenId) public view override(IToken, ERC721) returns (string memory) {
        return settings.metadataRenderer.tokenURI(_tokenId);
    }

    /// @notice The URI for the contract
    function contractURI() public view override(IToken, ERC721) returns (string memory) {
        return settings.metadataRenderer.contractURI();
    }

    ///                                                          ///
    ///                           FOUNDERS                       ///
    ///                                                          ///

    /// @notice The number of founders
    function totalFounders() external view returns (uint256) {
        return settings.numFounders;
    }

    /// @notice The founders total percent ownership
    function totalFounderOwnership() external view returns (uint256) {
        return settings.totalOwnership;
    }

    /// @notice The vesting details of a founder
    /// @param _founderId The founder id
    function getFounder(uint256 _founderId) external view returns (Founder memory) {
        return founder[_founderId];
    }

    /// @notice The vesting details of all founders
    function getFounders() external view returns (Founder[] memory) {
        // Cache the number of founders
        uint256 numFounders = settings.numFounders;

        // Get a temporary array to hold all founders
        Founder[] memory founders = new Founder[](numFounders);

        // Cannot realistically overflow
        unchecked {
            // Add each founder to the array
            for (uint256 i; i < numFounders; ++i) {
                founders[i] = founder[i];
            }
        }

        return founders;
    }

    /// @notice The founder scheduled to receive the given token id
    /// NOTE: If a founder is returned, there's no guarantee they'll receive the token as vesting expiration is not considered
    /// @param _tokenId The ERC-721 token id
    function getScheduledRecipient(uint256 _tokenId) external view returns (Founder memory) {
        return tokenRecipient[_tokenId % 100];
    }

    /// @notice Update the list of allocation owners
    /// @param newFounders the full list of founders
    function updateFounders(IManager.FounderParams[] calldata newFounders) external onlyOwner {
        // Cache the number of founders
        uint256 numFounders = settings.numFounders;

        // Get a temporary array to hold all founders
        Founder[] memory cachedFounders = new Founder[](numFounders);

        // Cannot realistically overflow
        unchecked {
            // Add each founder to the array
            for (uint256 i; i < numFounders; ++i) {
                cachedFounders[i] = founder[i];
            }
        }

        // Keep a mapping of all the reserved token IDs we're set to clear.
        bool[] memory clearedTokenIds = new bool[](100);

        unchecked {
            // for each existing founder:
            for (uint256 i; i < cachedFounders.length; ++i) {
                // copy the founder into memory
                Founder memory cachedFounder = cachedFounders[i];

                // Delete the founder from the stored mapping
                delete founder[i];

                // Some DAOs were initialized with 0 percentage ownership.
                // This skips them to avoid a division by zero error.
                if (cachedFounder.ownershipPct == 0) {
                    continue;
                }

                // using the ownership percentage, get reserved token percentages
                uint256 schedule = 100 / cachedFounder.ownershipPct;

                // Used to reverse engineer the indices the founder has reserved tokens in.
                uint256 baseTokenId;

                for (uint256 j; j < cachedFounder.ownershipPct; ++j) {
                    // Get the next index that hasn't already been cleared
                    while (clearedTokenIds[baseTokenId] != false) {
                        baseTokenId = (++baseTokenId) % 100;
                    }

                    delete tokenRecipient[baseTokenId];
                    clearedTokenIds[baseTokenId] = true;

                    emit MintUnscheduled(baseTokenId, i, cachedFounder);

                    // Update the base token id
                    baseTokenId = (baseTokenId + schedule) % 100;
                }
            }
        }

        settings.numFounders = 0;
        settings.totalOwnership = 0;
        emit FounderAllocationsCleared(newFounders);

        _addFounders(newFounders);
    }

    ///                                                          ///
    ///                           SETTINGS                       ///
    ///                                                          ///

    /// @notice The total supply of tokens
    function totalSupply() external view returns (uint256) {
        return settings.totalSupply;
    }

    /// @notice The address of the auction house
    function auction() external view returns (address) {
        return settings.auction;
    }

    /// @notice The address of the metadata renderer
    function metadataRenderer() external view returns (address) {
        return address(settings.metadataRenderer);
    }

    function owner() public view override(IToken, Ownable) returns (address) {
        return super.owner();
    }

    ///                                                          ///
    ///                         TOKEN UPGRADE                    ///
    ///                                                          ///

    /// @notice Ensures the caller is authorized to upgrade the contract and that the new implementation is valid
    /// @dev This function is called in `upgradeTo` & `upgradeToAndCall`
    /// @param _newImpl The new implementation address
    function _authorizeUpgrade(address _newImpl) internal view override {
        // Ensure the caller is the shared owner of the token and metadata renderer
        if (msg.sender != owner()) revert ONLY_OWNER();

        // Ensure the implementation is valid
        if (!manager.isRegisteredUpgrade(_getImplementation(), _newImpl)) revert INVALID_UPGRADE(_newImpl);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IUUPS } from "../../../lib/interfaces/IUUPS.sol";


/// @title IBaseMetadata
/// @author Rohan Kulkarni
/// @notice The external Base Metadata errors and functions
interface IBaseMetadata is IUUPS {
    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if the caller was not the contract manager
    error ONLY_MANAGER();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice Initializes a DAO's token metadata renderer
    /// @param initStrings The encoded token and metadata initialization strings
    /// @param token The associated ERC-721 token address
    function initialize(
        bytes calldata initStrings,
        address token
    ) external;

    /// @notice Generates attributes for a token upon mint
    /// @param tokenId The ERC-721 token id
    function onMinted(uint256 tokenId) external returns (bool);

    /// @notice The token URI
    /// @param tokenId The ERC-721 token id
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /// @notice The contract URI
    function contractURI() external view returns (string memory);

    /// @notice The associated ERC-721 token
    function token() external view returns (address);

    /// @notice Get metadata owner address
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { TokenTypesV1 } from "../types/TokenTypesV1.sol";

/// @title TokenStorageV1
/// @author Rohan Kulkarni
/// @notice The Token storage contract
contract TokenStorageV1 is TokenTypesV1 {
    /// @notice The token settings
    Settings internal settings;

    /// @notice The vesting details of a founder
    /// @dev Founder id => Founder
    mapping(uint256 => Founder) internal founder;

    /// @notice The recipient of a token
    /// @dev ERC-721 token id => Founder
    mapping(uint256 => Founder) internal tokenRecipient;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IBaseMetadata } from "../metadata/interfaces/IBaseMetadata.sol";

/// @title TokenTypesV1
/// @author Rohan Kulkarni
/// @notice The Token custom data types
interface TokenTypesV1 {
    /// @notice The settings type
    /// @param auction The DAO auction house
    /// @param totalSupply The number of active tokens
    /// @param numFounders The number of vesting recipients
    /// @param metadatarenderer The token metadata renderer
    /// @param mintCount The number of minted tokens
    /// @param totalPercentage The total percentage owned by founders
    struct Settings {
        address auction;
        uint88 totalSupply;
        uint8 numFounders;
        IBaseMetadata metadataRenderer;
        uint88 mintCount;
        uint8 totalOwnership;
    }

    /// @notice The founder type
    /// @param wallet The address where tokens are sent
    /// @param ownershipPct The percentage of token ownership
    /// @param vestExpiry The timestamp when vesting ends
    struct Founder {
        address wallet;
        uint8 ownershipPct;
        uint32 vestExpiry;
    }
}