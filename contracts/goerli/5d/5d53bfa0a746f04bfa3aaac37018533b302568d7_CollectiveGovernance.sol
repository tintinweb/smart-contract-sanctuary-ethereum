// SPDX-License-Identifier: BSD-3-Clause
/*
 * Copyright 2022 collective.xyz
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

import "../contracts/Storage.sol";
import "../contracts/GovernanceStorage.sol";
import "../contracts/Governance.sol";
import "../contracts/VoteStrategy.sol";

/// @title CollectiveGovernance
// factory contract for governance
contract CollectiveGovernance is Governance, VoteStrategy {
    /// @notice contract name
    string public constant name = "collective.xyz governance";
    uint32 public constant VERSION_1 = 1;

    Storage private _storage;

    /// @notice voting is open or not
    mapping(uint256 => bool) isVoteOpenByProposalId;

    address[] _projectSupervisorList = new address[](1);

    modifier requireStrategyVersion(uint256 _proposalId) {
        address strategy = _storage.voteStrategy(_proposalId);
        require(address(this) == strategy, "Strategy not valid for this proposalId");
        _;
    }

    modifier requireVoteOpen(uint256 _proposalId) {
        require(
            _storage.isReady(_proposalId) && isVoteOpenByProposalId[_proposalId] && !_storage.isVeto(_proposalId),
            "Voting is closed."
        );
        _;
    }

    modifier requireVoteReady(uint256 _proposalId) {
        require(_storage.isReady(_proposalId) && !_storage.isVeto(_proposalId), "Voting is not ready.");
        _;
    }

    modifier requireVoteClosed(uint256 _proposalId) {
        require(
            _storage.isReady(_proposalId) && !isVoteOpenByProposalId[_proposalId] && !_storage.isVeto(_proposalId),
            "Voting is not closed."
        );
        _;
    }

    modifier requireVoter(uint256 _proposalId, address _wallet) {
        require(_storage.isVoter(_proposalId, _wallet), "Voting interest required");
        _;
    }

    modifier requireElectorSupervisor(uint256 _proposalId) {
        require(_storage.isSupervisor(_proposalId, msg.sender), "Elector supervisor required");
        _;
    }

    constructor() {
        _storage = new GovernanceStorage();
        _projectSupervisorList[0] = address(this);
    }

    function version() public pure virtual returns (uint32) {
        return VERSION_1;
    }

    function getStorageAddress() external view returns (address) {
        return address(_storage);
    }

    function propose() external returns (uint256) {
        address owner = msg.sender;
        uint256 proposalId = _storage._initializeProposal(address(this));
        _storage.registerSupervisor(proposalId, owner);
        for (uint256 i = 0; i < _projectSupervisorList.length; i++) {
            _storage.registerSupervisor(proposalId, _projectSupervisorList[i]);
        }
        emit ProposalCreated(owner, proposalId);
        return proposalId;
    }

    function configure(
        uint256 _proposalId,
        uint256 _quorumThreshold,
        address _erc721,
        uint256 _requiredDuration
    ) external requireElectorSupervisor(_proposalId) {
        _storage.setQuorumThreshold(_proposalId, _quorumThreshold);
        _storage.setRequiredVoteDuration(_proposalId, _requiredDuration);
        _storage.registerVoterClassERC721(_proposalId, _erc721);
        _storage.makeReady(_proposalId);
        this.openVote(_proposalId);
        emit ProposalOpen(_proposalId);
    }

    /// @notice allow voting
    function openVote(uint256 _proposalId)
        public
        requireStrategyVersion(_proposalId)
        requireElectorSupervisor(_proposalId)
        requireVoteReady(_proposalId)
    {
        _storage._validOrRevert(_proposalId);
        require(_storage.quorumRequired(_proposalId) < _storage._maxPassThreshold(), "Quorum must be set prior to opening vote");
        if (!isVoteOpenByProposalId[_proposalId]) {
            isVoteOpenByProposalId[_proposalId] = true;
            emit VoteOpen(_proposalId);
        } else {
            revert("Already open.");
        }
    }

    function isOpen(uint256 _proposalId) public view requireStrategyVersion(_proposalId) returns (bool) {
        _storage._validOrRevert(_proposalId);
        uint256 endBlock = _storage.endBlock(_proposalId);
        return isVoteOpenByProposalId[_proposalId] && block.number < endBlock;
    }

    /// @notice forbid any further voting
    function endVote(uint256 _proposalId)
        public
        requireStrategyVersion(_proposalId)
        requireElectorSupervisor(_proposalId)
        requireVoteOpen(_proposalId)
    {
        _storage._validOrRevert(_proposalId);
        if (!_storage.isReady(_proposalId)) {
            _storage.makeReady(_proposalId);
        }
        uint256 _endBlock = _storage.endBlock(_proposalId);
        require(_endBlock < block.number, "Voting remains active");
        isVoteOpenByProposalId[_proposalId] = false;
        emit VoteClosed(_proposalId);
        emit ProposalClosed(_proposalId);
    }

    /// @notice veto the current measure
    function veto(uint256 _proposalId)
        public
        requireStrategyVersion(_proposalId)
        requireElectorSupervisor(_proposalId)
        requireVoteOpen(_proposalId)
    {
        _storage._veto(_proposalId);
    }

    // @notice cast an affirmative vote for the measure
    function voteFor(uint256 _proposalId)
        public
        requireStrategyVersion(_proposalId)
        requireVoter(_proposalId, msg.sender)
        requireVoteOpen(_proposalId)
    {
        _storage._castVoteFor(_proposalId, msg.sender);
    }

    // @notice undo any previous vote
    function undoVote(uint256 _proposalId)
        public
        requireStrategyVersion(_proposalId)
        requireVoter(_proposalId, msg.sender)
        requireVoteOpen(_proposalId)
    {
        _storage._castVoteUndo(_proposalId, msg.sender);
    }

    function voteAgainst(uint256 _proposalId)
        public
        requireStrategyVersion(_proposalId)
        requireVoter(_proposalId, msg.sender)
        requireVoteOpen(_proposalId)
    {
        _storage._castVoteAgainst(_proposalId, msg.sender);
    }

    function abstainFromVote(uint256 _proposalId)
        public
        requireStrategyVersion(_proposalId)
        requireVoter(_proposalId, msg.sender)
        requireVoteOpen(_proposalId)
    {
        _storage._abstainFromVote(_proposalId, msg.sender);
    }

    /// @notice get the result of the measure pass or failed
    function getVoteSucceeded(uint256 _proposalId)
        public
        view
        requireStrategyVersion(_proposalId)
        requireVoteClosed(_proposalId)
        returns (bool)
    {
        _storage._validOrRevert(_proposalId);
        uint256 totalVotesCast = _storage.quorum(_proposalId);
        require(totalVotesCast >= _storage.quorumRequired(_proposalId), "Not enough participants");
        return _storage.forVotes(_proposalId) > _storage.againstVotes(_proposalId);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 * Copyright 2022 collective.xyz
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

import "../contracts/VoterClass.sol";
import "../contracts/VoteStrategy.sol";

/// @title Storage
/// governance storage for the Proposal struct
interface Storage {
    // event section
    event InitializeProposal(uint256 proposalId, address owner);
    event AddSupervisor(uint256 proposalId, address supervisor);
    event BurnSupervisor(uint256 proposalId, address supervisor);
    event RegisterVoter(uint256 proposalId, address voter);
    event BurnVoter(uint256 proposalId, address voter);
    event RegisterVoterClassOpenVote(uint256 proposalId);
    event RegisterVoterClassERC721(uint256 proposalId, address token);
    event BurnVoterClass(uint256 proposalId);
    event SetQuorumThreshold(uint256 proposalId, uint256 passThreshold);
    event UndoVoteEnabled(uint256 proposalId);

    event VoteCast(uint256 proposalId, address voter, uint256 totalVotesCast);
    event UndoVote(uint256 proposalId, address voter, uint256 votesUndone);
    event VoteVeto(uint256 proposalId, address supervisor);
    event VoteReady(uint256 proposalId, uint256 startBlock, uint256 endBlock);

    struct Proposal {
        /// @notice Unique id for looking up a proposal
        uint256 id;
        /// @notice Creator of the proposal
        address proposalSender;
        /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
        uint256 quorumRequired;
        /// @notice The number of blocks to delay the first vote from voting open
        uint256 voteDelay;
        /// @notice The number of blocks duration for the vote, last vote must be cast prior
        uint256 voteDuration;
        /// @notice The block at which voting begins
        uint256 startBlock;
        /// @notice The block at which voting ends
        uint256 endBlock;
        /// @notice Current number of votes in favor of this proposal
        uint256 forVotes;
        /// @notice Current number of votes in opposition to this proposal
        uint256 againstVotes;
        /// @notice Current number of votes for abstaining for this proposal
        uint256 abstentionCount;
        /// @notice Flag marking whether the proposal has been vetoed
        bool isVeto;
        /// @notice Flag marking whether the proposal has been executed
        bool isExecuted;
        /// @notice construction phase, voting is not yet open or closed
        bool isReady;
        /// @notice this proposal allows undo votes
        bool isUndoEnabled;
        /// @notice general voter class enabled for this vote
        VoterClass voterClass;
        /// @notice Strategy applied to this proposal
        address voteStrategy;
        /// @notice Receipts of ballots for the entire set of voters
        mapping(address => Receipt) voteReceipt;
        /// @notice configured supervisors
        mapping(address => bool) supervisorPool;
        /// @notice whitelisted voters
        mapping(address => bool) voterPool;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice number of votes cast for
        uint256 votedFor;
        /// @notice The number of votes the voter had, which were cast
        uint256 votesCast;
        /// @notice mapping of tokens voted
        mapping(uint256 => bool) tokenVoted;
    }

    function name() external pure returns (string memory);

    function version() external pure returns (uint32);

    function registerSupervisor(uint256 _proposalId, address _supervisor) external;

    function burnSupervisor(uint256 _proposalId, address _supervisor) external;

    function registerVoter(uint256 _proposalId, address _voter) external;

    function registerVoters(uint256 _proposalId, address[] memory _voter) external;

    function burnVoter(uint256 _proposalId, address _voter) external;

    function registerVoterClassERC721(uint256 _proposalId, address token) external;

    function registerVoterClassOpenVote(uint256 _proposalId) external;

    function burnVoterClass(uint256 _proposalId) external;

    function setQuorumThreshold(uint256 _proposalId, uint256 _passThreshold) external;

    function setVoteDelay(uint256 _proposalId, uint256 _voteDelay) external;

    function setRequiredVoteDuration(uint256 _proposalId, uint256 _voteDuration) external;

    function enableUndoVote(uint256 _proposalId) external;

    function makeReady(uint256 _proposalId) external;

    function isSupervisor(uint256 _proposalId, address _supervisor) external returns (bool);

    function isVoter(uint256 _proposalId, address _voter) external returns (bool);

    function isReady(uint256 _proposalId) external view returns (bool);

    function isVeto(uint256 _proposalId) external view returns (bool);

    function getSender(uint256 _proposalId) external view returns (address);

    function quorumRequired(uint256 _proposalId) external view returns (uint256);

    function voteDelay(uint256 _proposalId) external view returns (uint256);

    function voteDuration(uint256 _proposalId) external view returns (uint256);

    function startBlock(uint256 _proposalId) external view returns (uint256);

    function endBlock(uint256 _proposalId) external view returns (uint256);

    function forVotes(uint256 _proposalId) external view returns (uint256);

    function againstVotes(uint256 _proposalId) external view returns (uint256);

    function abstentionCount(uint256 _proposalId) external view returns (uint256);

    function quorum(uint256 _proposalId) external view returns (uint256);

    function voteStrategy(uint256 _proposalId) external view returns (address);

    function _initializeProposal(address _strategy) external returns (uint256);

    function _castVoteFor(uint256 _proposalId, address wallet) external;

    function _castVoteUndo(uint256 _proposalId, address wallet) external;

    function _castVoteAgainst(uint256 _proposalId, address wallet) external;

    function _abstainFromVote(uint256 _proposalId, address wallet) external;

    function _veto(uint256 _proposalId) external;

    function _validOrRevert(uint256 _proposalId) external view;

    function _maxPassThreshold() external pure returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 * Copyright 2022 collective.xyz
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

import "../contracts/Storage.sol";
import "../contracts/VoterClassERC721.sol";
import "../contracts/VoterClassOpenVote.sol";

contract GovernanceStorage is Storage {
    /// @notice contract name
    string public constant name = "collective.xyz governance storage";
    uint32 public constant VERSION_1 = 1;

    uint256 public constant MAXIMUM_QUORUM = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 public constant MINIMUM_VOTE_DURATION = 1;

    /// @notice global list of proposed issues by id
    mapping(uint256 => Proposal) public proposalMap;

    /// @notice The total number of proposals
    uint256 internal _proposalCount;

    /// @notice The latest proposal for each proposer
    mapping(address => uint256) internal _latestProposalId;

    modifier requireValidAddress(address _wallet) {
        require(_wallet != address(0), "Not a valid wallet");
        _;
    }

    modifier requireValidProposal(uint256 _proposalId) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(
            _proposalId > 0 && _proposalId <= _proposalCount && proposal.id == _proposalId && !proposal.isVeto,
            "Invalid proposal"
        );
        _;
    }

    modifier requireProposalSender(uint256 _proposalId) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(proposal.proposalSender == msg.sender, "Not proposal creator");
        _;
    }

    modifier requireStrategy(uint256 _proposalId) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(proposal.voteStrategy == msg.sender, "Vote with VoteStrategy");
        _;
    }

    modifier requireElectorSupervisor(uint256 _proposalId) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(proposal.supervisorPool[msg.sender], "Operation requires elector supervisor");
        _;
    }

    modifier requireVoter(uint256 _proposalId, address _wallet) {
        Proposal storage proposal = proposalMap[_proposalId];
        bool isRegistered = proposal.voterPool[_wallet];
        bool isPartOfClass = proposal.voterClass.isVoter(_wallet);
        require(isRegistered || isPartOfClass, "Voter required");
        _;
    }

    modifier requireVotingNotReady(uint256 _proposalId) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(!proposal.isReady, "Vote not modifiable");
        _;
    }

    modifier requireVotingReady(uint256 _proposalId) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(proposal.isReady, "Vote not ready");
        _;
    }

    modifier requireVotingActive(uint256 _proposalId) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(proposal.startBlock >= block.number && proposal.endBlock > block.number, "Vote not active");
        _;
    }

    modifier requireUndo(uint256 _proposalId) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(proposal.isUndoEnabled, "Undo not enabled for this vote");
        _;
    }

    /// @notice initialize a proposal and return the id
    function _initializeProposal(address _strategy) external returns (uint256) {
        address owner = msg.sender;

        uint256 latestProposalId = _latestProposalId[owner];
        if (latestProposalId != 0) {
            Proposal storage latestProposal = proposalMap[latestProposalId];
            require(!latestProposal.isReady, "Too many proposals in process");
        }
        _proposalCount++;
        uint256 proposalId = _proposalCount;
        _latestProposalId[owner] = proposalId;

        // proposal
        Proposal storage proposal = proposalMap[proposalId];
        proposal.id = proposalId;
        proposal.proposalSender = owner;
        proposal.quorumRequired = MAXIMUM_QUORUM;
        proposal.voteDelay = 0;
        proposal.voteDuration = MINIMUM_VOTE_DURATION;
        proposal.startBlock = 0;
        proposal.endBlock = 0;
        proposal.forVotes = 0;
        proposal.againstVotes = 0;
        proposal.abstentionCount = 0;
        proposal.isVeto = false;
        proposal.isReady = false;
        proposal.isUndoEnabled = false;
        proposal.voterClass = new VoterClassNullObject();
        proposal.voteStrategy = _strategy;

        emit InitializeProposal(proposalId, owner);
        return proposalId;
    }

    /// @notice add a vote superviser to the supervisor pool with rights to add or remove voters prior to start of voting, also right to veto the outcome after voting is closed
    function registerSupervisor(uint256 _proposalId, address _supervisor)
        public
        requireValidAddress(_supervisor)
        requireValidProposal(_proposalId)
        requireProposalSender(_proposalId)
        requireVotingNotReady(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        if (!proposal.supervisorPool[_supervisor]) {
            proposal.supervisorPool[_supervisor] = true;
            emit AddSupervisor(_proposalId, _supervisor);
        }
    }

    /// @notice remove the supervisor from the supervisor pool suspending their rights to modify the election
    function burnSupervisor(uint256 _proposalId, address _supervisor)
        public
        requireValidAddress(_supervisor)
        requireValidProposal(_proposalId)
        requireProposalSender(_proposalId)
        requireVotingNotReady(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        if (proposal.supervisorPool[_supervisor]) {
            proposal.supervisorPool[_supervisor] = false;
            emit BurnSupervisor(_proposalId, _supervisor);
        }
    }

    /// @notice enable vote undo feature
    function enableUndoVote(uint256 _proposalId)
        public
        requireValidProposal(_proposalId)
        requireElectorSupervisor(_proposalId)
        requireVotingNotReady(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        proposal.isUndoEnabled = true;
        emit UndoVoteEnabled(_proposalId);
    }

    /// @notice register a voter on this measure
    function registerVoter(uint256 _proposalId, address _voter)
        public
        requireValidAddress(_voter)
        requireValidProposal(_proposalId)
        requireElectorSupervisor(_proposalId)
        requireVotingNotReady(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        if (!proposal.voterPool[_voter]) {
            proposal.voterPool[_voter] = true;
            emit RegisterVoter(_proposalId, _voter);
        } else {
            revert("Voter registered previously");
        }
    }

    /// @notice register a list of voters on this measure
    function registerVoters(uint256 _proposalId, address[] memory _voter)
        public
        requireValidProposal(_proposalId)
        requireElectorSupervisor(_proposalId)
        requireVotingNotReady(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        uint256 addedCount = 0;
        for (uint256 i = 0; i < _voter.length; i++) {
            if (_voter[i] != address(0) && !proposal.voterPool[_voter[i]]) {
                proposal.voterPool[_voter[i]] = true;
                emit RegisterVoter(_proposalId, _voter[i]);
            }
            addedCount++;
        }
    }

    /// @notice burn the specified voter, removing their rights to participate in the election
    function burnVoter(uint256 _proposalId, address _voter)
        public
        requireValidAddress(_voter)
        requireValidProposal(_proposalId)
        requireElectorSupervisor(_proposalId)
        requireVotingNotReady(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        if (proposal.voterPool[_voter]) {
            proposal.voterPool[_voter] = false;
            emit BurnVoter(_proposalId, _voter);
        }
    }

    /// @notice register a voting class for this measure
    function registerVoterClassERC721(uint256 _proposalId, address _token)
        public
        requireValidAddress(_token)
        requireValidProposal(_proposalId)
        requireElectorSupervisor(_proposalId)
        requireVotingNotReady(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        proposal.voterClass = new VoterClassERC721(_token);
        emit RegisterVoterClassERC721(_proposalId, _token);
    }

    /// @notice register a voting class for this measure
    function registerVoterClassOpenVote(uint256 _proposalId)
        public
        requireValidProposal(_proposalId)
        requireElectorSupervisor(_proposalId)
        requireVotingNotReady(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        proposal.voterClass = new VoterClassOpenVote();
        emit RegisterVoterClassOpenVote(_proposalId);
    }

    /// @notice burn voter class
    function burnVoterClass(uint256 _proposalId)
        public
        requireValidProposal(_proposalId)
        requireElectorSupervisor(_proposalId)
        requireVotingNotReady(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        proposal.voterClass = new VoterClassNullObject();
        emit BurnVoterClass(_proposalId);
    }

    /// @notice establish the pass threshold for this measure
    function setQuorumThreshold(uint256 _proposalId, uint256 _passThreshold)
        public
        requireValidProposal(_proposalId)
        requireElectorSupervisor(_proposalId)
        requireVotingNotReady(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        proposal.quorumRequired = _passThreshold;
        emit SetQuorumThreshold(_proposalId, _passThreshold);
    }

    function setVoteDelay(uint256 _proposalId, uint256 _voteDelay)
        public
        requireValidProposal(_proposalId)
        requireElectorSupervisor(_proposalId)
        requireVotingNotReady(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        proposal.voteDelay = _voteDelay;
    }

    function setRequiredVoteDuration(uint256 _proposalId, uint256 _voteDuration)
        public
        requireValidProposal(_proposalId)
        requireElectorSupervisor(_proposalId)
        requireVotingNotReady(_proposalId)
    {
        require(_voteDuration >= MINIMUM_VOTE_DURATION, "Voting duration is not valid");
        Proposal storage proposal = proposalMap[_proposalId];
        proposal.voteDuration = _voteDuration;
    }

    function getSender(uint256 _proposalId) external view requireValidProposal(_proposalId) returns (address) {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.proposalSender;
    }

    function quorumRequired(uint256 _proposalId) external view requireValidProposal(_proposalId) returns (uint256) {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.quorumRequired;
    }

    function forVotes(uint256 _proposalId) external view requireValidProposal(_proposalId) returns (uint256) {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.forVotes;
    }

    function againstVotes(uint256 _proposalId) external view requireValidProposal(_proposalId) returns (uint256) {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.againstVotes;
    }

    function abstentionCount(uint256 _proposalId) external view requireValidProposal(_proposalId) returns (uint256) {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.abstentionCount;
    }

    function quorum(uint256 _proposalId) external view requireValidProposal(_proposalId) returns (uint256) {
        return this.forVotes(_proposalId) + this.againstVotes(_proposalId) + this.abstentionCount(_proposalId);
    }

    function isSupervisor(uint256 _proposalId, address _supervisor)
        external
        view
        requireValidAddress(_supervisor)
        requireValidProposal(_proposalId)
        returns (bool)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.supervisorPool[_supervisor];
    }

    function isVoter(uint256 _proposalId, address _voter)
        external
        view
        requireValidAddress(_voter)
        requireValidProposal(_proposalId)
        returns (bool)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.voterPool[_voter] || proposal.voterClass.isVoter(_voter);
    }

    function isVeto(uint256 _proposalId) external view returns (bool) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(_proposalId > 0 && _proposalId <= _proposalCount, "Unknown proposal");
        return proposal.isVeto;
    }

    function makeReady(uint256 _proposalId) external requireElectorSupervisor(_proposalId) requireVotingNotReady(_proposalId) {
        Proposal storage proposal = proposalMap[_proposalId];
        proposal.isReady = true;
        proposal.startBlock = block.number + proposal.voteDelay;
        proposal.endBlock = proposal.startBlock + proposal.voteDuration;
        emit VoteReady(_proposalId, proposal.startBlock, proposal.endBlock);
    }

    /// @notice true if proposal is in setup phase
    function isReady(uint256 _proposalId) external view requireValidProposal(_proposalId) returns (bool) {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.isReady;
    }

    /// @notice veto the current measure
    function _veto(uint256 _proposalId) public requireValidProposal(_proposalId) requireElectorSupervisor(_proposalId) {
        Proposal storage proposal = proposalMap[_proposalId];
        if (!proposal.isVeto) {
            proposal.isVeto = true;
            emit VoteVeto(_proposalId, msg.sender);
        } else {
            revert("Double veto");
        }
    }

    /* @notice cast vote affirmative */
    function _castVoteFor(uint256 _proposalId, address _wallet)
        public
        requireValidProposal(_proposalId)
        requireStrategy(_proposalId)
        requireVoter(_proposalId, _wallet)
        requireVotingActive(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        uint256 votesAvailable = 1;
        if (proposal.voterClass.isVoter(_wallet)) {
            votesAvailable = proposal.voterClass.votesAvailable(_wallet);
        }
        Receipt storage receipt = proposal.voteReceipt[_wallet];
        if (receipt.votesCast < votesAvailable) {
            uint256 remainingVotes = votesAvailable - receipt.votesCast;
            receipt.votesCast += remainingVotes;
            receipt.votedFor += remainingVotes;
            proposal.forVotes += remainingVotes;
            emit VoteCast(_proposalId, _wallet, remainingVotes);
        } else {
            revert("Vote cast previously on this measure");
        }
    }

    /* @notice cast vote negative */
    function _castVoteAgainst(uint256 _proposalId, address _wallet)
        public
        requireValidProposal(_proposalId)
        requireStrategy(_proposalId)
        requireVoter(_proposalId, _wallet)
        requireVotingActive(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        uint256 votesAvailable = 1;
        if (proposal.voterClass.isVoter(_wallet)) {
            votesAvailable = proposal.voterClass.votesAvailable(_wallet);
        }
        Receipt storage receipt = proposal.voteReceipt[_wallet];
        if (receipt.votesCast < votesAvailable) {
            uint256 remainingVotes = votesAvailable - receipt.votesCast;
            receipt.votesCast += remainingVotes;
            proposal.againstVotes += remainingVotes;
            emit VoteCast(_proposalId, _wallet, remainingVotes);
        } else {
            revert("Vote cast previously on this measure");
        }
    }

    /* @notice cast vote Undo */
    function _castVoteUndo(uint256 _proposalId, address _wallet)
        public
        requireValidProposal(_proposalId)
        requireStrategy(_proposalId)
        requireVoter(_proposalId, _wallet)
        requireUndo(_proposalId)
        requireVotingActive(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        Receipt storage receipt = proposal.voteReceipt[_wallet];
        if (receipt.votedFor > 0) {
            uint256 undoVotes = receipt.votedFor;
            receipt.votedFor -= undoVotes;
            receipt.votesCast -= undoVotes;
            proposal.forVotes -= undoVotes;
            emit UndoVote(_proposalId, _wallet, undoVotes);
        } else {
            revert("Nothing to undo");
        }
    }

    /* @notice mark abstention */
    function _abstainFromVote(uint256 _proposalId, address _wallet)
        public
        requireValidProposal(_proposalId)
        requireStrategy(_proposalId)
        requireVoter(_proposalId, _wallet)
        requireVotingActive(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        uint256 votesAvailable = 1;
        if (proposal.voterClass.isVoter(_wallet)) {
            votesAvailable = proposal.voterClass.votesAvailable(_wallet);
        }
        Receipt storage receipt = proposal.voteReceipt[_wallet];
        if (receipt.votesCast < votesAvailable) {
            uint256 remainingVotes = votesAvailable - receipt.votesCast;
            receipt.votesCast += remainingVotes;
            proposal.abstentionCount += remainingVotes;
            emit VoteCast(_proposalId, _wallet, remainingVotes);
        } else {
            revert("Vote cast previously on this measure");
        }
    }

    function voteDelay(uint256 _proposalId) external view requireValidProposal(_proposalId) returns (uint256) {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.voteDelay;
    }

    function voteDuration(uint256 _proposalId) external view requireValidProposal(_proposalId) returns (uint256) {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.voteDuration;
    }

    function startBlock(uint256 _proposalId) external view requireValidProposal(_proposalId) returns (uint256) {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.startBlock;
    }

    function endBlock(uint256 _proposalId) external view requireValidProposal(_proposalId) returns (uint256) {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.endBlock;
    }

    function voteStrategy(uint256 _proposalId) external view requireValidProposal(_proposalId) returns (address) {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.voteStrategy;
    }

    function version() public pure virtual returns (uint32) {
        return VERSION_1;
    }

    function _validOrRevert(uint256 _proposalId)
        external
        view
        requireValidProposal(_proposalId)
    // solium-disable-next-line no-empty-blocks
    {

    }

    function _maxPassThreshold() external pure returns (uint256) {
        return MAXIMUM_QUORUM;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 * Copyright 2022 collective.xyz
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

/// @title Governance
/// contract enables proposing a measure to be voted upon
interface Governance {
    event ProposalCreated(address proposer, uint256 proposalId);
    event ProposalOpen(uint256 proposalId);
    event ProposalClosed(uint256 proposalId);

    /// @notice propose a measurement of a vote class @returns proposal id
    function propose() external returns (uint256);

    function configure(
        uint256 proposalId,
        uint256 quorumThreshold,
        address erc721,
        uint256 requiredDuration
    ) external;

    function name() external pure returns (string memory);

    function version() external pure returns (uint32);

    function getStorageAddress() external view returns (address);
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 * Copyright 2022 collective.xyz
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

import "./VoterClass.sol";
import "./VoterClassNullObject.sol";

/// @title VoteStrategy
/// upgradable implementation of voting for Collective Governance
interface VoteStrategy {
    // event section
    event VoteOpen(uint256 proposalId);
    event VoteClosed(uint256 proposalId);

    function openVote(uint256 _proposalId) external;

    function endVote(uint256 _proposalId) external;

    function voteFor(uint256 _proposalId) external;

    function voteAgainst(uint256 _proposalId) external;

    function abstainFromVote(uint256 _proposalId) external;

    function undoVote(uint256 _proposalId) external;

    function veto(uint256 _proposalId) external;

    function getVoteSucceeded(uint256 _proposalId) external view returns (bool);

    function isOpen(uint256 _proposalId) external view returns (bool);
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 * Copyright 2022 collective.xyz
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

/// @notice Interface indicating membership in a voting class
interface VoterClass {
    function isVoter(address _wallet) external view returns (bool);

    function votesAvailable(address _wallet) external view returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 * Copyright 2022 collective.xyz
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "./VoterClass.sol";

/// @notice voting class for ERC-721 contract
contract VoterClassERC721 is VoterClass {
    address public _contractAddress;

    modifier requireValidAddress(address _wallet) {
        require(_wallet != address(0), "Not a valid wallet");
        _;
    }

    constructor(address _contract) {
        _contractAddress = _contract;
    }

    function isVoter(address _wallet) external view requireValidAddress(_wallet) returns (bool) {
        return IERC721(_contractAddress).balanceOf(_wallet) > 0;
    }

    function votesAvailable(address _wallet) external view requireValidAddress(_wallet) returns (uint256) {
        return IERC721(_contractAddress).balanceOf(_wallet);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 * Copyright 2022 collective.xyz
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

import "./VoterClass.sol";

/// @notice voting class to include every address
contract VoterClassOpenVote is VoterClass {
    modifier requireValidAddress(address _wallet) {
        require(_wallet != address(0), "Not a valid wallet");
        _;
    }

    function isVoter(address _wallet) external pure requireValidAddress(_wallet) returns (bool) {
        return true;
    }

    function votesAvailable(address _wallet) external pure requireValidAddress(_wallet) returns (uint256) {
        return 1;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 * Copyright 2022 collective.xyz
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;
import "./VoterClass.sol";

/// @notice voting class for ERC-721 contract
contract VoterClassNullObject is VoterClass {
    modifier requireValidAddress(address _wallet) {
        require(_wallet != address(0), "Not a valid wallet");
        _;
    }

    function isVoter(address _wallet) external pure requireValidAddress(_wallet) returns (bool) {
        return false;
    }

    function votesAvailable(address _wallet) external pure requireValidAddress(_wallet) returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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