// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.9;

import "./ProposalFactoryStructures.sol";
import "./ExternalInterfaces.sol";
import "./Tally.sol";

contract CommunityProposalFactory is
    ProposalFactoryStructures,
    ProposalFactoryEvents,
    TallyBravoStyle
{
    /// @notice The name of this contract
    string public constant name = "GFX Community Proposal Factory";

    /// @notice The minimum settable proposal threshold
    uint public constant MIN_PROPOSAL_THRESHOLD = 1000000e18; // 1,000,000 VotingToken

    /// @notice The maximum settable proposal threshold
    uint public constant MAX_PROPOSAL_THRESHOLD = 10000000e18; //10,000,000 VotingToken

    /// @notice The minimum settable voting period
    uint public constant MIN_VOTING_PERIOD = 7200; // About 24 hours

    /// @notice The max settable voting period
    uint public constant MAX_VOTING_PERIOD = 100800; // About 2 weeks

    /// @notice The min settable voting delay
    uint public constant MIN_VOTING_DELAY = 1;

    /// @notice The max settable voting delay
    uint public constant MAX_VOTING_DELAY = 50400; // About 1 week

    /// @notice The grace period for proposal execution
    uint public constant GRACE_PERIOD = 1814400; //3 weeks

    /// @notice The maximum number of actions that can be included in a proposal
    uint public constant proposalMaxOperations = 10; // 10 actions

    // @notice string used to calculate eip712 domain typehash
    string public constant EIP712DomainSignature =
        "EIP712Domain(string name,uint256 chainId,address verifyingContract)";

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(abi.encodePacked(EIP712DomainSignature));

    // @notice string used to calculate ballot typehash
    string public constant BallotSignature =
        "Ballot(uint256 proposalId,uint8 support)";

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH =
        keccak256(abi.encodePacked(BallotSignature));

    /// @notice Initial proposal id set at become
    uint public initialProposalId = 0;

    /// @notice The total number of proposals
    uint public proposalCount;

    /// @notice The time in queue
    uint256 public delay;

    /// @notice The address of the governance token
    IVotingToken public votingToken;

    /// @notice The address of the governance contract
    IGovernorBravo public parent;

    /// @notice The official record of all proposals ever proposed
    mapping(uint => Proposal) public proposals;

    /// @notice The latest proposal for each proposer
    mapping(address => uint) public latestProposalIds;

    /// @notice The official record of queued transactions
    mapping(bytes32 => bool) public queuedTransactions;

    constructor(
        address votingToken_,
        uint votingPeriod_,
        uint votingDelay_,
        uint proposalThreshold_,
        address parent_,
        uint256 delay_
    ) {
        votingToken = IVotingToken(votingToken_);
        votingPeriod = votingPeriod_;
        votingDelay = votingDelay_;
        proposalThreshold = proposalThreshold_;
        parent = IGovernorBravo(parent_);
        delay = delay_;
        quorumVotes = 10000000e18; // 10,000,000 = 4% of VotingToken
    }

    /// @notice modifier to restrict access to only the governor
    modifier onlyGov() {
        require(_msgSender() == address(this), "Only Governor May Call");
        _;
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
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public override returns (uint) {
        // Allow addresses above proposal threshold
        require(
            votingToken.getPriorVotes(_msgSender(), sub256(block.number, 1)) >
                proposalThreshold,
            "GovernorBravo::propose: proposer votes below proposal threshold"
        );
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

        uint latestProposalId = latestProposalIds[_msgSender()];
        if (latestProposalId != 0) {
            ProposalState proposersLatestProposalState = state(
                latestProposalId
            );
            require(
                proposersLatestProposalState != ProposalState.Active,
                "GovernorBravo::propose: one live proposal per proposer, found an already active proposal"
            );
            require(
                proposersLatestProposalState != ProposalState.Pending,
                "GovernorBravo::propose: one live proposal per proposer, found an already pending proposal"
            );
        }

        uint startBlock = add256(block.number, votingDelay);
        uint endBlock = add256(startBlock, votingPeriod);

        proposalCount++;

        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = _msgSender();
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
        newProposal.description = description;
        newProposal.delay = delay;
        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(
            newProposal.id,
            _msgSender(),
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
    function queue(uint proposalId) external override {
        require(
            state(proposalId) == ProposalState.Succeeded,
            "can only be queued if succeeded"
        );
        Proposal storage proposal = proposals[proposalId];
        uint256 eta = getBlockTimestamp() + proposal.delay;
        bytes32 txHash = keccak256(
            abi.encode(
                proposal.targets,
                proposal.values,
                proposal.signatures,
                proposal.calldatas,
                eta,
                proposal.description
            )
        );
        require(!queuedTransactions[txHash], "proposal already queued");
        proposal.eta = eta;
        require(
            eta >= (getBlockTimestamp() + proposal.delay),
            "must satisfy delay."
        );
        queuedTransactions[txHash] = true;
        emit ProposalQueued(proposalId, eta);
    }

    /**
     * @notice Executes a queued proposal if eta has passed
     * @param proposalId The id of the proposal to execute
     */
    function execute(uint proposalId) external payable override {
        require(
            state(proposalId) == ProposalState.Queued,
            "can only be exec'd if queued"
        );
        Proposal storage proposal = proposals[proposalId];
        parent.propose(
            proposal.targets,
            proposal.values,
            proposal.signatures,
            proposal.calldatas,
            proposal.description
        );
        proposal.executed = true;

        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice Cancels a proposal only if sender is the proposer, or proposer delegates dropped below proposal threshold
     * @param proposalId The id of the proposal to cancel
     */
    function cancel(uint proposalId) external override {
        require(
            state(proposalId) != ProposalState.Executed,
            "cant cancel executed proposal"
        );

        Proposal storage proposal = proposals[proposalId];

        // Proposer can cancel
        if (_msgSender() != proposal.proposer) {
            require(
                (votingToken.getPriorVotes(
                    proposal.proposer,
                    (block.number - 1)
                ) < proposalThreshold),
                "cancel: proposer above threshold"
            );
        }

        proposal.canceled = true;
        bytes32 txHash = keccak256(
            abi.encode(
                proposal.targets,
                proposal.values,
                proposal.signatures,
                proposal.calldatas,
                proposal.eta,
                proposal.description
            )
        );
        queuedTransactions[txHash] = false;

        emit ProposalCanceled(proposalId);
    }

    /**
     * @notice Gets actions of a proposal
     * @param proposalId the id of the proposal
     * @return targets proposal targets
     * @return values proposal values
     * @return signatures proposal signatures
     * @return calldatas proposal calldatae
     */
    function getActions(
        uint proposalId
    )
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
    function getReceipt(
        uint proposalId,
        address voter
    ) external view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    /**
     * @notice Gets the state of a proposal
     * @param proposalId The id of the proposal
     * @return Proposal state
     */
    function state(
        uint proposalId
    ) public view override returns (ProposalState) {
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
        } else if (block.timestamp >= add256(proposal.eta, GRACE_PERIOD)) {
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
    function castVote(uint proposalId, uint8 support) external override {
        emit VoteCast(
            _msgSender(),
            proposalId,
            support,
            castVoteInternal(_msgSender(), proposalId, support),
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
        uint proposalId,
        uint8 support,
        string calldata reason
    ) external override {
        emit VoteCast(
            _msgSender(),
            proposalId,
            support,
            castVoteInternal(_msgSender(), proposalId, support),
            reason
        );
    }

    /**
     * @notice Cast a vote for a proposal by signature
     * @dev External function that accepts EIP-712 signatures for voting on proposals.
     */
    function castVoteBySig(
        uint proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
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
        uint proposalId,
        uint8 support
    ) internal returns (uint96) {
        require(
            state(proposalId) == ProposalState.Active,
            "GovernorBravo::castVoteInternal: voting is closed"
        );
        require(
            support <= 2,
            "GovernorBravo::castVoteInternal: invalid vote type"
        );
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(
            receipt.hasVoted == false,
            "GovernorBravo::castVoteInternal: voter already voted"
        );
        uint96 votes = votingToken.getPriorVotes(voter, proposal.startBlock);

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
    function _setVotingDelay(uint newVotingDelay) external onlyGov {
        require(
            newVotingDelay >= MIN_VOTING_DELAY &&
                newVotingDelay <= MAX_VOTING_DELAY,
            "GovernorBravo::_setVotingDelay: invalid voting delay"
        );
        uint oldVotingDelay = votingDelay;
        votingDelay = newVotingDelay;

        emit VotingDelaySet(oldVotingDelay, votingDelay);
    }

    /**
     * @notice Admin function for setting the voting period
     * @param newVotingPeriod new voting period, in blocks
     */
    function _setVotingPeriod(uint newVotingPeriod) external onlyGov {
        require(
            newVotingPeriod >= MIN_VOTING_PERIOD &&
                newVotingPeriod <= MAX_VOTING_PERIOD,
            "GovernorBravo::_setVotingPeriod: invalid voting period"
        );
        uint oldVotingPeriod = votingPeriod;
        votingPeriod = newVotingPeriod;

        emit VotingPeriodSet(oldVotingPeriod, votingPeriod);
    }

    /**
     * @notice Admin function for setting the proposal threshold
     * @dev newProposalThreshold must be greater than the hardcoded min
     * @param newProposalThreshold new proposal threshold
     */
    function _setProposalThreshold(uint newProposalThreshold) external onlyGov {
        require(
            newProposalThreshold >= MIN_PROPOSAL_THRESHOLD &&
                newProposalThreshold <= MAX_PROPOSAL_THRESHOLD,
            "GovernorBravo::_setProposalThreshold: invalid proposal threshold"
        );
        uint oldProposalThreshold = proposalThreshold;
        proposalThreshold = newProposalThreshold;

        emit ProposalThresholdSet(oldProposalThreshold, proposalThreshold);
    }

    /**
     * @notice Governance function for setting the quorum
     * @param newQuorumVotes new proposal quorum
     */
    function _setQuorumVotes(uint256 newQuorumVotes) external onlyGov {
        uint256 oldQuorumVotes = quorumVotes;
        quorumVotes = newQuorumVotes;

        emit QuorumNumeratorUpdated(oldQuorumVotes, quorumVotes);
    }

    function add256(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }

    function getChainIdInternal() internal view returns (uint) {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    function getBlockTimestamp() internal view returns (uint256) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.9;

interface IVotingToken {
    function getPriorVotes(
        address account,
        uint blockNumber
    ) external view returns (uint96);

    function getCurrentVotes(address account) external view returns (uint96);

    function delegate(address account) external;

    function balanceOf(address account) external view returns (uint256);
}

interface IGovernorBravo {
    struct Proposal {
        uint256 id;
        address proposer;
        uint256 eta;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        bool canceled;
        bool executed;
    }

    function propose(
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint);

    function queue(uint256 proposalId) external;

    function execute(uint256 proposalId) external;

    function castVote(uint proposalId, uint8 support) external;

    function votingDelay() external view returns (uint256);

    function votingPeriod() external view returns (uint256);

    function proposalCount() external view returns (uint256);

    function proposals(
        uint256 proposalId
    ) external view returns (Proposal calldata);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.9;

contract ProposalFactoryEvents {
    /// @notice Emitted when implementation is changed
    event NewImplementation(
        address oldImplementation,
        address newImplementation
    );
    /// @notice Emitted when pendingAdmin is changed
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    /// @notice Emitted when pendingAdmin is accepted, which means admin is updated
    event NewAdmin(address oldAdmin, address newAdmin);
}

contract ProposalFactoryStructures {
    struct Proposal {
        uint id; ///  Unique id for looking up a proposal
        address proposer; ///  Creator of the proposal
        uint eta; ///  The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint startBlock; ///  The block at which voting begins: holders must delegate their votes prior to this block
        uint endBlock; ///  The block at which voting ends: votes must be cast prior to this block
        uint forVotes; ///  Current number of votes in favor of this proposal
        uint againstVotes; ///  Current number of votes in opposition to this proposal
        uint abstainVotes; ///  Current number of votes for abstaining for this proposal
        bool canceled; ///  Flag marking whether the proposal has been canceled
        bool executed; ///  Flag marking whether the proposal has been executed
        uint256 delay; ///  The time in queue
        address[] targets; ///  the ordered list of target addresses for calls to be made
        uint[] values; ///  The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        string[] signatures; ///  The ordered list of function signatures to be called
        bytes[] calldatas; ///  The ordered list of calldata to be passed to each call
        string description; ///  Description
        mapping(address => Receipt) receipts; ///  Receipts of ballots for the entire set of voters
    }
    ///  Ballot receipt record for a voter
    struct Receipt {
        bool hasVoted; ///  Whether or not a vote has been cast
        uint8 support; ///  Whether or not the voter supports the proposal or abstains
        uint96 votes; ///  The number of votes the voter had, which were cast
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

/// @notice this is the compound-bravo style compatibility interface
/// see: https://docs.tally.xyz/user-guides/tally-contract-compatibility/compound-bravo-style
abstract contract TallyBravoStyle {
    /*
       State Variables
    */

    /// @notice The delay before voting on a proposal may take place, once proposed, in blocks
    uint public votingDelay;
    /// @notice The duration of voting on a proposal, in blocks
    uint public votingPeriod;
    /// @notice The number of votes required in order for a voter to become a proposer
    uint public proposalThreshold;
    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    uint public quorumVotes;

    /*
        Enum Definition
    */
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
    /*
       Events
    */
    event ProposalCreated(
        uint id,
        address proposer,
        address[] targets,
        uint[] values,
        string[] signatures,
        bytes[] calldatas,
        uint startBlock,
        uint endBlock,
        string description
    );
    event VoteCast(
        address indexed voter,
        uint proposalId,
        uint8 support,
        uint votes,
        string reason
    );
    event ProposalCanceled(uint id);
    event ProposalQueued(uint id, uint eta);
    event ProposalExecuted(uint id);
    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);
    event ProposalThresholdSet(
        uint256 oldProposalThreshold,
        uint256 newProposalThreshold
    );
    event QuorumNumeratorUpdated(
        uint256 oldQuorumNumerator,
        uint256 newQuorumNumerator
    );

    /*
       Functions to implement
    */
    function castVote(uint proposalId, uint8 support) external virtual;

    function castVoteWithReason(
        uint proposalId,
        uint8 support,
        string calldata reason
    ) external virtual;

    function castVoteBySig(
        uint proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual;

    function state(uint proposalId) public view virtual returns (ProposalState);

    function propose(
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public virtual returns (uint);

    function execute(uint proposalId) external payable virtual;

    function queue(uint proposalId) external virtual;

    function cancel(uint proposalId) external virtual;
}