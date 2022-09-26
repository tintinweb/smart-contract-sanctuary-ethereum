// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IGovernanceStrategy} from './interfaces/IGovernanceStrategy.sol';
import {IAaveGovernanceV2} from './interfaces/IAaveGovernanceV2.sol';
import {IExecutor} from './interfaces/IExecutor.sol';


/**
 * @title Executor
 * @author BGD Labs
 * @notice Time Locked, Validator, Executor Contract that:
 * - Validates Proposal creations/ cancellation
 * - Validates Vote Quorum and Vote success on proposal
 * - Allows queueing, execution and cancellation of proposals' transactions.
 **/
contract Executor is IExecutor {
  address private _admin;
  address private _pendingAdmin;
  uint256 private _delay;

  // uppercase is kept even not being constant/immutables, 
  // in order to keep interface compatibility with a previous version of the Executor
  uint256 public PROPOSITION_THRESHOLD;
  uint256 public VOTING_DURATION;
  uint256 public VOTE_DIFFERENTIAL;
  uint256 public MINIMUM_QUORUM;

  mapping(bytes32 => bool) private _queuedTransactions;  

  uint256 public immutable GRACE_PERIOD;
  uint256 public immutable MINIMUM_DELAY;
  uint256 public immutable MAXIMUM_DELAY;
  uint256 public constant ONE_HUNDRED_WITH_PRECISION = 10000; // Equivalent to 100%, but scaled for precision

  /**
   * @dev Constructor
   * @param admin admin address, that can call the main functions, (Governance)
   * @param delay minimum time between queueing and execution of proposal, in seconds
   * @param gracePeriod time after `delay` while a proposal can be executed, in seconds
   * @param minimumDelay lower threshold of `delay`, in seconds
   * @param maximumDelay upper threshold of `delay`, in seconds
   * @param propositionThreshold minimum percentage of supply needed to submit a proposal
   * - In ONE_HUNDRED_WITH_PRECISION units
   * @param voteDuration duration in blocks of the voting period
   * @param voteDifferential percentage of supply that `for` votes need to be over `against`
   *   in order for the proposal to pass
   * - In ONE_HUNDRED_WITH_PRECISION units
   * @param minimumQuorum minimum percentage of the supply in FOR-voting-power need for a proposal to pass
   * - In ONE_HUNDRED_WITH_PRECISION units
   **/
  constructor(
    address admin,
    uint256 delay,
    uint256 gracePeriod,
    uint256 minimumDelay,
    uint256 maximumDelay,
    uint256 propositionThreshold,
    uint256 voteDuration,
    uint256 voteDifferential,
    uint256 minimumQuorum
  )  
  {
    require(delay >= minimumDelay, 'DELAY_SHORTER_THAN_MINIMUM');
    require(delay <= maximumDelay, 'DELAY_LONGER_THAN_MAXIMUM');
    _delay = delay;
    _admin = admin;

    require(gracePeriod > 0, 'GRACE_PERIOD_LESS_THAN_0');
    GRACE_PERIOD = gracePeriod;

    MINIMUM_DELAY = minimumDelay;
    MAXIMUM_DELAY = maximumDelay;

    emit NewDelay(delay);
    emit NewAdmin(admin);

    _updateVotingDuration(voteDuration);
    _updateVoteDifferential(voteDifferential);
    _updateMinimumQuorum(minimumQuorum);
    _updatePropositionThreshold(propositionThreshold);
  }

  /**
  * -------------------------------------------------------------
  * --------------- IExecutorWithTimelock -----------------------
  * @dev logic for queue, execute, cancel transactions voted by Governance
  * Queued transactions can be executed after a delay and until
  * Grace period is not over.
  * -------------------------------------------------------------
  */

  modifier onlyAdmin() {
    require(msg.sender == _admin, 'ONLY_BY_ADMIN');
    _;
  }

  modifier onlyPendingAdmin() {
    require(msg.sender == _pendingAdmin, 'ONLY_BY_PENDING_ADMIN');
    _;
  }

  modifier onlyExecutor {
    require(msg.sender == address(this), 'CALLER_NOT_EXECUTOR');
    _;
  }

  /// @inheritdoc IExecutor
  function setDelay(uint256 delay) external onlyExecutor {
    _validateDelay(delay);
    _delay = delay;

    emit NewDelay(delay);
  }

  /// @inheritdoc IExecutor
  function acceptAdmin() external onlyPendingAdmin {
    _admin = msg.sender;
    _pendingAdmin = address(0);

    emit NewAdmin(msg.sender);
  }

  /// @inheritdoc IExecutor
  function setPendingAdmin(address newPendingAdmin) external onlyExecutor {
    _pendingAdmin = newPendingAdmin;

    emit NewPendingAdmin(newPendingAdmin);
  }

  /// @inheritdoc IExecutor
  function queueTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external onlyAdmin returns (bytes32) {
    require(executionTime >= block.timestamp + _delay, 'EXECUTION_TIME_UNDERESTIMATED');

    bytes32 actionHash = keccak256(
      abi.encode(target, value, signature, data, executionTime, withDelegatecall)
    );
    _queuedTransactions[actionHash] = true;

    emit QueuedAction(actionHash, target, value, signature, data, executionTime, withDelegatecall);
    return actionHash;
  }

  /// @inheritdoc IExecutor
  function cancelTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external onlyAdmin returns (bytes32) {
    bytes32 actionHash = keccak256(
      abi.encode(target, value, signature, data, executionTime, withDelegatecall)
    );
    _queuedTransactions[actionHash] = false;

    emit CancelledAction(
      actionHash,
      target,
      value,
      signature,
      data,
      executionTime,
      withDelegatecall
    );
    return actionHash;
  }

  /// @inheritdoc IExecutor
  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external payable onlyAdmin returns (bytes memory) {
    bytes32 actionHash = keccak256(
      abi.encode(target, value, signature, data, executionTime, withDelegatecall)
    );
    require(_queuedTransactions[actionHash], 'ACTION_NOT_QUEUED');
    require(block.timestamp >= executionTime, 'TIMELOCK_NOT_FINISHED');
    require(block.timestamp <= executionTime + GRACE_PERIOD, 'GRACE_PERIOD_FINISHED');

    _queuedTransactions[actionHash] = false;

    bytes memory callData;

    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    bool success;
    bytes memory resultData;
    if (withDelegatecall) {
      require(msg.value >= value, 'NOT_ENOUGH_MSG_VALUE');
      // solium-disable-next-line security/no-call-value
      (success, resultData) = target.delegatecall(callData);
    } else {
      // solium-disable-next-line security/no-call-value
      (success, resultData) = target.call{value: value}(callData);
    }

    require(success, 'FAILED_ACTION_EXECUTION');

    emit ExecutedAction(
      actionHash,
      target,
      value,
      signature,
      data,
      executionTime,
      withDelegatecall,
      resultData
    );

    return resultData;
  }

  /// @inheritdoc IExecutor
  function getAdmin() external view returns (address) {
    return _admin;
  }

  /// @inheritdoc IExecutor
  function getPendingAdmin() external view returns (address) {
    return _pendingAdmin;
  }

  /// @inheritdoc IExecutor
  function getDelay() external view returns (uint256) {
    return _delay;
  }

  /// @inheritdoc IExecutor
  function isActionQueued(bytes32 actionHash) external view returns (bool) {
    return _queuedTransactions[actionHash];
  }

  /// @inheritdoc IExecutor
  function isProposalOverGracePeriod(IAaveGovernanceV2 governance, uint256 proposalId)
    external
    view
    returns (bool)
  {
    IAaveGovernanceV2.ProposalWithoutVotes memory proposal = governance.getProposalById(proposalId);

    return (block.timestamp > proposal.executionTime + GRACE_PERIOD);
  }

  receive() external payable {}

  /**
  * --------------------------------------------------------
  * ---------- Proposal Validation -------------------------
  * @dev Validates/Invalidations propositions state modifications.
  * Proposition Power functions: Validates proposition creations/ cancellation
  * Voting Power functions: Validates success of propositions.
  * --------------------------------------------------------
  */

  /// @inheritdoc IExecutor
  function updateVotingDuration(uint256 votingDuration) external onlyExecutor {
    _updateVotingDuration(votingDuration);
  }
  
  /// @inheritdoc IExecutor
  function updateVoteDifferential(uint256 voteDifferential) external onlyExecutor {
    _updateVoteDifferential(voteDifferential);
  }

  /// @inheritdoc IExecutor
  function updateMinimumQuorum(uint256 minimumQuorum) external onlyExecutor {
    _updateMinimumQuorum(minimumQuorum);
  }

  /// @inheritdoc IExecutor
  function updatePropositionThreshold(uint256 propositionThreshold) external onlyExecutor {
    _updatePropositionThreshold(propositionThreshold);
  }

  /// @inheritdoc IExecutor
  function validateCreatorOfProposal(
    IAaveGovernanceV2 governance,
    address user,
    uint256 blockNumber
  ) external view returns (bool) {
    return isPropositionPowerEnough(governance, user, blockNumber);
  }

  /// @inheritdoc IExecutor
  function validateProposalCancellation(
    IAaveGovernanceV2 governance,
    address user,
    uint256 blockNumber
  ) external view returns (bool) {
    return !isPropositionPowerEnough(governance, user, blockNumber);
  }

  /// @inheritdoc IExecutor
  function isPropositionPowerEnough(
    IAaveGovernanceV2 governance,
    address user,
    uint256 blockNumber
  ) public view returns (bool) {
    IGovernanceStrategy currentGovernanceStrategy = IGovernanceStrategy(
      governance.getGovernanceStrategy()
    );
    return
      currentGovernanceStrategy.getPropositionPowerAt(user, blockNumber) >=
      getMinimumPropositionPowerNeeded(governance, blockNumber);
  }

  /// @inheritdoc IExecutor
  function getMinimumPropositionPowerNeeded(IAaveGovernanceV2 governance, uint256 blockNumber)
    public
    view
    returns (uint256)
  {
    IGovernanceStrategy currentGovernanceStrategy = IGovernanceStrategy(
      governance.getGovernanceStrategy()
    );
    return
      currentGovernanceStrategy
        .getTotalPropositionSupplyAt(blockNumber)
        * PROPOSITION_THRESHOLD
        / ONE_HUNDRED_WITH_PRECISION;
  }

  /// @inheritdoc IExecutor
  function isProposalPassed(IAaveGovernanceV2 governance, uint256 proposalId)
    external
    view
    returns (bool)
  {
    return (isQuorumValid(governance, proposalId) &&
      isVoteDifferentialValid(governance, proposalId));
  }

  /// @inheritdoc IExecutor
  function getMinimumVotingPowerNeeded(uint256 votingSupply)
    public
    view
    returns (uint256)
  {
    return votingSupply * MINIMUM_QUORUM / ONE_HUNDRED_WITH_PRECISION;
  }

  /// @inheritdoc IExecutor
  function isQuorumValid(IAaveGovernanceV2 governance, uint256 proposalId)
    public
    view
    returns (bool)
  {
    IAaveGovernanceV2.ProposalWithoutVotes memory proposal = governance.getProposalById(proposalId);
    uint256 votingSupply = IGovernanceStrategy(proposal.strategy).getTotalVotingSupplyAt(
      proposal.startBlock
    );

    return proposal.forVotes >= getMinimumVotingPowerNeeded(votingSupply);
  }

  /// @inheritdoc IExecutor
  function isVoteDifferentialValid(IAaveGovernanceV2 governance, uint256 proposalId)
    public
    view
    returns (bool)
  {
    IAaveGovernanceV2.ProposalWithoutVotes memory proposal = governance.getProposalById(proposalId);
    uint256 votingSupply = IGovernanceStrategy(proposal.strategy).getTotalVotingSupplyAt(
      proposal.startBlock
    );

    return (proposal.forVotes * ONE_HUNDRED_WITH_PRECISION / votingSupply) >
      ((proposal.againstVotes * ONE_HUNDRED_WITH_PRECISION / votingSupply) +
        VOTE_DIFFERENTIAL);
  }

  /// updates voting duration
  function _updateVotingDuration(uint256 votingDuration) internal {
    require(votingDuration > 0, 'VOTING_DURATION_CAN_NOT_BE_0');
    VOTING_DURATION = votingDuration;
    emit VotingDurationUpdated(votingDuration);
  }

  /// updates vote differential
  function _updateVoteDifferential(uint256 voteDifferential) internal {
    require(voteDifferential <= ONE_HUNDRED_WITH_PRECISION, 'VOTE_DIFFERENTIAL_CAN_NOT_BE_GREATER_THAN_100%');
    require(voteDifferential > 0, 'VOTE_DIFFERENTIAL_CAN_NOT_BE_LESS_THAN_0');
    VOTE_DIFFERENTIAL = voteDifferential;
    emit VoteDifferentialUpdated(voteDifferential);
  }

  /// updates minimum quorum
  function _updateMinimumQuorum(uint256 minimumQuorum) internal {
    require(minimumQuorum <= ONE_HUNDRED_WITH_PRECISION, 'MINIMUM_QUORUM_CAN_NOT_BE_GREATER_THAN_100%');
    require(minimumQuorum > 0, 'MINIMUM_QUORUM_CAN_NOT_BE_LESS_THAN_0');
    MINIMUM_QUORUM = minimumQuorum;
    emit MinimumQuorumUpdated(minimumQuorum);
  }

  /// updates proposition threshold
  function _updatePropositionThreshold(uint256 propositionThreshold) internal {
    require(propositionThreshold <= ONE_HUNDRED_WITH_PRECISION, 'PROPOSITION_THRESHOLD_CAN_NOT_BE_GREATER_THAN_100%');
    require(propositionThreshold > 0, 'PROPOSITION_THRESHOLD_CAN_NOT_BE_LESS_THAN_0');
    PROPOSITION_THRESHOLD = propositionThreshold;
    emit PropositionThresholdUpdated(propositionThreshold);
  }

  /// validates that a delay is correct
  function _validateDelay(uint256 delay) internal view {
    require(delay >= MINIMUM_DELAY, 'DELAY_SHORTER_THAN_MINIMUM');
    require(delay <= MAXIMUM_DELAY, 'DELAY_LONGER_THAN_MAXIMUM');
  }
}

