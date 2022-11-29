// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../policy/Policy.sol";
import "../governance/community/PolicyProposals.sol";
import "../governance/TimedPolicies.sol";

/** @title TimedPolicies
 * Oversees the time-based recurring processes that allow governance of the
 * Eco currency.
 */
contract SwitcherTimedPolicies is TimedPolicies {
    address public constant TEST_FILL_ADDRESS =
        0xDEADBEeFbAdf00dC0fFee1Ceb00dAFACEB00cEc0;

    bytes32 public constant TEST_FILL_BYTES =
        0x9f24c52e0fcd1ac696d00405c3bd5adc558c48936919ac5ab3718fcb7d70f93f;

    bytes32[] private fill;

    // this is for setting up the storage context
    // the values are unused but must validate the super constructor
    constructor()
        TimedPolicies(
            Policy(TEST_FILL_ADDRESS),
            PolicyProposals(TEST_FILL_ADDRESS),
            getFill()
        )
    {}

    function getFill() private returns (bytes32[] memory) {
        fill.push(TEST_FILL_BYTES);
        return fill;
    }

    /** Function for adding a notifier hash
     *
     * This is executed in the storage context of the TimedPolicies contract by the proposal.
     *
     * @param _newNotificationHash The identifier of the new contract to notify on generation increase
     */
    function addNotificationHash(bytes32 _newNotificationHash) public {
        notificationHashes.push(_newNotificationHash);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "../proxy/ForwardTarget.sol";
import "./ERC1820Client.sol";

/** @title The policy contract that oversees other contracts
 *
 * Policy contracts provide a mechanism for building pluggable (after deploy)
 * governance systems for other contracts.
 */
contract Policy is ForwardTarget, ERC1820Client {
    mapping(bytes32 => bool) public setters;

    modifier onlySetter(bytes32 _identifier) {
        require(
            setters[_identifier],
            "Identifier hash is not authorized for this action"
        );

        require(
            ERC1820REGISTRY.getInterfaceImplementer(
                address(this),
                _identifier
            ) == msg.sender,
            "Caller is not the authorized address for identifier"
        );

        _;
    }

    /** Remove the specified role from the contract calling this function.
     * This is for cleanup only, so if another contract has taken the
     * role, this does nothing.
     *
     * @param _interfaceIdentifierHash The interface identifier to remove from
     *                                 the registry.
     */
    function removeSelf(bytes32 _interfaceIdentifierHash) external {
        address old = ERC1820REGISTRY.getInterfaceImplementer(
            address(this),
            _interfaceIdentifierHash
        );

        if (old == msg.sender) {
            ERC1820REGISTRY.setInterfaceImplementer(
                address(this),
                _interfaceIdentifierHash,
                address(0)
            );
        }
    }

    /** Find the policy contract for a particular identifier.
     *
     * @param _interfaceIdentifierHash The hash of the interface identifier
     *                                 look up.
     */
    function policyFor(bytes32 _interfaceIdentifierHash)
        public
        view
        returns (address)
    {
        return
            ERC1820REGISTRY.getInterfaceImplementer(
                address(this),
                _interfaceIdentifierHash
            );
    }

    /** Set the policy label for a contract
     *
     * @param _key The label to apply to the contract.
     *
     * @param _implementer The contract to assume the label.
     */
    function setPolicy(
        bytes32 _key,
        address _implementer,
        bytes32 _authKey
    ) public onlySetter(_authKey) {
        ERC1820REGISTRY.setInterfaceImplementer(
            address(this),
            _key,
            _implementer
        );
    }

    /** Enact the code of one of the governance contracts.
     *
     * @param _delegate The contract code to delegate execution to.
     */
    function internalCommand(address _delegate, bytes32 _authKey)
        public
        onlySetter(_authKey)
    {
        // solhint-disable-next-line avoid-low-level-calls
        (bool _success, ) = _delegate.delegatecall(
            abi.encodeWithSignature("enacted(address)", _delegate)
        );
        require(_success, "Command failed during delegatecall");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../policy/PolicedUtils.sol";
import "../policy/Policy.sol";
import "../utils/TimeUtils.sol";
import "./IGenerationIncrease.sol";
import "./IGeneration.sol";
import "./community/PolicyProposals.sol";
import "../currency/ECO.sol";
import "../currency/ECOx.sol";

/** @title TimedPolicies
 * Oversees the time-based recurring processes that allow governance of the
 * Eco currency.
 */
contract TimedPolicies is PolicedUtils, TimeUtils, IGeneration {
    // Stores the current generation
    uint256 public override generation;
    // Stores when the next generation is allowed to start
    uint256 public nextGenerationWindowOpen;
    // Stores all contracts that need a function called on generation increase
    // Order matters here if there are any cross contract dependencies on the
    // actions taking on generation increase.
    bytes32[] public notificationHashes;

    /** The on-chain address for the policy proposal process contract. The
     * contract is cloned for every policy decision process.
     */
    PolicyProposals public policyProposalImpl;

    /**
     * An event indicating that a new generation has started.
     *
     * @param generation The generation number for the new generation.
     */
    event NewGeneration(uint256 indexed generation);

    /** An event indicating that a policy decision process has started. The
     * address included indicates where on chain the relevant contract can be
     * found. This event is emitted by `startPolicyProposals` to indicate that
     * a new decision process has started, and to help track historical vote
     * contracts.
     *
     * @param contractAddress The address of the PolicyProposals contract.
     */
    event PolicyDecisionStart(address contractAddress);

    constructor(
        Policy _policy,
        PolicyProposals _policyproposal,
        bytes32[] memory _notificationHashes
    ) PolicedUtils(_policy) {
        require(
            address(_policyproposal) != address(0),
            "Unrecoverable: do not set the _policyproposal as the zero address"
        );
        require(
            _notificationHashes.length > 0,
            "Unrecoverable: must set _notificationHashes"
        );
        policyProposalImpl = _policyproposal;
        generation = GENERATION_START;
        notificationHashes = _notificationHashes;
    }

    function initialize(address _self) public override onlyConstruction {
        super.initialize(_self);
        // implementations are left mutable for easier governance
        policyProposalImpl = TimedPolicies(_self).policyProposalImpl();

        generation = TimedPolicies(_self).generation();
        notificationHashes = TimedPolicies(_self).getNotificationHashes();
    }

    function getNotificationHashes() public view returns (bytes32[] memory) {
        return notificationHashes;
    }

    /**
     * This function kicks off a new generation
     * The process of a new generation is a bit of a chain reaction of creating contracts
     * This function only directly clones and configures the PolicyProposals contract
     * Everything else is notified via the notificationHashes array
     * At launch this contains the ECO contract and the CurrencyGovernance contract
     * however the structure is extensible to other contracts if needed.
     */
    function incrementGeneration() external {
        uint256 time = getTime();
        require(
            time >= nextGenerationWindowOpen,
            "Cannot update the generation counter so soon"
        );

        nextGenerationWindowOpen = time + MIN_GENERATION_DURATION;
        generation++;

        CurrencyGovernance bg = CurrencyGovernance(
            policyFor(ID_CURRENCY_GOVERNANCE)
        );

        uint256 _numberOfRecipients;
        uint256 _randomInflationReward;

        if (address(bg) != address(0)) {
            address winner = bg.winner();
            if (winner != address(0)) {
                (_numberOfRecipients, _randomInflationReward, , , , ) = bg
                    .proposals(winner);
            }
        }

        uint256 mintedOnGenerationIncrease = _numberOfRecipients *
            _randomInflationReward;

        // snapshot the ECOx total
        uint256 totalx = ECOx(policyFor(ID_ECOX)).totalSupply();

        PolicyProposals _proposals = PolicyProposals(
            policyProposalImpl.clone()
        );

        /**
         * totalx not allowed to be passed through as zero as a safeguard to if ECOx is
         * completely burned without first removing this part of the system
         */
        _proposals.configure(
            totalx == 0 ? 1 : totalx,
            mintedOnGenerationIncrease
        );

        policy.setPolicy(
            ID_POLICY_PROPOSALS,
            address(_proposals),
            ID_TIMED_POLICIES
        );

        uint256 notificationHashesLength = notificationHashes.length;
        for (uint256 i = 0; i < notificationHashesLength; ++i) {
            IGenerationIncrease notified = IGenerationIncrease(
                policy.policyFor(notificationHashes[i])
            );
            if (address(notified) != address(0)) {
                notified.notifyGenerationIncrease();
            }
        }

        emit PolicyDecisionStart(address(_proposals));
        emit NewGeneration(generation);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../policy/Policy.sol";
import "../../currency/IECO.sol";
import "../../policy/PolicedUtils.sol";
import "./proposals/Proposal.sol";
import "./PolicyVotes.sol";
import "./VotingPower.sol";
import "../../utils/TimeUtils.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/** @title PolicyProposals
 * `PolicyProposals` oversees the proposals phase of the policy decision
 * process. Proposals can be submitted by anyone willing to put forth funds, and
 * submitted proposals can be supported by anyone
 *
 * First, during the proposals portion of the proposals phase, proposals can be
 * submitted (for a fee). This is parallelized with a signal voting process where
 * support can be distributed and redistributed to proposals after they are submitted.
 *
 * A proposal that makes it to support above 30% of the total possible support ends this
 * phase and starts a vote.
 */
contract PolicyProposals is VotingPower, TimeUtils {
    /** The data tracked for a proposal in the process.
     */
    struct PropData {
        // the returnable data
        PropMetadata metadata;
        // A record of which addresses have already staked in support of the proposal
        mapping(address => bool) staked;
    }

    /** The submitted data for a proposal submitted to the process.
     */
    struct PropMetadata {
        /* The address of the proposing account.
         */
        address proposer;
        /* The address of the proposal contract.
         */
        Proposal proposal;
        /* The amount of tokens staked in support of this proposal.
         */
        uint256 totalStake;
        /* Flag to mark if a pause caused the fee to be waived.
         */
        bool feeWaived;
    }

    /** The set of proposals under consideration.
     * maps from addresses of proposals to structs containing with info and
     * the staking data (structs defined above)
     */
    mapping(Proposal => PropData) public proposals;

    /** The total number of proposals made.
     */
    uint256 public totalProposals;

    /** The duration of the proposal portion of the proposal phase.
     */
    uint256 public constant PROPOSAL_TIME = 9 days + 16 hours;

    /** Whether or not a winning proposal has been selected
     */
    bool public proposalSelected;

    /** Selected proposal awaiting configuration before voting
     */
    Proposal public proposalToConfigure;

    /** The minimum cost to register a proposal.
     */
    uint256 public constant COST_REGISTER = 10000e18;

    /** The amount refunded if a proposal does not get selected.
     */
    uint256 public constant REFUND_IF_LOST = 5000e18;

    /** The percentage of total voting power required to push to a vote.
     */
    uint256 public constant SUPPORT_THRESHOLD = 15;

    /** The divisor for the above constant, tracks the digits of precision.
     */
    uint256 public constant SUPPORT_THRESHOLD_DIVISOR = 100;

    /** The total voting value against which to compare for the threshold
     * This is a fixed digit number with 2 decimal digits
     * see SUPPORT_THRESHOLD_DIVISOR variable
     */
    uint256 public totalVotingThreshold;

    /** The time at which the proposal portion of the proposals phase ends.
     */
    uint256 public proposalEnds;

    /** The block number of the balance stores to use for staking in
     * support of a proposal.
     */
    uint256 public blockNumber;

    /** The address of the `PolicyVotes` contract, to be cloned for the voting
     * phase.
     */
    PolicyVotes public policyVotesImpl;

    /** An event indicating a proposal has been proposed
     *
     * @param proposer The address that submitted the Proposal
     * @param proposalAddress The address of the Proposal contract instance that was added
     */
    event Register(address indexed proposer, Proposal indexed proposalAddress);

    /** An event indicating that proposal have been supported by stake.
     *
     * @param supporter The address submitting their support for the proposal
     * @param proposalAddress The address of the Proposal contract instance that was supported
     */
    event Support(address indexed supporter, Proposal indexed proposalAddress);

    /** An event indicating that support has been removed from a proposal.
     *
     * @param unsupporter The address removing their support for the proposal
     * @param proposalAddress The address of the Proposal contract instance that was unsupported
     */
    event Unsupport(
        address indexed unsupporter,
        Proposal indexed proposalAddress
    );

    /** An event indicating a proposal has reached its support threshold
     *
     * @param proposalAddress The address of the Proposal contract instance that reached the threshold.
     */
    event SupportThresholdReached(Proposal indexed proposalAddress);

    /** An event indicating that a proposal has been accepted for voting
     *
     * @param contractAddress The address of the PolicyVotes contract instance.
     */
    event VoteStart(PolicyVotes indexed contractAddress);

    /** An event indicating that proposal fee was partially refunded.
     *
     * @param proposer The address of the proposee which was refunded
     * @param proposalAddress The address of the Proposal instance that was refunded
     */
    event ProposalRefund(
        address indexed proposer,
        Proposal indexed proposalAddress
    );

    /** Construct a new PolicyProposals instance using the provided supervising
     * policy (root) and supporting contracts.
     *
     * @param _policy The address of the root policy contract.
     * @param _policyvotes The address of the contract that will be cloned to
     *                     oversee the voting phase.
     * @param _ecoAddr The address of the ECO token contract.
     */
    constructor(
        Policy _policy,
        PolicyVotes _policyvotes,
        ECO _ecoAddr
    ) VotingPower(_policy, _ecoAddr) {
        require(
            address(_policyvotes) != address(0),
            "Unrecoverable: do not set the _policyvotes as the zero address"
        );
        policyVotesImpl = _policyvotes;
    }

    /** Initialize the storage context using parameters copied from the original
     * contract (provided as _self).
     *
     * Can only be called once, during proxy initialization.
     *
     * @param _self The original contract address.
     */
    function initialize(address _self) public override onlyConstruction {
        super.initialize(_self);

        // implementation addresses are left as mutable for easier governance
        policyVotesImpl = PolicyProposals(_self).policyVotesImpl();

        proposalEnds = getTime() + PROPOSAL_TIME;
        blockNumber = block.number;
    }

    /** Submit a proposal.
     *
     * You must approve the policy proposals contract to withdraw the required
     * fee from your account before calling this.
     *
     * Can only be called during the proposals portion of the proposals phase.
     * Each proposal may only be submitted once.
     *
     * @param _prop The address of the proposal to submit.
     */
    function registerProposal(Proposal _prop) external {
        require(
            address(_prop) != address(0),
            "The proposal address can't be 0"
        );

        require(
            getTime() < proposalEnds && !proposalSelected,
            "Proposals may no longer be registered because the registration period has ended"
        );

        PropMetadata storage _p = proposals[_prop].metadata;

        require(
            address(_p.proposal) == address(0),
            "A proposal may only be registered once"
        );

        _p.proposal = _prop;
        _p.proposer = msg.sender;

        totalProposals++;

        // if eco token is paused, the proposal fee can't be and isn't collected
        if (!ecoToken.paused()) {
            require(
                ecoToken.transferFrom(msg.sender, address(this), COST_REGISTER),
                "The token cost of registration must be approved to transfer prior to calling registerProposal"
            );
        } else {
            _p.feeWaived = true;
        }

        emit Register(msg.sender, _prop);

        // check if totalVotingThreshold still needs to be precomputed
        if (totalVotingThreshold == 0) {
            totalVotingThreshold =
                totalVotingPower(blockNumber) *
                SUPPORT_THRESHOLD;
        }
    }

    /** Stake in support of an existing proposal.
     *
     * Can only be called during the staking portion of the proposals phase.
     *
     * Your voting strength is added to the supporting stake of the proposal.
     *
     * @param _prop The proposal to support.
     */
    function support(Proposal _prop) external {
        require(
            policyFor(ID_POLICY_PROPOSALS) == address(this),
            "Proposal contract no longer active"
        );
        require(!proposalSelected, "A proposal has already been selected");
        require(
            getTime() < proposalEnds,
            "Proposals may no longer be supported because the registration period has ended"
        );

        PropData storage _p = proposals[_prop];
        PropMetadata storage _pMeta = _p.metadata;

        require(
            address(_pMeta.proposal) != address(0),
            "The supported proposal is not registered"
        );
        require(
            !_p.staked[msg.sender],
            "You may not stake in support of a proposal twice"
        );

        uint256 _amount = votingPower(msg.sender, blockNumber);

        require(
            _amount > 0,
            "In order to support a proposal you must stake a non-zero amount of tokens"
        );

        uint256 _totalStake = _pMeta.totalStake + _amount;

        _pMeta.totalStake = _totalStake;
        _p.staked[msg.sender] = true;

        emit Support(msg.sender, _prop);

        if (_totalStake * SUPPORT_THRESHOLD_DIVISOR > totalVotingThreshold) {
            emit SupportThresholdReached(_prop);
            proposalSelected = true;
            proposalToConfigure = _prop;
        }
    }

    function unsupport(Proposal _prop) external {
        require(
            policyFor(ID_POLICY_PROPOSALS) == address(this),
            "Proposal contract no longer active"
        );
        require(!proposalSelected, "A proposal has already been selected");
        require(
            getTime() < proposalEnds,
            "Proposals may no longer be supported because the registration period has ended"
        );

        PropData storage _p = proposals[_prop];

        require(_p.staked[msg.sender], "You have not staked this proposal");

        uint256 _amount = votingPower(msg.sender, blockNumber);
        _p.metadata.totalStake -= _amount;
        _p.staked[msg.sender] = false;

        emit Unsupport(msg.sender, _prop);
    }

    function deployProposalVoting() external {
        require(proposalSelected, "no proposal has been selected");
        Proposal _proposalToConfigure = proposalToConfigure;
        require(
            address(_proposalToConfigure) != address(0),
            "voting has already been deployed"
        );
        address _proposer = proposals[_proposalToConfigure].metadata.proposer;

        delete proposalToConfigure;
        delete proposals[_proposalToConfigure];
        totalProposals--;

        PolicyVotes pv = PolicyVotes(policyVotesImpl.clone());
        pv.configure(
            _proposalToConfigure,
            _proposer,
            blockNumber,
            totalECOxSnapshot,
            excludedVotingPower
        );
        policy.setPolicy(ID_POLICY_VOTES, address(pv), ID_POLICY_PROPOSALS);

        emit VoteStart(pv);
    }

    /** Refund the fee for a proposal that was not selected.
     *
     * Returns a partial refund only, does not work on proposals that are
     * on the ballot for the voting phase, and can only be called after voting
     * been deployed or when the period is over and no vote was selected.
     *
     * @param _prop The proposal to issue a refund for.
     */
    function refund(Proposal _prop) external {
        require(
            (proposalSelected && address(proposalToConfigure) == address(0)) ||
                getTime() > proposalEnds,
            "Refunds may not be distributed until the period is over or voting has started"
        );

        require(
            address(_prop) != address(0),
            "The proposal address can't be 0"
        );

        PropMetadata storage _p = proposals[_prop].metadata;

        require(
            _p.proposal == _prop,
            "The provided proposal address is not valid"
        );

        address receiver = _p.proposer;
        bool _feePaid = !_p.feeWaived;

        delete proposals[_prop];
        totalProposals--;

        // if fee was waived, still delete the proposal, but do not refund
        if (_feePaid) {
            require(
                ecoToken.transfer(receiver, REFUND_IF_LOST),
                "Transfer Failed"
            );
            emit ProposalRefund(receiver, _prop);
        }
    }

    /** Reclaim tokens after end time
     * only callable if all proposals are refunded
     */
    function destruct() external {
        require(
            proposalSelected || getTime() > proposalEnds,
            "The destruct operation can only be performed when the period is over"
        );

        require(totalProposals == 0, "Must refund all missed proposals first");

        policy.removeSelf(ID_POLICY_PROPOSALS);

        require(
            ecoToken.transfer(
                address(policy),
                ecoToken.balanceOf(address(this))
            ),
            "Transfer Failed"
        );
    }

    // configure the total voting power for the vote thresholds
    function configure(uint256 _totalECOxSnapshot, uint256 _excludedVotingPower)
        external
    {
        require(
            totalECOxSnapshot == 0,
            "This instance has already been configured"
        );
        require(_totalECOxSnapshot != 0, "Invalid value for ECOx voting power");

        totalECOxSnapshot = _totalECOxSnapshot;
        excludedVotingPower = _excludedVotingPower;
    }
}

/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* solhint-disable no-inline-assembly */

/** @title Target for ForwardProxy and EcoInitializable */
abstract contract ForwardTarget {
    // Must match definition in ForwardProxy
    // keccak256("com.eco.ForwardProxy.target")
    uint256 private constant IMPLEMENTATION_SLOT =
        0xf86c915dad5894faca0dfa067c58fdf4307406d255ed0a65db394f82b77f53d4;

    modifier onlyConstruction() {
        require(
            implementation() == address(0),
            "Can only be called during initialization"
        );
        _;
    }

    constructor() {
        setImplementation(address(this));
    }

    /** @notice Storage initialization of cloned contract
     *
     * This is used to initialize the storage of the forwarded contract, and
     * should (typically) copy or repeat any work that would normally be
     * done in the constructor of the proxied contract.
     *
     * Implementations of ForwardTarget should override this function,
     * and chain to super.initialize(_self).
     *
     * @param _self The address of the original contract instance (the one being
     *              forwarded to).
     */
    function initialize(address _self) public virtual onlyConstruction {
        address _implAddress = address(ForwardTarget(_self).implementation());
        require(
            _implAddress != address(0),
            "initialization failure: nothing to implement"
        );
        setImplementation(_implAddress);
    }

    /** Get the address of the proxy target contract.
     */
    function implementation() public view returns (address _impl) {
        assembly {
            _impl := sload(IMPLEMENTATION_SLOT)
        }
    }

    /** @notice Set new implementation */
    function setImplementation(address _impl) internal {
        require(implementation() != _impl, "Implementation already matching");
        assembly {
            sstore(IMPLEMENTATION_SLOT, _impl)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";

/** @title Utilities for interfacing with ERC1820
 */
abstract contract ERC1820Client {
    IERC1820Registry internal constant ERC1820REGISTRY =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);

    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";

import "../clone/CloneFactory.sol";
import "./Policed.sol";
import "./ERC1820Client.sol";

/** @title Utility providing helpers for policed contracts
 *
 * See documentation for Policed to understand what a policed contract is.
 */
abstract contract PolicedUtils is Policed, CloneFactory {
    bytes32 internal constant ID_FAUCET = keccak256("Faucet");
    bytes32 internal constant ID_ECO = keccak256("ECO");
    bytes32 internal constant ID_ECOX = keccak256("ECOx");
    bytes32 internal constant ID_TIMED_POLICIES = keccak256("TimedPolicies");
    bytes32 internal constant ID_TRUSTED_NODES = keccak256("TrustedNodes");
    bytes32 internal constant ID_POLICY_PROPOSALS =
        keccak256("PolicyProposals");
    bytes32 internal constant ID_POLICY_VOTES = keccak256("PolicyVotes");
    bytes32 internal constant ID_CURRENCY_GOVERNANCE =
        keccak256("CurrencyGovernance");
    bytes32 internal constant ID_CURRENCY_TIMER = keccak256("CurrencyTimer");
    bytes32 internal constant ID_ECOXSTAKING = keccak256("ECOxStaking");

    // The minimum time of a generation.
    uint256 public constant MIN_GENERATION_DURATION = 14 days;
    // The initial generation
    uint256 public constant GENERATION_START = 1000;

    address internal expectedInterfaceSet;

    constructor(Policy _policy) Policed(_policy) {}

    /** ERC1820 permissioning interface
     *
     * @param _addr The address of the contract this might act on behalf of.
     */
    function canImplementInterfaceForAddress(bytes32, address _addr)
        external
        view
        override
        returns (bytes32)
    {
        require(
            _addr == address(policy) || _addr == expectedInterfaceSet,
            "Only the policy or interface contract can set the interface"
        );
        return ERC1820_ACCEPT_MAGIC;
    }

    /** Set the expected interface set
     */
    function setExpectedInterfaceSet(address _addr) public onlyPolicy {
        expectedInterfaceSet = _addr;
    }

    /** Create a clone of this contract
     *
     * Creates a clone of this contract by instantiating a proxy at a new
     * address and initializing it based on the current contract. Uses
     * optionality.io's CloneFactory functionality.
     *
     * This is used to save gas cost during deployments. Rather than including
     * the full contract code in every contract that might instantiate it, it
     * can be deployed once and the location it was deployed can be referred to for
     * cloning. The calls to clone() create instances as needed without
     * increasing the code size of the instantiating contract.
     */
    function clone() public virtual returns (address) {
        require(
            implementation() == address(this),
            "This method cannot be called on clones"
        );
        address _clone = createClone(address(this));
        PolicedUtils(_clone).initialize(address(this));
        return _clone;
    }

    /** Find the policy contract for a particular identifier.
     *
     * This is intended as a helper function for contracts that are managed by
     * a policy framework. A typical use case is checking if the address calling
     * a function is the authorized policy for a particular action.
     *
     * eg:
     * ```
     * function doSomethingPrivileged() public {
     *   require(
     *     msg.sender == policyFor(keccak256("PolicyForDoingPrivilegedThing")),
     *     "Only the privileged contract may call this"
     *     );
     * }
     * ```
     */
    function policyFor(bytes32 _id) internal view returns (address) {
        return ERC1820REGISTRY.getInterfaceImplementer(address(policy), _id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGenerationIncrease {
    function notifyGenerationIncrease() external;
}

/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IECO.sol";
import "../policy/PolicedUtils.sol";
import "./ERC20Pausable.sol";

/** @title An ERC20 token interface for ECOx
 *
 * Contains the conversion mechanism for turning ECOx into ECO.
 */
contract ECOx is ERC20Pausable, PolicedUtils {
    // bits of precision used in the exponentiation approximation
    uint8 public constant PRECISION_BITS = 100;

    uint256 public immutable initialSupply;

    // the address of the contract for initial distribution
    address public immutable distributor;

    // the address of the ECO token contract
    IECO public immutable ecoToken;

    constructor(
        Policy _policy,
        address _distributor,
        uint256 _initialSupply,
        IECO _ecoAddr,
        address _initialPauser
    )
        ERC20Pausable("ECOx", "ECOx", address(_policy), _initialPauser)
        PolicedUtils(_policy)
    {
        require(_initialSupply > 0, "initial supply not properly set");
        require(
            address(_ecoAddr) != address(0),
            "Do not set the ECO address as the zero address"
        );

        initialSupply = _initialSupply;
        distributor = _distributor;
        ecoToken = _ecoAddr;
    }

    function initialize(address _self)
        public
        virtual
        override
        onlyConstruction
    {
        super.initialize(_self);
        pauser = ERC20Pausable(_self).pauser();
        _mint(distributor, initialSupply);
    }

    function ecoValueOf(uint256 _ecoXValue) public view returns (uint256) {
        uint256 _ecoSupply = ecoToken.totalSupply();

        return computeValue(_ecoXValue, _ecoSupply);
    }

    function valueAt(uint256 _ecoXValue, uint256 _blockNumber)
        public
        view
        returns (uint256)
    {
        uint256 _ecoSupplyAt = ecoToken.totalSupplyAt(_blockNumber);

        return computeValue(_ecoXValue, _ecoSupplyAt);
    }

    function computeValue(uint256 _ecoXValue, uint256 _ecoSupply)
        internal
        view
        returns (uint256)
    {
        uint256 _preciseRatio = safeLeftShift(_ecoXValue, PRECISION_BITS) /
            initialSupply;

        return
            (generalExp(_preciseRatio, PRECISION_BITS) * _ecoSupply) >>
            PRECISION_BITS;
    }

    function safeLeftShift(uint256 value, uint8 shift)
        internal
        pure
        returns (uint256)
    {
        uint256 _result = value << shift;
        require(
            _result >> shift == value,
            "value too large, shift out of bounds"
        );
        return _result;
    }

    /**
     * @dev this function can be auto-generated by the script 'PrintFunctionGeneralExp.py'.
     * it approximates "e ^ x" via maclaurin summation: "(x^0)/0! + (x^1)/1! + ... + (x^n)/n!".
     * it returns "e ^ (x / 2 ^ precision) * 2 ^ precision", that is, the result is upshifted for accuracy.
     * the global "maxExpArray" maps each "precision" to "((maximumExponent + 1) << (MAX_PRECISION - precision)) - 1".
     * the maximum permitted value for "x" is therefore given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
     */
    function generalExp(uint256 _x, uint8 _precision)
        internal
        pure
        returns (uint256)
    {
        uint256 xi = _x;
        uint256 res = 0;

        xi = (xi * _x) >> _precision;
        res += xi * 0x3442c4e6074a82f1797f72ac0000000; // add x^02 * (33! / 02!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x116b96f757c380fb287fd0e40000000; // add x^03 * (33! / 03!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x045ae5bdd5f0e03eca1ff4390000000; // add x^04 * (33! / 04!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00defabf91302cd95b9ffda50000000; // add x^05 * (33! / 05!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x002529ca9832b22439efff9b8000000; // add x^06 * (33! / 06!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00054f1cf12bd04e516b6da88000000; // add x^07 * (33! / 07!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000a9e39e257a09ca2d6db51000000; // add x^08 * (33! / 08!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000012e066e7b839fa050c309000000; // add x^09 * (33! / 09!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000001e33d7d926c329a1ad1a800000; // add x^10 * (33! / 10!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000002bee513bdb4a6b19b5f800000; // add x^11 * (33! / 11!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000003a9316fa79b88eccf2a00000; // add x^12 * (33! / 12!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000048177ebe1fa812375200000; // add x^13 * (33! / 13!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000005263fe90242dcbacf00000; // add x^14 * (33! / 14!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000057e22099c030d94100000; // add x^15 * (33! / 15!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000057e22099c030d9410000; // add x^16 * (33! / 16!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000052b6b54569976310000; // add x^17 * (33! / 17!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000004985f67696bf748000; // add x^18 * (33! / 18!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000003dea12ea99e498000; // add x^19 * (33! / 19!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000031880f2214b6e000; // add x^20 * (33! / 20!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000025bcff56eb36000; // add x^21 * (33! / 21!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000001b722e10ab1000; // add x^22 * (33! / 22!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000001317c70077000; // add x^23 * (33! / 23!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000cba84aafa00; // add x^24 * (33! / 24!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000082573a0a00; // add x^25 * (33! / 25!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000005035ad900; // add x^26 * (33! / 26!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000000000002f881b00; // add x^27 * (33! / 27!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000001b29340; // add x^28 * (33! / 28!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000000000efc40; // add x^29 * (33! / 29!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000007fe0; // add x^30 * (33! / 30!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000000420; // add x^31 * (33! / 31!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000000021; // add x^32 * (33! / 32!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000000001; // add x^33 * (33! / 33!)

        return res / 0x688589cc0e9505e2f2fee5580000000 + _x; // divide by 33! and then add x^1 / 1! + x^0 / 0!
    }

    function exchange(uint256 _ecoXValue) external {
        uint256 eco = ecoValueOf(_ecoXValue);

        _burn(msg.sender, _ecoXValue);

        ecoToken.mint(msg.sender, eco);
    }

    function mint(address _to, uint256 _value) external {
        require(
            msg.sender == policyFor(ID_FAUCET),
            "Caller not authorized to mint tokens"
        );

        _mint(_to, _value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGeneration {
    // generations index from 1000, see GENERATION_START in PolicedUtils.sol
    // @return uint256 generation number
    function generation() external view returns (uint256);
}

/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./InflationCheckpoints.sol";
import "../governance/monetary/CurrencyGovernance.sol";
import "../governance/IGeneration.sol";

/** @title An ERC20 token interface to the Eco currency system.
 */
contract ECO is InflationCheckpoints {
    /** Fired when a proposal with a new inflation multiplier is selected and passed.
     * Used to calculate new values for the rebased token.
     */
    event NewInflationMultiplier(uint256 inflationMultiplier);

    /* Current generation of the balance store. */
    uint256 public currentGeneration;

    // the address of the contract for initial distribution
    address public immutable distributor;

    uint256 public immutable initialSupply;

    constructor(
        Policy _policy,
        address _distributor,
        uint256 _initialSupply,
        address _initialPauser
    ) InflationCheckpoints(_policy, "ECO", "ECO", _initialPauser) {
        distributor = _distributor;
        initialSupply = _initialSupply;
    }

    function initialize(address _self)
        public
        virtual
        override
        onlyConstruction
    {
        super.initialize(_self);
        pauser = ERC20Pausable(_self).pauser();
        _mint(distributor, initialSupply);
    }

    function mint(address _to, uint256 _value) external {
        require(
            msg.sender == policyFor(ID_CURRENCY_TIMER) ||
                msg.sender == policyFor(ID_ECOX) ||
                msg.sender == policyFor(ID_FAUCET),
            "Caller not authorized to mint tokens"
        );

        _mint(_to, _value);
    }

    function burn(address _from, uint256 _value) external {
        require(
            msg.sender == _from || msg.sender == policyFor(ID_CURRENCY_TIMER),
            "Caller not authorized to burn tokens"
        );

        _burn(_from, _value);
    }

    function notifyGenerationIncrease() public virtual override {
        uint256 _old = currentGeneration;
        uint256 _new = IGeneration(policyFor(ID_TIMED_POLICIES)).generation();
        require(_new != _old, "Generation has not increased");

        // update currentGeneration
        currentGeneration = _new;

        CurrencyGovernance bg = CurrencyGovernance(
            policyFor(ID_CURRENCY_GOVERNANCE)
        );

        if (address(bg) != address(0)) {
            if (
                uint8(bg.currentStage()) <
                uint8(CurrencyGovernance.Stage.Compute)
            ) {
                bg.updateStage();
            }
            if (
                uint8(bg.currentStage()) ==
                uint8(CurrencyGovernance.Stage.Compute)
            ) {
                bg.compute();
            }
            address winner = bg.winner();
            if (winner != address(0)) {
                uint256 _inflationMultiplier;
                (, , , , _inflationMultiplier, ) = bg.proposals(winner);
                emit NewInflationMultiplier(_inflationMultiplier);

                // updates the inflation value
                uint256 _newInflationMultiplier = (_linearInflationCheckpoints[
                    _linearInflationCheckpoints.length - 1
                ].value * _inflationMultiplier) / INITIAL_INFLATION_MULTIPLIER;
                _writeCheckpoint(
                    _linearInflationCheckpoints,
                    _replace,
                    _newInflationMultiplier
                );
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** @title TimeUtils
 * Utility class for time, allowing easy unit testing.
 */
abstract contract TimeUtils {
    /** Determine the current time as perceived by the policy timing contract.
     *
     * Used extensively in testing, but also useful in production for
     * determining what processes can currently be run.
     */
    function getTime() internal view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
The MIT License (MIT)

Copyright (c) 2018 Murray Software, LLC.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
/* solhint-disable */

// See the EIP-1167: http://eips.ethereum.org/EIPS/eip-1167 and
// clone-factory: https://github.com/optionality/clone-factory for details.

abstract contract CloneFactory {
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC1820Implementer.sol";
import "../proxy/ForwardTarget.sol";
import "./Policy.sol";

/** @title Policed Contracts
 *
 * A policed contract is any contract managed by a policy.
 */
abstract contract Policed is ForwardTarget, IERC1820Implementer, ERC1820Client {
    bytes32 internal constant ERC1820_ACCEPT_MAGIC =
        keccak256("ERC1820_ACCEPT_MAGIC");

    /** The address of the root policy instance overseeing this instance.
     *
     * This address can be used for ERC1820 lookup of other components, ERC1820
     * lookup of role policies, and interaction with the policy hierarchy.
     */
    Policy public immutable policy;

    /** Restrict method access to the root policy instance only.
     */
    modifier onlyPolicy() {
        require(
            msg.sender == address(policy),
            "Only the policy contract may call this method"
        );
        _;
    }

    constructor(Policy _policy) {
        require(
            address(_policy) != address(0),
            "Unrecoverable: do not set the policy as the zero address"
        );
        policy = _policy;
        ERC1820REGISTRY.setManager(address(this), address(_policy));
    }

    /** ERC1820 permissioning interface
     *
     * @param _addr The address of the contract this might act on behalf of.
     */
    function canImplementInterfaceForAddress(bytes32, address _addr)
        external
        view
        virtual
        override
        returns (bytes32)
    {
        require(
            _addr == address(policy),
            "This contract only implements interfaces for the policy contract"
        );
        return ERC1820_ACCEPT_MAGIC;
    }

    /** Initialize the contract (replaces constructor)
     *
     * Policed contracts are often the targets of proxies, and therefore need a
     * mechanism to initialize internal state when adopted by a new proxy. This
     * replaces the constructor.
     *
     * @param _self The address of the original contract deployment (as opposed
     *              to the address of the proxy contract, which takes the place
     *              of `this`).
     */
    function initialize(address _self)
        public
        virtual
        override
        onlyConstruction
    {
        super.initialize(_self);
        ERC1820REGISTRY.setManager(address(this), address(policy));
    }

    /** Execute code as indicated by the managing policy contract
     *
     * Governance allows the managing policy contract to execute arbitrary code in this
     * contract's context by allowing it to specify an implementation address and
     * some message data, and then using delegatecall to execute the code at the
     * implementation address, passing in the message data, all within the protocol's
     * address space.
     *
     * @param _delegate The address of the contract to delegate execution to.
     * @param _data The call message/data to execute on.
     */
    function policyCommand(address _delegate, bytes memory _data)
        public
        onlyPolicy
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            /* Call the address indicated by _delegate passing the data in _data
             * as the call message using delegatecall. This allows the calling
             * of arbitrary functions on _delegate (by encoding the call message
             * into _data) in the context of the current contract's storage.
             */
            let result := delegatecall(
                gas(),
                _delegate,
                add(_data, 0x20),
                mload(_data),
                0,
                0
            )
            /* Collect up the return data from delegatecall and prepare it for
             * returning to the caller of policyCommand.
             */
            let size := returndatasize()
            returndatacopy(0x0, 0, size)
            /* If the delegated call reverted then revert here too. Otherwise
             * forward the return data prepared above.
             */
            switch result
            case 0 {
                revert(0x0, size)
            }
            default {
                return(0x0, size)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC1820Implementer.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for an ERC1820 implementer, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820#interface-implementation-erc1820implementerinterface[EIP].
 * Used by contracts that will be registered as implementers in the
 * {IERC1820Registry}.
 */
interface IERC1820Implementer {
    /**
     * @dev Returns a special value (`ERC1820_ACCEPT_MAGIC`) if this contract
     * implements `interfaceHash` for `account`.
     *
     * See {IERC1820Registry-setInterfaceImplementer}.
     */
    function canImplementInterfaceForAddress(bytes32 interfaceHash, address account) external view returns (bytes32);
}

/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IECO is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function currentGeneration() external view returns (uint256);

    /**
     *  Returns final votes of an address at the end of a blocknumber
     */
    function getPastVotes(address owner, uint256 blockNumber)
        external
        view
        returns (uint256);

    /**
     * Returns the final total supply at the end of the given block number
     */
    function totalSupplyAt(uint256 blockNumber) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./ERC20.sol";

/**
 * @dev Implementation of the {IERC20} interface with pausability
 * When paused by the pauser admin, transfers revert.
 */
contract ERC20Pausable is ERC20, Pausable {
    address public immutable roleAdmin;

    // initially no-one should have the pauser role
    // it can be granted and revoked by the admin policy
    address public pauser;

    /**
     * @notice event indicating the pauser was updated
     * @param pauser The new pauser
     */
    event PauserAssignment(address indexed pauser);

    constructor(
        string memory name,
        string memory symbol,
        address _roleAdmin,
        address _initialPauser
    ) ERC20(name, symbol) {
        require(
            address(_roleAdmin) != address(0),
            "Unrecoverable: do not set the _roleAdmin as the zero address"
        );
        roleAdmin = _roleAdmin;
        pauser = _initialPauser;
        emit PauserAssignment(_initialPauser);
    }

    modifier onlyAdmin() {
        require(msg.sender == roleAdmin, "ERC20Pausable: not admin");
        _;
    }

    modifier onlyPauser() {
        require(msg.sender == pauser, "ERC20Pausable: not pauser");
        _;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * If the token is not paused, it will pass through the amount
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override whenNotPaused returns (uint256) {
        return amount;
    }

    /**
     * @notice pauses transfers of this token
     * @dev only callable by the pauser
     */
    function pause() external onlyPauser {
        _pause();
    }

    /**
     * @notice unpauses transfers of this token
     * @dev only callable by the pauser
     */
    function unpause() external onlyPauser {
        _unpause();
    }

    /**
     * @notice set the given address as the pauser
     * @param _pauser The address that can pause this token
     * @dev only the roleAdmin can call this function
     */
    function setPauser(address _pauser) public onlyAdmin {
        require(_pauser != pauser, "ERC20Pausable: must change pauser");
        pauser = _pauser;
        emit PauserAssignment(_pauser);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/StringPacker.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./ERC20Permit.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This comment taken from the openzeppelin source contract.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
// internal _name and _symbol are stored immutable as bytes32 and unpacked via StringPacker
contract ERC20 is ERC20Permit {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    bytes32 internal immutable _name;
    bytes32 internal immutable _symbol;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) ERC20Permit(name_) {
        _name = StringPacker.pack(name_);
        _symbol = StringPacker.pack(symbol_);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return StringPacker.unpack(_name);
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return StringPacker.unpack(_symbol);
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + addedValue
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 originalAmount
    ) internal virtual {
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 amount = _beforeTokenTransfer(
            sender,
            recipient,
            originalAmount
        );

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, originalAmount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 originalAmount)
        internal
        virtual
        returns (uint256)
    {
        require(account != address(0), "ERC20: mint to the zero address");

        uint256 amount = _beforeTokenTransfer(
            address(0),
            account,
            originalAmount
        );

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, originalAmount);

        _afterTokenTransfer(address(0), account, amount);

        return amount;
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 originalAmount)
        internal
        virtual
        returns (uint256)
    {
        uint256 amount = _beforeTokenTransfer(
            account,
            address(0),
            originalAmount
        );

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), originalAmount);

        _afterTokenTransfer(account, address(0), amount);

        return amount;
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual override {
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address, // from
        address, // to
        uint256 amount
    ) internal virtual returns (uint256) {
        return amount;
    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

pragma solidity ^0.8.0;

library StringPacker {
    // takes a string of 31 or less characters and converts it to bytes32
    function pack(string memory unpacked)
        internal
        pure
        returns (bytes32 packed)
    {
        // do not use this function in a lossy way, it will not work
        // only strings with 31 or less characters are stored in memory packed with their length value
        require(bytes(unpacked).length < 32);
        // shift the memory pointer to pack the length of the string into the high byte
        // by assigning this to the return value, the type of bytes32 means that, when returning,
        // the pointer continues to read into the string data
        assembly {
            packed := mload(add(unpacked, 31))
        }
    }

    // takes a bytes32 packed in the format above and unpacks it into a string
    function unpack(bytes32 packed)
        internal
        pure
        returns (string memory unpacked)
    {
        // get the high byte which stores the length of the string when unpacked
        uint256 len = uint256(packed >> 248);
        // ensure that the length of the unpacked string doesn't read beyond the input value
        require(len < 32);
        // initialize the return value with the length
        unpacked = string(new bytes(len));
        // shift the pointer so that the length will be at the bottom of the word to match string encoding
        // then store the packed value
        assembly {
            // Potentially writes into unallocated memory as the length in the packed form will trail off the end
            // This is fine as there are no other relevant memory values to overwrite
            mstore(add(unpacked, 31), packed)
        }
    }
}

// SPDX-License-Identifier: MIT
// Heavily inspired by:
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {
        //empty block in order to pass parameters to the parent EIP712 constructor
    }

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                _useNonce(owner),
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner)
        internal
        virtual
        returns (uint256 current)
    {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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

/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../currency/VoteCheckpoints.sol";
import "../governance/IGenerationIncrease.sol";
import "../policy/PolicedUtils.sol";

/** @title InflationCheckpoints
 * This implements a generational store with snapshotted balances. Balances
 * are lazy-evaluated, but are effectively all atomically snapshotted when
 * the generation changes.
 */
abstract contract InflationCheckpoints is
    VoteCheckpoints,
    PolicedUtils,
    IGenerationIncrease
{
    uint256 public constant INITIAL_INFLATION_MULTIPLIER = 1e18;

    Checkpoint[] internal _linearInflationCheckpoints;

    // to be used to record the transfer amounts after _beforeTokenTransfer
    // these values are the base (unchanging) values the currency is stored in
    event BaseValueTransfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    /** Construct a new instance.
     *
     * Note that it is always necessary to call reAuthorize on the balance store
     * after it is first constructed to populate the authorized interface
     * contracts cache. These calls are separated to allow the authorized
     * contracts to be configured/deployed after the balance store contract.
     */
    constructor(
        Policy _policy,
        string memory _name,
        string memory _symbol,
        address _initialPauser
    )
        VoteCheckpoints(_name, _symbol, address(_policy), _initialPauser)
        PolicedUtils(_policy)
    {
        _writeCheckpoint(
            _linearInflationCheckpoints,
            _replace,
            INITIAL_INFLATION_MULTIPLIER
        );
    }

    function initialize(address _self)
        public
        virtual
        override
        onlyConstruction
    {
        super.initialize(_self);
        _writeCheckpoint(
            _linearInflationCheckpoints,
            _replace,
            INITIAL_INFLATION_MULTIPLIER
        );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override returns (uint256) {
        amount = super._beforeTokenTransfer(from, to, amount);
        uint256 gonsAmount = amount *
            _checkpointsLookup(_linearInflationCheckpoints, block.number);

        emit BaseValueTransfer(from, to, gonsAmount);

        return gonsAmount;
    }

    function getPastLinearInflation(uint256 blockNumber)
        public
        view
        returns (uint256)
    {
        require(
            blockNumber <= block.number,
            "InflationCheckpoints: cannot check future block"
        );
        return _checkpointsLookup(_linearInflationCheckpoints, blockNumber);
    }

    /** Access function to determine the token balance held by some address.
     */
    function balanceOf(address _owner) public view override returns (uint256) {
        uint256 _linearInflation = _checkpointsLookup(
            _linearInflationCheckpoints,
            block.number
        );
        return _balances[_owner] / _linearInflation;
    }

    /** Returns the total (inflation corrected) token supply
     */
    function totalSupply() public view override returns (uint256) {
        uint256 _linearInflation = _checkpointsLookup(
            _linearInflationCheckpoints,
            block.number
        );
        return _totalSupply / _linearInflation;
    }

    /** Returns the total (inflation corrected) token supply at a specified block number
     */
    function totalSupplyAt(uint256 _blockNumber)
        public
        view
        override
        returns (uint256)
    {
        uint256 _linearInflation = getPastLinearInflation(_blockNumber);

        return getPastTotalSupply(_blockNumber) / _linearInflation;
    }

    /** Return historical voting balance (includes delegation) at given block number.
     *
     * If the latest block number for the account is before the requested
     * block then the most recent known balance is returned. Otherwise the
     * exact block number requested is returned.
     *
     * @param _owner The account to check the balance of.
     * @param _blockNumber The block number to check the balance at the start
     *                        of. Must be less than or equal to the present
     *                        block number.
     */
    function getPastVotes(address _owner, uint256 _blockNumber)
        public
        view
        override
        returns (uint256)
    {
        uint256 _linearInflation = getPastLinearInflation(_blockNumber);

        return getPastVotingGons(_owner, _blockNumber) / _linearInflation;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./TrustedNodes.sol";
import "../../policy/Policy.sol";
import "../../policy/PolicedUtils.sol";
import "../../currency/IECO.sol";
import "./RandomInflation.sol";
import "../../utils/TimeUtils.sol";
import "../../VDF/VDFVerifier.sol";

/** @title Inflation/Deflation Process
 *
 * This contract oversees the voting on the currency inflation/deflation process.
 * Trusted nodes vote on a policy that is implemented the following generation
 * to manage the relative price of Eco tokens.
 */
contract CurrencyGovernance is PolicedUtils, TimeUtils, Pausable {
    enum Stage {
        Propose,
        Commit,
        Reveal,
        Compute,
        Finished
    }

    // tracks the progress of the contract
    Stage public currentStage;

    // data structure for monetary policy proposals
    struct GovernanceProposal {
        // random inflation recipients
        uint256 numberOfRecipients;
        // amount of weico recieved by each random inflation recipient
        uint256 randomInflationReward;
        // duration in seconds
        uint256 lockupDuration;
        // lockup interest as a 9 digit fixed point number
        uint256 lockupInterest;
        // multiplier for linear inflation as an 18 digit fixed point number
        uint256 inflationMultiplier;
        // to store a link to more information
        string description;
    }

    struct Vote {
        // the proposal being voted for
        address proposal;
        // the score of this proposal within the ballot, min recorded score is one
        // to get a score of zero, an item must be unscored
        uint256 score;
    }

    // timescales
    uint256 public constant PROPOSAL_TIME = 10 days;
    uint256 public constant VOTING_TIME = 3 days;
    uint256 public constant REVEAL_TIME = 1 days;

    // timestamps for the above periods
    uint256 public proposalEnds;
    uint256 public votingEnds;
    uint256 public revealEnds;

    uint256 public constant IDEMPOTENT_INFLATION_MULTIPLIER = 1e18;

    // max length of description field
    uint256 public constant MAX_DATA = 160;

    // mapping of proposing trustee addresses to their submitted proposals
    mapping(address => GovernanceProposal) public proposals;
    // mapping of trustee addresses to their hash commits for voting
    mapping(address => bytes32) public commitments;
    // mapping of proposals (indexed by the submitting trustee) to their voting score, accumulated during reveal
    mapping(address => uint256) public score;

    // used to track the leading proposal during the vote totalling
    address public leader;
    // used to denote the winning proposal when the vote is finalized
    address public winner;

    // address that can pause currency governance
    address public pauser;

    // emitted when a proposal is submitted to track the values
    event ProposalCreation(
        address indexed trusteeAddress,
        uint256 _numberOfRecipients,
        uint256 _randomInflationReward,
        uint256 _lockupDuration,
        uint256 _lockupInterest,
        uint256 _inflationMultiplier,
        string _description
    );

    // emitted when a trustee retracts their proposal
    event ProposalRetraction(address indexed trustee);

    /** Fired when the voting stage begins.
     * Triggered by updateStage().
     */
    event VoteStart();

    /** Fired when a trustee casts a vote.
     */
    event VoteCast(address indexed trustee);

    /** Fired when the reveal stage begins.
     * Triggered by updateStage().
     */
    event RevealStart();

    /** Fired when a vote is revealed, to create a voting history for all
     * participants. Records the voter, as well as all of the parameters of
     * the vote cast.
     */
    event VoteReveal(address indexed voter, Vote[] votes);

    /** Fired when vote results are computed, creating a permanent record of
     * vote outcomes.
     */
    event VoteResult(address indexed winner);

    /**
     * @notice event indicating the pauser was updated
     * @param pauser The new pauser
     */
    event PauserAssignment(address indexed pauser);

    modifier onlyPauser() {
        require(msg.sender == pauser, "CurrencyGovernance: not pauser");
        _;
    }

    modifier atStage(Stage _stage) {
        updateStage();
        require(
            currentStage == _stage,
            "This call is not allowed at this stage"
        );
        _;
    }

    function updateStage() public {
        uint256 time = getTime();
        if (currentStage == Stage.Propose && time >= proposalEnds) {
            currentStage = Stage.Commit;
            emit VoteStart();
        }
        if (currentStage == Stage.Commit && time >= votingEnds) {
            currentStage = Stage.Reveal;
            emit RevealStart();
        }
        if (currentStage == Stage.Reveal && time >= revealEnds) {
            currentStage = Stage.Compute;
        }
    }

    constructor(Policy _policy, address _initialPauser) PolicedUtils(_policy) {
        pauser = _initialPauser;
        emit PauserAssignment(_initialPauser);
    }

    /** Restrict access to trusted nodes only.
     */
    modifier onlyTrusted() {
        require(
            getTrustedNodes().isTrusted(msg.sender),
            "Only trusted nodes can call this method"
        );
        _;
    }

    function propose(
        uint256 _numberOfRecipients,
        uint256 _randomInflationReward,
        uint256 _lockupDuration,
        uint256 _lockupInterest,
        uint256 _inflationMultiplier,
        string calldata _description
    ) external onlyTrusted atStage(Stage.Propose) {
        require(
            _inflationMultiplier > 0,
            "Inflation multiplier cannot be zero"
        );
        require(
            // didn't choose this number for any particular reason
            uint256(bytes(_description).length) <= MAX_DATA,
            "Description is too long"
        );

        GovernanceProposal storage p = proposals[msg.sender];
        p.numberOfRecipients = _numberOfRecipients;
        p.randomInflationReward = _randomInflationReward;
        p.lockupDuration = _lockupDuration;
        p.lockupInterest = _lockupInterest;
        p.inflationMultiplier = _inflationMultiplier;
        p.description = _description;

        emit ProposalCreation(
            msg.sender,
            _numberOfRecipients,
            _randomInflationReward,
            _lockupDuration,
            _lockupInterest,
            _inflationMultiplier,
            _description
        );
    }

    function unpropose() external atStage(Stage.Propose) {
        require(
            proposals[msg.sender].inflationMultiplier != 0,
            "You do not have a proposal to retract"
        );
        delete proposals[msg.sender];
        emit ProposalRetraction(msg.sender);
    }

    function commit(bytes32 _commitment)
        external
        onlyTrusted
        atStage(Stage.Commit)
    {
        commitments[msg.sender] = _commitment;
        emit VoteCast(msg.sender);
    }

    function reveal(bytes32 _seed, Vote[] calldata _votes)
        external
        atStage(Stage.Reveal)
    {
        uint256 numVotes = _votes.length;
        require(numVotes > 0, "Invalid vote, cannot vote empty");
        require(
            commitments[msg.sender] != bytes32(0),
            "Invalid vote, no unrevealed commitment exists"
        );
        require(
            keccak256(abi.encode(_seed, msg.sender, _votes)) ==
                commitments[msg.sender],
            "Invalid vote, commitment mismatch"
        );

        delete commitments[msg.sender];

        // remove the trustee's default vote
        score[address(0)] -= 1;

        // use memory vars to store and track the changes of the leader
        address priorLeader = leader;
        address leaderTracker = priorLeader;
        uint256 leaderRankTracker = 0;

        /**
         * by setting this to 1, the code can skip checking _score != 0
         */
        uint256 scoreDuplicateCheck = 1;

        for (uint256 i = 0; i < numVotes; ++i) {
            Vote memory v = _votes[i];
            address _proposal = v.proposal;
            uint256 _score = v.score;

            require(
                proposals[_proposal].inflationMultiplier > 0,
                "Invalid vote, missing proposal"
            );
            require(
                i == 0 || _votes[i - 1].proposal < _proposal,
                "Invalid vote, proposals not in increasing order"
            );
            require(
                _score <= numVotes,
                "Invalid vote, proposal score out of bounds"
            );
            require(
                scoreDuplicateCheck & (1 << _score) == 0,
                "Invalid vote, duplicate score"
            );

            scoreDuplicateCheck += 1 << _score;

            score[_proposal] += _score;
            if (score[_proposal] > score[leaderTracker]) {
                leaderTracker = _proposal;
                leaderRankTracker = _score;
            } else if (score[_proposal] == score[leaderTracker]) {
                if (_score > leaderRankTracker) {
                    leaderTracker = _proposal;
                    leaderRankTracker = _score;
                }
            }
        }

        // only changes the leader if the new leader is of greater score
        if (
            leaderTracker != priorLeader &&
            score[leaderTracker] > score[priorLeader]
        ) {
            leader = leaderTracker;
        }

        // record the trustee's vote for compensation purposes
        getTrustedNodes().recordVote(msg.sender);

        emit VoteReveal(msg.sender, _votes);
    }

    function compute() external atStage(Stage.Compute) {
        // if paused then the default policy automatically wins
        if (!paused()) {
            winner = leader;
        }

        currentStage = Stage.Finished;

        emit VoteResult(winner);
    }

    /** Initialize the storage context using parameters copied from the
     * original contract (provided as _self).
     *
     * Can only be called once, during proxy initialization.
     *
     * @param _self The original contract address.
     */
    function initialize(address _self) public override onlyConstruction {
        super.initialize(_self);
        proposalEnds = getTime() + PROPOSAL_TIME;
        votingEnds = proposalEnds + VOTING_TIME;
        revealEnds = votingEnds + REVEAL_TIME;

        // should not emit an event
        pauser = CurrencyGovernance(_self).pauser();

        GovernanceProposal storage p = proposals[address(0)];
        p.inflationMultiplier = IDEMPOTENT_INFLATION_MULTIPLIER;

        // sets the default votes for the default proposal
        score[address(0)] = getTrustedNodes().numTrustees();
    }

    function getTrustedNodes() private view returns (TrustedNodes) {
        return TrustedNodes(policyFor(ID_TRUSTED_NODES));
    }

    /**
     * @notice set the given address as the pauser
     * @param _pauser The address that can pause this token
     * @dev only the roleAdmin can call this function
     */
    function setPauser(address _pauser) public onlyPolicy {
        pauser = _pauser;
        emit PauserAssignment(_pauser);
    }

    /**
     * @notice pauses transfers of this token
     * @dev only callable by the pauser
     */
    function pause() external onlyPauser {
        _pause();
    }

    /**
     * @notice unpauses transfers of this token
     * @dev only callable by the pauser
     */
    function unpause() external onlyPauser {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Pausable.sol";
import "./DelegatePermit.sol";

/**
 * @dev Extension of ERC20 to support Compound-like voting and delegation. This version is more generic than Compound's,
 * and supports token supply up to 2^224^ - 1, while COMP is limited to 2^96^ - 1.
 *
 * This extension keeps a history (checkpoints) of each account's vote power. Vote power can be delegated either
 * by calling the {delegate} function directly, or by providing a signature to be used with {delegateBySig}. Voting
 * power can be queried through the public accessors {getVotingGons} and {getPastVotingGons}.
 *
 * By default, token balance does not account for voting power. This makes transfers cheaper. The downside is that it
 * requires users to delegate to themselves in order to activate checkpoints and have their voting power tracked.
 * Enabling self-delegation can easily be done by overriding the {delegates} function. Keep in mind however that this
 * will significantly increase the base gas cost of transfers.
 *
 * _Available since v4.2._
 */
abstract contract VoteCheckpoints is ERC20Pausable, DelegatePermit {
    // structure for saving past voting balances, accounting for delegation
    struct Checkpoint {
        uint32 fromBlock;
        uint224 value;
    }

    // the mapping from an address to each address that it delegates to, then mapped to the amount delegated
    mapping(address => mapping(address => uint256)) internal _delegates;

    // a mapping that aggregates the total delegated amounts in the mapping above
    mapping(address => uint256) internal _delegatedTotals;

    /** a mapping that tracks the primaryDelegates of each user
     *
     * Primary delegates can only be chosen using delegate() which sends the full balance
     * The exist to maintain the functionality that recieving tokens gives those votes to the delegate
     */
    mapping(address => address) internal _primaryDelegates;

    // mapping that tracks if an address is willing to be delegated to
    mapping(address => bool) public delegationToAddressEnabled;

    // mapping that tracks if an address is unable to delegate
    mapping(address => bool) public delegationFromAddressDisabled;

    // mapping to the ordered arrays of voting checkpoints for each address
    mapping(address => Checkpoint[]) public checkpoints;

    // the checkpoints to track the token total supply
    Checkpoint[] private _totalSupplyCheckpoints;

    /**
     * @dev Emitted when a delegatee is delegated new votes.
     */
    event DelegatedVotes(
        address indexed delegator,
        address indexed delegatee,
        uint256 amount
    );

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to an account's voting power.
     */
    event UpdatedVotes(address indexed voter, uint256 newVotes);

    /**
     * @dev Emitted when an account denotes a primary delegate.
     */
    event NewPrimaryDelegate(
        address indexed delegator,
        address indexed primaryDelegate
    );

    constructor(
        string memory _name,
        string memory _symbol,
        address admin,
        address _initialPauser
    ) ERC20Pausable(_name, _symbol, admin, _initialPauser) {
        // call to super constructor
    }

    /** Returns the total (inflation corrected) token supply at a specified block number
     */
    function totalSupplyAt(uint256 _blockNumber)
        public
        view
        virtual
        returns (uint256)
    {
        return getPastTotalSupply(_blockNumber);
    }

    /** Return historical voting balance (includes delegation) at given block number.
     *
     * If the latest block number for the account is before the requested
     * block then the most recent known balance is returned. Otherwise the
     * exact block number requested is returned.
     *
     * @param _owner The account to check the balance of.
     * @param _blockNumber The block number to check the balance at the start
     *                        of. Must be less than or equal to the present
     *                        block number.
     */
    function getPastVotes(address _owner, uint256 _blockNumber)
        public
        view
        virtual
        returns (uint256)
    {
        return getPastVotingGons(_owner, _blockNumber);
    }

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account)
        public
        view
        virtual
        returns (uint32)
    {
        uint256 _numCheckpoints = checkpoints[account].length;
        require(
            _numCheckpoints <= type(uint32).max,
            "number of checkpoints cannot be casted safely"
        );
        return uint32(_numCheckpoints);
    }

    /**
     * @dev Set yourself as willing to recieve delegates.
     */
    function enableDelegationTo() public {
        require(
            isOwnDelegate(msg.sender),
            "Cannot enable delegation if you have outstanding delegation"
        );

        delegationToAddressEnabled[msg.sender] = true;
        delegationFromAddressDisabled[msg.sender] = true;
    }

    /**
     * @dev Set yourself as no longer recieving delegates.
     */
    function disableDelegationTo() public {
        delegationToAddressEnabled[msg.sender] = false;
    }

    /**
     * @dev Set yourself as being able to delegate again.
     * also disables delegating to you
     * NOTE: the condition for this is not easy and cannot be unilaterally achieved
     */
    function reenableDelegating() public {
        delegationToAddressEnabled[msg.sender] = false;

        require(
            _balances[msg.sender] == getVotingGons(msg.sender) &&
                isOwnDelegate(msg.sender),
            "Cannot re-enable delegating if you have outstanding delegations to you"
        );

        delegationFromAddressDisabled[msg.sender] = false;
    }

    /**
     * @dev Returns true if the user has no amount of their balance delegated, otherwise false.
     */
    function isOwnDelegate(address account) public view returns (bool) {
        return _delegatedTotals[account] == 0;
    }

    /**
     * @dev Get the primary address `account` is currently delegating to. Defaults to the account address itself if none specified.
     * The primary delegate is the one that is delegated any new funds the address recieves.
     */
    function getPrimaryDelegate(address account)
        public
        view
        virtual
        returns (address)
    {
        address _voter = _primaryDelegates[account];
        return _voter == address(0) ? account : _voter;
    }

    /**
     * sets the primaryDelegate and emits an event to track it
     */
    function _setPrimaryDelegate(address delegator, address delegatee)
        internal
    {
        _primaryDelegates[delegator] = delegatee;

        emit NewPrimaryDelegate(
            delegator,
            delegatee == address(0) ? delegator : delegatee
        );
    }

    /**
     * @dev Gets the current votes balance in gons for `account`
     */
    function getVotingGons(address account) public view returns (uint256) {
        Checkpoint[] memory accountCheckpoints = checkpoints[account];
        uint256 pos = accountCheckpoints.length;
        return pos == 0 ? 0 : accountCheckpoints[pos - 1].value;
    }

    /**
     * @dev Retrieve the number of votes in gons for `account` at the end of `blockNumber`.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotingGons(address account, uint256 blockNumber)
        public
        view
        returns (uint256)
    {
        require(
            blockNumber < block.number,
            "VoteCheckpoints: block not yet mined"
        );
        return _checkpointsLookup(checkpoints[account], blockNumber);
    }

    /**
     * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances.
     * It is NOT the sum of all the delegated votes!
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber)
        public
        view
        returns (uint256)
    {
        require(
            blockNumber < block.number,
            "VoteCheckpoints: block not yet mined"
        );
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber)
        internal
        view
        returns (uint256)
    {
        // This function runs a binary search to look for the last checkpoint taken before `blockNumber`.
        //
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, the next iteration looks in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, the next iteration looks in [mid+1, high)
        // Once it reaches a single value (when low == high), it has found the right checkpoint at the index high-1, if not
        // out of bounds (in which case it's looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, it will end up with an index that is
        // past the end of the array, so this technically doesn't find a checkpoint after `blockNumber`, but the result is
        // the same.

        uint256 ckptsLength = ckpts.length;
        if (ckptsLength == 0) return 0;
        Checkpoint memory lastCkpt = ckpts[ckptsLength - 1];
        if (blockNumber >= lastCkpt.fromBlock) return lastCkpt.value;

        uint256 high = ckptsLength;
        uint256 low = 0;

        while (low < high) {
            uint256 mid = low + ((high - low) >> 1);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].value;
    }

    /**
     * @dev Delegate all votes from the sender to `delegatee`.
     * NOTE: This function assumes that you do not have partial delegations
     * It will revert with "Must have an undelegated amount available to cover delegation" if you do
     */
    function delegate(address delegatee) public {
        require(
            delegatee != msg.sender,
            "Use undelegate instead of delegating to yourself"
        );

        require(
            delegationToAddressEnabled[delegatee],
            "Primary delegates must enable delegation"
        );

        if (!isOwnDelegate(msg.sender)) {
            undelegateFromAddress(getPrimaryDelegate(msg.sender));
        }

        uint256 _amount = _balances[msg.sender];
        _delegate(msg.sender, delegatee, _amount);
        _setPrimaryDelegate(msg.sender, delegatee);
    }

    /**
     * @dev Delegate all votes from the sender to `delegatee`.
     * NOTE: This function assumes that you do not have partial delegations
     * It will revert with "Must have an undelegated amount available to cover delegation" if you do
     */
    function delegateBySig(
        address delegator,
        address delegatee,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(delegator != delegatee, "Do not delegate to yourself");
        require(
            delegationToAddressEnabled[delegatee],
            "Primary delegates must enable delegation"
        );

        if (!isOwnDelegate(delegator)) {
            _undelegateFromAddress(delegator, getPrimaryDelegate(delegator));
        }

        _verifyDelegatePermit(delegator, delegatee, deadline, v, r, s);

        uint256 _amount = _balances[delegator];
        _delegate(delegator, delegatee, _amount);
        _setPrimaryDelegate(delegator, delegatee);
    }

    /**
     * @dev Delegate an `amount` of votes from the sender to `delegatee`.
     */
    function delegateAmount(address delegatee, uint256 amount) public {
        require(delegatee != msg.sender, "Do not delegate to yourself");

        _delegate(msg.sender, delegatee, amount);
    }

    /**
     * @dev Change delegation for `delegator` to `delegatee`.
     *
     * Emits events {NewDelegatedAmount} and {UpdatedVotes}.
     */
    function _delegate(
        address delegator,
        address delegatee,
        uint256 amount
    ) internal virtual {
        require(
            amount <= _balances[delegator] - _delegatedTotals[delegator],
            "Must have an undelegated amount available to cover delegation"
        );

        require(
            !delegationFromAddressDisabled[delegator],
            "Cannot delegate if you have enabled primary delegation to yourself and/or have outstanding delegates"
        );

        emit DelegatedVotes(delegator, delegatee, amount);

        _delegates[delegator][delegatee] += amount;
        _delegatedTotals[delegator] += amount;

        _moveVotingPower(delegator, delegatee, amount);
    }

    /**
     * @dev Undelegate all votes from the sender's primary delegate.
     */
    function undelegate() public {
        address _primaryDelegate = getPrimaryDelegate(msg.sender);
        require(
            _primaryDelegate != msg.sender,
            "Must specifiy address without a Primary Delegate"
        );
        undelegateFromAddress(_primaryDelegate);
    }

    /**
     * @dev Undelegate votes from the `delegatee` back to the sender.
     */
    function undelegateFromAddress(address delegatee) public {
        _undelegateFromAddress(msg.sender, delegatee);
    }

    /**
     * @dev Undelegate votes from the `delegatee` back to the delegator.
     */
    function _undelegateFromAddress(address delegator, address delegatee)
        internal
    {
        uint256 _amount = _delegates[delegator][delegatee];
        _undelegate(delegator, delegatee, _amount);
        if (delegatee == getPrimaryDelegate(delegator)) {
            _setPrimaryDelegate(delegator, address(0));
        }
    }

    /**
     * @dev Undelegate a specific amount of votes from the `delegatee` back to the sender.
     */
    function undelegateAmountFromAddress(address delegatee, uint256 amount)
        public
    {
        require(
            _delegates[msg.sender][delegatee] >= amount,
            "amount not available to undelegate"
        );
        require(
            msg.sender == getPrimaryDelegate(msg.sender),
            "undelegating amounts is only available for partial delegators"
        );
        _undelegate(msg.sender, delegatee, amount);
    }

    function _undelegate(
        address delegator,
        address delegatee,
        uint256 amount
    ) internal virtual {
        _delegatedTotals[delegator] -= amount;
        _delegates[delegator][delegatee] -= amount;

        _moveVotingPower(delegatee, delegator, amount);
    }

    /**
     * @dev Maximum token supply. Defaults to `type(uint224).max` (2^224^ - 1).
     */
    function _maxSupply() internal view virtual returns (uint224) {
        return type(uint224).max;
    }

    /**
     * @dev Snapshots the totalSupply after it has been increased.
     */
    function _mint(address account, uint256 amount)
        internal
        virtual
        override
        returns (uint256)
    {
        amount = super._mint(account, amount);
        require(
            totalSupply() <= _maxSupply(),
            "VoteCheckpoints: total supply risks overflowing votes"
        );

        _writeCheckpoint(_totalSupplyCheckpoints, _add, amount);
        return amount;
    }

    /**
     * @dev Snapshots the totalSupply after it has been decreased.
     */
    function _burn(address account, uint256 amount)
        internal
        virtual
        override
        returns (uint256)
    {
        amount = super._burn(account, amount);

        _writeCheckpoint(_totalSupplyCheckpoints, _subtract, amount);
        return amount;
    }

    /**
     * @dev Move voting power when tokens are transferred.
     *
     * Emits a {UpdatedVotes} event.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (from == to) {
            // self transfers require no change in delegation and can be the source of exploits
            return;
        }

        // if the address has delegated, they might be transfering tokens allotted to someone else
        if (!isOwnDelegate(from)) {
            uint256 _undelegatedAmount = _balances[from] +
                amount -
                _delegatedTotals[from];

            // check to see if tokens must be undelegated to transefer
            if (_undelegatedAmount < amount) {
                address _sourcePrimaryDelegate = getPrimaryDelegate(from);
                uint256 _sourcePrimaryDelegatement = _delegates[from][
                    _sourcePrimaryDelegate
                ];

                require(
                    amount <= _undelegatedAmount + _sourcePrimaryDelegatement,
                    "Delegation too complicated to transfer. Undelegate and simplify before trying again"
                );

                _undelegate(
                    from,
                    _sourcePrimaryDelegate,
                    amount - _undelegatedAmount
                );
            }
        }

        address _destPrimaryDelegate = _primaryDelegates[to];
        // saving gas by manually doing isOwnDelegate since this function already needs to read the data for this conditional
        if (_destPrimaryDelegate != address(0)) {
            _delegates[to][_destPrimaryDelegate] += amount;
            _delegatedTotals[to] += amount;
            _moveVotingPower(from, _destPrimaryDelegate, amount);
        } else {
            _moveVotingPower(from, to, amount);
        }
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                uint256 newWeight = _writeCheckpoint(
                    checkpoints[src],
                    _subtract,
                    amount
                );
                emit UpdatedVotes(src, newWeight);
            }

            if (dst != address(0)) {
                uint256 newWeight = _writeCheckpoint(
                    checkpoints[dst],
                    _add,
                    amount
                );
                emit UpdatedVotes(dst, newWeight);
            }
        }
    }

    // returns the newly written value in the checkpoint
    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) internal returns (uint256) {
        require(
            delta <= type(uint224).max,
            "newWeight cannot be casted safely"
        );
        require(
            block.number <= type(uint32).max,
            "block number cannot be casted safely"
        );

        uint256 pos = ckpts.length;

        /* if there are no checkpoints, just write the value
         * This part assumes that an account would never exist with a balance but without checkpoints.
         * This function cannot be called directly, so there's no malicious way to exploit this. If this
         * is somehow called with op = _subtract, it will revert as that action is nonsensical.
         */
        if (pos == 0) {
            ckpts.push(
                Checkpoint({
                    fromBlock: uint32(block.number),
                    value: uint224(op(0, delta))
                })
            );
            return delta;
        }

        // else, iterate on the existing checkpoints as per usual
        Checkpoint storage newestCkpt = ckpts[pos - 1];

        uint256 oldWeight = newestCkpt.value;
        uint256 newWeight = op(oldWeight, delta);

        require(
            newWeight <= type(uint224).max,
            "newWeight cannot be casted safely"
        );

        if (newestCkpt.fromBlock == block.number) {
            newestCkpt.value = uint224(newWeight);
        } else {
            ckpts.push(
                Checkpoint({
                    fromBlock: uint32(block.number),
                    value: uint224(newWeight)
                })
            );
        }
        return newWeight;
    }

    function _add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function _replace(uint256, uint256 b) internal pure returns (uint256) {
        return b;
    }
}

// SPDX-License-Identifier: MIT
// Heavily inspired by:
// OpenZeppelin Contracts v4.4.1 (token/Delegate/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

/**
 * @dev Abstract contract including helper functions to allow delegation by signature using
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {_verifyDelegatePermit} internal method, verifies a signature specifying permission to receive delegation power
 *
 */
abstract contract DelegatePermit is EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _DELEGATE_TYPEHASH =
        keccak256(
            "Delegate(address delegator,address delegatee,uint256 nonce,uint256 deadline)"
        );

    /**
     * @notice Verify that the given delegate signature is valid, throws if not
     * @param delegator The address delegating
     * @param delegatee The address being delegated to
     * @param deadline The deadling of the delegation after which it will be invalid
     * @param v The v part of the signature
     * @param r The r part of the signature
     * @param s The s part of the signature
     */
    function _verifyDelegatePermit(
        address delegator,
        address delegatee,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        require(
            block.timestamp <= deadline,
            "DelegatePermit: expired deadline"
        );
        require(delegator != address(0), "invalid delegator");

        bytes32 structHash = keccak256(
            abi.encode(
                _DELEGATE_TYPEHASH,
                delegator,
                delegatee,
                _useDelegationNonce(delegator),
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == delegator, "DelegatePermit: invalid signature");
    }

    /**
     * @notice get the current nonce for the given address
     * @param owner The address to get nonce for
     * @return the current nonce of `owner`
     */
    function delegationNonce(address owner) public view returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useDelegationNonce(address owner)
        private
        returns (uint256 current)
    {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BigNumber.sol";
import "./IsPrime.sol";
import "../policy/PolicedUtils.sol";

/** @title On-the-chain verification for RSA 2K VDF
 */
contract VDFVerifier is PolicedUtils, IsPrime {
    using BigNumber for BigNumber.Instance;

    /* 2048-bit modulus from RSA-2048 challenge
     * https://en.wikipedia.org/wiki/RSA_Factoring_Challenge
     * The security assumptions rely on RSA challenge rules:
     * No attacker knows or can obtain the factorization
     * Factorization wasn't recorded on generation of the number.
     */

    bytes public constant N =
        hex"c7970ceedcc3b0754490201a7aa613cd73911081c790f5f1a8726f463550bb5b7ff0db8e1ea1189ec72f93d1650011bd721aeeacc2acde32a04107f0648c2813a31f5b0b7765ff8b44b4b6ffc93384b646eb09c7cf5e8592d40ea33c80039f35b4f14a04b51f7bfd781be4d1673164ba8eb991c2c4d730bbbe35f592bdef524af7e8daefd26c66fc02c479af89d64d373f442709439de66ceb955f3ea37d5159f6135809f85334b5cb1813addc80cd05609f10ac6a95ad65872c909525bdad32bc729592642920f24c61dc5b3c3b7923e56b16a4d9d373d8721f24a3fc0f1b3131f55615172866bccc30f95054c824e733a5eb6817f7bc16399d48c6361cc7e5";
    uint256 public constant MIN_BYTES = 64;

    /* The State is a data structure that tracks progress of a logical single verification session
     * from a single verifier. Once verification is complete,
     * state is removed, and (if succesfully verified) replaced by a entry
     * in verified
     */
    struct State {
        uint256 progress; // progress: 1 .. t-1
        uint256 t;
        uint256 x;
        bytes32 concatHash;
        BigNumber.Instance y;
        BigNumber.Instance xi;
        BigNumber.Instance yi;
    }

    // Mapping from verifier to state
    mapping(address => State) private state;

    /** @notice Mapping from keccak256(t, x) to keccak256(y)
     */
    mapping(bytes32 => bytes32) public verified;

    /* Event to be emitted when verification is complete.
     */
    event SuccessfulVerification(uint256 x, uint256 t, bytes y);

    /**
     * @notice Construct the contract with global parameters.
     */
    // solhint-disable-next-line no-empty-blocks
    constructor(Policy _policy) PolicedUtils(_policy) {
        // uses PolicedUtils constructor
    }

    /**
     * @notice Start the verification process
     * This starts the submission of a proof that (x^(2^(2^t+1)))==y
     * @notice The caller should have already set the prime number, _x, to use in the random inflation
     * contract.
     */
    function start(
        uint256 _x,
        uint256 _t,
        bytes calldata _ybytes
    ) external {
        require(
            verified[keccak256(abi.encode(_t, _x))] == bytes32(0),
            "this _x, _t combination has already been verified"
        );

        require(_t >= 2, "t must be at least 2");

        require(_x > 1, "The commitment (x) must be > 1");

        BigNumber.Instance memory n = BigNumber.from(N);
        BigNumber.Instance memory x = BigNumber.from(_x);
        BigNumber.Instance memory y = BigNumber.from(_ybytes);
        BigNumber.Instance memory x2 = BigNumber.multiply(x, x);

        require(
            y.minimalByteLength() >= MIN_BYTES,
            "The secret (y) must be at least 64 bytes long"
        );
        require(BigNumber.cmp(y, n) == -1, "y must be less than N");

        State storage currentState = state[msg.sender];

        currentState.progress = 1; // reset the contract
        currentState.t = _t;

        currentState.x = _x;
        currentState.y = y;

        currentState.xi = x2; // the time-lock-puzzle is for x2 = x^2; x2 is a QR mod n
        currentState.yi = y;
        currentState.concatHash = keccak256(
            abi.encodePacked(_x, y.asBytes(n.byteLength()))
        );
    }

    /**
     * @notice Submit next step of proof
     * To be continuously called with progress = 1 ... t-1 and corresponding u, inclusively.
     * progress input parameter indicates the expected value of progress after the successful processing of this step.
     *
     * So, it starts with s.progress == 0 and call with progress=1, ... t-1. Once you set s.progress = t-1, this has
     * completed the verification successfully.
     *
     * In other words, the input is effectively (i, U_sqrt[i]).
     */
    function update(bytes calldata _ubytes) external {
        State storage s = state[msg.sender]; // saves gas

        require(s.progress > 0, "process has not yet been started");

        BigNumber.Instance memory n = BigNumber.from(N); // save in memory
        BigNumber.Instance memory one = BigNumber.from(1);
        BigNumber.Instance memory two = BigNumber.from(2);

        BigNumber.Instance memory u = BigNumber.from(_ubytes);
        BigNumber.Instance memory u2 = BigNumber.modexp(u, two, n); // u2 = u^2 mod n

        require(BigNumber.cmp(u, one) == 1, "u must be greater than 1");
        require(BigNumber.cmp(u, n) == -1, "u must be less than N");
        require(BigNumber.cmp(u2, one) == 1, "u*u must be greater than 1");

        uint256 nlen = n.byteLength();

        uint256 nextProgress = s.progress;

        BigNumber.Instance memory r = BigNumber.from(
            uint256(
                keccak256(
                    abi.encodePacked(
                        s.concatHash,
                        u.asBytes(nlen),
                        nextProgress
                    )
                )
            )
        );

        nextProgress++;

        BigNumber.Instance memory xi = BigNumber.modmul(
            BigNumber.modexp(s.xi, r, n),
            u2,
            n
        ); // xi^r * u^2
        BigNumber.Instance memory yi = BigNumber.modmul(
            BigNumber.modexp(u2, r, n),
            s.yi,
            n
        ); // u^2*r * y

        if (nextProgress != s.t) {
            // Intermediate step
            s.xi = xi;
            s.yi = yi;

            s.progress = nextProgress; // this becomes t-1 for the last step
        } else {
            // Final step. Finalize calculations.
            xi = xi.modexp(BigNumber.from(4), n); // xi^4. Must match yi

            require(
                BigNumber.cmp(xi, yi) == 0,
                "Verification failed in the last step"
            );

            // Success! Fall through

            verified[keccak256(abi.encode(s.t, s.x))] = keccak256(
                s.y.asBytes(nlen)
            );

            emit SuccessfulVerification(s.x, s.t, s.y.asBytes());
            delete (state[msg.sender]);
        }
    }

    /**
     * @notice Return verified state
     * @return true iff (x^(2^(2^t+1)))==y has been proven
     */
    function isVerified(
        uint256 _x,
        uint256 _t,
        bytes calldata _ybytes
    ) external view returns (bool) {
        BigNumber.Instance memory y = BigNumber.from(_ybytes);
        uint256 nlen = N.length;
        return
            verified[keccak256(abi.encode(_t, _x))] ==
            keccak256(y.asBytes(nlen));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../policy/PolicedUtils.sol";
import "../../currency/ECOx.sol";
import "../TimedPolicies.sol";
import "../IGeneration.sol";
import "../../utils/TimeUtils.sol";

/** @title TrustedNodes
 *
 * A registry of trusted nodes. Trusted nodes are able to vote during
 * inflation/deflation votes, and can only be added or removed using policy
 * proposals.
 *
 */
contract TrustedNodes is PolicedUtils, TimeUtils {
    uint256 public constant GENERATIONS_PER_YEAR = 26;

    uint256 public yearEnd;

    uint256 public yearStartGen;

    address public hoard;

    /** Tracks the current trustee cohort
     * each trustee election cycle corresponds to a new trustee cohort.
     */

    struct Cohort {
        /** The list of trusted nodes in the cohort*/
        address[] trustedNodes;
        /** @dev address of trusted node to index in trustedNodes */
        mapping(address => uint256) trusteeNumbers;
    }

    /** cohort number */
    uint256 public cohort;

    /** cohort number to cohort */
    mapping(uint256 => Cohort) internal cohorts;

    /** Represents the number of votes for which the trustee can claim rewards.
    Increments each time the trustee votes, set to zero upon redemption */
    mapping(address => uint256) public votingRecord;

    // last year's voting record
    mapping(address => uint256) public lastYearVotingRecord;

    // completely vested
    mapping(address => uint256) public fullyVestedRewards;

    /** reward earned per completed and revealed vote */
    uint256 public voteReward;

    // unallocated rewards to be sent to hoard upon the end of the year term
    uint256 public unallocatedRewardsCount;

    /** Event emitted when a node added to a list of trusted nodes.
     */
    event TrustedNodeAddition(address indexed node, uint256 cohort);

    /** Event emitted when a node removed from a list of trusted nodes
     */
    event TrustedNodeRemoval(address indexed node, uint256 cohort);

    /** Event emitted when voting rewards are redeemed */
    event VotingRewardRedemption(address indexed recipient, uint256 amount);

    // Event emitted on annualUpdate and newCohort to request funding to the contract
    event FundingRequest(uint256 amount);

    // information for the new trustee rewards term
    event RewardsTrackingUpdate(
        uint256 nextUpdateTimestamp,
        uint256 newRewardsCount
    );

    /** Creates a new trusted node registry, populated with some initial nodes.
     */
    constructor(
        Policy _policy,
        address[] memory _initialTrustedNodes,
        uint256 _voteReward
    ) PolicedUtils(_policy) {
        voteReward = _voteReward;
        uint256 trusteeCount = _initialTrustedNodes.length;
        hoard = address(_policy);

        for (uint256 i = 0; i < trusteeCount; ++i) {
            address node = _initialTrustedNodes[i];
            _trust(node);
        }
    }

    /** Initialize the storage context using parameters copied from the
     * original contract (provided as _self).
     *
     * Can only be called once, during proxy initialization.
     *
     * @param _self The original contract address.
     */
    function initialize(address _self) public override onlyConstruction {
        super.initialize(_self);
        // vote reward is left as mutable for easier governance
        voteReward = TrustedNodes(_self).voteReward();
        hoard = TrustedNodes(_self).hoard();
        yearStartGen = GENERATION_START + 1;
        yearEnd = getTime() + GENERATIONS_PER_YEAR * MIN_GENERATION_DURATION;

        uint256 _numTrustees = TrustedNodes(_self).numTrustees();

        unallocatedRewardsCount = _numTrustees * GENERATIONS_PER_YEAR;
        uint256 _cohort = TrustedNodes(_self).cohort();
        address[] memory trustees = TrustedNodes(_self)
            .getTrustedNodesFromCohort(_cohort);

        for (uint256 i = 0; i < _numTrustees; ++i) {
            _trust(trustees[i]);
        }
    }

    function getTrustedNodesFromCohort(uint256 _cohort)
        public
        view
        returns (address[] memory)
    {
        return cohorts[_cohort].trustedNodes;
    }

    /** Grant trust to a node.
     *
     * The node is pushed to trustedNodes array.
     *
     * @param _node The node to start trusting.
     */
    function trust(address _node) external onlyPolicy {
        _trust(_node);
    }

    /** Stop trusting a node.
     *
     * Node to distrust swaped to be a last element in the trustedNodes, then deleted
     *
     * @param _node The node to stop trusting.
     */
    function distrust(address _node) external onlyPolicy {
        Cohort storage currentCohort = cohorts[cohort];
        uint256 trusteeNumber = currentCohort.trusteeNumbers[_node];
        require(trusteeNumber > 0, "Node already not trusted");

        uint256 lastIndex = currentCohort.trustedNodes.length - 1;

        delete currentCohort.trusteeNumbers[_node];

        uint256 trusteeIndex = trusteeNumber - 1;
        if (trusteeIndex != lastIndex) {
            address lastNode = currentCohort.trustedNodes[lastIndex];

            currentCohort.trustedNodes[trusteeIndex] = lastNode;
            currentCohort.trusteeNumbers[lastNode] = trusteeNumber;
        }

        currentCohort.trustedNodes.pop();
        emit TrustedNodeRemoval(_node, cohort);
    }

    /** Incements the counter when the trustee reveals their vote
     * only callable by the CurrencyGovernance contract
     */
    function recordVote(address _who) external {
        require(
            msg.sender == policyFor(ID_CURRENCY_GOVERNANCE),
            "Must be the monetary policy contract to call"
        );

        votingRecord[_who]++;

        if (unallocatedRewardsCount > 0) {
            unallocatedRewardsCount--;
        }
    }

    /** The calling trustee can redeem any rewards from the previous generation
     *  that they have earned for participating in that generation's voting.
     */
    function redeemVoteRewards() external {
        // rewards from last year
        uint256 yearGenerationCount = IGeneration(policyFor(ID_TIMED_POLICIES))
            .generation() - yearStartGen;

        uint256 record = lastYearVotingRecord[msg.sender];
        uint256 vested = fullyVestedRewards[msg.sender];
        require(record + vested > 0, "No vested rewards to redeem");
        uint256 rewardsToRedeem = (
            record > yearGenerationCount ? yearGenerationCount : record
        );
        lastYearVotingRecord[msg.sender] = record - rewardsToRedeem;

        // fully vested rewards if they exist
        if (vested > 0) {
            rewardsToRedeem += vested;
            fullyVestedRewards[msg.sender] = 0;
        }

        uint256 reward = rewardsToRedeem * voteReward;

        require(
            ECOx(policyFor(ID_ECOX)).transfer(msg.sender, reward),
            "Transfer Failed"
        );

        emit VotingRewardRedemption(msg.sender, reward);
    }

    /** Return the number of entries in trustedNodes array.
     */
    function numTrustees() external view returns (uint256) {
        return cohorts[cohort].trustedNodes.length;
    }

    /** Helper function for adding a node to the trusted set.
     *
     * @param _node The node to add to the trusted set.
     */
    function _trust(address _node) private {
        uint256 _cohort = cohort;
        Cohort storage currentCohort = cohorts[_cohort];
        require(
            currentCohort.trusteeNumbers[_node] == 0,
            "Node is already trusted"
        );
        // trustee number of new node is len(trustedNodes) + 1, since there can't be a trustee with trusteeNumber = 0
        currentCohort.trusteeNumbers[_node] =
            currentCohort.trustedNodes.length +
            1;
        currentCohort.trustedNodes.push(_node);
        emit TrustedNodeAddition(_node, _cohort);
    }

    /** Checks if a node address is trusted in the current cohort
     */
    function isTrusted(address _node) public view returns (bool) {
        return cohorts[cohort].trusteeNumbers[_node] > 0;
    }

    /** Function for adding a new cohort of trustees
     * used for implementing the results of a trustee election
     */
    function newCohort(address[] memory _newCohort) external onlyPolicy {
        uint256 trustees = cohorts[cohort].trustedNodes.length;
        if (_newCohort.length > trustees) {
            emit FundingRequest(
                voteReward *
                    GENERATIONS_PER_YEAR *
                    (_newCohort.length - trustees)
            );
        }

        cohort++;

        for (uint256 i = 0; i < _newCohort.length; ++i) {
            _trust(_newCohort[i]);
        }
    }

    /** Updates the trustee rewards that they have earned for the year
     * and then sends the unallocated reward to the hoard.
     */
    function annualUpdate() external {
        require(
            getTime() > yearEnd,
            "cannot call this until the current year term has ended"
        );
        address[] memory trustees = cohorts[cohort].trustedNodes;
        for (uint256 i = 0; i < trustees.length; ++i) {
            address trustee = trustees[i];
            fullyVestedRewards[trustee] += lastYearVotingRecord[trustee];
            lastYearVotingRecord[trustee] = votingRecord[trustee];
            votingRecord[trustee] = 0;
        }

        uint256 reward = unallocatedRewardsCount * voteReward;
        unallocatedRewardsCount =
            cohorts[cohort].trustedNodes.length *
            GENERATIONS_PER_YEAR;
        yearEnd = getTime() + GENERATIONS_PER_YEAR * MIN_GENERATION_DURATION;
        yearStartGen = IGeneration(policyFor(ID_TIMED_POLICIES)).generation();

        ECOx ecoX = ECOx(policyFor(ID_ECOX));

        require(ecoX.transfer(hoard, reward), "Transfer Failed");

        emit FundingRequest(unallocatedRewardsCount * voteReward);
        emit VotingRewardRedemption(hoard, reward);
        emit RewardsTrackingUpdate(yearEnd, unallocatedRewardsCount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../policy/Policy.sol";
import "../../policy/PolicedUtils.sol";
import "../../currency/ECO.sol";
import "../../utils/TimeUtils.sol";
import "../../VDF/VDFVerifier.sol";
import "./InflationRootHashProposal.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/** @title RandomInflation
 *
 * This contract oversees the currency random inflation process and is spawned
 * on demand by the CurrencyTimer.
 */
contract RandomInflation is PolicedUtils, TimeUtils {
    /** The time period over which inflation reward is spread to prevent
     *  flooding by spreading out the new tokens.
     */
    uint256 public constant CLAIM_PERIOD = 28 days;

    /** The bound on how much more than the uint256 previous blockhash can a submitted prime be
     */
    uint256 public constant PRIME_BOUND = 1000;

    /** The number of checks to determine the prime seed to start the VDF
     */
    uint256 public constant MILLER_RABIN_ROUNDS = 25;

    /** The per-participant reward amount in basic unit of 10^{-18} ECO (weico) selected by the voting process.
     */
    uint256 public reward;

    /** The computed number of reward recipients (inflation/reward) in basic unit of 10^{-18} ECO (weico).
     */
    uint256 public numRecipients;

    /** The block number to use as the reference point when checking if an account holds currency.
     */
    uint256 public blockNumber;

    /** The initial value used for VDF to compute random seed. This is set by a
     * call to `commitEntropyVDFSeed()` after the vote results are computed.
     */
    uint256 public entropyVDFSeed;

    /** The random seed used to determine the inflation reward recipients.
     */
    bytes32 public seed;

    /** Difficulty of VDF for random process. This is left mutable for easier governance */
    uint256 public randomVDFDifficulty;

    /** Timestamp to start claim period from */
    uint256 public claimPeriodStarts;

    /** A mapping recording which claim numbers have been claimed.
     */
    mapping(uint256 => uint256) public claimed;

    // the max bits that can be stored in a uint256 number
    uint256 public constant BITMAP_MAXIMUM = 256;

    // A counter of outstanding unclaimed rewards
    uint256 public unclaimedRewards;

    /** The base VDFVerifier implementation */
    /** The VDF is used to set the random seed for inflation */
    VDFVerifier public vdfVerifier;

    /** The base InflationRootHashProposal implementation */
    /** The inflation root hash proposal that's used to verify inflation claims */
    InflationRootHashProposal public inflationRootHashProposal;

    // the ECO token address
    ECO public immutable ecoToken;

    /** A mapping of primals asssociated to the block they were commited in
     */
    mapping(uint256 => uint256) public primals;

    /** Emitted when inflation starts.
     */
    event InflationStart(
        VDFVerifier indexed vdfVerifier,
        InflationRootHashProposal indexed inflationRootHashProposal,
        uint256 claimPeriodStarts
    );

    /** Fired when a user claims their reward */
    event Claim(address indexed who, uint256 sequence);

    /** Emitted when the VDF seed used to provide entropy has been committed to the contract.
     */
    event EntropyVDFSeedCommit(uint256 seed);

    /** Emitted when the entropy seed is revealed by provable VDF computation.
     */
    event EntropySeedReveal(bytes32 seed);

    constructor(
        Policy _policy,
        VDFVerifier _vdfVerifierImpl,
        uint256 _randomDifficulty,
        InflationRootHashProposal _inflationRootHashProposalImpl,
        ECO _ecoAddr
    ) PolicedUtils(_policy) {
        require(
            address(_vdfVerifierImpl) != address(0),
            "do not set the _vdfVerifierImpl as the zero address"
        );
        require(
            _randomDifficulty > 0,
            "do not set the _randomDifficulty to zero"
        );
        require(
            address(_inflationRootHashProposalImpl) != address(0),
            "do not set the _inflationRootHashProposalImpl as the zero address"
        );
        require(
            address(_ecoAddr) != address(0),
            "do not set the _ecoAddr as the zero address"
        );
        vdfVerifier = _vdfVerifierImpl;
        randomVDFDifficulty = _randomDifficulty;
        inflationRootHashProposal = _inflationRootHashProposalImpl;
        ecoToken = _ecoAddr;
    }

    /** Clean up the inflation contract.
     *
     * Can only be called after all rewards
     * have been claimed.
     */
    function destruct() external {
        require(
            seed != 0 || getTime() > claimPeriodStarts + CLAIM_PERIOD,
            "Entropy not set, wait until end of full claim period to abort"
        );

        // consider putting a long scale timeout to allow for late stage aborts
        // unclaimedRewards is guaranteed to be set before the seed
        require(
            seed == 0 || unclaimedRewards == 0,
            "All rewards must be claimed prior to destruct"
        );

        require(
            ecoToken.transfer(
                address(policy),
                ecoToken.balanceOf(address(this))
            ),
            "Transfer Failed"
        );
    }

    /** Initialize the storage context using parameters copied from the
     * original contract (provided as _self).
     *
     * Can only be called once, during proxy initialization.
     *
     * @param _self The original contract address.
     */
    function initialize(address _self) public override onlyConstruction {
        super.initialize(_self);
        blockNumber = block.number - 1;

        vdfVerifier = VDFVerifier(RandomInflation(_self).vdfVerifier().clone());
        randomVDFDifficulty = RandomInflation(_self).randomVDFDifficulty();

        inflationRootHashProposal = InflationRootHashProposal(
            RandomInflation(_self).inflationRootHashProposal().clone()
        );
        inflationRootHashProposal.configure(blockNumber);
    }

    /** Commit to a VDF seed for inflation distribution entropy.
     *
     * Can only be called after results are computed and the registration
     * period has ended. The VDF seed can only be set once, and must be computed and
     * set in the previous block.
     *
     * @param _primal the primal to use, must have been committed to in a previous block
     */
    function commitEntropyVDFSeed(uint256 _primal) external {
        require(entropyVDFSeed == 0, "The VDF seed has already been set");
        uint256 _primalCommitBlock = primals[_primal];
        require(
            _primalCommitBlock > 0 && _primalCommitBlock < block.number,
            "primal block invalid"
        );
        require(
            vdfVerifier.isProbablePrime(_primal, MILLER_RABIN_ROUNDS),
            "input failed primality test"
        );

        entropyVDFSeed = _primal;

        emit EntropyVDFSeedCommit(entropyVDFSeed);
    }

    /** Sets a primal in storage associated to the commiting block
     * A user first adds a primal to the contract, then they can test
     * its primality in a subsequent block
     *
     * @param _primal uint256 the prime number to commit for the block
     */
    function setPrimal(uint256 _primal) external {
        uint256 _bhash = uint256(blockhash(block.number - 1));
        require(
            _primal > _bhash && _primal - _bhash < PRIME_BOUND,
            "suggested prime is out of bounds"
        );

        primals[_primal] = block.number;
    }

    /** Starts the inflation payout period. Validates that the contract is sufficiently
     * capitalized with Eco to meet the inflation demand. Can only be called once, ie by CurrencyTimer
     *
     * @param _numRecipients the number of recipients that will get rewards
     * @param _reward the amount of ECO to be given as reward to each recipient
     */
    function startInflation(uint256 _numRecipients, uint256 _reward) external {
        require(
            _numRecipients > 0 && _reward > 0,
            "Contract must have rewards"
        );
        require(
            ecoToken.balanceOf(address(this)) >= _numRecipients * _reward,
            "The contract must have a token balance at least the total rewards"
        );
        require(numRecipients == 0, "The sale can only be started once");

        /* This sets the amount of recipients to be iterated through later, it is important
        this number stay reasonable from gas consumption standpoint */
        numRecipients = _numRecipients;
        unclaimedRewards = _numRecipients;
        reward = _reward;
        claimPeriodStarts = getTime();
        emit InflationStart(
            vdfVerifier,
            inflationRootHashProposal,
            claimPeriodStarts
        );
    }

    /** Submit a solution for VDF for randomness.
     *
     * @param _y The computed VDF output. Must be proven with the VDF
     *           verification contract.
     */
    function submitEntropyVDF(bytes calldata _y) external {
        require(entropyVDFSeed != 0, "Initial seed must be set");
        require(seed == bytes32(0), "Can only submit once");

        require(
            vdfVerifier.isVerified(entropyVDFSeed, randomVDFDifficulty, _y),
            "The VDF output value must be verified by the VDF verification contract"
        );

        seed = keccak256(_y);

        emit EntropySeedReveal(seed);
    }

    /** Claim an inflation reward on behalf of some address.
     *
     * The reward is sent directly to the address that has claim to the reward, but the
     * gas cost is paid by the caller.
     *
     * For example, an exchange might stake using funds deposited into its
     * contract.
     *
     * @param _who The address to claim a reward on behalf of.
     * @param _sequence The reward sequence number to determine if the address
     *                  gets paid.
     * @param _proof the “other nodes” in the Merkle tree
     * @param _sum cumulative sum of all account ECO votes before this node
     * @param _index the index of the `who` address in the Merkle tree
     */
    function claimFor(
        address _who,
        uint256 _sequence,
        bytes32[] memory _proof,
        uint256 _sum,
        uint256 _index
    ) public {
        require(seed != bytes32(0), "Must prove VDF before claims can be paid");
        require(
            _sequence < numRecipients,
            "The provided sequence number must be within the set of recipients"
        );
        require(
            getTime() >
                claimPeriodStarts + (_sequence * CLAIM_PERIOD) / numRecipients,
            "A claim can only be made after enough time has passed"
        );
        require(
            claimed[_sequence / BITMAP_MAXIMUM] &
                (1 << (_sequence % BITMAP_MAXIMUM)) ==
                0,
            "A claim can only be made if it has not already been made"
        );

        require(
            inflationRootHashProposal.acceptedRootHash() != 0,
            "A claim can only be made after root hash for this generation was accepted"
        );

        require(
            inflationRootHashProposal.verifyClaimSubmission(
                _who,
                _proof,
                _sum,
                _index
            ),
            "A claim submission failed root hash verification"
        );

        claimed[_sequence / BITMAP_MAXIMUM] +=
            1 <<
            (_sequence % BITMAP_MAXIMUM);
        unclaimedRewards--;

        uint256 claimable = uint256(
            keccak256(abi.encodePacked(seed, _sequence))
        ) % inflationRootHashProposal.acceptedTotalSum();

        require(
            claimable < ecoToken.getPastVotes(_who, blockNumber) + _sum,
            "The provided address cannot claim this reward"
        );
        require(
            claimable >= _sum,
            "The provided address cannot claim this reward"
        );

        require(ecoToken.transfer(_who, reward), "Transfer Failed");

        emit Claim(_who, _sequence);
    }

    /** Claim an inflation reward for yourself.
     *
     * You need to know your claim number's place in the order.
     *
     * @param _sequence Your claim number's place in the order.
     */
    function claim(
        uint256 _sequence,
        bytes32[] calldata _proof,
        uint256 _sum,
        uint256 _index
    ) external {
        claimFor(msg.sender, _sequence, _proof, _sum, _index);
    }
}

pragma solidity ^0.8.0;

/*
MIT License

Copyright (c) 2017 zcoinofficial

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

// Originated from https://github.com/zcoinofficial/solidity-BigNumber

// SPDX-License-Identifier: MIT

// solhint-disable no-inline-assembly, no-empty-blocks, function-max-lines

/**
 * @title Big integer math library
 */
library BigNumber {
    /*
     * BigNumber is defined as a struct named 'Instance' to avoid naming conflicts.
     * DO NOT ALLOW INSTANTIATING THIS DIRECTLY - use the 'from' functions defined below.
     * Hoping in future Solidity will allow visibility modifiers on structs.
     */

    // @notice store bytes in word-size (32 byte) chunks
    struct Instance {
        bytes32[] value;
    }

    /**
     * @notice Create a new Bignumber instance from byte array
     * @dev    If the caller subsequently clears or modifies the input _value, it will corrupt the BigNumber value.
     * @param _value Number stored in big endian bytes
     * @return instance of BigNumber
     */
    function from(bytes memory _value) internal view returns (Instance memory) {
        uint256 length = _value.length;
        if (length == 0) {
            // Zero
            return Instance(new bytes32[](0));
        }
        uint256 numSlots = (length + 31) >> 5;
        Instance memory _instance = Instance(new bytes32[](numSlots));

        // ensure there aren't any leading zero words
        // this is not the zeroOffset yet, this is the modulo of the length
        uint256 zeroOffset = length & 0x1f;
        bytes32 word;
        if (zeroOffset == 0) {
            assembly {
                // load the first word from _value
                word := mload(add(_value, 0x20))
            }
            require(
                word != 0,
                "High-word must be set when input is bytes32-aligned"
            );
        } else {
            // calculate zeroOffset
            zeroOffset = 32 - zeroOffset;
            assembly {
                // load the first word from _value
                word := shr(mul(0x8, zeroOffset), mload(add(_value, 0x20)))
            }
            require(
                word != 0,
                "High-word must be set when input is bytes32-aligned"
            );
        }

        assembly {
            /*
            Call precompiled contract to copy data
            gas cost is 15 + 3/word
            there is no packing for structs in memory, so this just loads the slot for _instance
            shift 32 bytes to skip the length value of each reference type
            shift an additional 32 - offset bits on the result to naturally create the offset
            */
            if iszero(
                staticcall(
                    add(0x0f, mul(0x03, numSlots)),
                    0x04,
                    add(_value, 0x20),
                    length,
                    add(mload(_instance), add(0x20, zeroOffset)),
                    length
                )
            ) {
                revert(0, 0)
            }
        }

        return _instance;
    }

    /**
     * @notice Create a new BigNumber instance from uint256
     * @param _value Number stored in uint256
     * @return instance of BigNumber
     */
    function from(uint256 _value)
        internal
        pure
        returns (Instance memory instance)
    {
        if (_value != 0x0) {
            instance = Instance(new bytes32[](1));
            instance.value[0] = bytes32(_value);
        }
    }

    /**
     * @notice Convert instance to padded byte array
     * @param _instance BigNumber instance to convert
     * @param _size Desired size of byte array
     * @return result byte array
     */
    function asBytes(Instance memory _instance, uint256 _size)
        internal
        view
        returns (bytes memory)
    {
        uint256 length = _instance.value.length;
        require(_size & 0x1f == 0x0, "Size must be multiple of 0x20");

        uint256 _byteLength = length << 5;
        require(_size >= _byteLength, "Number too large to represent");

        uint256 zeroOffset = _size - _byteLength;
        bytes memory result = new bytes(_size);

        assembly {
            /*
            Call precompiled contract to copy data
            gas cost is 15 + 3/word
            there is no packing for structs in memory, so this just loads the slot for _instance
            shift 32 bytes to skip the length value of each reference type
            shift an additional zeroOffset bits on the result to naturally create the offset
            */
            if iszero(
                staticcall(
                    add(0x0f, mul(0x03, length)),
                    0x04,
                    add(mload(_instance), 0x20),
                    _byteLength,
                    add(result, add(0x20, zeroOffset)),
                    _byteLength
                )
            ) {
                revert(0, 0)
            }
        }

        return result;
    }

    /**
     * @notice Convert instance to minimal byte array
     * @param _instance BigNumber instance to convert
     * @return result byte array
     */
    function asBytes(Instance memory _instance)
        internal
        view
        returns (bytes memory)
    {
        uint256 _length = _instance.value.length;
        if (_length == 0) {
            return new bytes(0);
        }

        bytes32 firstWord = _instance.value[0];
        uint256 zeroOffset = 0;
        if (firstWord >> 128 == 0) {
            firstWord <<= 128;
            zeroOffset += 16;
        }
        if (firstWord >> 192 == 0) {
            firstWord <<= 64;
            zeroOffset += 8;
        }
        if (firstWord >> 224 == 0) {
            firstWord <<= 32;
            zeroOffset += 4;
        }
        if (firstWord >> 240 == 0) {
            firstWord <<= 16;
            zeroOffset += 2;
        }
        if (firstWord >> 248 == 0) {
            zeroOffset += 1;
        }

        uint256 _byteLength = (_length << 5) - zeroOffset;

        bytes memory result = new bytes(_byteLength);

        assembly {
            /*
            Call precompiled contract to copy data
            gas cost is 15 + 3/word
            there is no packing for structs in memory, so this just loads the slot for _instance
            shift 32 bytes to skip the length value of each reference type
            shift an additional 32 + zeroOffset bits on the result to naturally create the offset
            */
            if iszero(
                staticcall(
                    add(0x0f, mul(0x03, _length)),
                    0x04,
                    add(mload(_instance), add(0x20, zeroOffset)),
                    _byteLength,
                    add(result, 0x20),
                    _byteLength
                )
            ) {
                revert(0, 0)
            }
        }

        return result;
    }

    /**
     * @notice Obtain length (in bytes) of BigNumber instance
     * This will be rounded up to nearest multiple of 0x20 bytes
     *
     * @param _instance BigNumber instance
     * @return Size (in bytes) of BigNumber instance
     */
    function byteLength(Instance memory _instance)
        internal
        pure
        returns (uint256)
    {
        return _instance.value.length << 5;
    }

    /**
     * @notice Obtain minimal length (in bytes) of BigNumber instance
     *
     * @param _instance BigNumber instance
     * @return Size (in bytes) of minimal BigNumber instance
     */
    function minimalByteLength(Instance memory _instance)
        internal
        pure
        returns (uint256)
    {
        uint256 _byteLength = byteLength(_instance);

        if (_byteLength == 0) {
            return 0;
        }

        bytes32 firstWord = _instance.value[0];
        uint256 zeroOffset = 0;
        if (firstWord >> 128 == 0) {
            firstWord <<= 128;
            zeroOffset += 16;
        }
        if (firstWord >> 192 == 0) {
            firstWord <<= 64;
            zeroOffset += 8;
        }
        if (firstWord >> 224 == 0) {
            firstWord <<= 32;
            zeroOffset += 4;
        }
        if (firstWord >> 240 == 0) {
            firstWord <<= 16;
            zeroOffset += 2;
        }
        if (firstWord >> 248 == 0) {
            zeroOffset += 1;
        }

        return _byteLength - zeroOffset;
    }

    /**
     * @notice Perform modular exponentiation of BigNumber instance
     * @param _base Base number
     * @param _exponent Exponent
     * @param _modulus Modulus
     * @return result (_base ^ _exponent) % _modulus
     */
    function modexp(
        Instance memory _base,
        Instance memory _exponent,
        Instance memory _modulus
    ) internal view returns (Instance memory result) {
        result.value = innerModExp(
            _base.value,
            _exponent.value,
            _modulus.value
        );
    }

    /**
     * @notice Perform modular multiplication of BigNumber instances
     * @param _a number
     * @param _b number
     * @param _modulus Modulus
     * @return (_a * _b) % _modulus
     */
    function modmul(
        Instance memory _a,
        Instance memory _b,
        Instance memory _modulus
    ) internal view returns (Instance memory) {
        return modulo(multiply(_a, _b), _modulus);
    }

    /**
     * @notice Compare two BigNumber instances for equality
     * @param _a number
     * @param _b number
     * @return -1 if (_a<_b), 1 if (_a>_b) and 0 if (_a==_b)
     */
    function cmp(Instance memory _a, Instance memory _b)
        internal
        pure
        returns (int256)
    {
        uint256 aLength = _a.value.length;
        uint256 bLength = _b.value.length;
        if (aLength > bLength) return 0x1;
        if (bLength > aLength) return -0x1;

        bytes32 aWord;
        bytes32 bWord;

        for (uint256 i = 0; i < _a.value.length; i++) {
            aWord = _a.value[i];
            bWord = _b.value[i];

            if (aWord > bWord) {
                return 1;
            }
            if (bWord > aWord) {
                return -1;
            }
        }

        return 0;
    }

    /**
     * @notice Add two BigNumber instances
     * Not used outside the library itself
     */
    function privateAdd(Instance memory _a, Instance memory _b)
        internal
        pure
        returns (Instance memory instance)
    {
        uint256 aLength = _a.value.length;
        uint256 bLength = _b.value.length;
        if (aLength == 0) return _b;
        if (bLength == 0) return _a;

        if (aLength >= bLength) {
            instance.value = innerAdd(_a.value, _b.value);
        } else {
            instance.value = innerAdd(_b.value, _a.value);
        }
    }

    /**
     * @dev max + min
     */
    function innerAdd(bytes32[] memory _max, bytes32[] memory _min)
        private
        pure
        returns (bytes32[] memory result)
    {
        assembly {
            // Get the highest available block of memory
            let result_start := mload(0x40)

            // uint256 max (all bits set; inverse of 0)
            let uint_max := not(0x0)

            let carry := 0x0

            // load lengths of inputs
            let max_len := shl(5, mload(_max))
            let min_len := shl(5, mload(_min))

            // point to last word of each byte array.
            let max_ptr := add(_max, max_len)
            let min_ptr := add(_min, min_len)

            // set result_ptr end.
            let result_ptr := add(add(result_start, 0x20), max_len)

            // while 'min' words are still available
            // for(int i=0; i<min_length; i+=0x20)
            for {
                let i := 0x0
            } lt(i, min_len) {
                i := add(i, 0x20)
            } {
                // get next word for 'max'
                let max_val := mload(max_ptr)
                // get next word for 'min'
                let min_val := mload(min_ptr)

                // check if this needs to carry over to a new word
                // sum of both words that this is adding
                let min_max := add(min_val, max_val)
                // plus the carry amount if there is one
                let min_max_carry := add(min_max, carry)
                // store result
                mstore(result_ptr, min_max_carry)
                // carry again if this has overflowed
                carry := or(lt(min_max, min_val), lt(min_max_carry, carry))
                // point to next 'min' word
                min_ptr := sub(min_ptr, 0x20)

                // point to next 'result' word
                result_ptr := sub(result_ptr, 0x20)
                // point to next 'max' word
                max_ptr := sub(max_ptr, 0x20)
            }

            // remainder after 'min' words are complete.
            // for(int i=min_length; i<max_length; i+=0x20)
            for {
                let i := min_len
            } lt(i, max_len) {
                i := add(i, 0x20)
            } {
                // get next word for 'max'
                let max_val := mload(max_ptr)

                // result_word = max_word+carry
                let max_carry := add(max_val, carry)
                mstore(result_ptr, max_carry)
                // finds whether or not to set the carry bit for the next iteration.
                carry := lt(max_carry, carry)

                // point to next 'result' word
                result_ptr := sub(result_ptr, 0x20)
                // point to next 'max' word
                max_ptr := sub(max_ptr, 0x20)
            }

            // store the carry bit
            mstore(result_ptr, carry)
            // move result ptr up by a slot if no carry
            result := add(result_start, sub(0x20, shl(0x5, carry)))

            // store length of result. The function is finished with the byte array.
            mstore(result, add(shr(5, max_len), carry))

            // Update freemem pointer to point to new end of memory.
            mstore(0x40, add(result, add(shl(5, mload(result)), 0x20)))
        }
    }

    /**
     * @notice Return absolute difference between two instances
     * Not used outside the library itself
     */
    function absdiff(Instance memory _a, Instance memory _b)
        internal
        pure
        returns (Instance memory instance)
    {
        int256 compare = cmp(_a, _b);

        if (compare == 1) {
            instance.value = innerDiff(_a.value, _b.value);
        } else if (compare == -0x1) {
            instance.value = innerDiff(_b.value, _a.value);
        }
    }

    /**
     * @dev max - min
     */
    function innerDiff(bytes32[] memory _max, bytes32[] memory _min)
        private
        pure
        returns (bytes32[] memory result)
    {
        uint256 carry = 0x0;
        assembly {
            // Get the highest available block of memory
            let result_start := mload(0x40)

            // uint256 max. (all bits set; inverse of 0)
            let uint_max := not(0x0)

            // load lengths of inputs
            let max_len := shl(5, mload(_max))
            let min_len := shl(5, mload(_min))

            //go to end of arrays
            let max_ptr := add(_max, max_len)
            let min_ptr := add(_min, min_len)

            //point to least significant result word.
            let result_ptr := add(result_start, max_len)
            // save memory_end to update free memory pointer at the end.
            let memory_end := add(result_ptr, 0x20)

            // while 'min' words are still available.
            // for(int i=0; i<min_len; i+=0x20)
            for {
                let i := 0x0
            } lt(i, min_len) {
                i := add(i, 0x20)
            } {
                // get next word for 'max'
                let max_val := mload(max_ptr)
                // get next word for 'min'
                let min_val := mload(min_ptr)

                // result_word = (max_word-min_word)-carry
                // find whether or not to set the carry bit for the next iteration.
                let max_min := sub(max_val, min_val)
                let max_min_carry := sub(max_min, carry)
                mstore(result_ptr, max_min_carry)
                carry := or(gt(max_min, max_val), gt(max_min_carry, max_min))

                // point to next 'result' word
                min_ptr := sub(min_ptr, 0x20)
                // point to next 'result' word
                result_ptr := sub(result_ptr, 0x20)
                // point to next 'max' word
                max_ptr := sub(max_ptr, 0x20)
            }

            // remainder after 'min' words are complete.
            // for(int i=min_len; i<max_len; i+=0x20)
            for {
                let i := min_len
            } lt(i, max_len) {
                i := add(i, 0x20)
            } {
                // get next word for 'max'
                let max_val := mload(max_ptr)

                // result_word = max_word-carry
                let max_carry := sub(max_val, carry)
                mstore(result_ptr, max_carry)
                carry := gt(max_carry, max_val)

                // point to next 'result' word
                result_ptr := sub(result_ptr, 0x20)
                // point to next 'max' word
                max_ptr := sub(max_ptr, 0x20)
            }

            // the following code removes any leading words containing all zeroes in the result.
            let shift := 0x20
            for {

            } iszero(mload(add(result_ptr, shift))) {

            } {
                shift := add(shift, 0x20)
            }

            shift := sub(shift, 0x20)
            if gt(shift, 0x0) {
                // for(result_ptr+=0x20;; result==0x0; result_ptr+=0x20)
                // push up the start pointer for the result..
                result_start := add(result_start, shift)
                // and subtract a word (0x20 bytes) from the result length.
                max_len := sub(max_len, shift)
            }

            // point 'result' bytes value to the correct address in memory
            result := result_start

            // store length of result. The function is finished with the byte array.
            mstore(result, shr(5, max_len))

            // Update freemem pointer.
            mstore(0x40, memory_end)
        }

        return (result);
    }

    /**
     * @notice Multiply two instances
     * @param _a number
     * @param _b number
     * @return res _a * _b
     */
    function multiply(Instance memory _a, Instance memory _b)
        internal
        view
        returns (Instance memory res)
    {
        res = opAndSquare(_a, _b, true);

        if (cmp(_a, _b) != 0x0) {
            // diffSquared = (a-b)^2
            Instance memory diffSquared = opAndSquare(_a, _b, false);

            // res = add_and_square - diffSquared
            // diffSquared can never be greater than res
            // so it is safe to use innerDiff directly instead of absdiff
            res.value = innerDiff(res.value, diffSquared.value);
        }
        res = privateRightShift(res);
        return res;
    }

    /**
     * @dev take two instances, add or diff them, then square the result
     */
    function opAndSquare(
        Instance memory _a,
        Instance memory _b,
        bool _add
    ) private view returns (Instance memory res) {
        Instance memory two = from(0x2);

        bytes memory _modulus;

        res = _add ? privateAdd(_a, _b) : absdiff(_a, _b);
        uint256 modIndex = (res.value.length << 6) + 0x1;

        _modulus = new bytes(1);
        assembly {
            //store length of modulus
            mstore(_modulus, modIndex)
            //set first modulus word
            mstore(
                add(_modulus, 0x20),
                0xf000000000000000000000000000000000000000000000000000000000000000
            )
            //update freemem pointer to be modulus index + length
            // mstore(0x40, add(_modulus, add(modIndex, 0x20)))
        }

        Instance memory modulus;
        modulus = from(_modulus);

        res = modexp(res, two, modulus);
    }

    /**
     * @dev a % mod
     */
    function modulo(Instance memory _a, Instance memory _mod)
        private
        view
        returns (Instance memory res)
    {
        Instance memory one = from(1);
        res = modexp(_a, one, _mod);
    }

    /**
     * @dev Use the precompile to perform _base ^ _exp % _mod
     */
    function innerModExp(
        bytes32[] memory _base,
        bytes32[] memory _exp,
        bytes32[] memory _mod
    ) private view returns (bytes32[] memory ret) {
        assembly {
            let bl := shl(5, mload(_base))
            let el := shl(5, mload(_exp))
            let ml := shl(5, mload(_mod))

            // Free memory pointer is always stored at 0x40
            let freemem := mload(0x40)

            // arg[0] = base.length @ +0
            mstore(freemem, bl)

            // arg[1] = exp.length @ + 0x20
            mstore(add(freemem, 0x20), el)

            // arg[2] = mod.length @ + 0x40
            mstore(add(freemem, 0x40), ml)

            // arg[3] = base.bits @ + 0x60
            // Use identity built-in (contract 0x4) as a cheap memcpy
            let success := staticcall(
                450,
                0x4,
                add(_base, 0x20),
                bl,
                add(freemem, 0x60),
                bl
            )

            // arg[4] = exp.bits @ +0x60+base.length
            let argBufferSize := add(0x60, bl)
            success := and(
                success,
                staticcall(
                    450,
                    0x4,
                    add(_exp, 0x20),
                    el,
                    add(freemem, argBufferSize),
                    el
                )
            )

            // arg[5] = mod.bits @ +0x60+base.length+exp.length
            argBufferSize := add(argBufferSize, el)
            success := and(
                success,
                staticcall(
                    0x1C2,
                    0x4,
                    add(_mod, 0x20),
                    ml,
                    add(freemem, argBufferSize),
                    ml
                )
            )

            // Total argBufferSize of input = 0x60+base.length+exp.length+mod.length
            argBufferSize := add(argBufferSize, ml)
            // Invoke contract 0x5, put return value right after mod.length, @ +0x60
            success := and(
                success,
                staticcall(
                    sub(gas(), 0x546),
                    0x5,
                    freemem,
                    argBufferSize,
                    add(0x60, freemem),
                    ml
                )
            )

            if iszero(success) {
                revert(0x0, 0x0)
            } // fail where there isn't enough gas to make the call

            let length := ml
            let result_ptr := add(0x60, freemem)

            // the following code removes any leading words containing all zeroes in the result.
            let shift := 0x0
            for {

            } and(gt(length, shift), iszero(mload(add(result_ptr, shift)))) {

            } {
                shift := add(shift, 0x20)
            }

            if gt(shift, 0x0) {
                // push up the start pointer for the result..
                result_ptr := add(result_ptr, shift)
                // and subtract a the words from the result length.
                length := sub(length, shift)
            }

            ret := sub(result_ptr, 0x20)
            mstore(ret, shr(5, length))

            // point to the location of the return value (length, bits)
            // assuming mod length is multiple of 0x20, return value is already in the right format.
            // Otherwise, the offset needs to be adjusted.
            // ret := add(0x40,freemem)
            // deallocate freemem pointer
            mstore(0x40, add(add(0x60, freemem), ml))
        }
        return ret;
    }

    /**
     * @dev Right shift instance 'dividend' by 'value' bits.
     * This clobbers the passed _dividend
     */
    function privateRightShift(Instance memory _dividend)
        internal
        pure
        returns (Instance memory)
    {
        bytes32[] memory result;
        uint256 wordShifted;
        uint256 maskShift = 0xfe;
        uint256 precedingWord;
        uint256 resultPtr;
        uint256 length = _dividend.value.length << 5;

        require(length <= 1024, "Length must be less than 8192 bits");

        assembly {
            resultPtr := add(mload(_dividend), length)
        }

        for (int256 i = int256(length) - 0x20; i >= 0x0; i -= 0x20) {
            // for each word:
            assembly {
                // get next word
                wordShifted := mload(resultPtr)
                // if i==0x0:
                switch iszero(i)
                case 0x1 {
                    // handles msword: no precedingWord needed.
                    precedingWord := 0x0
                }
                default {
                    // else get precedingWord.
                    precedingWord := mload(sub(resultPtr, 0x20))
                }
            }
            // right shift current by value
            wordShifted >>= 0x2;
            // left shift next significant word by maskShift
            precedingWord <<= maskShift;
            assembly {
                // store OR'd precedingWord and shifted value in-place
                mstore(resultPtr, or(wordShifted, precedingWord))
            }
            // point to next value.
            resultPtr -= 0x20;
        }

        assembly {
            // the following code removes a leading word if any containing all zeroes in the result.
            resultPtr := add(resultPtr, 0x20)

            if and(gt(length, 0x0), iszero(mload(resultPtr))) {
                // push up the start pointer for the result..
                resultPtr := add(resultPtr, 0x20)
                // and subtract a word (0x20 bytes) from the result length.
                length := sub(length, 0x20)
            }

            result := sub(resultPtr, 0x20)
            mstore(result, shr(5, length))
        }

        return Instance(result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** @title Probable prime tester with Miller-Rabin
 */
contract IsPrime {
    /* Compute modular exponentiation using the modexp precompile contract
     * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-198.md
     */
    function expmod(
        uint256 _x,
        uint256 _e,
        uint256 _n
    ) private view returns (uint256 r) {
        assembly {
            let p := mload(0x40) // Load free memory pointer
            mstore(p, 0x20) // Store length of x (256 bit)
            mstore(add(p, 0x20), 0x20) // Store length of e (256 bit)
            mstore(add(p, 0x40), 0x20) // Store length of N (256 bit)
            mstore(add(p, 0x60), _x) // Store x
            mstore(add(p, 0x80), _e) // Store e
            mstore(add(p, 0xa0), _n) // Store n

            // Call precompiled modexp contract, input and output at p
            if iszero(staticcall(gas(), 0x05, p, 0xc0, p, 0x20)) {
                // revert if failed
                revert(0, 0)
            }
            // Load output (256 bit)
            r := mload(p)
        }
    }

    /** @notice Test if number is probable prime
     * Probability of false positive is (1/4)**_k
     * @param _n Number to be tested for primality
     * @param _k Number of iterations
     */
    function isProbablePrime(uint256 _n, uint256 _k)
        public
        view
        returns (bool)
    {
        if (_n == 2 || _n == 3 || _n == 5) {
            return true;
        }
        if (_n == 1 || (_n & 1 == 0)) {
            return false;
        }

        uint256 s = 0;
        uint256 _n3 = _n - 3;
        uint256 _n1 = _n - 1;
        uint256 d = _n1;

        //calculate the trailing zeros on the binary representation of the number
        if (d << 128 == 0) {
            d >>= 128;
            s += 128;
        }
        if (d << 192 == 0) {
            d >>= 64;
            s += 64;
        }
        if (d << 224 == 0) {
            d >>= 32;
            s += 32;
        }
        if (d << 240 == 0) {
            d >>= 16;
            s += 16;
        }
        if (d << 248 == 0) {
            d >>= 8;
            s += 8;
        }
        if (d << 252 == 0) {
            d >>= 4;
            s += 4;
        }
        if (d << 254 == 0) {
            d >>= 2;
            s += 2;
        }
        if (d << 255 == 0) {
            d >>= 1;
            s += 1;
        }

        bytes32 prevBlockHash = blockhash(block.number - 1);

        for (uint256 i = 0; i < _k; ++i) {
            bytes32 hash = keccak256(abi.encode(prevBlockHash, i));
            uint256 a = (uint256(hash) % _n3) + 2;
            uint256 x = expmod(a, d, _n);
            if (x != 1 && x != _n1) {
                uint256 j;
                for (j = 0; j < s; ++j) {
                    x = mulmod(x, x, _n);
                    if (x == _n1) {
                        break;
                    }
                }
                if (j == s) {
                    return false;
                }
            }
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../policy/Policy.sol";
import "../../policy/PolicedUtils.sol";
import "../../utils/TimeUtils.sol";
import "../../currency/IECO.sol";
import "../monetary/RandomInflation.sol";

/** @title Inflation Root Hash Proposal
 * This implements a root hash proposal contract to
 * establish a merkle tree representing accounts and balances
 *
 * Merkle Tree serves as a way to fairly establish which addresses can claim the random inflation reward
 */
contract InflationRootHashProposal is PolicedUtils, TimeUtils {
    enum ChallengeStatus {
        Empty,
        Pending,
        Resolved
    }

    enum RootHashStatus {
        Pending,
        Rejected,
        Accepted
    }

    struct ChallengeResponse {
        address account;
        uint256 balance;
        uint256 sum;
    }

    struct InflationChallenge {
        bool initialized;
        uint256 challengeEnds;
        uint256 amountOfRequests;
        mapping(uint256 => ChallengeStatus) challengeStatus;
    }

    struct RootHashProposal {
        bool initialized;
        bytes32 rootHash;
        uint256 totalSum;
        uint256 amountOfAccounts;
        uint256 lastLiveChallenge;
        uint256 amountPendingChallenges;
        uint256 totalChallenges;
        uint256 stakedAmount;
        uint256 newChallengerSubmissionEnds;
        RootHashStatus status;
        mapping(address => InflationChallenge) challenges;
        mapping(uint256 => ChallengeResponse) challengeResponses;
        mapping(address => bool) claimed;
    }

    // the ECO token contract address
    IECO public immutable ecoToken;

    /** The root hash accepted for current generation, set as a final result */
    bytes32 public acceptedRootHash;

    /** The total cumulative sum of the accepted root hash proposal */
    uint256 public acceptedTotalSum;

    /** The total number of accounts in the merkle tree of the accepted root hash proposal */
    uint256 public acceptedAmountOfAccounts;

    /** proposer to proposal data structure. Stores all evaluated proposals */
    mapping(address => RootHashProposal) public rootHashProposals;

    /** Challenger charged with CHALLENGE_FEE ECO every time they challenge proposal */
    uint256 public constant CHALLENGE_FEE = 1000e18;

    /** Root hash proposer charged with PROPOSER_FEE ECO for the root hash submission */
    uint256 public constant PROPOSER_FEE = 100000e18;

    /** Initial amount of time given to challengers to submit challenges to new proposal */
    uint256 public constant CHALLENGING_TIME = 1 days;

    /** Amount of time given to challengers to contest a challenges to a proposal */
    uint256 public constant CONTESTING_TIME = 1 hours;

    /** The time period to collect fees after the root hash was accepted.
     */
    uint256 public constant FEE_COLLECTION_TIME = 180 days;

    /** The timestamp at which the fee collection phase ends and contract might be destructed.
     */
    uint256 public feeCollectionEnds;

    /** merkle tree verified against balances at block number
     */
    uint256 public blockNumber;

    /* Event to be emitted whenever a new root hash proposal submitted to the contract.
     */
    event RootHashPost(
        address indexed proposer,
        bytes32 indexed proposedRootHash,
        uint256 totalSum,
        uint256 amountOfAccounts
    );

    /* Event to be emitted whenever a new challenge to root hash submitted to the contract.
     */
    event RootHashChallengeIndexRequest(
        address indexed proposer,
        address challenger,
        uint256 indexed index
    );

    /* Event to be emitted whenever proposer successfully responded to a challenge
     */
    event ChallengeSuccessResponse(
        address indexed proposer,
        address challenger,
        address account,
        uint256 balance,
        uint256 sum,
        uint256 indexed index
    );

    /* Event to be emitted whenever a root hash proposal rejected.
     */
    event RootHashRejection(address indexed proposer);

    /* Event to be emitted whenever a missing account claim succeeded. Root hash is rejected.
     */
    event ChallengeMissingAccountSuccess(
        address indexed proposer,
        address challenger,
        address missingAccount,
        uint256 indexed index
    );

    /* Event to be emitted whenever a root hash proposal accepted.
     */
    event RootHashAcceptance(
        address indexed proposer,
        uint256 totalSum,
        uint256 amountOfAccounts
    );

    /* Event to be emitted whenever the configuration for the inflation root hash proposal contract is set
     */
    event ConfigureBlock(uint256 _blockNumber);

    modifier hashIsNotAcceptedYet() {
        require(
            acceptedRootHash == 0,
            "The root hash accepted, no more actions allowed"
        );
        _;
    }

    constructor(Policy _policy, IECO _ecoAddr) PolicedUtils(_policy) {
        require(
            address(_ecoAddr) != address(0),
            "do not set the _ecoAddr as the zero address"
        );
        ecoToken = IECO(_ecoAddr);
    }

    /** @notice Configure the inflation root hash proposal contract
     *  which is part of the random inflation mechanism
     *
     * @param _blockNumber block number to verify accounts balances against
     */
    function configure(uint256 _blockNumber) external {
        require(blockNumber == 0, "This instance has already been configured");

        blockNumber = _blockNumber;
        emit ConfigureBlock(_blockNumber);
    }

    /** @notice Allows to propose new root hash
     *  which is part of the random inflation mechanism
     *
     * @param _proposedRootHash a root hash of the merkle tree describing all the accounts
     * @param _totalSum total cumulative sum of all the balances in the merkle tree
     * @param _amountOfAccounts total amount of accounts in the tree
     */
    function proposeRootHash(
        bytes32 _proposedRootHash,
        uint256 _totalSum,
        uint256 _amountOfAccounts
    ) external hashIsNotAcceptedYet {
        require(_proposedRootHash != bytes32(0), "Root hash cannot be zero");
        require(_totalSum > 0, "Total sum cannot be zero");
        require(
            _amountOfAccounts > 0,
            "Hash must consist of at least 1 account"
        );

        RootHashProposal storage proposal = rootHashProposals[msg.sender];

        require(!proposal.initialized, "Root hash already proposed");

        proposal.initialized = true;
        proposal.rootHash = _proposedRootHash;
        proposal.totalSum = _totalSum;
        proposal.amountOfAccounts = _amountOfAccounts;
        proposal.newChallengerSubmissionEnds = getTime() + CHALLENGING_TIME;

        emit RootHashPost(
            msg.sender,
            _proposedRootHash,
            _totalSum,
            _amountOfAccounts
        );

        chargeFee(msg.sender, msg.sender, PROPOSER_FEE);
    }

    /** @notice Allows to challenge previously proposed root hash.
     *  Challenge requires proposer of the root hash submit proof of the account for requested index
     *
     *  @param _proposer  the roothash proposer address
     *  @param _index    index in the merkle tree of the account being challenged
     */
    function challengeRootHashRequestAccount(address _proposer, uint256 _index)
        external
        hashIsNotAcceptedYet
    {
        requireValidChallengeConstraints(_proposer, msg.sender, _index);
        RootHashProposal storage proposal = rootHashProposals[_proposer];

        InflationChallenge storage challenge = proposal.challenges[msg.sender];

        if (!challenge.initialized) {
            challenge.initialized = true;
            challenge.challengeEnds = getTime() + CHALLENGING_TIME;
            challenge.challengeStatus[_index] = ChallengeStatus.Pending;
        } else {
            require(
                challenge.challengeStatus[_index] == ChallengeStatus.Empty,
                "Index already challenged"
            );
            challenge.challengeStatus[_index] = ChallengeStatus.Pending;
        }
        emit RootHashChallengeIndexRequest(_proposer, msg.sender, _index);
        updateCounters(_proposer, msg.sender);

        chargeFee(msg.sender, _proposer, CHALLENGE_FEE);
    }

    /** @notice A special challenge, the challenger can claim that an account is missing
     *
     * @param _proposer         the roothash proposer address
     * @param _index        index in the merkle tree of the account being challenged
     * @param _account      address of the missing account
     */
    function claimMissingAccount(
        address _proposer,
        uint256 _index,
        address _account
    ) external hashIsNotAcceptedYet {
        requireValidChallengeConstraints(_proposer, msg.sender, _index);
        RootHashProposal storage proposal = rootHashProposals[_proposer];
        InflationChallenge storage challenge = proposal.challenges[msg.sender];

        require(
            ecoToken.getPastVotes(_account, blockNumber) > 0,
            "Missing account does not exist"
        );

        require(challenge.initialized, "Submit Index Request first");

        if (_index != 0) {
            require(
                challenge.challengeStatus[_index - 1] ==
                    ChallengeStatus.Resolved,
                "Left _index is not resolved"
            );
            require(
                proposal.challengeResponses[_index - 1].account < _account,
                "Missing account claim failed"
            );
        }
        if (_index != proposal.amountOfAccounts) {
            require(
                challenge.challengeStatus[_index] == ChallengeStatus.Resolved,
                "Right _index is not resolved"
            );
            require(
                _account < proposal.challengeResponses[_index].account,
                "Missing account claim failed"
            );
        }

        challenge.amountOfRequests += 1;

        emit ChallengeMissingAccountSuccess(
            _proposer,
            msg.sender,
            _account,
            _index
        );
        rejectRootHash(_proposer);
    }

    /** @notice Allows to proposer of the root hash respond to a challenge of specific index with proof details
     *
     *  @param _challenger       address of the submitter of the challenge
     *  @param _proof            the “other nodes” in the merkle tree.
     *  @param _account          address of an account of challenged index in the tree
     *  @param _claimedBalance   balance of an account of challenged index in the tree
     *  @param _sum              cumulative sum of an account of challenged index in the tree
     *  @param _index            index in the merkle tree being answered
     */
    function respondToChallenge(
        address _challenger,
        bytes32[] calldata _proof,
        address _account,
        uint256 _claimedBalance,
        uint256 _sum,
        uint256 _index
    ) external hashIsNotAcceptedYet {
        require(
            _claimedBalance > 0,
            "Accounts with zero balance not allowed in Merkle tree"
        );
        require(
            _account != address(0),
            "The zero address not allowed in Merkle tree"
        );

        RootHashProposal storage proposal = rootHashProposals[msg.sender];
        InflationChallenge storage challenge = proposal.challenges[_challenger];

        require(
            getTime() < challenge.challengeEnds,
            "Timeframe to respond to a challenge is over"
        );

        require(
            challenge.challengeStatus[_index] == ChallengeStatus.Pending,
            "There is no pending challenge for this index"
        );

        /* Since the merkle tree includes the index as the hash, it's impossible to give isomorphic answers,
         * so any attempt to answer with a different value than what was used before will fail the merkle check,
         * hence this doesn't care if it rewrites previous answer */
        ChallengeResponse storage indexChallenge = proposal.challengeResponses[
            _index
        ];
        indexChallenge.account = _account;
        indexChallenge.balance = _claimedBalance;
        indexChallenge.sum = _sum;

        require(
            ecoToken.getPastVotes(_account, blockNumber) == _claimedBalance,
            "Challenge response failed account balance check"
        );

        require(
            verifyMerkleProof(
                _proof,
                proposal.rootHash,
                keccak256(
                    abi.encodePacked(_account, _claimedBalance, _sum, _index)
                ),
                _index,
                proposal.amountOfAccounts
            ),
            "Challenge response failed merkle tree verification check"
        );

        // Ensure first account starts at 0 cumulative sum
        if (_index == 0) {
            require(_sum == 0, "cumulative sum does not starts from 0");
        } else {
            ChallengeResponse storage leftNeighborChallenge = proposal
                .challengeResponses[_index - 1];
            if (leftNeighborChallenge.balance != 0) {
                // Is left neighbor queried, and is it valid?
                require(
                    leftNeighborChallenge.sum + leftNeighborChallenge.balance ==
                        _sum,
                    "Left neighbor sum verification failed"
                );
                require(
                    leftNeighborChallenge.account < _account,
                    "Left neighbor order verification failed"
                );
            }
        }

        // Ensure final account matches total sum
        if (_index == proposal.amountOfAccounts - 1) {
            require(
                proposal.totalSum == _sum + _claimedBalance,
                "cumulative sum does not match total sum"
            );
        } else {
            ChallengeResponse storage rightNeighborChallenge = proposal
                .challengeResponses[_index + 1];
            // Is right neighbor queried, and is it valid?
            if (rightNeighborChallenge.balance != 0) {
                require(
                    _sum + _claimedBalance == rightNeighborChallenge.sum,
                    "Right neighbor sum verification failed"
                );
                require(
                    _account < rightNeighborChallenge.account,
                    "Right neighbor order verification failed"
                );
            }
        }

        emit ChallengeSuccessResponse(
            msg.sender,
            _challenger,
            _account,
            _claimedBalance,
            _sum,
            _index
        );

        challenge.challengeStatus[_index] = ChallengeStatus.Resolved;
        proposal.amountPendingChallenges -= 1;
        challenge.challengeEnds += CONTESTING_TIME;
    }

    /** @notice Checks root hash proposal. If time is out and there is unanswered challenges proposal is rejected. If time to submit
     *  new challenges is over and there is no unanswered challenges, root hash is accepted.
     *
     *  @param _proposer the roothash proposer address
     *
     */
    function checkRootHashStatus(address _proposer) external {
        RootHashProposal storage proposal = rootHashProposals[_proposer];

        if (
            acceptedRootHash == 0 &&
            getTime() > proposal.newChallengerSubmissionEnds &&
            getTime() > proposal.lastLiveChallenge
        ) {
            if (proposal.amountPendingChallenges == 0) {
                acceptRootHash(_proposer);
            } else {
                rejectRootHash(_proposer);
            }
        }

        if (
            acceptedRootHash != 0 && proposal.status == RootHashStatus.Pending
        ) {
            rejectRootHash(_proposer);
        }
    }

    /** @notice Verifies that the account specified is associated with the provided cumulative sum in the approved
     * Merkle tree for the current generation.
     *
     *  @param _who     address of the account attempting to claim
     *  @param _proof   the “other nodes” in the merkle tree.
     *  @param _sum     cumulative sum of a claiming account
     *  @param _index   index of the account
     */
    function verifyClaimSubmission(
        address _who,
        bytes32[] calldata _proof,
        uint256 _sum,
        uint256 _index
    ) external view returns (bool) {
        require(
            acceptedRootHash != 0,
            "Can't claim before root hash established"
        );
        uint256 balance = ecoToken.getPastVotes(_who, blockNumber);
        return
            verifyMerkleProof(
                _proof,
                acceptedRootHash,
                keccak256(abi.encodePacked(_who, balance, _sum, _index)),
                _index,
                acceptedAmountOfAccounts
            );
    }

    /** @notice Allows to claim fee paid as part of challenge or proposal submissions
     *
     *  @param _who        fee recipient
     *  @param _proposer   the roothash proposer address
     */
    function claimFeeFor(address _who, address _proposer) public {
        RootHashProposal storage proposal = rootHashProposals[_proposer];
        InflationChallenge storage challenge = proposal.challenges[_who];
        require(
            proposal.status != RootHashStatus.Pending,
            "Can't claim _fee on pending root hash proposal"
        );

        require(!proposal.claimed[_who], "fee already claimed");

        if (_who == _proposer) {
            require(
                proposal.status == RootHashStatus.Accepted ||
                    (proposal.status == RootHashStatus.Rejected &&
                        proposal.rootHash == acceptedRootHash &&
                        proposal.totalSum == acceptedTotalSum &&
                        proposal.amountOfAccounts == acceptedAmountOfAccounts),
                "proposer can't claim fee on not accepted hash"
            );
            require(
                ecoToken.transfer(_who, proposal.stakedAmount),
                "Transfer Failed"
            );
        } else {
            require(
                challenge.initialized &&
                    proposal.status == RootHashStatus.Rejected,
                "challenger may claim fee on rejected proposal only"
            );
            uint256 amount = challenge.amountOfRequests * CHALLENGE_FEE;
            amount =
                amount +
                (proposal.stakedAmount *
                    proposal.challenges[msg.sender].amountOfRequests) /
                proposal.totalChallenges;
            require(ecoToken.transfer(_who, amount), "Transfer Failed");
        }
        proposal.claimed[_who] = true;
    }

    /** @notice Allows to claim fee paid as part of challenge or proposal submissions
     *          on behalf of the caller (`msg.sender`).
     *
     *  @param _proposer   the roothash proposer address
     *
     */
    function claimFee(address _proposer) external {
        claimFeeFor(msg.sender, _proposer);
    }

    /** @notice Reclaims tokens on the inflation root hash proposal contract.
     *
     */
    function destruct() external {
        require(
            feeCollectionEnds != 0 && getTime() > feeCollectionEnds,
            "contract might be destructed after fee collection period is over"
        );
        require(
            ecoToken.transfer(
                address(policy),
                ecoToken.balanceOf(address(this))
            ),
            "Transfer Failed"
        );
    }

    /** @notice updates root hash proposal data structure to mark it rejected
     */
    function rejectRootHash(address _proposer) internal {
        rootHashProposals[_proposer].status = RootHashStatus.Rejected;
        emit RootHashRejection(_proposer);
    }

    /** @notice updates root hash proposal data structure  and contract state variables
     *  to mark root hash is accepted
     */
    function acceptRootHash(address _proposer) internal {
        RootHashProposal storage proposal = rootHashProposals[_proposer];

        proposal.status = RootHashStatus.Accepted;
        acceptedRootHash = proposal.rootHash;
        acceptedTotalSum = proposal.totalSum;
        acceptedAmountOfAccounts = proposal.amountOfAccounts;
        feeCollectionEnds = getTime() + FEE_COLLECTION_TIME;
        emit RootHashAcceptance(
            _proposer,
            proposal.totalSum,
            proposal.amountOfAccounts
        );
    }

    /**
     * @dev Returns true if a `_leaf` can be proved to be a part of a Merkle tree
     * defined by `_root`. For this, a `_proof` must be provided, containing
     * sibling hashes on the branch from the _leaf to the _root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     * (c) https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/MerkleProof.sol
     */
    function verifyMerkleProof(
        bytes32[] memory _proof,
        bytes32 _root,
        bytes32 _leaf,
        uint256 _index,
        uint256 _numAccounts
    ) internal pure returns (bool) {
        // ensure that the proof conforms to the minimum possible tree height
        // and also that the number of accounts is small enough to fit in the claimed tree
        if (
            1 << (_proof.length - 1) >= _numAccounts ||
            1 << (_proof.length) < _numAccounts
        ) {
            return false;
        }

        bytes32 computedHash = _leaf;

        // checks for validity of proof elements and tree ordering
        for (uint256 i = 0; i < _proof.length; i++) {
            bytes32 proofElement = _proof[i];
            if ((_index >> i) & 1 == 1) {
                // Hash(current element of the _proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            } else {
                // Hash(current computed hash + current element of the _proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            }
        }

        if (computedHash != _root) {
            return false;
        }

        // xor to separate matching and non-matching elements of the bitmaps
        uint256 branchBitMap = _index ^ (_numAccounts - 1);

        // verifies that unused tree nodes are reperesnted by bytes32(0)
        for (uint256 i = _proof.length; i > 0; i--) {
            // check if this is traversing the right edge of the filled tree
            // _numAccounts indexes from 1 but _index does so from zero
            if ((branchBitMap >> (i - 1)) & 1 == 0) {
                // see if the index is in a left branch requiring a zero valued right branch
                if ((_index >> (i - 1)) & 1 == 0) {
                    if (_proof[i - 1] != bytes32(0)) {
                        return false;
                    }
                }
            } else {
                // the index is now in the middle of the tree, cannot check further
                break;
            }
        }

        // Check if the computed hash (_root) is equal to the provided _root
        return true;
    }

    /** @notice increment counter that's used to track amount of open challenges and the timelines
     */
    function updateCounters(address _proposer, address _challenger) internal {
        RootHashProposal storage proposal = rootHashProposals[_proposer];
        InflationChallenge storage challenge = proposal.challenges[_challenger];
        uint256 challengeEnds = challenge.challengeEnds;

        proposal.totalChallenges += 1;
        proposal.amountPendingChallenges += 1;
        challenge.amountOfRequests += 1;

        challenge.challengeEnds = challengeEnds + CONTESTING_TIME;
        challengeEnds += CONTESTING_TIME;

        if (proposal.lastLiveChallenge < challengeEnds) {
            proposal.lastLiveChallenge = challengeEnds;
        }
    }

    /** @notice charge sender with a fee while updating tracking stake counter
     */
    function chargeFee(
        address _submitter,
        address _proposer,
        uint256 _fee
    ) internal {
        require(
            ecoToken.transferFrom(_submitter, address(this), _fee),
            "Transfer Failed"
        );
        rootHashProposals[_proposer].stakedAmount += _fee;
    }

    function requireValidChallengeConstraints(
        address _proposer,
        address _challenger,
        uint256 _index
    ) internal view {
        RootHashProposal storage proposal = rootHashProposals[_proposer];

        require(
            _proposer != _challenger,
            "Root hash proposer can't challenge its own submission"
        );
        require(
            proposal.rootHash != bytes32(0),
            "There is no such hash proposal"
        );
        require(
            proposal.status == RootHashStatus.Pending,
            "The proposal is resolved"
        );
        require(
            proposal.amountOfAccounts > _index,
            "The index have to be within the range of claimed amount of accounts"
        );
        uint256 requestsByChallenger = proposal
            .challenges[_challenger]
            .amountOfRequests;
        if (requestsByChallenger > 2) {
            /* math explanation x - number of request, N - amount of accounts, log base 2
              condition  -- x < 2 * log( N ) + 2
                            2 ^ x < 2 ^ (2 * log( N ) + 2)
                            2 ^ (x - 2) < (2 ^ log( N )) ^ 2
                            2 ^ (x - 2) < N ^ 2
            */

            require(
                1 << (requestsByChallenger - 2) <=
                    (proposal.amountOfAccounts)**2,
                "Challenger reached maximum amount of allowed challenges"
            );
        }
        InflationChallenge storage challenge = proposal.challenges[_challenger];
        if (!challenge.initialized) {
            require(
                getTime() < proposal.newChallengerSubmissionEnds,
                "Time to submit new challenges is over"
            );
        } else {
            require(
                getTime() < challenge.challengeEnds,
                "Time to submit additional challenges is over"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../monetary/Lockup.sol";
import "../../policy/PolicedUtils.sol";
import "../../currency/ECO.sol";
import "../../currency/ECOx.sol";
import "./ECOxStaking.sol";

/** @title VotingPower
 * Compute voting power for user
 */
contract VotingPower is PolicedUtils {
    // ECOx voting power is snapshotted when the contract is cloned
    uint256 public totalECOxSnapshot;

    // voting power to exclude from totalVotingPower
    uint256 public excludedVotingPower;

    // the ECO contract address
    ECO public immutable ecoToken;

    constructor(Policy _policy, ECO _ecoAddr) PolicedUtils(_policy) {
        require(
            address(_ecoAddr) != address(0),
            "Unrecoverable: do not set the _ecoAddr as the zero address"
        );
        ecoToken = _ecoAddr;
    }

    function totalVotingPower(uint256 _blockNumber)
        public
        view
        returns (uint256)
    {
        uint256 _supply = ecoToken.totalSupplyAt(_blockNumber);

        return _supply + 10 * totalECOxSnapshot - excludedVotingPower;
    }

    function votingPower(address _who, uint256 _blockNumber)
        public
        view
        returns (uint256)
    {
        uint256 _power = ecoToken.getPastVotes(_who, _blockNumber);
        uint256 _powerx = getXStaking().votingECOx(_who, _blockNumber);
        // ECOx has 10x the voting power of ECO per unit
        return _power + 10 * _powerx;
    }

    function getXStaking() internal view returns (ECOxStaking) {
        return ECOxStaking(policyFor(ID_ECOXSTAKING));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../policy/Policy.sol";
import "./proposals/Proposal.sol";
import "../../policy/PolicedUtils.sol";
import "../../utils/TimeUtils.sol";
import "./VotingPower.sol";
import "../../currency/ECO.sol";
import "../../currency/ECOx.sol";

/** @title PolicyVotes
 * This implements the voting and implementation phases of the policy decision process.
 * Open stake based voting is used for the voting phase.
 */
contract PolicyVotes is VotingPower, TimeUtils {
    /** The proposal being voted on */
    Proposal public proposal;

    /* The proposer of the proposal being voted on */
    address public proposer;

    /** The stake an the yes votes of an address on a proposal
     */
    struct VotePartial {
        uint256 stake;
        uint256 yesVotes;
    }

    /** The voting power that a user has based on their stake and
     *  the portion that they have voted yes with
     */
    mapping(address => VotePartial) public votePartials;

    /** Total currency staked in all ongoing votes in basic unit of 10^{-18} ECO (weico).
     */
    uint256 public totalStake;

    /** Total revealed positive stake in basic unit of 10^{-18} ECO (weico).
     */
    uint256 public yesStake;

    /** The length of the commit portion of the voting phase.
     */
    uint256 public constant VOTE_TIME = 3 days;

    /** The delay on a plurality win
     */
    uint256 public constant ENACTION_DELAY = 1 days;

    /** The timestamp at which the commit portion of the voting phase ends.
     */
    uint256 public voteEnds;

    /** Vote result */
    enum Result {
        Accepted,
        Rejected,
        Failed
    }

    /** Event emitted when the vote outcome is known.
     */
    event VoteCompletion(Result indexed result);

    /** Event emitted when a vote is submitted.
     * simple votes have the address's voting power as votesYes or votesNo, depending on the vote
     * split votes show the split and votesYes + votesNo might be less than the address's voting power
     */
    event PolicyVote(address indexed voter, uint256 votesYes, uint256 votesNo);

    /** The store block number to use when checking account balances for staking.
     */
    uint256 public blockNumber;

    /** This constructor just passes the call to the super constructor
     */
    // solhint-disable-next-line no-empty-blocks
    constructor(Policy _policy, ECO _ecoAddr) VotingPower(_policy, _ecoAddr) {}

    /** Submit your yes/no support
     *
     * Shows whether or not your voting power supports or does not support the vote
     *
     * Note Not voting is not equivalent to voting no. Percentage of voted support,
     * not percentage of total voting power is used to determine the win.
     *
     * @param _vote The vote for the proposal
     */
    function vote(bool _vote) external {
        require(
            getTime() < voteEnds,
            "Votes can only be recorded during the voting period"
        );

        uint256 _amount = votingPower(msg.sender, blockNumber);

        require(
            _amount > 0,
            "Voters must have held tokens before this voting cycle"
        );

        VotePartial storage vpower = votePartials[msg.sender];
        uint256 _oldStake = vpower.stake;
        uint256 _oldYesVotes = vpower.yesVotes;
        bool _prevVote = _oldYesVotes != 0;

        if (_oldStake != 0) {
            require(
                _prevVote != _vote ||
                    _oldStake != _amount ||
                    (_vote && (_oldYesVotes != _amount)),
                "Your vote has already been recorded"
            );

            if (_prevVote) {
                yesStake -= _oldYesVotes;
                vpower.yesVotes = 0;
            }
        }

        vpower.stake = _amount;
        totalStake = totalStake + _amount - _oldStake;

        if (_vote) {
            yesStake += _amount;
            vpower.yesVotes = _amount;

            emit PolicyVote(msg.sender, _amount, 0);
        } else {
            emit PolicyVote(msg.sender, 0, _amount);
        }
    }

    /** Submit a mixed vote of yes/no support
     *
     * Useful for contracts that wish to vote for an agregate of users
     *
     * Note As not voting is not equivalent to voting no it matters recording the no votes
     * The total amount of votes in favor is relevant for early enaction and the total percentage
     * of voting power that voted is necessary for determining a winner.
     *
     * Note As this is designed for contracts, the onus is on the contract designer to correctly
     * understand and take responsibility for its input parameters. The only check is to stop
     * someone from voting with more power than they have.
     *
     * @param _votesYes The amount of votes in favor of the proposal
     * @param _votesNo The amount of votes against the proposal
     */
    function voteSplit(uint256 _votesYes, uint256 _votesNo) external {
        require(
            getTime() < voteEnds,
            "Votes can only be recorded during the voting period"
        );

        uint256 _amount = votingPower(msg.sender, blockNumber);

        require(
            _amount > 0,
            "Voters must have held tokens before this voting cycle"
        );

        uint256 _totalVotes = _votesYes + _votesNo;

        require(
            _amount >= _totalVotes,
            "Your voting power is less than submitted yes + no votes"
        );

        VotePartial storage vpower = votePartials[msg.sender];
        uint256 _oldStake = vpower.stake;
        uint256 _oldYesVotes = vpower.yesVotes;

        if (_oldYesVotes > 0) {
            yesStake -= _oldYesVotes;
        }

        vpower.yesVotes = _votesYes;
        yesStake += _votesYes;

        vpower.stake = _totalVotes;
        totalStake = totalStake + _totalVotes - _oldStake;

        emit PolicyVote(msg.sender, _votesYes, _votesNo);
    }

    /** Initialize a cloned/proxied copy of this contract.
     *
     * @param _self The original contract, to provide access to storage data.
     */
    function initialize(address _self) public override onlyConstruction {
        super.initialize(_self);
    }

    /** Configure the proposals that are part of this voting cycle and start
     * the lockup period.
     *
     * This also fixes the end times of each subsequent phase.
     *
     * This can only be called once, and should be called atomically with
     * instantiation.
     *
     * @param _proposal The proposal to vote on.
     */
    function configure(
        Proposal _proposal,
        address _proposer,
        uint256 _cutoffBlockNumber,
        uint256 _totalECOxSnapshot,
        uint256 _excludedVotingPower
    ) external {
        require(voteEnds == 0, "This instance has already been configured");

        voteEnds = getTime() + VOTE_TIME;
        blockNumber = _cutoffBlockNumber;
        totalECOxSnapshot = _totalECOxSnapshot;
        excludedVotingPower = _excludedVotingPower;

        proposal = _proposal;
        proposer = _proposer;
    }

    /** Execute the proposal if it has enough support.
     *
     * Can only be called after the voting and the delay phase,
     * or after the point that at least 50% of the total voting power
     * has voted in favor of the proposal.
     *
     * If the proposal has been accepted, it will be enacted by
     * calling the `enacted` functions using `delegatecall`
     * from the root policy.
     */
    function execute() external {
        uint256 _total = totalVotingPower(blockNumber);

        Result _res;

        if (2 * yesStake < _total) {
            require(
                getTime() > voteEnds + ENACTION_DELAY,
                "Majority support required for early enaction"
            );
        }

        require(
            policyFor(ID_POLICY_VOTES) == address(this),
            "This contract no longer has authorization to enact the vote"
        );

        if (totalStake == 0) {
            // Nobody voted
            _res = Result.Failed;
        } else if (2 * yesStake < totalStake) {
            // Not enough yes votes
            _res = Result.Rejected;
        } else {
            // Vote passed
            _res = Result.Accepted;

            //Enact the policy
            policy.internalCommand(address(proposal), ID_POLICY_VOTES);
        }

        emit VoteCompletion(_res);
        policy.removeSelf(ID_POLICY_VOTES);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** @title Proposal
 * Interface specification for proposals. Any proposal submitted in the
 * policy decision process must implement this interface.
 */
interface Proposal {
    /** The name of the proposal.
     *
     * This should be relatively unique and descriptive.
     */
    function name() external view returns (string memory);

    /** A longer description of what this proposal achieves.
     */
    function description() external view returns (string memory);

    /** A URL where voters can go to see the case in favour of this proposal,
     * and learn more about it.
     */
    function url() external view returns (string memory);

    /** Called to enact the proposal.
     *
     * This will be called from the root policy contract using delegatecall,
     * with the direct proposal address passed in as _self so that storage
     * data can be accessed if needed.
     *
     * @param _self The address of the proposal contract.
     */
    function enacted(address _self) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../currency/VoteCheckpoints.sol";
import "../../currency/ECOx.sol";
import "../../policy/PolicedUtils.sol";
import "../IGeneration.sol";

/** @title ECOxStaking
 *
 */
contract ECOxStaking is VoteCheckpoints, PolicedUtils {
    /** The Deposit event indicates that ECOx has been locked up, credited
     * to a particular address in a particular amount.
     *
     * @param source The address that a deposit certificate has been issued to.
     * @param amount The amount of ECOx tokens deposited.
     */
    event Deposit(address indexed source, uint256 amount);

    /** The Withdrawal event indicates that a withdrawal has been made to a particular
     * address in a particular amount.
     *
     * @param destination The address that has made a withdrawal.
     * @param amount The amount in basic unit of 10^{-18} ECOx (weicoX) tokens withdrawn.
     */
    event Withdrawal(address indexed destination, uint256 amount);

    // the ECOx contract address
    IERC20 public immutable ecoXToken;

    constructor(Policy _policy, IERC20 _ecoXAddr)
        // Note that the policy has the ability to pause transfers
        // through ERC20Pausable, although transfers are paused by default
        // therefore the pauser is unset
        VoteCheckpoints("Staked ECOx", "sECOx", address(_policy), address(0))
        PolicedUtils(_policy)
    {
        require(
            address(_ecoXAddr) != address(0),
            "Critical: do not set the _ecoXAddr as the zero address"
        );
        ecoXToken = _ecoXAddr;
    }

    function deposit(uint256 _amount) external {
        address _source = msg.sender;

        require(
            ecoXToken.transferFrom(_source, address(this), _amount),
            "Transfer failed"
        );

        _mint(_source, _amount);

        emit Deposit(_source, _amount);
    }

    function withdraw(uint256 _amount) external {
        address _destination = msg.sender;

        // do this first to ensure that any undelegations in this function are caught
        _burn(_destination, _amount);

        require(ecoXToken.transfer(_destination, _amount), "Transfer Failed");

        emit Withdrawal(_destination, _amount);
    }

    function votingECOx(address _voter, uint256 _blockNumber)
        external
        view
        returns (uint256)
    {
        return getPastVotingGons(_voter, _blockNumber);
    }

    function totalVotingECOx(uint256 _blockNumber)
        external
        view
        returns (uint256)
    {
        return getPastTotalSupply(_blockNumber);
    }

    function transfer(address, uint256) public pure override returns (bool) {
        revert("sECOx is non-transferrable");
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public pure override returns (bool) {
        revert("sECOx is non-transferrable");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../CurrencyTimer.sol";
import "../../policy/PolicedUtils.sol";
import "../../utils/TimeUtils.sol";
import "../IGeneration.sol";
import "../../currency/ECO.sol";

/** @title Lockup
 * This provides deposit certificate functionality for the purpose of countering
 * inflationary effects.
 *
 * The contract instance is cloned by the CurrencyTimer contract when a vote outcome
 * mandates the issuance of deposit certificates. It has no special privileges.
 *
 * Deposits can be made and interest will be paid out to those who make
 * deposits. Deposit principal is accessable before the interested period
 * but for a penalty of not retrieving your gained interest as well as an
 * additional penalty of that same amount.
 */
contract Lockup is PolicedUtils, TimeUtils {
    // data structure for deposits made per address
    struct DepositRecord {
        /** The amount deposited in the underlying representation of the token
         * This allows deposit amounts to account for linear inflation during lockup
         */
        uint256 gonsDepositAmount;
        /** The amount of ECO to reward a successful withdrawal
         * Also equal to the penalty for withdrawing early
         * Calculated upon deposit
         */
        uint256 ecoDepositReward;
        /** Address the lockup has delegated the deposited funds to
         * Either the depositor or their primary delegate at time of deposit
         */
        address delegate;
    }

    // the ECO token address
    ECO public immutable ecoToken;

    // the CurrencyTimer address
    CurrencyTimer public immutable currencyTimer;

    // length in seconds that deposited funds must be locked up for a reward
    uint256 public duration;

    // timestamp for when the Lockup is no longer recieving deposits
    uint256 public depositWindowEnd;

    // length of the deposit window
    uint256 public constant DEPOSIT_WINDOW = 2 days;

    /** The fraction of payout gained on successful withdrawal
     * Also the fraction for the penality for withdrawing early.
     * A 9 digit fixed point decimal representation
     */
    uint256 public interest;

    // denotes the number of decimals of fixed point math for interest
    uint256 public constant INTEREST_DIVISOR = 1e9;

    // mapping from depositing addresses to data on their deposit
    mapping(address => DepositRecord) public deposits;

    /** The Deposit event indicates that a deposit certificate has been sold
     * to a particular address in a particular amount.
     *
     * @param to The address that a deposit certificate has been issued to.
     * @param amount The amount in basic unit of 10^{-18} ECO (weico) at time of deposit.
     */
    event Deposit(address indexed to, uint256 amount);

    /** The Withdrawal event indicates that a withdrawal has been made,
     * and records the account that was credited, the amount it was credited
     * with.
     *
     * @param to The address that has made a withdrawal.
     * @param amount The amount in basic unit of 10^{-18} ECO (weico) withdrawn.
     */
    event Withdrawal(address indexed to, uint256 amount);

    constructor(
        Policy _policy,
        ECO _ecoAddr,
        CurrencyTimer _timerAddr
    ) PolicedUtils(_policy) {
        require(
            address(_ecoAddr) != address(0),
            "do not set the _ecoAddr as the zero address"
        );
        require(
            address(_timerAddr) != address(0),
            "do not set the _timerAddr as the zero address"
        );
        ecoToken = _ecoAddr;
        currencyTimer = _timerAddr;
    }

    function deposit(uint256 _amount) external {
        internalDeposit(_amount, msg.sender, msg.sender);
    }

    function depositFor(uint256 _amount, address _benefactor) external {
        internalDeposit(_amount, msg.sender, _benefactor);
    }

    function withdraw() external {
        doWithdrawal(msg.sender, true);
    }

    function withdrawFor(address _who) external {
        doWithdrawal(_who, false);
    }

    function clone(uint256 _duration, uint256 _interest)
        external
        returns (Lockup)
    {
        require(
            implementation() == address(this),
            "This method cannot be called on clones"
        );
        require(_duration > 0, "duration should not be zero");
        require(_interest > 0, "interest should not be zero");
        Lockup _clone = Lockup(createClone(address(this)));
        _clone.initialize(address(this), _duration, _interest);
        return _clone;
    }

    function initialize(
        address _self,
        uint256 _duration,
        uint256 _interest
    ) external onlyConstruction {
        super.initialize(_self);
        duration = _duration;
        interest = _interest;
        depositWindowEnd = getTime() + DEPOSIT_WINDOW;
    }

    function doWithdrawal(address _owner, bool _allowEarly) internal {
        DepositRecord storage _deposit = deposits[_owner];

        uint256 _gonsAmount = _deposit.gonsDepositAmount;

        require(
            _gonsAmount > 0,
            "Withdrawals can only be made for accounts with valid deposits"
        );

        bool early = getTime() < depositWindowEnd + duration;

        require(_allowEarly || !early, "Only depositor may withdraw early");

        uint256 _inflationMult = ecoToken.getPastLinearInflation(block.number);
        uint256 _amount = _gonsAmount / _inflationMult;
        uint256 _rawDelta = _deposit.ecoDepositReward;
        uint256 _delta = _amount > _rawDelta ? _rawDelta : _amount;

        _deposit.gonsDepositAmount = 0;
        _deposit.ecoDepositReward = 0;

        ecoToken.undelegateAmountFromAddress(_deposit.delegate, _gonsAmount);
        require(ecoToken.transfer(_owner, _amount), "Transfer Failed");
        currencyTimer.lockupWithdrawal(_owner, _delta, early);

        if (early) {
            emit Withdrawal(_owner, _amount - _delta);
        } else {
            emit Withdrawal(_owner, _amount + _delta);
        }
    }

    function internalDeposit(
        uint256 _amount,
        address _payer,
        address _who
    ) private {
        require(
            getTime() < depositWindowEnd,
            "Deposits can only be made during sale window"
        );

        require(
            ecoToken.transferFrom(_payer, address(this), _amount),
            "Transfer Failed"
        );

        address _primaryDelegate = ecoToken.getPrimaryDelegate(_who);
        uint256 _inflationMult = ecoToken.getPastLinearInflation(block.number);
        uint256 _gonsAmount = _amount * _inflationMult;

        DepositRecord storage _deposit = deposits[_who];
        uint256 depositGons = _deposit.gonsDepositAmount;
        address depositDelegate = _deposit.delegate;

        if (depositGons > 0 && _primaryDelegate != depositDelegate) {
            ecoToken.undelegateAmountFromAddress(depositDelegate, depositGons);
            ecoToken.delegateAmount(
                _primaryDelegate,
                _gonsAmount + depositGons
            );
        } else {
            ecoToken.delegateAmount(_primaryDelegate, _gonsAmount);
        }

        _deposit.ecoDepositReward += (_amount * interest) / INTEREST_DIVISOR;
        _deposit.gonsDepositAmount += _gonsAmount;
        _deposit.delegate = _primaryDelegate;

        emit Deposit(_who, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../policy/PolicedUtils.sol";
import "../policy/Policy.sol";
import "./community/PolicyProposals.sol";
import "./monetary/CurrencyGovernance.sol";
import "../utils/TimeUtils.sol";
import "./IGenerationIncrease.sol";
import "./IGeneration.sol";
import "./monetary/Lockup.sol";
import "./monetary/RandomInflation.sol";
import "../currency/ECO.sol";

/** @title TimedPolicies
 * Oversees the time-based recurring processes that allow governance of the
 * Eco currency.
 */
contract CurrencyTimer is PolicedUtils, IGenerationIncrease {
    /** The on-chain address for the currency voting contract. This contract is
     * cloned for each new currency vote.
     */
    CurrencyGovernance public bordaImpl;

    RandomInflation public inflationImpl;
    Lockup public lockupImpl;

    // the ECO contract address
    ECO public immutable ecoToken;

    /* Current generation of the balance store. */
    uint256 public currentGeneration;

    mapping(uint256 => Lockup) public lockups;
    mapping(address => bool) public isLockup;

    mapping(uint256 => RandomInflation) public randomInflations;

    event NewInflation(
        RandomInflation indexed addr,
        uint256 indexed generation
    );
    event NewLockup(Lockup indexed addr, uint256 indexed generation);
    event NewCurrencyGovernance(
        CurrencyGovernance indexed addr,
        uint256 indexed generation
    );

    constructor(
        Policy _policy,
        CurrencyGovernance _borda,
        RandomInflation _inflation,
        Lockup _lockup,
        ECO _ecoAddr
    ) PolicedUtils(_policy) {
        require(
            address(_borda) != address(0),
            "Critical: do not set the _borda as the zero address"
        );
        require(
            address(_inflation) != address(0),
            "Critical: do not set the _inflation as the zero address"
        );
        require(
            address(_lockup) != address(0),
            "Critical: do not set the _lockup as the zero address"
        );
        require(
            address(_ecoAddr) != address(0),
            "Critical: do not set the _ecoAddr as the zero address"
        );
        bordaImpl = _borda;
        inflationImpl = _inflation;
        lockupImpl = _lockup;
        ecoToken = _ecoAddr;
    }

    function initialize(address _self) public override onlyConstruction {
        super.initialize(_self);

        // all of these values are better left mutable to allow for easier governance
        bordaImpl = CurrencyTimer(_self).bordaImpl();
        inflationImpl = CurrencyTimer(_self).inflationImpl();
        lockupImpl = CurrencyTimer(_self).lockupImpl();
    }

    function notifyGenerationIncrease() external override {
        uint256 _old = currentGeneration;
        uint256 _new = IGeneration(policyFor(ID_TIMED_POLICIES)).generation();
        require(_new != _old, "Generation has not increased");

        currentGeneration = _new;

        CurrencyGovernance bg = CurrencyGovernance(
            policyFor(ID_CURRENCY_GOVERNANCE)
        );

        uint256 _numberOfRecipients = 0;
        uint256 _randomInflationReward = 0;
        uint256 _lockupDuration = 0;
        uint256 _lockupInterest = 0;

        if (address(bg) != address(0)) {
            if (uint8(bg.currentStage()) < 3) {
                bg.updateStage();
            }
            if (uint8(bg.currentStage()) == 3) {
                bg.compute();
            }
            address winner = bg.winner();
            if (winner != address(0)) {
                (
                    _numberOfRecipients,
                    _randomInflationReward,
                    _lockupDuration,
                    _lockupInterest,
                    ,

                ) = bg.proposals(winner);
            }
        }

        {
            CurrencyGovernance _clone = CurrencyGovernance(bordaImpl.clone());
            policy.setPolicy(
                ID_CURRENCY_GOVERNANCE,
                address(_clone),
                ID_CURRENCY_TIMER
            );
            emit NewCurrencyGovernance(_clone, _new);
        }

        if (_numberOfRecipients > 0 && _randomInflationReward > 0) {
            // new inflation contract
            RandomInflation _clone = RandomInflation(inflationImpl.clone());
            ecoToken.mint(
                address(_clone),
                _numberOfRecipients * _randomInflationReward
            );
            _clone.startInflation(_numberOfRecipients, _randomInflationReward);
            emit NewInflation(_clone, _old);
            randomInflations[_old] = _clone;
        }

        if (_lockupDuration > 0 && _lockupInterest > 0) {
            Lockup _clone = Lockup(
                lockupImpl.clone(_lockupDuration, _lockupInterest)
            );
            emit NewLockup(_clone, _old);
            lockups[_old] = _clone;
            isLockup[address(_clone)] = true;
        }
    }

    function lockupWithdrawal(
        address _withdrawer,
        uint256 _amount,
        bool _penalty
    ) external {
        require(isLockup[msg.sender], "Not authorized to call this function");

        if (_penalty) {
            ecoToken.burn(_withdrawer, _amount);
        } else {
            ecoToken.mint(_withdrawer, _amount);
        }
    }
}