/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Vote.sol



pragma solidity 0.8.16;


contract Vote is Ownable {
   constructor(bool _isVoterProposal) {
      blockEvent = block.number;
      isVoterProposal = _isVoterProposal;
   }

   bool isVoterProposal;

   uint256 public blockEvent;
   uint256[] winningProposalID;

   struct Voter {
      bool isRegistered;
      bool hasVoted;
      uint256 votedProposalId;
   }

   struct Proposal {
      string description;
      uint256 voteCount;
   }

   enum WorkflowStatus {
      RegisteringVoters,
      ProposalsRegistrationStarted,
      ProposalsRegistrationEnded,
      VotingSessionStarted,
      VotingSessionEnded,
      VotesTallied
   }

   WorkflowStatus public workflowStatus;
   Proposal[] proposalsArray;
   address[] voter;
   mapping(address => Voter) voters;

   event VoterRegistered(address voterAddress);
   event WorkflowStatusChange(WorkflowStatus newStatus);
   event ProposalRegistered(uint256 proposalId);
   event Voted(address voter, uint256 proposalId);
   event GetWinning(uint256[] winningProposal);

   modifier onlyVoters() {
      require(voters[msg.sender].isRegistered, "You're not a voter");
      _;
   }

   // on peut faire un modifier pour les états

   // ::::::::::::: GETTERS ::::::::::::: //

   function getVoter(address _addr) external view returns (Voter memory) {
      return voters[_addr];
   }

   function getOneProposal(uint256 _id) external view returns (Proposal memory) {
      return proposalsArray[_id];
   }

   // ::::::::::::: REGISTRATION ::::::::::::: //

   function addVoter(address _addr) external onlyOwner {
      require(workflowStatus == WorkflowStatus.RegisteringVoters, "Voters registration is not open yet");
      require(voters[_addr].isRegistered != true, "Already registered");

      voters[_addr].isRegistered = true;
      voter.push(_addr);
      emit VoterRegistered(_addr);
   }

   // ::::::::::::: PROPOSAL ::::::::::::: //

   function addProposal(string memory _desc) external {
      require((msg.sender == owner() && !isVoterProposal) || (isVoterProposal && voters[msg.sender].isRegistered), "Vous ne pouvez pas enregistrer de proposition");
      require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "Proposals are not allowed yet");
      require(keccak256(abi.encode(_desc)) != keccak256(abi.encode("")), "Vous ne pouvez pas ne rien proposer");

      proposalsArray.push(Proposal(_desc, 0));
      emit ProposalRegistered(proposalsArray.length - 1);
   }

   // ::::::::::::: VOTE ::::::::::::: //

   function setVote(uint256 _id) external onlyVoters {
      if (workflowStatus != WorkflowStatus.VotingSessionStarted) revert("Voting session havent started yet");
      if (voters[msg.sender].hasVoted) {
         revert("You have already voted");
      }
      if (_id >= proposalsArray.length) revert("Cette proposition n'existe pas !");
      if (keccak256(abi.encodePacked(proposalsArray[_id].description)) == keccak256(abi.encodePacked(""))) {
         revert("This proposal is empty");
      }
      voters[msg.sender].votedProposalId = _id;
      voters[msg.sender].hasVoted = true;
      proposalsArray[_id].voteCount++;

      emit Voted(msg.sender, _id);
   }

   // ::::::::::::: STATE ::::::::::::: //

   function startProposalsRegistering() external onlyOwner {
      require(workflowStatus == WorkflowStatus.RegisteringVoters, "Registering proposals cant be started now");
      workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
      emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted);
   }

   function endProposalsRegistering() external onlyOwner {
      require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "Registering proposals havent started yet");
      workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
      emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded);
   }

   function startVotingSession() external onlyOwner {
      require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, "Registering proposals phase is not finished");
      workflowStatus = WorkflowStatus.VotingSessionStarted;
      emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted);
   }

   function endVotingSession() external onlyOwner {
      require(workflowStatus == WorkflowStatus.VotingSessionStarted, "Voting session havent started yet");
      workflowStatus = WorkflowStatus.VotingSessionEnded;
      emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded);
   }

   function tallyVotes() external onlyOwner {
      require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Current status is not voting session ended");

      uint256 _winningProposalId;

      for (uint256 p = 0; p < proposalsArray.length; p++) {
         if (proposalsArray[p].voteCount > proposalsArray[_winningProposalId].voteCount) {
            _winningProposalId = p;
         }
      }

      for (uint256 p = 0; p < proposalsArray.length; p++) {
         if (proposalsArray[p].voteCount == proposalsArray[_winningProposalId].voteCount) {
            winningProposalID.push(p);
         }
      }
      workflowStatus = WorkflowStatus.VotesTallied;
      emit WorkflowStatusChange(WorkflowStatus.VotesTallied);
      emit GetWinning(winningProposalID);
   }

   function reset() external onlyOwner {
      if (winningProposalID.length == 1) {
         for (uint256 v = 0; v < voter.length; v++) {
            voters[voter[v]] = Voter(false, false, 0);
         }
         blockEvent = block.number;
         delete winningProposalID;
         delete proposalsArray;
         workflowStatus = WorkflowStatus.RegisteringVoters;
         emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters);
      } else {
         for (uint256 v = 0; v < voter.length; v++) {
            voters[voter[v]] = Voter(true, false, 0);
         }
         uint256 vote = proposalsArray[winningProposalID[0]].voteCount;
         for (uint256 p = 0; p < proposalsArray.length; p++) {
            if (vote > proposalsArray[p].voteCount) {
               proposalsArray[p] = Proposal("", 0);
            } else proposalsArray[p].voteCount = 0;
         }
         delete winningProposalID;
         workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
         emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded);
      }
   }
}

// File: contracts/factory.sol



pragma solidity 0.8.16;





contract VoteFactory {
   //    address immutable myWallet;

   Vote[] public Contrats;

   event newContract(Vote contrat, uint256 id);

   //    constructor(address _myWallet) {
   //       myWallet = _myWallet;
   //    }

   function createVote(bool _isVoterProposal) public {
      Vote voting = new Vote(_isVoterProposal);
      Contrats.push(voting);
      emit newContract(voting, Contrats.length - 1);
   }

   //    function paid(address _token, uint256 _decimales) public {
   //       bool result = IERC20(_token).transferFrom(msg.sender, myWallet, 50 * _decimales);
   //       require(result, "Transfer from error");
   //    }
}