pragma solidity ^0.8.0;

interface IGovernanceStrategy {
  /**
   * @dev Returns the Proposition Power of a user at a specific block number.
   * @param user Address of the user.
   * @param blockNumber Blocknumber at which to fetch Proposition Power
   * @return Power number
   **/
  function getPropositionPowerAt(address user, uint256 blockNumber) external view returns (uint256);

  /**
   * @dev Returns the total supply of Outstanding Proposition Tokens
   * @param blockNumber Blocknumber at which to evaluate
   * @return total supply at blockNumber
   **/
  function getTotalPropositionSupplyAt(uint256 blockNumber) external view returns (uint256);

  /**
   * @dev Returns the total supply of Outstanding Voting Tokens
   * @param blockNumber Blocknumber at which to evaluate
   * @return total supply at blockNumber
   **/
  function getTotalVotingSupplyAt(uint256 blockNumber) external view returns (uint256);

  /**
   * @dev Returns the Vote Power of a user at a specific block number.
   * @param user Address of the user.
   * @param blockNumber Blocknumber at which to fetch Vote Power
   * @return Vote number
   **/
  function getVotingPowerAt(address user, uint256 blockNumber) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;


interface IAaveGovernanceV2 {
  struct ProposalWithoutVotes {
    uint256 id;
    address creator;
    address executor;
    address[] targets;
    uint256[] values;
    string[] signatures;
    bytes[] calldatas;
    bool[] withDelegatecalls;
    uint256 startBlock;
    uint256 endBlock;
    uint256 executionTime;
    uint256 forVotes;
    uint256 againstVotes;
    bool executed;
    bool canceled;
    address strategy;
    bytes32 ipfsHash;
  }

