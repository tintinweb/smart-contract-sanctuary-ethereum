//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
  @title ZukiStaking contract which helps to Stake & Reward tokens
  @author HariPrakash ;) reference [email protected]
  @notice Add LP's, Stake Token in LP's, Withdraw LP Tokens, Withdraw reward tokens,
 */
contract ZukiStaking is Ownable, Pausable, ReentrancyGuard {
    string public constant name = "Zuki - Staking";

    //  total amount staked on pool
    mapping(uint256 => uint256) public totalStakedAmountInPool;
    mapping(address => bool) public blacklisted;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 stakingStartTime; // Staking start time in pool
        uint256 stakingEndTime; // Staking End time in pool
        bool hasStaked; // check is account staked
        bool isStaking; // check is account currently staking
        uint256 depositReward; // Reward for deposit
        uint256 interestReward; // Interest for staking period
        uint256 expectedReward; // expected reward of staking
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        IERC20 rewardToken; // Address of Reward token contract
        uint256 startTime; // Lp's start time
        uint256 endTime; // Lp's end time
        uint256 rewardRate; // reward rate in percentage (APR)
        uint256 duration; // duration of each user staking time to collect reward
        uint256 depositRewardRate; // user will get deposit-reward (stake amount * % / 100)
    }

    event Reward(address indexed from, address indexed to, uint256 amount);
    event StakedToken(address indexed from, address indexed to, uint256 amount);
    event UpdatedStakingEndTime(uint256 endTime);
    event WithdrawAll(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event AccountblacklistUpdated(address indexed account, bool status);
    event AccountsblacklistUpdated(address[] indexed accounts, bool status);

    // constructor ()  {
    //     // if needed need to write
    // }

    /**
       @dev get pool length
       @return current pool length
    */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
       @dev get current block timestamp
       @return current block timestamp
    */
    function getCurrentBlockTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    /**
       @dev setting staking pool end time
       @param _pid index of the array i.e pool id
       @param _endTime when staking pool ends
    */
    function setPoolStakingEndTime(uint256 _pid, uint256 _endTime)
        external
        virtual
        onlyOwner
        whenNotPaused
    {
        poolInfo[_pid].endTime = _endTime;
        emit UpdatedStakingEndTime(_endTime);
    }

    /** 
       @dev returns the total staked tokens in pool and it is independent of the total tokens in pool keeps
       @param _pid index of the array i.e pool id
       @return total staked amount in pool
    */
    function getTotalStakedInPool(uint256 _pid)
        external
        view
        returns (uint256)
    {
        return totalStakedAmountInPool[_pid];
    }

    /** 
       @dev returns the total staked user tokens in pool and it is independent of the total tokens in pool keeps
       @param _pid index of the array i.e pool id
       @return user staked balance in particular pool
    */
    function getUserStakedTokenInPool(uint256 _pid)
        external
        view
        returns (uint256)
    {
        return userInfo[_pid][msg.sender].amount;
    }

    /**
       @dev Add a new lp to the pool. Can only be called by the owner.
       @param _lpToken user staking token
       @param _rewardToken user rewarded token
       @param _startTime when pool starts
       @param _endTime when pool ends
       @param _rewardRate (APR) in %
    */
    function addPool(
        IERC20 _lpToken,
        IERC20 _rewardToken,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rewardRate,
        uint256 _duration,
        uint256 _depositReward
    ) public onlyOwner {
        _beforeAddPool(_startTime, _endTime, _rewardRate);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                rewardToken: _rewardToken,
                startTime: _startTime,
                endTime: _endTime,
                rewardRate: _rewardRate,
                duration: _duration,
                depositRewardRate: _depositReward
            })
        );
    }

    /**
       @dev AddPool validations.
       @param _startTime when pool starts
       @param _endTime when pool ends
       @param _rewardRate (APR) in %
    */
    function _beforeAddPool(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rewardRate
    ) internal virtual {
        require(
            block.timestamp >= _startTime,
            "STAKING: Start Block has not reached"
        );
        require(block.timestamp <= _endTime, "STACKING: Has Ended");
        require(
            _rewardRate > 0,
            "Reward Rate(APR) in %: Must be greater than 0"
        );
    }

    /**
       @dev Stake LP token's.
       @param _pid index of the array i.e pool id
       @param _amount staking amount
    */
    function stakeTokens(uint256 _pid, uint256 _amount)
        external
        virtual
        whenNotPaused
    {
        _beforeStakeTokens(_pid, _amount);
        require(!blacklisted[msg.sender], "Swap: Account is blacklisted");
        UserInfo storage user = userInfo[_pid][msg.sender];
        bool transferStatus = poolInfo[_pid].lpToken.transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        if (transferStatus) {
            // update user staking balance in particular pool
            user.amount = user.amount + _amount;
            // update Contract Staking balance in pool
            totalStakedAmountInPool[_pid] += _amount;
            // save the time when they started staking in particular pool
            user.stakingStartTime = block.timestamp;
            //staking end time of particular user in particular pool
            user.stakingEndTime =
                block.timestamp +
                (poolInfo[_pid].duration * 1 minutes);
            //expected reward after staking period
            user.expectedReward +=
                ((_amount * poolInfo[_pid].rewardRate) / 100) +
                ((_amount * poolInfo[_pid].depositRewardRate) / 100);
            //interest reward
            user.interestReward += ((_amount * poolInfo[_pid].rewardRate) /
                100);
            //deposit reward
            user.depositReward += ((_amount *
                poolInfo[_pid].depositRewardRate) / 100);
            // update staking status in particular pool
            user.hasStaked = true;
            user.isStaking = true;
            emit StakedToken(msg.sender, address(this), _amount);
        }
    }

    function _beforeStakeTokens(uint256 _pid, uint256 _amount)
        internal
        virtual
    {
        require(_amount > 0, "STAKING: Amount cannot be 0");
        require(_pid <= poolInfo.length, "Withdraw: Pool not exist");
        require(
            poolInfo[_pid].lpToken.balanceOf(msg.sender) >= _amount,
            "STAKING: Insufficient stake token balance"
        );
    }

    /**
       @dev check if the reward token is same as the staking token
         If staking token and reward token is same then -
         Contract should always contain more or equal tokens than staked tokens
         Because staked tokens are the locked amount that staker can unstake any time 
       @param _pid index of the array i.e pool id
       @param calculatedReward reward send to caller
       @param _toAddress caller address got reward
    */
    function SendRewardTo(
        uint256 _pid,
        uint256 calculatedReward,
        address _toAddress
    ) internal virtual returns (bool) {
        PoolInfo storage pool = poolInfo[_pid];
        require(_toAddress != address(0), "STAKING: Address cannot be zero");
        require(
            pool.rewardToken.balanceOf(address(this)) >= calculatedReward,
            "STAKING: Not enough reward balance"
        );

        if (pool.lpToken == pool.rewardToken) {
            if (
                (pool.rewardToken.balanceOf(address(this)) - calculatedReward) <
                totalStakedAmountInPool[_pid]
            ) {
                calculatedReward = 0;
            }
        }
        bool successStatus = false;
        if (calculatedReward > 0) {
            bool transferStatus = pool.rewardToken.transfer(
                _toAddress,
                calculatedReward
            );
            require(transferStatus, "STAKING: Transfer Failed");
            if (userInfo[_pid][_toAddress].amount == 0) {
                userInfo[_pid][_toAddress].isStaking = false;
            }
            // oldReward[_toAddress] = 0;
            emit Reward(address(this), _toAddress, calculatedReward);
            successStatus = true;
        }
        return successStatus;
    }

    /**
       @dev  withdraw all staked tokens and reward tokens
       @param _pid index of the array i.e pool id
     */
    function withdrawAll(uint256 _pid) external {
        require(_pid <= poolInfo.length, "Withdraw: Pool not exist");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount > 0, "Withdraw: Not enough reward balance");
        require(
            block.timestamp > user.stakingEndTime,
            "Staking period not yet completed"
        );
        uint256 reward = user.expectedReward;
        if (reward > 0) {
            uint256 rewardTokens = poolInfo[_pid].rewardToken.balanceOf(
                address(this)
            );
            require(
                rewardTokens > reward,
                "STAKING: Not Enough Reward Balance"
            );
            bool rewardSuccessStatus = SendRewardTo(_pid, reward, msg.sender);
            require(rewardSuccessStatus, "Withdraw: Claim Reward Failed");
        }
        user.expectedReward -= reward;
        user.interestReward = 0;
        user.depositReward = 0;
        uint256 amount = user.amount;
        user.amount = 0;
        user.isStaking = false;
        pool.lpToken.transfer(address(msg.sender), amount);
        emit WithdrawAll(msg.sender, _pid, amount);
    }

    /**
       @dev Emergency withdraw - withdraws all staked tokens and user gets null reward tokens
       @param _pid index of the array i.e pool id
     */
    function EmergencyWithdraw(uint256 _pid) external {
        require(_pid <= poolInfo.length, "Withdraw: Pool not exist");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(
            block.timestamp < user.stakingEndTime,
            "Staking reward already collected PLease withdraw it"
        );
        user.expectedReward = 0;
        user.interestReward = 0;
        user.depositReward = 0;
        uint256 amount = user.amount;
        user.amount = 0;
        user.isStaking = false;
        pool.lpToken.transfer(address(msg.sender), amount);
        emit WithdrawAll(msg.sender, _pid, amount);
    }
  

    /**
    @dev Include specific address for blacklisting
    @param account - blacklisting address
  */
    function includeInblacklist(address account) external onlyOwner {
        require(account != address(0), "Swap: Account cant be zero address");
        require(!blacklisted[account], "Swap: Account is already blacklisted");
        blacklisted[account] = true;
        emit AccountblacklistUpdated(account, true);
    }

    /**
    @dev Exclude specific address from blacklisting
    @param account - blacklisting address
  */
    function excludeFromblacklist(address account) external onlyOwner {
        require(account != address(0), "Swap: Account cant be zero address");
        require(blacklisted[account], "Swap: Account is not blacklisted");
        blacklisted[account] = false;
        emit AccountblacklistUpdated(account, false);
    }
   
    // returns all the pool info
    function getAllPoolInfo()public view returns(PoolInfo[]memory){
        return(poolInfo);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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