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

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../contracts/Storage.sol";
import "../contracts/GovernanceStorage.sol";
import "../contracts/Governance.sol";
import "../contracts/VoteStrategy.sol";

/// @title CollectiveGovernance
// factory contract for governance
contract CollectiveGovernance is Governance, VoteStrategy, ERC165 {
    /// @notice contract name
    string public constant name = "collective.xyz governance";
    uint32 public constant VERSION_1 = 1;

    Storage public _storage;

    /// @notice voting is open or not
    mapping(uint256 => bool) isVoteOpenByProposalId;

    address[] _projectSupervisorList = new address[](1);

    constructor() {
        _storage = new GovernanceStorage();
        _projectSupervisorList[0] = address(this);
    }

    modifier requireVoteOpen(uint256 _proposalId) {
        require(_storage.isReady(_proposalId) && isVoteOpenByProposalId[_proposalId], "Voting is closed");
        _;
    }

    modifier requireNoVeto(uint256 _proposalId) {
        require(!_storage.isVeto(_proposalId), "Vote is veto");
        _;
    }

    modifier requireVoteReady(uint256 _proposalId) {
        require(_storage.isReady(_proposalId) && !_storage.isVeto(_proposalId), "Voting is not ready");
        _;
    }

    modifier requireVoteClosed(uint256 _proposalId) {
        require(
            _storage.isReady(_proposalId) && !isVoteOpenByProposalId[_proposalId] && !_storage.isVeto(_proposalId),
            "Voting is not closed"
        );
        _;
    }

    modifier requireElectorSupervisor(uint256 _proposalId) {
        require(_storage.isSupervisor(_proposalId, msg.sender), "Elector supervisor required");
        _;
    }

    function version() public pure virtual returns (uint32) {
        return VERSION_1;
    }

    function getStorageAddress() external view returns (address) {
        return address(_storage);
    }

    function propose() external returns (uint256) {
        address _sender = msg.sender;
        uint256 proposalId = _storage.initializeProposal(_sender);
        _storage.registerSupervisor(proposalId, _sender, _sender);
        for (uint256 i = 0; i < _projectSupervisorList.length; i++) {
            _storage.registerSupervisor(proposalId, _projectSupervisorList[i], _sender);
        }
        emit ProposalCreated(_sender, proposalId);
        return proposalId;
    }

    function configureTokenVoteERC721(
        uint256 _proposalId,
        uint256 _quorumThreshold,
        address _erc721,
        uint256 _requiredDuration
    ) external requireElectorSupervisor(_proposalId) {
        address _sender = msg.sender;
        _storage.setQuorumThreshold(_proposalId, _quorumThreshold, _sender);
        _storage.setRequiredVoteDuration(_proposalId, _requiredDuration, _sender);
        _storage.registerVoterClassERC721(_proposalId, _erc721, _sender);
        _storage.makeReady(_proposalId, _sender);
        this.openVote(_proposalId);
        emit ProposalOpen(_proposalId);
    }

    function configureOpenVote(
        uint256 _proposalId,
        uint256 _quorumThreshold,
        uint256 _requiredDuration
    ) external requireElectorSupervisor(_proposalId) {
        address _sender = msg.sender;
        _storage.setQuorumThreshold(_proposalId, _quorumThreshold, _sender);
        _storage.setRequiredVoteDuration(_proposalId, _requiredDuration, _sender);
        _storage.registerVoterClassOpenVote(_proposalId, _sender);
        _storage.makeReady(_proposalId, _sender);
        this.openVote(_proposalId);
        emit ProposalOpen(_proposalId);
    }

    /// @notice allow voting
    function openVote(uint256 _proposalId) public requireElectorSupervisor(_proposalId) requireVoteReady(_proposalId) {
        _storage.validOrRevert(_proposalId);
        require(_storage.quorumRequired(_proposalId) < _storage.maxPassThreshold(), "Quorum must be set prior to opening vote");
        if (!isVoteOpenByProposalId[_proposalId]) {
            isVoteOpenByProposalId[_proposalId] = true;
            emit VoteOpen(_proposalId);
        } else {
            revert("Already open");
        }
    }

    function isOpen(uint256 _proposalId) public view returns (bool) {
        _storage.validOrRevert(_proposalId);
        uint256 endBlock = _storage.endBlock(_proposalId);
        return isVoteOpenByProposalId[_proposalId] && block.number < endBlock;
    }

    /// @notice forbid any further voting
    function endVote(uint256 _proposalId) public requireElectorSupervisor(_proposalId) requireVoteOpen(_proposalId) {
        _storage.validOrRevert(_proposalId);
        if (!_storage.isReady(_proposalId)) {
            _storage.makeReady(_proposalId, msg.sender);
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
        requireElectorSupervisor(_proposalId)
        requireVoteOpen(_proposalId)
        requireNoVeto(_proposalId)
    {
        _storage.veto(_proposalId, msg.sender);
    }

    // @notice cast an affirmative vote for the measure
    function voteFor(uint256 _proposalId) public requireVoteOpen(_proposalId) requireNoVeto(_proposalId) {
        VoterClass _class = _storage.voterClass(_proposalId);
        uint256[] memory _shareList = _class.discover(msg.sender);
        uint256 count = 0;
        for (uint256 i = 0; i < _shareList.length; i++) {
            uint256 shareId = _shareList[i];
            count += _storage.voteForByShare(_proposalId, msg.sender, shareId);
        }
        if (count > 0) {
            emit VoteTally(_proposalId, msg.sender, count);
        } else {
            revert("Not voter");
        }
    }

    function voteForWithTokenId(uint256 _proposalId, uint256 _tokenId)
        public
        requireVoteOpen(_proposalId)
        requireNoVeto(_proposalId)
    {
        uint256 count = _storage.voteForByShare(_proposalId, msg.sender, _tokenId);
        if (count > 0) {
            emit VoteTally(_proposalId, msg.sender, count);
        } else {
            revert("Not voter");
        }
    }

    function voteForWithTokenList(uint256 _proposalId, uint256[] memory _tokenIdList)
        external
        requireVoteOpen(_proposalId)
        requireNoVeto(_proposalId)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < _tokenIdList.length; i++) {
            count += _storage.voteForByShare(_proposalId, msg.sender, _tokenIdList[i]);
        }
        if (count > 0) {
            emit VoteTally(_proposalId, msg.sender, count);
        } else {
            revert("Not voter");
        }
    }

    // @notice undo any previous vote
    function undoVote(uint256 _proposalId) public requireVoteOpen(_proposalId) requireNoVeto(_proposalId) {
        VoterClass _class = _storage.voterClass(_proposalId);
        uint256[] memory _shareList = _class.discover(msg.sender);
        uint256 count = 0;
        for (uint256 i = 0; i < _shareList.length; i++) {
            uint256 shareId = _shareList[i];
            count += _storage.undoVoteById(_proposalId, msg.sender, shareId);
        }
        if (count > 0) {
            emit VoteUndo(_proposalId, msg.sender, count);
        } else {
            revert("Not voter");
        }
    }

    function undoWithTokenId(uint256 _proposalId, uint256 _tokenId)
        public
        requireVoteOpen(_proposalId)
        requireNoVeto(_proposalId)
    {
        uint256 count = _storage.undoVoteById(_proposalId, msg.sender, _tokenId);
        if (count > 0) {
            emit VoteUndo(_proposalId, msg.sender, count);
        } else {
            revert("Not voter");
        }
    }

    function voteAgainst(uint256 _proposalId) public requireVoteOpen(_proposalId) requireNoVeto(_proposalId) {
        VoterClass _class = _storage.voterClass(_proposalId);
        uint256[] memory _shareList = _class.discover(msg.sender);
        uint256 count = 0;
        for (uint256 i = 0; i < _shareList.length; i++) {
            uint256 shareId = _shareList[i];
            count += _storage.voteAgainstByShare(_proposalId, msg.sender, shareId);
        }
        if (count > 0) {
            emit VoteTally(_proposalId, msg.sender, count);
        } else {
            revert("Not voter");
        }
    }

    function voteAgainstWithTokenId(uint256 _proposalId, uint256 _tokenId)
        public
        requireVoteOpen(_proposalId)
        requireNoVeto(_proposalId)
    {
        uint256 count = _storage.voteAgainstByShare(_proposalId, msg.sender, _tokenId);
        if (count > 0) {
            emit VoteTally(_proposalId, msg.sender, count);
        } else {
            revert("Not voter");
        }
    }

    function voteAgainstWithTokenList(uint256 _proposalId, uint256[] memory _tokenIdList)
        external
        requireVoteOpen(_proposalId)
        requireNoVeto(_proposalId)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < _tokenIdList.length; i++) {
            count += _storage.voteAgainstByShare(_proposalId, msg.sender, _tokenIdList[i]);
        }
        if (count > 0) {
            emit VoteTally(_proposalId, msg.sender, count);
        } else {
            revert("Not voter");
        }
    }

    function abstainFromVote(uint256 _proposalId) public requireVoteOpen(_proposalId) requireNoVeto(_proposalId) {
        VoterClass _class = _storage.voterClass(_proposalId);
        uint256[] memory _shareList = _class.discover(msg.sender);
        uint256 count = 0;
        for (uint256 i = 0; i < _shareList.length; i++) {
            uint256 shareId = _shareList[i];
            count = _storage.abstainForShare(_proposalId, msg.sender, shareId);
        }
        if (count > 0) {
            emit AbstentionTally(_proposalId, msg.sender, count);
        } else {
            revert("Not voter");
        }
    }

    function abstainWithTokenId(uint256 _proposalId, uint256 _tokenId)
        public
        requireVoteOpen(_proposalId)
        requireNoVeto(_proposalId)
    {
        uint256 count = _storage.abstainForShare(_proposalId, msg.sender, _tokenId);
        if (count > 0) {
            emit AbstentionTally(_proposalId, msg.sender, count);
        } else {
            revert("Not voter");
        }
    }

    function abstainWithTokenList(uint256 _proposalId, uint256[] memory _tokenIdList)
        external
        requireVoteOpen(_proposalId)
        requireNoVeto(_proposalId)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < _tokenIdList.length; i++) {
            count += _storage.abstainForShare(_proposalId, msg.sender, _tokenIdList[i]);
        }
        if (count > 0) {
            emit AbstentionTally(_proposalId, msg.sender, count);
        } else {
            revert("Not voter");
        }
    }

    /// @notice get the result of the measure pass or failed
    function getVoteSucceeded(uint256 _proposalId)
        public
        view
        requireVoteClosed(_proposalId)
        requireNoVeto(_proposalId)
        returns (bool)
    {
        _storage.validOrRevert(_proposalId);
        uint256 totalVotesCast = _storage.quorum(_proposalId);
        require(totalVotesCast >= _storage.quorumRequired(_proposalId), "Not enough participants");
        return _storage.forVotes(_proposalId) > _storage.againstVotes(_proposalId);
    }

    /// @notice ERC-165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(Governance).interfaceId ||
            interfaceId == type(VoteStrategy).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
    event RegisterVoterClassVoterPool(uint256 proposalId);
    event RegisterVoterClassOpenVote(uint256 proposalId);
    event RegisterVoterClassERC721(uint256 proposalId, address token);
    event BurnVoterClass(uint256 proposalId);
    event SetQuorumThreshold(uint256 proposalId, uint256 passThreshold);
    event UndoVoteEnabled(uint256 proposalId);

    event VoteCast(uint256 proposalId, address voter, uint256 shareId, uint256 totalVotesCast);
    event UndoVote(uint256 proposalId, address voter, uint256 shareId, uint256 votesUndone);
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
        /// @notice Receipts of ballots for the entire set of voters
        mapping(uint256 => Receipt) voteReceipt;
        /// @notice configured supervisors
        mapping(address => bool) supervisorPool;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice address of voting wallet
        address wallet;
        /// @notice id of reserved shares
        uint256 shareId;
        /// @notice number of votes cast for
        uint256 shareFor;
        /// @notice The number of votes the voter had, which were cast
        uint256 votesCast;
        /// @notice did the voter abstain
        bool abstention;
        /// @notice has this share been reversed
        bool undoCast;
    }

    function name() external pure returns (string memory);

    function version() external pure returns (uint32);

    function registerSupervisor(
        uint256 _proposalId,
        address _supervisor,
        address _sender
    ) external;

    function burnSupervisor(
        uint256 _proposalId,
        address _supervisor,
        address _sender
    ) external;

    function registerVoter(
        uint256 _proposalId,
        address _voter,
        address _sender
    ) external;

    function registerVoters(
        uint256 _proposalId,
        address[] memory _voter,
        address _sender
    ) external;

    function burnVoter(
        uint256 _proposalId,
        address _voter,
        address _sender
    ) external;

    function registerVoterClassERC721(
        uint256 _proposalId,
        address token,
        address _sender
    ) external;

    function registerVoterClassVoterPool(uint256 _proposalId, address _sender) external;

    function registerVoterClassOpenVote(uint256 _proposalId, address _sender) external;

    function burnVoterClass(uint256 _proposalId, address _sender) external;

    function setQuorumThreshold(
        uint256 _proposalId,
        uint256 _passThreshold,
        address _sender
    ) external;

    function setVoteDelay(
        uint256 _proposalId,
        uint256 _voteDelay,
        address _sender
    ) external;

    function setRequiredVoteDuration(
        uint256 _proposalId,
        uint256 _voteDuration,
        address _sender
    ) external;

    function enableUndoVote(uint256 _proposalId, address _sender) external;

    function makeReady(uint256 _proposalId, address _sender) external;

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

    function voterClass(uint256 _proposalId) external view returns (VoterClass);

    function latestProposal(address _sender) external view returns (uint256);

    function voteReceipt(uint256 _proposalId, uint256 shareId)
        external
        view
        returns (
            uint256 _shareId,
            uint256 _shareFor,
            uint256 _votesCast,
            bool _isAbstention,
            bool _isUndo
        );

    function initializeProposal(address _sender) external returns (uint256);

    function voteForByShare(
        uint256 _proposalId,
        address _wallet,
        uint256 _shareId
    ) external returns (uint256);

    function voteAgainstByShare(
        uint256 _proposalId,
        address _wallet,
        uint256 _shareId
    ) external returns (uint256);

    function abstainForShare(
        uint256 _proposalId,
        address _wallet,
        uint256 _shareId
    ) external returns (uint256);

    function undoVoteById(
        uint256 _proposalId,
        address _wallet,
        uint256 _receiptId
    ) external returns (uint256);

    function veto(uint256 _proposalId, address _sender) external;

    function validOrRevert(uint256 _proposalId) external view;

    function maxPassThreshold() external pure returns (uint256);
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
import "../contracts/VoterClassVoterPool.sol";