  /**
   * @dev Set new Voting Delay (delay before a newly created proposal can be voted on)
   * Note: owner should be a timelocked executor, so needs to make a proposal
   * @param votingDelay new voting delay in seconds
   **/
  function setVotingDelay(uint256 votingDelay) external;

  /**
   * @dev Add new addresses to the list of authorized executors
   * @param executors list of new addresses to be authorized executors
   **/
  function authorizeExecutors(address[] memory executors) external;

  /**
   * @dev Remove addresses to the list of authorized executors
   * @param executors list of addresses to be removed as authorized executors
   **/
  function unauthorizeExecutors(address[] memory executors) external;

  /**
   * @dev Getter of the current Voting Delay (delay before a created proposal can be voted on)
   * Different from the voting duration
   * @return The voting delay in seconds
   **/
  function getVotingDelay() external view returns (uint256);

  /**
   * @dev Returns whether an address is an authorized executor
   * @param executor address to evaluate as authorized executor
   * @return true if authorized
   **/
  function isExecutorAuthorized(address executor) external view returns (bool);

  /**
   * @dev Getter of the current GovernanceStrategy address
   * @return The address of the current GovernanceStrategy contracts
   **/
   function getGovernanceStrategy() external view returns (address);
  
   /**
   * @dev Getter of a proposal by id
   * @param proposalId id of the proposal to get
   * @return the proposal as ProposalWithoutVotes memory object
   **/
   function getProposalById(uint256 proposalId) external view returns (ProposalWithoutVotes memory);

}

pragma solidity ^0.8.0;

import {IAaveGovernanceV2} from './IAaveGovernanceV2.sol';

interface IExecutor {
  /**
  * -------------------------------------------------------------
  * --------------- IExecutorWithTimelock --------------------------
  * -------------------------------------------------------------
  */
  /**
   * @dev emitted when a new pending admin is set
   * @param newPendingAdmin address of the new pending admin
   **/
   event NewPendingAdmin(address newPendingAdmin);

