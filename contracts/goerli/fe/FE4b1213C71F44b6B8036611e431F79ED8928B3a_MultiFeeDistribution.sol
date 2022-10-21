// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IChefIncentivesController.sol";
import "./interfaces/IMultiFeeDistribution.sol";


interface IMintableToken is IERC20 {
    function mint(address _receiver, uint256 _amount) external returns (bool);
    function setMinter(address _minter) external returns (bool);
}

// Based on Ellipsis EPS Staker
// https://github.com/ellipsis-finance/ellipsis/blob/master/contracts/EpsStaker.sol
contract MultiFeeDistribution is IMultiFeeDistribution, Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IMintableToken;

    /* ========== STATE VARIABLES ========== */

    struct Reward {
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        // tracks already-added balances to handle accrued interest in aToken rewards
        // for the stakingToken this value is unused and will always be 0
        uint256 balance;
    }
    struct Balances {
        uint256 total;
        uint256 unlocked;
        uint256 locked;
        uint256 earned;
    }
    struct LockedBalance {
        uint256 amount;
        uint256 unlockTime;
    }
    struct RewardData {
        address token;
        uint256 totalReward;
        uint256 stakingReward;
        uint256 lockingReward;
    }
    struct IncentiveData {
        uint256 amount;
        uint startTime;
    }

    IChefIncentivesController public incentivesController;
    IMintableToken public immutable stakingToken;
    address[] public rewardTokens;
    mapping(address => Reward) public rewardData;
    mapping(address => Reward) public stakingRewardData;
    IncentiveData[] public incentiveData;

    // Duration that rewards are streamed over
    uint256 public constant rewardsDuration = 604800;

    // Duration of lock/earned penalty period
    uint256 public constant lockBlock = 3600;
    uint256 public constant lockDuration = lockBlock * 2;

    // Addresses approved to call mint
    mapping(address => bool) public minters;
    mapping(address => bool) public gauges;
    bool public mintersAreSet;

    // user -> reward token -> amount
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) public userStakingRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) public rewards;
    mapping(address => mapping(address => uint256)) public stakingRewards;

    // 0xUnique: Using weight to rewards penalty + incentive for both staking and locking
    uint256 public priorStakingRewardWeight;
    uint256 public stakingRewardWeight;
    uint256 public priorLockingRewardWeight;
    uint256 public lockingRewardWeight;

    uint256 public totalSupply;
    uint256 public stakedSupply;
    uint256 public lockedSupply;

    // Private mappings for balance data
    mapping(address => Balances) private balances;
    mapping(address => LockedBalance[]) private userLocks;
    mapping(address => LockedBalance[]) private userEarnings;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _stakingToken) Ownable() {
        stakingToken = IMintableToken(_stakingToken);
        // 0xUnique Remove setMinter()
        // IMintableToken(_stakingToken).setMinter(address(this));

        // First reward MUST be the staking token or things will break
        // related to the 50% penalty and distribution to locked balances
        rewardTokens.push(_stakingToken);
        rewardData[_stakingToken].lastUpdateTime = block.timestamp;
        stakingRewardData[_stakingToken].lastUpdateTime = block.timestamp;

        // Set default rewards weight for staking and locking
        priorStakingRewardWeight = 1;
        stakingRewardWeight = 1;
        priorLockingRewardWeight = 1;
        lockingRewardWeight = 1;
    }

    /* ========== ADMIN CONFIGURATION ========== */

    function setMinters(address[] memory _minters) external onlyOwner {
        require(!mintersAreSet);
        for (uint i; i < _minters.length; i++) {
            minters[_minters[i]] = true;
        }
        mintersAreSet = true;
    }

    function addGauge(address _gauge) external onlyOwner {
        gauges[_gauge] = true;
    }

    function removeGauge(address _gauge) external onlyOwner {
        require(gauges[_gauge]);
        gauges[_gauge] = false;
    }

    function setIncentivesController(IChefIncentivesController _controller) external onlyOwner {
        incentivesController = _controller;
    }

    // Add a new reward token to be distributed to stakers
    function addReward(address _rewardsToken) external override onlyOwner {
        require(rewardData[_rewardsToken].lastUpdateTime == 0, "Reward does exist");
        require(stakingRewardData[_rewardsToken].lastUpdateTime == 0, "Reward does exist");

        // Other reward except staking will be calculated based on rewardData
        rewardTokens.push(_rewardsToken);
        rewardData[_rewardsToken].lastUpdateTime = block.timestamp;
        rewardData[_rewardsToken].periodFinish = block.timestamp;
    }

    function setRewardWeight(uint256 _stakingRewardWeight, uint256 _lockingRewardWeight) external onlyOwner {
        require(_stakingRewardWeight > 0, "Weight must be greater than zero");
        require(_lockingRewardWeight > 0, "Weight must be greater than zero");

        // Setting reward weight
        priorStakingRewardWeight = stakingRewardWeight;
        stakingRewardWeight = _stakingRewardWeight;
        priorLockingRewardWeight = lockingRewardWeight;
        lockingRewardWeight = _lockingRewardWeight;

        // Calling function to update reward rate
        _notifyReward(address(stakingToken), 0, true);
    }

    /* ========== VIEWS ========== */

    function _rewardPerToken(address _rewardsToken, uint256 _supply) internal view returns (uint256) {
        if (_supply == 0) {
            return rewardData[_rewardsToken].rewardPerTokenStored;
        }
        return
            rewardData[_rewardsToken].rewardPerTokenStored.add(
                lastTimeRewardApplicable(_rewardsToken).sub(
                    rewardData[_rewardsToken].lastUpdateTime).mul(
                    rewardData[_rewardsToken].rewardRate).mul(1e18).div(_supply)
            );
    }

    // 0xUnique: Calculate reward per token for staking
    function _stakingRewardPerToken(address _rewardsToken, uint256 _supply) internal view returns (uint256) {
        if (_supply == 0) {
            return stakingRewardData[_rewardsToken].rewardPerTokenStored;
        }
        return
            stakingRewardData[_rewardsToken].rewardPerTokenStored.add(
                lastTimeRewardApplicable(_rewardsToken).sub(
                    stakingRewardData[_rewardsToken].lastUpdateTime).mul(
                    stakingRewardData[_rewardsToken].rewardRate).mul(1e18).div(_supply)
            );
    }

    function _earned(
        address _user,
        address _rewardsToken,
        uint256 _balance,
        uint256 _currentRewardPerToken
    ) internal view returns (uint256) {
        return _balance.mul(
            _currentRewardPerToken.sub(userRewardPerTokenPaid[_user][_rewardsToken])
        ).div(1e18).add(rewards[_user][_rewardsToken]);
    }

    function _stakingEarned(
        address _user,
        address _rewardsToken,
        uint256 _balance,
        uint256 _currentRewardPerToken
    ) internal view returns (uint256) {
        return _balance.mul(
            _currentRewardPerToken.sub(userStakingRewardPerTokenPaid[_user][_rewardsToken])
        ).div(1e18).add(stakingRewards[_user][_rewardsToken]);
    }

    function lastTimeRewardApplicable(address _rewardsToken) public view returns (uint256) {
        uint periodFinish = rewardData[_rewardsToken].periodFinish;
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function lastTimeStakingRewardApplicable(address _rewardsToken) public view returns (uint256) {
        uint periodFinish = stakingRewardData[_rewardsToken].periodFinish;
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken(address _rewardsToken) external view returns (uint256) {
        // 0xUnique: uint256 supply = _rewardsToken == address(stakingToken) ? lockedSupply : totalSupply;
        uint256 supply = stakedSupply.add(lockedSupply);
        return _rewardPerToken(_rewardsToken, supply);

    }

    function stakingRewardPerToken(address _rewardsToken) external view returns (uint256) {
        // 0xUnique: uint256 supply = _rewardsToken == address(stakingToken) ? lockedSupply : totalSupply;
        uint256 supply = stakedSupply.add(lockedSupply);
        return _stakingRewardPerToken(_rewardsToken, supply);
    }

    function getRewardForDuration(address _rewardsToken) external view returns (uint256) {
        return rewardData[_rewardsToken].rewardRate.mul(rewardsDuration).div(1e12);
    }

    function getStakingRewardForDuration(address _rewardsToken) external view returns (uint256) {
        require(_rewardsToken == address(stakingToken), "Token is not the staking token");
        return stakingRewardData[_rewardsToken].rewardRate.mul(rewardsDuration).div(1e12);
    }

    // Address and claimable amount of all reward tokens for the given account
    function claimableRewards(address account) external view returns (RewardData[] memory rewards) {
        rewards = new RewardData[](rewardTokens.length);
        for (uint256 i = 0; i < rewards.length; i++) {
            // If i == 0 this is the stakingReward, distribution is based on locked balances
            // 0xUnique: uint256 balance = i == 0 ? balances[account].locked : balances[account].total;
            uint256 lockedBalance = balances[account].locked;
            uint256 stakedBalance = balances[account].unlocked;
            // 0xUnique: Use totalSupply since both staking and locking earn same rewards with different ratio
            // uint256 supply = i == 0 ? lockedSupply : totalSupply;
            uint256 supply = stakedSupply.add(lockedSupply);
            rewards[i].token = rewardTokens[i];
            // 0xUnique:
            // rewards[i].amount = _earned(account, rewards[i].token, balance, _rewardPerToken(rewardTokens[i], supply)).div(1e12);
            uint256 lockingEarn = _earned(
                account, rewards[i].token, lockedBalance, _rewardPerToken(rewardTokens[i], supply)).div(1e12);
            // Calculate earning from stakingRewardData for only reward token is staking token
            uint256 stakingEarn;
            if (rewardTokens[i] == address(stakingToken)) {
                stakingEarn = _stakingEarned(
                    account, rewards[i].token, stakedBalance, _stakingRewardPerToken(rewardTokens[i], supply)).div(1e12);
            }
            rewards[i].totalReward = lockingEarn.add(stakingEarn);
            rewards[i].stakingReward = stakingEarn;
            rewards[i].lockingReward = lockingEarn;
        }
        return rewards;
    }

    // Total balance of an account, including unlocked, locked and earned tokens
    function totalBalance(address user) view external returns (uint256 amount) {
        return balances[user].total;
    }

    function lockedBalance(address user) view external returns (uint256 amount) {
        return balances[user].locked;
    }

    function stakedBalance(address user) view external returns (uint256 amount) {
        return balances[user].unlocked;
    }

    // Total withdrawable balance for an account to which no penalty is applied
    function unlockedBalance(address user) view external returns (uint256 amount) {
        amount = balances[user].unlocked;
        LockedBalance[] storage earnings = userEarnings[msg.sender];
        for (uint i = 0; i < earnings.length; i++) {
            if (earnings[i].unlockTime > block.timestamp) {
                break;
            }
            amount = amount.add(earnings[i].amount);
        }
        return amount;
    }

    // Information on the "earned" balances of a user
    // Earned balances may be withdrawn immediately for a 50% penalty
    function earnedBalances(
        address user
    ) view external returns (
        uint256 total,
        LockedBalance[] memory earningsData
    ) {
        LockedBalance[] storage earnings = userEarnings[user];
        uint256 idx;
        for (uint i = 0; i < earnings.length; i++) {
            if (earnings[i].unlockTime > block.timestamp) {
                if (idx == 0) {
                    earningsData = new LockedBalance[](earnings.length - i);
                }
                earningsData[idx] = earnings[i];
                idx++;
                total = total.add(earnings[i].amount);
            }
        }
        return (total, earningsData);
    }

    // Information on a user's locked balances
    function lockedBalances(
        address user
    ) view external returns (
        uint256 total,
        uint256 unlockable,
        uint256 locked,
        LockedBalance[] memory lockData
    ) {
        LockedBalance[] storage locks = userLocks[user];
        uint256 idx;
        for (uint i = 0; i < locks.length; i++) {
            if (locks[i].unlockTime > block.timestamp) {
                if (idx == 0) {
                    lockData = new LockedBalance[](locks.length - i);
                }
                lockData[idx] = locks[i];
                idx++;
                locked = locked.add(locks[i].amount);
            } else {
                unlockable = unlockable.add(locks[i].amount);
            }
        }
        return (balances[user].locked, unlockable, locked, lockData);
    }

    // Information on a user's locked balances
    function lockedExpireBalances(
        address user
    ) view external returns (
        LockedBalance[] memory lockData
    ) {
        LockedBalance[] storage locks = userLocks[user];
        uint256 size;
        for (uint i = 0; i < locks.length; i++) {
            if (locks[i].unlockTime <= block.timestamp) {
                size++;
            }
        }
        if (size > 0) {
            uint256 idx;
            for (uint i = 0; i < locks.length; i++) {
                if (locks[i].unlockTime <= block.timestamp) {
                    if (idx == 0) {
                        lockData = new LockedBalance[](size);
                    }
                    lockData[idx] = locks[i];
                    idx++;
                }
            }
        }
        return lockData;
    }

    // Final balance received and penalty balance paid by user upon calling exit
    function withdrawableBalance(
        address user
    ) view public returns (
        uint256 amount,
        uint256 penaltyAmount
    ) {
        Balances storage bal = balances[user];
        uint256 earned = bal.earned;
        if (earned > 0) {
            uint256 amountWithoutPenalty;
            uint256 length = userEarnings[user].length;
            for (uint i = 0; i < length; i++) {
                uint256 earnedAmount = userEarnings[user][i].amount;
                if (earnedAmount == 0) continue;
                if (userEarnings[user][i].unlockTime > block.timestamp) {
                    break;
                }
                amountWithoutPenalty = amountWithoutPenalty.add(earnedAmount);
            }

            penaltyAmount = earned.sub(amountWithoutPenalty).div(2);
        }
        amount = bal.unlocked.add(earned).sub(penaltyAmount);
        return (amount, penaltyAmount);
    }

    // @author 0xUnique
    function withdrawableBalanceWithoutStaked(
        address user
    ) view public returns (
        uint256 amount,
        uint256 penaltyAmount
    ) {
        Balances storage bal = balances[user];
        uint256 earned = bal.earned;
        if (earned > 0) {
            uint256 amountWithoutPenalty;
            uint256 length = userEarnings[user].length;
            for (uint i = 0; i < length; i++) {
                uint256 earnedAmount = userEarnings[user][i].amount;
                if (earnedAmount == 0) continue;
                if (userEarnings[user][i].unlockTime > block.timestamp) {
                    break;
                }
                amountWithoutPenalty = amountWithoutPenalty.add(earnedAmount);
            }

            penaltyAmount = earned.sub(amountWithoutPenalty).div(2);
        }
        amount = earned.sub(penaltyAmount);
        return (amount, penaltyAmount);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // Stake tokens to receive rewards
    // Locked tokens cannot be withdrawn for lockDuration and are eligible to receive stakingReward rewards
    function stake(uint256 amount, bool lock) external {
        require(amount > 0, "Cannot stake 0");
        _updateReward(msg.sender);
        totalSupply = totalSupply.add(amount);
        Balances storage bal = balances[msg.sender];
        bal.total = bal.total.add(amount);
        if (lock) {
            lockedSupply = lockedSupply.add(amount);
            bal.locked = bal.locked.add(amount);
            uint256 unlockTime = block.timestamp.div(lockBlock).mul(lockBlock).add(lockDuration);
            uint256 idx = userLocks[msg.sender].length;
            if (idx == 0 || userLocks[msg.sender][idx-1].unlockTime < unlockTime) {
                userLocks[msg.sender].push(LockedBalance({amount: amount, unlockTime: unlockTime}));
            } else {
                userLocks[msg.sender][idx-1].amount = userLocks[msg.sender][idx-1].amount.add(amount);
            }
        } else {
            bal.unlocked = bal.unlocked.add(amount);
            stakedSupply = stakedSupply.add(amount);
        }
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount, lock);
    }

    // Mint new tokens
    // Minted tokens receive rewards normally but incur a 50% penalty when
    // withdrawn before lockDuration has passed.
    // Called by TokenVesting contract
    function mint(address user, uint256 amount, bool withPenalty) external override {
        require(minters[msg.sender]);
        if (amount == 0) return;
        _updateReward(user);
        // 0xUnique - Not require to mint new tokens since it was transferred to this contract before
        // stakingToken.mint(address(this), amount);
        if (user == address(this)) {
            // minting to this contract adds the new tokens as incentives for lockers
            _notifyReward(address(stakingToken), amount, false);
            return;
        }
        totalSupply = totalSupply.add(amount);
        Balances storage bal = balances[user];
        bal.total = bal.total.add(amount);
        if (withPenalty) {
            bal.earned = bal.earned.add(amount);
            uint256 unlockTime = block.timestamp.div(lockBlock).mul(lockBlock).add(lockDuration);
            LockedBalance[] storage earnings = userEarnings[user];
            uint256 idx = earnings.length;
            if (idx == 0 || earnings[idx-1].unlockTime < unlockTime) {
                earnings.push(LockedBalance({amount: amount, unlockTime: unlockTime}));
            } else {
                earnings[idx-1].amount = earnings[idx-1].amount.add(amount);
            }
        } else {
            bal.unlocked = bal.unlocked.add(amount);
            stakedSupply = stakedSupply.add(amount);
        }
        emit Staked(user, amount, false);
    }

    // @notice This function will be called from Gauge contract to transfer rewarded tokens
    //         to this contract for locking in certain period
    // @user   Owner of the rewards
    // @amount Rewards amount to be claimed
    // @withPenalty Flag to lock reward tokens. If withdraw before the time, user would be
    //              penalized for 50% of the amount
    // @author 0xUnique
    function vests(address user, uint256 amount, bool withPenalty) external {
        require(gauges[msg.sender]);
        require(msg.sender != address(this));
        if (amount == 0) return;
        _updateReward(user);

        // Transfer from rewards from Gauge to this contract
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        // Update numbers
        totalSupply = totalSupply.add(amount);
        Balances storage bal = balances[user];
        bal.total = bal.total.add(amount);
        if (withPenalty) {
            bal.earned = bal.earned.add(amount);
            uint256 unlockTime = block.timestamp.div(lockBlock).mul(lockBlock).add(lockDuration);
            LockedBalance[] storage earnings = userEarnings[user];
            uint256 idx = earnings.length;
            if (idx == 0) {
                // Found nothing, push new record
                earnings.push(LockedBalance({amount: amount, unlockTime: unlockTime}));
            }
            else {
                if (earnings[idx-1].unlockTime <= unlockTime) {
                    // Found vesting amount, then extend vesting amount and also unlock time
                    earnings[idx-1].amount = earnings[idx-1].amount.add(amount);
                    earnings[idx-1].unlockTime = unlockTime;
                }
                else {
                    // Found expired vesting amount then push new record
                    earnings.push(LockedBalance({amount: amount, unlockTime: unlockTime}));
                }
            }
        } else {
            bal.unlocked = bal.unlocked.add(amount);
            stakedSupply = stakedSupply.add(amount);
        }
        emit Staked(user, amount, true);
    }

    // @notice Claim all vested rewards including with and without penalty. Withdrawing
    //         earned tokens incurs a 50% penalty which is distributed based on locked balances.
    // @claimRewards Optionally claim pending rewards
    // @author 0xUnique
    function withdrawEarningWithPenalty(bool claimRewards) public {
        _updateReward(msg.sender);
        (uint256 amount, uint256 penaltyAmount) = withdrawableBalanceWithoutStaked(msg.sender);
        delete userEarnings[msg.sender];
        Balances storage bal = balances[msg.sender];
        bal.total = bal.total.sub(bal.earned);
        bal.earned = 0;

        totalSupply = totalSupply.sub(amount.add(penaltyAmount));
        stakingToken.safeTransfer(msg.sender, amount);
        if (penaltyAmount > 0) {
            incentivesController.claim(address(this), new address[](0));
            _notifyReward(address(stakingToken), penaltyAmount, false);
        }
        if (claimRewards) {
            _getReward(rewardTokens);
        }
        emit Withdrawn(msg.sender, amount, penaltyAmount);
    }

    // @notice Claim all vested rewards without penalty.
    // @claimRewards Optionally claim pending rewards
    // @author 0xUnique
    function withdrawEarningWithoutPenalty(bool claimRewards) public {
        _updateReward(msg.sender);
        (uint256 amount, uint256 calPenalty) = withdrawableBalanceWithoutStaked(msg.sender);
        amount = amount.sub(calPenalty);

        Balances storage bal = balances[msg.sender];
        uint256 penaltyAmount;
        uint256 remaining = amount;
        require(bal.earned >= remaining, "Insufficient unlocked balance");
        bal.earned = bal.earned.sub(remaining);
        for (uint i = 0; ; i++) {
            uint256 earnedAmount = userEarnings[msg.sender][i].amount;
            if (earnedAmount == 0) continue;
            if (penaltyAmount == 0 && userEarnings[msg.sender][i].unlockTime > block.timestamp) {
                penaltyAmount = remaining;
                require(bal.earned >= remaining, "Insufficient balance after penalty");
                bal.earned = bal.earned.sub(remaining);
                if (bal.earned == 0) {
                    delete userEarnings[msg.sender];
                    break;
                }
                remaining = remaining.mul(2);
            }
            if (remaining <= earnedAmount) {
                userEarnings[msg.sender][i].amount = earnedAmount.sub(remaining);
                break;
            } else {
                delete userEarnings[msg.sender][i];
                remaining = remaining.sub(earnedAmount);
            }
        }

        uint256 adjustedAmount = amount.add(penaltyAmount);
        bal.total = bal.total.sub(adjustedAmount);
        totalSupply = totalSupply.sub(adjustedAmount);
        stakingToken.safeTransfer(msg.sender, amount);
        if (penaltyAmount > 0) {
            incentivesController.claim(address(this), new address[](0));
            _notifyReward(address(stakingToken), penaltyAmount, false);
        }
        if (claimRewards) {
            _getReward(rewardTokens);
        }
        emit Withdrawn(msg.sender, amount, penaltyAmount);
    }

    // Withdraw amount which less than or equal staked tokens
    function unStake(uint256 amount) public {
        require(amount > 0, "Cannot withdraw 0");
        Balances storage bal = balances[msg.sender];
        require(amount <= bal.unlocked, "Insufficient balance");
        _updateReward(msg.sender);
        // Update remaining unlocked value
        bal.unlocked = bal.unlocked.sub(amount);
        stakedSupply = stakedSupply.sub(amount);
        // Update total value
        bal.total = bal.total.sub(amount);
        totalSupply = totalSupply.sub(amount);
        // Transfer tokens
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, 0);
    }

    // Withdraw staked tokens
    // First withdraws unlocked tokens, then earned tokens. Withdrawing earned tokens
    // incurs a 50% penalty which is distributed based on locked balances.
    function withdraw(uint256 amount) public {
        require(amount > 0, "Cannot withdraw 0");
        _updateReward(msg.sender);
        Balances storage bal = balances[msg.sender];
        uint256 penaltyAmount;

        if (amount <= bal.unlocked) {
            bal.unlocked = bal.unlocked.sub(amount);
            stakedSupply = stakedSupply.sub(amount);
        } else {
            uint256 remaining = amount.sub(bal.unlocked);
            require(bal.earned >= remaining, "Insufficient unlocked balance");
            bal.unlocked = 0;
            stakedSupply = stakedSupply.sub(bal.unlocked);
            bal.earned = bal.earned.sub(remaining);
            for (uint i = 0; ; i++) {
                uint256 earnedAmount = userEarnings[msg.sender][i].amount;
                if (earnedAmount == 0) continue;
                if (penaltyAmount == 0 && userEarnings[msg.sender][i].unlockTime > block.timestamp) {
                    penaltyAmount = remaining;
                    require(bal.earned >= remaining, "Insufficient balance after penalty");
                    bal.earned = bal.earned.sub(remaining);
                    if (bal.earned == 0) {
                        delete userEarnings[msg.sender];
                        break;
                    }
                    remaining = remaining.mul(2);
                }
                if (remaining <= earnedAmount) {
                    userEarnings[msg.sender][i].amount = earnedAmount.sub(remaining);
                    break;
                } else {
                    delete userEarnings[msg.sender][i];
                    remaining = remaining.sub(earnedAmount);
                }
            }
        }

        uint256 adjustedAmount = amount.add(penaltyAmount);
        bal.total = bal.total.sub(adjustedAmount);
        totalSupply = totalSupply.sub(adjustedAmount);
        stakingToken.safeTransfer(msg.sender, amount);
        if (penaltyAmount > 0) {
            incentivesController.claim(address(this), new address[](0));
            _notifyReward(address(stakingToken), penaltyAmount, false);
        }
        emit Withdrawn(msg.sender, amount, penaltyAmount);
    }

    function _getReward(address[] memory _rewardTokens) internal {
        uint256 length = _rewardTokens.length;
        for (uint i; i < length; i++) {
            address token = _rewardTokens[i];
            // Locked reward amount
            uint256 reward = rewards[msg.sender][token].div(1e12);
            if (token == address(stakingToken)) {
                // Added staking reward amount
                uint256 stakingReward = stakingRewards[msg.sender][token].div(1e12);
                reward = reward.add(stakingReward);
            }
            else {
                // for rewards other than stakingToken, every 24 hours we check if new
                // rewards were sent to the contract or accrued via aToken interest
                Reward storage r = rewardData[token];
                uint256 periodFinish = r.periodFinish;
                require(periodFinish > 0, "Unknown reward token");
                uint256 balance = r.balance;
                if (periodFinish < block.timestamp.add(rewardsDuration - 86400)) {
                    uint256 unseen = IERC20(token).balanceOf(address(this)).sub(balance);
                    if (unseen > 0) {
                        _notifyReward(token, unseen, false);
                        balance = balance.add(unseen);
                    }
                }
                r.balance = balance.sub(reward);
            }
            // Skip transfer if there is nothing to claim
            if (reward == 0) continue;

            // Reset reward to zero once able to claim
            rewards[msg.sender][token] = 0;
            if (token == address(stakingToken)) {
                stakingRewards[msg.sender][token] = 0;
            }
            // Claim the reward
            IERC20(token).safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, token, reward);
        }
    }

    // Claim all pending staking rewards
    function getReward(address[] memory _rewardTokens) public {
        _updateReward(msg.sender);
        _getReward(_rewardTokens);
    }

    // Withdraw full unlocked balance and optionally claim pending rewards
    function exit(bool claimRewards) external {
        _updateReward(msg.sender);
        (uint256 amount, uint256 penaltyAmount) = withdrawableBalance(msg.sender);
        delete userEarnings[msg.sender];
        Balances storage bal = balances[msg.sender];
        bal.total = bal.total.sub(bal.unlocked).sub(bal.earned);
        bal.unlocked = 0;
        stakedSupply = stakedSupply.sub(bal.unlocked);
        bal.earned = 0;

        totalSupply = totalSupply.sub(amount.add(penaltyAmount));
        stakingToken.safeTransfer(msg.sender, amount);
        if (penaltyAmount > 0) {
            incentivesController.claim(address(this), new address[](0));
            _notifyReward(address(stakingToken), penaltyAmount, false);
        }
        if (claimRewards) {
            _getReward(rewardTokens);
        }
        emit Withdrawn(msg.sender, amount, penaltyAmount);
    }

    // Withdraw all currently locked tokens where the unlock time has passed
    function withdrawExpiredLocks() external {
        _updateReward(msg.sender);
        LockedBalance[] storage locks = userLocks[msg.sender];
        Balances storage bal = balances[msg.sender];
        uint256 amount;
        uint256 length = locks.length;
        if (locks[length-1].unlockTime <= block.timestamp) {
            amount = bal.locked;
            delete userLocks[msg.sender];
        } else {
            for (uint i = 0; i < length; i++) {
                if (locks[i].unlockTime > block.timestamp) break;
                amount = amount.add(locks[i].amount);
                delete locks[i];
            }
        }
        bal.locked = bal.locked.sub(amount);
        bal.total = bal.total.sub(amount);
        totalSupply = totalSupply.sub(amount);
        lockedSupply = lockedSupply.sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, 0);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    // @notice Trigger calculation to change rewardRate
    function _notifyReward(address _rewardsToken, uint256 reward, bool isWeightChanged) internal {
        // 0xUnique: Add incentive into rewards distribution mechanic
        uint256 incentiveAmount;
        for (uint256 i = 0; i < incentiveData.length; i++) {
            IncentiveData memory incentive = incentiveData[i];
            if (incentive.startTime == 0) continue;
            if (block.timestamp > incentive.startTime) {
                incentiveAmount = incentiveAmount + incentive.amount;
                delete incentiveData[i];
            }
        }

        uint256 _priorLockingRewardWeight = isWeightChanged ? priorLockingRewardWeight : lockingRewardWeight;
        uint256 _priorStakingRewardWeight = isWeightChanged ? priorStakingRewardWeight : stakingRewardWeight;
        // Update locking reward data
        Reward storage r = rewardData[_rewardsToken];
        if (block.timestamp >= r.periodFinish) {
            // Reward has distributed, reset calculation based on input reward
            r.rewardRate = reward.add(incentiveAmount).mul(1e12).div(rewardsDuration).mul(
                lockingRewardWeight).div(lockingRewardWeight.add(stakingRewardWeight));
        } else {
            // New reward coming within distribution period, then adjust amount and rate
            uint256 remaining = r.periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(r.rewardRate).div(1e12);
            uint256 newReward;
            if (reward == 0) {
                // Recalculate rate based on reward weight changed
                uint256 fullRewardLeft = leftover.div(_priorLockingRewardWeight).mul(
                    _priorLockingRewardWeight.add(_priorStakingRewardWeight));
                newReward = fullRewardLeft.add(incentiveAmount);
            }
            else {
                // Recalculate rate based on reward amount changed
                uint256 fullRewardLeft = leftover.div(lockingRewardWeight).mul(
                    lockingRewardWeight.add(stakingRewardWeight));
                newReward = fullRewardLeft.add(reward).add(incentiveAmount);
            }
            r.rewardRate = newReward.mul(1e12).div(rewardsDuration).mul(
                lockingRewardWeight).div(lockingRewardWeight.add(stakingRewardWeight));
        }
        r.lastUpdateTime = block.timestamp;
        r.periodFinish = block.timestamp.add(rewardsDuration);

        if (_rewardsToken == address(stakingToken)) {
            // Update staking reward data
            r = stakingRewardData[_rewardsToken];
            if (block.timestamp >= r.periodFinish) {
                r.rewardRate = reward.add(incentiveAmount).mul(1e12).div(rewardsDuration).mul(
                    stakingRewardWeight).div(stakingRewardWeight.add(lockingRewardWeight));
            } else {
                uint256 sRemaining = r.periodFinish.sub(block.timestamp);
                uint256 sLeftover = sRemaining.mul(r.rewardRate).div(1e12);
                uint256 sNewReward;
                if (reward == 0) {
                    // Recalculate rate based on reward weight changed
                    uint256 sFullRewardLeft = sLeftover.div(_priorStakingRewardWeight).mul(
                        _priorStakingRewardWeight.add(_priorLockingRewardWeight));
                    sNewReward = sFullRewardLeft.add(incentiveAmount);
                }
                else {
                    // Recalculate rate based on reward amount changed
                    uint256 sFullRewardLeft = sLeftover.div(stakingRewardWeight).mul(
                        stakingRewardWeight.add(lockingRewardWeight));
                    sNewReward = sFullRewardLeft.add(reward).add(incentiveAmount);
                }
                r.rewardRate = sNewReward.mul(1e12).div(rewardsDuration).mul(
                    stakingRewardWeight).div(stakingRewardWeight.add(lockingRewardWeight));
            }
            r.lastUpdateTime = block.timestamp;
            r.periodFinish = block.timestamp.add(rewardsDuration);
        }
    }

    // @notice Operation for administrator to add Incentive (if needed) to reward staked and locked accounts
    // @author 0xUnique
    function addIncentive(
        uint256[] memory amountInWeek,
        uint256[] memory startTimeOffsetInDay
    ) external onlyOwner
    {
        require(amountInWeek.length == startTimeOffsetInDay.length, "Input parameters length does not equal");

        // Transfer incentive tokens into this contract
        bool isNotify = false;
        uint256 transferAmount;
        for (uint i = 0; i < amountInWeek.length; i++) {
            uint startTime = block.timestamp.div(86400).mul(86400).add(86400 * startTimeOffsetInDay[i]);
            incentiveData.push(IncentiveData({amount: amountInWeek[i], startTime: startTime}));
            transferAmount = transferAmount + amountInWeek[i];

            if (startTimeOffsetInDay[i] == 0) {
                isNotify = true;
            }
        }
        IERC20(address(stakingToken)).safeTransferFrom(msg.sender, address(this), transferAmount);

        if (isNotify) {
            _notifyReward(address(stakingToken), 0, false);
        }

        emit IncentiveAdded(amountInWeek, startTimeOffsetInDay);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(stakingToken), "Cannot withdraw staking token");
        require(rewardData[tokenAddress].lastUpdateTime == 0, "Cannot withdraw reward token");
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function _updateReward(address account) internal {
        address token = address(stakingToken);
        uint256 balance;

        // Update reward for locking
        Reward storage r = rewardData[token];
        uint256 supply = stakedSupply.add(lockedSupply);

        uint256 rpt = _rewardPerToken(token, supply);
        r.rewardPerTokenStored = rpt;
        r.lastUpdateTime = lastTimeRewardApplicable(token);
        if (account != address(this)) {
            // Special case, use the locked balances and supply for stakingReward rewards
            rewards[account][token] = _earned(account, token, balances[account].locked, rpt);
            userRewardPerTokenPaid[account][token] = rpt;
            balance = balances[account].total;
        }

        // Update reward for staking
        r = stakingRewardData[token];
        rpt = _stakingRewardPerToken(token, supply);
        r.rewardPerTokenStored = rpt;
        r.lastUpdateTime = lastTimeStakingRewardApplicable(token);
        if (account != address(this)) {
            stakingRewards[account][token] = _stakingEarned(account, token, balances[account].unlocked, rpt);
            userStakingRewardPerTokenPaid[account][token] = rpt;
        }

        // Other reward token rather than staking token
        uint256 length = rewardTokens.length;
        for (uint i = 1; i < length; i++) {
            token = rewardTokens[i];
            r = rewardData[token];
            rpt = _rewardPerToken(token, supply);
            r.rewardPerTokenStored = rpt;
            r.lastUpdateTime = lastTimeRewardApplicable(token);
            if (account != address(this)) {
                rewards[account][token] = _earned(account, token, balance, rpt);
                userRewardPerTokenPaid[account][token] = rpt;
            }
        }
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount, bool locked);
    event Withdrawn(address indexed user, uint256 receivedAmount, uint256 penaltyPaid);
    event RewardPaid(address indexed user, address indexed rewardsToken, uint256 reward);
    event RewardsDurationUpdated(address token, uint256 newDuration);
    event Recovered(address token, uint256 amount);
    event IncentiveAdded(uint256[] amount, uint256[] offsetInDays);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IChefIncentivesController {

  /**
   * @dev Called by the corresponding asset on any update that affects the rewards distribution
   * @param user The address of the user
   * @param userBalance The balance of the user of the asset in the lending pool
   * @param totalSupply The total supply of the asset in the lending pool
   **/
    function handleAction(
        address user,
        uint256 userBalance,
        uint256 totalSupply
    ) external;

    function addPool(address _token, uint256 _allocPoint) external;

    function claim(address _user, address[] calldata _tokens) external;

    function setClaimReceiver(address _user, address _receiver) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IMultiFeeDistribution {

    function addReward(address rewardsToken) external;

    function mint(address user, uint256 amount, bool withPenalty) external;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}