contract GovernanceStorage is Storage {
    /// @notice contract name
    string public constant name = "collective.xyz governance storage";
    uint32 public constant VERSION_1 = 1;

    uint256 public constant MAXIMUM_QUORUM = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 public constant MINIMUM_VOTE_DURATION = 1;

    /// @notice global list of proposed issues by id
    mapping(uint256 => Proposal) public proposalMap;

    /// @notice only the peer contract may modify the vote
    address private _cognate;

    /// @notice The total number of proposals
    uint256 internal _proposalCount;

    /// @notice The latest proposal for each proposer
    mapping(address => uint256) internal _latestProposalId;

    constructor() {
        _cognate = msg.sender;
        _proposalCount = 0;
    }

    modifier requireValidAddress(address _wallet) {
        require(_wallet != address(0), "Not a valid wallet");
        _;
    }

    modifier requireValidProposal(uint256 _proposalId) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(_proposalId > 0 && _proposalId <= _proposalCount && proposal.id == _proposalId, "Invalid proposal");
        _;
    }

    modifier requireVoteCast(uint256 _proposalId, uint256 _receiptId) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(_receiptId > 0, "Receipt id is not valid");
        Receipt storage receipt = proposal.voteReceipt[_receiptId];
        require(receipt.shareId == _receiptId, "No vote cast");
        require(receipt.votesCast > 0 && !receipt.abstention && !receipt.undoCast, "No affirmative vote");
        _;
    }

    modifier requireReceiptForWallet(
        uint256 _proposalId,
        uint256 _receiptId,
        address _wallet
    ) {
        Proposal storage proposal = proposalMap[_proposalId];
        Receipt storage receipt = proposal.voteReceipt[_receiptId];
        require(receipt.wallet == _wallet, "Not voter");
        _;
    }

    modifier requireValidReceipt(uint256 _proposalId, uint256 _receiptId) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(_receiptId > 0, "Receipt id is not valid");
        Receipt storage receipt = proposal.voteReceipt[_receiptId];
        require(receipt.shareId > 0, "Receipt not initialized");
        _;
    }

    modifier requireShareAvailable(uint256 _proposalId, uint256 _shareId) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(_shareId > 0, "Share id is not valid");
        Receipt storage receipt = proposal.voteReceipt[_shareId];
        require(receipt.votesCast == 0 && !receipt.abstention && !receipt.undoCast, "Already voted");
        _;
    }

    modifier requireProposalSender(uint256 _proposalId, address _sender) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(proposal.proposalSender == _sender, "Not proposal creator");
        _;
    }

    modifier requireElectorSupervisor(uint256 _proposalId, address _sender) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(proposal.supervisorPool[_sender], "Operation requires supervisor");
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
        require(proposal.startBlock <= block.number && proposal.endBlock > block.number, "Vote not active");
        _;
    }

    modifier requireUndo(uint256 _proposalId) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(proposal.isUndoEnabled, "Undo not enabled");
        _;
    }

    modifier requireCognate() {
        require(msg.sender == _cognate, "Not permitted");
        _;
    }

    /// @notice initialize a proposal and return the id
    function initializeProposal(address _sender) external requireCognate returns (uint256) {
        uint256 latestProposalId = _latestProposalId[_sender];
        if (latestProposalId != 0) {
            Proposal storage lastProposal = proposalMap[latestProposalId];
            require(lastProposal.isReady && block.number >= lastProposal.endBlock, "Too many proposals");
        }
        _proposalCount++;
        uint256 proposalId = _proposalCount;
        _latestProposalId[_sender] = proposalId;

        // proposal
        Proposal storage proposal = proposalMap[proposalId];
        proposal.id = proposalId;
        proposal.proposalSender = _sender;
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

        emit InitializeProposal(proposalId, _sender);
        return proposalId;
    }

    /// @notice add a vote superviser to the supervisor pool with rights to add or remove voters prior to start of voting, also right to veto the outcome after voting is closed
    function registerSupervisor(
        uint256 _proposalId,
        address _supervisor,
        address _sender
    )
        public
        requireCognate
        requireValidAddress(_supervisor)
        requireValidProposal(_proposalId)
        requireProposalSender(_proposalId, _sender)
        requireVotingNotReady(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        if (!proposal.supervisorPool[_supervisor]) {
            proposal.supervisorPool[_supervisor] = true;
            emit AddSupervisor(_proposalId, _supervisor);
        }
    }

    /// @notice remove the supervisor from the supervisor pool suspending their rights to modify the election
    function burnSupervisor(
        uint256 _proposalId,
        address _supervisor,
        address _sender
    )
        public
        requireCognate
        requireValidAddress(_supervisor)
        requireValidProposal(_proposalId)
        requireProposalSender(_proposalId, _sender)
        requireVotingNotReady(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        if (proposal.supervisorPool[_supervisor]) {
            proposal.supervisorPool[_supervisor] = false;
            emit BurnSupervisor(_proposalId, _supervisor);
        }
    }

    /// @notice enable vote undo feature
    function enableUndoVote(uint256 _proposalId, address _sender)
        public
        requireCognate
        requireValidProposal(_proposalId)
        requireElectorSupervisor(_proposalId, _sender)
        requireVotingNotReady(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        proposal.isUndoEnabled = true;
        emit UndoVoteEnabled(_proposalId);
    }

    /// @notice register a voter on this measure
    function registerVoter(
        uint256 _proposalId,
        address _voter,
        address _sender
    )
        public
        requireCognate
        requireValidAddress(_voter)
        requireValidProposal(_proposalId)
        requireElectorSupervisor(_proposalId, _sender)
        requireVotingNotReady(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        VoterClassVoterPool _class = VoterClassVoterPool(address(proposal.voterClass));
        _class.addVoter(_voter);
        emit RegisterVoter(_proposalId, _voter);
    }

    /// @notice register a list of voters on this measure
    function registerVoters(
        uint256 _proposalId,
        address[] memory _voter,
        address _sender
    )
        public
        requireCognate
        requireValidProposal(_proposalId)
        requireElectorSupervisor(_proposalId, _sender)
        requireVotingNotReady(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        VoterClassVoterPool _class = VoterClassVoterPool(address(proposal.voterClass));
        require(address(_class) != address(0x0), "Voter pool required");
        uint256 addedCount = 0;
        for (uint256 i = 0; i < _voter.length; i++) {
            if (_voter[i] != address(0)) {
                _class.addVoter(_voter[i]);
                emit RegisterVoter(_proposalId, _voter[i]);
            }
            addedCount++;
        }
    }

    /// @notice burn the specified voter, removing their rights to participate in the election
    function burnVoter(
        uint256 _proposalId,
        address _voter,
        address _sender
    )
        public
        requireCognate
        requireValidAddress(_voter)
        requireValidProposal(_proposalId)
        requireElectorSupervisor(_proposalId, _sender)
        requireVotingNotReady(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        VoterClassVoterPool _class = VoterClassVoterPool(address(proposal.voterClass));
        _class.removeVoter(_voter);
        emit BurnVoter(_proposalId, _voter);
    }

    function registerVoterClassVoterPool(uint256 _proposalId, address _sender)
        public
        requireCognate
        requireValidProposal(_proposalId)
        requireElectorSupervisor(_proposalId, _sender)
        requireVotingNotReady(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        proposal.voterClass = new VoterClassVoterPool(1);
        emit RegisterVoterClassVoterPool(_proposalId);
    }

    /// @notice register a voting class for this measure
    function registerVoterClassERC721(
        uint256 _proposalId,
        address _tokenContract,
        address _sender
    )
        public
        requireCognate
        requireValidAddress(_tokenContract)
        requireValidProposal(_proposalId)
        requireElectorSupervisor(_proposalId, _sender)
        requireVotingNotReady(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        proposal.voterClass = new VoterClassERC721(_tokenContract, 1);
        emit RegisterVoterClassERC721(_proposalId, _tokenContract);
    }

    /// @notice register a voting class for this measure
    function registerVoterClassOpenVote(uint256 _proposalId, address _sender)
        public
        requireCognate
        requireValidProposal(_proposalId)
        requireElectorSupervisor(_proposalId, _sender)
        requireVotingNotReady(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        proposal.voterClass = new VoterClassOpenVote(1);
        emit RegisterVoterClassOpenVote(_proposalId);
    }

    /// @notice burn voter class
    function burnVoterClass(uint256 _proposalId, address _sender)
        public
        requireCognate
        requireValidProposal(_proposalId)
        requireElectorSupervisor(_proposalId, _sender)
        requireVotingNotReady(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        proposal.voterClass = new VoterClassNullObject();
        emit BurnVoterClass(_proposalId);
    }

    /// @notice establish the pass threshold for this measure
    function setQuorumThreshold(
        uint256 _proposalId,
        uint256 _passThreshold,
        address _sender
    )
        public
        requireCognate
        requireValidProposal(_proposalId)
        requireElectorSupervisor(_proposalId, _sender)
        requireVotingNotReady(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        proposal.quorumRequired = _passThreshold;
        emit SetQuorumThreshold(_proposalId, _passThreshold);
    }

    function setVoteDelay(
        uint256 _proposalId,
        uint256 _voteDelay,
        address _sender
    )
        public
        requireCognate
        requireValidProposal(_proposalId)
        requireElectorSupervisor(_proposalId, _sender)
        requireVotingNotReady(_proposalId)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        proposal.voteDelay = _voteDelay;
    }

    function setRequiredVoteDuration(
        uint256 _proposalId,
        uint256 _voteDuration,
        address _sender
    )
        public
        requireCognate
        requireValidProposal(_proposalId)
        requireElectorSupervisor(_proposalId, _sender)
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

    function voterClass(uint256 _proposalId) external view requireValidProposal(_proposalId) returns (VoterClass) {
        Proposal storage proposal = proposalMap[_proposalId];
        return proposal.voterClass;
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
        return proposal.voterClass.isVoter(_voter);
    }

    function isVeto(uint256 _proposalId) external view returns (bool) {
        Proposal storage proposal = proposalMap[_proposalId];
        require(_proposalId > 0 && _proposalId <= _proposalCount, "Unknown proposal");
        return proposal.isVeto;
    }

    function makeReady(uint256 _proposalId, address _sender)
        external
        requireCognate
        requireElectorSupervisor(_proposalId, _sender)
        requireVotingNotReady(_proposalId)
    {
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

    function latestProposal(address _sender) external view returns (uint256) {
        uint256 latestProposalId = _latestProposalId[_sender];
        require(latestProposalId > 0, "No current proposal");
        return latestProposalId;
    }

    function voteReceipt(uint256 _proposalId, uint256 _shareId)
        external
        view
        requireValidProposal(_proposalId)
        requireValidReceipt(_proposalId, _shareId)
        returns (
            uint256,
            uint256,
            uint256,
            bool,
            bool
        )
    {
        Proposal storage proposal = proposalMap[_proposalId];
        Receipt storage receipt = proposal.voteReceipt[_shareId];
        return (receipt.shareId, receipt.shareFor, receipt.votesCast, receipt.abstention, receipt.undoCast);
    }

    function version() public pure virtual returns (uint32) {
        return VERSION_1;
    }

    function validOrRevert(uint256 _proposalId)
        external
        view
        requireCognate
        requireValidProposal(_proposalId)
    // solium-disable-next-line no-empty-blocks
    {

    }

    function maxPassThreshold() external pure returns (uint256) {
        return MAXIMUM_QUORUM;
    }

    /// @notice veto the current measure
    function veto(uint256 _proposalId, address _sender)
        public
        requireCognate
        requireValidProposal(_proposalId)
        requireElectorSupervisor(_proposalId, _sender)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        if (!proposal.isVeto) {
            proposal.isVeto = true;
            emit VoteVeto(_proposalId, msg.sender);
        } else {
            revert("Already vetoed");
        }
    }

    function voteForByShare(
        uint256 _proposalId,
        address _wallet,
        uint256 _shareId
    )
        external
        requireCognate
        requireValidProposal(_proposalId)
        requireShareAvailable(_proposalId, _shareId)
        requireVotingActive(_proposalId)
        returns (uint256)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        uint256 _shareCount = proposal.voterClass.confirm(_wallet, _shareId);
        require(_shareCount > 0, "Share not available");
        Receipt storage receipt = proposal.voteReceipt[_shareId];
        receipt.wallet = _wallet;
        receipt.shareId = _shareId;
        receipt.votesCast = _shareCount;
        receipt.shareFor = _shareCount;
        proposal.forVotes += _shareCount;
        emit VoteCast(_proposalId, _wallet, _shareId, _shareCount);
        return _shareCount;
    }

    function voteAgainstByShare(
        uint256 _proposalId,
        address _wallet,
        uint256 _shareId
    )
        public
        requireCognate
        requireValidProposal(_proposalId)
        requireShareAvailable(_proposalId, _shareId)
        requireVotingActive(_proposalId)
        returns (uint256)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        uint256 _shareCount = proposal.voterClass.confirm(_wallet, _shareId);
        require(_shareCount > 0, "Share not available");
        Receipt storage receipt = proposal.voteReceipt[_shareId];
        receipt.wallet = _wallet;
        receipt.shareId = _shareId;
        receipt.votesCast = _shareCount;
        receipt.abstention = false;
        proposal.againstVotes += _shareCount;
        emit VoteCast(_proposalId, _wallet, _shareId, _shareCount);
        return _shareCount;
    }

    function abstainForShare(
        uint256 _proposalId,
        address _wallet,
        uint256 _shareId
    ) public requireCognate requireValidProposal(_proposalId) requireVotingActive(_proposalId) returns (uint256) {
        Proposal storage proposal = proposalMap[_proposalId];
        uint256 _shareCount = proposal.voterClass.confirm(_wallet, _shareId);
        require(_shareCount > 0, "Share not available");
        Receipt storage receipt = proposal.voteReceipt[_shareId];
        receipt.wallet = _wallet;
        receipt.shareId = _shareId;
        receipt.votesCast = _shareCount;
        receipt.abstention = true;
        proposal.abstentionCount += _shareCount;
        emit VoteCast(_proposalId, _wallet, _shareId, _shareCount);
        return _shareCount;
    }

    function undoVoteById(
        uint256 _proposalId,
        address _wallet,
        uint256 _receiptId
    )
        public
        requireCognate
        requireValidProposal(_proposalId)
        requireVoteCast(_proposalId, _receiptId)
        requireReceiptForWallet(_proposalId, _receiptId, _wallet)
        requireUndo(_proposalId)
        requireVotingActive(_proposalId)
        returns (uint256)
    {
        Proposal storage proposal = proposalMap[_proposalId];
        Receipt storage receipt = proposal.voteReceipt[_receiptId];
        require(receipt.shareFor > 0, "Vote not affirmative");
        uint256 undoVotes = receipt.shareFor;
        receipt.undoCast = true;
        proposal.forVotes -= undoVotes;
        emit UndoVote(_proposalId, _wallet, _receiptId, undoVotes);
        return undoVotes;
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

import "../contracts/VoteStrategy.sol";

/// @title Governance
/// contract enables proposing a measure to be voted upon
interface Governance {
    event ProposalCreated(address proposer, uint256 proposalId);
    event ProposalOpen(uint256 proposalId);
    event ProposalClosed(uint256 proposalId);

    /// @notice propose a measurement of a vote class @returns proposal id
    function propose() external returns (uint256);

    function configureTokenVoteERC721(
        uint256 proposalId,
        uint256 quorumThreshold,
        address erc721,
        uint256 requiredDuration
    ) external;

    function configureOpenVote(
        uint256 proposalId,
        uint256 quorumThreshold,
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
    event VoteOpen(uint256 _proposalId);
    event VoteClosed(uint256 _proposalId);
    event VoteTally(uint256 _proposalId, address _wallet, uint256 _count);
    event AbstentionTally(uint256 _proposalId, address _wallet, uint256 _count);
    event VoteUndo(uint256 _proposalId, address _wallet, uint256 _count);

    function openVote(uint256 _proposalId) external;

    function endVote(uint256 _proposalId) external;

    function voteFor(uint256 _proposalId) external;

    function voteForWithTokenId(uint256 _proposalId, uint256 _tokenId) external;

    function voteForWithTokenList(uint256 _proposalId, uint256[] memory _tokenIdList) external;

    function voteAgainst(uint256 _proposalId) external;

    function voteAgainstWithTokenId(uint256 _proposalId, uint256 _tokenId) external;

    function voteAgainstWithTokenList(uint256 _proposalId, uint256[] memory _tokenIdList) external;

    function abstainFromVote(uint256 _proposalId) external;

    function abstainWithTokenId(uint256 _proposalId, uint256 _tokenId) external;

    function abstainWithTokenList(uint256 _proposalId, uint256[] memory _tokenIdList) external;

    function undoVote(uint256 _proposalId) external;

    function undoWithTokenId(uint256 _proposalId, uint256 _tokenId) external;

    function veto(uint256 _proposalId) external;

    function getVoteSucceeded(uint256 _proposalId) external view returns (bool);

    function isOpen(uint256 _proposalId) external view returns (bool);
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
    event VoteCommitted(uint256 _shareId, uint256 _weight);

    function isVoter(address _wallet) external view returns (bool);

    function discover(address _wallet) external view returns (uint256[] memory);

    /// @notice commit votes for shareId return number voted
    function confirm(address _wallet, uint256 shareId) external returns (uint256);

    /// @notice return voting weight of each confirmed share
    function weight() external view returns (uint256);
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
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./VoterClass.sol";

/// @notice voting class for ERC-721 contract
contract VoterClassERC721 is VoterClass {
    /// @notice commited vote
    mapping(uint256 => bool) private _committedVote;

    address private _cognate;

    address private _contractAddress;

    uint256 private _weight;

    constructor(address _contract, uint256 _voteWeight) {
        _cognate = msg.sender;
        _contractAddress = _contract;
        _weight = _voteWeight;
    }

    modifier requireCognate() {
        require(_cognate == msg.sender, "Not permitted");
        _;
    }

    modifier requireValidAddress(address _wallet) {
        require(_wallet != address(0), "Not a valid wallet");
        _;
    }

    modifier requireValidShare(uint256 _shareId) {
        require(_shareId != 0, "Share not valid");
        _;
    }

    function isVoter(address _wallet) external view requireValidAddress(_wallet) returns (bool) {
        return IERC721(_contractAddress).balanceOf(_wallet) > 0;
    }

    function votesAvailable(address _wallet, uint256 _shareId) external view requireValidAddress(_wallet) returns (uint256) {
        address tokenOwner = IERC721(_contractAddress).ownerOf(_shareId);
        if (_wallet == tokenOwner) {
            return 1;
        }
        return 0;
    }

    function discover(address _wallet) external view requireValidAddress(_wallet) returns (uint256[] memory) {
        bytes4 interfaceId721 = type(IERC721Enumerable).interfaceId;
        require(IERC721(_contractAddress).supportsInterface(interfaceId721), "ERC-721 Enumerable required");
        IERC721Enumerable enumContract = IERC721Enumerable(_contractAddress);
        uint256 tokenBalance = IERC721(_contractAddress).balanceOf(_wallet);
        uint256[] memory tokenIdList = new uint256[](tokenBalance);
        for (uint256 i = 0; i < tokenBalance; i++) {
            tokenIdList[i] = enumContract.tokenOfOwnerByIndex(_wallet, i);
        }
        return tokenIdList;
    }

    /// @notice commit votes for shareId return number voted
    function confirm(address _wallet, uint256 _shareId) external requireCognate requireValidShare(_shareId) returns (uint256) {
        require(!_committedVote[_shareId], "Share committed");
        uint256 voteCount = this.votesAvailable(_wallet, _shareId);
        require(voteCount > 0, "Not owner of specified token");
        _committedVote[_shareId] = true;
        emit VoteCommitted(_shareId, _weight);
        return _weight * voteCount;
    }

    /// @notice return voting weight of each confirmed share
    function weight() external view returns (uint256) {
        return _weight;
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
    mapping(uint256 => bool) private _committedVote;

    address private _cognate;

    uint256 private _weight;

    constructor(uint256 _voteWeight) {
        _cognate = msg.sender;
        _weight = _voteWeight;
    }

    modifier requireCognate() {
        require(_cognate == msg.sender, "Not permitted");
        _;
    }

    modifier requireValidAddress(address _wallet) {
        require(_wallet != address(0), "Not a valid wallet");
        _;
    }

    modifier requireValidShare(address _wallet, uint256 _shareId) {
        require(_shareId > 0 && _shareId == uint160(_wallet), "Not a valid share");
        _;
    }

    function isVoter(address _wallet) external pure requireValidAddress(_wallet) returns (bool) {
        return true;
    }

    function discover(address _wallet) external pure requireValidAddress(_wallet) returns (uint256[] memory) {
        uint256[] memory shareList = new uint256[](1);
        shareList[0] = uint160(_wallet);
        return shareList;
    }

    /// @notice commit votes for shareId return number voted
    function confirm(address _wallet, uint256 _shareId)
        external
        requireCognate
        requireValidShare(_wallet, _shareId)
        returns (uint256)
    {
        require(!_committedVote[_shareId], "Share committed");
        _committedVote[_shareId] = true;
        emit VoteCommitted(_shareId, _weight);
        return _weight;
    }

    /// @notice return voting weight of each confirmed share
    function weight() external view returns (uint256) {
        return _weight;
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
contract VoterClassVoterPool is VoterClass {
    event RegisterVoterInPool(address _wallet);
    event RemoveVoterFromPool(address _wallet);

    /// @notice whitelisted voters
    mapping(address => bool) private _voterPool;

    /// @notice commited vote
    mapping(uint256 => bool) private _committedVote;

    address private _cognate;

    uint256 private _weight;

    constructor(uint256 _voteWeight) {
        _cognate = msg.sender;
        _weight = _voteWeight;
    }

    modifier requireValidAddress(address _wallet) {
        require(_wallet != address(0), "Not a valid wallet");
        _;
    }

    modifier requireValidShare(address _wallet, uint256 _shareId) {
        require(_shareId > 0 && _shareId == uint160(_wallet), "Not a valid share");
        _;
    }

    modifier requireVoter(address _wallet) {
        require(_voterPool[_wallet], "Not voter");
        _;
    }

    modifier requireCognate() {
        require(_cognate == msg.sender, "Not permitted");
        _;
    }

    function addVoter(address _wallet) external requireValidAddress(_wallet) requireCognate {
        if (!_voterPool[_wallet]) {
            _voterPool[_wallet] = true;
            emit RegisterVoterInPool(_wallet);
        } else {
            revert("Voter already registered");
        }
    }

    function removeVoter(address _wallet) external requireValidAddress(_wallet) requireCognate {
        if (_voterPool[_wallet]) {
            _voterPool[_wallet] = false;
            emit RemoveVoterFromPool(_wallet);
        } else {
            revert("Voter not registered");
        }
    }

    function isVoter(address _wallet) external view requireValidAddress(_wallet) returns (bool) {
        return _voterPool[_wallet];
    }

    function discover(address _wallet) external view requireVoter(_wallet) returns (uint256[] memory) {
        uint256[] memory shareList = new uint256[](1);
        shareList[0] = uint160(_wallet);
        return shareList;
    }

    /// @notice commit votes for shareId return number voted
    function confirm(address _wallet, uint256 _shareId)
        external
        requireCognate
        requireVoter(_wallet)
        requireValidShare(_wallet, _shareId)
        returns (uint256)
    {
        require(!_committedVote[_shareId], "Share committed");
        _committedVote[_shareId] = true;
        emit VoteCommitted(_shareId, _weight);
        return _weight;
    }

    /// @notice return voting weight of each confirmed share
    function weight() external view returns (uint256) {
        return _weight;
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

    function discover(address _wallet) external pure requireValidAddress(_wallet) returns (uint256[] memory) {
        revert("Not a voter");
    }

    /// @notice commit votes for shareId return number voted
    function confirm(
        address, /* _wallet */
        uint256 /* shareId */
    ) external pure returns (uint256) {
        return 0;
    }

    /// @notice return voting weight of each confirmed share
    function weight() external pure returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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