   /**
    * @dev emitted when a new admin is set
    * @param newAdmin address of the new admin
    **/
   event NewAdmin(address newAdmin);
 
   /**
    * @dev emitted when a new delay (between queueing and execution) is set
    * @param delay new delay
    **/
   event NewDelay(uint256 delay);
 
   /**
    * @dev emitted when a new (trans)action is Queued.
    * @param actionHash hash of the action
    * @param target address of the targeted contract
    * @param value wei value of the transaction
    * @param signature function signature of the transaction
    * @param data function arguments of the transaction or callData if signature empty
    * @param executionTime time at which to execute the transaction
    * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
    **/
   event QueuedAction(
     bytes32 actionHash,
     address indexed target,
     uint256 value,
     string signature,
     bytes data,
     uint256 executionTime,
     bool withDelegatecall
   );
 
   /**
    * @dev emitted when an action is Cancelled
    * @param actionHash hash of the action
    * @param target address of the targeted contract
    * @param value wei value of the transaction
    * @param signature function signature of the transaction
    * @param data function arguments of the transaction or callData if signature empty
    * @param executionTime time at which to execute the transaction
    * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
    **/
   event CancelledAction(
     bytes32 actionHash,
     address indexed target,
     uint256 value,
     string signature,
     bytes data,
     uint256 executionTime,
     bool withDelegatecall
   );
 
