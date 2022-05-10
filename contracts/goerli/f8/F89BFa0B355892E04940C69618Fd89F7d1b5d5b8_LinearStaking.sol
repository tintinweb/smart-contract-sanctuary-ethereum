// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Util.sol";

/// @title Linear staking contract
/// @dev this library contains all funcionality related to the linear staking mechanism
/// Curve Token owner stake their curve token and receive Medici (MDC) token as rewards.
/// The amount of reward token (MDC) is calculated based on:
/// - the number of staked curve token
/// - the number of blocks the curve tokens are beig staked
/// - the amount of MDC rewards per Block per staked curve token
/// E.g. 10 MDC reward token per block per staked curve token
/// staker 1 stakes 100 curve token and claims rewards (MDC) after 200 Blocks
/// staker 1 recieves 200000 MDC reward tokens (200 blocks * 10 MDC/Block/CurveToken * 100 CurveToken)

library LinearStaking {
    event RewardTokensPerBlockUpdated(IERC20 stakedToken, IERC20 rewardToken, uint256 oldRewardTokensPerBlock, uint256 newRewardTokensPerBlock);
    event RewardsLockedUpdated(IERC20 stakedToken, IERC20 rewardToken, bool rewardsLocked);
    event StakedLinear(address indexed staker, IERC20 indexed stakableToken, uint256 amount);
    event UnstakedLinear(address indexed unstaker, IERC20 indexed stakedToken, uint256 amount, uint256 totalStakedBalance);
    event ClaimedRewardsLinear(address indexed claimer, IERC20 stakedToken, IERC20 rewardToken, uint256 amount);
    event RewardsDeposited(address depositor, IERC20 rewardToken, uint256 amount);
    event RewardsTransferedToTreasury(IERC20 rewardToken, uint256 amount);

    struct LinearStakingStorage {
        IERC20[] stakableTokens;
        /// @dev configuration of rewards for particular stakable tokens
        mapping(IERC20 => RewardConfiguration) rewardConfigurations;
        /// @dev storage of accumulated staking rewards for the pool participants addresses
        mapping(address => mapping(IERC20 => WalletStakingState)) walletStakingStates;
        /// @dev amount of tokens available to be distributed as staking rewards
        mapping(IERC20 => uint256) availableRewards;
    }

    struct RewardConfiguration {
        bool isStakable;
        IERC20[] rewardTokens;
        // mapping(IERC20 => uint256) rewardTokensPerBlock; //Old, should be removed when new algorithm is implemented

        // RewardToken => BlockNumber => RewardTokensPerBlock
        mapping(IERC20 => mapping(uint256 => uint256)) rewardTokensPerBlockHistory;
        // RewardToken => BlockNumbers/Keys of rewardTokensPerBlockHistory[RewardToken][BlockNumbers]
        mapping(IERC20 => uint256[]) rewardTokensPerBlockHistoryBlocks;
        mapping(IERC20 => bool) rewardsLocked;
    }

    struct WalletStakingState {
        uint256 stakedBalance;
        uint256 lastUpdate;
        mapping(IERC20 => uint256) outstandingRewards;
    }

    /// @dev Sets the rewardTokensPerBlock for a stakedToken-rewardToken pair
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param stakedToken the staked token
    /// @param rewardToken the reward token
    /// @param rewardTokensPerBlock rewardTokens per rewardToken per block (rewardToken decimals)
    function setRewardTokensPerBlockLinear(
        LinearStakingStorage storage linearStakingStorage,
        IERC20 stakedToken,
        IERC20 rewardToken,
        uint256 rewardTokensPerBlock
    ) public {
        require(address(stakedToken) != address(0) && address(rewardToken) != address(0), "token adress cannot be zero");

        RewardConfiguration storage rewardConfiguration = linearStakingStorage.rewardConfigurations[stakedToken];

        uint256[] storage rewardTokensPerBlockHistoryBlocks = rewardConfiguration.rewardTokensPerBlockHistoryBlocks[rewardToken];

        uint256 currentRewardTokensPerBlock = 0;

        if (rewardTokensPerBlockHistoryBlocks.length > 0) {
            uint256 lastRewardTokensPerBlockBlock = rewardTokensPerBlockHistoryBlocks[rewardTokensPerBlockHistoryBlocks.length - 1];
            currentRewardTokensPerBlock = rewardConfiguration.rewardTokensPerBlockHistory[rewardToken][lastRewardTokensPerBlockBlock];
        }

        require(rewardTokensPerBlock != currentRewardTokensPerBlock, "rewardTokensPerBlock already set to expected value");

        if (rewardTokensPerBlock != 0 && currentRewardTokensPerBlock == 0) {
            rewardConfiguration.rewardTokens.push(rewardToken);
            linearStakingStorage.stakableTokens.push(stakedToken);
        }

        if (rewardTokensPerBlock == 0 && currentRewardTokensPerBlock != 0) {
            Util.removeValueFromArray(rewardToken, rewardConfiguration.rewardTokens);
            Util.removeValueFromArray(stakedToken, linearStakingStorage.stakableTokens);
        }

        rewardConfiguration.isStakable = rewardTokensPerBlock != 0;

        rewardConfiguration.rewardTokensPerBlockHistory[rewardToken][block.number] = rewardTokensPerBlock;
        rewardTokensPerBlockHistoryBlocks.push(block.number);

        emit RewardTokensPerBlockUpdated(stakedToken, rewardToken, currentRewardTokensPerBlock, rewardTokensPerBlock);
    }

    /// @dev Locks/Unlocks the reward token (MDC) for a certain staking token (Curve Token)
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param stakedToken the staked token
    /// @param rewardToken the reward token
    /// @param rewardsLocked true = lock rewards; false = unlock rewards
    function setRewardsLockedLinear(
        LinearStakingStorage storage linearStakingStorage,
        IERC20 stakedToken,
        IERC20 rewardToken,
        bool rewardsLocked
    ) public {
        require(address(stakedToken) != address(0) && address(rewardToken) != address(0), "token adress cannot be zero");

        if (linearStakingStorage.rewardConfigurations[stakedToken].rewardsLocked[rewardToken] != rewardsLocked) {
            linearStakingStorage.rewardConfigurations[stakedToken].rewardsLocked[rewardToken] = rewardsLocked;
            emit RewardsLockedUpdated(stakedToken, rewardToken, rewardsLocked);
        }
    }

    /// @dev Staking of a stakable token
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param stakableToken the stakeable token
    /// @param amount the amount to stake (stakableToken decimals)
    function stakeLinear(
        LinearStakingStorage storage linearStakingStorage,
        IERC20 stakableToken,
        uint256 amount
    ) public {
        require(amount > 0, "amount must be greater zero");
        require(linearStakingStorage.rewardConfigurations[stakableToken].isStakable, "token is not stakable");
        updateRewardSnapshotLinear(linearStakingStorage, msg.sender, stakableToken);
        linearStakingStorage.walletStakingStates[msg.sender][stakableToken].stakedBalance += Util.checkedTransferFrom(stakableToken, msg.sender, address(this), amount);
        emit StakedLinear(msg.sender, stakableToken, amount);
    }

    /// @dev Unstaking of a staked token
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param stakedToken the staked token
    /// @param amount the amount to unstake
    function unstakeLinear(
        LinearStakingStorage storage linearStakingStorage,
        IERC20 stakedToken,
        uint256 amount
    ) public {
        amount = Math.min(amount, linearStakingStorage.walletStakingStates[msg.sender][stakedToken].stakedBalance);
        require(amount > 0, "amount must be greater zero");
        updateRewardSnapshotLinear(linearStakingStorage, msg.sender, stakedToken);
        linearStakingStorage.walletStakingStates[msg.sender][stakedToken].stakedBalance -= amount;
        stakedToken.transfer(msg.sender, amount);
        uint256 totalStakedBalance = linearStakingStorage.walletStakingStates[msg.sender][stakedToken].stakedBalance;
        emit UnstakedLinear(msg.sender, stakedToken, amount, totalStakedBalance);
        // emit UnstakedLinear(msg.sender, stakedToken, amount);
    }

    /// @dev Updates the outstanding rewards for a specific wallet and staked token. This needs to be called every time before any changes to staked balances are made
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param wallet the wallet
    /// @param stakedToken the staked token
    function updateRewardSnapshotLinear(
        LinearStakingStorage storage linearStakingStorage,
        address wallet,
        IERC20 stakedToken
    ) internal {
        uint256 lastUpdate = linearStakingStorage.walletStakingStates[wallet][stakedToken].lastUpdate;

        if (lastUpdate != 0) {
            IERC20[] memory rewardTokens = linearStakingStorage.rewardConfigurations[stakedToken].rewardTokens;
            for (uint256 i = 0; i < rewardTokens.length; i++) {
                IERC20 rewardToken = rewardTokens[i];
                uint256 newOutstandingRewards = calculateRewardsLinear(linearStakingStorage, wallet, stakedToken, rewardToken);
                linearStakingStorage.walletStakingStates[wallet][stakedToken].outstandingRewards[rewardToken] = newOutstandingRewards;
            }
        }
        linearStakingStorage.walletStakingStates[wallet][stakedToken].lastUpdate = block.number;
    }

    /// @dev Calculates the outstanding rewards for a wallet, staked token and reward token
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param wallet the wallet
    /// @param stakedToken the staked token
    /// @param rewardToken the reward token
    /// @return the outstading rewards (rewardToken decimals)
    function calculateRewardsLinear(
        LinearStakingStorage storage linearStakingStorage,
        address wallet,
        IERC20 stakedToken,
        IERC20 rewardToken
    ) public view returns (uint256) {
        uint256 lastUpdate = linearStakingStorage.walletStakingStates[wallet][stakedToken].lastUpdate;

        if (lastUpdate != 0) {
            uint256 stakedBalance = linearStakingStorage.walletStakingStates[wallet][stakedToken].stakedBalance / 10**Util.getERC20Decimals(stakedToken);

            uint256 accumulatedRewards; // = 0

            uint256 rewardRangeStart;
            uint256 rewardRangeStop = block.number;
            uint256 rewardRangeTokensPerBlock;
            uint256 rewardRangeBlocks;

            uint256[] memory fullHistory = linearStakingStorage.rewardConfigurations[stakedToken].rewardTokensPerBlockHistoryBlocks[rewardToken];
            uint256 i = fullHistory.length - 1;
            for (; i >= 0; i--) {
                rewardRangeStart = fullHistory[i];

                rewardRangeTokensPerBlock = linearStakingStorage.rewardConfigurations[stakedToken].rewardTokensPerBlockHistory[rewardToken][fullHistory[i]];

                if (rewardRangeStart < lastUpdate) {
                    rewardRangeStart = lastUpdate;
                }

                rewardRangeBlocks = rewardRangeStop - rewardRangeStart;

                accumulatedRewards += stakedBalance * rewardRangeBlocks * rewardRangeTokensPerBlock;

                if (rewardRangeStart == lastUpdate) break;

                rewardRangeStop = rewardRangeStart;
            }

            uint256 outStandingRewards = linearStakingStorage.walletStakingStates[wallet][stakedToken].outstandingRewards[rewardToken];

            return (outStandingRewards + accumulatedRewards);
        }
        return 0;
    }

    /// @dev Claims all rewards for a staked tokens
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param stakedToken the staked token
    function claimRewardsLinear(LinearStakingStorage storage linearStakingStorage, IERC20 stakedToken) public {
        updateRewardSnapshotLinear(linearStakingStorage, msg.sender, stakedToken);

        IERC20[] memory rewardTokens = linearStakingStorage.rewardConfigurations[stakedToken].rewardTokens;
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            IERC20 rewardToken = rewardTokens[i];

            if (linearStakingStorage.rewardConfigurations[stakedToken].rewardsLocked[rewardToken]) {
                //rewards for the token are not claimable yet
                continue;
            }

            uint256 rewardAmount = linearStakingStorage.walletStakingStates[msg.sender][stakedToken].outstandingRewards[rewardToken];
            uint256 payableRewardAmount = Math.min(rewardAmount, linearStakingStorage.availableRewards[rewardToken]);
            require(payableRewardAmount > 0, "no rewards available for payout");

            linearStakingStorage.walletStakingStates[msg.sender][stakedToken].outstandingRewards[rewardToken] -= payableRewardAmount;
            linearStakingStorage.availableRewards[rewardToken] -= payableRewardAmount;

            rewardToken.transfer(msg.sender, payableRewardAmount);
            emit ClaimedRewardsLinear(msg.sender, stakedToken, rewardToken, payableRewardAmount);
        }
    }

    /// @dev Allows the deposit of reward funds. This is usually used by the borrower or treasury
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param rewardToken the reward token
    /// @param amount the amount of tokens (rewardToken decimals)
    function depositRewardsLinear(
        LinearStakingStorage storage linearStakingStorage,
        IERC20 rewardToken,
        uint256 amount
    ) public {
        linearStakingStorage.availableRewards[rewardToken] += Util.checkedTransferFrom(rewardToken, msg.sender, address(this), amount);
        emit RewardsDeposited(msg.sender, rewardToken, amount);
    }

    /// @dev Get the staked balance for a specific token and wallet
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param wallet the wallet
    /// @param stakableToken the staked token
    /// @return the staked balance (stakableToken decimals)
    function getStakedBalanceLinear(
        LinearStakingStorage storage linearStakingStorage,
        address wallet,
        IERC20 stakableToken
    ) public view returns (uint256) {
        return linearStakingStorage.walletStakingStates[wallet][stakableToken].stakedBalance;
    }

    function getRewardTokens(LinearStakingStorage storage linearStakingStorage, IERC20 stakedToken) public view returns (IERC20[] memory) {
        return linearStakingStorage.rewardConfigurations[stakedToken].rewardTokens;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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