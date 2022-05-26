//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// Governance Rules

// Proposal Creation:
// Anyone can create proposal
// Duplicate proposals are not allowed

// Members:
// In the constructor, founding members are added.
// Anyone can create a proposal to add new member or remove existing member.

// Voting
// Only members can vote
// There is no castBySig or delegation; each member has to cast a vote by themselves
// All votes carry equal weight
// For a proposal to be passed
//    for votes >= 0.75 * total members
// We don't keep track of against votes as it doesn't matter, in our case.
// Because if for votes are > 75 out of 100, against votes are always going to be less than that
// Inactive vote is a superset of against vote, which additionally allows one to change their vote to true
// Once quorum is reached, voting is closed.

// Proposal Execution
// Anyone can execute a proposal once passed
// Each proposal can be executed only once

contract Governor {
    // constants
    uint256 public constant VOTING_PERIOD = 30 days;

    // variables
    mapping(address => bool) public members;
    uint128 public totalMembers;
    uint128 public quorum;

    struct Receipt {
        bool hasVoted;
        bool support;
    }

    struct Proposal {
        // slot 1
        uint128 start;
        uint128 end;
        // slot 2
        bool executed;
        uint128 forVotes;
        mapping(address => Receipt) receipts;
    }

    mapping(uint256 => Proposal) public proposals;

    enum ProposalState {
        Executed,
        Active,
        Succeeded,
        Defeated
    }

    /*///////////////////////////////////////////////////////////////
                      MEMEBERSHIP
    //////////////////////////////////////////////////////////////*/

    // events
    event NewMember(address add);
    event MembershipRemoved(address add);

    // errrors
    error NotAllowed();
    error AlreadyMember();
    error NotAMember();

    constructor(uint128 _quorum, address[] memory foundingMembers) {
        quorum = _quorum;
        emit QuorumChanged(0, _quorum);
        
        uint256 length = foundingMembers.length;
        for (uint256 i = 0; i < length; ++i) {
            _addMember(foundingMembers[i]);
        }
    }

    function addMember(address _newMember) external {
        if (msg.sender != address(this)) revert NotAllowed();
        _addMember(_newMember);
    }

    function _addMember(address _newMember) internal {
        if (members[_newMember] != false) revert AlreadyMember();
        totalMembers++;
        members[_newMember] = true;
        emit NewMember(_newMember);
    }

    function removeMember(address _oldMember) external {
        if (msg.sender != address(this)) revert NotAllowed();
        isMember(_oldMember);
        totalMembers--;
        members[_oldMember] = false;
        emit MembershipRemoved(_oldMember);
    }

    function isMember(address _add) internal view {
        if (!members[_add]) revert NotAMember();
    }

    /*///////////////////////////////////////////////////////////////
                      PROPOSAL
    //////////////////////////////////////////////////////////////*/

    // events
    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock
    );
    event ProposalExecuted(uint256 proposalId);

    // errors
    error InvalidProposal(string reason);
    error RevertForCall(uint256 proposalId, uint256 position);
    error NotAProposer();
    error NotSucceededOrAlreadyExecuted();
    error ProposalAlreadyExecuted();

    function state(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage p = proposals[proposalId];

        if (p.executed) return ProposalState.Executed;
        if (p.start == 0) revert InvalidProposal("NotDefined");
        if (_isSucceeded(p)) return ProposalState.Succeeded;
        if (p.end >= block.timestamp) return ProposalState.Active;
        return ProposalState.Defeated;
    }

    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public pure returns (uint256) {
        return
            uint256(
                keccak256(abi.encode(targets, values, calldatas, description))
            );
    }

    function isValidProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public view returns (uint256 id) {
        if (targets.length != values.length)
            revert InvalidProposal("targets!=values");
        if (targets.length != calldatas.length)
            revert InvalidProposal("targets!=calldatas");
        if (targets.length == 0) revert InvalidProposal("empty");

        id = hashProposal(targets, values, calldatas, description);

        if (proposals[id].start != 0) revert InvalidProposal("Duplicate");
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256) {
        uint256 proposalId = isValidProposal(
            targets,
            values,
            calldatas,
            description
        );
        uint256 _start = block.timestamp;
        uint256 _end = _start + VOTING_PERIOD;
        proposals[proposalId].start = uint128(_start);
        proposals[proposalId].end = uint128(_end);

        emit ProposalCreated(
            proposalId,
            msg.sender,
            targets,
            values,
            calldatas,
            _start,
            _end
        );
        return proposalId;
    }

    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external {
        uint256 proposalId = hashProposal(
            targets,
            values,
            calldatas,
            description
        );
        // Check
        if (state(proposalId) != ProposalState.Succeeded)
            revert NotSucceededOrAlreadyExecuted();

        // Effect
        proposals[proposalId].executed = true;
        emit ProposalExecuted(proposalId);

        // Interaction
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{
                value: values[i]
            }(calldatas[i]);
            if (!success) {
                if (returndata.length == 0) revert RevertForCall(proposalId, i);
                assembly {
                    revert(add(32, returndata), mload(returndata))
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                          VOTE
    //////////////////////////////////////////////////////////////*/

    // events
    event VoteCast(address indexed voter, uint256 proposalId, bool support);
    event QuorumChanged(uint128 old, uint128 new_);

    // errors
    error VotingClosed();
    error AlreadyVoted();
    error InvalidQuorum();

    function castVote(uint256 proposalId, bool support) external {
        return _castVote(msg.sender, proposalId, support);
    }

    function _castVote(
        address voter,
        uint256 proposalId,
        bool support
    ) internal {
        isMember(voter);
        if (state(proposalId) != ProposalState.Active) revert VotingClosed();

        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];

        if (receipt.hasVoted) revert AlreadyVoted();

        if (support) proposal.forVotes++;

        receipt.hasVoted = true;
        receipt.support = support;

        emit VoteCast(voter, proposalId, support);
    }

    function _isSucceeded(Proposal storage proposal)
        internal
        view
        returns (bool)
    {
        if (proposal.forVotes * 100 >= totalMembers * quorum) return true;
        else return false;
    }

    function changeQuorum(uint128 _newQuorum) external {
        if (msg.sender != address(this)) revert NotAllowed();
        if (_newQuorum < 50 || _newQuorum > 100) revert InvalidQuorum();

        emit QuorumChanged(quorum, _newQuorum);
        quorum = _newQuorum;
    }
}