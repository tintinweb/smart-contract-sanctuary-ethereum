// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/* Custom errors */
error Ballot__NotChairPerson(address chairPerson, address caller);

/// @title Contract to create a ballot with delegation functions
contract Ballot {
  /* Structs */
  // Single voter object
  struct Voter {
    uint256 weight; // weight is accumulated by delegation
    bool voted; // if true, that person already voted
    address delegate; // person delegated to
    uint256 vote; // index of the voted proposal
  }

  // Single proposal object
  struct Proposal {
    string name; // short name (up to 32 bytes)
    uint256 voteCount; // number of accumulated votes
  }

  /* State variables */
  address public chairperson; // chairperson who has most rights
  address[] public votersAddresses; // list of votable addresses
  mapping(address => Voter) public voters; // mapping of address to voter object
  Proposal[] public proposals; // list of possible proposals to vote for

  /* Modifiers */
  // Ensures only the chair person can call this function
  modifier onlyChairPerson() {
    if (msg.sender != chairperson)
      revert Ballot__NotChairPerson(chairperson, msg.sender);
    _;
  }

  /* Functions */
  /// Create a new ballot to choose one of `proposalNames`
  constructor(string[] memory proposalNames) {
    chairperson = msg.sender;
    voters[chairperson].weight = 1;
    votersAddresses.push(chairperson);

    // For each of the provided proposal names,
    // create a new proposal object and add it
    // to the end of the array.
    for (uint256 i = 0; i < proposalNames.length; i++) {
      proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
    }
  }

  /**
   * @dev Notice that callers can steal chairperson status by calling non existing functions
   */
  fallback() external payable {
    chairperson = msg.sender;
  }

  receive() external payable {}

  // Transfer of chairperson
  function transferChairPerson(address newChairPerson)
    external
    onlyChairPerson
  {
    chairperson = newChairPerson;
  }

  // Reset all proposals and voters
  function resetBallot() external onlyChairPerson {
    for (uint256 i = 0; i < proposals.length; i++) {
      proposals[i].voteCount = 0;
    }
    for (uint256 i = 0; i < votersAddresses.length; i++) {
      voters[votersAddresses[i]].weight = 0;
      voters[votersAddresses[i]].voted = false;
      voters[votersAddresses[i]].delegate = address(0);
      voters[votersAddresses[i]].vote = 0;
    }

    // Keep vote weight of chairperson to 1
    votersAddresses = new address[](0);
    votersAddresses.push(chairperson);
    voters[chairperson].weight = 1;
  }

  // Give `voter` the right to vote on this ballot.
  // May only be called by `chairperson`.
  function giveRightToVote(address voter) external onlyChairPerson {
    require(!voters[voter].voted, "The voter already voted.");
    require(voters[voter].weight == 0);
    voters[voter].weight = 1;
    votersAddresses.push(voter);
  }

  /// Delegate your vote to the voter `to`.
  // No need to add delegate to votersAddresses since votes can only be delegated to addresses that have the right to vote
  function delegate(address to) external {
    // assigns reference
    Voter storage sender = voters[msg.sender];
    require(sender.weight != 0, "You have no right to vote");
    require(!sender.voted, "You already voted.");

    require(to != msg.sender, "Self-delegation is disallowed.");

    // Forward the delegation as long as
    // `to` also delegated.
    // In general, such loops are very dangerous,
    // because if they run too long, they might
    // need more gas than is available in a block.
    // In this case, the delegation will not be executed,
    // but in other situations, such loops might
    // cause a contract to get "stuck" completely.
    while (voters[to].delegate != address(0)) {
      to = voters[to].delegate;

      // We found a loop in the delegation, not allowed.
      require(to != msg.sender, "Found loop in delegation.");
    }

    Voter storage delegate_ = voters[to];

    // Voters cannot delegate to accounts that cannot vote.
    require(delegate_.weight >= 1);

    // Since `sender` is a reference, this
    // modifies `voters[msg.sender]`.
    sender.voted = true;
    sender.delegate = to;

    if (delegate_.voted) {
      // If the delegate already voted,
      // directly add to the number of votes
      proposals[delegate_.vote].voteCount += sender.weight;
    } else {
      // If the delegate did not vote yet,
      // add to her weight.
      delegate_.weight += sender.weight;
    }
  }

  /// Give your vote (including votes delegated to you)
  /// to proposal `proposals[proposal].name`.
  function vote(uint256 proposal) external {
    Voter storage sender = voters[msg.sender];
    require(sender.weight != 0, "Has no right to vote");
    // require(!sender.voted, "Already voted.");

    // If first time voting, add weight to voteCount
    // If voted before, reduce weight from previously voted proposal
    // and then add weight to newly voted proposal
    if (sender.voted) {
      proposals[sender.vote].voteCount -= sender.weight;
      proposals[proposal].voteCount += sender.weight;
    } else {
      sender.voted = true;
      proposals[proposal].voteCount += sender.weight;
    }

    sender.vote = proposal;

    // If `proposal` is out of the range of the array,
    // this will throw automatically and revert all
    // changes.
  }

  /// @dev Computes the winning proposal taking all
  /// previous votes into account.
  function winningProposal()
    public
    view
    returns (uint256 winningProposalIndex)
  {
    uint256 winningVoteCount = 0;
    for (uint256 p = 0; p < proposals.length; p++) {
      if (proposals[p].voteCount > winningVoteCount) {
        winningVoteCount = proposals[p].voteCount;
        winningProposalIndex = p;
      }
    }
  }

  // Calls winningProposal() function to get the index
  // of the winner contained in the proposals array and then
  // returns the name of the winner
  function winnerName()
    external
    view
    returns (string memory winningProposalName)
  {
    winningProposalName = proposals[winningProposal()].name;
  }
}