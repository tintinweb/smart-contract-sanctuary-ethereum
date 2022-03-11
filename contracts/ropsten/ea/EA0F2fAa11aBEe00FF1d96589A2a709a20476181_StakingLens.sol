//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "./StakingLockable.sol";

/// @author  umb.network
/// @notice Math is based on synthetix staking contract
///         Contract allows to stake and lock tokens. For rUMB tokens only locking option is available.
///         When locking user choose period and based on period multiplier is apply to the amount (boost).
///         If pool is set for rUMB1->rUMB2, (rUmbPool) then rUMB2 can be locked as well
contract StakingLens {
    struct LockData {
        uint256 period;
        uint256 multiplier;
    }

    /// @dev returns amount of all staked and locked tokens including bonuses
    function balanceOf(StakingLockable _pool, address _account) external view returns (uint256) {
        (uint96 umbBalance, uint96 lockedWithBonus,,,) = _pool.balances(_account);
        return umbBalance + lockedWithBonus;
    }

    function getRewardForDuration(StakingLockable _pool) external view returns (uint256) {
        (, uint32 rewardsDuration,,) = _pool.timeData();
        return _pool.rewardRate() * rewardsDuration;
    }

    function rewards(StakingLockable _pool, address _user) external view returns (uint256) {
        (,,,,uint96 userRewards) = _pool.balances(_user);
        return userRewards;
    }

    /// @notice returns array of max 100 booleans, where index corresponds to lock id. `true` means lock can be withdraw
    function getVestedLockIds(StakingLockable _pool, address _account, uint256 _offset)
        external
        view
        returns (bool[] memory results)
    {
        (,,uint256 nextLockIndex,,) = _pool.balances(_account);
        uint256 batch = 100;

        if (nextLockIndex == 0) return results;
        if (nextLockIndex <= _offset) return results;

        uint256 end = _offset + batch > nextLockIndex ? nextLockIndex : _offset + batch;

        results = new bool[](end);

        for (uint256 i = _offset; i < end; i++) {
            (,,, uint32 unlockDate,, uint32 withdrawnAt) = _pool.locks(_account, i);
            results[i] = withdrawnAt == 0 && unlockDate <= block.timestamp;
        }
    }

    /// @notice returns array of max 100 booleans, where index corresponds to lock id.
    ///         `true` means lock was not withdrawn yet
    function getActiveLockIds(StakingLockable _pool, address _account, uint256 _offset)
        external
        view
        returns (bool[] memory results)
    {
        (,,uint256 nextLockIndex,,) = _pool.balances(_account);
        uint256 batch = 100;

        if (nextLockIndex == 0) return results;
        if (nextLockIndex <= _offset) return results;

        uint256 end = _offset + batch > nextLockIndex ? nextLockIndex : _offset + batch;

        results = new bool[](end);

        for (uint256 i = _offset; i < end; i++) {
            (,,,,, uint32 withdrawnAt) = _pool.locks(_account, i);
            results[i] = withdrawnAt == 0;
        }
    }

    function getPeriods(StakingLockable _pool, address _token) external view returns (uint256[] memory periods) {
        return _pool.getPeriods(_token);
    }

    function getPeriodsAndMultipliers(StakingLockable _pool, address _token)
        external
        view
        returns (LockData[] memory lockData)
    {
        uint256[] memory periods = _pool.getPeriods(_token);
        uint256 n = periods.length;
        lockData = new LockData[](n);

        for (uint256 i; i < n; i++) {
            lockData[i] = LockData(periods[i], _pool.multipliers(_token, periods[i]));
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Inheritance
import "../interfaces/IStakingRewards.sol";
import "../interfaces/Pausable.sol";
import "../interfaces/IBurnableToken.sol";
import "../interfaces/RewardsDistributionRecipient.sol";
import "../interfaces/OnDemandToken.sol";
import "../interfaces/LockSettings.sol";
import "../interfaces/SwappableTokenV2.sol";

/// @author  umb.network
/// @notice Math is based on synthetix staking contract
///         Contract allows to stake and lock tokens. For rUMB tokens only locking option is available.
///         When locking user choose period and based on period multiplier is apply to the amount (boost).
///         If pool is set for rUMB1->rUMB2, (rUmbPool) then rUMB2 can be locked as well
contract StakingLockable is LockSettings, RewardsDistributionRecipient, ReentrancyGuard, Pausable {
    struct Times {
        uint32 periodFinish;
        uint32 rewardsDuration;
        uint32 lastUpdateTime;
        uint96 totalRewardsSupply;
    }

    struct Balance {
        // total supply of UMB = 500_000_000e18, it can be saved using 89bits, so we good with 96 and above
        // user UMB balance
        uint96 umbBalance;
        // amount locked + virtual balance generated using multiplier when locking
        uint96 lockedWithBonus;
        uint32 nextLockIndex;
        uint160 userRewardPerTokenPaid;
        uint96 rewards;
    }

    struct Supply {
        // staked + raw locked
        uint128 totalBalance;
        // virtual balance
        uint128 totalBonus;
    }

    struct Lock {
        uint8 tokenId;
        // total supply of UMB can be saved using 89bits, so we good with 96 and above
        uint120 amount;
        uint32 lockDate;
        uint32 unlockDate;
        uint32 multiplier;
        uint32 withdrawnAt;
    }

    uint8 public constant UMB_ID = 2 ** 0;
    uint8 public constant RUMB1_ID = 2 ** 1;
    uint8 public constant RUMB2_ID = 2 ** 2;

    uint256 public immutable maxEverTotalRewards;

    address public immutable umb;
    address public immutable rUmb1;
    /// @dev this is reward token but we also allow to lock it
    address public immutable rUmb2;

    uint256 public rewardRate = 0;
    uint256 public rewardPerTokenStored;

    Supply public totalSupply;

    Times public timeData;

    /// @dev user => Balance
    mapping(address => Balance) public balances;

    /// @dev user => lock ID => Lock
    mapping(address => mapping(uint256 => Lock)) public locks;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount, uint256 bonus);

    event LockedTokens(
        address indexed user,
        address indexed token,
        uint256 lockId,
        uint256 amount,
        uint256 period,
        uint256 multiplier
    );

    event UnlockedTokens(address indexed user, address indexed token, uint256 lockId, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event FarmingFinished();
    event Swap1to2(uint256 swapped);

    modifier updateReward(address _account) virtual {
        uint256 newRewardPerTokenStored = rewardPerToken();
        rewardPerTokenStored = newRewardPerTokenStored;
        timeData.lastUpdateTime = uint32(lastTimeRewardApplicable());

        if (_account != address(0)) {
            balances[_account].rewards = uint96(earned(_account));
            balances[_account].userRewardPerTokenPaid = uint160(newRewardPerTokenStored);
        }

        _;
    }

    constructor(
        address _owner,
        address _rewardsDistribution,
        address _umb,
        address _rUmb1,
        address _rUmb2
    ) Owned(_owner) {
        require(
            (
                MintableToken(_umb).maxAllowedTotalSupply() +
                MintableToken(_rUmb1).maxAllowedTotalSupply() +
                MintableToken(_rUmb2).maxAllowedTotalSupply()
            ) * MAX_MULTIPLIER / RATE_DECIMALS <= type(uint96).max,
            "staking overflow"
        );

        require(
            MintableToken(_rUmb2).maxAllowedTotalSupply() * MAX_MULTIPLIER / RATE_DECIMALS <= type(uint96).max,
            "rewards overflow"
        );

        require(OnDemandToken(_rUmb2).ON_DEMAND_TOKEN(), "rewardsToken must be OnDemandToken");

        umb = _umb;
        rUmb1 = _rUmb1;
        rUmb2 = _rUmb2;

        rewardsDistribution = _rewardsDistribution;
        timeData.rewardsDuration = 2592000; // 30 days
        maxEverTotalRewards = MintableToken(_rUmb2).maxAllowedTotalSupply();
    }

    function lockTokens(address _token, uint256 _amount, uint256 _period) external {
        if (_token == rUmb2 && !SwappableTokenV2(rUmb2).isSwapStarted()) {
            revert("locking rUMB2 not available yet");
        }

        _lockTokens(msg.sender, _token, _amount, _period);
    }

    function unlockTokens(uint256[] calldata _ids) external {
        _unlockTokensFor(msg.sender, _ids, msg.sender);
    }

    function restart(uint256 _rewardsDuration, uint256 _reward) external {
        setRewardsDuration(_rewardsDuration);
        notifyRewardAmount(_reward);
    }

    // when farming was started with 1y and 12tokens
    // and we want to finish after 4 months, we need to end up with situation
    // like we were starting with 4mo and 4 tokens.
    function finishFarming() external onlyOwner {
        Times memory t = timeData;
        require(block.timestamp < t.periodFinish, "can't stop if not started or already finished");

        if (totalSupply.totalBalance != 0) {
            uint32 remaining = uint32(t.periodFinish - block.timestamp);
            timeData.rewardsDuration = t.rewardsDuration - remaining;
        }

        timeData.periodFinish = uint32(block.timestamp);

        emit FarmingFinished();
    }

    /// @notice one of the reasons this method can throw is, when we swap for UMB and somebody stake rUMB1 after that.
    ///         In that case execution of `swapForUMB()` is required (anyone can execute this method) before proceeding.
    function exit() external {
        _withdraw(type(uint256).max, msg.sender, msg.sender);
        _getReward(msg.sender, msg.sender);
    }

    /// @notice one of the reasons this method can throw is, when we swap for UMB and somebody stake rUMB1 after that.
    ///         In that case execution of `swapForUMB()` is required (anyone can execute this method) before proceeding.
    function exitAndUnlock(uint256[] calldata _lockIds) external {
        _withdraw(type(uint256).max, msg.sender, msg.sender);
        _unlockTokensFor(msg.sender, _lockIds, msg.sender);
        _getReward(msg.sender, msg.sender);
    }

    function stake(uint256 _amount) external {
        _stake(umb, msg.sender, _amount, 0);
    }

    function getReward() external {
        _getReward(msg.sender, msg.sender);
    }

    function swap1to2() public {
        if (!SwappableTokenV2(rUmb2).isSwapStarted()) return;

        uint256 myBalance = IERC20(rUmb1).balanceOf(address(this));
        if (myBalance == 0) return;

        IBurnableToken(rUmb1).burn(myBalance);
        OnDemandToken(rUmb2).mint(address(this), myBalance);

        emit Swap1to2(myBalance);
    }

    /// @dev when notifying about amount, we don't have to mint or send any tokens, reward tokens will be mint on demand
    ///         this method is used to restart staking
    function notifyRewardAmount(
        uint256 _reward
    ) override public onlyRewardsDistribution updateReward(address(0)) {
        // this method can be executed on its own as well, I'm including here to not need to remember about it
        swap1to2();

        Times memory t = timeData;
        uint256 newRewardRate;

        if (block.timestamp >= t.periodFinish) {
            newRewardRate = _reward / t.rewardsDuration;
        } else {
            uint256 remaining = t.periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            newRewardRate = (_reward + leftover) / t.rewardsDuration;
        }

        require(newRewardRate != 0, "invalid rewardRate");

        rewardRate = newRewardRate;

        // always increasing by _reward even if notification is in a middle of period
        // because leftover is included
        uint256 totalRewardsSupply = timeData.totalRewardsSupply + _reward;
        require(totalRewardsSupply <= maxEverTotalRewards, "rewards overflow");

        timeData.totalRewardsSupply = uint96(totalRewardsSupply);
        timeData.lastUpdateTime = uint32(block.timestamp);
        timeData.periodFinish = uint32(block.timestamp + t.rewardsDuration);

        emit RewardAdded(_reward);
    }

    function setRewardsDuration(uint256 _rewardsDuration) public onlyRewardsDistribution {
        require(_rewardsDuration != 0, "empty _rewardsDuration");

        require(
            block.timestamp > timeData.periodFinish,
            "Previous period must be complete before changing the duration"
        );

        timeData.rewardsDuration = uint32(_rewardsDuration);
        emit RewardsDurationUpdated(_rewardsDuration);
    }

    /// @notice one of the reasons this method can throw is, when we swap for UMB and somebody stake rUMB1 after that.
    ///         In that case execution of `swapForUMB()` is required (anyone can execute this method) before proceeding.
    function withdraw(uint256 _amount) public {
        _withdraw(_amount, msg.sender, msg.sender);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        uint256 periodFinish = timeData.periodFinish;
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256 perToken) {
        Supply memory s = totalSupply;

        if (s.totalBalance == 0) {
            return rewardPerTokenStored;
        }

        perToken = rewardPerTokenStored + (
            (lastTimeRewardApplicable() - timeData.lastUpdateTime) * rewardRate * 1e18 / (s.totalBalance + s.totalBonus)
        );
    }

    function earned(address _account) virtual public view returns (uint256) {
        Balance memory b = balances[_account];
        uint256 totalBalance = b.umbBalance + b.lockedWithBonus;
        return (totalBalance * (rewardPerToken() - b.userRewardPerTokenPaid) / 1e18) + b.rewards;
    }

    function calculateBonus(uint256 _amount, uint256 _multiplier) public pure returns (uint256 bonus) {
        if (_multiplier <= RATE_DECIMALS) return 0;

        bonus = _amount * _multiplier / RATE_DECIMALS - _amount;
    }

    /// @param _token token that we allow to stake, validator check should be do outside
    /// @param _user token owner
    /// @param _amount amount
    /// @param _bonus if bonus is 0, means we are staking, bonus > 0 means this is locking
    function _stake(address _token, address _user, uint256 _amount, uint256 _bonus)
        internal
        nonReentrant
        notPaused
        updateReward(_user)
    {
        uint256 amountWithBonus = _amount + _bonus;

        require(timeData.periodFinish > block.timestamp, "Stake period not started yet");
        require(amountWithBonus != 0, "Cannot stake 0");

        // TODO check if we ever need to separate balance and bonuses
        totalSupply.totalBalance += uint96(_amount);
        totalSupply.totalBonus += uint128(_bonus);

        if (_bonus == 0) {
            balances[_user].umbBalance += uint96(_amount);
        } else {
            balances[_user].lockedWithBonus += uint96(amountWithBonus);
        }

        // not using safe transfer, because we working with trusted tokens
        require(IERC20(_token).transferFrom(_user, address(this), _amount), "token transfer failed");

        emit Staked(_user, _amount, _bonus);
    }

    function _lockTokens(address _user, address _token, uint256 _amount, uint256 _period) internal notPaused {
        uint256 multiplier = multipliers[_token][_period];
        require(multiplier != 0, "invalid period or not supported token");

        uint256 stakeBonus = calculateBonus(_amount, multiplier);

        _stake(_token, _user, _amount, stakeBonus);
        _addLock(_user, _token, _amount, _period, multiplier);
    }

    function _addLock(address _user, address _token, uint256 _amount, uint256 _period, uint256 _multiplier) internal {
        uint256 newIndex = balances[_user].nextLockIndex;
        if (newIndex == type(uint32).max) revert("nextLockIndex overflow");

        balances[_user].nextLockIndex = uint32(newIndex + 1);

        Lock storage lock = locks[_user][newIndex];

        lock.amount = uint120(_amount);
        lock.multiplier = uint32(_multiplier);
        lock.lockDate = uint32(block.timestamp);
        lock.unlockDate = uint32(block.timestamp + _period);

        if (_token == rUmb2) lock.tokenId = RUMB2_ID;
        else if (_token == rUmb1) lock.tokenId = RUMB1_ID;
        else lock.tokenId = UMB_ID;

        emit LockedTokens(_user, _token, newIndex, _amount, _period, _multiplier);
    }

    // solhint-disable-next-line code-complexity
    function _unlockTokensFor(address _user, uint256[] calldata _indexes, address _recipient)
        internal
        returns (address token, uint256 totalRawAmount)
    {
        uint256 totalBonus;
        uint256 acceptedTokenId;
        bool isSwapStarted = SwappableTokenV2(rUmb2).isSwapStarted();

        for (uint256 i; i < _indexes.length; i++) {
            (uint256 amount, uint256 bonus, uint256 tokenId) = _markAsUnlocked(_user, _indexes[i]);
            if (amount == 0) continue;

            if (acceptedTokenId == 0) {
                acceptedTokenId = tokenId;
                token = _idToToken(tokenId);

                // if token is already rUmb2 means swap started already

                if (token == rUmb1 && isSwapStarted) {
                    token = rUmb2;
                    acceptedTokenId = RUMB2_ID;
                }
            } else if (acceptedTokenId != tokenId) {
                if (acceptedTokenId == RUMB2_ID && tokenId == RUMB1_ID) {
                    // this lock is for rUMB1 but swap 1->2 is started so we unlock as rUMB2
                } else revert("batch unlock possible only for the same tokens");
            }

            emit UnlockedTokens(_user, token, _indexes[i], amount);

            totalRawAmount += amount;
            totalBonus += bonus;
        }

        if (totalRawAmount == 0) revert("nothing to unlock");
        _withdrawUnlockedTokens(_user, token, _recipient, totalRawAmount, totalBonus);
    }

    function _withdrawUnlockedTokens(
        address _user,
        address _token,
        address _recipient,
        uint256 _totalRawAmount,
        uint256 _totalBonus
    )
        internal
    {
        uint256 amountWithBonus = _totalRawAmount + _totalBonus;

        balances[_user].lockedWithBonus -= uint96(amountWithBonus);

        totalSupply.totalBalance -= uint96(_totalRawAmount);
        totalSupply.totalBonus -= uint128(_totalBonus);

        // note: there is one case when this transfer can fail:
        // when swap is started by we did not swap rUmb1 -> rUmb2,
        // in that case we have to execute `swap1to2`
        // to save gas I'm not including it here, because it is unlikely case
        require(IERC20(_token).transfer(_recipient, _totalRawAmount), "withdraw unlocking failed");
    }

    function _markAsUnlocked(address _user, uint256 _index)
        internal
        returns (uint256 amount, uint256 bonus, uint256 tokenId)
    {
        // TODO will storage save gas?
        Lock memory lock = locks[_user][_index];

        if (lock.withdrawnAt != 0) revert("DepositAlreadyWithdrawn");
        if (block.timestamp < lock.unlockDate) revert("DepositLocked");

        if (lock.amount == 0) return (0, 0, 0);

        locks[_user][_index].withdrawnAt = uint32(block.timestamp);

        return (lock.amount, calculateBonus(lock.amount, lock.multiplier), lock.tokenId);
    }

    /// @param _amount tokens to withdraw
    /// @param _user address
    /// @param _recipient address, where to send tokens, if we migrating token address can be zero
    function _withdraw(uint256 _amount, address _user, address _recipient) internal nonReentrant updateReward(_user) {
        Balance memory balance = balances[_user];

        if (_amount == type(uint256).max) _amount = balance.umbBalance;
        else require(balance.umbBalance >= _amount, "withdraw amount to high");

        if (_amount == 0) return;

        // not using safe math, because there is no way to overflow because of above check
        totalSupply.totalBalance -= uint120(_amount);
        balances[_user].umbBalance = uint96(balance.umbBalance - _amount);

        // not using safe transfer, because we working with trusted tokens
        require(IERC20(umb).transfer(_recipient, _amount), "token transfer failed");

        emit Withdrawn(_user, _amount);
    }

    /// @param _user address
    /// @param _recipient address, where to send reward
    function _getReward(address _user, address _recipient)
        internal
        nonReentrant
        updateReward(_user)
        returns (uint256 reward)
    {
        reward = balances[_user].rewards;

        if (reward != 0) {
            balances[_user].rewards = 0;
            OnDemandToken(address(rUmb2)).mint(_recipient, reward);
            emit RewardPaid(_user, reward);
        }
    }

    function _idToToken(uint256 _tokenId) internal view returns (address token) {
        if (_tokenId == RUMB2_ID) token = rUmb2;
        else if (_tokenId == RUMB1_ID) token = rUmb1;
        else if (_tokenId == UMB_ID) token = umb;
        else return address(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;


interface IStakingRewards {
    // Mutative
    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

// Inheritance
import "./Owned.sol";


abstract contract Pausable is Owned {
    bool public paused;

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }

    constructor() {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner() != address(0), "Owner must be set");
        // Paused will be false
    }

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IBurnableToken {
    function burn(uint256 _amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

// Inheritance
import "./Owned.sol";


// https://docs.synthetix.io/contracts/RewardsDistributionRecipient
abstract contract RewardsDistributionRecipient is Owned {
    address public rewardsDistribution;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistributor");
        _;
    }

    function notifyRewardAmount(uint256 reward) virtual external;

    function setRewardsDistribution(address _rewardsDistribution) external onlyOwner {
        rewardsDistribution = _rewardsDistribution;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./MintableToken.sol";

abstract contract OnDemandToken is MintableToken {
    bool constant public ON_DEMAND_TOKEN = true;

    mapping (address => bool) public minters;

    event SetupMinter(address minter, bool active);

    modifier onlyOwnerOrMinter() {
        address msgSender = _msgSender();
        require(owner() == msgSender || minters[msgSender], "access denied");

        _;
    }

    function setupMinter(address _minter, bool _active) external onlyOwner() {
        minters[_minter] = _active;
        emit SetupMinter(_minter, _active);
    }

    function setupMinters(address[] calldata _minters, bool[] calldata _actives) external onlyOwner() {
        for (uint256 i; i < _minters.length; i++) {
            minters[_minters[i]] = _actives[i];
            emit SetupMinter(_minters[i], _actives[i]);
        }
    }

    function mint(address _holder, uint256 _amount)
        external
        virtual
        override
        onlyOwnerOrMinter()
        assertMaxSupply(_amount)
    {
        require(_amount != 0, "zero amount");

        _mint(_holder, _amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract LockSettings is Ownable {
    /// @dev decimals for: baseRate, APY, multipliers
    ///         eg for baseRate: 1e6 is 1%, 50e6 is 50%
    ///         eg for multipliers: 1e6 is 1.0x, 3210000 is 3.21x
    uint256 public constant RATE_DECIMALS = 10 ** 6;
    uint256 public constant MAX_MULTIPLIER = 5 * RATE_DECIMALS;

    /// @notice token => period => multiplier
    mapping(address => mapping(uint256 => uint256)) public multipliers;

    /// @notice token => period => index in periods array
    mapping(address => mapping(uint256 => uint256)) public periodIndexes;

    /// @notice token => periods
    mapping(address => uint256[]) public periods;

    event TokenSettings(address indexed token, uint256 period, uint256 multiplier);

    function removePeriods(address _token, uint256[] calldata _periods) external onlyOwner {
        for (uint256 i; i < _periods.length; i++) {
            if (_periods[i] == 0) revert("InvalidSettings");

            multipliers[_token][_periods[i]] = 0;
            _removePeriod(_token, _periods[i]);

            emit TokenSettings(_token, _periods[i], 0);
        }
    }

    // solhint-disable-next-line code-complexity
    function setLockingTokenSettings(address _token, uint256[] calldata _periods, uint256[] calldata _multipliers)
        external
        onlyOwner
    {
        if (_periods.length == 0) revert("EmptyPeriods");
        if (_periods.length != _multipliers.length) revert("ArraysNotMatch");

        for (uint256 i; i < _periods.length; i++) {
            if (_periods[i] == 0) revert("InvalidSettings");
            if (_multipliers[i] < RATE_DECIMALS) revert("multiplier must be >= 1e6");
            if (_multipliers[i] > MAX_MULTIPLIER) revert("multiplier overflow");

            multipliers[_token][_periods[i]] = _multipliers[i];
            emit TokenSettings(_token, _periods[i], _multipliers[i]);

            if (_multipliers[i] == 0) _removePeriod(_token, _periods[i]);
            else _addPeriod(_token, _periods[i]);
        }
    }

    function periodsCount(address _token) external view returns (uint256) {
        return periods[_token].length;
    }

    function getPeriods(address _token) external view returns (uint256[] memory) {
        return periods[_token];
    }

    function _addPeriod(address _token, uint256 _period) internal {
        uint256 key = periodIndexes[_token][_period];
        if (key != 0) return;

        periods[_token].push(_period);
        // periodIndexes are starting from 1, not from 0
        periodIndexes[_token][_period] = periods[_token].length;
    }

    function _removePeriod(address _token, uint256 _period) internal {
        uint256 key = periodIndexes[_token][_period];
        if (key == 0) return;

        periods[_token][key - 1] = periods[_token][periods[_token].length - 1];
        periodIndexes[_token][_period] = 0;
        periods[_token].pop();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

// Inheritance
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/Owned.sol";
import "../interfaces/ISwapReceiver.sol";


/// @title   Umbrella Rewards contract V2
/// @author  umb.network
/// @notice  This contract serves Swap functionality for rewards tokens
/// @dev     It allows to swap itself for other token (main UMB token).
abstract contract SwappableTokenV2 is Owned, ERC20 {
    struct SwapData {
        // number of tokens swapped so far (no decimals)
        uint32 swappedSoFar;
        // used limit since last swap (no decimals)
        uint32 usedLimit;
        // daily cup (no decimals)
        uint32 dailyCup;
        uint32 dailyCupTimestamp;
        uint32 swapEnabledAt;
    }

    uint256 public constant ONE = 1e18;

    uint256 public immutable swapStartsOn;
    ISwapReceiver public immutable umb;

    SwapData public swapData;

    event LogStartEarlySwapNow(uint time);
    event LogSwap(address indexed swappedTo, uint amount);
    event LogDailyCup(uint newCup);

    constructor(address _umb, uint32 _swapStartsOn, uint32 _dailyCup) {
        require(_dailyCup != 0, "invalid dailyCup");
        require(_swapStartsOn > block.timestamp, "invalid swapStartsOn");
        require(ERC20(_umb).decimals() == 18, "invalid UMB token");

        swapStartsOn = _swapStartsOn;
        umb = ISwapReceiver(_umb);
        swapData.dailyCup = _dailyCup;
    }

    function swapForUMB() external {
        SwapData memory data = swapData;

        (uint256 limit, bool fullLimit) = _currentLimit(data);
        require(limit != 0, "swapping period not started OR limit");

        uint256 amountToSwap = balanceOf(msg.sender);
        require(amountToSwap != 0, "you dont have tokens to swap");

        uint32 amountWoDecimals = uint32(amountToSwap / ONE);
        require(amountWoDecimals <= limit, "daily CUP limit");

        swapData.usedLimit = uint32(fullLimit ? amountWoDecimals : data.usedLimit + amountWoDecimals);
        swapData.swappedSoFar += amountWoDecimals;
        if (fullLimit) swapData.dailyCupTimestamp = uint32(block.timestamp);

        _burn(msg.sender, amountToSwap);
        umb.swapMint(msg.sender, amountToSwap);

        emit LogSwap(msg.sender, amountToSwap);
    }

    function startEarlySwap() external onlyOwner {
        require(block.timestamp < swapStartsOn, "swap is already allowed");
        require(swapData.swapEnabledAt == 0, "swap was already enabled");

        swapData.swapEnabledAt = uint32(block.timestamp);
        emit LogStartEarlySwapNow(block.timestamp);
    }

    /// @param _cup daily cup limit (no decimals), eg. if cup=5 means it is 5 * 10^18 tokens
    function setDailyCup(uint32 _cup) external onlyOwner {
        swapData.dailyCup = _cup;
        emit LogDailyCup(_cup);
    }

    function isSwapStarted() external view returns (bool) {
        // will it save gas if I do 2x if??
        return block.timestamp >= swapStartsOn || swapData.swapEnabledAt != 0;
    }

    function canSwapTokens(address _address) external view returns (bool) {
        uint256 balance = balanceOf(_address);
        if (balance == 0) return false;

        (uint256 limit,) = _currentLimit(swapData);
        return balance / ONE <= limit;
    }

    function currentLimit() external view returns (uint256 limit) {
        (limit,) = _currentLimit(swapData);
        limit *= ONE;
    }

    function _currentLimit(SwapData memory data) internal view returns (uint256 limit, bool fullLimit) {
        if (block.timestamp < swapStartsOn && data.swapEnabledAt == 0) return (0, false);

        fullLimit = block.timestamp - data.dailyCupTimestamp >= 24 hours;
        limit = fullLimit ? data.dailyCup : data.dailyCup - data.usedLimit;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Owned is Ownable {
    constructor(address _owner) {
        transferOwnership(_owner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/Owned.sol";
import "../interfaces/IBurnableToken.sol";

/// @author  umb.network
abstract contract MintableToken is Owned, ERC20, IBurnableToken {
    uint256 public immutable maxAllowedTotalSupply;
    uint256 public everMinted;

    modifier assertMaxSupply(uint256 _amountToMint) {
        _assertMaxSupply(_amountToMint);
        _;
    }

    // ========== CONSTRUCTOR ========== //

    constructor (uint256 _maxAllowedTotalSupply) {
        require(_maxAllowedTotalSupply != 0, "_maxAllowedTotalSupply is empty");

        maxAllowedTotalSupply = _maxAllowedTotalSupply;
    }

    // ========== MUTATIVE FUNCTIONS ========== //

    function burn(uint256 _amount) override external {
        _burn(msg.sender, _amount);
    }

    // ========== RESTRICTED FUNCTIONS ========== //

    function mint(address _holder, uint256 _amount)
        virtual
        external
        onlyOwner()
        assertMaxSupply(_amount)
    {
        require(_amount != 0, "zero amount");

        _mint(_holder, _amount);
    }

    function _assertMaxSupply(uint256 _amountToMint) internal {
        uint256 everMintedTotal = everMinted + _amountToMint;
        everMinted = everMintedTotal;
        require(everMintedTotal <= maxAllowedTotalSupply, "total supply limit exceeded");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface ISwapReceiver {
    function swapMint(address _holder, uint256 _amount) external;
}