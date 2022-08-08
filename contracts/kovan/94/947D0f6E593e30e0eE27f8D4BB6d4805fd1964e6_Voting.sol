// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* Voting System for an organization, without factory patterm, that means this contract will have
 the information of all the porposals, the voting options can be written depending on
 proposal_id */

contract Voting {
  // owner sets admins, it's an admin by default
  address public owner = msg.sender;
  // Proposal Admins
  mapping(address => bool) public admins;
  // Proposals
  mapping(uint256 => Proposal) public Proposals;
  // Voting Options from particular proposal_id
  mapping(uint256=> mapping(uint256 => VotingOption)) public votingOptions;
  // Voters
  mapping(address => bool) public Voters;
  // checks the voting state of voter for a particular proposal_id
  mapping(uint256 => mapping(address => bool)) public voterState;
  // Check is proposal is still active
  mapping(uint256 => bool) public proposalState;

  uint256 public proposalsCount = 0;
  uint256 public currentOptions = 0;

  struct Proposal {
    uint256 id;
    string name;
    uint8 maxOptions;
    uint8 options;
    bool isOpen;
  }

  struct VotingOption {
    uint256 proposal_id;
    uint256 id;
    string name;
    uint256 voteCount;
  }

  modifier adminOnly() {
    require((msg.sender == owner) || (admins[msg.sender]), "Admin only");
    _;
  }

  modifier onlyOpenVotation(uint256 _proposal_id) {
    require(Proposals[_proposal_id].isOpen, "Votation is closed");
    _;
  }

  modifier onlyCloseVotation(uint256 _proposal_id) {
    require(
      !Proposals[_proposal_id].isOpen,
      "Votation is open cannot be changed"
    );
    _;
  }

  modifier validOption(uint256 _proposal_id, uint256 _option) {
    require(Proposals[_proposal_id].isOpen, "Votation is closed");
    require(_option < Proposals[_proposal_id].options, "Invalid option");
    _;
  }

  constructor() {
  }

  function addAdmin(address _admin) public {
    require(msg.sender == owner, "ERR WRG sender");
    admins[_admin] = true;
  }

  function banAdmin(address _admin) public {
    require(msg.sender == owner, "ERR WRG sender");
    admins[_admin] = false;
  }

  function allowVoter(address _voter) public adminOnly {
    Voters[_voter] = true;
  }

  function banVoter(address _voter) public adminOnly {
    Voters[_voter] = false;
  }

    function createNewProposal(string memory _name, uint8 _maxOptions)
    public
    adminOnly
  {
    Proposals[proposalsCount] = Proposal(
      proposalsCount,
      _name,
      _maxOptions,
      0,
      false
    );
    proposalsCount++;
  }

  function openVotation(uint256 _proposal_id) public adminOnly {
    proposalState[_proposal_id] = true;
    Proposals[_proposal_id].isOpen = true;
  }

  function closeVotation(uint256 _proposal_id) public adminOnly {
    proposalState[_proposal_id] = false;
    Proposals[_proposal_id].isOpen = false;
  }

  function addVotingOption(uint256 _proposal_id, string memory _name)
    public
    adminOnly
    onlyCloseVotation(_proposal_id)
  {
    require(
      Proposals[_proposal_id].options < Proposals[_proposal_id].maxOptions,
      "Max options reached"
    );
    uint256 optionNumber = Proposals[_proposal_id].options++;
    votingOptions[_proposal_id][optionNumber] = VotingOption(
      _proposal_id,
      optionNumber,
      _name,
      0
    );
    currentOptions++;
  }

  function vote(uint256 _proposal_id, uint256 _votedOption)
    public
    onlyOpenVotation(_proposal_id)
    validOption(_proposal_id, _votedOption)
  {
    require(Voters[msg.sender], "You are not allowed to vote");
    require(
      voterState[_proposal_id][msg.sender] == false,
      "You have already voted"
    );
    voterState[_proposal_id][msg.sender] = true;
    votingOptions[_proposal_id][_votedOption].voteCount++;
  }
}