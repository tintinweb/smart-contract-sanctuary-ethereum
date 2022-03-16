/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Voting {

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }
    struct Proposal {
        string description;
        uint voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    address private _admin;
    uint public winningProposalId;
    mapping(address=> bool) private _whitelist;
    WorkflowStatus currentStatus = WorkflowStatus.RegisteringVoters;

   

    // This declares a state variable that
    // stores a `Voter` struct for each possible address.
    mapping(address => Voter) public voters;

    // A dynamically-sized array of `Proposal` structs.
    Proposal[] public proposals;
    
    constructor () {
        
        _admin = msg.sender; // set admin to deployer address 
        //could have used ownable open zeppelin lib instead
    }
    modifier onlyAdmin() {
        require(msg.sender == _admin);
        _;
    } 

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    modifier withStatus(WorkflowStatus _status) {
        require(currentStatus == _status, "Wrong status");
        _;
    }

    function addProposal (string memory _description) public onlyWhitelisted {
        proposals.push(Proposal(_description, 0));
    }

    function startProposalRegistration() public onlyAdmin withStatus(WorkflowStatus.RegisteringVoters) {
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
        currentStatus = WorkflowStatus.ProposalsRegistrationStarted;
    }

    function getWinner() public view withStatus(WorkflowStatus.VotesTallied) returns (uint) {
        return winningProposalId;
    }

    function endProposalRegistration() public onlyAdmin withStatus(WorkflowStatus.ProposalsRegistrationStarted) {
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
        currentStatus = WorkflowStatus.ProposalsRegistrationEnded;
    }

    function startVote() public onlyAdmin withStatus(WorkflowStatus.ProposalsRegistrationEnded){
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
        currentStatus = WorkflowStatus.VotingSessionStarted;
    }

    function endVote() public onlyAdmin withStatus(WorkflowStatus.VotingSessionStarted){
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
        currentStatus = WorkflowStatus.VotingSessionEnded;
    }
 
    function whitelist(address _address) public onlyAdmin {
      require(!_whitelist[_address], "Already whitelisted");
      _whitelist[_address] = true;
    }
 
    function isWhitelisted(address _address) public view returns (bool){
      return _whitelist[_address];
    }

    function vote(uint _proposalNum) external onlyWhitelisted withStatus(WorkflowStatus.VotingSessionStarted){
        Voter storage sender = voters[msg.sender];
        require(!sender.hasVoted, "Already voted");
        sender.hasVoted = true;
        sender.votedProposalId = _proposalNum;
        proposals[_proposalNum].voteCount += 1;
        emit Voted(msg.sender, _proposalNum);
    }

    function tallyVotes() public onlyAdmin withStatus(WorkflowStatus.VotingSessionEnded){
        currentStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);

        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposalId = p;
            }
        }
    }

}