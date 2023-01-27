/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

// File: contracts/StakeVRT.sol


pragma solidity 0.8.17;




interface IRsnacks {
    function mint(address to, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

contract StakeVRT is Ownable, ReentrancyGuard {
    struct Stake {
        uint256 amount;
        uint256 totalStakeTime;
        uint256 score;
        uint256 lastClaim;
        uint256 unlockTimestamp;
    }

    uint256 public constant MONTH = 30 days;
    uint256 public constant YEAR = 365 days;

    uint256 public userScoreDivisor = 1e15;
    uint256 public perSecondDivisor = 1e5;

    address public immutable snacks;
    address public immutable vrt;
    IRsnacks immutable iSnacks;
    IERC20 immutable iVrt;

    mapping(address => Stake) private stakes;

    event Deposit(address user, uint256 amount, uint256 period, uint256 rewardAmount, uint256 startTime);
    event Withdraw(address user, uint256 amount, uint256 rewardAmount, uint256 timestamp);
    event ClaimRewards(address user, uint256 amount, uint256 timestamp);
    event WithdrawToken(address user, address token, uint256 timestamp);
    event SetUserScoreDivisor(uint256 userScoreDivisor, uint256 timestamp);
    event SetPerSecondDivisor(uint256 perSecondDivisor, uint256 timestamp);
    event Redeem(address user, uint256 amount, uint256 rewardId, uint256 timestamp);

    constructor(address _vrt, address _rSnacks) {
        snacks = _rSnacks;
        iSnacks = IRsnacks(snacks);
        vrt = _vrt;
        iVrt = IERC20(vrt);
    }

    /**
    * @notice The main staking function.
    * @param depositAmount The amount to stake.
    * @param depositTime The period to stake.
    * Users may stake repeatedly, adding more tokens and/or more time to their stake.
    * (Up to a max of 1 year from block.timestamp)

    * Note: Reward calculation logic is replicated inline for gas optimization
    */
    function deposit(uint256 depositAmount, uint256 depositTime) external nonReentrant {
        require(depositTime <= YEAR, "1");
        Stake storage userStake = stakes[msg.sender];
        uint256 maxExtension = block.timestamp + YEAR - userStake.unlockTimestamp;
        uint256 stakeTimeIncrease = depositTime > maxExtension ? maxExtension : depositTime;
        // Reward calculation logic
        uint256 elapsedSeconds = block.timestamp - userStake.lastClaim;
        uint256 pendingReward = userStake.score * elapsedSeconds / perSecondDivisor;
        // End Reward calculation logic
        if(userStake.lastClaim == 0) { //Initial stake logic
            require(stakeTimeIncrease >= MONTH, "1"); // Minimum stake time is 1 month.
            userStake.lastClaim = block.timestamp;
            userStake.unlockTimestamp = block.timestamp + stakeTimeIncrease; // Initializes stake to now, increases it 
            userStake.amount = depositAmount;
            userStake.totalStakeTime = stakeTimeIncrease;
        } else{
            userStake.unlockTimestamp += stakeTimeIncrease;
            userStake.amount += depositAmount;
            userStake.totalStakeTime += stakeTimeIncrease;
            userStake.lastClaim = block.timestamp;
            iSnacks.mint(msg.sender, pendingReward);
        }
        userStake.score = userStake.amount * userStake.totalStakeTime / userScoreDivisor;
        if(depositAmount > 0){
            iVrt.transferFrom(msg.sender, address(this), depositAmount);
        }
        emit Deposit(msg.sender, userStake.amount, userStake.totalStakeTime, pendingReward, block.timestamp);
    }

    function withdraw() external nonReentrant {
        // Reward calculation logic
        Stake storage userStake = stakes[msg.sender];
        require(userStake.unlockTimestamp < block.timestamp, "5");
        uint256 elapsedSeconds = block.timestamp - userStake.lastClaim;
        uint256 rewardAmount = userStake.score * elapsedSeconds / perSecondDivisor;
        iVrt.transfer(msg.sender, userStake.amount);
        iSnacks.mint(msg.sender, rewardAmount);
        // End Reward calculation logic
        emit Withdraw(msg.sender, userStake.amount, rewardAmount, block.timestamp);
        delete(stakes[msg.sender]);
    }

    function claimRewards(address user) external nonReentrant {
        // Reward calculation logic
        Stake storage userStake = stakes[user];
        require(userStake.amount > 0, "2");
        uint256 elapsedSeconds = block.timestamp - userStake.lastClaim;
        uint256 rewardAmount = userStake.score * elapsedSeconds / perSecondDivisor;
        // End Reward calculation logic
        userStake.lastClaim = block.timestamp;
        iSnacks.mint(user, rewardAmount);
        emit ClaimRewards(user, rewardAmount, block.timestamp);
    }

    function withdrawETH() external onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }

    function withdrawToken(address token) external onlyOwner {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function redeemReward(uint256 rewardId, uint256 amount) external {
        iSnacks.burnFrom(msg.sender, amount);
        emit Redeem(msg.sender, amount, rewardId, block.timestamp);
    }

    function viewRewards(address user) external view returns (uint256) {
        // Reward calculation logic
        Stake storage userStake = stakes[user];
        uint256 elapsedSeconds = block.timestamp - userStake.lastClaim;
        uint256 rewardAmount = userStake.score * elapsedSeconds / perSecondDivisor;
        // End Reward calculation logic
        return rewardAmount;
    }

    function getStake(address user) 
        external 
        view 
        returns (
            uint256, 
            uint256, 
            uint256, 
            uint256, 
            uint256
        ) 
    {
        Stake storage userStake = stakes[user];
        return (
            userStake.amount, 
            userStake.totalStakeTime, 
            userStake.score, 
            userStake.lastClaim, 
            userStake.unlockTimestamp
        );
    }
    
    /**
    * @notice The userScoreDivisor can be set by only owner.
    * @param newUserScoreDivisor The score factor variable to set.
    */
    function setUserScoreDivisor(uint256 newUserScoreDivisor) public onlyOwner {
        require(newUserScoreDivisor > 0, "3");
        userScoreDivisor = newUserScoreDivisor;
        emit SetUserScoreDivisor(newUserScoreDivisor, block.timestamp);
    }
    
    /**
    * @notice The perSecondDivisor can be set by only owner.
    * @param newPerSecondDivisor The perSecondDivisor variable to set.
    */
    function setPerSecondDivisor(uint256 newPerSecondDivisor) public onlyOwner {
        require(newPerSecondDivisor > 0, "4");
        perSecondDivisor = newPerSecondDivisor;
        emit SetPerSecondDivisor(newPerSecondDivisor, block.timestamp);
    }
}