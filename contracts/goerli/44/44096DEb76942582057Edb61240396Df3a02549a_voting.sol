// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract voting {
  struct Election {
    address creator;
    string title;
    string[] names;
    uint[] number_of_votes;
    bool done;
  }

  Election[] all_elections;
  address public contract_creator;

  constructor() {
    contract_creator = msg.sender;
  }

  modifier onlyOwner() {
    bool is_creator = true;
    if (msg.sender != contract_creator) {
      is_creator = false;
    }
    require(
      is_creator,
      'You do NOT have permission to perform this operation, only the owner of this contract!'
    );

    _;
  }

  function create_election(
    string memory _title,
    string[] memory _candidates
  ) public onlyOwner {
    Election memory new_election;

    new_election.title = _title;
    new_election.creator = msg.sender;
    new_election.done = false;
    new_election.names = _candidates;
    new_election.number_of_votes = new uint[](_candidates.length);

    all_elections.push(new_election);
  }

  function vote(uint _election_index, uint _candidate_index) public onlyOwner {
    Election storage election = all_elections[_election_index];
    require(!election.done, 'this vote is already done');

    election.number_of_votes[_candidate_index]++;
  }

  function close_election(uint _election_index) public onlyOwner {
    Election storage election = all_elections[_election_index];
    require(!election.done, 'this vote is already done');

    election.done = true;
  }

  function get_all_elections() public view returns (Election[] memory) {
    return all_elections;
  }

  function get_length() public view returns (uint) {
    return all_elections.length;
  }

  function get_election(
    uint _election_index
  ) public view returns (Election memory) {
    return all_elections[_election_index];
  }
}