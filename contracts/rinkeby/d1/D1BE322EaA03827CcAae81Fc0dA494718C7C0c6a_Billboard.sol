pragma solidity 0.8.13;

import "Ownable.sol";
import "IERC20.sol";

/**
    ROADMAP BILLBOARD REWARDER
    A platform where users are incentived to find lit content before they get mass adoption.
    WHY?. i think its pretty cool when you have a chance to earn for finding a cool song from early on
    - A cool way to discover music,
    - Get rewarded for you sweet music taste
    - Promotes underground artist work

    FUNCTIONS
    - propose A song that you think will be a banger
    - vote on the proposed song
    - withdraw your rewards

    IDEA
    - maybe a user can only propose for the song they own as NFT
    - there should be a propose fee and vote fee
    - users should have the RANK TOKEN to vote and propose

    QUESTION
    - is there a limit to how many times a user can propose a song
    - how to do the math for calculation


 */


 contract Billboard is Ownable {
    /* WTF does this do?
        A platform where users are incentived to find lit content before they get mass adoption.
        WHY?. i think its pretty cool when you have a chance to earn for finding a cool song from early on
        - A cool way to discover music,
        - Get rewarded for your sweet music taste
        - Promotes underground artist work
    */

    uint8 public  constant DECIMALS = 6;

    
    uint256 public proposalCost; // 20 rank tokens
    uint256 public upvoteCost;   // 10 rank tokens
    address public tokenAddress;
    IERC20 rankToken;

    struct Song {
        // Tracks the time when the song was initially submitted
        uint256 submittedTime;
        // Tracks the block when the song was initially submitted (to facilitate calculating a score that decays over time)
        uint256 submittedInBlock;
        // Tracks the number of tokenized votes not yet withdrawn from the song.  We use this to calculate withdrawable amounts.
        uint256 currentUpvotes;
        // Tracks the total number of tokenized votes this song has received.  We use this to rank songs.
        uint256 allTimeUpvotes;
        // Tracks the number of upvoters (!= allTimeUpvotes when upvoteCost != 1)
        uint256 numUpvoters;
        // Maps a user's address to their place in the "queue" of users who have upvoted this song.  Used to calculate withdrawable amounts.
        mapping(address => Upvote) upvotes;
    }


    struct Upvote {
        uint index; // 1-based index
        uint withdrawnAmount;
    }

    mapping(bytes => Song) public songs;

    // This mapping tracks which addresses we've seen before.  If an address has never been seen, and
    // its balance is 0, then it receives a token grant the first time it proposes or upvotes a song.
    // This helps us prevent users from re-upping on tokens every time they hit a 0 balance.
    mapping(address => bool) public receivedTokenGrant;
    uint public tokenGrantSize = 100 * (10 ** DECIMALS);


    /**** ****** ******* ****** ****** 
                EVENTS
    ****** ******* ****** ****** ****/

    event SongProposed(address indexed proposer, bytes cid);
    event SongUpvoted(address indexed upvoter, bytes cid);
    event Withdrawal(address indexed withdrawer, bytes cid, uint tokens);
    event UpdateProposalCost(address indexed proposer, uint amount);
    event UpdateUpvoteCost(address indexed proposer, uint amount);
    constructor(address _address) {
        tokenAddress = _address;
        rankToken = IERC20(_address);
    }


    /**** ****** ******* ****** ****** 
                INITS
    ****** ******* ****** ****** ****/

    function setProposalCost(uint256 _amount)  public onlyOwner {
        proposalCost = _amount * (10 ** DECIMALS);
        emit UpdateProposalCost(msg.sender, _amount);

    }

    function setUpvoteCost(uint256 _amount)  public onlyOwner {
        upvoteCost = _amount * (10 ** DECIMALS);
        emit UpdateUpvoteCost(msg.sender, _amount);

    }

    /**** ****** ******* ****** ****** 
              PROPOSE &  UPVOTE LOGIC SER
    ****** ******* ****** ****** ****/

    modifier maybeTokenGrant {
        if (receivedTokenGrant[msg.sender] == false) {
            receivedTokenGrant[msg.sender] = true;
            rankToken.transferFrom(tokenAddress, msg.sender, tokenGrantSize);
        }
        _;
    }

    function propose(bytes memory cid) maybeTokenGrant public {
        require(songs[cid].numUpvoters == 0, "already proposed");
        require(rankToken.balanceOf(msg.sender) >= proposalCost, "sorry bro, not enough tokens to propose");


        
        Song storage song = songs[cid];
        song.submittedInBlock = block.number;
        song.submittedTime = block.timestamp;
        song.currentUpvotes += proposalCost;
        song.allTimeUpvotes += proposalCost;
        song.numUpvoters++;
        song.upvotes[msg.sender].index = song.numUpvoters;

        emit SongProposed(msg.sender, cid);


    }



    






 }

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: MIT
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