   /**
    * @dev emitted when an action is Cancelled
    * @param actionHash hash of the action
    * @param target address of the targeted contract
    * @param value wei value of the transaction
    * @param signature function signature of the transaction
    * @param data function arguments of the transaction or callData if signature empty
    * @param executionTime time at which to execute the transaction
    * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
    * @param resultData the actual callData used on the target
    **/
   event ExecutedAction(
     bytes32 actionHash,
     address indexed target,
     uint256 value,
     string signature,
     bytes data,
     uint256 executionTime,
     bool withDelegatecall,
     bytes resultData
   );

   /**
    * @dev Getter of the current admin address (should be governance)
    * @return The address of the current admin 
    **/
   function getAdmin() external view returns (address);

   /**
    * @dev Getter of the current pending admin address
    * @return The address of the pending admin 
    **/
   function getPendingAdmin() external view returns (address);

   /**
    * @dev Getter of the delay between queuing and execution
    * @return The delay in seconds
    **/
   function getDelay() external view returns (uint256);

   /**
    * @dev Returns whether an action (via actionHash) is queued
    * @param actionHash hash of the action to be checked
    * keccak256(abi.encode(target, value, signature, data, executionTime, withDelegatecall))
    * @return true if underlying action of actionHash is queued
    **/
   function isActionQueued(bytes32 actionHash) external view returns (bool);

