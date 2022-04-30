/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract VotingApp{

    // *********************************************************
    // Setting up Smart Contract Variables
    // *********************************************************   

    address private admin;

    // voter variable
    struct Voter {
        uint256 voteSelected;   
        bool isRegistered;
        bool hasVoted;          
    }

    // candidate variable
    struct Candidate {
        uint256 candidateID;
        uint256 votingResult;
        bool isRegistered;          
        string candidateFullName;
    }


    // Voting Process Phases
    enum VotingStatus {
        VotingPreparation, 
        VotingRegistrationStarted, 
        VotingRegistrationEnded,
        VotingStarted,
        VotingFinished,
        VotingTallied,
        VotingAuditStarted,
        VotingFullyEnded
    }

    VotingStatus private votingStatus;

    // Mappint both strucuture type users to their addresses
    mapping(address => Voter) private voters;
    mapping(uint256 => Candidate) private candidates;

    uint256 public candidateID;
    uint256 public voterID;
    uint256 private candidateWinnerID;

    // *********************************************************
    // Settig Up Smart Contract Modifiers 
    // (Funtion Access Requirements)
    // *********************************************************   

    // Checks if the person accessing contract has same address as admin from constructor
    modifier onlyAdmin() {
       require(msg.sender == admin, 
       "Function can be run only by user who created this contract, the administrator.");
       _;
    }
    
    // Checks if  the user is registered for voting
    modifier onlyRegisteredVoter() {
        require(voters[msg.sender].isRegistered, 
        "The caller of this function must be a registered voter");
       _;
    }
    
    // Checks that it the is the voting preparation stage 
    modifier onlyDuringVotingPreparation() {
        require(votingStatus == VotingStatus.VotingPreparation, 
        "Function can run only during Registration stage");
       _; 
    }

    // Checks that it the is the voting registration stage 
    modifier onlyDuringVotingRegistration() {
        require(votingStatus == VotingStatus.VotingRegistrationStarted, 
        "Function can run only during Registration stage");
       _; 
    }

    // Checks that if the voting registration finished
    modifier onlyAfterVotingRegistrationEnded() {
        require(votingStatus == VotingStatus.VotingRegistrationEnded, 
        "Function can run only during Registration stage");
       _; 
    }

    // Checks that the actual voting process started
    modifier onlyDuringVoting() {
        require(votingStatus == VotingStatus.VotingStarted, 
        "Function can run only when Voting is started");
       _;
    }

    // Checks that the actual voting has ended
    modifier onlyAfterVoting() {
        require(votingStatus == VotingStatus.VotingFinished, 
        "Function can run only when Voting is finished");
       _;
    }

    // Checks that the actual voting has ended
    modifier onlyForResults() {
        require(votingStatus == VotingStatus.VotingTallied, 
        "Function can run only when Voting is finished");
       _;
    }


    // *********************************************************
    // Events that store arguments passed in transaction logs
    // *********************************************************   

    event candidateRegisteredEvent (string candidateFullName_, uint256 votingResult_); 

    event voterRegisteredEvent (address indexed votingAddress_);

    event VotingStatusChangeEvent (VotingStatus tellStatus_);

    // *********************************************************
    // Main Voting System Functions
    // *********************************************************   

    // The first time contract is deplayed, this constructor runs automatically
    // It sets the values in a way that the contract can be reused every time it runs
    constructor() {
        // Account of user who deployes the contract becomes administrator
        admin = msg.sender;
        // Initiate the number of candidates to start from 0 every time it is deployed
        candidateID = 0;
        // Initiate the number of voters  to start from 0 every time it is deployed
        voterID = 0;
        // Defines the first state in the voting proess as "Voting Preparation"
        votingStatus = VotingStatus.VotingPreparation;
    }

    // Start Registration Process
    function startRegistration() public onlyAdmin onlyDuringVotingPreparation {
        votingStatus = VotingStatus.VotingRegistrationStarted;

        emit VotingStatusChangeEvent(votingStatus);
    }

    // The following function registers the voters 
    function addCandidates (string memory _candidateFullName) onlyAdmin onlyDuringVotingRegistration public {

        // Add main candidate details (name, surname, and unique address)
        candidates[candidateID].candidateFullName = _candidateFullName;

        // setting that the cadidate already registered
        candidates[candidateID].isRegistered = true;
        // Resetting the votting tallie to 0 to starting point
        candidates[candidateID].votingResult = 0;
        // Preparing to add the next candidate, if there is one.
        candidateID += 1;

        emit candidateRegisteredEvent (candidates[candidateID].candidateFullName, candidates[candidateID].votingResult);
    }

    // Function that managers adding the voters to the blockchain
    // This process is managed by Administrator, only the approver users can be part of it
    function addVoters(address _voterAddress) onlyAdmin onlyDuringVotingRegistration public {
        // Make sure the voter is not reagistered already
        require(!voters[_voterAddress].isRegistered, "Person already resistered for voting");

        // initializing the key voter details
        voters[_voterAddress].isRegistered = true;
        voters[_voterAddress].hasVoted = false;
        voters[_voterAddress].voteSelected = 0;
        voterID += 1; 

        emit voterRegisteredEvent(_voterAddress);
        emit voterRegisteredEvent(_voterAddress);
        emit voterRegisteredEvent(_voterAddress);
    }

    // End Registration Process
    function endRegistration() public onlyAdmin onlyDuringVotingRegistration {
        votingStatus = VotingStatus.VotingRegistrationEnded;

        emit VotingStatusChangeEvent(votingStatus);
    }

    // Start Voting Process
    function startVotingProcess() public onlyAdmin onlyAfterVotingRegistrationEnded {
        votingStatus = VotingStatus.VotingStarted;

        emit VotingStatusChangeEvent(votingStatus);
    }

    // A function that is called in order for the voter
    // to submit the votes, only for registered voters
    // and only durig the votig session
    function voteSubmission(uint256 _voteId) onlyRegisteredVoter onlyDuringVoting public {
        //!!!!!!!! Do we need to check that user has voted already or not?
        //require(!voters[msg.sender].hasVoted, "The voter has already voted");
        require(_voteId<=candidateID, "There is no such ID candidate");        

        if (voters[msg.sender].hasVoted){
            candidates[voters[msg.sender].voteSelected].votingResult -= 1;    
        }

        // Setting that voter has already voted
        voters[msg.sender].hasVoted = true;
        // assiging the selection of the voter.
        voters[msg.sender].voteSelected = _voteId;
        // adding the value based on candidate ID
        candidates[_voteId].votingResult += 1;

        emit voterRegisteredEvent(msg.sender);
    }

    // End Voting Process
    function endVotingProcess() public onlyAdmin onlyDuringVoting {
        votingStatus = VotingStatus.VotingFinished;

        emit VotingStatusChangeEvent(votingStatus);
    }

    // This is the funtion that tallies the votes
    function tallyVotes() onlyAdmin onlyAfterVoting public {
        //Declaring variables within the function to avoid gas fees
        //These are local variables
        uint256 tempCount = 0;
        uint256 winnerID = 0;

        for (uint256 i = 0; i < candidateID; i++) {
            if (candidates[i].votingResult > tempCount) {
                tempCount = candidates[i].votingResult;
                winnerID = i;
            }
        }
        
        candidateWinnerID = winnerID;
        votingStatus = VotingStatus.VotingTallied;
    }

    // End Voting Process
    function endElections() public onlyAdmin onlyForResults {
        votingStatus = VotingStatus.VotingFullyEnded;

        emit VotingStatusChangeEvent(votingStatus);
    }


    // System can check if user is registered
    function isUserRegistered(address _userAddress) public view returns (bool) {
        return voters[_userAddress].isRegistered;
    }

    // Funtion that returns the cadidate name
    function getCandidateId(uint256 _candidateID) onlyDuringVoting public view returns (string memory candidate_){
        require(_candidateID<=candidateID, "There is no such ID candidate");        
        
        candidate_ = candidates[_candidateID].candidateFullName;
    }
         
    // Function that returns the winner
    function checkWinnerName () onlyForResults public view returns (string memory candidate_, uint256 result_) {
        candidate_ = candidates[candidateWinnerID].candidateFullName;
        result_ = candidates[candidateWinnerID].votingResult;
    }

     // Function to Check the Voting Stage Status
    function checkVotingStatus() public view returns (VotingStatus votingstatus_) {
        return votingStatus;       
    }

     // Function to Audit user votings
    function auditVotingResults(address _voterAddress) onlyForResults public view returns (uint256){
        return voters[_voterAddress].voteSelected;
    }

     // Function to Audit user votings
    function checkCandidateResults(uint256 _candidateResults) onlyForResults public view returns (string memory candidate_, uint256 result_){
        candidate_ = candidates[_candidateResults].candidateFullName;
        result_ = candidates[_candidateResults].votingResult;
    }


}