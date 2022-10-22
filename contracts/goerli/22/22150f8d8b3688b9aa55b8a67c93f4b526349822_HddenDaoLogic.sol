/**
 *Submitted for verification at Etherscan.io on 2022-10-22
*/

// SPDX-License-Identifier: NONE

pragma solidity ^0.8.6;

contract HddenDaoEvents {
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

    event ProposalCreatedWithRequirements(
        uint256 id,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        uint256 proposalThreshold,
        uint256 quorumVotes,
        string description
    );

    /// @notice An event emitted when a vote has been cast on a proposal
    /// @param voter The address which casted a vote
    /// @param proposalId The proposal id which was voted on
    /// @param support Support value for the vote. 0=against, 1=for, 2=abstain
    /// @param votes Number of votes which were cast by the voter
    /// @param reason The reason given for the vote by the voter
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 votes, string reason);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint256 id);

    /// @notice An event emitted when a proposal has been queued in the NounsDAOExecutor
    event ProposalQueued(uint256 id, uint256 eta);

    /// @notice An event emitted when a proposal has been executed in the NounsDAOExecutor
    event ProposalExecuted(uint256 id);

    /// @notice An event emitted when a proposal has been vetoed by vetoAddress
    event ProposalVetoed(uint256 id);

    /// @notice An event emitted when the voting delay is set
    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);

    /// @notice An event emitted when the voting period is set
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);

    /// @notice Emitted when implementation is changed
    event NewImplementation(address oldImplementation, address newImplementation);

    /// @notice Emitted when proposal threshold basis points is set
    event ProposalThresholdBPSSet(uint256 oldProposalThresholdBPS, uint256 newProposalThresholdBPS);

    /// @notice Emitted when quorum votes basis points is set
    event QuorumVotesBPSSet(uint256 oldQuorumVotesBPS, uint256 newQuorumVotesBPS);

    /// @notice Emitted when pendingAdmin is changed
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /// @notice Emitted when pendingAdmin is accepted, which means admin is updated
    event NewAdmin(address oldAdmin, address newAdmin);

    /// @notice Emitted when vetoer is changed
    event NewVetoer(address oldVetoer, address newVetoer);
}

interface IHddenTreasury {
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


interface IHddenToken {
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);

    function totalSupply() external view returns (uint96);

}


contract HddenStorage {
    /// @notice Administrator for this contract
    address public admin;

    /// @notice Pending administrator for this contract
    address public pendingAdmin;

    /// @notice Active brains of Governor
    address public implementation;
}

