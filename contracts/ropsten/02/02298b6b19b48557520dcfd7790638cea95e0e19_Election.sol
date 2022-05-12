pragma solidity ^0.4.20;

contract Election {

  struct Vote {
    string _hash;
    uint8 candidate;
  }

  struct Voter {
    address from;
    bool voted;
  }

  struct Candidate {
    string name;
    uint8 number;
    string party;
    string vice;
    string candidate_pic;
    string vice_pic;
  }

  // this variable holds the constracts creator, which is the election's administrator
  address private owner;

  // these variables hold the election's deadlines (descriptions below)
  uint256 private insertLimit; // must be given in seconds since the contract's creation
  uint256 private joinLimit;   // must be given in seconds since the contract's creation
  uint256 private voteLimit;   // must be given in seconds since the contract's creation

  // this variable defines if the contract is running or not
  bool private _isOn;

  // this variable holds the election's candidates
  mapping(uint8 => Candidate) private candidates;
  uint8[] private numberList;

  // this variable holds the election's votes
  mapping(string => Vote) private votes;
  mapping(uint8 => uint256) private appuration;
  uint8[] private votesList;

  // this variable holds the election's voters (the structures are redundant to ensure the hash is unique)
  mapping(address => Voter) private voters;
  address[] private votersList;

  // the constructor must receive the election's deadlines:
  // uint256 _insertLimit : the limit to the administrator to insert candidates (the edition limit goes until the first vote enters)
  // uint256 _joinLimit   : the limit to another external account to subscribe to the election
  // uint256 _voteLimit   : the limit to external accounts to insert their votes
  constructor(
    uint256 _insertLimit, // must be given in seconds since the contract's creation
    uint256 _joinLimit,   // must be given in seconds since the contract's creation
    uint256 _voteLimit    // must be given in seconds since the contract's creation
  ) public {
    owner = msg.sender;
    insertLimit = now + _insertLimit;
    joinLimit = now + _joinLimit;
    voteLimit = now + _voteLimit;
    _isOn = true;
  }

  // this function destroys the contract forever (only use in emergency case)
  function shut_down() public {

    // only the admin can perform this action
    require(msg.sender == owner, 'This action can be performed only by the account which created the contract');
    _isOn = false;
  }

  // this function lets the owner to input candidates into the election database
  function insert_candidate(string name, uint8 number, string party, string vice, string candidate_pic, string vice_pic) public {

    // admin
    require(msg.sender == owner, 'You do not have permission to execute this route');

    // any function in the contract only is executed if the election is on
    require(_isOn == true, 'This election is closed by the owner, sorry');

    // deadlines
    require(now <= insertLimit, 'The insertion deadline is over');
    require(votesList.length == 0, 'The voting already started, you cannot add more candidates');

    // doubles
    require(candidates[number].number == 0, 'This candidate has already been added. With you want to edit, delete and add again');

    // if the candidate's number already exists, it will be overwritten
    candidates[number].name = name;
    candidates[number].number = number;
    candidates[number].vice = vice;
    candidates[number].party = party;
    candidates[number].candidate_pic = candidate_pic;
    candidates[number].vice_pic = vice_pic;
    numberList.push(number);

    // start candidate's personal vote appuration
    appuration[number] = 0;
  }

  // this function lets the owner to delete candidates
  function delete_candidate(uint8 number) public {

    // admin
    require(msg.sender == owner, 'You do not have permission to execute this route');

    // any function in the contract only is executed if the election is on
    require(_isOn == true, 'This election is closed by the owner, sorry');

    // deadlines
    require(now <= insertLimit, 'The deletion deadline is over');
    require(votesList.length == 0, 'The voting already started, you cannot delete candidates');

    // deleting
    delete candidates[number];
    delete appuration[number];
  }

  // this function lets an external account to join as voter in the election
  // a voter, once joined, cannot withdraw
  function join_voter() public {

    // not admin
    require(msg.sender != owner, 'Only voters have permission to execute this route');

    // any function in the contract only is executed if the election is on
    require(_isOn == true, 'This election is closed by the owner, sorry');

    // deadlines
    require(now <= joinLimit, 'The join deadline is over');

    // duplicates - an account has as unique id the address and the user hash together (the hash should be unique, like a password)
    require(voters[msg.sender].from == 0, 'This account has already joined as voter with this address');

    // joining
    voters[msg.sender].from = msg.sender;
    voters[msg.sender].voted = false;

    votersList.push(msg.sender);
  }

  // this function allows you to vote
  function vote(uint8 number, string __hash) public {

    // not admin
    require(msg.sender != owner, 'Only voters have permission to execute this route');

    // any function in the contract only is executed if the election is on
    require(_isOn == true, 'This election is closed by the owner, sorry');

    // deadlines
    require(now <= voteLimit, 'The vote deadline is over');

    // joined
    require(voters[msg.sender].from != 0, 'This account has not joined as voter with this address');

    // already voted
    require(!voters[msg.sender].voted, 'You have already voted in this election');

    // valid number
    require(candidates[number].number != 0, 'This candidate does not exist');

    // vote;
    votes[__hash]._hash = __hash;
    votes[__hash].candidate = number;

    // already voted
    voters[msg.sender].voted = true;

    votesList.push(number);

    // appuration
    appuration[number] = appuration[number] + 1;
  }

  // this function returns the candidates stored in the Election
  function get_candidates() public view returns (uint8[]) {
    return numberList;
  }

  function get_candidate(uint8 number) public view returns (string, uint8, string, string) {
    return (candidates[number].name, candidates[number].number, candidates[number].party, candidates[number].vice);
  }
  
  function get_candidate_pic(uint8 number) public view returns (string) {
      return candidates[number].candidate_pic;
  }
  
  function get_vice_pic(uint8 number) public view returns (string) {
      return candidates[number].vice_pic;
  }

  // this function returns the candidate's appuration
  function get_appuration(uint8 candidate) public view returns (uint256) {
    return appuration[candidate];
  }

  // this function returns your joining status
  function has_joined() public view returns (bool) {
    require(msg.sender != owner, 'Only voters have permission to execute this route');  
    return (voters[msg.sender].from != 0);
  }

  // this function returns your voting status
  function has_voted() public view returns (bool) {
    require(msg.sender != owner, 'Only voters have permission to execute this route');
    return voters[msg.sender].voted;
  }

  // this function returns the votes
  function get_votes() public view returns (uint8[]) {
    return votesList;
  }

  // this function allows you to check your vote
  function check_vote(string __hash) public view returns (uint8) {
    require(msg.sender != owner, 'Only voters have permission to execute this route');
    require(votes[__hash].candidate != 0, 'This hash has not voted');
    return votes[__hash].candidate;
  }
}