// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "./IGovernor.sol";
import "./GovernorStorage.sol";

contract GovernorCharlieDelegator is GovernorCharlieDelegatorStorage, GovernorCharlieEvents, IGovernorCharlieDelegator {
  constructor(
    address ipt_,
    address implementation_,
    uint256 votingPeriod_,
    uint256 votingDelay_,
    uint256 proposalThreshold_,
    uint256 proposalTimelockDelay_,
    uint256 quorumVotes_,
    uint256 emergencyQuorumVotes_,
    uint256 emergencyVotingPeriod_,
    uint256 emergencyTimelockDelay_
  ) {
    delegateTo(
      implementation_,
      abi.encodeWithSignature(
        "initialize(address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)",
        ipt_,
        votingPeriod_,
        votingDelay_,
        proposalThreshold_,
        proposalTimelockDelay_,
        quorumVotes_,
        emergencyQuorumVotes_,
        emergencyVotingPeriod_,
        emergencyTimelockDelay_
      )
    );
    address oldImplementation = implementation;
    implementation = implementation_;
    emit NewImplementation(oldImplementation, implementation);
  }

  /**
   * @notice Called by itself via governance to update the implementation of the delegator
   * @param implementation_ The address of the new implementation for delegation
   */
  function _setImplementation(address implementation_) public override {
    require(msg.sender == address(this), "governance proposal required");
    require(implementation_ != address(0), "invalid implementation address");

    address oldImplementation = implementation;
    implementation = implementation_;

    emit NewImplementation(oldImplementation, implementation);
  }

  /**
   * @notice Internal method to delegate execution to another contract
   * @dev It returns to the external caller whatever the implementation returns or forwards reverts
   * @param callee The contract to delegatecall
   * @param data The raw data to delegatecall
   */
  function delegateTo(address callee, bytes memory data) internal {
    //solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returnData) = callee.delegatecall(data);
    //solhint-disable-next-line no-inline-assembly
    assembly {
      if eq(success, 0) {
        revert(add(returnData, 0x20), returndatasize())
      }
    }
  }

  /**
   * @dev Delegates execution to an implementation contract.
   * It returns to the external caller whatever the implementation returns
   * or forwards reverts.
   */
  // solhint-disable-next-line no-complex-fallback
  fallback() external payable override {
    // delegate all other functions to current implementation
    //solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = implementation.delegatecall(msg.data);

    //solhint-disable-next-line no-inline-assembly
    assembly {
      let free_mem_ptr := mload(0x40)
      returndatacopy(free_mem_ptr, 0, returndatasize())

      switch success
      case 0 {
        revert(free_mem_ptr, returndatasize())
      }
      default {
        return(free_mem_ptr, returndatasize())
      }
    }
  }

  receive() external payable override {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Structs.sol";

/// @title interface to interact with TokenDelgator
interface IGovernorCharlieDelegator {
  function _setImplementation(address implementation_) external;

  fallback() external payable;

  receive() external payable;
}

/// @title interface to interact with TokenDelgate
interface IGovernorCharlieDelegate {
  function initialize(
    address ipt_,
    uint256 votingPeriod_,
    uint256 votingDelay_,
    uint256 proposalThreshold_,
    uint256 proposalTimelockDelay_,
    uint256 quorumVotes_,
    uint256 emergencyQuorumVotes_,
    uint256 emergencyVotingPeriod_,
    uint256 emergencyTimelockDelay_
  ) external;

  function propose(
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    string memory description,
    bool emergency
  ) external returns (uint256);

  function queue(uint256 proposalId) external;

  function execute(uint256 proposalId) external payable;

  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) external payable;

  function cancel(uint256 proposalId) external;

  function getActions(uint256 proposalId)
    external
    view
    returns (
      address[] memory targets,
      uint256[] memory values,
      string[] memory signatures,
      bytes[] memory calldatas
    );

  function getReceipt(uint256 proposalId, address voter) external view returns (Receipt memory);

  function state(uint256 proposalId) external view returns (ProposalState);

  function castVote(uint256 proposalId, uint8 support) external;

  function castVoteWithReason(
    uint256 proposalId,
    uint8 support,
    string calldata reason
  ) external;

  function castVoteBySig(
    uint256 proposalId,
    uint8 support,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function isWhitelisted(address account) external view returns (bool);

  function _setDelay(uint256 proposalTimelockDelay_) external;

  function _setEmergencyDelay(uint256 emergencyTimelockDelay_) external;

  function _setVotingDelay(uint256 newVotingDelay) external;

  function _setVotingPeriod(uint256 newVotingPeriod) external;

  function _setEmergencyVotingPeriod(uint256 newEmergencyVotingPeriod) external;

  function _setProposalThreshold(uint256 newProposalThreshold) external;

  function _setQuorumVotes(uint256 newQuorumVotes) external;

  function _setEmergencyQuorumVotes(uint256 newEmergencyQuorumVotes) external;

  function _setWhitelistAccountExpiration(address account, uint256 expiration) external;

  function _setWhitelistGuardian(address account) external;
}

/// @title interface which contains all events emitted by delegator & delegate
interface GovernorCharlieEvents {
  /// @notice An event emitted when a new proposal is created
  event ProposalCreated(
    uint256 indexed id,
    address indexed proposer,
    address[] targets,
    uint256[] values,
    string[] signatures,
    bytes[] calldatas,
    uint256 indexed startBlock,
    uint256 endBlock,
    string description
  );

  /// @notice An event emitted when a vote has been cast on a proposal
  /// @param voter The address which casted a vote
  /// @param proposalId The proposal id which was voted on
  /// @param support Support value for the vote. 0=against, 1=for, 2=abstain
  /// @param votes Number of votes which were cast by the voter
  /// @param reason The reason given for the vote by the voter
  event VoteCast(address indexed voter, uint256 indexed proposalId, uint8 support, uint256 votes, string reason);

  /// @notice An event emitted when a proposal has been canceled
  event ProposalCanceled(uint256 indexed id);

  /// @notice An event emitted when a proposal has been queued in the Timelock
  event ProposalQueued(uint256 indexed id, uint256 eta);

  /// @notice An event emitted when a proposal has been executed in the Timelock
  event ProposalExecuted(uint256 indexed id);

  /// @notice An event emitted when the voting delay is set
  event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);

  /// @notice An event emitted when the voting period is set
  event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);

  /// @notice An event emitted when the emergency voting period is set
  event EmergencyVotingPeriodSet(uint256 oldEmergencyVotingPeriod, uint256 emergencyVotingPeriod);

  /// @notice Emitted when implementation is changed
  event NewImplementation(address oldImplementation, address newImplementation);

  /// @notice Emitted when proposal threshold is set
  event ProposalThresholdSet(uint256 oldProposalThreshold, uint256 newProposalThreshold);

  /// @notice Emitted when pendingAdmin is changed
  event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

  /// @notice Emitted when pendingAdmin is accepted, which means admin is updated
  event NewAdmin(address oldAdmin, address newAdmin);

  /// @notice Emitted when whitelist account expiration is set
  event WhitelistAccountExpirationSet(address account, uint256 expiration);

  /// @notice Emitted when the whitelistGuardian is set
  event WhitelistGuardianSet(address oldGuardian, address newGuardian);

  /// @notice Emitted when the a new delay is set
  event NewDelay(uint256 oldTimelockDelay, uint256 proposalTimelockDelay);

  /// @notice Emitted when the a new emergency delay is set
  event NewEmergencyDelay(uint256 oldEmergencyTimelockDelay, uint256 emergencyTimelockDelay);

  /// @notice Emitted when the quorum is updated
  event NewQuorum(uint256 oldQuorumVotes, uint256 quorumVotes);

  /// @notice Emitted when the emergency quorum is updated
  event NewEmergencyQuorum(uint256 oldEmergencyQuorumVotes, uint256 emergencyQuorumVotes);

  /// @notice Emitted when a transaction is canceled
  event CancelTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );

  /// @notice Emitted when a transaction is executed
  event ExecuteTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );

  /// @notice Emitted when a transaction is queued
  event QueueTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IIpt.sol";