contract HddenDao is HddenStorage {
    /// @notice Vetoer who has the ability to veto any proposal
    address public vetoer;

    /// @notice The delay before voting on a proposal may take place, once proposed, in blocks
    uint256 public votingDelay;

    /// @notice The duration of voting on a proposal, in blocks
    uint256 public votingPeriod;

    /// @notice The basis point number of votes required in order for a voter to become a proposer. *DIFFERS from GovernerBravo
    uint256 public proposalThresholdBPS;

    /// @notice The basis point number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed. *DIFFERS from GovernerBravo
    uint256 public quorumVotesBPS;

    /// @notice The total number of proposals
    uint256 public proposalCount;

    IHddenTreasury public timelock;

    IHddenToken public hddentoken;

    mapping (uint256 => Proposal) public proposals;

    mapping(address => uint256) public latestProposalIds;

    struct Proposal {
        uint256 id;
        address proposer;
        uint256 proposalThreshold;
        uint256 quoromVotes;
        uint256 eta;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        bool canceled;
        bool vetoed;
        bool executed;
        mapping(address => Receipt) receipts;
    }
    struct Receipt {
        bool hasVoted;
        uint8 support;
        uint96 votes;
    }
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

contract HddenDaoLogic is HddenDao, HddenDaoEvents{
    string public constant name = "Hdden Dao";

    uint256 public constant MIN_PROPOSAL_THRESHOLD_BPS = 1; // 1 basis point or 0.01%

    /// @notice The maximum setable proposal threshold
    uint256 public constant MAX_PROPOSAL_THRESHOLD_BPS = 1_000; // 1,000 basis points or 10%

    /// @notice The minimum setable voting period
    uint256 public constant MIN_VOTING_PERIOD = 5_760; // About 24 hours

    /// @notice The max setable voting period
    uint256 public constant MAX_VOTING_PERIOD = 80_640; // About 2 weeks

    /// @notice The min setable voting delay
    uint256 public constant MIN_VOTING_DELAY = 1;

    /// @notice The max setable voting delay
    uint256 public constant MAX_VOTING_DELAY = 40_320; // About 1 week

    /// @notice The minimum setable quorum votes basis points
    uint256 public constant MIN_QUORUM_VOTES_BPS = 200; // 200 basis points or 2%

    /// @notice The maximum setable quorum votes basis points
    uint256 public constant MAX_QUORUM_VOTES_BPS = 2_000; // 2,000 basis points or 20%

    /// @notice The maximum number of actions that can be included in a proposal
    uint256 public constant proposalMaxOperations = 10; // 10 actions

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)');

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256('Ballot(uint256 proposalId,uint8 support)');

    function _initialize(address _timelock, address _hddentoken, address vetoer_, uint256 votingPeriod_, uint256 votingDelay_, uint256 proposalThresholdBPS_, uint256 quorumVotesBPS_) public virtual {
        require(address(timelock) == address(0), "HddenDao: Treasure can not be zero Address");
        require(msg.sender == admin, "Admin only");
        require(_timelock != address(0), "HddenDao:: initialize: invalid timelock address");
        require(votingPeriod_ >= MIN_VOTING_PERIOD && votingPeriod_ <= MAX_VOTING_PERIOD, "Invalid voting period"); 
        require(votingDelay_ >= MIN_VOTING_DELAY && votingDelay_ <= MAX_VOTING_DELAY, "Invalid Voting Period");
        require(proposalThresholdBPS_ >= MIN_PROPOSAL_THRESHOLD_BPS && proposalThresholdBPS_ <= MAX_PROPOSAL_THRESHOLD_BPS,
            'Initialize: invalid proposal threshold'
        );
        require(quorumVotesBPS_ >= MIN_QUORUM_VOTES_BPS && quorumVotesBPS_ <= MAX_QUORUM_VOTES_BPS,
            'initialize: invalid proposal threshold'
        );
        timelock = IHddenTreasury(_timelock);
        hddentoken = IHddenToken(_hddentoken);
        vetoer = vetoer_;
        votingDelay = votingDelay_;
        votingPeriod = votingPeriod_;
        proposalThresholdBPS = proposalThresholdBPS_;
        quorumVotesBPS = quorumVotesBPS_;
    }

    struct ProposalTemp {
        uint256 totalSupply;
        uint256 proposalThreshold;
        uint256 latestProposalId;
        uint256 startBlock;
        uint256 endBlock;
    }

    function propose(address[] memory targets,
                     uint256[] memory values,
                     string[] memory signatures,
                     bytes[] memory calldatas,
                     string memory description
                 )  public returns(uint256) {
                    ProposalTemp memory temp;
                    temp.totalSupply = hddentoken.totalSupply();
                    temp.proposalThreshold = bps2Uint(proposalThresholdBPS, temp.totalSupply);
        require(hddentoken.getPriorVotes(msg.sender, block.number - 1) > temp.proposalThreshold, "Proposer Votes Below threshold");
        require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "Proposal function arity mismatch");
        require(targets.length != 0, "Must Provide Actions");
        require(targets.length <= proposalMaxOperations, "Too many Actions");

        temp.latestProposalId = latestProposalIds[msg.sender];
        if(temp.latestProposalId != 0 ) {
            ProposalState proposersLatestProposalState = state(temp.latestProposalId);
            require(proposersLatestProposalState != ProposalState.Active, "One Live proposal per proposer");
            require(proposersLatestProposalState != ProposalState.Pending, "Found an already pending proposal");

        }
        temp.startBlock = block.number + votingDelay;
        temp.endBlock = block.number + votingPeriod;

        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];

        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.proposalThreshold = temp.proposalThreshold;
        newProposal.quoromVotes = bps2Uint(quorumVotesBPS, temp.totalSupply);
        newProposal.eta = 0;
        newProposal.targets = targets;
        newProposal.values = values;
        newProposal.signatures = signatures;
        newProposal.calldatas = calldatas;
        newProposal.startBlock = temp.startBlock;
        newProposal.endBlock = temp.endBlock;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.abstainVotes = 0;
        newProposal.canceled = false;
        newProposal.executed = false;
        newProposal.vetoed = false;

        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(
            newProposal.id,
            msg.sender,
            targets,
            values,
            signatures,
            calldatas,
            newProposal.startBlock,
            newProposal.endBlock,
            description
        );

        emit ProposalCreatedWithRequirements(newProposal.id, msg.sender, targets, values, signatures, calldatas, newProposal.startBlock, newProposal.endBlock, newProposal.proposalThreshold, newProposal.quoromVotes, description);

        return newProposal.id;

    }
    
    function queue(uint256 proposalId) external {
        require(state(proposalId) == ProposalState.Succeeded, "proposal can only be queued if it is succeeded");
        Proposal storage proposal = proposals[proposalId];
        uint256 eta = block.timestamp + timelock.delay();
        for(uint256 i = 0; i < proposal.targets.length; i++) {
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
    function queueOrRevertInternal(address target, uint256 value, string memory signature, bytes memory data, uint256 eta) internal {
        require(!timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))), "Identical Proposal at Queue");
        timelock.queueTransaction(target, value, signature, data, eta);
    }
    function execute(uint256 proposalId) external {
        require(state(proposalId) == ProposalState.Queued, "Proposal can be executed if queued");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for(uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }
        emit ProposalExecuted(proposalId);

    }
    function cancel(uint256 proposalId) external {
        require(state(proposalId) != ProposalState.Executed, ':cancel: cannot cancel executed proposal');
        Proposal storage proposal = proposals[proposalId];
        require(msg.sender == proposal.proposer || hddentoken.getPriorVotes(proposal.proposer, block.number - 1) < proposal.proposalThreshold, "cancel: proposer above threshold");
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
    function veto(uint256 proposalId) external {
        require(vetoer != address(0), "Veto Power Burned");
        require(msg.sender == vetoer, "Only Vetoer");
        require(state(proposalId) != ProposalState.Executed, "Veto: cannot veto executed Proposal");

        Proposal storage proposal = proposals[proposalId];

        proposal.vetoed = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        emit ProposalVetoed(proposalId);

    }
    function getActions(uint256 proposalId) external view returns(address[] memory targets, uint256[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }
    function getReceipt(uint256 proposalId, address voter) external view returns (Receipt memory) {
        return (proposals[proposalId].receipts[voter]);
    }
    function state(uint256 proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId, "Invalid Proposal Id");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.vetoed) {
            return ProposalState.Vetoed;
        } else if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if(block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if(block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if(proposal.forVotes <= proposal.againstVotes || proposal.forVotes < proposal.quoromVotes) {
            return ProposalState.Defeated;
        } else if(proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= proposal.eta + timelock.GRACE_PERIOD()) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }

    }
    function castVote(uint256 proposalId, uint8 support) external {
        emit VoteCast(msg.sender, proposalId, support, castVoteInternal(msg.sender, proposalId, support), "");
    }
    function castVoteWithReason(uint256 proposalId, uint8 support, string calldata reason) external {
        emit VoteCast(msg.sender, proposalId, support, castVoteInternal(msg.sender, proposalId, support), reason);
    }
    function castVoteBySig(uint256 proposalId, uint8 support, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainIdInternal(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), 'NounsDAO::castVoteBySig: invalid signature');
        emit VoteCast(signatory, proposalId, support, castVoteInternal(signatory, proposalId, support), '');

    }
    function castVoteInternal(address voter, uint256 proposalId, uint8 support) internal returns(uint96) {
        require(state(proposalId) == ProposalState.Active, "vOTING IS CLOSED");
        require(support <= 2, "Invalid vote type");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "Voter Already Voted");

        uint96 votes = hddentoken.getPriorVotes(voter, proposal.startBlock - votingDelay);

        if(support == 0) {
            proposal.againstVotes = proposal.againstVotes + votes;
        } else if(support == 1) {
            proposal.forVotes = proposal.forVotes + votes;
        } else if(support == 2) {
            proposal.abstainVotes = proposal.abstainVotes + votes;
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        return votes;

    }
    function _setVotingDelay(uint256 newVotingDelay) external {
        require(msg.sender == admin, '_setVotingDelay: admin only');
        require(
            newVotingDelay >= MIN_VOTING_DELAY && newVotingDelay <= MAX_VOTING_DELAY,
            '_setVotingDelay: invalid voting delay'
        );
        uint256 oldVotingDelay = votingDelay;
        votingDelay = newVotingDelay;

        emit VotingDelaySet(oldVotingDelay, votingDelay);
    }
    function _setVotingPeriod(uint256 newVotingPeriod) external {
        require(msg.sender == admin, '_setVotingPeriod: admin only');
        require(
            newVotingPeriod >= MIN_VOTING_PERIOD && newVotingPeriod <= MAX_VOTING_PERIOD,
            '_setVotingPeriod: invalid voting period'
        );
        uint256 oldVotingPeriod = votingPeriod;
        votingPeriod = newVotingPeriod;

        emit VotingPeriodSet(oldVotingPeriod, votingPeriod);
    }
    function _setProposalThresholdBPS(uint256 newProposalThresholdBPS) external {
        require(msg.sender == admin, '_setProposalThresholdBPS: admin only');
        require(
            newProposalThresholdBPS >= MIN_PROPOSAL_THRESHOLD_BPS &&
                newProposalThresholdBPS <= MAX_PROPOSAL_THRESHOLD_BPS,
            '_setProposalThreshold: invalid proposal threshold'
        );
        uint256 oldProposalThresholdBPS = proposalThresholdBPS;
        proposalThresholdBPS = newProposalThresholdBPS;

        emit ProposalThresholdBPSSet(oldProposalThresholdBPS, proposalThresholdBPS);
    }
    function _setQuorumVotesBPS(uint256 newQuorumVotesBPS) external {
        require(msg.sender == admin, 'setQuorumVotesBPS: admin only');
        require(
            newQuorumVotesBPS >= MIN_QUORUM_VOTES_BPS && newQuorumVotesBPS <= MAX_QUORUM_VOTES_BPS,
            '_setProposalThreshold: invalid proposal threshold'
        );
        uint256 oldQuorumVotesBPS = quorumVotesBPS;
        quorumVotesBPS = newQuorumVotesBPS;

        emit QuorumVotesBPSSet(oldQuorumVotesBPS, quorumVotesBPS);
    }
    function _setPendingAdmin(address newPendingAdmin) external {
        require(msg.sender == admin, "Admin only");
        address oldPendingAdmin = pendingAdmin;

        pendingAdmin = newPendingAdmin;
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }
    function _acceptAdmin() external {
        require(msg.sender == pendingAdmin && msg.sender != address(0), "pending admin only");
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        admin = pendingAdmin;

        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }
    function _setVetoer(address newVetoer) public {
        require(msg.sender == vetoer, "setVetoer: vetoer only");
        emit NewVetoer(vetoer, newVetoer);
        vetoer = newVetoer;
    }
    function _burnVetoPower() public {
        require(msg.sender == vetoer, "Burn VETO power: vetoer only");
        _setVetoer(address(0));

    }
    function proposalThreshold() public view returns (uint256) {
        return bps2Uint(proposalThresholdBPS, hddentoken.totalSupply());
    }
    function quorumVotes() public view returns (uint256) {
        return bps2Uint(quorumVotesBPS, hddentoken.totalSupply());
    }
    function bps2Uint(uint256 bps, uint256 number) internal pure returns (uint256) {
        return (number * bps) / 10000;
    }
    
    function getChainIdInternal() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}