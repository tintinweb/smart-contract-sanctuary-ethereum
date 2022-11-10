/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @notice This interface is used to certify that an address can vote
 */
interface IRoles {
  /**
   * @notice Ask if the address is superAdmin
   * @param superAdmin_ the superAdmin ?
   * @return true if superAdmin, false otherwise
   */
  function isSuperAdmin(address superAdmin_) external view returns (bool);

  /**
   * @notice Returns if the 'admin' given is admin
   * @param user_ The admin
   * @return true if admin, false otherwise
   */
  function isAdmin(address user_) external view returns (bool);

  /**
   * @notice Gets the amount of admins
   * @return The amount of admins
   */
  function getAdminCount() external view returns (uint256);
}

/**
 * @notice Votation module
 */
contract Votation {
  /**
   * @notice The roles contract address
   */
  IRoles rolesContract;

  //! --------------------------------------------------------------------------- CONSTANTS ---------------------------------------------------------------------------

  /**
   * @notice The proposal should have 70% of the admins approval
   */
  uint8 constant SEMI_QUORUM = 0;

  /**
   * @notice The proposal should have 100% of the admins approval
   */
  uint8 constant FULL_QUORUM = 1;

  /**
   * @notice Flag to identify finished proposals
   */
  uint8 constant FINISHED = 1;

  /**
   * @notice Flag to identify if an admin has voted
   */
  uint8 constant VOTED = 1;

  //! --------------------------------------------------------------------------- STRUCTS ---------------------------------------------------------------------------

  /**
  * @notice Proposal structure
  * @param result This proposal result
  * @param quorum If this proposal should need full quorum
  * @param votesInFavor Amount of votes in favor
  * @param votesAgainst Amount of votes against
  * @param to Address where the code is executed
  * @param action Action to execute (in bytes)
  */
  struct Proposal {
    uint72 result;
    uint72 quorum;
    uint144 votesInFavor;
    uint144 votesAgainst;
    address to;
    bytes action;
  }

  /**
   * @notice Counter of proposals
   */
  uint256 public nextId;

  /**
   * @notice Deployer of the contract
   */
  address public deployer;

  /**
   * @notice Mapping to save proposal structures
   */
  mapping(uint256 => Proposal) public proposals;

  /**
   * @notice Mapping saving if an admin has votes 
   */
  mapping(address => mapping(uint144 => uint144)) public hasVoted;

  //! --------------------------------------------------------------------------- EVENTS ---------------------------------------------------------------------------
  /**
   * @notice Event for when a proposal is created
   */
  event ProposalCreated(address indexed authority_, uint256 id_);

  /**
   * @notice Event for when an admin has voted
   */
  event ProposalVoted(address indexed authority_, uint256 id_);

  /**
   * @notice Event for when an admin has cancelled a proposal
   */
  event ProposalCancelled(address indexed authority_, uint256 id_);

  /**
   * @notice Event for when an proposal is executed
   */
  event ProposalExecuted(uint256 id_);

  /**
   * @notice Event for when the contract is changed
   */
  event ContractChanged(address indexed newContract_);

  //! --------------------------------------------------------------------------- MODIFIERS ---------------------------------------------------------------------------

  /**
   * @notice Requires the msg.sender to be admin
   */
  modifier onlyAdmin {
    require(rolesContract.isAdmin(msg.sender), 'V202');
    _;
  }

  /**
   * @notice Builder 
   */
  constructor () {
    deployer = msg.sender;
  }

  //! --------------------------------------------------------------------------- CREATE PROPOSAL ---------------------------------------------------------------------------

  /**
   * @notice Function to create proposals
   * @param action_ The data to execute
   * @param quorum_ The quorum needed
   * @dev only admins can create a proposal
   */
  function createProposal(bytes memory action_, uint8 quorum_, address to_) public onlyAdmin {
    require((quorum_ == 0) || (quorum_ == 1), 'V201');
    rolesContract.getAdminCount() <= 3 ? 
      proposals[nextId] = Proposal(0, 1, 0, 0, to_, action_) : 
      proposals[nextId] = Proposal(0, quorum_, 0, 0, to_, action_);
    emit ProposalCreated(msg.sender, nextId);
    nextId++;
  }


  //! --------------------------------------------------------------------------- VOTING  ---------------------------------------------------------------------------

  /**
   * @notice function to validate vote parms
   * @param proposal_ Proposal Id to check
   */
  function _validateVoteParams(uint144 proposal_) internal view {
    require(proposal_ < nextId, 'V203'); 
    require(hasVoted[msg.sender][proposal_] != VOTED, 'V204');
    Proposal memory proposal = proposals[proposal_]; 
    require(proposal.result != FINISHED, 'V205'); 
  }

  /**
   * @notice function to refresh the proposal tatus after voting in favour
   * @param proposal_ proposa Id to refresh
  */
  function _refreshAfterFavourVote(uint144 proposal_) internal {
    Proposal storage proposal = proposals[proposal_];
    if (proposal.quorum == FULL_QUORUM) {
      if (proposal.votesInFavor >= rolesContract.getAdminCount()) {
        proposal.result = FINISHED;
        proposalFinished(proposal_);
      }
    } else {
      if (proposal.votesInFavor >= getQuorum(rolesContract.getAdminCount())) {
        proposal.result = FINISHED;
        proposalFinished(proposal_);
      }
    }
  }

  /**
   * @notice function to refresh the proposal tatus after voting against
   * @param proposal_ proposa Id to refresh
  */
  function _refreshAfterAgainstVote(uint144 proposal_) internal {
    Proposal storage proposal = proposals[proposal_]; 
    if (proposal.quorum == FULL_QUORUM) {
        proposal.result = FINISHED;
        emit ProposalCancelled(msg.sender, proposal_);
    } else {
      if (proposal.votesAgainst >= getQuorum(rolesContract.getAdminCount())) {
        proposal.result = FINISHED;
        emit ProposalCancelled(msg.sender, proposal_);
      }
    }
  }

  /**
   * @notice Function to vote a proposal
   * @param proposal_ Id of the proposal to vote
   * @dev only admins can vote
   */
  function voteInFavor(uint144 proposal_) public onlyAdmin {
    _validateVoteParams(proposal_);
    hasVoted[msg.sender][proposal_] = VOTED; 
    Proposal storage proposal = proposals[proposal_]; 
    proposal.votesInFavor++;
    emit ProposalVoted(msg.sender, proposal_);
    _refreshAfterFavourVote(proposal_);
    
  }

  /**
   * @notice Funtion to vote against a proposal
   * @param proposal_ Id of the proposal to vote
   * @dev Only admins
   */
  function voteAgainst(uint144 proposal_) public onlyAdmin  {
    _validateVoteParams(proposal_);
    hasVoted[msg.sender][proposal_] = VOTED;
    Proposal storage proposal = proposals[proposal_];
    proposal.votesAgainst++;
    emit ProposalVoted(msg.sender, proposal_);
    _refreshAfterAgainstVote(proposal_);
  }  

  //! --------------------------------------------------------------------------- FINISHED ---------------------------------------------------------------------------

  /**
   * @notice Funcion called when the proposal is finished
   * @param proposal_ Id of the proposal finished
   */
  function proposalFinished(uint144 proposal_) internal returns (bool) {
    bytes memory data_ = proposals[proposal_].action;
    address to_ = proposals[proposal_].to;
    uint256 dataLength_ = data_.length;
    bool result;
    assembly {
      let position := mload(0x40)
      let data := add(data_, 32)
      result := call(
        gas(),
        to_,
        0,
        data,
        dataLength_,
        position,
        0
      )
    }
    emit ProposalExecuted(proposal_);
    return result;
  }

  //! --------------------------------------------------------------------------- Getter & Setters ---------------------------------------------------------------------------

  /**
   * @notice Returns the 70% aprox of the amount given
   * @param number_ Amount given to calculate
   * @return The 75% of the param number
   */
  function getQuorum(uint number_) public pure returns (uint) {
    if (number_ <= 1) return number_;
    uint percent = ((number_ / 2) + ((number_ / 2) / 2));
    return (percent + 1) > (number_ / 2) ? percent : percent + 1;
  }

  //! -------------------------------------------------------------------- Set Modules module (only in deploy)-----------------------------------------------------------------------
  
  /**
   * @notice Sets the roles contract
   * @param newContract_ The address of the contract
   */
  function setVotationContract(address newContract_) public {
    require(msg.sender == deployer, 'V206');
    rolesContract = IRoles(newContract_);
    emit ContractChanged(newContract_);
    deployer = address(0);
  }

}