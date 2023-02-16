// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../dependencies/openzeppelin/contracts/SafeMath.sol";

import "../dependencies/pulsex/IPulseXFactory.sol";
import "../dependencies/pulsex/IPulseXPair.sol";

import "../interfaces/IPhiatFeeDistribution.sol";
import "./interfaces/IUiStakeDataProvider.sol";

contract UiStakeDataProvider is IUiStakeDataProvider {
    using SafeMath for uint256;

    IPulseXFactory public immutable pulsexFactory;
    address public immutable wPLS;
    mapping(address => address) private _aTokenMapping;

    constructor(
        IPulseXFactory _pulsexFactory,
        address _wPLS,
        address[] memory aTokens,
        address[] memory underlyings
    ) {
        pulsexFactory = _pulsexFactory;
        wPLS = _wPLS;
        for (uint256 i = 0; i < aTokens.length; i++) {
            _aTokenMapping[aTokens[i]] = underlyings[i];
        }
    }

    function getStakingData(IPhiatFeeDistribution feeDistributor)
        public
        view
        override
        returns (StakingData memory data)
    {
        data.stakingToken = address(feeDistributor.stakingToken());
        data.totalSupply = feeDistributor.totalSupply();
        data.totalStakedSupply = feeDistributor.totalStakedSupply();
        data.stakingTokenPrecision = feeDistributor.stakingTokenPrecision();
        data.rewardDuration = feeDistributor.REWARD_DURATION();
        data.unstakeDuration = feeDistributor.UNSTAKE_DURATION();
        data.withdrawDuration = feeDistributor.WITHDRAW_DURATION();

        data.rewardsPerToken = feeDistributor.claimableRewards(address(0));
        uint256 durationRewardsInPls = 0;
        for (uint256 i = 0; i < data.rewardsPerToken.length; i++) {
            uint256 rewardAmount = feeDistributor.getRewardForDuration(
                data.rewardsPerToken[i].token
            );
            durationRewardsInPls = durationRewardsInPls.add(
                _getEquivalentPlsOnPulsex(
                    _aTokenMapping[data.rewardsPerToken[i].token],
                    rewardAmount
                )
            );
            data.rewardsPerToken[i].amount = rewardAmount
                .mul(data.stakingTokenPrecision)
                .div(data.totalSupply);
        }
        uint256 stakingTokenTotalSupplyInPls = _getEquivalentPlsOnPulsex(
            data.stakingToken,
            data.totalSupply
        );
        data.rewardDurationReturn = durationRewardsInPls.mul(1e18).div(
            stakingTokenTotalSupplyInPls
        );
    }

    function getStakingUserData(
        IPhiatFeeDistribution feeDistributor,
        address user
    )
        external
        view
        override
        returns (StakingData memory data, UserStakingData memory userData)
    {
        data = getStakingData(feeDistributor);

        userData.walletBalance = feeDistributor.stakingToken().balanceOf(user);
        userData.stakedBalance = feeDistributor.stakedBalance(user);
        IPhiatFeeDistribution.TimedBalance memory balance = feeDistributor
            .unstakedBalance(user);
        userData.unstakedBalance = balance.amount;
        userData.withdrawTimestamp = balance.time;
        balance = feeDistributor.withdrawableBalance(user);
        userData.withdrawableBalance = balance.amount;
        userData.expirationTimestamp = balance.time;
        userData.claimableRewards = feeDistributor.claimableRewards(user);
    }

    function _getEquivalentPlsOnPulsex(address targetToken, uint256 amount)
        private
        view
        returns (uint256 plsAmount)
    {
        if (targetToken == wPLS) {
            plsAmount = amount;
        } else {
            IPulseXPair pair = IPulseXPair(
                pulsexFactory.getPair(targetToken, wPLS)
            );
            if (address(pair) == address(0)) {
                return 0;
            }
            // get reserve size
            (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
            if (reserve0 == 0 || reserve1 == 0) {
                return 0;
            }
            // calculate pls amount
            if (pair.token0() == wPLS) {
                plsAmount = amount.mul(reserve0).div(reserve1);
            } else {
                plsAmount = amount.mul(reserve1).div(reserve0);
            }
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.2;

interface IPulseXFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.2;

interface IPulseXPair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../../interfaces/IPhiatFeeDistribution.sol";

interface IUiStakeDataProvider {
    struct StakingData {
        address stakingToken;
        uint256 totalSupply;
        uint256 totalStakedSupply;
        uint256 stakingTokenPrecision;
        uint256 rewardDuration;
        uint256 unstakeDuration;
        uint256 withdrawDuration;
        IPhiatFeeDistribution.RewardAmount[] rewardsPerToken;
        uint256 rewardDurationReturn;
    }

    struct UserStakingData {
        uint256 walletBalance;
        uint256 stakedBalance;
        uint256 unstakedBalance;
        uint256 withdrawTimestamp;
        uint256 withdrawableBalance;
        uint256 expirationTimestamp;
        IPhiatFeeDistribution.RewardAmount[] claimableRewards;
    }

    function getStakingData(IPhiatFeeDistribution feeDistributor)
        external
        view
        returns (StakingData memory data);

    function getStakingUserData(
        IPhiatFeeDistribution feeDistributor,
        address user
    )
        external
        view
        returns (StakingData memory data, UserStakingData memory userData);
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