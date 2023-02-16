// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "../../dependencies/openzeppelin/contracts/IERC20Capped.sol";
import "../../dependencies/openzeppelin/contracts/SafeERC20.sol";
import "../../dependencies/openzeppelin/contracts/SafeMath.sol";
import "../../dependencies/openzeppelin/contracts/Ownable.sol";
import "../../dependencies/governance/TreasuryOwnable.sol";
import "../../interfaces/IPhiatFeeDistribution.sol";
import "./ERC20Recoverable.sol";

contract PhiatFeeDistribution is
    IPhiatFeeDistribution,
    Ownable,
    TreasuryOwnable,
    ERC20Recoverable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20Capped;
    using SafeERC20 for IERC20;

    uint256 public constant override REWARD_RATE_PRECISION_ASSIST = 1e18;
    // Duration that rewards are streamed over
    uint256 public constant override REWARD_DURATION = 86400 * 7; // 1 week
    // Duration to unstake so that tokens are withdrawable
    uint256 public constant override UNSTAKE_DURATION = 86400 * 7 * 2; // 2 weeks
    // Duration to withdraw unstaked tokens
    uint256 public constant override WITHDRAW_DURATION = 86400 * 7; // 1 week

    IERC20Capped public immutable override stakingToken;
    uint256 public immutable override stakingTokenPrecision;
    uint256 public immutable override totalSupply; // staking token's total supply (cap)
    uint256 public override totalStakedSupply; // staking token's total staked supply
    address[] public tokens;
    // reward token -> TokenReward
    mapping(address => TokenReward) public tokenRewards;

    // user -> reward token -> amount
    // should divide by REWARD_RATE_PRECISION_ASSIST to get true reward (for total supply)
    // token's decimals are kept
    mapping(address => mapping(address => uint256)) private _userRewardPaid;
    // treasury reward is recorded in this contract's address - address(this)
    // should divide by REWARD_RATE_PRECISION_ASSIST to get true rewards (for individual user)
    // token's decimals are kept
    mapping(address => mapping(address => uint256)) private _userRewards;

    // user -> total staked balance (including unstaked and not withdrawn)
    mapping(address => uint256) private staked;
    // user -> TimedBalance(unstaked amount, withdraw time)
    mapping(address => TimedBalance) private unstaked;

    /* ========== CONSTRUCTOR ========== */

    constructor(address stakingToken_, address treasury_)
        Ownable()
        TreasuryOwnable(treasury_)
    {
        stakingToken = IERC20Capped(stakingToken_);
        stakingTokenPrecision = 10**IERC20Capped(stakingToken_).decimals();
        totalSupply = IERC20Capped(stakingToken_).cap();
    }

    /* ========== ADMIN CONFIGURATION ========== */

    // Add a new reward token to be distributed to stakers
    function addReward(address tokenAddress) external onlyOwner {
        require(
            tokenAddress != address(stakingToken),
            "PHIAT: Can not add staking token as reward token"
        );
        require(
            tokenRewards[tokenAddress].lastUpdateTime == 0,
            "PHIAT: Can not add existing reward token"
        );
        tokens.push(tokenAddress);
        tokenRewards[tokenAddress].lastUpdateTime = block.timestamp;
        tokenRewards[tokenAddress].periodFinish = block.timestamp;
    }

    function transferTreasury(address newTreasury)
        external
        override
        onlyTreasury
    {
        require(
            newTreasury != address(0),
            "TreasuryOwnable: new treasury is the zero address"
        );
        require(
            staked[newTreasury] == 0,
            "PHIAT: new treasury can not have staked tokens"
        );
        _transferTreasury(newTreasury);
    }

    /* ========== REWARD VIEWS ========== */

    function lastTimeRewardApplicable(address tokenAddress)
        public
        view
        override
        returns (uint256)
    {
        // should only return periodFinish
        // when this is a new reward token
        // or when no new rewards have been collected for over REWARD_DURATION
        uint256 periodFinish = tokenRewards[tokenAddress].periodFinish;
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    // should divide by REWARD_RATE_PRECISION_ASSIST to get true reward per token
    // token's decimals are kept
    // staking token's decimals are removed
    function rewardPerToken(address tokenAddress)
        external
        view
        override
        returns (uint256)
    {
        return _reward(tokenAddress).div(totalSupply);
    }

    function getRewardForDuration(address tokenAddress)
        external
        view
        override
        returns (uint256)
    {
        return
            tokenRewards[tokenAddress].rewardRate.mul(REWARD_DURATION).div(
                REWARD_RATE_PRECISION_ASSIST
            );
    }

    // Address and claimable amount of all reward tokens for the given account
    function claimableRewards(address account)
        external
        view
        override
        returns (RewardAmount[] memory rewards)
    {
        uint256 stakedBalance_;
        if (account == treasury()) {
            account = address(this);
            stakedBalance_ = totalSupply.sub(totalStakedSupply);
        } else {
            stakedBalance_ = staked[account];
        }

        uint256 length = tokens.length;
        rewards = new RewardAmount[](length);
        for (uint256 i = 0; i < length; i++) {
            rewards[i].token = tokens[i];
            rewards[i].amount = _earned(
                account,
                tokens[i],
                stakedBalance_,
                _reward(tokens[i])
            ).div(REWARD_RATE_PRECISION_ASSIST);
        }
        return rewards;
    }

    /* ========== STAKING VIEWS ========== */

    // Total staked balance of an account, including unstaked tokens that haven't been withdrawn
    function stakedBalance(address user)
        external
        view
        override
        returns (uint256 amount)
    {
        return staked[user];
    }

    // Total unstaked balance for an account (in the process of unstaking)
    function unstakedBalance(address user)
        external
        view
        override
        returns (TimedBalance memory balance)
    {
        balance = unstaked[user];
        if (balance.amount == 0) {
            // no record
        } else if (block.timestamp < balance.time) {
            // still unstaking
        } else {
            balance.amount = 0;
            balance.time = 0;
        }
        return balance;
    }

    // Total withdrawable balance for an account
    function withdrawableBalance(address user)
        external
        view
        override
        returns (TimedBalance memory balance)
    {
        balance = unstaked[user];
        if (balance.amount == 0) {
            // no record
        } else if (block.timestamp >= balance.time) {
            // can withdraw if not reaching expiration time
            balance.time = balance.time.add(WITHDRAW_DURATION); // calculate expiration time
            if (block.timestamp >= balance.time) {
                // reached expiration time
                balance.amount = 0;
                balance.time = 0;
            }
        } else {
            balance.amount = 0;
            balance.time = 0;
        }
        return balance;
    }

    /* ========== STAKING MANAGEMENT ========== */

    // Stake tokens to receive rewards
    function stake(uint256 amount) external {
        require(amount > 0, "PHIAT: Cannot stake 0");
        require(_msgSender() != treasury(), "PHIAT: treasury can not stake");
        _updateReward(_msgSender(), true);
        stakingToken.safeTransferFrom(_msgSender(), address(this), amount);
        staked[_msgSender()] = staked[_msgSender()].add(amount);
        totalStakedSupply = totalStakedSupply.add(amount);
        emit Staked(_msgSender(), amount);
    }

    function unstake(uint256 amount) external {
        require(amount > 0, "PHIAT: Cannot unstake 0");
        TimedBalance memory balance = unstaked[_msgSender()];
        require(
            balance.amount == 0 ||
                block.timestamp >= balance.time.add(WITHDRAW_DURATION), // expired
            "PHIAT: Cannot perform multiple unstaking at the same time"
        );
        require(
            amount <= staked[_msgSender()],
            "PHIAT: Cannot unstake more than staked amount"
        );
        balance.amount = amount;
        balance.time = block.timestamp.add(UNSTAKE_DURATION);
        unstaked[_msgSender()] = balance; // will override previously expired unstaking
        emit Unstaked(_msgSender(), amount);
    }

    function cancelUnstake() external {
        TimedBalance memory balance = unstaked[_msgSender()];
        require(
            balance.amount > 0 && block.timestamp < balance.time, // unstaking not finished
            "PHIAT: No unstaking to cancel"
        );
        delete unstaked[_msgSender()];
        emit UnstakeCancelled(_msgSender());
    }

    // Withdraw all withdrawable tokens
    function withdraw() external {
        TimedBalance memory balance = unstaked[_msgSender()];
        require(
            balance.amount > 0 &&
                block.timestamp >= balance.time && // unstaking finished
                block.timestamp < balance.time.add(WITHDRAW_DURATION), // not expired
            "PHIAT: No withdrawable token"
        );
        _updateReward(_msgSender(), true);
        delete unstaked[_msgSender()];
        if (staked[_msgSender()] == balance.amount) {
            delete staked[_msgSender()];
        } else {
            staked[_msgSender()] = staked[_msgSender()].sub(balance.amount);
        }
        totalStakedSupply = totalStakedSupply.sub(balance.amount);
        stakingToken.safeTransfer(_msgSender(), balance.amount);
        emit Withdrawn(_msgSender(), balance.amount);
    }

    // Claim all pending staking rewards
    function getReward() public override {
        _updateReward(_msgSender(), false);
        _getReward();
    }

    /* ========== INTERNAL REWARD MANAGEMENT ========== */

    // should divide by REWARD_RATE_PRECISION_ASSIST to get true reward
    // token's decimals are kept
    function _reward(address tokenAddress) internal view returns (uint256) {
        uint256 lastTimeRewardApplicable_ = lastTimeRewardApplicable(
            tokenAddress
        );
        if (
            lastTimeRewardApplicable_ ==
            tokenRewards[tokenAddress].lastUpdateTime
        ) {
            return tokenRewards[tokenAddress].rewardStored;
        } else {
            uint256 additionalReward = lastTimeRewardApplicable_
                .sub(tokenRewards[tokenAddress].lastUpdateTime)
                .mul(tokenRewards[tokenAddress].rewardRate);
            return
                tokenRewards[tokenAddress].rewardStored.add(additionalReward);
        }
    }

    // should divide by REWARD_RATE_PRECISION_ASSIST to get true earned rewards
    // token's decimals are kept
    function _earned(
        address account,
        address tokenAddress,
        uint256 stakedBalance_,
        uint256 reward
    ) internal view returns (uint256) {
        return
            stakedBalance_
                .mul(reward.sub(_userRewardPaid[account][tokenAddress]))
                .div(totalSupply)
                .add(_userRewards[account][tokenAddress]);
    }

    function _updateReward(address account, bool updateTreasury) internal {
        address thisAddress = address(this);
        uint256 treasuryBalance = totalSupply.sub(totalStakedSupply);
        if (account == treasury()) {
            // treasury info is saved in address(this) to make transferTreasury simpler
            account = thisAddress;
            updateTreasury = false; // no need to update treasury as a separate step
        }
        uint256 stakedBalance_ = account == thisAddress
            ? treasuryBalance
            : staked[account];
        uint256 length = tokens.length;
        for (uint256 i = 0; i < length; i++) {
            address token = tokens[i];
            TokenReward storage tokenReward = tokenRewards[token];

            uint256 reward = _reward(token);
            tokenReward.rewardStored = reward;
            tokenReward.lastUpdateTime = lastTimeRewardApplicable(token);

            // update account reward
            _userRewards[account][token] = _earned(
                account,
                token,
                stakedBalance_,
                reward
            );
            _userRewardPaid[account][token] = reward;
            if (updateTreasury) {
                // update treasury reward
                _userRewards[thisAddress][token] = _earned(
                    thisAddress,
                    token,
                    treasuryBalance,
                    reward
                );
                _userRewardPaid[thisAddress][token] = reward;
            }
        }
    }

    // every 24 hours treasury will check
    // if new rewards were sent to the contract or accrued via aToken interest
    // and collect treasury rewards
    function _getReward() internal {
        address account = _msgSender() == treasury()
            ? address(this)
            : _msgSender();
        uint256 length = tokens.length;
        for (uint256 i = 0; i < length; i++) {
            address token = tokens[i];
            uint256 reward = _userRewards[account][token].div(
                REWARD_RATE_PRECISION_ASSIST
            );
            TokenReward storage tokenReward = tokenRewards[token];
            uint256 tokenBalance = tokenReward.balance;
            uint256 currentBalance = IERC20(token).balanceOf(address(this));
            if (tokenBalance > currentBalance) {
                // current balance has a slight chance to be lower than stored balance
                // when no new rewards for a prolonged period,
                // and some existing rewards are collected
                // this is due to phToken's balanceOf using a scaling function
                // and therefore has a rounding issue
                tokenBalance = currentBalance;
            }
            if (
                tokenReward.periodFinish <=
                block.timestamp.add(REWARD_DURATION - 86400)
            ) {
                // update if progressed more than 1 day since last periodFinish update
                // or when token is newly added as reward token
                uint256 newlyCollectedRewards = currentBalance.sub(
                    tokenBalance
                );
                if (newlyCollectedRewards > 0) {
                    if (block.timestamp >= tokenReward.periodFinish) {
                        // token is newly added as reward token
                        tokenReward.rewardRate = newlyCollectedRewards
                            .mul(REWARD_RATE_PRECISION_ASSIST)
                            .div(REWARD_DURATION);
                    } else {
                        uint256 remainingTime = tokenReward.periodFinish.sub(
                            block.timestamp
                        ); // around 6 days
                        uint256 projectRewards = remainingTime.mul(
                            tokenReward.rewardRate
                        );
                        // use 1-day real and 6-day projection (current reward rate)
                        // to smooth our reward rate calculation
                        tokenReward.rewardRate = newlyCollectedRewards
                            .mul(REWARD_RATE_PRECISION_ASSIST)
                            .add(projectRewards)
                            .div(REWARD_DURATION);
                    }

                    tokenReward.lastUpdateTime = block.timestamp;
                    tokenReward.periodFinish = block.timestamp.add(
                        REWARD_DURATION
                    );
                    tokenBalance = currentBalance;
                }
            }
            if (tokenBalance < reward) {
                // again this may happen due to phToken balanceOf's rounding issue
                // under extreme circumstances mentioned above
                reward = tokenBalance;
                if (reward == 0) {
                    _userRewards[account][token] = 0;
                }
            }
            tokenReward.balance = tokenBalance.sub(reward);

            if (reward == 0) continue;
            _userRewards[account][token] = 0;
            IERC20(token).safeTransfer(_msgSender(), reward);
            emit RewardPaid(_msgSender(), token, reward);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // support recovering ERC20 tokens except for staking tokens and reward tokens
    function recoverERC20(address tokenAddress) external onlyTreasury {
        require(
            tokenAddress != address(stakingToken),
            "PHIAT: Cannot recover staking token"
        );
        require(
            tokenRewards[tokenAddress].lastUpdateTime == 0,
            "PHIAT: Cannot recover reward token"
        );
        _recoverERC20(tokenAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Metadata.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
interface IERC20Capped is IERC20Metadata {
    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
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
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../openzeppelin/contracts/Context.sol";

abstract contract TreasuryOwnable is Context {
    address private _treasury;

    event TreasuryTransferred(
        address indexed previousTreasury,
        address indexed newTreasury
    );

    /**
     * @dev Initializes the contract setting the given account (`treasury_`) as the initial treasury.
     */
    constructor(address treasury_) {
        _treasury = treasury_;
        emit TreasuryTransferred(address(0), treasury_);
    }

    /**
     * @dev Returns the address of the current treasury.
     */
    function treasury() public view virtual returns (address) {
        return _treasury;
    }

    /**
     * @dev Throws if called by any account other than the treasury.
     */
    modifier onlyTreasury() {
        require(
            treasury() == _msgSender(),
            "TreasuryOwnable: caller is not the treasury"
        );
        _;
    }

    /**
     * @dev Transfers treasury of the contract to a new account (`newTreasury`).
     * Can only be called by the current treasury.
     */
    function transferTreasury(address newTreasury)
        external
        virtual
        onlyTreasury
    {
        require(
            newTreasury != address(0),
            "TreasuryOwnable: new treasury is the zero address"
        );
        _transferTreasury(newTreasury);
    }

    function _transferTreasury(address newTreasury) internal virtual {
        emit TreasuryTransferred(_treasury, newTreasury);
        _treasury = newTreasury;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "../dependencies/openzeppelin/contracts/IERC20Capped.sol";

interface IPhiatFeeDistribution {
    /* ========== STATE VARIABLES ========== */

    struct TokenReward {
        // updated via _getReward <- getReward
        uint256 periodFinish;
        // updated via _getReward <- getReward
        // every second how many rewards are accumulated for 1 wei
        // should divide by REWARD_RATE_PRECISION_ASSIST to get true reward rate
        uint256 rewardRate;
        // updated via _updateReward / _getReward <- stake / withdraw / getReward
        uint256 lastUpdateTime;
        // how much rewards have been accumulated so far
        // should divide by REWARD_RATE_PRECISION_ASSIST to get true reward
        // updated via _updateReward <- stake / withdraw / getReward
        uint256 rewardStored;
        // tracks already-added balances to handle accrued interest in phToken rewards
        // updated via _getReward <- getReward
        uint256 balance;
    }
    struct TimedBalance {
        uint256 amount;
        uint256 time; // when user can withdraw or unstaking expires
    }
    struct RewardAmount {
        address token;
        uint256 amount;
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event UnstakeCancelled(address indexed user);
    event Withdrawn(address indexed user, uint256 receivedAmount);
    event RewardPaid(
        address indexed user,
        address indexed rewardToken,
        uint256 reward
    );

    function stakingToken() external view returns (IERC20Capped);

    function stakingTokenPrecision() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalStakedSupply() external view returns (uint256);

    function REWARD_DURATION() external view returns (uint256);

    function UNSTAKE_DURATION() external view returns (uint256);

    function WITHDRAW_DURATION() external view returns (uint256);

    function REWARD_RATE_PRECISION_ASSIST() external view returns (uint256);

    /* ========== REWARD VIEWS ========== */

    function lastTimeRewardApplicable(address tokenAddress)
        external
        view
        returns (uint256);

    // should divide by REWARD_RATE_PRECISION_ASSIST to get true reward per token
    // token's decimals are kept
    // staking token's decimals are removed
    function rewardPerToken(address tokenAddress)
        external
        view
        returns (uint256);

    function getRewardForDuration(address tokenAddress)
        external
        view
        returns (uint256);

    // Address and claimable amount of all reward tokens for the given account
    function claimableRewards(address account)
        external
        view
        returns (RewardAmount[] memory rewards);

    /* ========== STAKING VIEWS ========== */

    // Total staked balance of an account, including unstaked tokens that haven't been withdrawn
    function stakedBalance(address user) external view returns (uint256 amount);

    // Total unstaked balance for an account (in the process of unstaking)
    function unstakedBalance(address user)
        external
        view
        returns (TimedBalance memory balance);

    // Total withdrawable balance for an account
    function withdrawableBalance(address user)
        external
        view
        returns (TimedBalance memory balance);

    function getReward() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../dependencies/openzeppelin/contracts/Context.sol";
import "../../dependencies/openzeppelin/contracts/IERC20.sol";
import "../../dependencies/openzeppelin/contracts/SafeERC20.sol";

abstract contract ERC20Recoverable is Context {
    using SafeERC20 for IERC20;

    event Recovered(address token, address account, uint256 amount);

    function _recoverERC20(address tokenAddress) internal {
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenAmount = token.balanceOf(address(this));
        require(tokenAmount > 0, "ERC20Recoverable: no token to recover");
        token.safeTransfer(_msgSender(), tokenAmount);
        emit Recovered(tokenAddress, _msgSender(), tokenAmount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity 0.7.6;

import "./IERC20.sol";

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
        assembly {
            size := extcodesize(account)
        }
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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