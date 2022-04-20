// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/GovernorBravoInterfaces.sol";
import "../interface/IStaking.sol";

contract GovernorBravoDelegate is
  Initializable,
  UUPSUpgradeable,
  OwnableUpgradeable,
  GovernorBravoDelegateStorageV1,
  GovernorBravoEvents
{
  using CountersUpgradeable for CountersUpgradeable.Counter;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

  /// @notice The name of this contract
  string public constant name = "Mern Governor Bravo";

  /// @notice The minimum setable voting period
  uint256 public constant MIN_VOTING_PERIOD = 1; // About 24 hours

  /// @notice The max setable voting period
  uint256 public constant MAX_VOTING_PERIOD = 80640; // About 2 weeks

  /// @notice The min setable voting delay
  uint256 public constant MIN_VOTING_DELAY = 1;

  /// @notice The max setable voting delay
  uint256 public constant MAX_VOTING_DELAY = 40320; // About 1 week

  /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
  uint256 public constant quorumVotes = 1e18; // 1 Billion

  /// @notice The maximum number of actions that can be included in a proposal
  uint256 public constant proposalMaxOperations = 10; // 10 actions

  /// @notice The EIP-712 typehash for the contract's domain
  bytes32 public constant DOMAIN_TYPEHASH =
    keccak256(
      "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
    );

  /// @notice The EIP-712 typehash for the ballot struct used by the contract
  bytes32 public constant BALLOT_TYPEHASH =
    keccak256("Ballot(uint256 proposalId,uint8 support)");

  CountersUpgradeable.Counter public proposalIDs;
  address stakingAddress;

  EnumerableSetUpgradeable.AddressSet artistList;
  struct userProposer {
    address[] targets;
    uint256[] values;
    string[] signatures;
    bytes[] calldatas;
    string description;
    address proposer;
    bool status;
  }

  mapping(uint256 => userProposer) public proposerDetails;

  /**
   * @notice Used to initialize the contract during delegator constructor
   * @param timelock_ The address of the Timelock
   * @param mern_ The address of the mern token
   * @param votingPeriod_ The initial voting period
   * @param votingDelay_ The initial voting delay
   */
  function initialize(
    address timelock_,
    address mern_,
    uint256 votingPeriod_,
    uint256 votingDelay_,
    address staking_
  ) public initializer {
    require(
      address(timelock) == address(0),
      "GovernorBravo::initialize: can only initialize once"
    );
    require(
      timelock_ != address(0),
      "GovernorBravo::initialize: invalid timelock address"
    );
    require(
      mern_ != address(0),
      "GovernorBravo::initialize: invalid mern address"
    );
    require(
      staking_ != address(0),
      "GovernorBravo::initialize: invalid staking address"
    );
    require(
      votingPeriod_ >= MIN_VOTING_PERIOD && votingPeriod_ <= MAX_VOTING_PERIOD,
      "GovernorBravo::initialize: invalid voting period"
    );
    require(
      votingDelay_ >= MIN_VOTING_DELAY && votingDelay_ <= MAX_VOTING_DELAY,
      "GovernorBravo::initialize: invalid voting delay"
    );

    __Ownable_init();
    timelock = TimelockInterface(timelock_);
    mern = MernInterface(mern_);
    votingPeriod = votingPeriod_;
    votingDelay = votingDelay_;
    admin = timelock_;
    stakingAddress = staking_;
  }

  modifier isArtist() {
    require(artistExist(msg.sender), "Artist can create proposal");
    _;
  }

  modifier isUser() {
    require(!artistExist(msg.sender), "User can call userProposer");
    _;
  }

  /**
   * @dev Fuction to check artist has existed or not
   * @param _artist: address of the artist
   */
  function artistExist(address _artist) public view returns (bool) {
    return artistList.contains(_artist);
  }

  /**
   * @dev Add new artist to the artistMember array
   * @param _artistAddress: address of the artist
   * Only owner of this contract can add unique artist
   */
  function addOrRemoveArtist(address _artistAddress, bool _status) public onlyOwner {
    require(_artistAddress != address(0), "Zero address can't be memeber ");
    if (_status) artistList.add(_artistAddress);
    else artistList.remove(_artistAddress);
  }

  /**
   * @dev Approved the proposal created by user for particular artist
   * @param _proposalID: proposal id for which artist has reponsed
   * Only proposer of this proposal can perform action
   */
  function acceptOrRejectProposal(uint256 _proposalID, bool _status) public {
    userProposer memory _userProposer = proposerDetails[_proposalID];
    require(
      _userProposer.proposer == msg.sender,
      "proposer must be caller or already considered"
    );
    if (_status) {
      propose(
        _userProposer.targets,
        _userProposer.values,
        _userProposer.signatures,
        _userProposer.calldatas,
        _userProposer.description
      );
      _userProposer.status = true;
    } else {
      _userProposer.status = false;
    }
  }

  /**
   * @dev Create a new proposal for user behalf of artist. Vote start {IGovernor-votingDelay} blocks after the proposal is created and ends
   * {IGovernor-votingPeriod} blocks after the voting starts.
   *
   * Emits a {ProposalCreated} event.
   */
  function userProposal(
    address[] memory _targets,
    uint256[] memory _values,
    string[] memory _signatures,
    bytes[] memory _calldatas,
    string memory _description,
    address _proposer
  ) public isUser returns (uint256) {
    require(
      IStaking(stakingAddress).hasStaked(msg.sender) && artistExist(_proposer),
      "TokenId not staked by caller or invalid proposer"
    );
    proposalIDs.increment();
    userProposer storage _userProposer = proposerDetails[proposalIDs.current()];
    _userProposer.targets = _targets;
    _userProposer.values = _values;
    _userProposer.signatures = _signatures;
    _userProposer.calldatas = _calldatas;
    _userProposer.description = _description;
    _userProposer.proposer = _proposer;
    _userProposer.status = false;
    return proposalIDs.current();
  }

  /**
   * @notice Function used to propose a new proposal. Sender must have delegates above the proposal threshold
   * @param targets Target addresses for proposal calls
   * @param values Eth values for proposal calls
   * @param signatures Function signatures for proposal calls
   * @param calldatas Calldatas for proposal calls
   * @param description String description of the proposal
   * @return Proposal id of new proposal
   */
  function propose(
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    string memory description
  ) public isArtist returns (uint256) {
    // Allow addresses above proposal threshold and whitelisted addresses to propose
    require(
      targets.length == values.length &&
        targets.length == signatures.length &&
        targets.length == calldatas.length,
      "GovernorBravo::propose: proposal function information arity mismatch"
    );
    require(
      targets.length != 0,
      "GovernorBravo::propose: must provide actions"
    );
    require(
      targets.length <= proposalMaxOperations,
      "GovernorBravo::propose: too many actions"
    );

    uint256 latestProposalId = latestProposalIds[msg.sender];
    if (latestProposalId != 0) {
      ProposalState proposersLatestProposalState = state(latestProposalId);
      require(
        proposersLatestProposalState != ProposalState.Active,
        "GovernorBravo::propose: one live proposal per proposer, found an already active proposal"
      );
      require(
        proposersLatestProposalState != ProposalState.Pending,
        "GovernorBravo::propose: one live proposal per proposer, found an already pending proposal"
      );
    }

    uint256 startBlock = add256(block.number, votingDelay);
    uint256 endBlock = add256(startBlock, votingPeriod);

    proposalCount++;

    Proposal storage newProposal = proposals[proposalCount];

    newProposal.id = proposalCount;
    newProposal.proposer = msg.sender;
    newProposal.eta = 0;
    newProposal.targets = targets;
    newProposal.values = values;
    newProposal.signatures = signatures;
    newProposal.calldatas = calldatas;
    newProposal.startBlock = startBlock;
    newProposal.endBlock = endBlock;
    newProposal.forVotes = 0;
    newProposal.againstVotes = 0;
    newProposal.abstainVotes = 0;
    newProposal.canceled = false;
    newProposal.executed = false;

    latestProposalIds[newProposal.proposer] = newProposal.id;

    emit ProposalCreated(
      newProposal.id,
      msg.sender,
      targets,
      values,
      signatures,
      calldatas,
      startBlock,
      endBlock,
      description
    );
    return newProposal.id;
  }

  /**
   * @notice Queues a proposal of state succeeded
   * @param proposalId The id of the proposal to queue
   */
  function queue(uint256 proposalId) external {
    require(
      state(proposalId) == ProposalState.Succeeded,
      "GovernorBravo::queue: proposal can only be queued if it is succeeded"
    );
    Proposal storage proposal = proposals[proposalId];
    uint256 eta = add256(block.timestamp, timelock.delay());
    for (uint256 i = 0; i < proposal.targets.length; i++) {
      queueOrRevertInternal(
        proposal.targets[i],
        proposal.values[i],
        proposal.signatures[i],
        proposal.calldatas[i],
        eta
      );
    }
    proposal.eta = eta;
    emit ProposalQueued(proposalId, eta);
  }

  function queueOrRevertInternal(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) internal {
    require(
      !timelock.queuedTransactions(
        keccak256(abi.encode(target, value, signature, data, eta))
      ),
      "GovernorBravo::queueOrRevertInternal: identical proposal action already queued at eta"
    );
    timelock.queueTransaction(target, value, signature, data, eta);
  }

  /**
   * @notice Executes a queued proposal if eta has passed
   * @param proposalId The id of the proposal to execute
   */
  function execute(uint256 proposalId) external payable {
    require(
      state(proposalId) == ProposalState.Queued,
      "GovernorBravo::execute: proposal can only be executed if it is queued"
    );
    Proposal storage proposal = proposals[proposalId];
    proposal.executed = true;
    for (uint256 i = 0; i < proposal.targets.length; i++) {
      timelock.executeTransaction{ value: proposal.values[i] }(
        proposal.targets[i],
        proposal.values[i],
        proposal.signatures[i],
        proposal.calldatas[i],
        proposal.eta
      );
    }
    emit ProposalExecuted(proposalId);
  }

  /**
   * @notice Cancels a proposal only if sender is the proposer
   * @param proposalId The id of the proposal to cancel
   */
  function cancel(uint256 proposalId) external {
    require(
      state(proposalId) != ProposalState.Executed,
      "GovernorBravo::cancel: cannot cancel executed proposal"
    );

    Proposal storage proposal = proposals[proposalId];

    require(
      msg.sender == proposal.proposer,
      "GovernorBravo::cancel: Other user cannot cancel proposal"
    );

    proposal.canceled = true;
    for (uint256 i = 0; i < proposal.targets.length; i++) {
      timelock.cancelTransaction(
        proposal.targets[i],
        proposal.values[i],
        proposal.signatures[i],
        proposal.calldatas[i],
        proposal.eta
      );
    }

    emit ProposalCanceled(proposalId);
  }

  /**
   * @notice Gets actions of a proposal
   * @param proposalId the id of the proposal
   * @return targets , values, signatures, and calldatas of the proposal actions
   */
  function getActions(uint256 proposalId)
    external
    view
    returns (
      address[] memory targets,
      uint256[] memory values,
      string[] memory signatures,
      bytes[] memory calldatas
    )
  {
    Proposal storage p = proposals[proposalId];
    return (p.targets, p.values, p.signatures, p.calldatas);
  }

  /**
   * @notice Gets the receipt for a voter on a given proposal
   * @param proposalId the id of proposal
   * @param voter The address of the voter
   * @return The voting receipt
   */
  function getReceipt(uint256 proposalId, address voter)
    external
    view
    returns (Receipt memory)
  {
    return proposals[proposalId].receipts[voter];
  }

  /**
   * @notice Gets the state of a proposal
   * @param proposalId The id of the proposal
   * @return Proposal state
   */
  function state(uint256 proposalId) public view returns (ProposalState) {
    require(
      proposalCount >= proposalId && proposalId > initialProposalId,
      "GovernorBravo::state: invalid proposal id"
    );
    Proposal storage proposal = proposals[proposalId];
    if (proposal.canceled) {
      return ProposalState.Canceled;
    } else if (block.number <= proposal.startBlock) {
      return ProposalState.Pending;
    } else if (block.number <= proposal.endBlock) {
      return ProposalState.Active;
    } else if (
      proposal.forVotes <= proposal.againstVotes ||
      proposal.forVotes < quorumVotes
    ) {
      return ProposalState.Defeated;
    } else if (proposal.eta == 0) {
      return ProposalState.Succeeded;
    } else if (proposal.executed) {
      return ProposalState.Executed;
    } else if (
      block.timestamp >= add256(proposal.eta, timelock.GRACE_PERIOD())
    ) {
      return ProposalState.Expired;
    } else {
      return ProposalState.Queued;
    }
  }

  /**
   * @notice Cast a vote for a proposal
   * @param proposalId The id of the proposal to vote on
   * @param support The support value for the vote. 0=against, 1=for, 2=abstain
   */
  function castVote(uint256 proposalId, uint8 support) external {
    emit VoteCast(
      msg.sender,
      proposalId,
      support,
      castVoteInternal(msg.sender, proposalId, support),
      ""
    );
  }

  /**
   * @notice Cast a vote for a proposal with a reason
   * @param proposalId The id of the proposal to vote on
   * @param support The support value for the vote. 0=against, 1=for, 2=abstain
   * @param reason The reason given for the vote by the voter
   */
  function castVoteWithReason(
    uint256 proposalId,
    uint8 support,
    string calldata reason
  ) external {
    emit VoteCast(
      msg.sender,
      proposalId,
      support,
      castVoteInternal(msg.sender, proposalId, support),
      reason
    );
  }

  /**
   * @notice Cast a vote for a proposal by signature
   * @dev External function that accepts EIP-712 signatures for voting on proposals.
   */
  function castVoteBySig(
    uint256 proposalId,
    uint8 support,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    bytes32 domainSeparator = keccak256(
      abi.encode(
        DOMAIN_TYPEHASH,
        keccak256(bytes(name)),
        getChainIdInternal(),
        address(this)
      )
    );
    bytes32 structHash = keccak256(
      abi.encode(BALLOT_TYPEHASH, proposalId, support)
    );
    bytes32 digest = keccak256(
      abi.encodePacked("\x19\x01", domainSeparator, structHash)
    );
    address signatory = ecrecover(digest, v, r, s);
    require(
      signatory != address(0),
      "GovernorBravo::castVoteBySig: invalid signature"
    );
    emit VoteCast(
      signatory,
      proposalId,
      support,
      castVoteInternal(signatory, proposalId, support),
      ""
    );
  }

  /**
   * @notice Internal function that caries out voting logic
   * @param voter The voter that is casting their vote
   * @param proposalId The id of the proposal to vote on
   * @param support The support value for the vote. 0=against, 1=for, 2=abstain
   * @return The number of votes cast
   */
  function castVoteInternal(
    address voter,
    uint256 proposalId,
    uint8 support
  ) internal returns (uint256) {
    require(
      state(proposalId) == ProposalState.Active,
      "GovernorBravo::castVoteInternal: voting is closed"
    );
    require(support <= 2, "GovernorBravo::castVoteInternal: invalid vote type");
    Proposal storage proposal = proposals[proposalId];
    Receipt storage receipt = proposal.receipts[voter];
    require(
      receipt.hasVoted == false,
      "GovernorBravo::castVoteInternal: voter already voted"
    );
    uint256 votes = mern.getPastVotes(voter, proposal.startBlock);

    if (support == 0) {
      proposal.againstVotes = add256(proposal.againstVotes, votes);
    } else if (support == 1) {
      proposal.forVotes = add256(proposal.forVotes, votes);
    } else if (support == 2) {
      proposal.abstainVotes = add256(proposal.abstainVotes, votes);
    }

    receipt.hasVoted = true;
    receipt.support = support;
    receipt.votes = votes;

    return votes;
  }

  /**
   * @notice Admin function for setting the voting delay
   * @param newVotingDelay new voting delay, in blocks
   */
  function _setVotingDelay(uint256 newVotingDelay) external {
    require(msg.sender == admin, "GovernorBravo::_setVotingDelay: admin only");
    require(
      newVotingDelay >= MIN_VOTING_DELAY && newVotingDelay <= MAX_VOTING_DELAY,
      "GovernorBravo::_setVotingDelay: invalid voting delay"
    );
    uint256 oldVotingDelay = votingDelay;
    votingDelay = newVotingDelay;

    emit VotingDelaySet(oldVotingDelay, votingDelay);
  }

  /**
   * @notice Admin function for setting the voting period
   * @param newVotingPeriod new voting period, in blocks
   */
  function _setVotingPeriod(uint256 newVotingPeriod) external {
    require(msg.sender == admin, "GovernorBravo::_setVotingPeriod: admin only");
    require(
      newVotingPeriod >= MIN_VOTING_PERIOD &&
        newVotingPeriod <= MAX_VOTING_PERIOD,
      "GovernorBravo::_setVotingPeriod: invalid voting period"
    );
    uint256 oldVotingPeriod = votingPeriod;
    votingPeriod = newVotingPeriod;

    emit VotingPeriodSet(oldVotingPeriod, votingPeriod);
  }

  /**
   * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
   * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
   * @param newPendingAdmin New pending admin.
   */
  function _setPendingAdmin(address newPendingAdmin) external {
    // Check address is not zero
    require(
      newPendingAdmin != address(0),
      "GovernorBravo:_setPendingAdmin: zero address"
    );
    // Check caller = admin
    require(msg.sender == admin, "GovernorBravo:_setPendingAdmin: admin only");

    // Save current value, if any, for inclusion in log
    address oldPendingAdmin = pendingAdmin;

    // Store pendingAdmin with value newPendingAdmin
    pendingAdmin = newPendingAdmin;

    // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
    emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
  }

  /**
   * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
   * @dev Admin function for pending admin to accept role and update admin
   */
  function _acceptAdmin() external {
    // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
    require(
      msg.sender == pendingAdmin && msg.sender != address(0),
      "GovernorBravo:_acceptAdmin: pending admin only"
    );

    // Save current values for inclusion in log
    address oldAdmin = admin;
    address oldPendingAdmin = pendingAdmin;

    // Store admin with value pendingAdmin
    admin = pendingAdmin;

    // Clear the pending value
    pendingAdmin = address(0);

    emit NewAdmin(oldAdmin, admin);
    emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
  }

  /**
   * @notice Accepts Admin for timelock of admin rights.
   * @dev Admin function for transferring admin to accept role and update admin
   */
  function _AcceptTimelockAdmin() external {
    timelock.acceptAdmin();
  }

  function _authorizeUpgrade(address) internal view override {
    require(admin == msg.sender, "Only admin can upgrade implementation");
  }

  function add256(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "addition overflow");
    return c;
  }

  function sub256(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "subtraction underflow");
    return a - b;
  }

  function getChainIdInternal() internal view returns (uint256) {
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    return chainId;
  }
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

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
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
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
library CountersUpgradeable {
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

contract GovernorBravoEvents {
  /// @notice An event emitted when a new proposal is created
  event ProposalCreated(
    uint256 id,
    address proposer,
    address[] targets,
    uint256[] values,
    string[] signatures,
    bytes[] calldatas,
    uint256 startBlock,
    uint256 endBlock,
    string description
  );

  /// @notice An event emitted when a vote has been cast on a proposal
  /// @param voter The address which casted a vote
  /// @param proposalId The proposal id which was voted on
  /// @param support Support value for the vote. 0=against, 1=for, 2=abstain
  /// @param votes Number of votes which were cast by the voter
  /// @param reason The reason given for the vote by the voter
  event VoteCast(
    address indexed voter,
    uint256 proposalId,
    uint8 support,
    uint256 votes,
    string reason
  );

  /// @notice An event emitted when a proposal has been canceled
  event ProposalCanceled(uint256 id);

  /// @notice An event emitted when a proposal has been queued in the Timelock
  event ProposalQueued(uint256 id, uint256 eta);

  /// @notice An event emitted when a proposal has been executed in the Timelock
  event ProposalExecuted(uint256 id);

  /// @notice An event emitted when the voting delay is set
  event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);

  /// @notice An event emitted when the voting period is set
  event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);

  /// @notice Emitted when implementation is changed
  event NewImplementation(address oldImplementation, address newImplementation);

  /// @notice Emitted when proposal threshold is set
  event ProposalThresholdSet(
    uint256 oldProposalThreshold,
    uint256 newProposalThreshold
  );

  /// @notice Emitted when pendingAdmin is changed
  event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

  /// @notice Emitted when pendingAdmin is accepted, which means admin is updated
  event NewAdmin(address oldAdmin, address newAdmin);

  /// @notice Alpha contract initiated. For initiating already deployed governance alpha
  event GovernanceInitiated(address governanceAddress);
}

