/**
 *Submitted for verification at Etherscan.io on 2022-07-18
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

// File: Survey.sol


pragma solidity ^0.8.4;

// For implementing the modifer onlyOwner



contract Survey is Ownable {
    // Proposal Struct
    struct Proposal {
        address author; // Address of Proposer
        string title; // Title of Proposal
        string description; // Description of Proposal
        uint256 createdAt; // Block Height Created
        uint256 numOfOptions; // Number of Voting Options
        address[] voters; // An array of voters
        uint256 totalVotes; // Total Voted
    }

    // Part of the proposal struct
    mapping(uint256 => mapping(uint256 => string)) public proposalOptions; // Options String
    mapping(uint256 => mapping(uint256 => uint256)) public proposalCount; // Voting Count
    mapping(uint256 => mapping(address => bool)) public proposalStatus; // Voting status of a given address
    mapping(uint256 => mapping(address => uint256)) public proposalPower; // Voting power used by a given address

    // ERC20 token address
    address public voteToken;
    // Proposal Storage
    mapping(uint256 => Proposal) proposals; // 1,2,3,4,5,...
    // Set period to cast a vote
    uint256 constant VOTING_PERIOD = 1 days;
    // Set proposal Id
    uint public currentProposalId = 0;
    // Member whitelist for proposal creation
    mapping(address => bool) public whitelistMembers;

    // Constructor, with parameter as the voting token
    constructor (address _voteToken) {
        voteToken = _voteToken;
        whitelistMembers[msg.sender] = true; // Contract creator can make proposals by default
    }

    // Join the whitelist as a proposer
    function join(address _newMember) public onlyOwner {
        address user = _newMember;
        require(whitelistMembers[user] = true, "Already whitelisted");
        whitelistMembers[user] = true;   
    }

    // Create a proposal, need to be whitelisted
    function createProposal(string memory _name, string memory _description, string[] memory _optionsStringArray, uint256 _numOfOptions) public {
        require(whitelistMembers[msg.sender] = true ,"Only whitelisted members can create a proposal");

        address[] memory voters;
        for (uint i = 0; i < _numOfOptions; i++) {
            proposalOptions[currentProposalId][i] = _optionsStringArray[i];
        }
    
        proposals[currentProposalId] = Proposal(
            msg.sender, // address author; // Address of Proposer
            _name, // string title; // Title of Proposal
            _description, // string description; // Description of Proposal
            block.timestamp, // uint256 createdAt; // Block Height Created
            _numOfOptions, // uint256 numOfOptions; // Number of Voting Options
            voters, // address[] voters; // An array of voters
            0 // uint256 totalVotes; // Total Voted
        );

        currentProposalId++;
    }

    // Vote in any proposal
    function voteInProposal(uint256 _proposalId, uint256 _voteOption) public {
        // Retrieve the proposal
        Proposal storage proposal = proposals[_proposalId];

        // Sanity checks
        require(proposalStatus[_proposalId][msg.sender] == false, "You have already voted. ");
        require(block.timestamp <= proposal.createdAt + VOTING_PERIOD, "The voting period is over. ");

        // Retrieve ERC20 voting power
        IERC20 vToken = IERC20(voteToken);
        uint256 senderVotePower = vToken.balanceOf(msg.sender);

        // // Modify proposal struct
        proposal.voters.push(msg.sender); // Register as a voter
        proposalCount[_proposalId][_voteOption] += senderVotePower; // Increment the vote 
        proposalStatus[_proposalId][msg.sender] = true; // Mark as voted
        proposalPower[_proposalId][msg.sender] = senderVotePower; // Mark the sender voting power
        proposal.totalVotes += senderVotePower; // Increment the total votes
    }

    //// View functions
    function viewProposalStatus(uint256 _proposalId) public view returns(bool) {
        return (block.timestamp <= proposals[_proposalId].createdAt + VOTING_PERIOD);
    }

    // // // View Functions
    // function viewNumberOfProposals(uint256 _proposalId) public view returns(uint256) {
    //     return currentProposalId;
    // }

    // // View Functions
    function viewProposalDetails(uint256 _proposalId) public view returns(Proposal memory) {
        return proposals[_proposalId];
    }

    function viewUserVoteTokenBalance() public view returns(uint256)  {
        // Retrieve ERC20 voting power
        IERC20 vToken = IERC20(voteToken);
        return vToken.balanceOf(msg.sender);
    }
}