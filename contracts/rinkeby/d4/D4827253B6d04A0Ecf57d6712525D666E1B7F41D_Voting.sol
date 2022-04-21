// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

contract Voting {

  /*
    * get teachers list
  */
  mapping(address => bool) public teachers;

  /*
    * get student list
  */
  mapping(address => bool) public students;

  address public admin;

  address public chairman;

  /*
    * get voting status
  */
  bool votingEnabled;

  /*
    * get voting result
  */
  bool votingResult;


  /*
    * struct for voting choices
  */

  struct Choice {
    uint id;
    string name;
    uint votes;
  }

  /*
    * struct for voting Ballot
  */
  struct Ballot {
    uint id;
    string name;
    Choice[] choices;
  }

  mapping(uint => Ballot) ballots;
  uint nextBallotId;
  mapping(address => mapping(uint => bool)) votes;

  /**
    @notice Events to log public library
    */
    event CreateBallot(uint id, string name, string[] choices);

  constructor() {
    admin = msg.sender;
  }


  /*
    * set chairman
  */
  function setChairman(address _chairman) external onlyAdmin() {
    chairman = _chairman;
  }

  /*
    * set voting status
  */
  function setVotingStatus(bool _votingStatus) external {
    require(msg.sender == chairman);
    votingEnabled = _votingStatus;
  }

  /*
    * view voting status
  */
  function getVotingStatus() external view returns (bool) {
    return votingEnabled;
  }

  /*
    * set voting result
  */
  function setVotingResultStatus(bool _votingResult) external onlyAuthorized() {
    votingResult = _votingResult;
  }

    /*
    * view voting status
  */
  function getVotingResultStatus() external view returns (bool) {
    return votingResult;
  }

  /*
    * add teacher
  */
  function addTeachers(address[] calldata _teachers) external onlyAdmin() {
    for(uint i = 0; i < _teachers.length; i++) {
        teachers[_teachers[i]] = true;
    }
  }

  /*
    * add stuudent
  */
  function addStudents(address[] calldata _students) external onlyAdmin() {
    for(uint i = 0; i < _students.length; i++) {
        students[_students[i]] = true;
    }
  }

  /*
    * create ballot
  */
  function createBallot(
    string memory name,
    string[] memory _choices
    ) public onlyChairman() {
      ballots[nextBallotId].id = nextBallotId;
      ballots[nextBallotId].name = name;
      for(uint i = 0; i < _choices.length ; i++) {
        ballots[nextBallotId].choices.push(Choice(i, _choices[i], 0));
      }
    emit CreateBallot(nextBallotId, name, _choices);
    nextBallotId++;
    
  }

  /*
    * get ballot
  */

  function getBallot(uint _id) external view returns (Ballot memory) {
    return ballots[_id];
  }


  /*
    * vote
  */
  function vote(uint ballotId, uint choiceId) external onlyAuthorizedToVote() {
    require(votingEnabled, "Voting is not enabled");
    require(ballots[ballotId].choices[choiceId].id == choiceId, "Choice does not exist");
    require(votes[msg.sender][ballotId] == false, 'You have already voted, voter can only vote once for a ballot');
    votes[msg.sender][ballotId] = true;
    ballots[ballotId].choices[choiceId].votes++;
  }

  function results(uint ballotId)  view external returns(Choice[] memory) {
    require(votingResult, 'cannot see the ballot result until Chairman or Teacher has it shared');
    return ballots[ballotId].choices;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin, 'only admin');
    _;
  }

  modifier onlyAuthorized() {
    require((msg.sender == chairman) || (teachers[msg.sender] == true), 'only the chairman or authorized teacher');
    _;
  }

    modifier onlyAuthorizedToVote() {
    require((msg.sender == chairman) || (teachers[msg.sender] == true) || (students[msg.sender] == true), 'only the chairman or authorized teacher');
    _;
  }

  modifier onlyChairman() {
    require(msg.sender == chairman, 'only chairman');
    _;
  }

  

}