contract GovernorBravoDelegatorStorage {
  /// @notice Administrator for this contract
  address public admin;

  /// @notice Pending administrator for this contract
  address public pendingAdmin;

  /// @notice Active brains of Governor
  address public implementation;
}

/**
 * @title Storage for Governor Bravo Delegate
 * @notice For future upgrades, do not change GovernorBravoDelegateStorageV1. Create a new
 * contract which implements GovernorBravoDelegateStorageV1 and following the naming convention
 * GovernorBravoDelegateStorageVX.
 */
contract GovernorBravoDelegateStorageV1 is GovernorBravoDelegatorStorage {
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

  /// @notice The address of the cult Protocol Timelock
  TimelockInterface public timelock;

  /// @notice The address of the cult governance token
  MernInterface public mern;

  /// @notice The official record of all proposals ever proposed
  mapping(uint256 => Proposal) public proposals;

  /// @notice The latest proposal for each proposer
  mapping(address => uint256) public latestProposalIds;

  struct Proposal {
    // Unique id for looking up a proposal
    uint256 id;
    // Creator of the proposal
    address proposer;
    // The timestamp that the proposal will be available for execution, set once the vote succeeds
    uint256 eta;
    // the ordered list of target addresses for calls to be made
    address[] targets;
    // The ordered list of values (i.e. msg.value) to be passed to the calls to be made
    uint256[] values;
    // The ordered list of function signatures to be called
    string[] signatures;
    // The ordered list of calldata to be passed to each call
    bytes[] calldatas;
    // The block at which voting begins: holders must delegate their votes prior to this block
    uint256 startBlock;
    // The block at which voting ends: votes must be cast prior to this block
    uint256 endBlock;
    // Current number of votes in favor of this proposal
    uint256 forVotes;
    // Current number of votes in opposition to this proposal
    uint256 againstVotes;
    // Current number of votes for abstaining for this proposal
    uint256 abstainVotes;
    // Flag marking whether the proposal has been canceled
    bool canceled;
    // Flag marking whether the proposal has been executed
    bool executed;
    // Receipts of ballots for the entire set of voters
    mapping(address => Receipt) receipts;
  }

  /// @notice Ballot receipt record for a voter
  struct Receipt {
    // Whether or not a vote has been cast
    bool hasVoted;
    // Whether or not the voter supports the proposal or abstains
    uint8 support;
    // The number of votes the voter had, which were cast
    uint256 votes;
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
}

interface TimelockInterface {
  function delay() external view returns (uint256);

  function GRACE_PERIOD() external view returns (uint256);

  function acceptAdmin() external;

  function queuedTransactions(bytes32 hash) external view returns (bool);

  function queueTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external returns (bytes32);

  function cancelTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external;

  function executeTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external payable returns (bytes memory);
}

interface MernInterface {
  /// @notice Get the past vote of the users
  function getPastVotes(address account, uint256 blockNumber)
    external
    view
    returns (uint256);
}

interface GovernorAlpha {
  /// @notice The total number of proposals
  function proposalCount() external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IStaking {
  function hasStaked(address account) external view returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
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
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            _functionDelegateCall(newImplementation, data);
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
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
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
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
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
library StorageSlotUpgradeable {
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