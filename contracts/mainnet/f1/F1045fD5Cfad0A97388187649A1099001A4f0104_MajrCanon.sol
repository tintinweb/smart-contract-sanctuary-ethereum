// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IMajrStaking {
  function balanceOf(address _account) external view returns (uint256);

  function totalSupply() external view returns (uint256);
}

contract MajrCanon is Ownable, Pausable {
  /// @notice OpenZeppelin libraries
  using Counters for Counters.Counter;

  /// @notice The address of the staking contract for the MAJR IDs
  IMajrStaking public stakingContract;

  /// @notice The address of the MAJR DAO treasury
  address public daoTreasury;

  /// @notice Tracks the ID of the next ordinary (general) proposal to be proposed
  Counters.Counter public proposalCount;

  /// @notice Tracks the ID of the next pre set proposal to be proposed
  Counters.Counter public preSetProposalCount;

  /**
   * @notice Possible states that a proposal may be in
   * @dev Pending: pending approval from the Guardian Council
   * @dev Active: voting period is currently active
   * @dev Canceled: proposal has been canceled
   * @dev Queued: proposal has been queued for execution
   * @dev Executed: proposal has been executed
  */
  enum ProposalState {
    Pending, 
    Active,
    Canceled,
    Queued,
    Executed
  }

  /**  
   * @notice Custom struct for storing general proposals
   * @param id uint256
   * @param title string 
   * @param shortDescription string
   * @param longDescriptionURI string
   * @param timestamp uint256
   * @param proposer address
   * @param forVotes uint256
   * @param againstVotes uint256
   * @param canceled bool
   * @param executed bool
   * @param proposalQuorum uint256
   * @param state ProposalState
   */
  struct Proposal {
    uint256 id;
    string title;
    string shortDescription;
    string longDescriptionURI;
    uint256 timestamp;
    address proposer;
    uint256 forVotes;
    uint256 againstVotes;
    bool canceled;
    bool executed;
    uint256 proposalQuorum;
    ProposalState state;
  }

  /**
   * @notice Possible states that a proposal may be in
   * @dev Active: voting period is currently active
   * @dev Canceled: proposal has been canceled
   * @dev Queued: proposal has been queued for execution
   * @dev Executed: proposal has been executed
  */
  enum PreSetProposalState {
    Active,
    Canceled,
    Queued,
    Executed
  }

  /**  
   * @notice Custom struct for storing pre set proposals
   * @param id uint256
   * @param title string 
   * @param shortDescription string
   * @param timestamp uint256
   * @param proposer address
   * @param option1Votes uint256
   * @param option2Votes uint256
   * @param option3Votes uint256
   * @param option4Votes uint256
   * @param option5Votes uint256
   * @param canceled bool
   * @param executed bool
   * @param state PreSetProposalState
   */
  struct PreSetProposal {
    uint256 id;
    string title;
    uint256 timestamp;
    address proposer;
    uint256 option1Votes;
    uint256 option2Votes;
    uint256 option3Votes;
    uint256 option4Votes;
    uint256 option5Votes;
    bool canceled;
    bool executed;
    PreSetProposalState state;
  }

  /// @notice Mapping from the proposal id to the proposal data
  mapping(uint256 => Proposal) public proposals;

  /// @notice Mapping from the pre set proposal id to the pre set proposal data
  mapping(uint256 => PreSetProposal) public preSetProposals;

  /**  
   * @notice Ballot receipt record for a voter for the general proposal
   * @param hasVoted bool
   * @param support bool
   * @param votingPower uint256
   */
  struct Receipt {
    bool hasVoted;
    bool support;
    uint256 votingPower;
  }

  /**  
   * @notice Ballot receipt record for a voter for the pre set proposal
   * @param hasVoted bool
   * @param supportedOption uint256
   * @param votingPower uint256
   */
  struct PreSetReceipt {
    bool hasVoted;
    uint256 supportedOption;
    uint256 votingPower;
  }

  /// @notice Receipts of ballots for the entire set of voters for general proposals
  mapping(uint256 => mapping(address => Receipt)) public receipts;

  /// @notice Receipts of ballots for the entire set of voters for the pre set proposals
  mapping(uint256 => mapping(address => PreSetReceipt)) public preSetReceipts;

  /// @notice The minimum number of MAJR IDs required to propose a new proposal
  uint256 public proposalThreshold;

  /// @notice The minimum percentage of the total supply of staked MAJR IDs involved in voting (for and against votes combined) required for the proposal vote to pass and to be able to be queued for execution
  uint256 public quorumVotes;

  /// @notice The cost to submit a new general proposal in case it's proposed by someone other than the guardian council
  uint256 public proposalCost;

  /// @notice Mapping from the proposal id to its queued status (true if queued, false if otherwise)
  mapping(uint256 => bool) public queuedProposals;

  /// @notice Mapping from the pre set proposal id to its queued status (true if queued, false if otherwise)
  mapping(uint256 => bool) public queuedPreSetProposals;

  /// @notice An event emitted when a new proposal is created
  event ProposalCreated(
    uint256 proposalId,
    string title,
    string shortDescription,
    string longDescriptionURI,
    uint256 timestamp,
    address indexed proposer,
    uint256 proposalQuorum,
    ProposalState state
  );

  /// @notice An event emitted when a new pre set proposal is created
  event PreSetProposalCreated(
    uint256 proposalId,
    string title,
    uint256 timestamp,
    address indexed proposer,
    PreSetProposalState state
  );

  /// @notice An event emitted when a vote has been cast on a proposal
  event VoteCast(
    address voter,
    uint256 proposalId,
    bool support,
    uint256 votes
  );

  /// @notice An event emitted when a vote has been cast on a pre set proposal
  event PreSetVoteCast(
    address voter,
    uint256 proposalId,
    uint256 supportedOption,
    uint256 votes
  );

  /// @notice An event emitted when a proposal has been approved and put into the active state
  event ProposalApproved(uint256 proposalId);

  /// @notice An event emitted when a proposal has been queued for execution
  event ProposalQueued(uint256 proposalId);

  /// @notice An event emitted when a pre set proposal has been queued for execution
  event PreSetProposalQueued(uint256 proposalId);

  /// @notice An event emitted when a proposal has been executed
  event ProposalExecuted(uint256 proposalId);

  /// @notice An event emitted when a pre set proposal has been executed
  event PreSetProposalExecuted(uint256 proposalId);

  /// @notice An event emitted when a proposal has been canceled
  event ProposalCanceled(uint256 proposalId);

  /// @notice An event emitted when a pre set proposal has been canceled
  event PreSetProposalCanceled(uint256 proposalId);

  /**
   * @notice Constructor
   * @param _stakingContract address
   * @param _daoTreasury address
   * @param _proposalThreshold uint256
   * @param _quorumVotes uint256
   * @param _proposalCost uint256
   */
  constructor(address _stakingContract, address _daoTreasury, uint256 _proposalThreshold, uint256 _quorumVotes, uint256 _proposalCost) {
    require(_stakingContract != address(0), "MajrCanon: Staking contract address cannot be address(0).");
    require(_daoTreasury != address(0), "MajrCanon: DAO treasury address cannot be address(0).");
    require(_proposalThreshold > 0, "MajrCanon: Proposal threshold must be greater than 0.");
    require(_quorumVotes >= 1 && _quorumVotes <= 51, "MajrCanon: Quorum votes must be greater than or equal to 1 and lesser than or equal to 51.");
    require(_proposalCost > 0, "MajrCanon: Proposal cost must be greater than 0.");

    stakingContract = IMajrStaking(_stakingContract);
    daoTreasury = _daoTreasury;
    proposalThreshold = _proposalThreshold;
    quorumVotes = _quorumVotes;
    proposalCost = _proposalCost;
  }

  /**
   * @notice Modifier which checks whether the proposalId is in bounds or not
   * @param _proposalId uint256
   */
  modifier validProposalId(uint256 _proposalId) {
    require(proposalCount.current() > _proposalId, "MajrCanon: Proposal ID is out of bounds.");
    _;
  }

  /**
   * @notice Modifier which checks whether the preSetProposalId is in bounds or not
   * @param _proposalId uint256
   */
  modifier validPreSetProposalId(uint256 _proposalId) {
    require(preSetProposalCount.current() > _proposalId, "MajrCanon: Pre set proposal ID is out of bounds.");
    _;
  }

  /**
   * @notice Let's the user vote on a general proposal
   * @param _proposalId uint256
   * @param _support bool
   * @dev Can only be called while the contract is not paused
   */
  function vote(uint256 _proposalId, bool _support) external whenNotPaused validProposalId(_proposalId) {
    Proposal storage proposal = proposals[_proposalId];
    require(proposal.state == ProposalState.Active, "MajrCanon: Voting is not active for this proposal.");

    Receipt storage receipt = receipts[_proposalId][msg.sender];
    require(receipt.hasVoted == false, "MajrCanon: Voter already voted on this proposal.");

    uint256 _votingPower = getVotingPower(msg.sender);

    if (_support) {
      proposal.forVotes += _votingPower;
    } else {
      proposal.againstVotes += _votingPower;
    }

    receipt.hasVoted = true;
    receipt.support = _support;
    receipt.votingPower = _votingPower;

    emit VoteCast(msg.sender, _proposalId, _support, _votingPower);
  } 

  /**
   * @notice Let's the user vote on a pre set proposal
   * @param _preSetProposalId uint256
   * @param _option uint256
   * @dev Can only be called while the contract is not paused
   */
  function votePreSet(uint256 _preSetProposalId, uint256 _option) external whenNotPaused validPreSetProposalId(_preSetProposalId) {
    PreSetProposal storage preSetProposal = preSetProposals[_preSetProposalId];
    require(preSetProposal.state == PreSetProposalState.Active, "MajrCanon: Voting is not active for this pre set proposal.");

    require(_option == 1 || _option == 2 || _option == 3 || _option == 4 || _option == 5, "MajrCanon: Invalid option.");

    PreSetReceipt storage preSetReceipt = preSetReceipts[_preSetProposalId][msg.sender];
    require(preSetReceipt.hasVoted == false, "MajrCanon: Voter already voted on this pre set proposal.");

    uint256 _votingPower = getVotingPower(msg.sender);

    if (_option == 1) {
      preSetProposal.option1Votes += _votingPower;
    } else if (_option == 2) {
      preSetProposal.option2Votes += _votingPower;
    } else if (_option == 3) {
      preSetProposal.option3Votes += _votingPower;
    } else if (_option == 4) {
      preSetProposal.option4Votes += _votingPower;
    } else if (_option == 5) {
      preSetProposal.option5Votes += _votingPower;
    }

    preSetReceipt.hasVoted = true;
    preSetReceipt.supportedOption = _option;
    preSetReceipt.votingPower = _votingPower;
    
    emit PreSetVoteCast(msg.sender, _preSetProposalId, _option, _votingPower);
  }

  /**
   * @notice Returns the receipt of the user's vote on the specified general proposal
   * @param _proposalId uint256
   * @param _voter address
   * @return Receipt memory
   */
  function getReceipt(uint256 _proposalId, address _voter) public validProposalId(_proposalId) view returns (Receipt memory) {
    return receipts[_proposalId][_voter];
  }

  /**
   * @notice Returns the receipt of the user's vote on the specified pre set proposal
   * @param _preSetProposalId uint256
   * @param _voter address
   * @return PreSetReceipt memory
   */
  function getPreSetReceipt(uint256 _preSetProposalId, address _voter) public validPreSetProposalId(_preSetProposalId) view returns (PreSetReceipt memory) {
    return preSetReceipts[_preSetProposalId][_voter];
  }

  /**
   * @notice Creates a new general proposal
   * @param _title string calldata
   * @param _shortDescription string calldata
   * @param _longDescriptionURI string calldata
   * @dev Can only be called while the contract is not paused
   */
  function propose(string calldata _title, string calldata _shortDescription, string calldata _longDescriptionURI) external payable whenNotPaused {
    if (msg.sender != owner()) {
      require(stakingContract.balanceOf(msg.sender) >= proposalThreshold, "MajrCanon: Insufficient number of staked MAJR IDs to add a proposal.");
      require(msg.value == proposalCost, "MajrCanon: Must send the exact proposal fee.");
    
      (bool sent, ) = daoTreasury.call{value: msg.value}("");
      require(sent, "MajrCanon: Failed to send the proposal fee.");
    }

    uint256 currentProposalCount = proposalCount.current();
    ProposalState _proposalState = msg.sender == owner() ? ProposalState.Active : ProposalState.Pending;
    uint256 _proposalQuorum = uint256(stakingContract.totalSupply() / 100 * quorumVotes);

    proposals[currentProposalCount] = Proposal({
      id: currentProposalCount,
      title: _title,
      shortDescription: _shortDescription,
      longDescriptionURI: _longDescriptionURI,
      timestamp: block.timestamp,
      proposer: msg.sender,
      forVotes: 0,
      againstVotes: 0,
      canceled: false,
      executed: false,
      proposalQuorum: _proposalQuorum,
      state: _proposalState
    });

    proposalCount.increment();

    emit ProposalCreated(currentProposalCount, _title, _shortDescription, _longDescriptionURI, block.timestamp, msg.sender, _proposalQuorum, _proposalState);
  }

  /**
   * @notice Creates a new pre set proposal
   * @param _title string calldata
   * @dev Only guardian council can call it
   */
  function proposePreSet(string calldata _title) external onlyOwner whenNotPaused {
    uint currentPreSetProposalCount = preSetProposalCount.current();

    preSetProposals[currentPreSetProposalCount] = PreSetProposal({
      id: currentPreSetProposalCount,
      title: _title,
      timestamp: block.timestamp,
      proposer: msg.sender,
      option1Votes: 0,
      option2Votes: 0,
      option3Votes: 0,
      option4Votes: 0,
      option5Votes: 0,
      canceled: false,
      executed: false,
      state: PreSetProposalState.Active
    });

    preSetProposalCount.increment();

    emit PreSetProposalCreated(currentPreSetProposalCount, _title, block.timestamp, msg.sender, PreSetProposalState.Active);
  }

  /**
   * @notice Approves the specified general proposal and puts it into the active state
   * @param _proposalId uint256
   * @dev Only guardian council can call it
   */
  function approveProposal(uint256 _proposalId) external onlyOwner validProposalId(_proposalId) {
    Proposal storage proposal = proposals[_proposalId];

    require(proposal.state == ProposalState.Pending, "MajrCanon: Proposal must be in Pending state to be approved.");
    proposal.state = ProposalState.Active;

    emit ProposalApproved(_proposalId);
  }

  /**
   * @notice Places the specified general proposal into the execution queue
   * @param _proposalId uint256
   * @dev Only guardian council can call it
   */
  function queueProposal(uint256 _proposalId) external onlyOwner validProposalId(_proposalId) {
    Proposal storage proposal = proposals[_proposalId];

    require(proposal.state == ProposalState.Active, "MajrCanon: Proposal must be in Active state to be queued.");
    require(!queuedProposals[_proposalId], "MajrCanon: Proposal must not be queued already.");

    uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
    require(totalVotes >= proposal.proposalQuorum, "MajrCanon: Proposal must have reached the quorum to be queued for execution.");

    queuedProposals[_proposalId] = true;
    proposal.state = ProposalState.Queued;

    emit ProposalQueued(_proposalId);
  }

  /**
   * @notice Places the specified pre set proposal into the execution queue
   * @param _preSetProposalId uint256
   * @dev Only guardian council can call it
   */
  function queuePreSetProposal(uint256 _preSetProposalId) external onlyOwner validPreSetProposalId(_preSetProposalId) {
    PreSetProposal storage preSetProposal = preSetProposals[_preSetProposalId];

    require(preSetProposal.state == PreSetProposalState.Active, "MajrCanon: PreSetProposal must be in Active state to be queued.");
    require(!queuedPreSetProposals[_preSetProposalId], "MajrCanon: PreSetProposal must not be queued already.");

    queuedPreSetProposals[_preSetProposalId] = true;
    preSetProposal.state = PreSetProposalState.Queued;

    emit PreSetProposalQueued(_preSetProposalId);
  }

  /**
   * @notice Changes the specified general proposal's state to executed and removes it from the execution queue
   * @param _proposalId uint256
   * @dev Only guardian council can call it
   */
  function executeProposal(uint256 _proposalId) external onlyOwner validProposalId(_proposalId) {
    Proposal storage proposal = proposals[_proposalId];

    require(proposal.state == ProposalState.Queued, "MajrCanon: Proposal must be in Queued state to be executed.");
    require(queuedProposals[_proposalId], "MajrCanon: Proposal must be queued to be executed.");

    queuedProposals[_proposalId] = false;
    proposal.state = ProposalState.Executed;

    emit ProposalExecuted(_proposalId);
  }

  /**
   * @notice Changes the specified pre set proposal's state to executed and removes it from the execution queue
   * @param _preSetProposalId uint256
   * @dev Only guardian council can call it
   */
  function executePreSetProposal(uint256 _preSetProposalId) external onlyOwner validPreSetProposalId(_preSetProposalId) {
    PreSetProposal storage preSetProposal = preSetProposals[_preSetProposalId];

    require(preSetProposal.state == PreSetProposalState.Queued, "MajrCanon: PreSetProposal must be in Queued state to be executed.");
    require(queuedPreSetProposals[_preSetProposalId], "MajrCanon: PreSetProposal must be queued to be executed.");

    queuedPreSetProposals[_preSetProposalId] = false;
    preSetProposal.state = PreSetProposalState.Executed;

    emit PreSetProposalExecuted(_preSetProposalId);
  }

  /**
   * @notice Changes the specified general proposal's state to canceled
   * @param _proposalId uint256
   * @dev Only guardian council can call it
   */
  function cancelProposal(uint256 _proposalId) external onlyOwner validProposalId(_proposalId) {
    Proposal storage proposal = proposals[_proposalId];

    require(proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active, "MajrCanon: Proposal must be in Pending or Active state to be canceled.");

    proposal.canceled = true;
    proposal.state = ProposalState.Canceled;

    emit ProposalCanceled(_proposalId);
  }

  /**
   * @notice Changes the specified pre set proposal's state to canceled
   * @param _preSetProposalId uint256
   * @dev Only guardian council can call it
   */
  function cancelPreSetProposal(uint256 _preSetProposalId) external onlyOwner validPreSetProposalId(_preSetProposalId) {
    PreSetProposal storage preSetProposal = preSetProposals[_preSetProposalId];

    require(preSetProposal.state == PreSetProposalState.Active, "MajrCanon: PreSetProposal must be in Active state to be canceled.");

    preSetProposal.canceled = true;
    preSetProposal.state = PreSetProposalState.Canceled;

    emit PreSetProposalCanceled(_preSetProposalId);
  }

  /**
   * @notice Returns the voting power of the specified voter (a square root of their staked balance in the MAJR DAO's staking contract, rounded down to the nearest integer)
   * @param _account address
   * @return _votingPower uint256
   */
  function getVotingPower(address _account) public view returns (uint256 _votingPower) {
    uint256 _stakedBalance = stakingContract.balanceOf(_account);

    uint256 _temp = (_stakedBalance + 1) / 2;
    _votingPower = _stakedBalance;

    while (_temp < _votingPower) {
      _votingPower = _temp;
      _temp = (_stakedBalance / _temp + _temp) / 2;
    }
  }

  /**
   * @notice Pauses the pausable functions inside the contract
   * @dev Only guardian council can call it
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice Unpauses the pausable functions inside the contract
   * @dev Only guardian council can call it
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @notice Sets the new staking contract address
   * @dev Only guardian council can call it
   */
  function setStakingContract(address _stakingContract) external onlyOwner {
    require(_stakingContract != address(0), "MajrCanon: Staking contract address cannot be address zero.");

    stakingContract = IMajrStaking(_stakingContract);
  }

  /**
   * @notice Sets the new DAO treasury address
   * @dev Only guardian council can call it
   */
  function setDaoTreasury(address _daoTreasury) external onlyOwner {
    require(_daoTreasury != address(0), "MajrCanon: DAO treasury address cannot be address zero.");

    daoTreasury = _daoTreasury;
  }

  /**
   * @notice Sets the new proposal fee
   * @dev Only guardian council can call it
   */
  function setProposalCost(uint256 _proposalCost) external onlyOwner {
    require(_proposalCost > 0, "MajrCanon: Proposal cost must be greater than 0.");

    proposalCost = _proposalCost;
  }

  /**quoru
   * @notice Sets the new proposal threshold
   * @dev Only guardian council can call it
   */
  function setProposalThreshold(uint256 _proposalThreshold) external onlyOwner {
    require(_proposalThreshold > 0, "MajrCanon: Proposal threshold must be greater than 0.");

    proposalThreshold = _proposalThreshold;
  }

  /**
   * @notice Sets the new quorum votes percentage required to pass a proposal
   * @dev Only guardian council can call it
   */
  function setQuorumVotes(uint256 _quorumVotes) external onlyOwner {
    require(_quorumVotes >= 1 && _quorumVotes <= 51, "MajrCanon: Quorum votes must be greater than or equal to 1 and lesser than or equal to 51.");

    quorumVotes = _quorumVotes;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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