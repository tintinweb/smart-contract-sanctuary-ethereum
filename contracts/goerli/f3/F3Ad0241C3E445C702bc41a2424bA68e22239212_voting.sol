// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract voting {
  struct Vote {
    address creator;
    string title;
    string[] names;
    uint[] numberOfVotes;
    uint currentParticipants;
    uint totalParticipants;
    bool done;
  }

  Vote[] all_votes;
  address public contractCreator;

  constructor() {
    contractCreator = msg.sender;
  }

  modifier onlyOwner() {
    bool isCreator = true;
    if (msg.sender != contractCreator) {
      isCreator = false;
    }
    require(
      isCreator,
      'You do NOT have permission to perform this operation, only the owner of this contract!'
    );

    _;
  }

  function create_vote(
    string memory _title,
    string[] memory _candidates,
    uint _totalParticipants
  ) public onlyOwner {
    Vote memory newVote;
    newVote.title = _title;
    newVote.creator = msg.sender;
    newVote.done = false;
    newVote.names = _candidates;
    newVote.numberOfVotes = new uint[](_candidates.length);
    newVote.currentParticipants = 0;
    newVote.totalParticipants = _totalParticipants;

    all_votes.push(newVote);
  }

  function vote(uint _voteKey, uint _candidateKey) public onlyOwner {
    Vote storage v = all_votes[_voteKey];
    require(!v.done, 'This vote has already done!');
    require(
      v.currentParticipants > v.totalParticipants,
      'Maximum allowed total participants'
    );

    v.currentParticipants++;
    v.numberOfVotes[_candidateKey]++;
  }

  function close_vote(uint _voteKey) public onlyOwner {
    Vote storage v = all_votes[_voteKey];

    require(!v.done, 'This vote has already done');

    v.done = true;
  }

  function getAllVotes() public view returns (Vote[] memory) {
    return all_votes;
  }

  function getLength() public view returns (uint) {
    return all_votes.length;
  }

  function getVote(uint _voteKey) public view returns (Vote memory) {
    return all_votes[_voteKey];
  }
}