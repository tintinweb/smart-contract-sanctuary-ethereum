// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Governor } from "./Governor.sol";

contract PVFDGovernor is Governor {
    /// @notice Emmited when the base suppy is set
    event BaseSupplySet(uint16 baseSupply);

    /// @notice Emitted when the quorum bips is set
    event QuorumBipsSet(uint16 quorumBips);

    /// @notice The min setable value for base supply
    uint16 public constant MIN_BASE_SUPPLY = 1;

    /// @notice The max setable value for base supply
    uint16 public constant MAX_BASE_SUPPLY = 5000;

    /// @notice The min setable value for quorum bips
    uint16 public constant MIN_QUORUM_BIPS = 0;

    /// @notice The max setable value for quorum bips
    uint16 public constant MAX_QUORUM_BIPS = 5000;

    /// @notice The base supply for quorum calculation. Below this value, quorum
    ///    calculation will revert.
    uint16 public baseSupply;

    /// @notice The bips for quorum calculation.
    uint16 public quorumBips;

    constructor(
        address token_,
        uint256 votingPeriod_,
        uint256 votingDelay_,
        uint256 proposalThreshold_,
        uint16 baseSupply_,
        uint16 quorumBips_
    )
        Governor(
            "PVFD Governor",
            token_,
            votingPeriod_,
            votingDelay_,
            proposalThreshold_
        )
    {
        require(
            baseSupply_ >= MIN_BASE_SUPPLY && baseSupply_ <= MAX_BASE_SUPPLY,
            "PVFDGovernor::constructor: invalid base supply"
        );
        require(
            quorumBips_ >= MIN_QUORUM_BIPS && quorumBips_ <= MAX_QUORUM_BIPS,
            "PVFDGovernor::constructor: invalid quorum bips"
        );

        baseSupply = baseSupply_;
        quorumBips = quorumBips_;

        emit BaseSupplySet(baseSupply);
        emit QuorumBipsSet(quorumBips);
    }

    /**
     * @notice Provide the current quorum based on blockchain state
     * @dev Once reaching the baseSupply, the quorum is quorumBips * tokenSupply / 10000
     * @return quorum The quorum in votes
     */
    function quorumVotes() public view override returns (uint16 quorum) {
        uint128 tokenSupply = token.totalSupply();
        require(
            tokenSupply >= baseSupply,
            "PVFDGovernor::currentQuorum: total supply too low"
        );
        quorum = uint16((uint256(tokenSupply) * quorumBips) / 10000);
    }

    /**
     * @notice Sets the base supply for the quorum calculation
     * @param newBaseSupply The new base supply in votes
     */
    function _setBaseSupply(uint16 newBaseSupply) public {
        require(
            msg.sender == admin,
            "PVFDGovernor::_setBaseSupply: admin only"
        );
        require(
            newBaseSupply >= MIN_BASE_SUPPLY &&
                newBaseSupply <= MAX_BASE_SUPPLY,
            "PVFDGovernor::_setBaseSupply: invalid base quorum"
        );
        baseSupply = newBaseSupply;

        emit BaseSupplySet(baseSupply);
    }

    /**
     * @notice Sets the quorum bips for the quorum calculation
     * @dev Quorum bips is calulcated such that 100 BIPS = 1%. For example,
     *    for the quorum to be 5% of the total supply, set quorumBips to 500.
     * @param newQuorumBips The new quorum bips for the quorum calculation
     */
    function _setQuorumBips(uint16 newQuorumBips) public {
        require(
            msg.sender == admin,
            "PVFDGovernor::_setQuorumBips: admin only"
        );
        require(
            newQuorumBips >= MIN_QUORUM_BIPS &&
                newQuorumBips <= MAX_QUORUM_BIPS,
            "PVFDGovernor::_setQuorumBips: invalid quorum bips"
        );
        quorumBips = newQuorumBips;

        emit QuorumBipsSet(quorumBips);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { ERC721WrapperVotes } from "./ERC721WrapperVotes.sol";
import { TokenReceiver } from "./TokenReceiver.sol";
import { TimelockEvents } from "./TimelockEvents.sol";
import { GovernorEvents } from "./GovernorEvents.sol";
import { VoteType, Proposal, ProposalVote, ProposalState } from "./GovernorTypes.sol";

/**
 * @title Governor
 * @notice A generalized on chain governor contract optimized for NFT governance. Heavily influenced by Compound Governance.
 * @dev This contract is optimized for NFTs with a low supply--do not use it if the
 *      max supply of NFT will not fit in a uint16.
 * @author Arr00
 */
abstract contract Governor is GovernorEvents, TimelockEvents, TokenReceiver {
    /// MARK: Constants
    /// @notice The name of this contract
    string public name;

    /// @notice The minimum setable proposal threshold
    uint16 public constant MIN_PROPOSAL_THRESHOLD = 1; // 1 NFT

    /// @notice The maximum setable proposal threshold
    uint16 public constant MAX_PROPOSAL_THRESHOLD = 1000; // 1,000 NFTs

    /// @notice The minimum setable voting period
    uint40 public constant MIN_VOTING_PERIOD = 1 days;

    /// @notice The max setable voting period
    uint40 public constant MAX_VOTING_PERIOD = 2 weeks;

    /// @notice The min setable voting delay
    uint40 public constant MIN_VOTING_DELAY = 1 seconds;

    /// @notice The max setable voting delay
    uint40 public constant MAX_VOTING_DELAY = 1 weeks;

    /// @notice The maximum number of actions that can be included in a proposal
    uint8 public constant PROPOSAL_MAX_OPERATIONS = 10; // 10 actions

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 internal constant _DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 internal constant _BALLOT_TYPEHASH =
        keccak256("Ballot(uint256 proposalId,uint8 support)");

    /// @notice The EIP-712 DOMAIN_SEPARATOR used for signature validation
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    /// @notice The chainId which was used for calculating `_DOMAIN_SEPARATOR`
    uint256 internal immutable _CHAIN_ID;

    /// MARK: Timelock Constants
    /// @notice Grace period for timelock. Action executable until `ETA + TIMELOCK_GRACE_PERIOD`
    uint40 public constant TIMELOCK_GRACE_PERIOD = 1 weeks;

    /// @notice Delay for timelock. Action is executable after delay passes since queued.
    uint40 public constant TIMELOCK_DELAY = 2 days;

    /// MARK: Variables
    /// @notice Administrator for this contract. Admin has permission to set governance parameters and directly use timelock.
    address public admin;

    /// @notice Pending administrator for this contract
    address public pendingAdmin;

    /// @notice The delay before voting on a proposal may take place, once proposed, in seconds
    uint256 public votingDelay;

    /// @notice The duration of voting on a proposal, in seconds
    uint256 public votingPeriod;

    /// @notice The number of votes required in order to propose a proposal
    uint256 public proposalThreshold;

    /// @notice The total number of proposals
    uint256 public proposalCount;

    /// @notice The address of the governance token
    ERC721WrapperVotes public token;

    /// @notice Mapping of proposal ID to proposal structs
    mapping(uint256 => Proposal) public proposals;

    /// @notice Mapping of proposal ID to proposal vote structs
    mapping(uint256 => ProposalVote) public proposalVotes;

    /// @notice The latest proposal for each proposer
    mapping(address => uint256) public latestProposalIds;

    /// MARK: Timelock variables
    mapping(bytes32 => bool) public queuedTransactions;

    /*//////////////////////////////////////////////////////////////
                        Governance Functionality
    //////////////////////////////////////////////////////////////*/

    /**
     * @param name_ The name of the Governor
     * @param token_ The address of the governance token (max supply MUST fit in uint16)
     * @param votingPeriod_ The initial voting period in seconds
     * @param votingDelay_ The initial voting delay in seconds
     * @param proposalThreshold_ The initial proposal threshold
     */
    constructor(
        string memory name_,
        address token_,
        uint256 votingPeriod_,
        uint256 votingDelay_,
        uint256 proposalThreshold_
    ) {
        require(
            token_ != address(0),
            "Governor::constructor: invalid token address"
        );
        require(
            votingPeriod_ >= MIN_VOTING_PERIOD &&
                votingPeriod_ <= MAX_VOTING_PERIOD,
            "Governor::constructor: invalid voting period"
        );
        require(
            votingDelay_ >= MIN_VOTING_DELAY &&
                votingDelay_ <= MAX_VOTING_DELAY,
            "Governor::constructor: invalid voting delay"
        );
        require(
            proposalThreshold_ >= MIN_PROPOSAL_THRESHOLD &&
                proposalThreshold_ <= MAX_PROPOSAL_THRESHOLD,
            "Governor::constructor: invalid proposal threshold"
        );

        token = ERC721WrapperVotes(token_);
        votingPeriod = votingPeriod_;
        votingDelay = votingDelay_;
        proposalThreshold = proposalThreshold_;
        admin = address(this);
        name = name_;

        // Store DOMAIN_SEPARATOR as a constant
        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                _DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                block.chainid,
                address(this)
            )
        );
        _CHAIN_ID = block.chainid;
    }

    /**
     * @notice Function used to propose a new proposal. Sender must have delegates above the proposal threshold
     * @param targets Target addresses for proposal calls
     * @param values Eth values for proposal calls
     * @param signatures Function signatures for proposal calls
     * @param calldatas Calldatas for proposal calls
     * @param description String description of the proposal
     * @return proposalId Id of new proposal
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256) {
        require(
            calldatas.length == signatures.length,
            "Governor::propose: proposal function information arity mismatch"
        );

        return _propose(targets, values, signatures, calldatas, description);
    }

    /**
     * @notice Function used to propose a new proposal. Sender must have delegates above the proposal threshold
     * @param targets Target addresses for proposal calls
     * @param values Eth values for proposal calls
     * @param calldatas Calldatas for proposal calls
     * @param description String description of the proposal
     * @return proposalId Id of new proposal
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string calldata description
    ) external returns (uint256) {
        return
            _propose(targets, values, new string[](0), calldatas, description);
    }

    function _propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) private returns (uint256) {
        require(
            token.getPriorVotes(msg.sender, uint40(block.timestamp - 1)) >=
                proposalThreshold,
            "Governor::propose: proposer votes below proposal threshold"
        );
        require(
            targets.length == values.length &&
                targets.length == calldatas.length,
            "Governor::propose: proposal function information arity mismatch"
        );
        require(targets.length != 0, "Governor::propose: must provide actions");
        require(
            targets.length <= PROPOSAL_MAX_OPERATIONS,
            "Governor::propose: too many actions"
        );

        uint256 latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
            ProposalState proposersLatestProposalState = state(
                latestProposalId
            );
            require(
                proposersLatestProposalState != ProposalState.Active &&
                    proposersLatestProposalState != ProposalState.Pending,
                "Governor::propose: one live proposal per proposer"
            );
        }

        uint256 startTime = block.timestamp + votingDelay;
        uint256 endTime = startTime + votingPeriod;
        uint256 proposalId = ++proposalCount;

        emit ProposalCreated(
            proposalId,
            msg.sender,
            targets,
            values,
            signatures,
            calldatas,
            startTime,
            endTime,
            description
        );

        // Prepend signature hash to calldata if needed
        if (signatures.length != 0) {
            // Bring signataure into calldatas
            for (uint256 i = 0; i < calldatas.length; i++) {
                calldatas[i] = bytes(signatures[i]).length == 0
                    ? calldatas[i]
                    : abi.encodePacked(
                        bytes4(keccak256(bytes(signatures[i]))),
                        calldatas[i]
                    );
            }
        }

        // Signatures are not stored for efficiency
        proposals[proposalId] = Proposal({
            startTime: uint40(startTime), // time will be less than 2**40 until year 36812
            endTime: uint40(endTime),
            canceled: false,
            executed: false,
            quorum: quorumVotes(),
            proposer: msg.sender,
            targets: targets,
            values: values,
            calldatas: calldatas
        });
        latestProposalIds[msg.sender] = proposalId;

        return proposalId;
    }

    /**
     * @notice Get the current quorum based on blockchain state
     * @dev Quorum is wholely based on state at proposal creation time
     * @return The current quorum (uint16)
     */
    function quorumVotes() public view virtual returns (uint16);

    /**
     * @notice Cancels a proposal only if sender is the proposer, or proposer delegates dropped below proposal threshold
     * @param proposalId The id of the proposal to cancel
     */
    function cancel(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        ProposalVote storage proposalVote = proposalVotes[proposalId];

        require(
            state(proposal, proposalVote) != ProposalState.Executed,
            "Governor::cancel: cannot cancel executed proposal"
        );

        require(
            proposalId <= proposalCount && proposalId != 0,
            "Governor::cancel: invalid proposal id"
        );

        // Proposer can cancel
        if (msg.sender != proposal.proposer) {
            require(
                (token.getPriorVotes(
                    proposal.proposer,
                    uint40(block.timestamp - 1)
                ) < proposalThreshold),
                "Governor::cancel: proposer above threshold"
            );
        }

        proposal.canceled = true;

        emit ProposalCanceled(proposalId);
    }

    /**
     * @notice Gets actions of a proposal
     * @param proposalId the id of the proposal
     */
    function getActions(uint256 proposalId)
        external
        view
        returns (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas
        )
    {
        require(
            proposalCount >= proposalId && proposalId != 0,
            "Governor::getActions: invalid proposal id"
        );
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.calldatas);
    }

    /**
     * @notice Gets the state of a proposal
     * @dev Proposal quorum includes all votes (for, against, abstain)
     * @param proposalId The id of the proposal
     * @return Proposal state
     */
    function state(uint256 proposalId) public view returns (ProposalState) {
        require(
            proposalCount >= proposalId && proposalId != 0,
            "Governor::state: invalid proposal id"
        );
        Proposal storage proposal = proposals[proposalId];
        ProposalVote storage proposalVote = proposalVotes[proposalId];

        return state(proposal, proposalVote);
    }

    /**
     * @notice Private function that gets the state of a proposal.
     * @param proposal The proposal struct
     * @param proposalVote The proposal vote struct
     * @return Proposal state
     */
    function state(Proposal storage proposal, ProposalVote storage proposalVote)
        private
        view
        returns (ProposalState)
    {
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.timestamp <= proposal.startTime) {
            return ProposalState.Pending;
        } else if (block.timestamp <= proposal.endTime) {
            return ProposalState.Active;
        } else if (
            proposalVote.forVotes <= proposalVote.againstVotes ||
            (proposalVote.forVotes +
                proposalVote.againstVotes +
                proposalVote.abstainVotes) <
            proposal.quorum
        ) {
            return ProposalState.Defeated;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (
            block.timestamp >=
            proposal.endTime + TIMELOCK_DELAY + TIMELOCK_GRACE_PERIOD
        ) {
            return ProposalState.Expired;
        } else if (block.timestamp < proposal.endTime + TIMELOCK_DELAY) {
            return ProposalState.Queued;
        } else {
            return ProposalState.Executable;
        }
    }

    /**
     * @notice Cast a vote for a proposal
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote of enum VoteType. (0=against, 1=for, 2=abstain)
     */
    function castVote(uint256 proposalId, VoteType support) external {
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
        VoteType support,
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
        VoteType support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 structHash = keccak256(
            abi.encode(_BALLOT_TYPEHASH, proposalId, support)
        );
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _CHAIN_ID == block.chainid
                    ? _DOMAIN_SEPARATOR
                    : keccak256(
                        abi.encode(
                            _DOMAIN_TYPEHASH,
                            keccak256(bytes(name)),
                            block.chainid,
                            address(this)
                        )
                    ),
                structHash
            )
        );
        address signatory = ecrecover(digest, v, r, s);
        require(
            signatory != address(0),
            "Governor::castVoteBySig: invalid signature"
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
        VoteType support
    ) internal returns (uint16) {
        ProposalVote storage proposalVote = proposalVotes[proposalId];
        uint256 voterCommunityId = token.getOrCreateCommunityId(voter);

        uint256 wordIndex;
        uint256 bitIndex;
        uint256 upperVotesWord;
        uint208 lowerVotesWord;
        bool voted;

        // We are bitpacking 208 votes into the main `ProposalVote` slot.
        // Community id starts at 1. Have 208 bits in lowerVotesWord. Therefore,
        // we can fit communityIds 1-208 into lowerVotesWord.
        if (voterCommunityId < 209) {
            // bring lowerVotes into the stack
            lowerVotesWord = proposalVote.lowerVotes;
            // Bit flag at index voterCommunityId - 1 (since id starts at 1)
            // indicates if the voter has voted on this proposal.
            voted =
                lowerVotesWord & (1 << (voterCommunityId - 1)) ==
                (1 << (voterCommunityId - 1));
        } else {
            // Community id is too large to fit in lowerVotesWord. Therefore,
            // pull from the upperWords. Upper words indecies start at 209.
            wordIndex = (voterCommunityId - 209) / 256;
            // Get bit index within the word.
            bitIndex = (voterCommunityId - 209) % 256;
            upperVotesWord = proposalVote.upperVotes[wordIndex];
            // Bit flag at index bitIndex indicates if the voter has voted on this proposal.
            voted = upperVotesWord & (1 << bitIndex) == (1 << bitIndex);
        }

        Proposal storage proposal = proposals[proposalId];

        require(
            state(proposal, proposalVote) == ProposalState.Active,
            "Governor::castVoteInternal: voting is closed"
        );

        require(
            voted == false,
            "Governor::castVoteInternal: voter already voted"
        );

        uint16 votes = uint16(
            token.getPriorVotes(voter, uint40(proposal.startTime))
        );

        require(votes != 0, "Governor::castVoteInternal: voter has no votes");

        if (support == VoteType.Against) {
            proposalVote.againstVotes += votes;
        } else if (support == VoteType.For) {
            proposalVote.forVotes += votes;
        } else {
            // must be abstain
            proposalVote.abstainVotes += votes;
        }

        // Set has voted to be true
        if (voterCommunityId < 209) {
            // Using lower votes word.
            proposalVote.lowerVotes =
                lowerVotesWord |
                uint208(1 << (voterCommunityId - 1));
            // Community Id starts from one, store id 1 at index 0.
        } else {
            // Using up votes word.
            proposalVote.upperVotes[wordIndex] =
                upperVotesWord |
                (1 << bitIndex);
        }

        return votes;
    }

    /**
     * @notice Indicates if a voter has voted on a proposal
     * @param voter The voter to check
     * @param proposalId The id of the proposal to check
     * @return voted Bool indicated if voter has voted
     */
    function hasVoted(address voter, uint256 proposalId)
        external
        view
        returns (bool voted)
    {
        require(
            proposalId <= proposalCount && proposalId != 0,
            "Governor::hasVoted: invalid proposal id"
        );

        uint256 voterCommunityId = token.getCommunityId(voter);

        ProposalVote storage proposalVote = proposalVotes[proposalId];
        uint256 wordIndex;
        uint256 bitIndex;
        uint256 upperVotesWord;
        uint208 lowerVotesWord;

        // We are bitpacking 208 votes into the main `ProposalVote` slot.
        // Community id starts at 1. Have 208 bits in lowerVotesWord. Therefore,
        // we can fit communityIds 1-208 into lowerVotesWord.
        if (voterCommunityId < 209) {
            // bring lowerVotes into the stack
            lowerVotesWord = proposalVote.lowerVotes;
            // Bit flag at index voterCommunityId - 1 (since id starts at 1)
            // indicates if the voter has voted on this proposal.
            voted =
                lowerVotesWord & (1 << (voterCommunityId - 1)) ==
                (1 << (voterCommunityId - 1));
        } else {
            // Community id is too large to fit in lowerVotesWord. Therefore,
            // pull from the upperWords. Upper words indecies start at 209.
            wordIndex = (voterCommunityId - 209) / 256;
            // Get bit index within the word.
            bitIndex = (voterCommunityId - 209) % 256;
            upperVotesWord = proposalVote.upperVotes[wordIndex];
            // Bit flag at index bitIndex indicates if the voter has voted on this proposal.
            voted = upperVotesWord & (1 << bitIndex) == (1 << bitIndex);
        }
    }

    /**
     * @notice Executes a proposal. Execution calls come from this contract.
     * @param proposalId ID of the proposal to execute.
     */
    function execute(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        ProposalVote storage proposalVote = proposalVotes[proposalId];
        require(
            state(proposal, proposalVote) == ProposalState.Executable,
            "Governor::execute: proposal not executable"
        );
        proposal.executed = true;
        uint40 proposalEta = proposal.endTime + TIMELOCK_DELAY;

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            address target = proposal.targets[i];
            uint256 value = proposal.values[i];
            bytes memory callData = proposal.calldatas[i];

            (bool success, ) = target.call{ value: value }(callData);
            require(
                success,
                "Governor::execute: Transaction execution reverted."
            );
            emit ExecuteTransaction(0, target, value, callData, proposalEta);
        }
        emit ProposalExecuted(proposalId);
    }

    /*//////////////////////////////////////////////////////////////
                        Admin Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Admin function for setting the voting delay
     * @param newVotingDelay new voting delay, in blocks
     */
    function _setVotingDelay(uint256 newVotingDelay) external {
        require(msg.sender == admin, "Governor::_setVotingDelay: admin only");
        require(
            newVotingDelay >= MIN_VOTING_DELAY &&
                newVotingDelay <= MAX_VOTING_DELAY,
            "Governor::_setVotingDelay: invalid voting delay"
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
        require(msg.sender == admin, "Governor::_setVotingPeriod: admin only");
        require(
            newVotingPeriod >= MIN_VOTING_PERIOD &&
                newVotingPeriod <= MAX_VOTING_PERIOD,
            "Governor::_setVotingPeriod: invalid voting period"
        );
        uint256 oldVotingPeriod = votingPeriod;
        votingPeriod = newVotingPeriod;

        emit VotingPeriodSet(oldVotingPeriod, votingPeriod);
    }

    /**
     * @notice Admin function for setting the proposal threshold
     * @dev newProposalThreshold must be greater than the hardcoded min
     * @param newProposalThreshold new proposal threshold
     */
    function _setProposalThreshold(uint256 newProposalThreshold) external {
        require(
            msg.sender == admin,
            "Governor::_setProposalThreshold: admin only"
        );
        require(
            newProposalThreshold >= MIN_PROPOSAL_THRESHOLD &&
                newProposalThreshold <= MAX_PROPOSAL_THRESHOLD,
            "Governor::_setProposalThreshold: invalid proposal threshold"
        );
        uint256 oldProposalThreshold = proposalThreshold;
        proposalThreshold = newProposalThreshold;

        emit ProposalThresholdSet(oldProposalThreshold, proposalThreshold);
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     */
    function _setPendingAdmin(address newPendingAdmin) external {
        // Check caller = admin
        require(msg.sender == admin, "Governor::_setPendingAdmin: admin only");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     */
    function _acceptAdmin() external {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(
            msg.sender == pendingAdmin && msg.sender != address(0),
            "Governor::_acceptAdmin: pending admin only"
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

    /*//////////////////////////////////////////////////////////////
                    Backup Timelock Functionality
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Admin function to queue a timelock transaction
     * @param target The target of the transaction
     * @param value The value of the transaction
     * @param data The data of the transaction
     * @param eta The earliest time to allow execution
     * @return TX hash of the queued transaction
     */
    function _queueTransaction(
        address target,
        uint256 value,
        bytes memory data,
        uint256 eta
    ) public returns (bytes32) {
        require(
            msg.sender == admin,
            "Governor::queueTransaction: Call must come from admin"
        );
        require(
            eta >= block.timestamp + TIMELOCK_DELAY,
            "Governor::queueTransaction: Estimated execution time must satisfy delay"
        );

        bytes32 txHash = keccak256(abi.encode(target, value, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, data, eta);
        return txHash;
    }

    /**
     * @notice Admin function to cancel a queued timelock transaction
     * @param target The target of the transaction
     * @param value The value of the transaction
     * @param data The data of the transaction
     * @param eta The earliest time to allow execution
     */
    function _cancelTransaction(
        address target,
        uint256 value,
        bytes memory data,
        uint256 eta
    ) public {
        require(
            msg.sender == admin,
            "Governor::cancelTransaction: Call must come from admin"
        );

        bytes32 txHash = keccak256(abi.encode(target, value, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, data, eta);
    }

    /**
     * @notice Admin function to execute a queued timelock transaction
     * @param target The target of the transaction
     * @param value The value of the transaction
     * @param data The data of the transaction
     * @param eta The earliest time to allow execution
     */
    function _executeTransaction(
        address target,
        uint256 value,
        bytes memory data,
        uint256 eta
    ) public payable returns (bytes memory) {
        require(
            msg.sender == admin,
            "Governor::executeTransaction: Call must come from admin"
        );

        bytes32 txHash = keccak256(abi.encode(target, value, data, eta));
        require(
            queuedTransactions[txHash],
            "Governor::executeTransaction: Transaction hasn't been queued"
        );
        require(
            block.timestamp >= eta,
            "Governor::executeTransaction: Transaction hasn't surpassed time lock"
        );
        require(
            block.timestamp <= eta + TIMELOCK_GRACE_PERIOD,
            "Governor::executeTransaction: Transaction is stale"
        );

        queuedTransactions[txHash] = false;

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );
        require(
            success,
            "Governor::executeTransaction: Transaction execution reverted"
        );

        emit ExecuteTransaction(txHash, target, value, data, eta);

        return returnData;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @title TimelockEvents
 * @notice Events used by the integrated Timelock within Governor.
 * @author Arr00
 */
interface TimelockEvents {
    /**
     * @notice Emitted when a tx in the Timelock is canceled
     */
    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        bytes data,
        uint256 eta
    );

    /**
     * @notice Emitted when a tx in the Timelock is executed
     */
    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        bytes data,
        uint256 eta
    );

    /**
     * @notice Emiited when a tx is queued to the Timelock
     * @param txHash Hash of the queued tx
     * @param target Address which is called in the tx
     * @param value Eth value of the tx
     * @param data Calldata bytes of the tx
     * @param eta UNIX epoch at which tx is executable
     */
    event QueueTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        bytes data,
        uint256 eta
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { ERC721Wrapper } from "./ERC721Wrapper.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { TimeCheckpoints } from "./TimeCheckpoint.sol";

/**
 * @title ERC721WrapperVotes
 * @notice A wrapper token which checkpoints delegations on the wrapper token
 * @author Arr00
 */
abstract contract ERC721WrapperVotes is ERC721Wrapper {
    using TimeCheckpoints for TimeCheckpoints.History;

    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );
    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(
        address indexed delegate,
        uint128 previousBalance,
        uint128 newBalance
    );

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) private _delegation;
    mapping(address => TimeCheckpoints.History) private _delegateCheckpoints;

    constructor(
        string memory name_,
        string memory symbol_,
        IERC721Metadata rootToken_,
        uint16 maxSupply
    ) ERC721Wrapper(name_, symbol_, rootToken_, maxSupply) {}

    /**
     * @notice Called on token wrap, transfers voting units
     */
    function _onTokenWrap(address to, uint128 quantity) internal override {
        _transferVotingUnits(address(0), to, quantity);
    }

    /**
     * @notice Called on token unwrap, transfers voting units
     */
    function _onTokenUnwrap(address from, uint128 quantity) internal override {
        _transferVotingUnits(from, address(0), quantity);
    }

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) public view virtual returns (uint128) {
        return _delegateCheckpoints[account].latest();
    }

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPriorVotes(address account, uint40 time)
        public
        view
        virtual
        returns (uint128)
    {
        return _delegateCheckpoints[account].getAtTime(time);
    }

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegateOf(address account) public view virtual returns (address) {
        if (_delegation[account] == address(0)) {
            return account;
        }
        return _delegation[account];
    }

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual {
        _delegate(msg.sender, delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(
            block.timestamp <= expiry,
            "ERC721WrapperVotes::delegateBySig: signature expired"
        );
        bytes32 structHash = keccak256(
            abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", _domainSeparator(), structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(
            signatory != address(0),
            "ERC721WrapperVotes::delegateBySig: invalid signature"
        );
        require(
            nonce == nonces[signatory]++,
            "ERC721WrapperVotes::delegateBySig: invalid nonce"
        );
        _delegate(signatory, delegatee);
    }

    /**
     * @dev Delegate all of `account`'s voting units to `delegatee`.
     *
     * Emits events {DelegateChanged} and {DelegateVotesChanged}.
     */
    function _delegate(address account, address delegatee) internal virtual {
        require(
            delegatee != address(0),
            "ERC721WrapperVotes::_delegate: delegatee cannot be zero address"
        );

        address oldDelegate = delegateOf(account);
        _delegation[account] = delegatee;

        emit DelegateChanged(account, oldDelegate, delegatee);
        _moveDelegateVotes(oldDelegate, delegatee, userInfos[account].balance);
    }

    /**
     * @dev Transfers, mints, or burns voting units. To register a mint, `from` should be zero. To register a burn, `to`
     * should be zero.
     */
    function _transferVotingUnits(
        address from,
        address to,
        uint128 amount
    ) internal virtual {
        _moveDelegateVotes(delegateOf(from), delegateOf(to), amount);
    }

    /**
     * @dev Moves delegated votes from one delegate to another.
     */
    function _moveDelegateVotes(
        address from,
        address to,
        uint128 amount
    ) private {
        if (from != to && amount != 0) {
            if (from != address(0)) {
                uint128 oldValue = _delegateCheckpoints[from].push(
                    _subtract,
                    amount
                );
                emit DelegateVotesChanged(from, oldValue, oldValue - amount);
            }
            if (to != address(0)) {
                uint128 oldValue = _delegateCheckpoints[to].push(_add, amount);
                emit DelegateVotesChanged(to, oldValue, oldValue + amount);
            }
        }
    }

    function _add(uint128 a, uint128 b) private pure returns (uint128) {
        return a + b;
    }

    function _subtract(uint128 a, uint128 b) private pure returns (uint128) {
        return a - b;
    }

    /*//////////////////////////////////////////////////////////////
                        Disable All Transfers
    //////////////////////////////////////////////////////////////*/

    function transferFrom(
        address,
        address,
        uint256
    ) public pure override {
        revert("ERC721WrapperVotes::transferFrom: Transfer Disabled");
    }

    function safeTransferFrom(
        address,
        address,
        uint256
    ) external pure override {
        revert("ERC721WrapperVotes::safeTransferFrom: Transfer Disabled");
    }

    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public pure override {
        revert("ERC721WrapperVotes::safeTransferFrom: Transfer Disabled");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/**
 * @title TokenReceiver
 * @notice Abstract contract which enables receiving ETH, and safeTransfers of ERC721, ERC1155, and ERC1155 batch.
 * @author Arr00
 */
abstract contract TokenReceiver is IERC721Receiver, IERC1155Receiver {
    /// @notice Receive Ether
    receive() external payable {}

    /// @notice Receive ERC721
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure virtual returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /// @notice Receive ERC1155 batch
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure virtual returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    /// @notice Receive ERC1155
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure virtual returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        returns (bool)
    {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { VoteType } from "./GovernorTypes.sol";

/**
 * @title GovernorEvents
 * @notice Events emitted by Governor
 * @author Arr00
 */
interface GovernorEvents {
    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(
        uint256 id,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startTime,
        uint256 endTime,
        string description
    );

    /**
     * @notice An event emitted when a vote has been cast on a proposal
     * @param voter The address which casted a vote
     * @param proposalId The proposal id which was voted on
     * @param support Support value for the vote. 0=against, 1=for, 2=abstain
     * @param votes Number of votes which were cast by the voter
     * @param reason The reason given for the vote by the voter
     */
    event VoteCast(
        address indexed voter,
        uint256 proposalId,
        VoteType support,
        uint256 votes,
        string reason
    );

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint256 id);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint256 id);

    /// @notice An event emitted when the voting delay is set
    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);

    /// @notice An event emitted when the voting period is set
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);

    /// @notice Emitted when proposal threshold is set
    event ProposalThresholdSet(
        uint256 oldProposalThreshold,
        uint256 newProposalThreshold
    );

    /// @notice Emitted when pendingAdmin is changed
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /// @notice Emitted when pendingAdmin is accepted, which means admin is updated
    event NewAdmin(address oldAdmin, address newAdmin);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @notice Possible states that a proposal may be in
enum ProposalState {
    Pending,
    Active,
    Canceled,
    Defeated,
    SPACE, // State unused by Governor. For tally compatibility.
    Queued,
    Expired,
    Executed,
    Executable
}

/// @notice Support value for a vote
enum VoteType {
    Against,
    For,
    Abstain
}

/// @notice Struct for proposal information
struct Proposal {
    /// @notice The timestamp at which voting begins: holders must delegate their votes prior to this timestamp
    uint40 startTime;
    /// @notice The timestamp at which voting ends: votes must be cast prior to this timestamp
    uint40 endTime;
    /// @notice Flag marking whether the proposal has been canceled
    bool canceled;
    /// @notice Flag marking whether the proposal has been executed
    bool executed;
    /// @notice Value indicating the quorum for this proposal
    uint16 quorum; // Can not be greater than 100% of token supply
    /// @notice Creator of the proposal
    address proposer;
    /// @notice The ordered list of target addresses for calls to be made
    address[] targets;
    /// @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
    uint256[] values;
    /// @notice The ordered list of calldata to be passed to each call
    bytes[] calldatas;
}

/// @notice Struct for vote voting information
struct ProposalVote {
    /// @notice Against votes for the proposal
    uint16 againstVotes;
    /// @notice For votes for the proposal
    uint16 forVotes;
    /// @notice Abstain votes for the proposal
    uint16 abstainVotes;
    /// @notice First 208 has voted flags (bitpacked)
    uint208 lowerVotes;
    /// @notice Remaining has voted flags (bitpacked)
    mapping(uint256 => uint256) upperVotes;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { CommunityToken } from "./CommunityToken.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/**
 * @title ERC721Wrapper
 * @notice Implements a wrapper for the `CommunityToken` contract. Can wrap via `wrap` function or `safeTransferFrom` to the wrapper contract.
 * @author Arr00
 */
abstract contract ERC721Wrapper is CommunityToken, IERC721Receiver {
    bytes32 internal constant _WRAP_TYPEHASH =
        keccak256("Wrap(uint256 tokenId,uint256 nonce,uint256 expiry)");

    bytes32 internal constant _UNWRAP_TYPEHASH =
        keccak256("Unwrap(uint256 tokenId,uint256 nonce,uint256 expiry)");

    bytes32 internal constant _DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );

    /// @notice The EIP-712 DOMAIN_SEPARATOR used for signature validation
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    /// @notice The chainId which was used for calculating `DOMAIN_SEPARATOR`
    uint256 internal immutable _CHAIN_ID;

    mapping(address => uint256) public nonces;

    IERC721Metadata public immutable rootToken;

    constructor(
        string memory name_,
        string memory symbol_,
        IERC721Metadata rootToken_,
        uint16 maxSupply
    ) CommunityToken(name_, symbol_, maxSupply) {
        rootToken = rootToken_;

        // Setup EIP712

        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                _DOMAIN_TYPEHASH,
                keccak256(bytes(name_)),
                block.chainid,
                address(this)
            )
        );
        _CHAIN_ID = block.chainid;
    }

    /**
     * @notice Fetch the relevant domain seperator
     */
    function _domainSeparator() internal view returns (bytes32) {
        // If blockchain forked, need to get current domain separator
        return
            _CHAIN_ID == block.chainid
                ? _DOMAIN_SEPARATOR
                : keccak256(
                    abi.encode(
                        _DOMAIN_TYPEHASH,
                        keccak256(bytes(name)),
                        block.chainid,
                        address(this)
                    )
                );
    }

    /**
     * @notice Wrap an instance of `rootToken`. Must set approval first.
     * @param tokenId the tokenId of the token to wrap
     */
    function wrap(uint256 tokenId) external {
        _wrap(msg.sender, tokenId);
        _onTokenWrap(msg.sender, 1);
    }

    /**
     * @notice Wrap an instance of `rootToken` by sig. Must set approval first.
     */
    function wrapBySig(
        uint256 tokenId,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(
            block.timestamp <= expiry,
            "ERC721Wrapper::wrapBySig: signature expired"
        );

        bytes32 structHash = keccak256(
            abi.encode(_WRAP_TYPEHASH, tokenId, nonce, expiry)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", _domainSeparator(), structHash)
        );
        address signatory = ecrecover(digest, v, r, s);

        require(
            signatory != address(0),
            "ERC721Wrapper::wrapBySig: invalid signature"
        );
        require(
            nonce == nonces[signatory]++,
            "ERC721Wrapper::wrapBySig: invalid nonce"
        );

        _wrap(signatory, tokenId);
        _onTokenWrap(signatory, 1);
    }

    /**
     * @dev Transfer token in, then mint wrapped token to `from`
     */
    function _wrap(address from, uint256 tokenId) private {
        rootToken.transferFrom(from, address(this), tokenId);
        _mint(from, tokenId);
    }

    /**
     * @dev Wrap instances of `rootToken` when sent via `safeTransferFrom`. Send wrapped token to `from`.
     */
    function onERC721Received(
        address, /* operator */
        address from,
        uint256 tokenId,
        bytes calldata /* data */
    ) external virtual override returns (bytes4) {
        require(
            msg.sender == address(rootToken),
            "ERC721Wrapper::onERC721Received: NFT not root NFT"
        );
        _mint(from, tokenId);
        _onTokenWrap(from, 1);

        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @notice Unwrap token. Burns the wrapped token and returns the root token.
     * @param tokenId The tokenId of the wrapped token to unwrap
     */
    function unwrap(uint256 tokenId) external {
        _unwrap(msg.sender, tokenId);
        _onTokenUnwrap(msg.sender, 1);
    }

    /**
     * @notice Unwrap token by sig. Burns the wrapped token and returns the root token.
     */
    function unwrapBySig(
        uint256 tokenId,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(
            block.timestamp <= expiry,
            "ERC721Wrapper::unwrapBySig: signature expired"
        );

        bytes32 structHash = keccak256(
            abi.encode(_UNWRAP_TYPEHASH, tokenId, nonce, expiry)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", _domainSeparator(), structHash)
        );
        address signatory = ecrecover(digest, v, r, s);

        require(
            signatory != address(0),
            "ERC721Wrapper::unwrapBySig: invalid signature"
        );
        require(
            nonce == nonces[signatory]++,
            "ERC721Wrapper::unwrapBySig: invalid nonce"
        );

        _unwrap(signatory, tokenId);
        _onTokenUnwrap(signatory, 1);
    }

    /**
     * @dev Checks that token to wrap is owned by `from`. Burns wrapped token and transfers back underlying.
     */
    function _unwrap(address from, uint256 tokenId) private {
        require(
            from == ownerOf[tokenId],
            "ERC721Wrapper::_unwrap: UNAUTHORIZED"
        );

        _burn(tokenId);
        rootToken.transferFrom(address(this), from, tokenId);
    }

    /**
     * @notice Get URI for the token with token id `tokenId`.
     * @dev Forward URI from the root token
     */
    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        require(
            ownerOf[tokenId] != address(0),
            "ERC721Wrapper::tokenURI: URI query for nonexistent token"
        );
        return rootToken.tokenURI(tokenId);
    }

    /**
     * @dev Called on token wrap
     * @param to The address which the wrapped tokens are sent to
     * @param quantity The number of tokens wrapped
     */
    function _onTokenWrap(address to, uint128 quantity) internal virtual;

    /**
     * @dev Called on token unwrap
     * @param from The address from which holds the wrapped tokens prior to unwrap
     * @param quantity The number of tokens unwrapped
     */
    function _onTokenUnwrap(address from, uint128 quantity) internal virtual;

    /*//////////////////////////////////////////////////////////////
                        Helper Function
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Wrap many instances of `rootToken`
     * @param tokenIds Array of tokenIds to wrap
     */
    function wrapMany(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; i++) {
            _wrap(msg.sender, tokenIds[i]);
        }
        // Wrapping of max uint128 value will always run out of gas
        _onTokenWrap(msg.sender, uint128(tokenIds.length));
    }

    /**
     * @notice Unwrap many wrapped tokens
     * @param tokenIds Array of tokenIds to unwrap
     */
    function unwrapMany(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; i++) {
            _unwrap(msg.sender, tokenIds[i]);
        }
        // Wrapping of max uint128 value will always run out of gas
        _onTokenUnwrap(msg.sender, uint128(tokenIds.length));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @dev This library defines the `History` struct, for checkpointing values as they change at different points in
 * time, and later looking up past values by timestamp. See {Votes} as an example.
 *
 * To create a history of checkpoints define a variable type `Checkpoints.History` in your contract, and store a new
 * checkpoint for the current transaction timestamp using the {push} function.
 */
library TimeCheckpoints {
    struct Checkpoint {
        uint128 _timestamp;
        uint128 _value;
    }

    struct History {
        Checkpoint[] _checkpoints;
    }

    /**
     * @dev Returns the value in the latest checkpoint, or zero if there are no checkpoints.
     */
    function latest(History storage self) internal view returns (uint128) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : self._checkpoints[pos - 1]._value;
    }

    /**
     * @dev Returns the value at a given timestamp. If a checkpoint is not available at that timestamp, the closest one
     * before it is returned, or zero otherwise.
     */
    function getAtTime(History storage self, uint128 timestamp)
        internal
        view
        returns (uint128)
    {
        require(
            timestamp < block.timestamp,
            "Checkpoints: block not yet mined"
        );

        uint256 high = self._checkpoints.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = (low & high) + ((low ^ high) >> 1);
            if (self._checkpoints[mid]._timestamp > timestamp) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high == 0 ? 0 : self._checkpoints[high - 1]._value;
    }

    /**
     * @dev Pushes a value onto a History so that it is stored as the checkpoint for the current timestamp.
     */
    function push(History storage self, uint128 value)
        internal
        returns (uint128)
    {
        uint256 pos = self._checkpoints.length;
        uint128 old = latest(self);
        if (
            pos != 0 && self._checkpoints[pos - 1]._timestamp == block.timestamp
        ) {
            self._checkpoints[pos - 1]._value = value;
        } else {
            self._checkpoints.push(
                Checkpoint({
                    _timestamp: uint40(block.timestamp),
                    _value: value
                })
            );
        }

        return old;
    }

    /**
     * @dev Pushes a value onto a History, by updating the latest value using binary operation `op`. The new value will
     * be set to `op(latest, delta)`.
     *
     * Returns previous value and new value.
     */
    function push(
        History storage self,
        function(uint128, uint128) view returns (uint128) op,
        uint128 delta
    ) internal returns (uint128) {
        return push(self, op(latest(self), delta));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title CommunityToken
 * @notice Custom ERC-721 like token. Assigns a unique community ID to each holder of the NFT. Community ID is accessable via `getCommunityId`.
 * @author Arr00
 */
abstract contract CommunityToken {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    /// @notice per user storage
    struct UserInfo {
        uint128 communityId;
        uint128 balance;
    }
    /// @notice Global storage variables
    struct GlobalInfo {
        uint128 totalSupply;
        uint128 communityMembersCounter;
    }

    string public name;
    string public symbol;
    GlobalInfo internal globalInfo;
    mapping(address => UserInfo) internal userInfos;
    mapping(uint256 => address) public ownerOf;
    uint16 public immutable MAX_SUPPLY; /// @notice Max supply of the token

    /**
     * @param name_ Name to be set for the token
     * @param symbol_ Symbol to be set for the token
     * @param maxSupply The maximum supply for the token (max 65535)
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint16 maxSupply
    ) {
        name = name_;
        symbol = symbol_;
        MAX_SUPPLY = maxSupply;
    }

    /**
     * @notice Returns the balance of the given `owner`
     * @param owner The address of the `owner` to check balance of
     * @return uin128 The balance of the given `owner`
     */
    function balanceOf(address owner) public view returns (uint128) {
        return userInfos[owner].balance;
    }

    /**
     * @notice Returns total supply of the token
     * @return uint128 integer value of the total supply
     */
    function totalSupply() public view returns (uint128) {
        return globalInfo.totalSupply;
    }

    /**
     * @notice Transfers `id` token from `from` to `to`.
     * @dev Does not check that `to` can receive token, use `safeTransferFrom` for that functionality
     */
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(
            from == ownerOf[id],
            "CommunityToken::transferFrom: wrong from"
        );
        require(
            msg.sender == from,
            "CommunityToken::transferFrom: not authorized"
        );

        UserInfo storage toUserInfo = userInfos[to];

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't overflow
        unchecked {
            userInfos[from].balance--;

            toUserInfo.balance++;
        }

        if (toUserInfo.communityId == 0) {
            toUserInfo.communityId = ++globalInfo.communityMembersCounter;
        }

        ownerOf[id] = to;

        emit Transfer(from, to, id);
    }

    /**
     * @notice Transfers `id` token from `from` to `to` with a safety check
     * @dev If `to` is a contract, it must implement the `IERC721Receiver` contract to receive successfully
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external virtual {
        safeTransferFrom(from, to, id, "");
    }

    /**
     * @notice Transfers `id` token from `from` to `to` with a safety check and sends `data` to receiver (`to`)
     * @dev If `to` is a contract, it must implement the `IERC721Receiver` contract to receive successfully
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, tokenId);

        require(
            to.code.length == 0 ||
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    data
                ) ==
                IERC721Receiver.onERC721Received.selector,
            "CommunityToken::ERC721TokenReceiver: Unsafe"
        );
    }

    /**
     * @notice Mints `tokenId` and transfers it to `to`
     */
    function _mint(address to, uint256 tokenId) internal {
        require(
            to != address(0),
            "CommunityToken::_mint: mint to the zero address"
        );
        require(
            ownerOf[tokenId] == address(0),
            "CommunityToken::_mint: token already minted"
        );
        require(
            globalInfo.totalSupply < MAX_SUPPLY,
            "CommunityToken::_mint: max supply reached"
        );

        // Could overflow, mint will revert
        globalInfo.totalSupply++;

        UserInfo storage userInfo = userInfos[to];

        if (userInfo.communityId == 0) {
            userInfo.communityId = ++globalInfo.communityMembersCounter;
        }

        unchecked {
            // Can't overflow, total supply overflow first
            userInfo.balance++;
        }

        ownerOf[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @notice Destroys `tokenId`
     */
    function _burn(uint256 id) internal {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "CommunityToken::_burn: not minted");

        // Ownership check above ensures no underflow.
        unchecked {
            globalInfo.totalSupply--;
            userInfos[owner].balance--;
        }

        delete ownerOf[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                            Community ID Logic
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Returns the community id for the given `user`
     * @dev will revert for addresses not part of community. Returns non-zero user id for members of community
     */
    function getCommunityId(address user) public view returns (uint128) {
        require(
            userInfos[user].communityId != 0,
            "CommunityToken::getCommunityId: not part of community"
        );
        return userInfos[user].communityId;
    }

    /**
     * @notice Returns the community id for the given `user`. Assigns a new community id if user is not part of community
     * @dev will revert for zero address
     */
    function getOrCreateCommunityId(address user) public returns (uint128) {
        require(
            user != address(0),
            "CommunityToken::getOrCreateCommunityId: zero address"
        );
        uint128 communityId = userInfos[user].communityId;
        if (communityId == 0) {
            userInfos[user].communityId = communityId = ++globalInfo
                .communityMembersCounter;
        }
        return communityId;
    }

    /**
     * @notice Returns the total number of community members
     */
    function getTotalCommunityMembers() public view returns (uint128) {
        return globalInfo.communityMembersCounter;
    }

    /**
     * @notice Returns the URI for the given `tokenId`
     */
    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}