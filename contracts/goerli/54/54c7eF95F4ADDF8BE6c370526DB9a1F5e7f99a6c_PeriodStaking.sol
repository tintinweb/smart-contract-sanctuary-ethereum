// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "./Util.sol";

/// @title Period staking contract
/// @dev this library contains all funcionality related to the period staking mechanism
/// Lending Pool Token (LPT) owner stake their LPTs within an active staking period (e.g. staking period could be three months)
/// The LPTs can remain staked over several consecutive periods while accumulating staking rewards (currently USDC token).
/// The amount of staking rewards depends on the total staking score per staking period of the LPT owner address and
/// on the total amount of rewards distrubuted for this staking period
/// E.g. Staking period is 90 days and total staking rewards is 900 USDC
/// LPT staker 1 stakes 100 LPTs during the whole 90 days
/// LPT staker 2 starts staking after 45 days and stakes 100 LPTs until the end of the staking period
/// staker 1 staking score is 600 and staker 2 staking score is 300
/// staker 1 claims 600 USDC after staking period is completed
/// staker 2 claims 300 USDC after staking period is completed
/// the staking rewards need to be claimed actively after each staking period is completed and the total rewards have been deposited to the contract by the Borrower

library PeriodStaking {
    event StakedPeriod(address indexed staker, IERC20 indexed stakableToken, uint256 amount);
    event UnstakedPeriod(address indexed unstaker, IERC20 indexed stakedToken, uint256 amount);
    event ClaimedRewardsPeriod(address indexed claimer, IERC20 stakedToken, IERC20 rewardToken, uint256 amount);

    struct PeriodStakingStorage {
        mapping(uint256 => RewardPeriod) rewardPeriods;
        mapping(address => WalletStakingState) walletStakedAmounts;
        mapping(uint256 => mapping(address => uint256)) walletStakingScores;
        uint256 currentRewardPeriodId;
        uint256 duration;
        IERC20 rewardToken;
    }

    struct RewardPeriod {
        uint256 id;
        uint256 start;
        uint256 end;
        uint256 totalRewards;
        uint256 totalStakingScore;
        uint256 finalStakedAmount;
        IERC20 rewardToken;
    }

    struct WalletStakingState {
        uint256 stakedBalance;
        uint256 lastUpdate;
        mapping(IERC20 => uint256) outstandingRewards;
    }

    /// @dev Get the struct/info of all reward periods
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @return returns the array including all reward period structs
    function getRewardPeriods(PeriodStakingStorage storage periodStakingStorage) external view returns (RewardPeriod[] memory) {
        RewardPeriod[] memory rewardPeriodsArray = new RewardPeriod[](periodStakingStorage.currentRewardPeriodId);

        for (uint256 i = 1; i <= periodStakingStorage.currentRewardPeriodId; i++) {
            RewardPeriod storage rewardPeriod = periodStakingStorage.rewardPeriods[i];
            rewardPeriodsArray[i - 1] = rewardPeriod;
        }
        return rewardPeriodsArray;
    }

    /// @dev Start the next reward period
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param periodStart start block of the period, 0 == follow previous period, 1 == start at current block, >1 use passed value
    function startNextRewardPeriod(PeriodStakingStorage storage periodStakingStorage, uint256 periodStart) external {
        require(periodStakingStorage.duration > 0 && address(periodStakingStorage.rewardToken) != address(0), "duration and/or rewardToken not configured");

        RewardPeriod storage currentRewardPeriod = periodStakingStorage.rewardPeriods[periodStakingStorage.currentRewardPeriodId];
        if (periodStakingStorage.currentRewardPeriodId > 0) {
            require(currentRewardPeriod.end > 0 && currentRewardPeriod.end < block.number, "current period has not ended yet");
        }

        periodStakingStorage.currentRewardPeriodId += 1;
        RewardPeriod storage nextRewardPeriod = periodStakingStorage.rewardPeriods[periodStakingStorage.currentRewardPeriodId];
        nextRewardPeriod.rewardToken = periodStakingStorage.rewardToken;

        nextRewardPeriod.id = periodStakingStorage.currentRewardPeriodId;

        if (periodStart == 0) {
            nextRewardPeriod.start = currentRewardPeriod.end != 0 ? currentRewardPeriod.end : block.number;
        } else if (periodStart == 1) {
            nextRewardPeriod.start = block.number;
        } else {
            nextRewardPeriod.start = periodStart;
        }

        nextRewardPeriod.end = nextRewardPeriod.start + periodStakingStorage.duration;
        nextRewardPeriod.finalStakedAmount = currentRewardPeriod.finalStakedAmount;
        nextRewardPeriod.totalStakingScore = currentRewardPeriod.finalStakedAmount * (nextRewardPeriod.end - nextRewardPeriod.start);
    }

    /// @dev Deposit the rewards (USDC token) for a reward period
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param rewardPeriodId The ID of the reward period
    /// @param _totalRewards total amount of period rewards to deposit
    function depositRewardPeriodRewards(
        PeriodStakingStorage storage periodStakingStorage,
        uint256 rewardPeriodId,
        uint256 _totalRewards
    ) public {
        RewardPeriod storage rewardPeriod = periodStakingStorage.rewardPeriods[rewardPeriodId];

        require(rewardPeriod.end > 0 && rewardPeriod.end < block.number, "period has not ended");

        periodStakingStorage.rewardPeriods[rewardPeriodId].totalRewards = Util.checkedTransferFrom(rewardPeriod.rewardToken, msg.sender, address(this), _totalRewards);
    }

    /// @dev Updates the staking score for a wallet over all staking periods
    /// @param periodStakingStorage pointer to period staking storage struct
    function updatePeriod(PeriodStakingStorage storage periodStakingStorage) internal {
        WalletStakingState storage walletStakedAmount = periodStakingStorage.walletStakedAmounts[msg.sender];
        if (walletStakedAmount.stakedBalance > 0 && walletStakedAmount.lastUpdate < periodStakingStorage.currentRewardPeriodId && walletStakedAmount.lastUpdate > 0) {
            uint256 i = walletStakedAmount.lastUpdate + 1;
            for (; i <= periodStakingStorage.currentRewardPeriodId; i++) {
                RewardPeriod storage rewardPeriod = periodStakingStorage.rewardPeriods[i];
                periodStakingStorage.walletStakingScores[i][msg.sender] = walletStakedAmount.stakedBalance * (rewardPeriod.end - rewardPeriod.start);
            }
        }
        walletStakedAmount.lastUpdate = periodStakingStorage.currentRewardPeriodId;
    }

    /// @dev Calculate the staking score for a wallet for a given rewards period
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param wallet wallet address
    /// @param period period ID for which to calculate the staking rewards
    /// @return wallet staking score for a given rewards period
    function getWalletRewardPeriodStakingScore(
        PeriodStakingStorage storage periodStakingStorage,
        address wallet,
        uint256 period
    ) public view returns (uint256) {
        WalletStakingState storage walletStakedAmount = periodStakingStorage.walletStakedAmounts[wallet];
        RewardPeriod storage rewardPeriod = periodStakingStorage.rewardPeriods[period];
        if (walletStakedAmount.lastUpdate > 0 && walletStakedAmount.lastUpdate < period) {
            return walletStakedAmount.stakedBalance * (rewardPeriod.end - rewardPeriod.start);
        } else {
            return periodStakingStorage.walletStakingScores[period][wallet];
        }
    }

    /// @dev Stake Lending Pool Token in current rewards period
    /// @notice emits event StakedPeriod
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param amount amount of LPT to stake
    /// @param lendingPoolToken Lending Pool Token address
    function stakeRewardPeriod(
        PeriodStakingStorage storage periodStakingStorage,
        uint256 amount,
        IERC20 lendingPoolToken
    ) external {
        RewardPeriod storage currentRewardPeriod = periodStakingStorage.rewardPeriods[periodStakingStorage.currentRewardPeriodId];
        require(currentRewardPeriod.start <= block.number && currentRewardPeriod.end > block.number, "no active period");

        updatePeriod(periodStakingStorage);

        amount = Util.checkedTransferFrom(lendingPoolToken, msg.sender, address(this), amount);

        emit StakedPeriod(msg.sender, lendingPoolToken, amount);

        periodStakingStorage.walletStakedAmounts[msg.sender].stakedBalance += amount;

        currentRewardPeriod.finalStakedAmount += amount;

        currentRewardPeriod.totalStakingScore += (currentRewardPeriod.end - block.number) * amount;

        periodStakingStorage.walletStakingScores[periodStakingStorage.currentRewardPeriodId][msg.sender] += (currentRewardPeriod.end - block.number) * amount;
    }

    /// @dev Unstake Lending Pool Token
    /// @notice emits event UnstakedPeriod
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param amount amount of LPT to unstake
    /// @param lendingPoolToken Lending Pool Token address
    function unstakeRewardPeriod(
        PeriodStakingStorage storage periodStakingStorage,
        uint256 amount,
        IERC20 lendingPoolToken
    ) external {
        require(amount <= periodStakingStorage.walletStakedAmounts[msg.sender].stakedBalance, "amount greater than staked amount");
        updatePeriod(periodStakingStorage);

        RewardPeriod storage currentRewardPeriod = periodStakingStorage.rewardPeriods[periodStakingStorage.currentRewardPeriodId];

        periodStakingStorage.walletStakedAmounts[msg.sender].stakedBalance -= amount;
        currentRewardPeriod.finalStakedAmount -= amount;
        if (currentRewardPeriod.end > block.number) {
            currentRewardPeriod.totalStakingScore -= (currentRewardPeriod.end - block.number) * amount;
            periodStakingStorage.walletStakingScores[periodStakingStorage.currentRewardPeriodId][msg.sender] -= (currentRewardPeriod.end - block.number) * amount;
        }

        lendingPoolToken.transfer(msg.sender, amount);
        emit UnstakedPeriod(msg.sender, lendingPoolToken, amount);
    }

    /// @dev Claim rewards (USDC) for a certain staking period
    /// @notice emits event ClaimedRewardsPeriod
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param rewardPeriodId period ID of which to claim staking rewards
    /// @param lendingPoolToken Lending Pool Token address
    function claimRewardPeriod(
        PeriodStakingStorage storage periodStakingStorage,
        uint256 rewardPeriodId,
        IERC20 lendingPoolToken
    ) external {
        RewardPeriod storage rewardPeriod = periodStakingStorage.rewardPeriods[rewardPeriodId];
        require(rewardPeriod.end > 0 && rewardPeriod.end < block.number && rewardPeriod.totalRewards > 0, "period not ready for claiming");
        updatePeriod(periodStakingStorage);

        require(periodStakingStorage.walletStakingScores[rewardPeriodId][msg.sender] > 0, "no rewards to claim");

        uint256 payableRewardAmount = calculatePeriodRewards(
            rewardPeriod.rewardToken,
            rewardPeriod.totalRewards,
            rewardPeriod.totalStakingScore,
            periodStakingStorage.walletStakingScores[rewardPeriodId][msg.sender]
        );
        periodStakingStorage.walletStakingScores[rewardPeriodId][msg.sender] = 0;

        // This condition can never be true, because:
        // calculateRewardsPeriod can never have a walletStakingScore > totalPeriodStakingScore
        // require(payableRewardAmount > 0, "no rewards to claim");

        rewardPeriod.rewardToken.transfer(msg.sender, payableRewardAmount);
        emit ClaimedRewardsPeriod(msg.sender, lendingPoolToken, rewardPeriod.rewardToken, payableRewardAmount);
    }

    /// @dev Calculate the staking rewards of a staking period for a wallet address
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param rewardPeriodId period ID for which to calculate the rewards
    /// @param projectedTotalRewards The amount of total rewards which is planned to be deposited at the end of the staking period
    /// @return returns the amount of staking rewards for a wallet address for a certain staking period
    function calculateWalletRewardsPeriod(
        PeriodStakingStorage storage periodStakingStorage,
        address wallet,
        uint256 rewardPeriodId,
        uint256 projectedTotalRewards
    ) public view returns (uint256) {
        RewardPeriod storage rewardPeriod = periodStakingStorage.rewardPeriods[rewardPeriodId];
        if (projectedTotalRewards == 0) {
            projectedTotalRewards = rewardPeriod.totalRewards;
        }
        return
            calculatePeriodRewards(
                rewardPeriod.rewardToken,
                projectedTotalRewards,
                rewardPeriod.totalStakingScore,
                getWalletRewardPeriodStakingScore(periodStakingStorage, wallet, rewardPeriodId)
            );
    }

    /// @dev Calculate the total amount of payable rewards
    /// @param rewardToken The reward token (e.g. USDC)
    /// @param totalPeriodRewards The total amount of rewards for a certain period
    /// @param totalPeriodStakingScore The total staking score (of all wallet addresses during a certain staking period)
    /// @param walletStakingScore The total staking score (of one wallet address during a certain staking period)
    /// @return returns the total payable amount of staking rewards
    function calculatePeriodRewards(
        IERC20 rewardToken,
        uint256 totalPeriodRewards,
        uint256 totalPeriodStakingScore,
        uint256 walletStakingScore
    ) public view returns (uint256) {
        uint256 rewardTokenDecimals = Util.getERC20Decimals(rewardToken);
        uint256 payableRewardAmount = Util.percent((walletStakingScore * totalPeriodRewards), totalPeriodStakingScore, rewardTokenDecimals);
        // We need to devide after the calculation, so that the 'rest' is cut off
        return payableRewardAmount / (uint256(10)**rewardTokenDecimals);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

library Util {
    /// @dev Return the decimals of an ERC20 token (if the implementations offers it)
    /// @param _token (IERC20) the ERC20 token
    /// @return  (uint8) the decimals
    function getERC20Decimals(IERC20 _token) internal view returns (uint8) {
        return IERC20Metadata(address(_token)).decimals();
    }

    function checkedTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        require(amount > 0, "checkedTransferFrom: amount zero");
        uint256 balanceBefore = token.balanceOf(to);
        token.transferFrom(from, to, amount);
        uint256 receivedAmount = token.balanceOf(to) - balanceBefore;
        require(receivedAmount == amount, "checkedTransferFrom: not amount");
        return receivedAmount;
    }

    function checkedTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) public returns (uint256) {
        require(amount > 0, "checkedTransfer: amount zero");
        uint256 balanceBefore = token.balanceOf(to);
        token.transfer(to, amount);
        uint256 receivedAmount = token.balanceOf(to) - balanceBefore;
        require(receivedAmount == amount, "checkedTransfer: not amount");
        return receivedAmount;
    }

    /// @dev Converts a number from one decimal precision to the other
    /// @param _number (uint256) the number
    /// @param _currentDecimals (uint256) the current decimals of the number
    /// @param _targetDecimals (uint256) the desired decimals for the number
    /// @return  (uint256) the number with _targetDecimals decimals
    function convertDecimals(
        uint256 _number,
        uint256 _currentDecimals,
        uint256 _targetDecimals
    ) public pure returns (uint256) {
        uint256 diffDecimals;

        uint256 amountCorrected = _number;

        if (_targetDecimals < _currentDecimals) {
            diffDecimals = _currentDecimals - _targetDecimals;
            amountCorrected = _number / (uint256(10)**diffDecimals);
        } else if (_targetDecimals > _currentDecimals) {
            diffDecimals = _targetDecimals - _currentDecimals;
            amountCorrected = _number * (uint256(10)**diffDecimals);
        }

        return (amountCorrected);
    }

    function convertDecimalsERC20(
        uint256 _number,
        IERC20 _sourceToken,
        IERC20 _targetToken
    ) public view returns (uint256) {
        return convertDecimals(_number, getERC20Decimals(_sourceToken), getERC20Decimals(_targetToken));
    }

    function percent(
        uint256 numerator,
        uint256 denominator,
        uint256 precision
    ) public pure returns (uint256 quotient) {
        // caution, check safe-to-multiply here
        uint256 _numerator = numerator * 10**(precision + 1);
        // with rounding of last digit
        uint256 _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }

    function removeValueFromArray(IERC20 value, IERC20[] storage array) public {
        bool shift = false;
        uint256 i = 0;
        while (i < array.length - 1) {
            if (array[i] == value) shift = true;
            if (shift) {
                array[i] = array[i + 1];
            }
            i++;
        }
        array.pop();
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}