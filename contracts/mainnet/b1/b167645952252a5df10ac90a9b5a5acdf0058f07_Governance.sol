// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 _______  _______  _______  _        _        _______  _          _______           _        _        _______
(  ____ \(  ____ )(  ___  )( (    /|| \    /\(  ____ \( (    /|  (  ____ )|\     /|( (    /|| \    /\(  ____ \
| (    \/| (    )|| (   ) ||  \  ( ||  \  / /| (    \/|  \  ( |  | (    )|| )   ( ||  \  ( ||  \  / /| (    \/
| (__    | (____)|| (___) ||   \ | ||  (_/ / | (__    |   \ | |  | (____)|| |   | ||   \ | ||  (_/ / | (_____
|  __)   |     __)|  ___  || (\ \) ||   _ (  |  __)   | (\ \) |  |  _____)| |   | || (\ \) ||   _ (  (_____  )
| (      | (\ (   | (   ) || | \   ||  ( \ \ | (      | | \   |  | (      | |   | || | \   ||  ( \ \       ) |
| )      | ) \ \__| )   ( || )  \  ||  /  \ \| (____/\| )  \  |  | )      | (___) || )  \  ||  /  \ \/\____) |
|/       |/   \__/|/     \||/    )_)|_/    \/(_______/|/    )_)  |/       (_______)|/    )_)|_/    \/\_______)

*/

import "./interfaces/IGovernance.sol";
import "./interfaces/IExecutor.sol";
import "./interfaces/IStaking.sol";
import "./utils/Admin.sol";
import "./utils/Refundable.sol";
import "./utils/SafeCast.sol";

/// @title FrankenDAO Governance
/// @author Zach Obront & Zakk Fleischmann
/// @notice Users use their staked FrankenPunks and FrankenMonsters to make & vote on governance proposals
/** @dev Loosely forked from NounsDAOLogicV1.sol (0xa43afe317985726e4e194eb061af77fbcb43f944) with following major modifications:
- add gas refunding for voting and creating proposals
- pack proposal struct into fewer storage slots 
- track votes, proposals created, and proposal passed by user for community score calculation
- track votes, proposals created, and proposal passed across all users counting towards community voting power
- removed tempProposal from the proposal creation process
- added a verification step for new proposals to confirm they passed Snapshot pre-governance
- adjusted roles and permissions
- added an array to track Active Proposals and a clear() function to remove them 
- removed the ability to pass a reason along with a vote, and to vote by EIP-712 signature
- allow the contract to receive Ether (for gas refunds)
 */
contract Governance is IGovernance, Admin, Refundable {
    using SafeCast for uint;

    /// @notice The name of this contract
    string public constant name = "FrankenDAO";

    /// @notice The address of staked the Franken tokens
    IStaking public staking;

    //////////////////////////
    //// Voting Constants ////
    //////////////////////////

    /// @notice The min setable voting delay 
    /// @dev votingDelay is the time between a proposal being created and voting opening
    uint256 public constant MIN_VOTING_DELAY = 1 hours;

    /// @notice The max setable voting delay
    /// @dev votingDelay is the time between a proposal being created and voting opening
    uint256 public constant MAX_VOTING_DELAY = 1 weeks;

    /// @notice The minimum setable voting period 
    /// @dev votingPeriod is the time that voting is open for
    uint256 public constant MIN_VOTING_PERIOD = 1 days; 

    /// @notice The max setable voting period 
    /// @dev votingPeriod is the time that voting is open for
    uint256 public constant MAX_VOTING_PERIOD = 14 days;

    /// @notice The minimum setable proposal threshold
    /// @dev proposalThreshold is the minimum percentage of votes that a user must have to create a proposal
    uint256 public constant MIN_PROPOSAL_THRESHOLD_BPS = 1; // 1 basis point or 0.01%

    /// @notice The maximum setable proposal threshold
    /// @dev proposalThreshold is the minimum percentage of votes that a user must have to create a proposal
    uint256 public constant MAX_PROPOSAL_THRESHOLD_BPS = 1_000; // 1,000 basis points or 10%

    /// @notice The minimum setable quorum votes basis points
    /// @dev quorumVotesBPS is the minimum percentage of YES votes that must be cast on a proposal for it to succeed
    uint256 public constant MIN_QUORUM_VOTES_BPS = 200; // 200 basis points or 2%

    /// @notice The maximum setable quorum votes basis points
    /// @dev quorumVotesBPS is the minimum percentage of YES votes that must be cast on a proposal for it to succeed
    uint256 public constant MAX_QUORUM_VOTES_BPS = 2_000; // 2,000 basis points or 20%

    /// @notice The maximum number of actions that can be included in a proposal
    uint256 public constant PROPOSAL_MAX_OPERATIONS = 10; // 10 actions

    ///////////////////////////
    //// Voting Parameters ////
    ///////////////////////////

    /// @notice The delay before voting on a proposal may take place, once proposed, in seconds.
    uint256 public votingDelay;

    /// @notice The duration of voting on a proposal, in seconds.
    uint256 public votingPeriod;

    /// @notice The basis point number of votes required in order for a voter to become a proposer. 
    uint256 public proposalThresholdBPS;

    /// @notice The basis point number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed. 
    uint256 public quorumVotesBPS;

    /// @notice Whether or not gas is refunded for casting votes.
    bool public votingRefund;

    /// @notice Whether or not gas is refunded for submitting proposals.
    bool public proposalRefund;

    //////////////////
    //// Proposal ////
    //////////////////

    /// @notice The total number of proposals
    uint256 public proposalCount;

    /// @notice The official record of all proposals ever proposed
    mapping(uint256 => Proposal) public proposals;

    /// @notice Propsals that are currently verified, but have not been canceled, vetoed, or queued
    /** @dev Admins (or anyone else) will regularly clear out proposals that have been defeated 
             by calling clear() to keep gas costs of iterating through this array low  */
    uint256[] public activeProposals;

    /// @notice The latest proposal for each proposer
    mapping(address => uint256) public latestProposalIds;

    /// @notice Users who have been banned from creating proposals
    mapping(address => bool) public bannedProposers;

    /// @notice The number of votes, verified proposals, and passed proposals for each user
    mapping(address => CommunityScoreData) public userCommunityScoreData;

    /// @notice The total number of votes, verified proposals, and passed proposals actively contributing to total community voting power
    /** @dev Users only get community voting power if they currently have token voting power (ie have staked, undelegated tokens 
            or are delegated to). These totals adjust as users stake, undelegate, or delegate to ensure they only reflect the current 
            total community score. Therefore, these totals will not equal the sum of the totals in the userCommunityScoreData mapping. */
    /// @dev This is used to calculate the total voting power of the entire system, so that we can calculate thresholds from BPS.
    CommunityScoreData public totalCommunityScoreData;


    /// @notice Initialize the contract during proxy setup
    /// @param _executor The address of the FrankenDAO Executor
    /// @param _staking The address of the staked FrankenPunks tokens
    /// @param _founders The address of the founder multisig
    /// @param _council The address of the council multisig
    /// @param _votingPeriod The initial voting period (time voting is open for)
    /// @param _votingDelay The initial voting delay (time between proposal creation and voting opening)
    /// @param _proposalThresholdBPS The initial threshold to create a proposal (in basis points)
    /// @param _quorumVotesBPS The initial threshold of quorum votes needed (in basis points)
    function initialize(
        address _staking,
        address _executor,
        address _founders,
        address _council,
        uint256 _votingPeriod,
        uint256 _votingDelay,
        uint256 _proposalThresholdBPS,
        uint256 _quorumVotesBPS
    ) public {
        // Check whether this contract has already been initialized.
        if (address(executor) != address(0)) revert AlreadyInitialized();
        if (address(_executor) == address(0)) revert ZeroAddress();

        if (_votingDelay < MIN_VOTING_DELAY || _votingDelay > MAX_VOTING_DELAY) revert ParameterOutOfBounds();
        if (_votingPeriod < MIN_VOTING_PERIOD || _votingPeriod > MAX_VOTING_PERIOD) revert ParameterOutOfBounds();
        if (_proposalThresholdBPS < MIN_PROPOSAL_THRESHOLD_BPS || _proposalThresholdBPS > MAX_PROPOSAL_THRESHOLD_BPS) revert ParameterOutOfBounds();
        if (_quorumVotesBPS < MIN_QUORUM_VOTES_BPS || _quorumVotesBPS > MAX_QUORUM_VOTES_BPS) revert ParameterOutOfBounds();

        executor = IExecutor(_executor);
        founders = _founders;
        council = _council;
        staking = IStaking(_staking);

        votingRefund = true;
        proposalRefund = true;

        emit VotingDelaySet(0, votingDelay = _votingDelay);
        emit VotingPeriodSet(0, votingPeriod = _votingPeriod);
        emit ProposalThresholdBPSSet(0, proposalThresholdBPS = _proposalThresholdBPS);
        emit QuorumVotesBPSSet(0, quorumVotesBPS = _quorumVotesBPS);
    }

    ///////////////////
    //// Modifiers ////
    ///////////////////

    modifier cancelable(uint _proposalId) {
        Proposal storage proposal = proposals[_proposalId];

        if (
            // Proposals that are executed, canceled, or vetoed have already been removed from
            // ActiveProposals array and the Executor queue.
            state(_proposalId) == ProposalState.Executed ||
            state(_proposalId) == ProposalState.Canceled ||
            state(_proposalId) == ProposalState.Vetoed ||

            // Proposals that are Defeated or Expired should be cleared instead, to preserve their state.
            state(_proposalId) == ProposalState.Defeated ||
            state(_proposalId) == ProposalState.Expired
        ) revert InvalidStatus();

        _;
    }

    ///////////////
    //// Views ////
    ///////////////

    /// @notice Gets actions of a proposal
    /// @param _proposalId the id of the proposal
    /// @return targets Array of addresses that the Executor will call if the proposal passes
    /// @return values Array of values (i.e. msg.value) that Executor will call if the proposal passes
    /// @return signatures Array of function signatures that the Executor will call if the proposal passes
    /// @return calldatas Array of calldata that the Executor will call if the proposal passes
    function getActions(uint256 _proposalId) external view returns (
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
    ) {
        Proposal storage p = proposals[_proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    /// @notice Gets the data of a proposal
    /// @param _proposalId the id of the proposal
    /// @return id the id of the proposal
    /// @return proposer the address of the proposer
    /// @return quorumVotes the number of YES votes needed for the proposal to pass
    function getProposalData(uint256 _proposalId) public view returns (uint256, address, uint256) {
        Proposal storage p = proposals[_proposalId];
        return (p.id, p.proposer, p.quorumVotes);
    }

    /// @notice Gets the status of a proposal
    /// @param _proposalId the id of the proposal
    /// @return verified has the team verified the proposal?
    /// @return canceled has the proposal been canceled?
    /// @return vetoed has the proposal been vetoed?
    /// @return executed has the proposal been executed?
    function getProposalStatus(uint256 _proposalId) public view returns (bool, bool, bool, bool) {
        Proposal storage p = proposals[_proposalId];
        return (p.verified, p.canceled, p.vetoed, p.executed);
    }

    /// @notice Gets the voting status of a proposal
    /// @param _proposalId the id of the proposal
    /// @return forVotes the number of votes in favor of the proposal
    /// @return againstVotes the number of votes against the proposal
    /// @return abstainVotes the number of abstain votes
    function getProposalVotes(uint256 _proposalId) public view returns (uint256, uint256, uint256) {
        Proposal storage p = proposals[_proposalId];
        return (p.forVotes, p.againstVotes, p.abstainVotes);
    }

    /// @notice Gets a list of all Active Proposals (created, but not queued, canceled, vetoed, or cleared)
    /// @return activeProposals the list of proposal ids
    function getActiveProposals() public view returns (uint256[] memory) {
        return activeProposals;
    }

    
    /// @notice Gets the receipt for a voter on a given proposal
    /// @param _proposalId the id of proposal
    /// @param _voter The address of the voter
    /// @return The voting receipt (hasVoted, support, votes)
    function getReceipt(uint256 _proposalId, address _voter) external view returns (Receipt memory) {
        return proposals[_proposalId].receipts[_voter];
    }

    /// @notice Gets the state of a proposal
    /// @param _proposalId The id of the proposal
    /// @return Proposal state
    function state(uint256 _proposalId) public view returns (ProposalState) {
        if (_proposalId > proposalCount) revert InvalidId();
        Proposal storage proposal = proposals[_proposalId];

        // If the proposal has been vetoed, it should always return Vetoed.
        if (proposal.vetoed) {
            return ProposalState.Vetoed;

        // If the proposal isn't verified by the time it ends, it's Canceled.
        } else if (proposal.canceled || (!proposal.verified && block.timestamp > proposal.endTime)) {
            return ProposalState.Canceled;

        // If it's unverified at any time before end time, or if it is verified but is before start time, it's Pending.
        }  else if (block.timestamp < proposal.startTime || !proposal.verified) {
            return ProposalState.Pending;
        
        // If it's verified and after start time but before end time, it's Active.
        } else if (block.timestamp <= proposal.endTime) {
            return ProposalState.Active;

        // If this is the case, it means it was verified and it's after the end time. 
        // The YES votes must be greater than the NO votes, and greater than or equal to quorumVotes to pass.
        // If it doesn't meet these criteria, it's Defeated.
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < proposal.quorumVotes) {
            return ProposalState.Defeated;

        // If this is the case, the proposal passed, but it hasn't been queued yet, so it's Succeeded.
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;

        // execute() has been called, so the transaction has been run and the proposal is Executed.
        } else if (proposal.executed) {
            return ProposalState.Executed;

        // If execute() hasn't been run and we're GRACE_PERIOD after the eta, it's Expired.
        } else if (block.timestamp >= proposal.eta + executor.GRACE_PERIOD()) {
            return ProposalState.Expired;
        
        // Otherwise, it's queued, unexecuted, and within the GRACE_PERIOD, so we're Queued.
        } else {
            return ProposalState.Queued;
        }
    }

    /// @notice Current proposal threshold based on the voting power of the system
    /// @dev This incorporates the totals of both token voting power and community voting power
    function proposalThreshold() public view returns (uint256) {
        return bps2Uint(proposalThresholdBPS, staking.getTotalVotingPower());
    }

    /// @notice Current quorum threshold based on the voting power of the system
    /// @dev This incorporates the totals of both token voting power and community voting power
    function quorumVotes() public view returns (uint256) {
        return bps2Uint(quorumVotesBPS, staking.getTotalVotingPower());
    }

    ///////////////////
    //// Proposals ////
    ///////////////////

    /// @notice Function used to propose a new proposal
    /// @param _targets Target addresses for proposal calls
    /// @param _values Eth values for proposal calls
    /// @param _signatures Function signatures for proposal calls
    /// @param _calldatas Calldatas for proposal calls
    /// @param _description String description of the proposal
    /// @return Proposal id of new proposal
    function propose(
        address[] memory _targets,
        uint256[] memory _values,
        string[] memory _signatures,
        bytes[] memory _calldatas,
        string memory _description
    ) public returns (uint256) {
        uint proposalId;

        // Refunds gas if proposalRefund is true
        if (proposalRefund) {
            uint256 startGas = gasleft();
            proposalId = _propose(_targets, _values, _signatures, _calldatas, _description);
            _refundGas(startGas);
        } else {
            proposalId = _propose(_targets, _values, _signatures, _calldatas, _description);
        }
        return proposalId;
    }

    /// @notice Function used to propose a new proposal
    /// @param _targets Target addresses for proposal calls
    /// @param _values Eth values for proposal calls
    /// @param _signatures Function signatures for proposal calls
    /// @param _calldatas Calldatas for proposal calls
    /// @param _description String description of the proposal
    /// @return Proposal id of new proposal
    function _propose(
        address[] memory _targets,
        uint256[] memory _values,
        string[] memory _signatures,
        bytes[] memory _calldatas,
        string memory _description
    ) internal returns (uint256) {
        // Confirm the user hasn't been banned
        if (bannedProposers[msg.sender]) revert NotAuthorized();

        // Confirm the proposer meets the proposalThreshold
        uint votesNeededToPropose = proposalThreshold();
        if (staking.getVotes(msg.sender) < votesNeededToPropose) revert NotEligible();

        // Validate the proposal's actions
        if (_targets.length == 0) revert InvalidProposal();
        if (_targets.length > PROPOSAL_MAX_OPERATIONS) revert InvalidProposal();
        if (
            _targets.length != _values.length ||
            _targets.length != _signatures.length ||
            _targets.length != _calldatas.length
        ) revert InvalidProposal();

        // Ensure the proposer doesn't already have an active or pending proposal
        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
            ProposalState proposersLatestProposalState = state(latestProposalId);
            if (
                proposersLatestProposalState == ProposalState.Active || 
                proposersLatestProposalState == ProposalState.Pending
            ) revert NotEligible();
        }
        
        // Create a new proposal in storage, and fill it with the correct data
        uint newProposalId = ++proposalCount;
        Proposal storage newProposal = proposals[newProposalId];

        // All non-array values in the Proposal struct are packed into 2 storage slots:
        // Slot 1: id (96) + proposer (address, 160)
        // Slot 2: quorumVotes (24), eta (32), startTime (32), endTime (32), forVotes (24), 
        //         againstVotes (24), canceled (8), vetoed (8), executed (8), verified (8)
        
        // All times are stored as uint32s, which takes us through the year 2106 (we can upgrade then :))
        // All votes are stored as uint24s with lots of buffer, since max votes in system is < 4 million
        // (10k punks * (max 50 token VP + max ~100 community VP) + 10k monsters * (max 25 token VP + max ~100 community VP))
        
        newProposal.id = newProposalId.toUint96();
        newProposal.proposer = msg.sender;
        newProposal.targets = _targets;
        newProposal.values = _values;
        newProposal.signatures = _signatures;
        newProposal.calldatas = _calldatas;
        newProposal.quorumVotes = quorumVotes().toUint24();
        newProposal.startTime = (block.timestamp + votingDelay).toUint32();
        newProposal.endTime = (block.timestamp + votingDelay + votingPeriod).toUint32();
        
        // Other values are set automatically:
        //  - forVotes, againstVotes, and abstainVotes = 0
        //  - verified, canceled, executed, and vetoed = false
        //  - eta = 0

        latestProposalIds[newProposal.proposer] = newProposalId;
        activeProposals.push(newProposalId);

        emit ProposalCreated(
            newProposalId,
            msg.sender,
            _targets,
            _values,
            _signatures,
            _calldatas,
            newProposal.startTime,
            newProposal.endTime,
            newProposal.quorumVotes,
            _description
        );

        return newProposalId;
    }

    /// @notice Function for verifying a proposal
    /// @param _proposalId Id of the proposal to verify
    /// @dev This is intended to confirm that the proposal got through Snapshot pre-governance
    /// @dev This doesn't add any additional centralization risk, as the team already has veto power
    function verifyProposal(uint _proposalId) external onlyVerifierOrAdmins {
        // Can only verify proposals that are currently in the Pending state
        if (state(_proposalId) != ProposalState.Pending) revert InvalidStatus();

        Proposal storage proposal = proposals[_proposalId];
        
        if (proposal.verified) revert InvalidStatus();
        proposal.verified = true;

        // If a proposal was valid, we are ready to award the community voting power bonuses to the proposer
        ++userCommunityScoreData[proposal.proposer].proposalsCreated;
        
        // We don't need to check whether the proposer is accruing community voting power because
        // they needed that voting power to propose, and once they have an Active Proposal, their
        // tokens are locked from delegating and unstaking.
        ++totalCommunityScoreData.proposalsCreated;
    }

    /////////////////
    //// Execute ////
    /////////////////

    /// @notice Queues a proposal of state succeeded
    /// @param _proposalId The id of the proposal to queue
    function queue(uint256 _proposalId) external {
        // Succeeded means we're past the endTime, yes votes outweigh no votes, and quorum threshold is met
        if(state(_proposalId) != ProposalState.Succeeded) revert InvalidStatus();

        Proposal storage proposal = proposals[_proposalId];

        // Set the ETA (time for execution) to the soonest time based on the Executor's delay
        uint256 eta = block.timestamp + executor.DELAY();
        proposal.eta = eta.toUint32();

        // Queue separate transactions for each action in the proposal
        uint numTargets = proposal.targets.length;
        for (uint256 i = 0; i < numTargets; i++) {
            executor.queueTransaction(i, proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }

        // If a proposal is queued, we are ready to award the community voting power bonuses to the proposer
        ++userCommunityScoreData[proposal.proposer].proposalsPassed;

        // We don't need to check whether the proposer is accruing community voting power because
        // they needed that voting power to propose, and once they have an Active Proposal, their
        // tokens are locked from delegating and unstaking.
        ++totalCommunityScoreData.proposalsPassed;

        // Remove the proposal from the Active Proposals array
        _removeFromActiveProposals(_proposalId);

        emit ProposalQueued(_proposalId, eta);
    }

    /// @notice Executes a queued proposal if eta has passed
    /// @param _proposalId The id of the proposal to execute
    function execute(uint256 _proposalId) external {
        // Queued means the proposal is passed, queued, and within the grace period.
        if (state(_proposalId) != ProposalState.Queued) revert InvalidStatus();

        Proposal storage proposal = proposals[_proposalId];
        proposal.executed = true;

        // Separate transactions were queued for each action in the proposal, so execute each separately
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            executor.executeTransaction(
                i, proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta
            );
        }

        emit ProposalExecuted(_proposalId);
    }

    ////////////////////////////////
    //// Cancel / Veto Proposal ////
    ////////////////////////////////

    /// @notice Vetoes a proposal 
    /// @param _proposalId The id of the proposal to veto
    /// @dev This allows the founder or council multisig to veto a malicious proposal
    function veto(uint256 _proposalId) external cancelable(_proposalId) onlyAdmins {
        Proposal storage proposal = proposals[_proposalId];

        // If the proposal is queued or executed, remove it from the Executor's queuedTransactions mapping
        // Otherwise, remove it from the Active Proposals array
        _removeTransactionWithQueuedOrExpiredCheck(proposal);

        // Update the vetoed flag so the proposal's state is Vetoed
        proposal.vetoed = true;

        // Remove Community Voting Power someone might have earned from creating
        // the proposal
        if (proposal.verified) {
            --userCommunityScoreData[proposal.proposer].proposalsCreated;
            --totalCommunityScoreData.proposalsCreated;
        }

        if (state(_proposalId) == ProposalState.Queued) {
            --userCommunityScoreData[proposal.proposer].proposalsPassed;
            --totalCommunityScoreData.proposalsPassed;
        }

        emit ProposalVetoed(_proposalId);
    }

    /// @notice Cancels a proposal
    /// @param _proposalId The id of the proposal to cancel
    function cancel(uint256 _proposalId) external cancelable(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];

        // Proposals can be canceled if proposer themselves decide to cancel the proposal (at any time before execution)
        // Nouns allows anyone to cancel if proposer falls below threshold, but because tokens are locked, this isn't possible
        if (msg.sender != proposal.proposer) revert NotEligible();

        // If the proposal is queued or executed, remove it from the Executor's queuedTransactions mapping
        // Otherwise, remove it from the Active Proposals array
        _removeTransactionWithQueuedOrExpiredCheck(proposal);

        // Set the canceled flag to true to change the status to Canceled
        proposal.canceled = true;   

        emit ProposalCanceled(_proposalId);
    }

    /// @notice clear the proposal from the ActiveProposals array or the Executor's queuedTransactions
    /// @param _proposalId The id of the proposal to clear
    function clear(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];

        // This function can only be called in three situations:
        // 1. EXPIRED: The proposal was queued but the grace period has passed (removes it from Executor's 
        //    queuedTransactions). We use this instead of using cancel() so Expired state is preserved.
        // 2. DEFEATED: The proposal is over and was not passed (removes it from ActiveProposals array).
        //    We use this instead of using cancel() so Defeated state is preserved.
        // 3. UNVERIFIED AFTER END TIME (CANCELED): The proposal remained unverified through the endTime and is 
        //    now considered canceled (removes it from ActiveProposals array). We use this because cancel() is 
        //    not allowed to be called on canceled proposals, but this situation is a special case where the 
        //    proposal still needs to be removed from the ActiveProposals array.
        if (
            state(_proposalId) != ProposalState.Expired &&
            state(_proposalId) != ProposalState.Defeated && 
            (proposal.verified || block.timestamp <= proposal.endTime)
        ) revert NotEligible();

        // If the proposal is Expired, remove it from the Executor's queuedTransactions mapping
        // If the proposal is Defeated or Canceled, remove it from the Active Proposals array
        _removeTransactionWithQueuedOrExpiredCheck(proposal);

        emit ProposalCanceled(_proposalId);
    }

    ////////////////
    //// Voting ////
    ////////////////

    /// @notice Cast a vote for a proposal
    /// @param _proposalId The id of the proposal to vote on
    /// @param _support The support value for the vote (0=against, 1=for, 2=abstain)
    function castVote(uint256 _proposalId, uint8 _support) external {
        // Refunds gas if votingRefund is true
        if (votingRefund) {
            uint256 startGas = gasleft();
            uint votes = _castVote(msg.sender, _proposalId, _support);
            emit VoteCast( msg.sender, _proposalId, _support, votes);
            _refundGas(startGas);
        } else {
            uint votes = _castVote(msg.sender, _proposalId, _support);
            emit VoteCast( msg.sender, _proposalId, _support, votes);
        }
    }

    /// @notice Internal function that caries out voting logic
    /// @param _voter The voter that is casting their vote
    /// @param _proposalId The id of the proposal to vote on
    /// @param _support The support value for the vote (0=against, 1=for, 2=abstain)
    /// @return The number of votes cast
    function _castVote(address _voter, uint256 _proposalId, uint8 _support) internal returns (uint) {
        // Only Active proposals can be voted on
        if (state(_proposalId) != ProposalState.Active) revert InvalidStatus();
        
        // Only valid values for _support are 0 (against), 1 (for), and 2 (abstain)
        if (_support > 2) revert InvalidInput();

        Proposal storage proposal = proposals[_proposalId];

        // If the voter has already voted, revert        
        Receipt storage receipt = proposal.receipts[_voter];
        if (receipt.hasVoted) revert AlreadyVoted();

        // Calculate the number of votes a user is able to cast
        // This takes into account delegation and community voting power
        uint24 votes = (staking.getVotes(_voter)).toUint24();

        if (votes == 0) revert NotEligible();

        // Update the proposal's total voting records based on the votes
        if (_support == 0) {
            proposal.againstVotes = proposal.againstVotes + votes;
        } else if (_support == 1) {
            proposal.forVotes = proposal.forVotes + votes;
        } else if (_support == 2) {
            proposal.abstainVotes = proposal.abstainVotes + votes;
        }

        // Update the user's receipt for this proposal
        receipt.hasVoted = true;
        receipt.support = _support;
        receipt.votes = votes;

        // Make these updates after the vote so it doesn't impact voting power for this vote.
        ++totalCommunityScoreData.votes;

        // We can update the total community voting power with no check because if you can vote, 
        // it means you have votes so you haven't delegated.
        ++userCommunityScoreData[_voter].votes;

        return votes;
    }


    /////////////////
    //// Helpers ////
    /////////////////
    
    /// @notice Calculates a fixed value given a BPS value and a number to calculate against
    /// @dev For example, if _bps is 5000, it means 50% of _number
    /// @dev Used to calculate the proposalThreshold or quorumThreshold at a given point in time
    function bps2Uint(uint256 _bps, uint256 _number) internal pure returns (uint256) {
        return (_number * _bps) / 10000;
    }

    /// @notice Removes a proposal from the ActiveProposals array or the Executor's queuedTransactions mapping
    /// @param _proposal The proposal to remove
    function _removeTransactionWithQueuedOrExpiredCheck(Proposal storage _proposal) internal {
        if (
            state(_proposal.id) == ProposalState.Queued || 
            state(_proposal.id) == ProposalState.Expired
        ) {
            for (uint256 i = 0; i < _proposal.targets.length; i++) {
                executor.cancelTransaction(
                    i,
                    _proposal.targets[i],
                    _proposal.values[i],
                    _proposal.signatures[i],
                    _proposal.calldatas[i],
                    _proposal.eta
                );
            }
        } else {
            _removeFromActiveProposals(_proposal.id);
        }
    }

    /// @notice Removes a proposal from the ActiveProposals array
    /// @param _id The id of the proposal to remove
    /// @dev uses swap and pop to find the proposal, swap it with the final index, and pop the final index off
    function _removeFromActiveProposals(uint256 _id) private {
        uint256 index;
        uint[] memory actives = activeProposals;

        bool found = false;
        for (uint256 i = 0; i < actives.length; i++) {
            if (actives[i] == _id) {
                found = true;
                index = i;
                break;
            }
        }

        // This is important because otherwise, if the proposal is not found, it will remove the first index
        // There shouldn't be any ways to call this with an ID that isn't in the array, but this is here for extra safety
        if (!found) revert NotInActiveProposals();

        activeProposals[index] = activeProposals[actives.length - 1];
        activeProposals.pop();
    }
    
    /// @notice Passes in new values for the total community score data
    /// @param _votes The total number of votes users have cast that are accruing towards community scores
    /// @param _againstVotes The number of proposals created that are accruing towards community scores
    /// @param _forVotes The number of proposals passed that are accruing towards community scores
    /** @dev This is used by the staking contract to update these values when users stake, unstake, delegate, 
        so that we are able to calculate total community score that equals the sum of individual community scores,
        since these actions can move their scores to 0 and back. */
    function updateTotalCommunityScoreData(uint64 _votes, uint64 _proposalsCreated, uint64 _proposalsPassed) external {
        if (msg.sender != address(staking)) revert NotAuthorized();

        totalCommunityScoreData.proposalsCreated = _proposalsCreated;
        totalCommunityScoreData.proposalsPassed = _proposalsPassed;
        totalCommunityScoreData.votes = _votes;

        emit TotalCommunityScoreDataUpdated(_proposalsCreated, _proposalsPassed, _votes);
    }

    ///////////////
    //// Admin ////
    ///////////////

    /// @notice Turn on or off gas refunds for proposing and voting
    /// @param _votingRefund Should refunds for voting be on (true) or off (false)?
    /// @param _proposalRefund Should refunds for proposing be on (true) or off (false)?
    function setRefunds(bool _votingRefund, bool _proposalRefund) external onlyExecutor {
        
        emit RefundSet(false, votingRefund, _votingRefund);
        emit RefundSet(true, proposalRefund, _proposalRefund);
        
        votingRefund = _votingRefund;
        proposalRefund = _proposalRefund;
    }

    /// @notice Admin function for setting the voting delay
    /// @param _newVotingDelay new voting delay, in seconds
    function setVotingDelay(uint256 _newVotingDelay) external onlyExecutor {
        if (_newVotingDelay < MIN_VOTING_DELAY || _newVotingDelay > MAX_VOTING_DELAY) revert ParameterOutOfBounds();

        emit VotingDelaySet(votingDelay, _newVotingDelay);

        votingDelay = _newVotingDelay;
    }

    /// @notice Admin function for setting the voting period
    /// @param _newVotingPeriod new voting period, in seconds
    function setVotingPeriod(uint256 _newVotingPeriod) external onlyExecutor {
        if (_newVotingPeriod < MIN_VOTING_PERIOD || _newVotingPeriod > MAX_VOTING_PERIOD) revert ParameterOutOfBounds();

        emit VotingPeriodSet(votingPeriod, _newVotingPeriod);

        votingPeriod = _newVotingPeriod;        
    }

    /// @notice Admin function for setting the proposal threshold basis points
    /// @param _newProposalThresholdBPS new proposal threshold
    /** @dev This function can be called by the multisigs or by governance, to ensure
        it can be decreased in the event that governance isn't able to hit the threshold. */
    function setProposalThresholdBPS(uint256 _newProposalThresholdBPS) external onlyExecutorOrAdmins {
        if (_newProposalThresholdBPS < MIN_PROPOSAL_THRESHOLD_BPS || _newProposalThresholdBPS > MAX_PROPOSAL_THRESHOLD_BPS) revert ParameterOutOfBounds();
        
        emit ProposalThresholdBPSSet(proposalThresholdBPS, _newProposalThresholdBPS);
        
        proposalThresholdBPS = _newProposalThresholdBPS;
    }

    /// @notice Admin function for setting the quorum votes basis points
    /// @param _newQuorumVotesBPS new proposal threshold
    /** @dev This function can be called by the multisigs or by governance, to ensure
        it can be decreased in the event that governance isn't able to hit the threshold. */
    function setQuorumVotesBPS(uint256 _newQuorumVotesBPS) external onlyExecutorOrAdmins {
        if (_newQuorumVotesBPS < MIN_QUORUM_VOTES_BPS || _newQuorumVotesBPS > MAX_QUORUM_VOTES_BPS) revert ParameterOutOfBounds();

        emit QuorumVotesBPSSet(quorumVotesBPS, _newQuorumVotesBPS);
        
        quorumVotesBPS = _newQuorumVotesBPS;
    }

    /// @notice Admin function to ban a user from submitting new proposals
    /// @param _proposer The user to ban
    /// @param _banned Should the user be banned (true) or unbanned (false)?
    /// @dev This function is used if a delegate tries to create constant proposals to prevent undelegation
    function banProposer(address _proposer, bool _banned) external onlyExecutorOrAdmins {
        bannedProposers[_proposer] = _banned;
    }

    /// @notice Upgrade the Staking contract to a new address
    /// @param _newStaking Address of the new Staking contract
    /// @dev Since upgrades are only allowed by governance, this is only callable by Executor
    function setStakingAddress(IStaking _newStaking) external onlyExecutor {
        try _newStaking.isFrankenPunksStakingContract() returns (bool isStaking) {
            if (!isStaking) revert NotStakingContract();
        } catch {
            revert NotStakingContract();
        }

        staking = _newStaking;

        emit NewStakingContract(address(_newStaking));
    }

    /// @notice Contract can receive ETH (will be used to pay for gas refunds)
    receive() external payable {}

    /// @notice Contract can receive ETH (will be used to pay for gas refunds)
    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract FrankenDAOErrors {
    // General purpose
    error NotAuthorized();

    // Staking
    error NonExistentToken();
    error InvalidDelegation();
    error Paused();
    error InvalidParameter();
    error TokenLocked();
    error StakedTokensCannotBeTransferred();

    // Governance
    error ZeroAddress();
    error AlreadyInitialized();
    error ParameterOutOfBounds();
    error InvalidId();
    error InvalidProposal();
    error InvalidStatus();
    error InvalidInput();
    error AlreadyVoted();
    error NotEligible();
    error NotInActiveProposals();
    error NotStakingContract();

    // Executor
    error DelayNotSatisfied();
    error IdenticalTransactionAlreadyQueued();
    error TransactionNotQueued();
    error TimelockNotMet();
    error TransactionReverted();
}

pragma solidity ^0.8.10;

import {IExecutor} from "./IExecutor.sol";

interface IAdmin {

    ////////////////////
    ////// Events //////
    ////////////////////

    /// @notice Emited when a new address is set for the Council
    event NewCouncil(address oldCouncil, address newCouncil);
    /// @notice Emited when a new address is set for the Founders
    event NewFounders(address oldFounders, address newFounders);
    /// @notice Emited when a new address is set for the Pauser
    event NewPauser(address oldPauser, address newPauser);
    /// @notice Emited when a new address is set for the Verifier
    event NewVerifier(address oldVerifier, address newVerifier);
    /// @notice Emitted when pendingFounders is changed
    event NewPendingFounders(address oldPendingFounders, address newPendingFounders);

    /////////////////////
    ////// Methods //////
    /////////////////////

    function acceptFounders() external;
    function council() external view returns (address);
    function executor() external view returns (IExecutor);
    function founders() external view returns (address);
    function pauser() external view returns (address);
    function pendingFounders() external view returns (address);
    function revokeFounders() external;
    function setCouncil(address _newCouncil) external;
    function setPauser(address _newPauser) external;
    function setPendingFounders(address _newPendingFounders) external;
}

pragma solidity ^0.8.10;

interface IExecutor {

    ////////////////////
    ////// Events //////
    ////////////////////

    /// @notice Emited when a transaction is cancelled
    event CancelTransaction(bytes32 indexed txHash, uint256 id, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
    /// @notice Emited when a transaction is executed
    event ExecuteTransaction(bytes32 indexed txHash, uint256 id, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
    /// @notice Emited when a new delay value is set
    event NewDelay(uint256 indexed newDelay);
    /// @notice Emited when a transaction is queued
    event QueueTransaction(bytes32 indexed txHash, uint256 id, address indexed target, uint256 value, string signature, bytes data, uint256 eta);

    /////////////////////
    ////// Methods //////
    /////////////////////

    function DELAY() external view returns (uint256);

    function GRACE_PERIOD() external view returns (uint256);

    function cancelTransaction(uint256 _id, address _target, uint256 _value, string memory _signature, bytes memory _data, uint256 _eta) external;

    function executeTransaction(uint256 _id, address _target, uint256 _value, string memory _signature, bytes memory _data, uint256 _eta) external returns (bytes memory);

    function queueTransaction(uint256 _id, address _target, uint256 _value, string memory _signature, bytes memory _data, uint256 _eta) external returns (bytes32 txHash);

    function queuedTransactions(bytes32) external view returns (bool);
}

pragma solidity ^0.8.10;

import {IStaking} from "./IStaking.sol";

interface IGovernance {

    ////////////////////
    ////// Events //////
    ////////////////////

    /// @notice Emited when a proposal is canceled
    event ProposalCanceled(uint256 id);
    /// @notice Emited when a proposal is created
    event ProposalCreated( uint256 id, address proposer, address[] targets, uint256[] values, string[] signatures, bytes[] calldatas, uint32 startTime, uint32 endTime, uint24 quorumVotes, string description);
    /// @notice Emited when a proposal is executed
    event ProposalExecuted(uint256 id);
    /// @notice Emited when a proposal is queued
    event ProposalQueued(uint256 id, uint256 eta);
    /// @notice Emited when a proposal is vetoed
    event ProposalVetoed(uint256 id);
    /// @notice Emited when a new proposal threshold BPS is set
    event ProposalThresholdBPSSet(uint256 oldProposalThresholdBPS, uint256 newProposalThresholdBPS);
    /// @notice Emited when a new quorum votes BPS is set
    event QuorumVotesBPSSet(uint256 oldQuorumVotesBPS, uint256 newQuorumVotesBPS);
    /// @notice Emited when the refund status changes
    event RefundSet(bool isProposingRefund, bool oldStatus, bool newStatus);
    /// @notice Emited when the total community score data is updated
    event TotalCommunityScoreDataUpdated(uint64 proposalsCreated, uint64 proposalsPassed, uint64 votes);
    /// @notice Emited when a vote is cast
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 votes);
    /// @notice Emited when the voting delay is updated
    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);
    /// @notice Emited when the voting period is updated
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);
    /// @notice Emited when the staking contract is changed.
    event NewStakingContract(address stakingContract);

    /////////////////////
    ////// Storage //////
    /////////////////////

    struct CommunityScoreData {
        uint64 votes;
        uint64 proposalsCreated;
        uint64 proposalsPassed;
    }

    struct Proposal {
        /// @notice Unique id for looking up a proposal
        uint96 id;
        /// @notice Creator of the proposal
        address proposer;
        /// @notice the ordered list of target addresses for calls to be made
        address[] targets;
        /// @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint256[] values;
        /// @notice The ordered list of function signatures to be called
        string[] signatures;
        /// @notice The ordered list of calldata to be passed to each call
        bytes[] calldatas;
        /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed at the time of proposal creation. 
        uint24 quorumVotes;
        /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint32 eta;
        /// @notice The block at which voting begins: holders must delegate their votes prior to this block
        uint32 startTime;
        /// @notice The block at which voting ends: votes must be cast prior to this block
        uint32 endTime;
        /// @notice Current number of votes in favor of this proposal
        uint24 forVotes;
        /// @notice Current number of votes in opposition to this proposal
        uint24 againstVotes;
        /// @notice Current number of votes for abstaining for this proposal
        uint24 abstainVotes;
        /// @notice Flag marking whether a proposal has been verified
        bool verified;
        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;
        /// @notice Flag marking whether the proposal has been vetoed
        bool vetoed;
        /// @notice Flag marking whether the proposal has been executed
        bool executed;
        /// @notice Receipts of ballots for the entire set of voters
        mapping(address => Receipt) receipts;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice Whether or not a vote has been cast
        bool hasVoted;
        /// @notice Whether or not the voter supports the proposal or abstains
        uint8 support;
        /// @notice The number of votes the voter had, which were cast
        uint24 votes;
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
        Executed,
        Vetoed
    }

    /////////////////////
    ////// Methods //////
    /////////////////////

    function MAX_PROPOSAL_THRESHOLD_BPS() external view returns (uint256);
    function MAX_QUORUM_VOTES_BPS() external view returns (uint256);
    function MAX_VOTING_DELAY() external view returns (uint256);
    function MAX_VOTING_PERIOD() external view returns (uint256);
    function MIN_PROPOSAL_THRESHOLD_BPS() external view returns (uint256);
    function MIN_QUORUM_VOTES_BPS() external view returns (uint256);
    function MIN_VOTING_DELAY() external view returns (uint256);
    function MIN_VOTING_PERIOD() external view returns (uint256);
    function PROPOSAL_MAX_OPERATIONS() external view returns (uint256);
    function activeProposals(uint256) external view returns (uint256);
    function cancel(uint256 _proposalId) external;
    function castVote(uint256 _proposalId, uint8 _support) external;
    function clear(uint256 _proposalId) external;
    function execute(uint256 _proposalId) external;
    function getActions(uint256 _proposalId)
        external
        view
        returns (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        );
    function getActiveProposals() external view returns (uint256[] memory);
    function getProposalData(uint256 _proposalId) external view returns (uint256, address, uint256);
    function getProposalStatus(uint256 _proposalId) external view returns (bool, bool, bool, bool);
    function getProposalVotes(uint256 _proposalId) external view returns (uint256, uint256, uint256);
    function getReceipt(uint256 _proposalId, address _voter) external view returns (Receipt memory);
    function initialize(
        address _staking,
        address _executor,
        address _founders,
        address _council,
        uint256 _votingPeriod,
        uint256 _votingDelay,
        uint256 _proposalThresholdBPS,
        uint256 _quorumVotesBPS
    ) external;
    function latestProposalIds(address) external view returns (uint256);
    function name() external view returns (string memory);
    function proposalCount() external view returns (uint256);
    function proposalRefund() external view returns (bool);
    function proposalThreshold() external view returns (uint256);
    function proposalThresholdBPS() external view returns (uint256);
    function proposals(uint256)
        external
        view
        returns (
            uint96 id,
            address proposer,
            uint24 quorumVotes,
            uint32 eta,
            uint32 startTime,
            uint32 endTime,
            uint24 forVotes,
            uint24 againstVotes,
            uint24 abstainVotes,
            bool verified,
            bool canceled,
            bool vetoed,
            bool executed
        );
    function propose(
        address[] memory _targets,
        uint256[] memory _values,
        string[] memory _signatures,
        bytes[] memory _calldatas,
        string memory _description
    ) external returns (uint256);
    function queue(uint256 _proposalId) external;
    function quorumVotes() external view returns (uint256);
    function quorumVotesBPS() external view returns (uint256);
    function setProposalThresholdBPS(uint256 _newProposalThresholdBPS) external;
    function setQuorumVotesBPS(uint256 _newQuorumVotesBPS) external;
    function setRefunds(bool _votingRefund, bool _proposalRefund) external;
    function setStakingAddress(IStaking _newStaking) external;
    function setVotingDelay(uint256 _newVotingDelay) external;
    function setVotingPeriod(uint256 _newVotingPeriod) external;
    function staking() external view returns (IStaking);
    function state(uint256 _proposalId) external view returns (ProposalState);
    function totalCommunityScoreData()
        external
        view
        returns (uint64 votes, uint64 proposalsCreated, uint64 proposalsPassed);
    function updateTotalCommunityScoreData(uint64 _votes, uint64 _proposalsCreated, uint64 _proposalsPassed) external;
    function userCommunityScoreData(address)
        external
        view
        returns (uint64 votes, uint64 proposalsCreated, uint64 proposalsPassed);
    function verifyProposal(uint256 _proposalId) external;
    function veto(uint256 _proposalId) external;
    function votingDelay() external view returns (uint256);
    function votingPeriod() external view returns (uint256);
    function votingRefund() external view returns (bool);
}

pragma solidity ^0.8.10;

interface IRefundable {

    ////////////////////
    ////// Events //////
    ////////////////////

    /// @notice Emitted when a refund is issued
    event IssueRefund(address refunded, uint256 amount, bool sent, uint256 remainingBalance);

    /// @notice Emited when we're not able to refund the full amount
    event InsufficientFundsForRefund(address refunded, uint256 intendedAmount, uint256 sentAmount);

    /////////////////////
    ////// Methods //////
    /////////////////////

    function MAX_REFUND_PRIORITY_FEE() external view returns (uint256);
    function REFUND_BASE_GAS() external view returns (uint256);
}

pragma solidity ^0.8.10;

interface IStaking {

    ////////////////////
    ////// Events //////
    ////////////////////

    /// @notice Emited a staker changes who they're delegating to
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    /// @notice Emited when staking is paused/unpaused
    event StakingPause(bool status);
    /// @notice Emited when admins change the token's base URI
    event BaseURIChanged(string _baseURI);
    /// @notice Emited when the contract URI is updated
    event ContractURIChanged(string _contractURI);
    /// @notice Emited when refund settings are updated
    event RefundSettingsChanged(bool _stakingRefund, bool _delegatingRefund, uint256 _newCooldown);
    /// @notice Emited when FrankenMonster voting multiplier is changed
    event MonsterMultiplierChanged(uint256 _monsterMultiplier);
    /// @notice Emited when the voting multiplier for passed proposals is changed
    event ProposalPassedMultiplierChanged(uint64 _proposalPassedMultiplier);
    /// @notice Emited when the stake time multiplier is changed
    event StakeTimeChanged(uint128 _stakeTime);
    /// @notice Emited when the staking multiplier is changed
    event StakeAmountChanged(uint128 _stakeAmount);
    /// @notice Emited when the voting multiplier for voting is changed
    event VotesMultiplierChanged(uint64 _votesMultiplier);
    /// @notice Emited when the voting multiplier for creating proposals is changed
    event ProposalsCreatedMultiplierChanged(uint64 _proposalsCreatedMultiplier);
    /// @notice Emited when the base votes for a token is changed
    event BaseVotesChanged(uint256 _baseVotes);

    /////////////////////
    ////// Storage //////
    /////////////////////

    struct CommunityPowerMultipliers {
        uint64 votes;
        uint64 proposalsCreated;
        uint64 proposalsPassed;
    }

    struct StakingSettings {
        uint128 maxStakeBonusTime;
        uint128 maxStakeBonusAmount;
    }

    enum RefundStatus { 
        StakingAndDelegatingRefund,
        StakingRefund, 
        DelegatingRefund, 
        NoRefunds
    }

    /////////////////////
    ////// Methods //////
    /////////////////////

    function baseTokenURI() external view returns (string memory);
    function BASE_VOTES() external view returns (uint256);
    function changeStakeAmount(uint128 _newMaxStakeBonusAmount) external;
    function changeStakeTime(uint128 _newMaxStakeBonusTime) external;
    function communityPowerMultipliers()
        external
        view
        returns (uint64 votes, uint64 proposalsCreated, uint64 proposalsPassed);
    function delegate(address _delegatee) external;
    function delegatingRefund() external view returns (bool);
    function evilBonus(uint256 _tokenId) external view returns (uint256);
    function getCommunityVotingPower(address _voter) external view returns (uint256);
    function getDelegate(address _delegator) external view returns (address);
    function getStakedTokenSupplies() external view returns (uint128, uint128);
    function getTokenVotingPower(uint256 _tokenId) external view returns (uint256);
    function getTotalVotingPower() external view returns (uint256);
    function getVotes(address _account) external view returns (uint256);
    function isFrankenPunksStakingContract() external pure returns (bool);
    function lastDelegatingRefund(address) external view returns (uint256);
    function lastStakingRefund(address) external view returns (uint256);
    function paused() external view returns (bool);
    function setBaseURI(string memory _baseURI) external;
    function setPause(bool _paused) external;
    function setProposalsCreatedMultiplier(uint64 _proposalsCreatedMultiplier) external;
    function setProposalsPassedMultiplier(uint64 _proposalsPassedMultiplier) external;
    function setRefunds(bool _stakingRefund, bool _delegatingRefund, uint256 _newCooldown) external;
    function setVotesMultiplier(uint64 _votesmultiplier) external;
    function stake(uint256[] memory _tokenIds, uint256 _unlockTime) external;
    function stakedFrankenMonsters() external view returns (uint128);
    function stakedFrankenPunks() external view returns (uint128);
    function stakingRefund() external view returns (bool);
    function stakingSettings() external view returns (uint128 maxStakeBonusTime, uint128 maxStakeBonusAmount);
    function tokenVotingPower(address) external view returns (uint256);
    function unlockTime(uint256) external view returns (uint256);
    function unstake(uint256[] memory _tokenIds, address _to) external;
    function votesFromOwnedTokens(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../interfaces/IAdmin.sol";
import "../interfaces/IExecutor.sol";
import { FrankenDAOErrors } from "../errors/FrankenDAOErrors.sol";

/// @notice Custom access control manager for FrankenDAO
/// @dev This functionality is inherited by Governance.sol and Staking.sol
abstract contract Admin is IAdmin, FrankenDAOErrors {
    /// @notice Founder multisig
    address public founders;

    /// @notice Council multisig
    address public council;

    /// @notice Executor contract address for passed governance proposals
    IExecutor public executor;

    /// @notice Admin that only has the power to pause and unpause staking
    /// @dev This will be a EOA used by the team for easy pausing and unpausing
    /// @dev This address is changeable by governance if the community thinks the team is misusing this power
    address public pauser;

    /// @notice Admin that only has the power to verify contracts
    /// @dev This will be an EOA used by the team for contract verification
    address public verifier;

    /// @notice Pending founder addresses for this contract
    /// @dev Only founders is two-step, because errors in transferring other admin addresses can be corrected by founders
    address public pendingFounders;

    /////////////////////////////
    ///////// MODIFIERS /////////
    /////////////////////////////

    /// @notice Modifier for functions that can only be called by the Executor contract
    /// @dev This is for functions that only Governance is able to call
    modifier onlyExecutor() {
        if(msg.sender != address(executor)) revert NotAuthorized();
        _;
    }

    /// @notice Modifier for functions that can only be called by the Council or Founder multisigs
    modifier onlyAdmins() {
        if(msg.sender != founders && msg.sender != council) revert NotAuthorized();
        _;
    }

    /// @notice Modifier for functions that can only be called by the Pauser or either multisig
    modifier onlyPauserOrAdmins() {
        if(msg.sender != founders && msg.sender != council && msg.sender != pauser) revert NotAuthorized();
        _;
    }

    modifier onlyVerifierOrAdmins() {
        if(msg.sender != founders && msg.sender != council && msg.sender != verifier) revert NotAuthorized();
        _;
    }

    /// @notice Modifier for functions that can only be called by either multisig or the Executor contract
    modifier onlyExecutorOrAdmins() {
        if (
            msg.sender != address(executor) && 
            msg.sender != council && 
            msg.sender != founders
        ) revert NotAuthorized();
        _;
    }

    /////////////////////////////
    ////// ADMIN TRANSFERS //////
    /////////////////////////////

    /// @notice Begins transfer of founder rights. The newPendingFounders must call `_acceptFounders` to finalize the transfer.
    /// @param _newPendingFounders New pending founder.
    /// @dev This doesn't use onlyAdmins because only Founders have the right to set new Founders.
    function setPendingFounders(address _newPendingFounders) external {
        if (msg.sender != founders) revert NotAuthorized();
        emit NewPendingFounders(pendingFounders, _newPendingFounders);
        pendingFounders = _newPendingFounders;
    }

    /// @notice Accepts transfer of founder rights. msg.sender must be pendingFounders
    function acceptFounders() external {
        if (msg.sender != pendingFounders) revert NotAuthorized();
        emit NewFounders(founders, pendingFounders);
        founders = pendingFounders;
        pendingFounders = address(0);
    }

    /// @notice Revokes permissions for the founder multisig
    /// @dev Only the founders can call this, as nobody else should be able to revoke this permission
    /// @dev Used for eventual decentralization, as otherwise founders cannot be set to address(0) because of two-step
    /// @dev This also ensures that pendingFounders is set to address(0), to ensure they can't re-accept it later
    function revokeFounders() external {
        if (msg.sender != founders) revert NotAuthorized();
        
        emit NewFounders(founders, address(0));
        
        founders = address(0);
        pendingFounders = address(0);
    }

    /// @notice Transfers council address to a new multisig
    /// @param _newCouncil New address for council
    /// @dev This uses onlyAdmin because either the Council or the Founders can set a new Council.
    function setCouncil(address _newCouncil) external onlyAdmins {
       
        emit NewCouncil(council, _newCouncil);
       
        council = _newCouncil;
    }

    /// @notice Transfers verifier role to a new address.
    /// @param _newVerifier New address for verifier
    function setVerifier(address _newVerifier) external onlyAdmins {

        emit NewVerifier(verifier, _newVerifier);
        
        verifier = _newVerifier;
    }

    /// @notice Transfers pauser role to a new address.
    /// @param _newPauser New address for pauser
    function setPauser(address _newPauser) external onlyExecutorOrAdmins {
        
        emit NewPauser(pauser, _newPauser);
        
        pauser = _newPauser;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../interfaces/IRefundable.sol";
import { FrankenDAOErrors } from "../errors/FrankenDAOErrors.sol";

/// @notice Provides a _refundGas() function that can be used for inhering contracts to refund user gas cost
/// @dev This functionality is inherited by Governance.sol (for proposing and voting) and Staking.sol (for staking and delegating)
contract Refundable is IRefundable, FrankenDAOErrors {

    /// @notice The maximum priority fee used to cap gas refunds
    uint256 public constant MAX_REFUND_PRIORITY_FEE = 2 gwei;

    /// @notice Gas used before _startGas or after refund
    /// @dev Includes 21K TX base, 3.7K for other overhead, and 2.3K for ETH transfer 
    /** @dev This will be slightly different depending on which function is used, but all are within a few 
        thousand gas, so approximation is fine. */
    uint256 public constant REFUND_BASE_GAS = 27_000;

    /// @notice Calculate the amount spent on gas and send that to msg.sender from the contract's balance
    /// @param _startGas gasleft() at the start of the transaction, used to calculate gas spent
    /// @dev Forked from NounsDAO: https://github.com/nounsDAO/nouns-monorepo/blob/master/packages/nouns-contracts/contracts/governance/NounsDAOLogicV2.sol#L1033-L1046
    function _refundGas(uint256 _startGas) internal {
        unchecked {
            uint256 gasPrice = _min(tx.gasprice, block.basefee + MAX_REFUND_PRIORITY_FEE);
            uint256 gasUsed = _startGas - gasleft() + REFUND_BASE_GAS;
            uint refundAmount = gasPrice * gasUsed;
            
            // If gas fund runs out, pay out as much as possible and emit warning event.
            if (address(this).balance < refundAmount) {
                emit InsufficientFundsForRefund(msg.sender, refundAmount, address(this).balance);
                refundAmount = address(this).balance;
            }

            // There shouldn't be any reentrancy risk, as this is called last at all times.
            // They also can't exploit the refund by wasting gas before we've already finalized amount.
            (bool refundSent, ) = msg.sender.call{ value: refundAmount }('');

            // Includes current balance in event so team can listen and filter to know when to propose refill.
            emit IssueRefund(msg.sender, refundAmount, refundSent, address(this).balance);
        }
    }

    /// @notice Returns the lower value of two uints
    /// @param a First uint
    /// @param b Second uint
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }
}