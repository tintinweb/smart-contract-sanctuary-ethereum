// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract DemOS {

  event NewElection(uint electionId);
  event NewCandidate(uint electionId, address candidateAddr);

  struct Voter {
    address votedFor; // address of the candidate that person voted for
  }

  struct Candidate {
    bytes32 name; // name of the candidate (max 32 char.)
    string  pitch; // the candidate election pitch
    uint    voteCount; // number of votes obtained
  }

  struct Election {
    uint      id;
    bytes32   name;
    uint      endDate;
    address[] candidates; // array of candidate addresses
    uint      totalVotes; // number of people who voted
    address   winner; // winner of the election
  }

  uint public electionIdCounter = 0; // Counter incremented each time there is a new election

  mapping (uint => Election) public elections;
  mapping (uint => mapping(address => Voter)) public voters;
  mapping (uint => mapping(address => Candidate)) public candidates;


  /// @notice Check that the election exists and is not closed.
  /// @param electionId Id of the election to check.
  modifier checkElectionIsValid(uint electionId) {
    require( // Election does not exists.
      elections[electionId].name != bytes32(0),
      "Election does not exists."
    );
    require(
      block.timestamp <= elections[electionId].endDate,
      "Election is now closed."
    );
    _;
  }


  /// @notice Return the number of candidates for an election.
  /// @param electionId Id of the election to check.
  /// @return uint Number of candidates.
  function totalCandidates(uint electionId) public view checkElectionIsValid(electionId) returns (uint) {
    return elections[electionId].candidates.length;
  }

  /// @notice Return the election associated with the given [electionId].
  /// @param electionId Id of the election to return
  /// @return election
  function getElection(uint electionId) public view returns (Election memory election) {
    return elections[electionId];
  }

  /// @notice Create an new election.
  /// @param name Name of the election.
  /// @param endDate End date of the election.
  function createElection(
    bytes32 name,
    uint endDate
  ) public {

    address[] memory candidatesList;

    elections[electionIdCounter] = Election(
      electionIdCounter,
      name, // name of the election
      endDate, // end date of the election in unix timestamp (seconds)
      candidatesList, // list of candidates address
      0, // total number of people who voted
      address(0x0) // winner address
    );
    emit NewElection(electionIdCounter);

    // Increment counter for next election creation
    electionIdCounter++;
  }

  /// @notice Run for an existing election.
  /// @param electionId Id of the election to run for.
  /// @param candidateName Display name use for the election campaign.
  function runForElection(
    uint electionId,
    bytes32 candidateName,
    string memory candidatePitch
  ) public checkElectionIsValid(electionId) {

    require( // Candidate name is invalid.
      candidateName != bytes32(0) && candidateName != bytes32(""),
      "Candidate name can't be empty."
    );
    require( // Sender is already candidate to that election.
      candidates[electionId][msg.sender].name == bytes32(0),
      "Sender is already candidate to that election."
    );

    candidates[electionId][msg.sender] = Candidate(
      candidateName,
      candidatePitch,
      0
    );

    // Add the candidate to the current election candidate list
    elections[electionId].candidates.push(msg.sender);
    emit NewCandidate(electionId, msg.sender);
  }

  /// @notice Vote for a candidate in an election.
  /// @param electionId Id of the election to vote in.
  /// @param candidateAddr Address of the candidate to vote for.
  function vote(uint electionId, address candidateAddr) public checkElectionIsValid(electionId) {

    Election storage election   = elections[electionId]; // Election the voter is voting in
    Voter storage voter         = voters[electionId][msg.sender];
    Candidate storage candidate = candidates[electionId][candidateAddr]; // Candidate whos receiving the vote

    require( // Voter has already voted in that election
      voter.votedFor == address(0x0),
      "Voter has already voted in that election."
    );
    require( // Voter tries to vote for someone who's candidate
      candidate.name != bytes32(0),
      "Trying to vote for someone who's not candidate to that election."
    );

    voter.votedFor = candidateAddr;
    candidate.voteCount++;
    election.totalVotes++;
    election.candidates.push(candidateAddr);
  }



}