// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import { IStakedToken } from "./interfaces/IStakedToken.sol";

/**
 * @title StakedTokenBatcher
 * @dev Batch transactions for staking a given staked token.
 */
contract StakedTokenBatcher {
    /**
     * @dev Called by anyone to poke the timestamp of an array of accounts. This allows users to
     * effectively 'claim' any new timeMultiplier, but will revert if any of the accounts has no changes.
     * It is recommend to validate off-chain the accounts before calling this function.
     * @param _stakedToken Address of user the staked token.
     * @param _accounts Array of account addresses to update.
     */
    function reviewTimestamp(address _stakedToken, address[] calldata _accounts) external {
        IStakedToken stakedToken = IStakedToken(_stakedToken);
        uint256 len = _accounts.length;
        require(len > 0, "Invalid inputs");
        for (uint256 i = 0; i < len; ) {
            stakedToken.reviewTimestamp(_accounts[i]);
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../deps/GamifiedTokenStructs.sol";

interface IStakedToken {
    // GETTERS
    function COOLDOWN_SECONDS() external view returns (uint256);

    function UNSTAKE_WINDOW() external view returns (uint256);

    function STAKED_TOKEN() external view returns (IERC20);

    function getRewardToken() external view returns (address);

    function pendingAdditionalReward() external view returns (uint256);

    function whitelistedWrappers(address) external view returns (bool);

    function balanceData(address _account) external view returns (Balance memory);

    function balanceOf(address _account) external view returns (uint256);

    function rawBalanceOf(address _account) external view returns (uint256, uint256);

    function calcRedemptionFeeRate(uint32 _weightedTimestamp)
        external
        view
        returns (uint256 _feeRate);

    function safetyData()
        external
        view
        returns (uint128 collateralisationRatio, uint128 slashingPercentage);

    function delegates(address account) external view returns (address);

    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    function getVotes(address account) external view returns (uint256);

    // HOOKS/PERMISSIONED
    function applyQuestMultiplier(address _account, uint8 _newMultiplier) external;

    // ADMIN
    function whitelistWrapper(address _wrapper) external;

    function blackListWrapper(address _wrapper) external;

    function changeSlashingPercentage(uint256 _newRate) external;

    function emergencyRecollateralisation() external;

    function setGovernanceHook(address _newHook) external;

    // USER
    function stake(uint256 _amount) external;

    function stake(uint256 _amount, address _delegatee) external;

    function stake(uint256 _amount, bool _exitCooldown) external;

    function withdraw(
        uint256 _amount,
        address _recipient,
        bool _amountIncludesFee,
        bool _exitCooldown
    ) external;

    function delegate(address delegatee) external;

    function startCooldown(uint256 _units) external;

    function endCooldown() external;

    function reviewTimestamp(address _account) external;

    function claimReward() external;

    function claimReward(address _to) external;

    // Backwards compatibility
    function createLock(uint256 _value, uint256) external;

    function exit() external;

    function increaseLockAmount(uint256 _value) external;

    function increaseLockLength(uint256) external;
}

// SPDX-License-Identifier: MIT

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
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

struct Balance {
    /// units of staking token that has been deposited and consequently wrapped
    uint88 raw;
    /// (block.timestamp - weightedTimestamp) represents the seconds a user has had their full raw balance wrapped.
    /// If they deposit or withdraw, the weightedTimestamp is dragged towards block.timestamp proportionately
    uint32 weightedTimestamp;
    /// multiplier awarded for staking for a long time
    uint8 timeMultiplier;
    /// multiplier duplicated from QuestManager
    uint8 questMultiplier;
    /// Time at which the relative cooldown began
    uint32 cooldownTimestamp;
    /// Units up for cooldown
    uint88 cooldownUnits;
}

struct QuestBalance {
    /// last timestamp at which the user made a write action to this contract
    uint32 lastAction;
    /// permanent multiplier applied to an account, awarded for PERMANENT QuestTypes
    uint8 permMultiplier;
    /// multiplier that decays after each "season" (~9 months) by 75%, to avoid multipliers getting out of control
    uint8 seasonMultiplier;
}

/// @notice Quests can either give permanent rewards or only for the season
enum QuestType {
    PERMANENT,
    SEASONAL
}

/// @notice Quests can be turned off by the questMaster. All those who already completed remain
enum QuestStatus {
    ACTIVE,
    EXPIRED
}
struct Quest {
    /// Type of quest rewards
    QuestType model;
    /// Multiplier, from 1 == 1.01x to 100 == 2.00x
    uint8 multiplier;
    /// Is the current quest valid?
    QuestStatus status;
    /// Expiry date in seconds for the quest
    uint32 expiry;
}