/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Voting 
{    
    struct Voter 
    {    
        bool Registered;
        bool Voted;  
        uint votedProposalId;   
    }

    struct Proposal 
    {
        string description;   
        uint voteCount; 
    }

    enum WorkflowStatus 
    {
        RegisteringVoters, 
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    WorkflowStatus public workflowStatus;
    address public administrator;
    mapping(address => Voter) public voters;
    Proposal[] public proposals;
    uint private winningProposalId;

    modifier onlyAdministrator() 
    {
       require(msg.sender == administrator,"The caller is not an administrator.");
       _;
    }
    
    modifier onlyRegisteredVoter() 
    {
        require(voters[msg.sender].Registered,"The caller is not a registered voter.");
        _;
    }
    
    modifier onlyDuringVotersRegistration() 
    {
        require(workflowStatus == WorkflowStatus.RegisteringVoters,"This function can be called only before proposals registration has started.");
       _;
    }
    
    modifier onlyDuringProposalsRegistration() 
    {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted,"This function can be called only during proposals registration.");
       _;
    }
    
    modifier onlyAfterProposalsRegistration() 
    {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded,"This function can be called only after proposals registration has ended.");
       _;
    }
    
    modifier onlyDuringVotingSession() 
    {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted,"This function can be called only during the voting session.");
       _;
    }
    
    modifier onlyAfterVotingSession() 
    {
        require(workflowStatus == WorkflowStatus.VotingSessionEnded,"This function can be called only after the voting session has ended.");
       _;
    }
    
    modifier onlyAfterVotesTallied() 
    {
        require(workflowStatus == WorkflowStatus.VotesTallied,"This function can be called only after votes have been counted.");
       _;
    }
    
     event VoterRegisteredEvent(address voterAddress); 
     event ProposalsRegistrationStartedEvent();
     event ProposalsRegistrationEndedEvent();
     event ProposalRegisteredEvent(uint proposalId);
     event VotingSessionStartedEvent();
     event VotingSessionEndedEvent();
     event VotedEvent(address voter,uint proposalId);
     event VotesTalliedEvent();
     event WorkflowStatusChangeEvent(WorkflowStatus previousStatus,WorkflowStatus newStatus);
    
    constructor() 
    {
        administrator = msg.sender;
        workflowStatus = WorkflowStatus.RegisteringVoters;
    }
    
    function registerVoter(address _voterAddress) public onlyAdministrator onlyDuringVotersRegistration 
    {
        require(!voters[_voterAddress].Registered,"The voter is already registered.");
        voters[_voterAddress].Registered = true;
        voters[_voterAddress].Voted = false;
        voters[_voterAddress].votedProposalId = 0;
        emit VoterRegisteredEvent(_voterAddress);
    }
    
    function startProposalsRegistration() public onlyAdministrator  
    {
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;    
        emit ProposalsRegistrationStartedEvent();
        emit WorkflowStatusChangeEvent(WorkflowStatus.RegisteringVoters, workflowStatus);
    }
    
    function endProposalsRegistration() public onlyAdministrator onlyDuringProposalsRegistration 
    {
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit ProposalsRegistrationEndedEvent();
        emit WorkflowStatusChangeEvent(WorkflowStatus.ProposalsRegistrationStarted, workflowStatus);
    }
    
    function registerProposal(string memory proposalDescription) public onlyAdministrator onlyDuringProposalsRegistration 
    {
        proposals.push(Proposal({description: proposalDescription,voteCount: 0}));
        emit ProposalRegisteredEvent(proposals.length - 1);
    }
    
    function getProposalsNumber() public view returns (uint) 
    {
        return proposals.length;
    }
     
    function getProposalDescription(uint index) public view returns (string memory) 
    {
        return proposals[index].description;
    }    

    function startVotingSession() public onlyAdministrator onlyAfterProposalsRegistration 
    {
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit VotingSessionStartedEvent();
        emit WorkflowStatusChangeEvent(WorkflowStatus.ProposalsRegistrationEnded, workflowStatus);
    }
    
    function endVotingSession() public onlyAdministrator onlyDuringVotingSession 
    {
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit VotingSessionEndedEvent();
        emit WorkflowStatusChangeEvent(WorkflowStatus.VotingSessionStarted, workflowStatus);        
    }

    function vote(uint proposalId) onlyRegisteredVoter onlyDuringVotingSession public 
    {
        require(!voters[msg.sender].Voted, "This person has already voted.");
        voters[msg.sender].Voted = true;
        voters[msg.sender].votedProposalId = proposalId;
        proposals[proposalId].voteCount += 1;
        emit VotedEvent(msg.sender, proposalId);
    }

    function countVots() onlyAdministrator onlyAfterVotingSession public 
    {
        uint winningVoteCount = 0;
        uint winningProposalIndex = 0;    
        for (uint i = 0; i < proposals.length; i++) 
        {
            if (proposals[i].voteCount > winningVoteCount) 
            {
                winningVoteCount = proposals[i].voteCount;
                winningProposalIndex = i;
            }
        }
        winningProposalId = winningProposalIndex;
        workflowStatus = WorkflowStatus.VotesTallied;
        emit VotesTalliedEvent();
        emit WorkflowStatusChangeEvent(WorkflowStatus.VotingSessionEnded, workflowStatus);     
    }
    
    function Winning_Proposal_Id() onlyAfterVotesTallied public view returns (uint) 
    {
        return winningProposalId;
    }
    
    function Winning_Proposal() onlyAfterVotesTallied public view returns (string memory) 
    {
        return proposals[winningProposalId].description;
    }  
    
    function Winner_Vote_Count() onlyAfterVotesTallied public view returns (uint) 
    {
        return proposals[winningProposalId].voteCount;
    }   
    
    function Check_Voter_Registration(address _voterAddress) public view returns (bool) 
    {
        return voters[_voterAddress].Registered;
    }
     
    function Administrator() public view returns (address) 
    {
        return administrator;
    }     
     
    function Voting_Status() public view returns (WorkflowStatus) 
    {
        return workflowStatus;       
    }
}