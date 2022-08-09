/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IERC20DetailedBurnable {
    function decimals() external view returns (uint8);

    function burn(uint256 amount) external;

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

interface IERC20DetailedMintable {
    function decimals() external view returns (uint8);

    function mint(address recipient, uint256 amount) external;

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

interface IUniswapV2Router {
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

/**
 * @title HAI staking contract (V2) with rewards harvesting.
 */
contract Staking {
    // Events
    event Stake(
        address indexed account,
        uint256 stakedAt,
        uint256 period,
        uint256 sum,
        uint256 totalStaked
    );

    event Withdraw(address indexed account, uint256 sum, bool isEarly);

    event RewardPoolUpdated(uint256 amount);

    event Harvest(address account, uint256 periods, uint256 amount);

    //Structs
    struct StakeInfo {
        uint256 amount;
        uint256 startedAt;
        uint256 period;
        uint256 activeUntil;
    }

    //Constants
    uint256 private constant _DAY = 60; // 1 day
    uint256 private constant _DAYS_IN_MONT = 30;
    uint256 private constant _YEAR_IN_DAYS = 360;
    //Fields
    mapping(address => StakeInfo) public stakes;
    mapping(uint256 => uint256[]) public levelPeriods;
    mapping(address => uint256) public lastRewardClaims;
    mapping(address => bool) private _operators;

    uint256[] public availablePeriods;

    IERC20DetailedBurnable public stakingToken;
    IERC20DetailedMintable public rewardToken;
    IUniswapV2Router public uniswapV2Router;

    uint256 public tokenDecimals;
    uint256 public totalStaked;
    uint256 public rewardsBalance;
    uint256 public rewardRate;
    uint256 public earlyWithdrawFee;

    constructor(
        address _stakingToken,
        address _rewardToken,
        address _routerAddress
    ) {
        stakingToken = IERC20DetailedBurnable(_stakingToken);
        rewardToken = IERC20DetailedMintable(_rewardToken);
        uniswapV2Router = IUniswapV2Router(_routerAddress);
        tokenDecimals = stakingToken.decimals();
        earlyWithdrawFee = 10;
        rewardRate = 5;
        availablePeriods = [6, 12]; //6 or 12 monthes
    }

    //View functions

    /**
     * @notice Returns staking period of an `account`.
     * @param account account to fetch data for.
     * @return uint256 current staking period.
     */
    function getStakingPeriod(address account) external view returns (uint256) {
        return (stakes[account].activeUntil - stakes[account].startedAt) / _DAY;
    }

    /**
     * @notice Returns rewards available for harvesting.
     * @param account account to fetch data for.
     * @return uint256 - available rewards.
     */
    function availableRewards(address account) external view returns (uint256) {
        (, uint256 reward) = _rewardAmount(account);
        return reward;
    }

    /**
     * @notice Returns a number of not harvested reward periods.
     * @param account account to fetch data for.
     * @return uint256 - reward periods available for harvesting.
     */
    function passedRewardPeriods(address account)
        external
        view
        returns (uint256)
    {
        (uint256 passedPeriods, ) = _rewardAmount(account);
        return passedPeriods;
    }

    /**
     * @notice Returns all stake info.
     * @param account account to fetch data for.
     */
    function allStakeInfo(address account)
        external
        view
        returns (
            uint256 amount,
            uint256 startedAt,
            uint256 period,
            uint256 activeUntil,
            uint256 rewards,
            uint256 nextRewardSeconds
        )
    {
        StakeInfo storage stakeInfo = stakes[account];
        amount = stakeInfo.amount;
        startedAt = stakeInfo.startedAt;
        period = stakeInfo.period;
        activeUntil = stakeInfo.activeUntil;
        if (amount != 0) {
            (, uint256 reward) = _rewardAmount(account);
            rewards = reward;
            nextRewardSeconds = _nextRewardDate(account);
        } else {
            rewards = 0;
            nextRewardSeconds = 0;
        }
    }

    /**
     * @notice Returns timestamp of the next reward period.
     * @param account account to fetch data for.
     * @return uint256 - next reward period timestamp.
     */
    function nextRewardDate(address account) external view returns (uint256) {
        return _nextRewardDate(account);
    }

    //external functions

    /**
     * @notice stake a specific amount for a specified period
     * @param period stake period in months
     * @param amount amount to stake
     */
    function stake(uint256 period, uint256 amount) external {
        require(amount > 0, "amount should be > 0");
        uint256 previousAmount = stakes[msg.sender].amount;
        if (previousAmount != 0) {
            _collectRewards(msg.sender, true);
        }
        _stake(msg.sender, period, amount);
    }

    /**
     * @notice withdraw all tokens if the stake period has passed.
     */
    function withdraw() external {
        require(stakes[msg.sender].amount > 0, "no stake");
        _collectRewards(msg.sender, true);
        _withdraw(msg.sender, stakes[msg.sender].amount);
    }

    /**
     * @notice withdraw all tokens before stake period is not passed.
     * Fee is applied and will be burned.
     */
    function emergencyWithdraw() external {
        require(stakes[msg.sender].amount > 0, "no stake");

        totalStaked -= stakes[msg.sender].amount;
        stakes[msg.sender].amount = 0;

        _withdraw(msg.sender, stakes[msg.sender].amount);
    }

    /**
     * @notice prolong stake
     * Fee is applied and will be burned.
     */
    function prolong(uint256 period) external {
        StakeInfo storage stakeInfo = stakes[msg.sender];
        require(stakeInfo.amount > 0, "stake required");
        require(stakeInfo.activeUntil < block.timestamp, "still active");
        _collectRewards(msg.sender, true);
        _stake(msg.sender, period, 0);
    }

    /**
     * @notice collect all available rewards.
     */
    function harvest() external {
        require(stakes[msg.sender].amount > 0, "no stake");
        _collectRewards(msg.sender, false);
    }

    /**
     * @notice send `amount` of tokens to the reward pool.
     * @param amount to send
     */
    function updateRewardsPool(uint256 amount) external {
        require(
            stakingToken.transferFrom(msg.sender, address(this), amount),
            "transfer failed"
        );
        rewardsBalance += amount;
        emit RewardPoolUpdated(amount);
    }

    function _validatePeriod(uint256 period) private view {
        bool found;
        for (uint256 i = 0; i < availablePeriods.length; i++) {
            if (availablePeriods[i] == period) {
                found = true;
            }
        }
        require(found, "period not exist");
    }

    function _rewardAmount(address account)
        private
        view
        returns (uint256 periodsPassed, uint256 reward)
    {
        StakeInfo storage stakeInfo = stakes[account];
        uint256 time;
        if (block.timestamp > stakeInfo.activeUntil) {
            time = stakeInfo.activeUntil;
        } else {
            time = block.timestamp;
        }
        periodsPassed = (time - lastRewardClaims[account]) / _DAY;
        //Div(360) added because the reward percent is yearly reward.
        //1e8 multiplication and dividing added to mitigate rounding issues.
        reward =
            (stakeInfo.amount * rewardRate * periodsPassed * 1e8) /
            100 /
            _YEAR_IN_DAYS /
            1e8;
    }

    function _nextRewardDate(address account) private view returns (uint256) {
        if (lastRewardClaims[account] == 0) {
            return 0;
        }
        StakeInfo storage stakeInfo = stakes[account];
        if (block.timestamp > stakeInfo.activeUntil) {
            return stakeInfo.activeUntil;
        }
        uint256 passedPeriods = (block.timestamp - stakeInfo.startedAt) / _DAY;
        return ((passedPeriods + 1) * _DAY) + stakeInfo.startedAt;
    }

    function _stake(
        address account,
        uint256 periods,
        uint256 amount
    ) private {
        uint256 newAmount = stakes[account].amount + amount;
        _validatePeriod(periods);

        //Sending tokens from the message sender: user or operator.
        require(
            stakingToken.transferFrom(msg.sender, address(this), amount),
            "transfer failed"
        );
        uint256 until;

        if (amount == 0) {
            until = block.timestamp + (periods * _DAY * _DAYS_IN_MONT);
        } else {
            until = stakes[account].activeUntil;
        }

        _setStakeInfo(account, newAmount, periods, block.timestamp, until);
        totalStaked = totalStaked + amount;
        emit Stake(account, block.timestamp, periods, amount, newAmount);
    }

    function _withdraw(address account, uint256 _amount) private {
        _setStakeInfo(account, 0, 0, 0, 0);
        stakingToken.transfer(account, _amount);
        emit Withdraw(account, _amount, false);
    }

    function _collectRewards(address account, bool notDirect) private {
        if (stakes[account].amount > 0) {
            (uint256 periods, uint256 reward) = _rewardAmount(account);
            if (notDirect && periods == 0) {
                return;
            }
            require(rewardsBalance >= reward, "not enough rewards");
            require(periods > 0, "too early");
            lastRewardClaims[account] =
                lastRewardClaims[account] +
                (_DAY * periods);
            rewardsBalance -= reward;
            uint256 rewardAmountInRewardToken = toRewardTokens(reward);
            require(
                rewardToken.transfer(account, rewardAmountInRewardToken),
                "transfer failed"
            );
            emit Harvest(account, periods, reward);
        }
    }

    function _setStakeInfo(
        address account,
        uint256 amount,
        uint256 periods,
        uint256 startedAt,
        uint256 until
    ) private {
        stakes[account].amount = amount;
        stakes[account].startedAt = startedAt;
        stakes[account].activeUntil = until;
        stakes[account].period = periods;
    }

    function toRewardTokens(uint256 inputAmount)
        private
        view
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = address(rewardToken);
        path[1] = address(stakingToken);

        uint256[] memory outAmountsOut = uniswapV2Router.getAmountsOut(
            inputAmount,
            path
        );
        return outAmountsOut[0];
    }
}