import "./Structs.sol";

contract GovernorCharlieDelegatorStorage {
  /// @notice Active brains of Governor
  address public implementation;
}

/**
 * @title Storage for Governor Charlie Delegate
 * @notice For future upgrades, do not change GovernorCharlieDelegateStorage. Create a new
 * contract which implements GovernorCharlieDelegateStorage and following the naming convention
 * GovernorCharlieDelegateStorageVX.
 */
//solhint-disable-next-line max-states-count
contract GovernorCharlieDelegateStorage is GovernorCharlieDelegatorStorage {
  /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
  uint256 public quorumVotes;

  /// @notice The number of votes in support of a proposal required in order for an emergency quorum to be reached and for a vote to succeed
  uint256 public emergencyQuorumVotes;

  /// @notice The delay before voting on a proposal may take place, once proposed, in blocks
  uint256 public votingDelay;

  /// @notice The duration of voting on a proposal, in blocks
  uint256 public votingPeriod;

  /// @notice The number of votes required in order for a voter to become a proposer
  uint256 public proposalThreshold;

  /// @notice Initial proposal id set at become
  uint256 public initialProposalId;

  /// @notice The total number of proposals
  uint256 public proposalCount;

  /// @notice The address of the Interest Protocol governance token
  IIpt public ipt;

  /// @notice The official record of all proposals ever proposed
  mapping(uint256 => Proposal) public proposals;

  /// @notice The latest proposal for each proposer
  mapping(address => uint256) public latestProposalIds;

  /// @notice The latest proposal for each proposer
  mapping(bytes32 => bool) public queuedTransactions;

  /// @notice The proposal holding period
  uint256 public proposalTimelockDelay;

  /// @notice Stores the expiration of account whitelist status as a timestamp
  mapping(address => uint256) public whitelistAccountExpirations;

  /// @notice Address which manages whitelisted proposals and whitelist accounts
  address public whitelistGuardian;

  /// @notice The duration of the voting on a emergency proposal, in blocks
  uint256 public emergencyVotingPeriod;

  /// @notice The emergency proposal holding period
  uint256 public emergencyTimelockDelay;

  /// all receipts for proposal
  mapping(uint256 => mapping(address => Receipt)) public proposalReceipts;

  /// @notice The emergency proposal holding period
  bool public initialized;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

struct Proposal {
  /// @notice Unique id for looking up a proposal
  uint256 id;
  /// @notice Creator of the proposal
  address proposer;
  /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
  uint256 eta;
  /// @notice the ordered list of target addresses for calls to be made
  address[] targets;
  /// @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
  uint256[] values;
  /// @notice The ordered list of function signatures to be called
  string[] signatures;
  /// @notice The ordered list of calldata to be passed to each call
  bytes[] calldatas;
  /// @notice The block at which voting begins: holders must delegate their votes prior to this block
  uint256 startBlock;
  /// @notice The block at which voting ends: votes must be cast prior to this block
  uint256 endBlock;
  /// @notice Current number of votes in favor of this proposal
  uint256 forVotes;
  /// @notice Current number of votes in opposition to this proposal
  uint256 againstVotes;
  /// @notice Current number of votes for abstaining for this proposal
  uint256 abstainVotes;
  /// @notice Flag marking whether the proposal has been canceled
  bool canceled;
  /// @notice Flag marking whether the proposal has been executed
  bool executed;
  /// @notice Whether the proposal is an emergency proposal
  bool emergency;
  /// @notice quorum votes requires
  uint256 quorumVotes;
  /// @notice time delay
  uint256 delay;
}

/// @notice Ballot receipt record for a voter
struct Receipt {
  /// @notice Whether or not a vote has been cast
  bool hasVoted;
  /// @notice Whether or not the voter supports the proposal or abstains
  uint8 support;
  /// @notice The number of votes the voter had, which were cast
  uint96 votes;
}

/// @notice Possible states that a proposal may be in
enum ProposalState {
  Pending,
  Active,
  Canceled,
  Defeated,
  Succeeded,
  Queued,
  Expired,
  Executed
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IIpt {
  function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);
}