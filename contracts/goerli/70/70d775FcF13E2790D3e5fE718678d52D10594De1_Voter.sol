// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

error cannot_add_new_voter_voting_on_going_or_closed();
error cannot_register_new_candidate_voting_on_going_or_closed();
error voting_is_not_closed();
error voting_is_not_ongoing();
error already_voted();

contract Voter {
    /**Type declaration */
    /**State Variables */
    enum State {
        REGISTRATION,
        ONGOING,
        CLOSED
    }
    
    /**Voting contract Variables */
    address private immutable i_owner;
    address[] private voters;
    mapping(address => uint256) num_votes;
    address[] private candidates;
    mapping(uint256 => address) identity;
    struct candidate {
        string name;
        string proposal;
        uint256 id;
    }
    mapping(address => candidate) list_candidate;
    struct Voters {
        string name;
        string voted_to;
        bool delegated;
    }
    mapping(address => Voters) list_voters;
    mapping(address => address) delegate_voting;
    State private state;
    address private winner;
    mapping(address => bool) voted;

    constructor() {
        i_owner = msg.sender;
    }

    /**Modifier */
    modifier isOwner() {
        require(msg.sender == i_owner);
        _;
    }

    /**Function */
    function addcandidate(
        address _candidateAddress,
        string memory _name,
        string memory _proposal,
        uint256 _id
    ) public isOwner {
        if (state != State.REGISTRATION)
            revert cannot_register_new_candidate_voting_on_going_or_closed();
        candidates.push(_candidateAddress);
        list_candidate[_candidateAddress] = candidate(_name, _proposal, _id);
    }

    function newVoter(address _voter, string memory name) public isOwner {
        if (state != State.REGISTRATION)
            revert cannot_add_new_voter_voting_on_going_or_closed();
        voters.push(_voter);
        list_voters[_voter] = Voters(name, "", false);
    }

    function StartElection() public isOwner {
        state = State.ONGOING;
    }

    function displayCandidateDetails(
        address _candidate
    ) public view isOwner returns (string memory, string memory, uint256) {
        return (
            list_candidate[_candidate].name,
            list_candidate[_candidate].proposal,
            list_candidate[_candidate].id
        );
    }

    function Winner() public returns (string memory, uint256 number_of_votes) {
        if (state != State.CLOSED) revert voting_is_not_closed();
        string memory newStr="None";
        uint256 maxVotes = 0;
        for (uint256 i = 0; i < candidates.length; i++) {
            if (maxVotes < num_votes[candidates[i]]) {
                newStr = list_candidate[candidates[i]].name;
                maxVotes = num_votes[candidates[i]];
                winner = candidates[i];
            }
        }
        return (newStr, maxVotes);
    }

    function Delegate_voter(
        address _delegating,
        address _delegating_to
    ) public isOwner {
        delegate_voting[_delegating] = _delegating_to;
        list_voters[_delegating].delegated = true;
        for (uint256 i = 0; i < voters.length; i++) {
            if (voters[i] == _delegating) {
                voters[i] = _delegating_to;
            }
        }
    }

    function castVote(uint256 _id) public {
        if (state != State.ONGOING) revert voting_is_not_ongoing();
        address cad = identity[_id];
        if (voted[msg.sender] != true) revert already_voted();
        list_voters[msg.sender].voted_to = list_candidate[cad].name;
        voted[msg.sender] = true;
        num_votes[cad] = num_votes[cad] + 1;
    }

    function endElection() public isOwner {
        state = State.CLOSED;
    }

    function showResult(
        uint256 _id
    ) public returns (uint256, string memory, uint256) {
        address cad = identity[_id];
        return (
            list_candidate[cad].id,
            list_candidate[cad].name,
            num_votes[cad]
        );
    }

    function votersProfile(
        address _voter
    ) public returns (string memory, string memory, bool) {
        return (
            list_voters[_voter].name,
            list_voters[_voter].voted_to,
            list_voters[_voter].delegated
        );
    }
}