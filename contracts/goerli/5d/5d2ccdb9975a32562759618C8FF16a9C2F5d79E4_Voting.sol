// SPDX-License-Identifier:MIT

/* Future Improvements 
    - Remove Proposal
    - More Robust Evaluation
*/
pragma solidity ^0.8.0;

error NotAuthorized();
error NotAuthorizedToVote(address invalidPerson);
error ProposalNotFound();
error WrongState();

contract Voting {
    event MemberAdded(address member);
    event ProposalAdded(uint256 proposalIndex);
    event VoteUsed(address indexed voter, uint256 indexed proposalIndex);
    event WinnerDeclared(uint256 indexed proposalIndex);
    event NewVotingCreated();
    event StateChanged(Status oldState, Status newState);

    address private immutable s_chairPerson;
    enum Status {
        PREPARING,
        VOTING,
        FINISH
    }

    Status private state;

    struct VoteRight {
        uint256 voteWeight;
        bool isVoted;
    }

    struct Map {
        address[] keys;
        mapping(address => VoteRight) values;
    }
    Map private s_voters;

    struct Proposal {
        uint256 proposalIndex;
        uint256 voteCount;
    }

    Proposal[] private proposals;

    constructor() {
        s_chairPerson = msg.sender;
        s_voters.values[msg.sender] = VoteRight(2, false);
        s_voters.keys.push(msg.sender);
        state = Status.PREPARING;
    }

    function incrementState() public {
        if (msg.sender != s_chairPerson) {
            revert NotAuthorized();
        }
        Status temp = state;
        state = Status(uint(state) + 1);
        emit StateChanged(temp, state);
    }

    function addMember(address candidateMember) public {
        if (state != Status.PREPARING) {
            revert WrongState();
        }

        if (msg.sender != s_chairPerson) {
            revert NotAuthorized();
        }
        VoteRight memory temp = VoteRight(1, false);
        s_voters.values[candidateMember] = temp;
        s_voters.keys.push(candidateMember);
        emit MemberAdded(candidateMember);
    }

    function addProposal() public {
        if (state != Status.PREPARING) {
            revert WrongState();
        }
        if (msg.sender != s_chairPerson) {
            revert NotAuthorized();
        }
        proposals.push(Proposal(proposals.length + 1, 0));
        emit ProposalAdded(proposals.length);
    }

    function vote(uint256 proposalIndex) public {
        if (state != Status.VOTING) {
            revert WrongState();
        }
        if (
            (s_voters.values[msg.sender].voteWeight == 0) ||
            (s_voters.values[msg.sender].isVoted)
        ) {
            revert NotAuthorizedToVote(msg.sender);
        }
        if (proposals[proposalIndex].proposalIndex == 0) {
            revert ProposalNotFound();
        }

        proposals[proposalIndex].voteCount =
            proposals[proposalIndex].voteCount +
            s_voters.values[msg.sender].voteWeight;
        s_voters.values[msg.sender].isVoted = true;
        emit VoteUsed(msg.sender, proposalIndex);
    }

    function declareWinner() public returns (uint256) {
        if (state != Status.FINISH) {
            revert WrongState();
        }
        if (msg.sender != s_chairPerson) {
            revert NotAuthorized();
        }

        uint256 winnerIndex = 0;
        uint256 mostVote = 0;
        uint256 currentVoteCount;

        for (uint i = 0; i < proposals.length; i++) {
            currentVoteCount = proposals[i].voteCount;
            if (currentVoteCount > mostVote) {
                winnerIndex = i;
                mostVote = currentVoteCount;
            }
        }
        emit WinnerDeclared(winnerIndex);
        return proposals[winnerIndex].proposalIndex;
    }

    function startNewVoting() public {
        if (state != Status.FINISH) {
            revert WrongState();
        }
        if (msg.sender != s_chairPerson) {
            revert NotAuthorized();
        }
        delete proposals;
        address tempMember;
        for (uint i = 0; i < s_voters.keys.length; i++) {
            tempMember = s_voters.keys[i];
            delete s_voters.values[tempMember];
        }
        delete s_voters.keys;
        s_voters.values[msg.sender] = VoteRight(2, false);
        s_voters.keys.push(msg.sender);

        state = Status.PREPARING;
        emit NewVotingCreated();
    }

    function getChairPerson() public view returns (address) {
        return s_chairPerson;
    }

    function getVoteRight(address member)
        public
        view
        returns (VoteRight memory)
    {
        return s_voters.values[member];
    }

    function getProposal(uint256 index) public view returns (Proposal memory) {
        return proposals[index];
    }

    function getState() public view returns (Status) {
        return state;
    }
}