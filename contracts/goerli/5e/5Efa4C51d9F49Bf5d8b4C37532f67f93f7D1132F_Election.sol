// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

error Election__NotAdmin();
error Election__NoRightToVote();
error Election__AlreadyVoted();
error Election__InvalidCandidateId();
error Election__NotInSetupState();
error Election__NotInOpenState();

contract Election {
    enum ElectionState {
        SETUP,
        OPEN,
        CLOSED
    }

    struct Voter {
        bool hasRightToVote;
        bool voted;
    }

    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    ElectionState private s_electionState;
    address private immutable i_owner;
    mapping(address => Voter) private s_voters;
    mapping(uint256 => Candidate) private s_candidates;
    uint256 private s_votersCount = 0;
    uint256 private s_candidatesCount = 0;

    event CandidateAdded(uint256 indexed candidateId);
    event Voted(uint256 candidateId);

    modifier onlyAdmin() {
        if (msg.sender != i_owner) revert Election__NotAdmin();
        _;
    }

    modifier onlyApprovedVoter() {
        if (s_voters[msg.sender].hasRightToVote == false)
            revert Election__NoRightToVote();
        _;
    }

    modifier onlyDuringSetup() {
        if (s_electionState != ElectionState.SETUP)
            revert Election__NotInSetupState();
        _;
    }

    modifier onlyDuringVoting() {
        if (s_electionState != ElectionState.OPEN)
            revert Election__NotInOpenState();
        _;
    }

    constructor() {
        i_owner = msg.sender;
        s_electionState = ElectionState.SETUP;
    }

    function addVoter(address voterAddress) external onlyAdmin onlyDuringSetup {
        s_voters[voterAddress] = Voter(true, false);
        s_votersCount++;
    }

    function addCandidate(string memory name)
        external
        onlyAdmin
        onlyDuringSetup
    {
        s_candidatesCount++;
        s_candidates[s_candidatesCount] = Candidate(s_candidatesCount, name, 0);
        emit CandidateAdded(s_candidatesCount);
    }

    function startElection() external onlyAdmin onlyDuringSetup {
        s_electionState = ElectionState.OPEN;
    }

    function endElection() external onlyAdmin onlyDuringVoting {
        s_electionState = ElectionState.CLOSED;
    }

    function vote(uint256 candidateId)
        external
        onlyApprovedVoter
        onlyDuringVoting
    {
        if (s_voters[msg.sender].voted == true) revert Election__AlreadyVoted();
        if (candidateId <= 0 || candidateId > s_candidatesCount)
            revert Election__InvalidCandidateId();
        s_voters[msg.sender].voted = true;
        s_candidates[candidateId].voteCount++;
        emit Voted(candidateId);
    }

    function getVotersCount() external view returns (uint256) {
        return s_votersCount;
    }

    function getCandidatesCount() external view returns (uint256) {
        return s_candidatesCount;
    }

    function getElectionState() external view returns (ElectionState) {
        return s_electionState;
    }

    function getCandidate(uint256 candidateId)
        external
        view
        returns (Candidate memory)
    {
        return s_candidates[candidateId];
    }

    function getAdmin() external view returns (address) {
        return i_owner;
    }

    function getVoter(address voterAddress)
        external
        view
        returns (Voter memory)
    {
        return s_voters[voterAddress];
    }
}