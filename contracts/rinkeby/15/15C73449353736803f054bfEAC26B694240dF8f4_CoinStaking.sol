// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IStaking.sol";

/// @title CoinStaking contract for two tokens
/// @notice Staking for GEAR and LP(GEAR/ETH) to GEAR tokens
contract CoinStaking is Ownable, ReentrancyGuard, IStaking {
    /// @notice PRECISION constant to save funds during division
    /// @dev Used in reward calculations
    uint256 public constant PRECISION = 1e12;

    /// @notice Token that pays as reward
    /// @dev Using IERC20 interface
    IERC20 public immutable rewardToken;

    /// @notice Keeps traking of reward balance
    /// @dev Use "depositReward" to increase, get reward to decrease
    uint256 public rewardBalance;

    /// @notice Overall reward for two pools
    /// @dev Changeble by "setRewardPerSecond" function
    uint256 public rewardPerSecond;

    /// @notice Summ of pool allocation points, use in calcaulation reward per pool
    /// @dev Used as divider while calculation of reward
    uint256 public totalAllocPoint;

    /// @notice When staking starts
    /// @dev Set it in constructor
    uint256 public startTime;

    /// @notice List of pools with information
    /// @dev There is only two pools
    PoolInfo[] public poolInfo;

    /// @notice Information about users in each pools
    /// @dev Mapping Pool_ID => User => user info
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    /// @notice User info struct
    /// @dev amount [BN] - staked, rewardDebt [BN] - earned
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    /// @notice Pool Info struct
    /// @dev token [address] - token to stake
    /// @dev allocationPoint [BN] - pool share of the total reward
    /// @dev lastRewardTime [number] - need to calculate accRewardPerShare
    /// @dev accRewardPerShare [BN] - summ of all shares to make magic
    struct PoolInfo {
        IERC20 token;
        uint256 allocPoint;
        uint256 lastRewardTime;
        uint256 accRewardPerShare;
        uint256 totalStaked;
    }

    /// @notice Event when user deposits
    /// @dev userAddress[address], pool_id [BN], tokenAmount [BN]
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);

    /// @notice Event user withdraws
    /// @dev userAddress[address], pool_id [BN], tokenAmount [BN]
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    /// @notice Event when user withdraws without calculating reward
    /// @dev Usefull when reward is over
    /// @dev userAddress[address], pool_id [BN], tokenAmount [BN]
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    /// @notice Should check that pool_id is correct
    /// @dev Pool_id should be 1 or 2
    /// @param _pid pool_id
    modifier correctPool(uint256 _pid) {
        require(_pid == 0 || _pid == 1, "wrong PID");
        _;
    }

    /// @notice Invokes while contact deploys
    /// @dev Reward and LP shouldn't be eq 0x0000 address
    /// @param _rewardToken [address] of reward token and staking token for first pool
    /// @param _lpToken [address] of staking token for second pool
    /// @param _rewardPerSecond [BN] reward to all pools per second
    /// @param _startTime [number] when staking starts
    /// @param _tokenPoolAllocPoint [BN] share of first pool
    /// @param _lpPoolAllocPoint [BN] share of second pool
    constructor(
        IERC20 _rewardToken,
        IERC20 _lpToken,
        uint256 _rewardPerSecond,
        uint256 _startTime,
        uint256 _tokenPoolAllocPoint,
        uint256 _lpPoolAllocPoint
    ) {
        require(
            address(_lpToken) != address(0) &&
                address(_rewardToken) != address(0),
            "Wrong token addresses"
        );
        rewardToken = _rewardToken;
        rewardPerSecond = _rewardPerSecond;
        startTime = _startTime;

        uint256 lastRewardTime = block.timestamp > startTime
            ? block.timestamp
            : startTime;

        poolInfo.push(
            PoolInfo({
                token: IERC20(_rewardToken),
                allocPoint: _tokenPoolAllocPoint,
                lastRewardTime: lastRewardTime,
                accRewardPerShare: 0,
                totalStaked: 0
            })
        );
        poolInfo.push(
            PoolInfo({
                token: IERC20(_lpToken),
                allocPoint: _lpPoolAllocPoint,
                lastRewardTime: lastRewardTime,
                accRewardPerShare: 0,
                totalStaked: 0
            })
        );

        totalAllocPoint = _tokenPoolAllocPoint + _lpPoolAllocPoint;
    }

    /// @notice Get pool lenth
    /// @dev It's always 2
    /// @return [BN] 2
    function poolLength() external view override returns (uint256) {
        return poolInfo.length;
    }

    /// @notice Get pending reward
    /// @dev Calculated with allocation of pool and accumulated reward
    /// @param _pid [BN] pool_id
    /// @param _user [address] whose reward is pending
    /// @return [BN] 0 or reward if staking exists
    function pendingReward(uint256 _pid, address _user)
        external
        view
        override
        correctPool(_pid)
        returns (uint256)
    {
        uint256 currentTime = block.timestamp;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 supply = pool.totalStaked;
        if (currentTime > pool.lastRewardTime && supply != 0) {
            uint256 multiplier = currentTime - pool.lastRewardTime;
            uint256 reward = (multiplier * rewardPerSecond * pool.allocPoint) /
                totalAllocPoint;

            accRewardPerShare += (reward * PRECISION) / supply;
        }

        return
            ((user.amount * accRewardPerShare) / PRECISION) - user.rewardDebt;
    }

    /// @notice Set reward per second to both pools
    /// @dev Reward will be split to pools via allocation point of each pool
    /// @param _rewardPerSecond [BN] Token reward in wei
    /// @param _withUpdate [bool] true to update reward now, false means update must be after next deposit/withdraw operation
    function setRewardPerSecond(uint256 _rewardPerSecond, bool _withUpdate)
        external
        override
        onlyOwner
    {
        if (_withUpdate) {
            massUpdatePools();
        }
        rewardPerSecond = _rewardPerSecond;
    }

    /// @notice Set allocation point to pool
    /// @dev Reward will be split to pool by (Reward*(poolAllocationPoint)) / totalAllocationPoint
    /// @param _pid [BN] poolID
    /// @param _allocPoint [BN] Pool share of total RewardPerSecond
    /// @param _withUpdate [bool] update now or it will updates after next deposit/withdraw at each pool
    function setPoolAllocPoint(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external override correctPool(_pid) onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint =
            (totalAllocPoint - poolInfo[_pid].allocPoint) +
            _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    /// @notice Owner can deposit reward via this function
    /// @dev RewardBalace should be updated after each change
    /// @param _amount [BN] Amount of tokens in wei to deposit
    function depositReward(uint256 _amount) external onlyOwner {
        rewardBalance += _amount;
        rewardToken.transferFrom(_msgSender(), address(this), _amount);
    }

    /// @notice Deposits funds to staking pool.
    /// @dev Possible when pool_id is correct. Also collects pending reward
    /// @param _pid [BN] pool_id , should be 0 for token => token and 1 for LP => token
    /// @param _amount [BN] amount to deposit in wei. Can be 0 to get reward only
    function deposit(uint256 _pid, uint256 _amount)
        external
        override
        nonReentrant
        correctPool(_pid)
    {
        address sender = _msgSender();
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][sender];

        updatePool(_pid);
        _payReward(sender, user, pool.accRewardPerShare);

        if (_amount > 0) {
            user.amount += _amount;
            pool.totalStaked += _amount;
            pool.token.transferFrom(sender, address(this), _amount);
        }
        user.rewardDebt = (user.amount * pool.accRewardPerShare) / PRECISION;

        emit Deposit(sender, _pid, _amount);
    }

    /// @notice Withdraws funds from staking with pending reward
    /// @dev Works when user has funds and pool_id is correct
    /// @param _pid [BN] pool_id , 0 or 1
    /// @param _amount [BN] amount of tokens to withdraw. Can be 0 to get reward only
    function withdraw(uint256 _pid, uint256 _amount)
        external
        override
        nonReentrant
        correctPool(_pid)
    {
        address sender = _msgSender();
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][sender];

        require(user.amount >= _amount, "Cannot withdraw this much");

        updatePool(_pid);
        _payReward(sender, user, pool.accRewardPerShare);

        if (_amount != 0) {
            pool.totalStaked -= _amount;
            user.amount -= _amount;
            pool.token.transfer(sender, _amount);
        }

        user.rewardDebt = (user.amount * pool.accRewardPerShare) / PRECISION;
        emit Withdraw(sender, _pid, _amount);
    }

    /// @notice Function to withdraw all funds without reward
    /// @dev Resets user info to initial values and returns funds
    /// @param _pid [BN] pool_id , can be 0 or 1
    function emergencyWithdraw(uint256 _pid)
        external
        override
        nonReentrant
        correctPool(_pid)
    {
        address sender = _msgSender();
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][sender];
        pool.token.transfer(sender, user.amount);
        pool.totalStaked -= user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        emit EmergencyWithdraw(sender, _pid, user.amount);
    }

    /// @notice Function to get mistaken sent tokens to owner.
    /// @dev Returns diff between the totalStaked and actual balance, or full balance of any token, if it's not GEAR or LP
    /// @param _token [address] address of token
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        uint256 amount;
        PoolInfo storage poolLP = poolInfo[1];

        if (_token == address(rewardToken)) {
            amount =
                rewardToken.balanceOf(address(this)) -
                poolInfo[0].totalStaked -
                rewardBalance;
            rewardToken.transfer(_msgSender(), amount);
        } else if (_token == address(poolLP.token)) {
            amount = poolLP.token.balanceOf(address(this)) - poolLP.totalStaked;
            poolLP.token.transfer(_msgSender(), amount);
        } else {
            amount = IERC20(_token).balanceOf(address(this));
            IERC20(_token).transfer(_msgSender(), amount);
        }
    }

    /// @notice Updates both pools manually
    /// @dev Same as updatePool(0) and updatePool(1)
    function massUpdatePools() public {
        updatePool(0);
        updatePool(1);
    }

    /// @notice Updates pool to calculate rewardPerShare
    /// @dev Works with right pool_id, invokes at depost/withdraw operation except emergency
    /// @param _pid [BN] pool_id , 0 or 1
    function updatePool(uint256 _pid) public correctPool(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 currentTime = block.timestamp;
        if (currentTime <= pool.lastRewardTime) {
            return;
        }

        uint256 supply = pool.totalStaked;
        if (supply == 0) {
            pool.lastRewardTime = currentTime;
            return;
        }
        uint256 multiplier = currentTime - pool.lastRewardTime;
        uint256 reward = (multiplier * rewardPerSecond * pool.allocPoint) /
            totalAllocPoint;
        pool.accRewardPerShare += (reward * PRECISION) / supply;
        pool.lastRewardTime = currentTime;
    }

    /// @notice Pays reward to user if any
    /// @dev If there is reward and it's less then rewardBalance
    function _payReward(
        address _recipient,
        UserInfo memory _userInfo,
        uint256 _accRewardPerShare
    ) internal {
        if (_userInfo.amount > 0) {
            uint256 pending = (_userInfo.amount * (_accRewardPerShare)) /
                (PRECISION) -
                (_userInfo.rewardDebt);
            if (pending > 0) {
                require(
                    rewardBalance >= pending,
                    "Reward is over, use emergencyWithdraw"
                );
                rewardBalance -= pending;
                rewardToken.transfer(_recipient, pending);
            }
        }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStaking {
    function poolLength() external view returns(uint256);
    function rewardPerSecond() external view returns(uint256);
    function pendingReward(uint256 _pid, address _user) external view returns(uint256); 
    function setRewardPerSecond(uint256 _rewardPerSecond, bool _withUpdate) external;
    function setPoolAllocPoint(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external;
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
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