   /**
    * @dev Checks whether a proposal is over its grace period 
    * @param governance Governance contract
    * @param proposalId Id of the proposal against which to test
    * @return true of proposal is over grace period
    **/
   function isProposalOverGracePeriod(IAaveGovernanceV2 governance, uint256 proposalId)
     external
     view
     returns (bool);

   /**
    * @dev Getter of grace period constant
    * @return grace period in seconds
    **/
   function GRACE_PERIOD() external view returns (uint256);

   /**
    * @dev Getter of minimum delay constant
    * @return minimum delay in seconds
    **/
   function MINIMUM_DELAY() external view returns (uint256);

   /**
    * @dev Getter of maximum delay constant
    * @return maximum delay in seconds
    **/
   function MAXIMUM_DELAY() external view returns (uint256);

   /**
   * @dev Set the delay
   * @param delay time in seconds between queue and execution of proposal
   **/
  function setDelay(uint256 delay) external;

  /**
   * @dev Function enabling pending admin to become admin
   **/
   function acceptAdmin() external;

  /**
   * @dev Setting a new pending admin (that can then become admin)
   * Can only be called by this executor (i.e via proposal)
   * @param newPendingAdmin address of the new admin
   **/
  function setPendingAdmin(address newPendingAdmin) external;

   /**
    * @dev Function, called by Governance, that queue a transaction, returns action hash
    * @param target smart contract target
    * @param value wei value of the transaction
    * @param signature function signature of the transaction
    * @param data function arguments of the transaction or callData if signature empty
    * @param executionTime time at which to execute the transaction
    * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
    **/
   function queueTransaction(
     address target,
     uint256 value,
     string memory signature,
     bytes memory data,
     uint256 executionTime,
     bool withDelegatecall
   ) external returns (bytes32);
   /**
    * @dev Function, called by Governance, that cancels a transaction, returns the callData executed
    * @param target smart contract target
    * @param value wei value of the transaction
    * @param signature function signature of the transaction
    * @param data function arguments of the transaction or callData if signature empty
    * @param executionTime time at which to execute the transaction
    * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
    **/
   function executeTransaction(
     address target,
     uint256 value,
     string memory signature,
     bytes memory data,
     uint256 executionTime,
     bool withDelegatecall
   ) external payable returns (bytes memory);
   /**
    * @dev Function, called by Governance, that cancels a transaction, returns action hash
    * @param target smart contract target
    * @param value wei value of the transaction
    * @param signature function signature of the transaction
    * @param data function arguments of the transaction or callData if signature empty
    * @param executionTime time at which to execute the transaction
    * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
    **/
   function cancelTransaction(
     address target,
     uint256 value,
     string memory signature,
     bytes memory data,
     uint256 executionTime,
     bool withDelegatecall
   ) external returns (bytes32);

  /**
  * -------------------------------------------------------------
  * --------------- Proposal Validator --------------------------
  * -------------------------------------------------------------
  */
  // event triggered when voting duration gets updated by the admin
  event VotingDurationUpdated(uint256 newVotingDuration);
  // event triggered when vote differential gets updated by the admin
  event VoteDifferentialUpdated(uint256 newVoteDifferential);
  // event triggered when minimum quorum gets updated by the admin
  event MinimumQuorumUpdated(uint256 newMinimumQuorum);
  // event triggered when proposition threshold gets updated by the admin
  event PropositionThresholdUpdated(uint256 newPropositionThreshold);
  
  /**
  * @dev method tu update the voting duration of the proposal. Only callable by admin.
  * @param votingDuration duration of the vote, in blocks
  */
  function updateVotingDuration(uint256 votingDuration) external;

  /**
  * @dev method to update the vote differential needed to pass the proposal. Only callable by admin.
  * @param voteDifferential differential needed on the votes to pass the proposal
  */
  function updateVoteDifferential(uint256 voteDifferential) external;

  /**
  * @dev method to update the minimum quorum needed to pass the proposal. Only callable by admin.
  * @param minimumQuorum quorum needed to pass the proposal 
  */
  function updateMinimumQuorum(uint256 minimumQuorum) external;

  /**
    * @dev method to update the propositionThreshold. Only callable by admin.
    * @param propositionThreshold new proposition threshold
    **/
  function updatePropositionThreshold(uint256 propositionThreshold) external;

