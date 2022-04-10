// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TCGStakingFixedAPRLocked is Ownable {

    struct UserInfo {
        uint256 amount;         // How many Staking Tokens the user has provided.
        uint256 rewardDebt;     // Reward debt.
        uint256 stakeTimestamp; // Last stake time. Resets locking period for user
        uint256 totalReward;    // The total reward the user will receive over the staking period
    } 

    address public immutable rewardToken;   // Reward ERC-20 Token.
    address public immutable stakingToken;  // Staking ERC20 token
    address public treasuryAddress;
    bool public stakingEnabled = true;
    uint256 public stakeLockPeriod;         // Period to lock stake; 0 for no lock; used to calc tokens per minute for fixed apr
    uint256 public claimLockPeriod;         // Period to lock claim; 0 for no lock
    uint256 public apr;                     // 1000 = 10%
    uint256 public maxStake;                // Max total amount to stake
    uint256 private maxStakePlusOne;        // Utility variable for less gas
    uint256 public startBlock;              // The block number when token mining starts.
    uint256 public totalReward;             // Total pool rewards
    mapping(address => UserInfo) public UserInfos;    // User stake
    uint256 public rewardPerMinutePerToken; // Tokens distributed per minute
    uint256 public totalStaked;
    
    // _stakeLockPeriod and _claimLockPeriod are days
    constructor(address _rewardToken, address _stakingToken, uint256 _startBlock, address _treasuryAddress, uint256 _stakeLockPeriod,
        uint256 _claimLockPeriod, uint256 _apr, uint256 _maxStake, uint256 _totalReward) 
    {
        require(address(_rewardToken) != address(0), "_rewardToken address is invalid");
        rewardToken = _rewardToken;
        stakingToken = _stakingToken;
        startBlock = _startBlock == 0 ? block.number : _startBlock;        
        treasuryAddress = _treasuryAddress;
        stakeLockPeriod = _stakeLockPeriod * 1 days;
        claimLockPeriod = _claimLockPeriod * 1 days;
        apr = _apr;
        maxStake = _maxStake;
        maxStakePlusOne = _maxStake + 1;
        totalReward = _totalReward;
        rewardPerMinutePerToken = _totalReward * 1e12 * 60 / stakeLockPeriod / maxStake;
    }

    /**** USER FUNCTIONS ****/

    function deposit(uint256 _amount) public {
        require(stakingEnabled, "STAKING_DISABLED");
        require(totalStaked + _amount < maxStakePlusOne, "MAX_STAKED");
        UserInfo storage user = UserInfos[_msgSender()];
        if (_amount == 0 && user.amount > 0 && user.rewardDebt != user.totalReward &&
            user.stakeTimestamp + claimLockPeriod < block.timestamp)
        {
            uint256 pending = user.amount * rewardPerMinutePerToken * (block.timestamp - user.stakeTimestamp) / 60 / 1e12 - user.rewardDebt;
            pending = user.rewardDebt + pending < user.totalReward ? pending : user.totalReward - user.rewardDebt;
            if (pending > 0) {
                tokenTransfer(_msgSender(), pending);
            }
            user.rewardDebt += pending;
            user.rewardDebt = user.rewardDebt > user.totalReward ? user.totalReward : user.rewardDebt;
        }
        if (_amount > 0) {
            IERC20(stakingToken).transferFrom(address(_msgSender()), address(this), _amount);
            user.amount += _amount;
            user.stakeTimestamp = block.timestamp;
            user.totalReward = user.amount * apr / 1e4;
            totalStaked += _amount;
        }
        emit Deposit(_msgSender(), _amount);
    }

    function withdraw() public {
        UserInfo storage user = UserInfos[_msgSender()];
        require(user.amount > 0, "NO_STAKE");
        require(user.stakeTimestamp + stakeLockPeriod <= block.timestamp, "STAKE_LOCKED");

        // send pending rewards
        uint256 pending = user.totalReward - user.rewardDebt;
        if (pending > 0) {
            tokenTransfer(_msgSender(), pending);
        }
        // send pending stake
        IERC20(stakingToken).transfer(address(_msgSender()), user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        user.stakeTimestamp = block.timestamp;
        user.totalReward = 0;
        // do not update totalStaked, as it's used to manage maxStake for entire pool
        emit Withdraw(_msgSender());
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        UserInfo storage user = UserInfos[_msgSender()];
        require(user.amount > 0, "NO_STAKE");
        IERC20(stakingToken).transfer(address(_msgSender()), user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        user.stakeTimestamp = block.timestamp;
        user.totalReward = 0;
        emit EmergencyWithdraw(_msgSender());
    }

    /**** VIEWS ****/

    function getPending(address _user) external view returns(uint256) {
        UserInfo memory user = UserInfos[_user];
        return user.amount * rewardPerMinutePerToken * (block.timestamp - user.stakeTimestamp) / 60 / 1e12 - user.rewardDebt;
    }

    function getStakeLockTime(address _user) external view returns(uint256) {
        UserInfo memory user = UserInfos[_user];
        return block.timestamp > user.stakeTimestamp + stakeLockPeriod ? 0
            : user.stakeTimestamp + claimLockPeriod - block.timestamp;
    }

    function getClaimLockTime(address _user) external view returns(uint256) {
        UserInfo memory user = UserInfos[_user];
        return block.timestamp > user.stakeTimestamp + claimLockPeriod ? 0
            : user.stakeTimestamp + claimLockPeriod - block.timestamp;
    }

    // View function to see pending tokens on frontend.
    function pendingRewards(address _user) external view returns (uint256) {
        UserInfo memory user = UserInfos[_user];
        if (user.amount > 0) {
            uint256 pending = user.amount * rewardPerMinutePerToken * (block.timestamp - user.stakeTimestamp) / 60 / 1e12 - user.rewardDebt;
            if (pending > 0 && user.totalReward - pending >= 0 ) {
                return pending;
            }
        }
        return 0;
    }

    /**** UTILITY ****/

    // Safe token transfer function, just in case if
    // rounding error causes pool to not have enough tokens
    function tokenTransfer(address _to, uint256 _amount) internal {
        //uint256 balance = IERC20(reward).balanceOf(address(this));
        uint256 amount = _amount > totalReward ? totalReward : _amount;
        IERC20(rewardToken).transfer(_to, amount);
        totalReward -= amount;
    }

    /**** ADMIN ****/

    function setTotalReward(uint256 amount) external onlyOwner {
        totalReward = amount;
        rewardPerMinutePerToken = totalReward * 1e12 * 60 / stakeLockPeriod / maxStake;
    }

    function setStakingEnabled(bool enabled) external onlyOwner {
        stakingEnabled = enabled;
    }

    function transferTokens(address _tokenAddr) external {
        IERC20(_tokenAddr).transfer(treasuryAddress, IERC20(_tokenAddr).balanceOf(address(this)));
    }    

    function withdrawETH() external {
        require(treasuryAddress != address(0), "TREASURY_NOT_SET");
        uint256 bal = address(this).balance;
        (bool sent, ) = treasuryAddress.call{value: bal}("");
        require(sent, "FAILED_SENDING_FUNDS");
        emit WithdrawETH(_msgSender(), bal);
    }  

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user);
    event EmergencyWithdraw(address indexed user);
    event WithdrawETH(address indexed sender, uint256 indexed balance);
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