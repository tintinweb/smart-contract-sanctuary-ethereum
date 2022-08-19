/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/IERC20.sol


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

    function mint(address to, uint amount) external;

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
// File: contracts/StakingV2.sol


pragma solidity ^0.8.16;




contract StakingV2 is Ownable, ReentrancyGuard{
    
    address public RewardToken;             
    uint public TotalUsers;  
    uint public Time = 60;

    event NewStaker(uint _amount, uint _stakingTime);
    event TokenChanged(address _token);
    event RewardClaimed(uint result);
    event NewPoolCreated(address _token, uint _percentReward, uint _priceToStart);
    
    struct PoolInfo {
        address token;
        uint percentReward;              
        uint priceToStart;
        uint poolBalance;
    }

    struct UserInfo {
        uint amount;
        uint timeStart;
        uint stakingTime;
    }
  
    mapping(address => mapping(address => UserInfo)) public users;
    mapping(address => PoolInfo) public poolInfo;

    constructor(address _token) {
        RewardToken = _token;
    }

    function selfDestruct(address payable _owner) public onlyOwner{
        selfdestruct(_owner);
    }

    function changeToken(address _token) public onlyOwner{    
        RewardToken = _token;
        emit TokenChanged(_token);
    } 
    
    // calculate passed time of staking for user
    function calculatePassedTime(address _token) public view returns(uint timePassed) {
        require(users[_token][msg.sender].amount > 0, "You do not have staked assets");
        return block.timestamp - users[_token][msg.sender].timeStart;
    }

    function calculateReward(uint _amount, uint _stakingTime, uint _percent) public view returns(uint reward){
        uint periodPassed = _stakingTime/Time;
        return _amount*(_percent*periodPassed)/100;
    }

    function poolInstance(address _token, uint _percentReward, uint _priceToStart) public onlyOwner{
        PoolInfo storage pool = poolInfo[_token];
        pool.token = _token;
        pool.percentReward = _percentReward;
        pool.priceToStart = _priceToStart;
        emit NewPoolCreated(_token, _percentReward, _priceToStart);
    }
    
    function stake(uint _amount, address _token, uint _stakingTime) public nonReentrant {
        PoolInfo storage pool = poolInfo[_token];
        UserInfo storage user = users[_token][msg.sender];
        require(_stakingTime >= Time, "Wrong staking period");
        require(_amount >= pool.priceToStart, "Not enough amount to start");
        IERC20(pool.token).transferFrom(msg.sender, address(this), _amount);
        user.amount = _amount;
        user.timeStart = block.timestamp;
        user.stakingTime = _stakingTime;
        pool.poolBalance = pool.poolBalance + _amount;
        TotalUsers++;
        emit NewStaker(_amount, _stakingTime);
    }

    function unstake(address _token) public nonReentrant returns(uint) {
        PoolInfo storage pool = poolInfo[_token];
        UserInfo storage user = users[_token][msg.sender];
        require(block.timestamp - users[_token][msg.sender].timeStart >= users[_token][msg.sender].stakingTime, "Not enough time passed");
        uint result = _calculateReward(user.timeStart, user.amount, pool.percentReward);
        IERC20(pool.token).transfer(msg.sender, user.amount);
        IERC20(RewardToken).mint(msg.sender, result);
        pool.poolBalance = pool.poolBalance - user.amount;
        user.amount = 0;
        user.timeStart = 0;
        user.stakingTime = 0;
        TotalUsers--;
        emit RewardClaimed(result);
        return result;                            
    }
    
    // 1 period = 60 sec, for easily testing
    function _calculateReward(uint _timeStart, uint _amount, uint _percent) internal view returns(uint) {
        uint periodPassed = (block.timestamp - _timeStart)/Time;
        uint reward = _amount*(_percent*periodPassed)/100;
        return reward;
    }    
}