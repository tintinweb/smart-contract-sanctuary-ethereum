// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IStaking {
  function checkHighestStaker(address user) external returns (bool);
}

interface IERC20 {
   function balanceOf(address account) external view returns (uint256);
   function transfer(address recipient, uint256 amount) external returns (bool);
   function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Governance is Ownable{
	uint256 public votingPeriod;
	uint256 public proposalCount;
	
	address public USDC;
	address public TGC;
	address public staking;
	address public marketing;
	
	struct Proposal {
      uint256 id;
	  uint256 fundRequest;
      uint256 startTime;
      uint256 endTime;
      uint256 forVotes;
      uint256 againstVotes;
      uint256 abstainVotes;
      bool canceled;
      bool approved;
	  bool claimed;
	  uint256 voters;
	  address proposer;
	  mapping (address => Receipt) receipts;
    }
	
	struct Receipt {
	  bool hasVoted;
	  uint256 support;
    }
	
	enum ProposalState {
	  Pending,
	  Active,
	  Canceled,
	  Defeated,
	  Succeeded,
	  Approved,
	  Expired
    }
	
	mapping (address => bool) public isBlacklist;
	mapping (address => uint256) public latestProposalIds;
	mapping (uint => Proposal) public proposals;
	
    event ProposalCreated(uint256 id, address proposer, uint256 startTime, uint256 endTime, string description);
    event VoteCast(address indexed voter, uint256 proposalId, uint256 support, uint256 votes);
    event ProposalCanceled(uint256 id);
	event ProposalApproved(uint256 id);
	
    constructor () {
       votingPeriod = 86400 * 7;
	   USDC = address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
	   TGC = address(0xd50AF0A056Ec855A323854207b814518112651ff);
	   staking = address(0x1aAEbA6c3025Dc2581a15640E6F18FD38378bee9);
	   marketing = address(0x95207D592B54A85768f2b95059CeFb3e0E1c758A);
    }
	
    function propose(uint256 fundRequest, string memory description) public returns (uint256) {
        uint256 latestProposalId = latestProposalIds[msg.sender];
		if (latestProposalId != 0)
		{
           ProposalState proposersLatestProposalState = state(latestProposalId);
           require(proposersLatestProposalState != ProposalState.Active, "Governor::propose: one live proposal per proposer, found an already active proposal");
           require(proposersLatestProposalState != ProposalState.Pending, "Governor::propose: one live proposal per proposer, found an already pending proposal");
        }
		require(IStaking(staking).checkHighestStaker(msg.sender),"Governor::propose: only top staker");
		require(fundRequest <= 10000 * 10**18,"Governor::propose: max 10000 USDC limit");
		require(IERC20(USDC).balanceOf(marketing) >= fundRequest,"Governor::propose: insufficient fund in marketing wallet");
		require(!isBlacklist[msg.sender], "Governor::propose: proposer not whitelist to submit newProposal");
		
        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
		
        newProposal.id = proposalCount;
		newProposal.fundRequest = fundRequest;
        newProposal.proposer = msg.sender;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp + votingPeriod;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.abstainVotes = 0;
        newProposal.canceled = false;
        newProposal.approved = false;
		newProposal.claimed = false;
		newProposal.voters = 0;
		
        latestProposalIds[newProposal.proposer] = newProposal.id;
		IERC20(USDC).transferFrom(address(marketing), address(this), fundRequest);
		
        emit ProposalCreated(newProposal.id, msg.sender, block.timestamp, (block.timestamp + votingPeriod), description);
        return newProposal.id;
    }
	
    function cancel(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(msg.sender == proposal.proposer || msg.sender == owner(), "Governor::cancel: Other user cannot cancel proposal");
		require(proposal.approved == false, "Governor::cancel: cannot cancel approved proposal");
		
        proposal.canceled = true;
		IERC20(USDC).transferFrom(address(this), address(marketing), proposal.fundRequest);
        emit ProposalCanceled(proposalId);
    }
	
	function approved(uint256 proposalId) external onlyOwner{
        Proposal storage proposal = proposals[proposalId];
		require(proposal.canceled == false, "Governor::cancel: cannot approved cancel proposal");
		
		proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + votingPeriod;
        proposal.approved = true;
        emit ProposalApproved(proposalId);
    }
	
    function getReceipt(uint256 proposalId, address voter) external view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }
	
    function state(uint256 proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId, "Governor::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.timestamp >= proposal.startTime && proposal.approved == false) {
            return ProposalState.Pending;
        } else if (block.timestamp <= proposal.endTime && proposal.approved == true) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes) {
            return ProposalState.Defeated;
        } else if (proposal.approved) {
            return ProposalState.Approved;
        } else if (proposal.forVotes > proposal.againstVotes && votingPercent(proposalId) >= 65 && block.timestamp > proposal.endTime && proposal.voters >= 5) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Expired;
        }
    }
	
    function castVote(uint256 proposalId, uint256 support) external {
		require(IERC20(TGC).balanceOf(msg.sender) > 0, "Governor::castVote: not eligible for voting");
        emit VoteCast(msg.sender, proposalId, support, castVoteInternal(msg.sender, proposalId, support));
    }
	
    function castVoteInternal(address voter, uint proposalId, uint256 support) internal returns (uint256) {
        require(state(proposalId) == ProposalState.Active, "Governor::castVoteInternal: voting is closed");
        require(support <= 2, "Governor::castVoteInternal: invalid vote type");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "Governor::castVoteInternal: voter already voted");
		require(proposal.approved == true, "Governor::castVoteInternal: proposal not approved for vote");
		
        if (support == 0) 
		{
            proposal.againstVotes += IERC20(TGC).balanceOf(msg.sender);
        } 
		else if (support == 1) 
		{
            proposal.forVotes += IERC20(TGC).balanceOf(msg.sender);
        } 
		else if (support == 2) 
		{
            proposal.abstainVotes += IERC20(TGC).balanceOf(msg.sender);
        }
		proposal.voters += 1;
        receipt.hasVoted = true;
        receipt.support = support;
        return (proposal.forVotes + proposal.againstVotes + proposal.abstainVotes);
    }
	
	function whiteListAddress(address wallet, bool status) external onlyOwner{
	   isBlacklist[wallet] = status;
    }
	
	function claimFund(uint256 proposalId) external {
	   Proposal storage proposal = proposals[proposalId];
	   require(state(proposalId) == ProposalState.Succeeded, "Governor::castVoteInternal: proposal is not succeeded");
	   
	   proposal.claimed = true;
       IERC20(USDC).transferFrom(address(this), address(proposal.proposer), proposal.fundRequest);
    }
	
	function votingPercent(uint256 proposalId) public view returns(uint256){
	   Proposal storage proposal = proposals[proposalId];
	   
	   uint256 totalVote = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;
	   return totalVote / proposal.forVotes * 100;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}