  /**
   * @dev Called to validate a proposal (e.g when creating new proposal in Governance)
   * @param governance Governance Contract
   * @param user Address of the proposal creator
   * @param blockNumber Block Number against which to make the test (e.g proposal creation block -1).
   * @return boolean, true if can be created
   **/
  function validateCreatorOfProposal(
    IAaveGovernanceV2 governance,
    address user,
    uint256 blockNumber
  ) external view returns (bool);

  /**
   * @dev Called to validate the cancellation of a proposal
   * @param governance Governance Contract
   * @param user Address of the proposal creator
   * @param blockNumber Block Number against which to make the test (e.g proposal creation block -1).
   * @return boolean, true if can be cancelled
   **/
  function validateProposalCancellation(
    IAaveGovernanceV2 governance,
    address user,
    uint256 blockNumber
  ) external view returns (bool);

  /**
   * @dev Returns whether a user has enough Proposition Power to make a proposal.
   * @param governance Governance Contract
   * @param user Address of the user to be challenged.
   * @param blockNumber Block Number against which to make the challenge.
   * @return true if user has enough power
   **/
  function isPropositionPowerEnough(
    IAaveGovernanceV2 governance,
    address user,
    uint256 blockNumber
  ) external view returns (bool);

  /**
   * @dev Returns the minimum Proposition Power needed to create a proposition.
   * @param governance Governance Contract
   * @param blockNumber Blocknumber at which to evaluate
   * @return minimum Proposition Power needed
   **/
  function getMinimumPropositionPowerNeeded(IAaveGovernanceV2 governance, uint256 blockNumber)
    external
    view
    returns (uint256);

  /**
   * @dev Returns whether a proposal passed or not
   * @param governance Governance Contract
   * @param proposalId Id of the proposal to set
   * @return true if proposal passed
   **/
  function isProposalPassed(IAaveGovernanceV2 governance, uint256 proposalId)
    external
    view
    returns (bool);

  /**
   * @dev Check whether a proposal has reached quorum, ie has enough FOR-voting-power
   * Here quorum is not to understand as number of votes reached, but number of for-votes reached
   * @param governance Governance Contract
   * @param proposalId Id of the proposal to verify
   * @return voting power needed for a proposal to pass
   **/
  function isQuorumValid(IAaveGovernanceV2 governance, uint256 proposalId)
    external
    view
    returns (bool);

  /**
   * @dev Check whether a proposal has enough extra FOR-votes than AGAINST-votes
   * FOR VOTES - AGAINST VOTES > VOTE_DIFFERENTIAL * voting supply
   * @param governance Governance Contract
   * @param proposalId Id of the proposal to verify
   * @return true if enough For-Votes
   **/
  function isVoteDifferentialValid(IAaveGovernanceV2 governance, uint256 proposalId)
    external
    view
    returns (bool);

  /**
   * @dev Calculates the minimum amount of Voting Power needed for a proposal to Pass
   * @param votingSupply Total number of oustanding voting tokens
   * @return voting power needed for a proposal to pass
   **/
  function getMinimumVotingPowerNeeded(uint256 votingSupply) external view returns (uint256);

  /**
   * @dev Get proposition threshold constant value
   * @return the proposition threshold value (100 <=> 1%)
   **/
  function PROPOSITION_THRESHOLD() external view returns (uint256);

  /**
   * @dev Get voting duration constant value
   * @return the voting duration value in blocks
   **/
  function VOTING_DURATION() external view returns (uint256);

  /**
   * @dev Get the vote differential threshold constant value
   * to compare with % of for votes/total supply - % of against votes/total supply
   * @return the vote differential threshold value (100 <=> 1%)
   **/
  function VOTE_DIFFERENTIAL() external view returns (uint256);

  /**
   * @dev Get quorum threshold constant value
   * to compare with % of for votes/total supply
   * @return the quorum threshold value (100 <=> 1%)
   **/
  function MINIMUM_QUORUM() external view returns (uint256);

  /**
   * @dev precision helper: 100% = 10000
   * @return one hundred percents with our chosen precision
   **/
  function ONE_HUNDRED_WITH_PRECISION() external view returns (uint256);
}