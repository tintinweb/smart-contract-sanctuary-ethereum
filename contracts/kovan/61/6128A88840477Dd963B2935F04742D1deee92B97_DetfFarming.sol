// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DetfFarming is Ownable {
    // 3 MONTHS
    uint256 constant UNLOCK_TIME =  60 * 15;//60 * 60 * 24 * 90;

    IERC20 public immutable rewardToken;
    IERC20 public immutable lpToken;

    uint256 public rewardAmount;
    uint256 public totalStaked;
    uint256 public rewardPerSec;

    uint256 public farmingDuration;
    uint256 public farmingEnd;

    PoolInfo public pool;
    mapping(address => UserInfo) public userInfo;
    // for withdraw finc, save if withdraw proccess was sharted
    mapping(address => bool) public isWithdraw;
    // for withdraw func, save how many lp token user already withdraw
    mapping(address => uint256) public lpWithdrawed;

    // Info of each user
    struct UserInfo {
        uint256 amount; // how many LP tokens the user has provided.
        uint256 rewardDebt; // locked amount
        uint256 accReward; // saved reward
    }

    // Info of each pool.
    struct PoolInfo {
        uint256 lastRewardUpdateTimestamp; // last timestamp, when reward updated
        uint256 accRewardPerShare; // accumulated reward tokens per share, times 1e12
    }

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(
        address indexed user,
        uint256 lpAmount,
        uint256 rewardAmount
    );
    event EmergencyWithdraw(address indexed user, uint256 amount);

    /**
     * @param _lpToken - address of lp token usdc/d-etf
     * @param _rewardToken - address of d-etf token
     */
    constructor(IERC20 _lpToken, IERC20 _rewardToken) {
        rewardToken = _rewardToken;
        lpToken = _lpToken;
    }

    /**
     * @notice allow owner setup farming,
     * tokens must be approved for rewardAmount before call
     * @dev create pool, set fermingDuration = month
     * @param _rewardAmount - initial amount of reward token * decimals
     * @param startTimestamp - timestamp, from which the accrual of rewards starts
     */
    function setupFarming(uint256 _rewardAmount, uint256 startTimestamp)
        external
        onlyOwner
    {
        require(farmingEnd == 0, "Farming already started");
        require(
            block.timestamp < startTimestamp,
            "Farming can't start before setup"
        );
        rewardAmount = _rewardAmount;
        uint256 days30 = 60 * 5; //60 * 60 * 24 * 30;
        farmingDuration = days30;
        farmingEnd = startTimestamp + days30;
        rewardPerSec = _rewardAmount / days30;
        pool = PoolInfo(startTimestamp, 0);
        require(
            rewardToken.transferFrom(_msgSender(), address(this), _rewardAmount),
            "Token transfer error"
        );
    }

    /**
     * @notice allow owner increase rewardPerSec, without change farmin duration,
     * tokens must be approved for _rewardAmount before call
     * @param _rewardAmount - for this amount total reward amount will be increased
     */
    function increaseRewardPerSec(uint256 _rewardAmount) external onlyOwner {
        require(block.timestamp < farmingEnd, "Farming is over");
        updatePool();
        rewardAmount += _rewardAmount;
        rewardPerSec = rewardAmount / farmingDuration;
        require(
            rewardToken.transferFrom(_msgSender(), address(this), _rewardAmount),
            "Token transfer error"
        );
    }

    /**
     * @notice allow owner increase farming duration, without change rewardPerSec,
     * tokens must be approved for rewardIncrease before call
     * @param timeIncrease - time in seconds to increase farming duration
     */
    function increaseFarmingDuration(uint256 timeIncrease) external onlyOwner {
        require(block.timestamp < farmingEnd, "Farming is over");
        updatePool();
        farmingDuration += timeIncrease;
        farmingEnd += timeIncrease;
        uint256 rewardIncrease = farmingDuration * rewardPerSec - rewardAmount;
        rewardAmount += rewardIncrease;
        require(
            rewardToken.transferFrom(_msgSender(), address(this), rewardIncrease),
            "Token transfer error"
        );
    }

    /**
     * @notice calclate multiplier for pendingReward
     * @param _from - timestamp of last reward update
     * @param _to - now timestamp
     * @return miltiplier = how many seconds have passed
     * between _from and _to or farmingEnd
     */
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= farmingEnd) {
            return _to - _from;
        } else if (_from >= farmingEnd) {
            return 0;
        } else {
            return farmingEnd - _from;
        }
    }

    /** @notice view function to see pending reward on frontend.
     * @param _user - address of user, which reward will be returned
     * @return total reward amount accumulated for user
     */
    function pendingReward(address _user) public view returns(uint256) {
        UserInfo memory user = userInfo[_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        if (
            block.timestamp > pool.lastRewardUpdateTimestamp && totalStaked != 0
        ) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardUpdateTimestamp,
                block.timestamp
            );
            uint256 reward = multiplier * rewardPerSec;
            accRewardPerShare += (reward * 1e12) / totalStaked;
        }
        return
            (user.amount * accRewardPerShare) /
            1e12 -
            user.rewardDebt +
            user.accReward;
    }

    /**
     * @notice update reward variables of the pool to be up-to-date
     */
    function updatePool() private {
        if (
            block.timestamp <= pool.lastRewardUpdateTimestamp ||
            pool.lastRewardUpdateTimestamp > farmingEnd
        ) {
            return;
        }
        if (totalStaked == 0) {
            pool.lastRewardUpdateTimestamp = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(
            pool.lastRewardUpdateTimestamp,
            block.timestamp
        );
        uint256 reward = multiplier * rewardPerSec;
        pool.accRewardPerShare += (reward * 1e12) / totalStaked;
        pool.lastRewardUpdateTimestamp = block.timestamp;
    }

    /**
     * @notice allow users deposit their lp tokens and increase their
     * amount later, tokens must be approved for amount,
     * fire Deposit event
     * @param amount - how many lp tokens user wants to deposit
     * @dev can be called before farming setup and before farmingStart
     */
    function deposit(uint256 amount) external {
        require(
            block.timestamp < farmingEnd && farmingEnd != 0,
            "Farming is over"
        );
        require(amount != 0, "Zero amount");

        updatePool();
        UserInfo storage user = userInfo[_msgSender()];

        if (user.amount > 0) {
            user.accReward +=
                (user.amount * pool.accRewardPerShare) /
                1e12 -
                user.rewardDebt;
        }

        user.amount += amount;
        user.rewardDebt = (user.amount * pool.accRewardPerShare) / 1e12;
        totalStaked += amount;
        lpToken.transferFrom(_msgSender(), address(this), amount);
        emit Deposit(_msgSender(), amount);
    }

    /**
     * @notice allow user to withdraw their lp and reward tokens,
     * can be called only after farming ends, tokens will be unlocked
     * gradually oven next 3 months, fire Withdraw event
     * @dev if user call withdraw first time, his UserInfo struct will be rewrited:
     * user.amount - his total lp amount,
     * user.rewardDebt - how many reward tokens already withdrawed,
     * user.accReward - his total reward amount,
     * lpWithdrawed[address] - how many lp tokens already withdrawed
     * and info about first call saved in isWithdraw[address]
     */
    function withdraw() external {
        require(
            farmingEnd < block.timestamp && farmingEnd != 0,
            "Farming is not over yet"
        );

        UserInfo storage user = userInfo[_msgSender()];
        require(user.amount != 0, "Zero LP staked");
        updatePool();
        if (!isWithdraw[_msgSender()]) {
            isWithdraw[_msgSender()] = true;
            user.accReward = pendingReward(_msgSender());
            user.rewardDebt = 0;
        }
        uint256 lpWithdraw;
        uint256 rewardWithdraw;
        if (block.timestamp > farmingEnd + UNLOCK_TIME) {
            lpWithdraw = user.amount - lpWithdrawed[_msgSender()];
            rewardWithdraw = user.accReward - user.rewardDebt;
        } else {
            uint256 multiplier = block.timestamp - farmingEnd;
            lpWithdraw =
                (user.amount * multiplier) /
                UNLOCK_TIME -
                lpWithdrawed[_msgSender()];
            rewardWithdraw =
                (user.accReward * multiplier) /
                UNLOCK_TIME -
                user.rewardDebt;
        }
        if (lpWithdraw > 0) {
            lpWithdrawed[_msgSender()] += lpWithdraw;
            lpToken.transfer(_msgSender(), lpWithdraw);
        }
        if (rewardWithdraw > 0) {
            user.rewardDebt += rewardWithdraw;
            rewardToken.transfer(_msgSender(), rewardWithdraw);
        }
        emit Withdraw(_msgSender(), lpWithdraw, rewardWithdraw);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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