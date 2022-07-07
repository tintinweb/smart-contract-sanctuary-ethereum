// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IDAOStaking.sol";
import "./Timelock.sol";
import "./interfaces/IGovernance.sol";

contract Governance is IGovernance, Timelock, Initializable {

    // important: never change the order, type or remove variables
    // it's safe only to add new variables at the end to avoid any storage bugs

    bool public isActive;

    IDAOStaking public daoStaking;

    uint256 public lastProposalId;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => AbrogationProposal) public abrogationProposals;
    mapping(address => uint256) public latestProposalIds;

    event ProposalCreated(uint256 indexed proposalId);
    event Vote(uint256 indexed proposalId, address indexed user, bool support, uint256 power);
    event VoteCanceled(uint256 indexed proposalId, address indexed user);
    event ProposalQueued(uint256 indexed proposalId, address caller, uint256 eta);
    event ProposalExecuted(uint256 indexed proposalId, address caller);
    event ProposalCanceled(uint256 indexed proposalId, address caller);
    event AbrogationProposalStarted(uint256 indexed proposalId, address caller);
    event AbrogationProposalExecuted(uint256 indexed proposalId, address caller);
    event AbrogationProposalVote(uint256 indexed proposalId, address indexed user, bool support, uint256 power);
    event AbrogationProposalVoteCancelled(uint256 indexed proposalId, address indexed user);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(GovernanceConfig memory cfg) public initializer {
        __Governance_init(cfg);
    }

    function __Governance_init(GovernanceConfig memory cfg) internal onlyInitializing {
        __Governance_init_unchained(cfg);
    }

    function __Governance_init_unchained(GovernanceConfig memory cfg) internal onlyInitializing {
        require(cfg.acceptanceThreshold > 50, "invalid acceptance threshold");
        require(cfg.acceptanceThreshold <= 100, "invalid acceptance threshold");
        require(cfg.creationThresholdPercentage <= 100, "invalid creation threshold");
        require(cfg.daoStakingAddr != address(0), "DAOStaking must not be 0x0");

        warmUpDuration = cfg.warmUpDuration;
        activeDuration = cfg.activeDuration;
        queueDuration = cfg.queueDuration;
        gracePeriodDuration = cfg.gracePeriodDuration;
        acceptanceThreshold = cfg.acceptanceThreshold;
        minQuorum = cfg.minQuorum;
        activationThreshold = cfg.activationThreshold;
        proposalMaxActions = cfg.proposalMaxActions;
        creationThresholdPercentage = cfg.creationThresholdPercentage;
        daoStaking = IDAOStaking(cfg.daoStakingAddr);
    }

    receive() external payable {}

    function activate() public {
        require(!isActive, "DAO already active");
        require(daoStaking.govTokenStaked() >= activationThreshold, "Threshold not met yet");

        isActive = true;
    }

    /// Create a proposal
    /// @dev A group of elements at the same index in the [targets, values, signatures, calldatas] parameters
    /// represents a proposal action. For example: (targets[0], values[0], signatures[0], calldatas[0]) is one action.
    ///
    /// A proposal can be created if:
    /// - the DAO is active
    /// - the creator has enough voting power (see `_getCreationThreshold`)
    /// - the creator doesn't have another proposal in a state considered "live" (see `_isLiveState`
    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description,
        string memory title
    )
    public returns (uint256)
    {
        if (!isActive) {
            require(daoStaking.govTokenStaked() >= activationThreshold, "DAO not yet active");
            isActive = true;
        }

        require(
            daoStaking.votingPowerAtTs(msg.sender, block.timestamp - 1) >= _getCreationThresholdAmount(),
            "Creation threshold not met"
        );
        require(
            targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length,
            "Proposal function information arity mismatch"
        );
        require(targets.length != 0, "Must provide actions");
        require(targets.length <= proposalMaxActions, "Too many actions on a vote");
        require(bytes(title).length > 0, "title can't be empty");
        require(bytes(description).length > 0, "description can't be empty");

        // check if user has another running vote
        uint256 previousProposalId = latestProposalIds[msg.sender];
        if (previousProposalId != 0) {
            require(_isLiveState(previousProposalId) == false, "One live proposal per proposer");
        }

        uint256 newProposalId = lastProposalId + 1;
        Proposal storage newProposal = proposals[newProposalId];
        newProposal.id = newProposalId;
        newProposal.proposer = msg.sender;
        newProposal.description = description;
        newProposal.title = title;
        newProposal.targets = targets;
        newProposal.values = values;
        newProposal.signatures = signatures;
        newProposal.calldatas = calldatas;
        newProposal.createTime = block.timestamp - 1;
        newProposal.parameters.warmUpDuration = warmUpDuration;
        newProposal.parameters.activeDuration = activeDuration;
        newProposal.parameters.queueDuration = queueDuration;
        newProposal.parameters.gracePeriodDuration = gracePeriodDuration;
        newProposal.parameters.acceptanceThreshold = acceptanceThreshold;
        newProposal.parameters.minQuorum = minQuorum;

        lastProposalId = newProposalId;
        latestProposalIds[msg.sender] = newProposalId;

        emit ProposalCreated(newProposalId);

        return newProposalId;
    }

    /// Queue an accepted proposal for execution
    /// @dev The current architecture doesn't allow for identical actions (same signature, same parameters)
    /// being called multiple times in the same proposal.
    function queue(uint256 proposalId) public {
        require(state(proposalId) == ProposalState.Accepted, "Proposal can only be queued if it is succeeded");

        Proposal storage proposal = proposals[proposalId];
        uint256 eta = proposal.createTime + proposal.parameters.warmUpDuration + proposal.parameters.activeDuration + proposal.parameters.queueDuration;
        proposal.eta = eta;

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            require(
                !queuedTransactions[_getTxHash(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta)],
                "proposal action already queued at eta"
            );

            queueTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }

        emit ProposalQueued(proposalId, msg.sender, eta);
    }

    /// Execute a queued proposal
    function execute(uint256 proposalId) public payable {
        require(_canBeExecuted(proposalId), "Cannot be executed");

        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            executeTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit ProposalExecuted(proposalId, msg.sender);
    }

    /// Cancel a proposal
    /// @dev The proposal can only be cancelled if it is in a cancellable state (see `_isCancellableState`)
    /// If in a cancellable state, then the creator can cancel at any time. Alternatively, any other user can cancel
    /// if the voting power of the creator goes below the threshold.
    function cancelProposal(uint256 proposalId) public {
        require(_isCancellableState(proposalId), "Proposal in state that does not allow cancellation");
        require(_canCancelProposal(proposalId), "Cancellation requirements not met");

        Proposal storage proposal = proposals[proposalId];
        proposal.canceled = true;

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit ProposalCanceled(proposalId, msg.sender);
    }

    /// Cast or change a vote on a proposal
    /// @dev Only allowed while the proposal is in the Active state.
    ///
    /// A user can change their vote by calling this function with a different `support` parameter.
    function castVote(uint256 proposalId, bool support) public {
        require(state(proposalId) == ProposalState.Active, "Voting is closed");

        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[msg.sender];

        // exit if user already voted
        require(receipt.hasVoted == false || receipt.hasVoted && receipt.support != support, "Already voted this option");

        uint256 votes = daoStaking.votingPowerAtTs(msg.sender, _getSnapshotTimestamp(proposal));
        require(votes > 0, "no voting power");

        // means it changed its vote
        if (receipt.hasVoted) {
            if (receipt.support) {
                proposal.forVotes = proposal.forVotes - receipt.votes;
            } else {
                proposal.againstVotes = proposal.againstVotes - receipt.votes;
            }
        }

        if (support) {
            proposal.forVotes = proposal.forVotes + votes;
        } else {
            proposal.againstVotes = proposal.againstVotes + votes;
        }

        receipt.hasVoted = true;
        receipt.votes = votes;
        receipt.support = support;

        emit Vote(proposalId, msg.sender, support, votes);
    }

    /// Cancel an existing vote
    function cancelVote(uint256 proposalId) public {
        require(state(proposalId) == ProposalState.Active, "Voting is closed");

        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[msg.sender];

        uint256 votes = daoStaking.votingPowerAtTs(msg.sender, _getSnapshotTimestamp(proposal));

        require(receipt.hasVoted, "Cannot cancel if not voted yet");

        if (receipt.support) {
            proposal.forVotes = proposal.forVotes - votes;
        } else {
            proposal.againstVotes = proposal.againstVotes - votes;
        }

        receipt.hasVoted = false;
        receipt.votes = 0;
        receipt.support = false;

        emit VoteCanceled(proposalId, msg.sender);
    }

    // ======================================================================================================
    // Abrogation proposal methods
    // ======================================================================================================

    // the Abrogation Proposal is a mechanism for the DAO participants to veto the execution of a proposal that was already
    // accepted and it is currently queued. For the Abrogation Proposal to pass, 50% + 1 of the stakers
    // must vote FOR the Abrogation Proposal
    function startAbrogationProposal(uint256 proposalId, string memory description) public {
        require(state(proposalId) == ProposalState.Queued, "Proposal must be in queue");
        require(
            daoStaking.votingPowerAtTs(msg.sender, block.timestamp - 1) >= _getCreationThresholdAmount(),
            "Creation threshold not met"
        );

        AbrogationProposal storage ap = abrogationProposals[proposalId];

        require(ap.createTime == 0, "Abrogation proposal already exists");
        require(bytes(description).length > 0, "description can't be empty");

        ap.createTime = block.timestamp;
        ap.creator = msg.sender;
        ap.description = description;

        emit AbrogationProposalStarted(proposalId, msg.sender);
    }

    // abrogateProposal cancels a proposal if there's an Abrogation Proposal that passed
    function abrogateProposal(uint256 proposalId) public {
        require(state(proposalId) == ProposalState.Abrogated, "Cannot be abrogated");

        Proposal storage proposal = proposals[proposalId];

        require(proposal.canceled == false, "Cannot be abrogated");

        proposal.canceled = true;

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit AbrogationProposalExecuted(proposalId, msg.sender);
    }

    /// Cast or change a vote on an abrogation proposal
    /// @dev Same as `castVote` but for abrogation proposals
    function abrogationProposal_castVote(uint256 proposalId, bool support) public {
        require(0 < proposalId && proposalId <= lastProposalId, "invalid proposal id");

        AbrogationProposal storage abrogationProposal = abrogationProposals[proposalId];
        require(
            state(proposalId) == ProposalState.Queued && abrogationProposal.createTime != 0,
            "Abrogation Proposal not active"
        );

        Receipt storage receipt = abrogationProposal.receipts[msg.sender];
        require(
            receipt.hasVoted == false || receipt.hasVoted && receipt.support != support,
            "Already voted this option"
        );

        uint256 votes = daoStaking.votingPowerAtTs(msg.sender, abrogationProposal.createTime - 1);
        require(votes > 0, "no voting power");

        // means it changed its vote
        if (receipt.hasVoted) {
            if (receipt.support) {
                abrogationProposal.forVotes = abrogationProposal.forVotes - receipt.votes;
            } else {
                abrogationProposal.againstVotes = abrogationProposal.againstVotes - receipt.votes;
            }
        }

        if (support) {
            abrogationProposal.forVotes = abrogationProposal.forVotes + votes;
        } else {
            abrogationProposal.againstVotes = abrogationProposal.againstVotes + votes;
        }

        receipt.hasVoted = true;
        receipt.votes = votes;
        receipt.support = support;

        emit AbrogationProposalVote(proposalId, msg.sender, support, votes);
    }

    /// Cancel a vote on an abrogation proposal
    function abrogationProposal_cancelVote(uint256 proposalId) public {
        require(0 < proposalId && proposalId <= lastProposalId, "invalid proposal id");

        AbrogationProposal storage abrogationProposal = abrogationProposals[proposalId];
        Receipt storage receipt = abrogationProposal.receipts[msg.sender];

        require(
            state(proposalId) == ProposalState.Queued && abrogationProposal.createTime != 0,
            "Abrogation Proposal not active"
        );

        uint256 votes = daoStaking.votingPowerAtTs(msg.sender, abrogationProposal.createTime - 1);

        require(receipt.hasVoted, "Cannot cancel if not voted yet");

        if (receipt.support) {
            abrogationProposal.forVotes = abrogationProposal.forVotes - votes;
        } else {
            abrogationProposal.againstVotes = abrogationProposal.againstVotes - votes;
        }

        receipt.hasVoted = false;
        receipt.votes = 0;
        receipt.support = false;

        emit AbrogationProposalVoteCancelled(proposalId, msg.sender);
    }

    // ======================================================================================================
    // views
    // ======================================================================================================

    /// Process and return the current state of a proposal
    function state(uint256 proposalId) public view returns (ProposalState) {
        require(0 < proposalId && proposalId <= lastProposalId, "invalid proposal id");

        Proposal storage proposal = proposals[proposalId];

        if (proposal.canceled) {
            return ProposalState.Canceled;
        }

        if (proposal.executed) {
            return ProposalState.Executed;
        }

        if (block.timestamp <= proposal.createTime + proposal.parameters.warmUpDuration) {
            return ProposalState.WarmUp;
        }

        if (block.timestamp <= proposal.createTime + proposal.parameters.warmUpDuration + proposal.parameters.activeDuration) {
            return ProposalState.Active;
        }

        if ((proposal.forVotes + proposal.againstVotes) < _getQuorum(proposal) ||
            (proposal.forVotes < _getMinForVotes(proposal))) {
            return ProposalState.Failed;
        }

        if (proposal.eta == 0) {
            return ProposalState.Accepted;
        }

        if (block.timestamp < proposal.eta) {
            return ProposalState.Queued;
        }

        if (_proposalAbrogated(proposalId)) {
            return ProposalState.Abrogated;
        }

        if (block.timestamp <= proposal.eta + proposal.parameters.gracePeriodDuration) {
            return ProposalState.Grace;
        }

        return ProposalState.Expired;
    }

    /// Return the receipt of a user's vote on a regular proposal
    function getReceipt(uint256 proposalId, address voter) public view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    // Return the receipt of a user's vote on an abrogation proposal
    function getAbrogationProposalReceipt(uint256 proposalId, address voter) public view returns (Receipt memory) {
        return abrogationProposals[proposalId].receipts[voter];
    }

    // Return the parameters (durations, quorum, acceptance threshold) for a proposal
    function getProposalParameters(uint256 proposalId) public view returns (ProposalParameters memory) {
        return proposals[proposalId].parameters;
    }

    /// Return the actions for a proposal
    function getActions(uint256 proposalId) public view returns (
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
    ) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    /// Return the absolute amount of voting power required as quorum for the proposal specified
    function getProposalQuorum(uint256 proposalId) public view returns (uint256) {
        require(0 < proposalId && proposalId <= lastProposalId, "invalid proposal id");

        return _getQuorum(proposals[proposalId]);
    }

    function getCreationThresholdAmount() public view returns (uint256) {
        return _getCreationThresholdAmount();
    }

    // ======================================================================================================
    // internal methods
    // ======================================================================================================

    function _canCancelProposal(uint256 proposalId) internal view returns (bool){
        Proposal storage proposal = proposals[proposalId];

        if (msg.sender == proposal.proposer ||
            daoStaking.votingPower(proposal.proposer) < _getCreationThresholdAmount()
        ) {
            return true;
        }

        return false;
    }

    function _isCancellableState(uint256 proposalId) internal view returns (bool) {
        ProposalState s = state(proposalId);

        return s == ProposalState.WarmUp || s == ProposalState.Active;
    }

    function _isLiveState(uint256 proposalId) internal view returns (bool) {
        ProposalState s = state(proposalId);

        return s == ProposalState.WarmUp ||
        s == ProposalState.Active ||
        s == ProposalState.Accepted ||
        s == ProposalState.Queued ||
        s == ProposalState.Grace;
    }

    function _canBeExecuted(uint256 proposalId) internal view returns (bool) {
        return state(proposalId) == ProposalState.Grace;
    }

    function _getMinForVotes(Proposal storage proposal) internal view returns (uint256) {
        return (proposal.forVotes + proposal.againstVotes) * proposal.parameters.acceptanceThreshold / 100;
    }

    function _getCreationThresholdAmount() internal view returns (uint256) {
        return daoStaking.govTokenStaked() * creationThresholdPercentage / 100;
    }

    // Returns the timestamp of the snapshot for a given proposal
    // If the current block's timestamp is equal to `proposal.createTime + warmUpDuration` then the state function
    // will return WarmUp as state which will prevent any vote to be cast which will gracefully avoid any flashloan attack
    function _getSnapshotTimestamp(Proposal storage proposal) internal view returns (uint256) {
        return proposal.createTime + proposal.parameters.warmUpDuration;
    }

    function _getQuorum(Proposal storage proposal) internal view returns (uint256) {
        return daoStaking.govTokenStakedAtTs(_getSnapshotTimestamp(proposal)) * proposal.parameters.minQuorum / 100;
    }

    function _proposalAbrogated(uint256 proposalId) internal view returns (bool) {
        Proposal storage p = proposals[proposalId];
        AbrogationProposal storage cp = abrogationProposals[proposalId];

        if (cp.createTime == 0 || block.timestamp < p.eta) {
            return false;
        }

        return cp.forVotes >= daoStaking.govTokenStakedAtTs(cp.createTime - 1) / 2;
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
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

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

interface IDAOStaking {
    struct Stake {
        uint256 timestamp;
        uint256 amount;
        uint256 expiryTimestamp;
        address delegatedTo;
    }

    // deposit allows a user to add more governance token to his staked balance
    function deposit(uint256 amount) external;

    // withdraw allows a user to withdraw funds if the balance is not locked
    function withdraw(uint256 amount) external;

    // lock a user's currently staked balance until timestamp & add the bonus to his voting power
    function lock(uint256 timestamp) external;

    // delegate allows a user to delegate his voting power to another user
    function delegate(address to) external;

    // stopDelegate allows a user to take back the delegated voting power
    function stopDelegate() external;

    // balanceOf returns the current governance token balance of a user (bonus not included)
    function balanceOf(address user) external view returns (uint256);

    // balanceAtTs returns the amount of governance token that the user currently staked (bonus NOT included)
    function balanceAtTs(address user, uint256 timestamp) external view returns (uint256);

    // stakeAtTs returns the Stake object of the user that was valid at `timestamp`
    function stakeAtTs(address user, uint256 timestamp) external view returns (Stake memory);

    // votingPower returns the voting power (bonus included) + delegated voting power for a user at the current block
    function votingPower(address user) external view returns (uint256);

    // votingPowerAtTs returns the voting power (bonus included) + delegated voting power for a user at a point in time
    function votingPowerAtTs(address user, uint256 timestamp) external view returns (uint256);

    // govTokenStaked returns the total raw amount of governance token staked at the current block
    function govTokenStaked() external view returns (uint256);

    // govTokenStakedAtTs returns the total raw amount of governance tokens users have deposited into the contract
    // it does not include any bonus
    function govTokenStakedAtTs(uint256 timestamp) external view returns (uint256);

    // delegatedPower returns the total voting power that a user received from other users
    function delegatedPower(address user) external view returns (uint256);

    // delegatedPowerAtTs returns the total voting power that a user received from other users at a point in time
    function delegatedPowerAtTs(address user, uint256 timestamp) external view returns (uint256);

    // multiplierAtTs calculates the multiplier at a given timestamp based on the user's stake a the given timestamp
    // it includes the decay mechanism
    function multiplierAtTs(address user, uint256 timestamp) external view returns (uint256);

    // userLockedUntil returns the timestamp until the user's balance is locked
    function userLockedUntil(address user) external view returns (uint256);

    // userDidDelegate returns the address to which a user delegated their voting power; address(0) if not delegated
    function userDelegatedTo(address user) external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "./Parameters.sol";

abstract contract Timelock is Parameters {

    mapping(bytes32 => bool) public queuedTransactions;

    function queueTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta) internal returns (bytes32) {
        bytes32 txHash = _getTxHash(target, value, signature, data, eta);
        queuedTransactions[txHash] = true;

        return txHash;
    }

    function cancelTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta) internal {
        bytes32 txHash = _getTxHash(target, value, signature, data, eta);
        queuedTransactions[txHash] = false;
    }

    function executeTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta) internal returns (bytes memory) {
        bytes32 txHash = _getTxHash(target, value, signature, data, eta);

        require(block.timestamp >= eta, "executeTransaction: Transaction hasn't surpassed time lock.");
        require(block.timestamp <= eta + gracePeriodDuration, "executeTransaction: Transaction is stale.");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value : value}(callData);
        require(success, string(returnData));

        return returnData;
    }

    function _getTxHash(address target, uint256 value, string memory signature, bytes memory data, uint256 eta) internal pure returns (bytes32) {
        return keccak256(abi.encode(target, value, signature, data, eta));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

interface IGovernance {
    struct GovernanceConfig {
        uint256 warmUpDuration;
        uint256 activeDuration;
        uint256 queueDuration;
        uint256 gracePeriodDuration;
        uint256 acceptanceThreshold;
        uint256 minQuorum;
        uint256 activationThreshold;
        uint256 proposalMaxActions;
        uint256 creationThresholdPercentage;
        address daoStakingAddr;
    }

    enum ProposalState {
        WarmUp,
        Active,
        Canceled,
        Failed,
        Accepted,
        Queued,
        Grace,
        Expired,
        Executed,
        Abrogated
    }

    struct Receipt {
        // Whether or not a vote has been cast
        bool hasVoted;
        // The number of votes the voter had, which were cast
        uint256 votes;
        // support
        bool support;
    }

    struct AbrogationProposal {
        address creator;
        uint256 createTime;
        string description;

        uint256 forVotes;
        uint256 againstVotes;

        mapping(address => Receipt) receipts;
    }

    struct ProposalParameters {
        uint256 warmUpDuration;
        uint256 activeDuration;
        uint256 queueDuration;
        uint256 gracePeriodDuration;
        uint256 acceptanceThreshold;
        uint256 minQuorum;
    }

    struct Proposal {
        // proposal identifiers
        // unique id
        uint256 id;
        // Creator of the proposal
        address proposer;
        // proposal description
        string description;
        string title;

        // proposal technical details
        // ordered list of target addresses to be made
        address[] targets;
        // The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint256[] values;
        // The ordered list of function signatures to be called
        string[] signatures;
        // The ordered list of calldata to be passed to each call
        bytes[] calldatas;

        // proposal creation time - 1
        uint256 createTime;

        // votes status
        // The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint256 eta;
        // Current number of votes in favor of this proposal
        uint256 forVotes;
        // Current number of votes in opposition to this proposal
        uint256 againstVotes;

        bool canceled;
        bool executed;

        // Receipts of ballots for the entire set of voters
        mapping(address => Receipt) receipts;

        ProposalParameters parameters;
    }

    function initialize(GovernanceConfig memory cfg) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

abstract contract Parameters {
    uint256 public warmUpDuration;
    uint256 public activeDuration;
    uint256 public queueDuration;
    uint256 public gracePeriodDuration;

    uint256 public acceptanceThreshold;
    uint256 public minQuorum;

    uint256 public activationThreshold;
    uint256 public proposalMaxActions;
    uint256 public creationThresholdPercentage;

    modifier onlyDAO () {
        require(msg.sender == address(this), "Only DAO can call");
        _;
    }

    function setWarmUpDuration(uint256 period) public onlyDAO {
        warmUpDuration = period;
    }

    function setActiveDuration(uint256 period) public onlyDAO {
        require(period >= 4 hours, "period must be > 0");
        activeDuration = period;
    }

    function setQueueDuration(uint256 period) public onlyDAO {
        queueDuration = period;
    }

    function setGracePeriodDuration(uint256 period) public onlyDAO {
        require(period >= 4 hours, "period must be > 0");
        gracePeriodDuration = period;
    }

    function setAcceptanceThreshold(uint256 threshold) public onlyDAO {
        require(threshold <= 100, "Maximum is 100.");
        require(threshold > 50, "Minimum is 50.");

        acceptanceThreshold = threshold;
    }

    function setMinQuorum(uint256 quorum) public onlyDAO {
        require(quorum > 5, "quorum must be greater than 5");
        require(quorum <= 100, "Maximum is 100.");

        minQuorum = quorum;
    }
}