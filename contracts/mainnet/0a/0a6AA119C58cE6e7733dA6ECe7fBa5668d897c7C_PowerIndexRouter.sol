// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/WrappedPiErc20Interface.sol";
import "../interfaces/IRouterConnector.sol";

/**
 * @notice Connectors execute staking strategies by calling from PowerIndexRouter with delegatecall. Therefore,
 * connector contracts should not have any rights stored in other contracts. Instead, rights for connector logic
 * must be provided to PowerIndexRouter by proxy pattern, where the router is a proxy, and the connectors are
 * implementations. Every connector implementation has unique staking logic for stake, redeem, beforePoke, and
 * afterPoke functions, that returns data to save in PowerIndexRouter storage because connectors don't have any
 * storage.
 */
abstract contract AbstractConnector is IRouterConnector {
  using SafeMath for uint256;

  uint256 public constant DEGRADATION_COEFFICIENT = 1 ether;
  uint256 public constant HUNDRED_PCT = 1 ether;
  uint256 public immutable LOCKED_PROFIT_DEGRADATION;

  event Stake(address indexed sender, address indexed staking, address indexed underlying, uint256 amount);
  event Redeem(address indexed sender, address indexed staking, address indexed underlying, uint256 amount);

  event DistributeReward(
    address indexed sender,
    uint256 totalReward,
    uint256 performanceFee,
    uint256 piTokenReward,
    uint256 lockedProfitBefore,
    uint256 lockedProfitAfter
  );

  event DistributePerformanceFee(
    uint256 performanceFeeDebtBefore,
    uint256 performanceFeeDebtAfter,
    uint256 underlyingBalance,
    uint256 performance
  );

  constructor(uint256 _lockedProfitDegradation) public {
    LOCKED_PROFIT_DEGRADATION = _lockedProfitDegradation;
  }

  /**
   * @notice Call external contract by piToken (piERC20) contract.
   * @param _piToken piToken(piERC20) to call from.
   * @param _contract Contract to call.
   * @param _sig Function signature to call.
   * @param _data Data of function arguments to call.
   * @return Data returned from contract.
   */
  function _callExternal(
    WrappedPiErc20Interface _piToken,
    address _contract,
    bytes4 _sig,
    bytes memory _data
  ) internal returns (bytes memory) {
    return _piToken.callExternal(_contract, _sig, _data, 0);
  }

  /**
   * @notice Distributes performance fee from reward and calculates locked profit.
   * @param _distributeData Data is stored in the router contract and passed to the connector's functions.
   * @param _piToken piToken(piERC20) address.
   * @param _token ERC20 Token address to distribute reward.
   * @param _totalReward Total reward received
   * @return lockedProfitReward Rewards that locked in vesting.
   * @return stakeData Result packed rewards data.
   */
  function _distributeReward(
    DistributeData memory _distributeData,
    WrappedPiErc20Interface _piToken,
    IERC20 _token,
    uint256 _totalReward
  ) internal returns (uint256 lockedProfitReward, bytes memory stakeData) {
    (uint256 lockedProfit, uint256 lastRewardDistribution, uint256 performanceFeeDebt) = unpackStakeData(
      _distributeData.stakeData
    );
    uint256 pvpReward;
    // Step #1. Distribute pvpReward
    (pvpReward, lockedProfitReward, performanceFeeDebt) = _distributePerformanceFee(
      _distributeData.performanceFee,
      _distributeData.performanceFeeReceiver,
      performanceFeeDebt,
      _piToken,
      _token,
      _totalReward
    );
    require(lockedProfitReward > 0, "NO_POOL_REWARDS_UNDERLYING");

    // Step #2 Reset lockedProfit
    uint256 lockedProfitBefore = calculateLockedProfit(lockedProfit, lastRewardDistribution);
    uint256 lockedProfitAfter = lockedProfitBefore.add(lockedProfitReward);
    lockedProfit = lockedProfitAfter;

    lastRewardDistribution = block.timestamp;

    emit DistributeReward(
      msg.sender,
      _totalReward,
      pvpReward,
      lockedProfitReward,
      lockedProfitBefore,
      lockedProfitAfter
    );

    return (lockedProfitReward, packStakeData(lockedProfit, lastRewardDistribution, performanceFeeDebt));
  }

  /**
   * @notice Distributes performance fee from reward.
   * @param _performanceFee Share of fee to subtract as performance fee.
   * @param _performanceFeeReceiver Receiver of performance fee.
   * @param _performanceFeeDebt Performance fee amount left from last distribution.
   * @param _piToken piToken(piERC20).
   * @param _underlying Underlying ERC20 token.
   * @param _totalReward Total reward amount.
   * @return performance Fee amount calculated to distribute.
   * @return remainder Diff between total reward amount and performance fee.
   * @return resultPerformanceFeeDebt Not yet distributed performance amount due to insufficient balance on
   *         piToken (piERC20).
   */
  function _distributePerformanceFee(
    uint256 _performanceFee,
    address _performanceFeeReceiver,
    uint256 _performanceFeeDebt,
    WrappedPiErc20Interface _piToken,
    IERC20 _underlying,
    uint256 _totalReward
  )
    internal
    returns (
      uint256 performance,
      uint256 remainder,
      uint256 resultPerformanceFeeDebt
    )
  {
    performance = 0;
    remainder = 0;
    resultPerformanceFeeDebt = _performanceFeeDebt;

    if (_performanceFee > 0) {
      performance = _totalReward.mul(_performanceFee).div(HUNDRED_PCT);
      remainder = _totalReward.sub(performance);

      uint256 performanceFeeDebtBefore = _performanceFeeDebt;
      uint256 underlyingBalance = _underlying.balanceOf(address(_piToken));
      uint256 totalFeeToPayOut = performance.add(performanceFeeDebtBefore);
      if (underlyingBalance >= totalFeeToPayOut) {
        _safeTransfer(_piToken, _underlying, _performanceFeeReceiver, totalFeeToPayOut);
      } else {
        resultPerformanceFeeDebt = totalFeeToPayOut.sub(underlyingBalance);
        _safeTransfer(_piToken, _underlying, _performanceFeeReceiver, underlyingBalance);
      }

      emit DistributePerformanceFee(performanceFeeDebtBefore, resultPerformanceFeeDebt, underlyingBalance, performance);
    } else {
      remainder = _totalReward;
    }
  }

  /**
   * @notice Pack stake data to bytes.
   */
  function packStakeData(
    uint256 lockedProfit,
    uint256 lastRewardDistribution,
    uint256 performanceFeeDebt
  ) public pure returns (bytes memory) {
    return abi.encode(lockedProfit, lastRewardDistribution, performanceFeeDebt);
  }

  /**
   * @notice Unpack stake data from bytes to variables.
   */
  function unpackStakeData(bytes memory _stakeData)
    public
    pure
    returns (
      uint256 lockedProfit,
      uint256 lastRewardDistribution,
      uint256 performanceFeeDebt
    )
  {
    if (_stakeData.length == 0 || keccak256(_stakeData) == keccak256("")) {
      return (0, 0, 0);
    }
    (lockedProfit, lastRewardDistribution, performanceFeeDebt) = abi.decode(_stakeData, (uint256, uint256, uint256));
  }

  /**
   * @notice Calculate locked profit from packed _stakeData.
   */
  function calculateLockedProfit(bytes memory _stakeData) external view override returns (uint256) {
    (uint256 lockedProfit, uint256 lastRewardDistribution, ) = unpackStakeData(_stakeData);
    return calculateLockedProfit(lockedProfit, lastRewardDistribution);
  }

  /**
   * @notice Calculate locked profit based on lastRewardDistribution timestamp.
   * @param _lockedProfit Previous locked profit amount.
   * @param _lastRewardDistribution Timestamp of last rewards distribution.
   * @return Updated locked profit amount, calculated with past time from _lastRewardDistribution.
   */
  function calculateLockedProfit(uint256 _lockedProfit, uint256 _lastRewardDistribution) public view returns (uint256) {
    uint256 lockedFundsRatio = (block.timestamp.sub(_lastRewardDistribution)).mul(LOCKED_PROFIT_DEGRADATION);

    if (lockedFundsRatio < DEGRADATION_COEFFICIENT) {
      uint256 currentLockedProfit = _lockedProfit;
      return currentLockedProfit.sub(lockedFundsRatio.mul(currentLockedProfit) / DEGRADATION_COEFFICIENT);
    } else {
      return 0;
    }
  }

  /**
   * @notice Transfer token amount from piToken(piERC20) to destination.
   * @param _piToken piToken(piERC20).
   * @param _token ERC20 token address.
   * @param _to Destination address.
   * @param _value Amount to transfer.
   */
  function _safeTransfer(
    WrappedPiErc20Interface _piToken,
    IERC20 _token,
    address _to,
    uint256 _value
  ) internal {
    bytes memory response = _piToken.callExternal(
      address(_token),
      IERC20.transfer.selector,
      abi.encode(_to, _value),
      0
    );

    if (response.length > 0) {
      // Return data is optional
      require(abi.decode(response, (bool)), "ERC20 operation did not succeed");
    }
  }

  function isClaimAvailable(
    bytes calldata _claimParams, // solhint-disable-line
    uint256 _lastClaimRewardsAt, // solhint-disable-line
    uint256 _lastChangeStakeAt // solhint-disable-line
  ) external view virtual override returns (bool) {
    return true;
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

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20Permit.sol";

interface WrappedPiErc20Interface is IERC20Permit {
  function deposit(uint256 _amount) external payable returns (uint256);

  function withdraw(uint256 _amount) external payable returns (uint256);

  function withdrawShares(uint256 _burnAmount) external payable returns (uint256);

  function changeRouter(address _newRouter) external;

  function enableRouterCallback(bool _enable) external;

  function setNoFee(address _for, bool _noFee) external;

  function setEthFee(uint256 _newEthFee) external;

  function withdrawEthFee(address payable receiver) external;

  function approveUnderlying(address _to, uint256 _amount) external;

  function getPiEquivalentForUnderlying(uint256 _underlyingAmount) external view returns (uint256);

  function getUnderlyingEquivalentForPi(uint256 _piAmount) external view returns (uint256);

  function balanceOfUnderlying(address account) external view returns (uint256);

  function callExternal(
    address voting,
    bytes4 signature,
    bytes calldata args,
    uint256 value
  ) external payable returns (bytes memory);

  struct ExternalCallData {
    address destination;
    bytes4 signature;
    bytes args;
    uint256 value;
  }

  function callExternalMultiple(ExternalCallData[] calldata calls) external payable returns (bytes[] memory);

  function getUnderlyingBalance() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

import "../interfaces/PowerIndexRouterInterface.sol";

interface IRouterConnector {
  struct DistributeData {
    bytes stakeData;
    bytes stakeParams;
    uint256 performanceFee;
    address performanceFeeReceiver;
  }

  function beforePoke(
    bytes calldata _pokeData,
    DistributeData memory _distributeData,
    bool _willClaimReward
  ) external;

  function afterPoke(PowerIndexRouterInterface.StakeStatus _status, bool _rewardClaimDone)
    external
    returns (bytes calldata);

  function initRouter(bytes calldata) external;

  function getUnderlyingStaked() external view returns (uint256);

  function isClaimAvailable(
    bytes calldata _claimParams,
    uint256 _lastClaimRewardsAt,
    uint256 _lastChangeStakeAt
  ) external view returns (bool);

  function redeem(uint256 _amount, DistributeData calldata _distributeData)
    external
    returns (bytes calldata, bool claimed);

  function stake(uint256 _amount, DistributeData calldata _distributeData)
    external
    returns (bytes calldata, bool claimed);

  function calculateLockedProfit(bytes calldata _stakeData) external view returns (uint256);

  function claimRewards(PowerIndexRouterInterface.StakeStatus _status, DistributeData calldata _distributeData)
    external
    returns (bytes calldata);
}

// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit is IERC20 {
  /**
   * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
   * given ``owner``'s signed approval.
   *
   * IMPORTANT: The same issues {IERC20-approve} has related to transaction
   * ordering also apply here.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `deadline` must be a timestamp in the future.
   * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
   * over the EIP712-formatted function arguments.
   * - the signature must use ``owner``'s current nonce (see {nonces}).
   *
   * For more information on the signature format, see the
   * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
   * section].
   */
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @dev Returns the current nonce for `owner`. This value must be
   * included whenever a signature is generated for {permit}.
   *
   * Every successful call to {permit} increases ``owner``'s nonce by one. This
   * prevents a signature from being used multiple times.
   */
  function nonces(address owner) external view returns (uint256);

  /**
   * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
   */
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view returns (bytes32);
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

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface PowerIndexRouterInterface {
  enum StakeStatus {
    EQUILIBRIUM,
    EXCESS,
    SHORTAGE
  }

  //  function setVotingAndStaking(address _voting, address _staking) external;

  function setReserveConfig(
    uint256 _reserveRatio,
    uint256 _reserveRatioLowerBound,
    uint256 _reserveRatioUpperBound,
    uint256 _claimRewardsInterval
  ) external;

  function getPiEquivalentForUnderlying(uint256 _underlyingAmount, uint256 _piTotalSupply)
    external
    view
    returns (uint256);

  function getPiEquivalentForUnderlyingPure(
    uint256 _underlyingAmount,
    uint256 _totalUnderlyingWrapped,
    uint256 _piTotalSupply
  ) external pure returns (uint256);

  function getUnderlyingEquivalentForPi(uint256 _piAmount, uint256 _piTotalSupply) external view returns (uint256);

  function getUnderlyingEquivalentForPiPure(
    uint256 _piAmount,
    uint256 _totalUnderlyingWrapped,
    uint256 _piTotalSupply
  ) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/torn/ITornStaking.sol";
import "../interfaces/torn/ITornGovernance.sol";
import "./AbstractConnector.sol";
import { UniswapV3OracleHelper } from "../libs/UniswapV3OracleHelper.sol";

contract TornPowerIndexConnector is AbstractConnector {
  event Stake(address indexed sender, uint256 amount, uint256 rewardReceived);
  event Redeem(address indexed sender, uint256 amount, uint256 rewardReceived);

  uint256 public constant RATIO_CONSTANT = 10000000 ether;
  address public immutable GOVERNANCE;
  address public immutable STAKING;
  IERC20 public immutable UNDERLYING;
  WrappedPiErc20Interface public immutable PI_TOKEN;

  constructor(
    address _staking,
    address _underlying,
    address _piToken,
    address _governance
  )
    public
    // 1e18 for 100% / (6 hours * 60 * 60) seconds ~= 46e12 degradation per 1 second
    AbstractConnector(46e12)
  {
    STAKING = _staking;
    UNDERLYING = IERC20(_underlying);
    PI_TOKEN = WrappedPiErc20Interface(_piToken);
    GOVERNANCE = _governance;
  }

  // solhint-disable-next-line
  function claimRewards(PowerIndexRouterInterface.StakeStatus _status, DistributeData memory _distributeData)
    external
    override
    returns (bytes memory stakeData)
  {
    uint256 tokenBefore = UNDERLYING.balanceOf(address(PI_TOKEN));
    _claimImpl();
    uint256 receivedReward = UNDERLYING.balanceOf(address(PI_TOKEN)).sub(tokenBefore);
    if (receivedReward > 0) {
      uint256 rewardsToReinvest;
      (rewardsToReinvest, stakeData) = _distributeReward(_distributeData, PI_TOKEN, UNDERLYING, receivedReward);
      _approveToStaking(rewardsToReinvest);
      _stakeImpl(rewardsToReinvest);
      return stakeData;
    }
    // Otherwise the rewards are distributed each time deposit/withdraw methods are called,
    // so no additional actions required.
    return new bytes(0);
  }

  function stake(uint256 _amount, DistributeData memory) public override returns (bytes memory result, bool claimed) {
    _stakeImpl(_amount);
    emit Stake(msg.sender, GOVERNANCE, address(UNDERLYING), _amount);
  }

  function redeem(uint256 _amount, DistributeData memory)
    external
    override
    returns (bytes memory result, bool claimed)
  {
    _redeemImpl(_amount);
    emit Redeem(msg.sender, GOVERNANCE, address(UNDERLYING), _amount);
  }

  function beforePoke(
    bytes memory _pokeData,
    DistributeData memory _distributeData,
    bool _willClaimReward
  ) external override {}

  function afterPoke(
    PowerIndexRouterInterface.StakeStatus, /*reserveStatus*/
    bool /*_rewardClaimDone*/
  ) external override returns (bytes memory) {
    return new bytes(0);
  }

  function initRouter(bytes calldata) external override {
    _approveToStaking(uint256(-1));
  }

  /*** VIEWERS ***/

  function getPendingRewards() external view returns (uint256) {
    return ITornStaking(STAKING).checkReward(address(PI_TOKEN));
  }

  /**
   * @notice Calculate pending rewards of TornStaking
   * @param _accRewardPerTorn TornStaking variable, getting by accumulatedRewardPerTorn()
   * @param _accRewardRateOnLastUpdate TornStaking variable, getting by accumulatedRewardRateOnLastUpdate()
   * @param _lockedBalance Staked amount in TornGovernance
   */
  function pendingReward(
    uint256 _accRewardPerTorn,
    uint256 _accRewardRateOnLastUpdate,
    uint256 _lockedBalance
  ) public view returns (uint256) {
    return
      _lockedBalance.mul(_accRewardPerTorn.sub(_accRewardRateOnLastUpdate)).div(RATIO_CONSTANT).add(
        ITornStaking(STAKING).accumulatedRewards(address(PI_TOKEN))
      );
  }

  /**
   * @notice Calculate forecast rewards from TornStaking
   * @param _accRewardPerTorn TornStaking variable, getting by accumulatedRewardPerTorn()
   * @param _accRewardRateOnLastUpdate TornStaking variable, getting by accumulatedRewardRateOnLastUpdate()
   * @param _reinvestDuration Duration in seconds to forecast future rewards
   * @param _lastRewardsUpdate Last stake/unstake/claim action timestamp
   * @param _lockedBalance Staked amount in TornGovernance
   */
  function forecastReward(
    uint256 _accRewardPerTorn,
    uint256 _accRewardRateOnLastUpdate,
    uint256 _reinvestDuration,
    uint256 _lastRewardsUpdate,
    uint256 _lockedBalance
  ) public view returns (uint256) {
    return
      _reinvestDuration
        .mul(_accRewardPerTorn.sub(_accRewardRateOnLastUpdate))
        .div(block.timestamp.sub(_lastRewardsUpdate))
        .mul(_lockedBalance)
        .div(RATIO_CONSTANT);
  }

  /**
   * @notice Calculate pending rewards from TornStaking and forecast
   * @param _lastClaimRewardsAt Last claim action timestamp
   * @param _lastChangeStakeAt Last stake/unstake action timestamp
   * @param _reinvestDuration Duration to forecast future rewards, based on last stake/unstake period of rewards
   */
  function getPendingAndForecastReward(
    uint256 _lastClaimRewardsAt,
    uint256 _lastChangeStakeAt,
    uint256 _reinvestDuration
  )
    public
    view
    returns (
      uint256 pending,
      uint256 forecast,
      uint256 forecastByPending
    )
  {
    uint256 lastUpdate = _lastClaimRewardsAt > _lastChangeStakeAt ? _lastClaimRewardsAt : _lastChangeStakeAt;
    uint256 lockedBalance = getUnderlyingStaked();
    uint256 accRewardPerTorn = ITornStaking(STAKING).accumulatedRewardPerTorn();
    uint256 accRewardOnLastUpdate = ITornStaking(STAKING).accumulatedRewardRateOnLastUpdate(address(PI_TOKEN));
    pending = pendingReward(accRewardPerTorn, accRewardOnLastUpdate, lockedBalance);

    return (
      pending,
      forecastReward(accRewardPerTorn, accRewardOnLastUpdate, _reinvestDuration, lastUpdate, lockedBalance),
      forecastReward(accRewardPerTorn, accRewardOnLastUpdate, _reinvestDuration, lastUpdate, pending)
    );
  }

  /**
   * @notice Checking: is pending rewards in TORN enough to cover transaction cost to reinvest
   * @param _claimParams Claim parameters, that stored in PowerIndexRouter
   * @param _lastClaimRewardsAt Last claim action timestamp
   * @param _lastChangeStakeAt Last stake/unstake action timestamp
   */
  function isClaimAvailable(
    bytes calldata _claimParams,
    uint256 _lastClaimRewardsAt,
    uint256 _lastChangeStakeAt
  ) external view virtual override returns (bool) {
    (uint256 paybackDuration, uint256 gasToReinvest) = unpackClaimParams(_claimParams);
    (, , uint256 forecastByPending) = getPendingAndForecastReward(
      _lastClaimRewardsAt,
      _lastChangeStakeAt,
      paybackDuration
    );
    return forecastByPending >= getTornUsedToReinvest(gasToReinvest, tx.gasprice);
  }

  /**
   * @notice Get reinvest transaction cost in TORN
   * @param _gasUsed Gas used for reinvest transaction
   * @param _gasPrice Gas price
   */
  function getTornUsedToReinvest(uint256 _gasUsed, uint256 _gasPrice) public view returns (uint256) {
    return calcTornOutByWethIn(_gasUsed.mul(_gasPrice));
  }

  /**
   * @notice Get Uniswap V3 TORN price ratio
   */
  function getTornPriceRatio() public view virtual returns (uint256) {
    uint32 uniswapTimePeriod = 5400;
    uint24 uniswapTornSwappingFee = 10000;
    uint24 uniswapWethSwappingFee = 0;

    return
      UniswapV3OracleHelper.getPriceRatioOfTokens(
        [address(UNDERLYING), UniswapV3OracleHelper.WETH],
        [uniswapTornSwappingFee, uniswapWethSwappingFee],
        uniswapTimePeriod
      );
  }

  /**
   * @notice Convert TORN amount to WETH amount with built in ratio
   * @param _tornAmountIn TORN amount to convert
   */
  function calcWethOutByTornIn(uint256 _tornAmountIn) external view returns (uint256) {
    return _tornAmountIn.mul(getTornPriceRatio()).div(UniswapV3OracleHelper.RATIO_DIVIDER);
  }

  /**
   * @notice Convert WETH amount to TORN amount with built in ratio
   * @param _wethAmount WETH amount to convert
   */
  function calcTornOutByWethIn(uint256 _wethAmount) public view returns (uint256) {
    return _wethAmount.mul(UniswapV3OracleHelper.RATIO_DIVIDER).div(getTornPriceRatio());
  }

  /**
   * @notice Pack claim params to bytes.
   */
  function packClaimParams(uint256 paybackDuration, uint256 gasToReinvest) external pure returns (bytes memory) {
    return abi.encode(paybackDuration, gasToReinvest);
  }

  /**
   * @notice Unpack claim params from bytes to variables.
   */
  function unpackClaimParams(bytes memory _claimParams)
    public
    pure
    returns (uint256 paybackDuration, uint256 gasToReinvest)
  {
    if (_claimParams.length == 0 || keccak256(_claimParams) == keccak256("")) {
      return (0, 0);
    }
    (paybackDuration, gasToReinvest) = abi.decode(_claimParams, (uint256, uint256));
  }

  /*** OVERRIDES ***/

  function getUnderlyingStaked() public view override returns (uint256) {
    if (STAKING == address(0)) {
      return 0;
    }
    return ITornGovernance(GOVERNANCE).lockedBalance(address(PI_TOKEN));
  }

  function _approveToStaking(uint256 _amount) internal {
    PI_TOKEN.approveUnderlying(GOVERNANCE, _amount);
  }

  function _claimImpl() internal {
    _callExternal(PI_TOKEN, STAKING, ITornStaking.getReward.selector, new bytes(0));
  }

  function _stakeImpl(uint256 _amount) internal {
    _callExternal(PI_TOKEN, GOVERNANCE, ITornGovernance.lockWithApproval.selector, abi.encode(_amount));
  }

  function _redeemImpl(uint256 _amount) internal {
    _callExternal(PI_TOKEN, GOVERNANCE, ITornGovernance.unlock.selector, abi.encode(_amount));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ITornStaking {
  function checkReward(address user) external view returns (uint256 amount);

  function getReward() external;

  function accumulatedRewards(address user) external view returns (uint256 amount);

  function accumulatedRewardPerTorn() external view returns (uint256);

  function accumulatedRewardRateOnLastUpdate(address user) external view returns (uint256);

  function addBurnRewards(uint256 amount) external;

  function updateRewardsOnLockedBalanceChange(address account, uint256 amountLockedBeforehand) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ITornGovernance {
  function lockedBalance(address _user) external view returns (uint256 amount);

  function lockWithApproval(uint256 amount) external;

  function unlock(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import { OracleLibrary } from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import { IUniswapV3Factory } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

interface IERC20Decimals {
  function decimals() external view returns (uint8);
}

library UniswapV3OracleHelper {
  using SafeMath for uint256;

  IUniswapV3Factory internal constant UniswapV3Factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
  address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  uint256 internal constant RATIO_DIVIDER = 1e18;

  /**
   * @notice This function should return the price of baseToken in quoteToken, as in: quote/base (WETH/TORN)
   * @dev uses the Uniswap written OracleLibrary "getQuoteAtTick", does not call external libraries,
   *      uses decimals() for the correct power of 10
   * @param baseToken token which will be denominated in quote token
   * @param quoteToken token in which price will be denominated
   * @param fee the uniswap pool fee, pools have different fees so this is a pool selector for our usecase
   * @param period the amount of seconds we are going to look into the past for the new token price
   * @return returns the price of baseToken in quoteToken
   * */
  function getPriceOfTokenInToken(
    address baseToken,
    address quoteToken,
    uint24 fee,
    uint32 period
  ) internal view returns (uint256) {
    uint128 base = uint128(10)**uint128(IERC20Decimals(quoteToken).decimals());
    if (baseToken == quoteToken) {
      return base;
    } else {
      (int24 timeWeightedAverageTick, ) = OracleLibrary.consult(
        UniswapV3Factory.getPool(baseToken, quoteToken, fee),
        period
      );
      return OracleLibrary.getQuoteAtTick(timeWeightedAverageTick, base, baseToken, quoteToken);
    }
  }

  /**
   * @notice This function should return the price of token in WETH
   * @dev simply feeds WETH in to the above function
   * @param token token which will be denominated in WETH
   * @param fee the uniswap pool fee, pools have different fees so this is a pool selector for our usecase
   * @param period the amount of seconds we are going to look into the past for the new token price
   * @return returns the price of token in WETH
   * */
  function getPriceOfTokenInWETH(
    address token,
    uint24 fee,
    uint32 period
  ) internal view returns (uint256) {
    return getPriceOfTokenInToken(token, WETH, fee, period);
  }

  /**
   * @notice This function should return the price of WETH in token
   * @dev simply feeds WETH into getPriceOfTokenInToken
   * @param token token which WETH will be denominated in
   * @param fee the uniswap pool fee, pools have different fees so this is a pool selector for our usecase
   * @param period the amount of seconds we are going to look into the past for the new token price
   * @return returns the price of token in WETH
   * */
  function getPriceOfWETHInToken(
    address token,
    uint24 fee,
    uint32 period
  ) internal view returns (uint256) {
    return getPriceOfTokenInToken(WETH, token, fee, period);
  }

  /**
   * @notice This function returns the price of token[0] in token[1], but more precisely and importantly the price ratio
      of the tokens in WETH
   * @dev this is done as to always have good prices due to WETH-token pools mostly always having the most liquidity
   * @param tokens array of tokens to get ratio for
   * @param fees the uniswap pool FEES, since these are two independent tokens
   * @param period the amount of seconds we are going to look into the past for the new token price
   * @return returns the price of token[0] in token[1]
   * */
  function getPriceRatioOfTokens(
    address[2] memory tokens,
    uint24[2] memory fees,
    uint32 period
  ) internal view returns (uint256) {
    return
      getPriceOfTokenInWETH(tokens[0], fees[0], period).mul(RATIO_DIVIDER) /
      getPriceOfTokenInWETH(tokens[1], fees[1], period);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.0;

import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

/// @title Oracle library
/// @notice Provides functions to integrate with V3 pool oracle
library OracleLibrary {
    /// @notice Calculates time-weighted means of tick and liquidity for a given Uniswap V3 pool
    /// @param pool Address of the pool that we want to observe
    /// @param secondsAgo Number of seconds in the past from which to calculate the time-weighted means
    /// @return arithmeticMeanTick The arithmetic mean tick from (block.timestamp - secondsAgo) to block.timestamp
    /// @return harmonicMeanLiquidity The harmonic mean liquidity from (block.timestamp - secondsAgo) to block.timestamp
    function consult(address pool, uint32 secondsAgo)
        internal
        view
        returns (int24 arithmeticMeanTick, uint128 harmonicMeanLiquidity)
    {
        require(secondsAgo != 0, 'BP');

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s) =
            IUniswapV3Pool(pool).observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        uint160 secondsPerLiquidityCumulativesDelta =
            secondsPerLiquidityCumulativeX128s[1] - secondsPerLiquidityCumulativeX128s[0];

        arithmeticMeanTick = int24(tickCumulativesDelta / secondsAgo);
        // Always round to negative infinity
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % secondsAgo != 0)) arithmeticMeanTick--;

        // We are multiplying here instead of shifting to ensure that harmonicMeanLiquidity doesn't overflow uint128
        uint192 secondsAgoX160 = uint192(secondsAgo) * type(uint160).max;
        harmonicMeanLiquidity = uint128(secondsAgoX160 / (uint192(secondsPerLiquidityCumulativesDelta) << 32));
    }

    /// @notice Given a tick and a token amount, calculates the amount of token received in exchange
    /// @param tick Tick value used to calculate the quote
    /// @param baseAmount Amount of token to be converted
    /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
    /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
    /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
    function getQuoteAtTick(
        int24 tick,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) internal pure returns (uint256 quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }

    /// @notice Given a pool, it returns the number of seconds ago of the oldest stored observation
    /// @param pool Address of Uniswap V3 pool that we want to observe
    /// @return secondsAgo The number of seconds ago of the oldest observation stored for the pool
    function getOldestObservationSecondsAgo(address pool) internal view returns (uint32 secondsAgo) {
        (, , uint16 observationIndex, uint16 observationCardinality, , , ) = IUniswapV3Pool(pool).slot0();
        require(observationCardinality > 0, 'NI');

        (uint32 observationTimestamp, , , bool initialized) =
            IUniswapV3Pool(pool).observations((observationIndex + 1) % observationCardinality);

        // The next index might not be initialized if the cardinality is in the process of increasing
        // In this case the oldest observation is always in index 0
        if (!initialized) {
            (observationTimestamp, , , ) = IUniswapV3Pool(pool).observations(0);
        }

        secondsAgo = uint32(block.timestamp) - observationTimestamp;
    }

    /// @notice Given a pool, it returns the tick value as of the start of the current block
    /// @param pool Address of Uniswap V3 pool
    /// @return The tick that the pool was in at the start of the current block
    function getBlockStartingTickAndLiquidity(address pool) internal view returns (int24, uint128) {
        (, int24 tick, uint16 observationIndex, uint16 observationCardinality, , , ) = IUniswapV3Pool(pool).slot0();

        // 2 observations are needed to reliably calculate the block starting tick
        require(observationCardinality > 1, 'NEO');

        // If the latest observation occurred in the past, then no tick-changing trades have happened in this block
        // therefore the tick in `slot0` is the same as at the beginning of the current block.
        // We don't need to check if this observation is initialized - it is guaranteed to be.
        (uint32 observationTimestamp, int56 tickCumulative, uint160 secondsPerLiquidityCumulativeX128, ) =
            IUniswapV3Pool(pool).observations(observationIndex);
        if (observationTimestamp != uint32(block.timestamp)) {
            return (tick, IUniswapV3Pool(pool).liquidity());
        }

        uint256 prevIndex = (uint256(observationIndex) + observationCardinality - 1) % observationCardinality;
        (
            uint32 prevObservationTimestamp,
            int56 prevTickCumulative,
            uint160 prevSecondsPerLiquidityCumulativeX128,
            bool prevInitialized
        ) = IUniswapV3Pool(pool).observations(prevIndex);

        require(prevInitialized, 'ONI');

        uint32 delta = observationTimestamp - prevObservationTimestamp;
        tick = int24((tickCumulative - prevTickCumulative) / delta);
        uint128 liquidity =
            uint128(
                (uint192(delta) * type(uint160).max) /
                    (uint192(secondsPerLiquidityCumulativeX128 - prevSecondsPerLiquidityCumulativeX128) << 32)
            );
        return (tick, liquidity);
    }

    /// @notice Information for calculating a weighted arithmetic mean tick
    struct WeightedTickData {
        int24 tick;
        uint128 weight;
    }

    /// @notice Given an array of ticks and weights, calculates the weighted arithmetic mean tick
    /// @param weightedTickData An array of ticks and weights
    /// @return weightedArithmeticMeanTick The weighted arithmetic mean tick
    /// @dev Each entry of `weightedTickData` should represents ticks from pools with the same underlying pool tokens. If they do not,
    /// extreme care must be taken to ensure that ticks are comparable (including decimal differences).
    /// @dev Note that the weighted arithmetic mean tick corresponds to the weighted geometric mean price.
    function getWeightedArithmeticMeanTick(WeightedTickData[] memory weightedTickData)
        internal
        pure
        returns (int24 weightedArithmeticMeanTick)
    {
        // Accumulates the sum of products between each tick and its weight
        int256 numerator;

        // Accumulates the sum of the weights
        uint256 denominator;

        // Products fit in 152 bits, so it would take an array of length ~2**104 to overflow this logic
        for (uint256 i; i < weightedTickData.length; i++) {
            numerator += weightedTickData[i].tick * int256(weightedTickData[i].weight);
            denominator += weightedTickData[i].weight;
        }

        weightedArithmeticMeanTick = int24(numerator / int256(denominator));
        // Always round to negative infinity
        if (numerator < 0 && (numerator % int256(denominator) != 0)) weightedArithmeticMeanTick--;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../../connectors/TornPowerIndexConnector.sol";

contract MockTornPowerIndexConnector is TornPowerIndexConnector {
  constructor(
    address _staking,
    address _underlying,
    address _piToken,
    address _governance
  ) public TornPowerIndexConnector(_staking, _underlying, _piToken, _governance) {}

  function getTornPriceRatio() public view override returns (uint256) {
    return 15000000000000000;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/Initializable.sol";
import "../../interfaces/torn/ITornGovernance.sol";

/**
 * @notice This is the staking contract of the governance staking upgrade.
 *         This contract should hold the staked funds which are received upon relayer registration,
 *         and properly attribute rewards to addresses without security issues.
 * @dev CONTRACT RISKS:
 *      - Relayer staked TORN at risk if contract is compromised.
 * */
contract TornStaking {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /// @notice 1e25
  uint256 public immutable ratioConstant;
  ITornGovernance public immutable Governance;
  IERC20 public immutable torn;

  /// @notice the sum torn_burned_i/locked_amount_i*coefficient where i is incremented at each burn
  uint256 public accumulatedRewardPerTorn;
  /// @notice notes down accumulatedRewardPerTorn for an address on a lock/unlock/claim
  mapping(address => uint256) public accumulatedRewardRateOnLastUpdate;
  /// @notice notes down how much an account may claim
  mapping(address => uint256) public accumulatedRewards;

  event RewardsUpdated(address indexed account, uint256 rewards);
  event RewardsClaimed(address indexed account, uint256 rewardsClaimed);

  modifier onlyGovernance() {
    require(msg.sender == address(Governance), "only governance");
    _;
  }

  constructor(address governanceAddress, address tornAddress) public {
    Governance = ITornGovernance(governanceAddress);
    torn = IERC20(tornAddress);
    ratioConstant = IERC20(tornAddress).totalSupply();
  }

  /**
   * @notice This function should safely send a user his rewards.
   * @dev IMPORTANT FUNCTION:
   *      We know that rewards are going to be updated every time someone locks or unlocks
   *      so we know that this function can't be used to falsely increase the amount of
   *      lockedTorn by locking in governance and subsequently calling it.
   *      - set rewards to 0 greedily
   */
  function getReward() external {
    uint256 rewards = _updateReward(msg.sender, Governance.lockedBalance(msg.sender));
    rewards = rewards.add(accumulatedRewards[msg.sender]);
    accumulatedRewards[msg.sender] = 0;
    torn.safeTransfer(msg.sender, rewards);
    emit RewardsClaimed(msg.sender, rewards);
  }

  /**
   * @notice This function should increment the proper amount of rewards per torn for the contract
   * @dev IMPORTANT FUNCTION:
   *      - calculation must not overflow with extreme values
   *        (amount <= 1e25) * 1e25 / (balance of vault <= 1e25) -> (extreme values)
   * @param amount amount to add to the rewards
   */
  function addBurnRewards(uint256 amount) external {
    accumulatedRewardPerTorn = accumulatedRewardPerTorn.add(
      amount.mul(ratioConstant).div(torn.balanceOf(address(this)))
    );
  }

  /**
   * @notice This function should allow governance to properly update the accumulated rewards rate for an account
   * @param account address of account to update data for
   * @param amountLockedBeforehand the balance locked beforehand in the governance contract
   * */
  function updateRewardsOnLockedBalanceChange(address account, uint256 amountLockedBeforehand) external onlyGovernance {
    uint256 claimed = _updateReward(account, amountLockedBeforehand);
    accumulatedRewards[account] = accumulatedRewards[account].add(claimed);
  }

  /**
   * @notice This function should allow governance rescue tokens from the staking rewards contract
   * */
  function withdrawTorn(uint256 amount) external onlyGovernance {
    if (amount == type(uint256).max) amount = torn.balanceOf(address(this));
    torn.safeTransfer(address(Governance), amount);
  }

  /**
   * @notice This function should calculated the proper amount of rewards attributed to user since the last update
   * @dev IMPORTANT FUNCTION:
   *      - calculation must not overflow with extreme values
   *        (accumulatedReward <= 1e25) * (lockedBeforehand <= 1e25) / 1e25
   *      - result may go to 0, since this implies on 1 TORN locked => accumulatedReward <= 1e7, meaning a very small reward
   * @param account address of account to calculate rewards for
   * @param amountLockedBeforehand the balance locked beforehand in the governance contract
   * @return claimed the rewards attributed to user since the last update
   */
  function _updateReward(address account, uint256 amountLockedBeforehand) private returns (uint256 claimed) {
    if (amountLockedBeforehand != 0)
      claimed = (accumulatedRewardPerTorn.sub(accumulatedRewardRateOnLastUpdate[account]))
        .mul(amountLockedBeforehand)
        .div(ratioConstant);
    accumulatedRewardRateOnLastUpdate[account] = accumulatedRewardPerTorn;
    emit RewardsUpdated(account, claimed);
  }

  /**
   * @notice This function should show a user his rewards.
   * @param account address of account to calculate rewards for
   */
  function checkReward(address account) external view returns (uint256 rewards) {
    uint256 amountLocked = Governance.lockedBalance(account);
    if (amountLocked != 0)
      rewards = (accumulatedRewardPerTorn.sub(accumulatedRewardRateOnLastUpdate[account])).mul(amountLocked).div(
        ratioConstant
      );
    rewards = rewards.add(accumulatedRewards[account]);
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/PowerIndexNaiveRouterInterface.sol";
import "./interfaces/PowerIndexRouterInterface.sol";
import "./interfaces/WrappedPiErc20Interface.sol";
import "./interfaces/IERC20Permit.sol";

contract WrappedPiErc20 is ERC20, ReentrancyGuard, WrappedPiErc20Interface {
  using SafeMath for uint256;
  using SafeERC20 for IERC20Permit;

  bytes32 public constant PERMIT_TYPEHASH =
    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes public constant EIP712_REVISION = bytes("1");
  bytes32 internal constant EIP712_DOMAIN =
    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

  IERC20Permit public immutable underlying;
  bytes32 public immutable override DOMAIN_SEPARATOR;
  address public router;
  bool public routerCallbackEnabled;
  uint256 public ethFee;
  mapping(address => bool) public noFeeWhitelist;
  mapping(address => uint256) public override nonces;

  event Deposit(address indexed account, uint256 undelyingDeposited, uint256 piMinted);
  event Withdraw(address indexed account, uint256 underlyingWithdrawn, uint256 piBurned);
  event Approve(address indexed to, uint256 amount);
  event ChangeRouter(address indexed newRouter);
  event EnableRouterCallback(bool indexed enabled);
  event SetEthFee(uint256 newEthFee);
  event SetNoFee(address indexed addr, bool noFee);
  event WithdrawEthFee(uint256 value);
  event CallExternal(address indexed destination, bytes4 indexed inputSig, bytes inputData, bytes outputData);

  modifier onlyRouter() {
    require(router == msg.sender, "ONLY_ROUTER");
    _;
  }

  constructor(
    address _token,
    address _router,
    string memory _name,
    string memory _symbol
  ) public ERC20(_name, _symbol) {
    underlying = IERC20Permit(_token);
    router = _router;

    uint256 chainId;

    assembly {
      chainId := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(EIP712_DOMAIN, keccak256(bytes(_name)), keccak256(EIP712_REVISION), chainId, address(this))
    );
  }

  /**
   * @notice Deposits underlying ERC20 token to the piToken(piERC20) with permit params
   * @param _amount The amount to deposit in underlying ERC20 tokens.
   * @param _deadline Deadline timestamp of permit
   * @param _v param of permit
   * @param _r param of permit
   * @param _s param of permit
   */
  function depositWithPermit(
    uint256 _amount,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) public virtual {
    underlying.permit(msg.sender, address(this), _amount, _deadline, _v, _r, _s);
    deposit(_amount);
  }

  /**
   * @notice Deposits underlying ERC20 token to the piToken(piERC20).
   * @param _depositAmount The amount to deposit in underlying ERC20 tokens.
   */
  function deposit(uint256 _depositAmount) public payable override nonReentrant returns (uint256) {
    if (noFeeWhitelist[msg.sender]) {
      require(msg.value == 0, "NO_FEE_FOR_WL");
    } else {
      require(msg.value >= ethFee, "FEE");
    }

    require(_depositAmount > 0, "ZERO_DEPOSIT");

    uint256 mintAmount = getPiEquivalentForUnderlying(_depositAmount);
    require(mintAmount > 0, "ZERO_PI_FOR_MINT");

    underlying.safeTransferFrom(msg.sender, address(this), _depositAmount);
    _mint(msg.sender, mintAmount);

    emit Deposit(msg.sender, _depositAmount, mintAmount);

    if (routerCallbackEnabled) {
      PowerIndexNaiveRouterInterface(router).piTokenCallback{ value: msg.value }(msg.sender, 0);
    }

    return mintAmount;
  }

  /**
   * @notice Withdraws underlying ERC20 token from the piToken (piERC20).
   * @param _withdrawAmount The amount to withdraw in underlying ERC20 tokens.
   * @return The amount of the burned shares.
   */
  function withdraw(uint256 _withdrawAmount) external payable override nonReentrant returns (uint256) {
    if (noFeeWhitelist[msg.sender]) {
      require(msg.value == 0, "NO_FEE_FOR_WL");
    } else {
      require(msg.value >= ethFee, "FEE");
    }

    require(_withdrawAmount > 0, "ZERO_WITHDRAWAL");

    if (routerCallbackEnabled) {
      PowerIndexNaiveRouterInterface(router).piTokenCallback{ value: msg.value }(msg.sender, _withdrawAmount);
    }

    uint256 burnAmount = getPiEquivalentForUnderlying(_withdrawAmount);
    require(burnAmount > 0, "ZERO_PI_FOR_BURN");

    _burn(msg.sender, burnAmount);
    underlying.safeTransfer(msg.sender, _withdrawAmount);

    emit Withdraw(msg.sender, _withdrawAmount, burnAmount);

    return burnAmount;
  }

  /**
   * @notice Withdraws underlying ERC20 token from the piToken(piERC20).
   * @param _burnAmount The amount of shares to burn.
   * @return The amount of the withdrawn underlying ERC20 token.
   */
  function withdrawShares(uint256 _burnAmount) external payable override nonReentrant returns (uint256) {
    if (noFeeWhitelist[msg.sender]) {
      require(msg.value == 0, "NO_FEE_FOR_WL");
    } else {
      require(msg.value >= ethFee, "FEE");
    }

    require(_burnAmount > 0, "ZERO_WITHDRAWAL");

    uint256 withdrawAmount = getUnderlyingEquivalentForPi(_burnAmount);
    require(withdrawAmount > 0, "ZERO_UNDERLYING_TO_WITHDRAW");

    if (routerCallbackEnabled) {
      PowerIndexNaiveRouterInterface(router).piTokenCallback{ value: msg.value }(msg.sender, withdrawAmount);
    }

    _burn(msg.sender, _burnAmount);
    underlying.safeTransfer(msg.sender, withdrawAmount);

    emit Withdraw(msg.sender, withdrawAmount, _burnAmount);

    return withdrawAmount;
  }

  function getPiEquivalentForUnderlying(uint256 _underlyingAmount) public view override returns (uint256) {
    return PowerIndexRouterInterface(router).getPiEquivalentForUnderlying(_underlyingAmount, totalSupply());
  }

  function getUnderlyingEquivalentForPi(uint256 _piAmount) public view override returns (uint256) {
    return PowerIndexRouterInterface(router).getUnderlyingEquivalentForPi(_piAmount, totalSupply());
  }

  function balanceOfUnderlying(address account) external view override returns (uint256) {
    return getUnderlyingEquivalentForPi(balanceOf(account));
  }

  function totalSupplyUnderlying() external view returns (uint256) {
    return getUnderlyingEquivalentForPi(totalSupply());
  }

  function changeRouter(address _newRouter) external override onlyRouter {
    router = _newRouter;
    emit ChangeRouter(router);
  }

  function enableRouterCallback(bool _enable) external override onlyRouter {
    routerCallbackEnabled = _enable;
    emit EnableRouterCallback(_enable);
  }

  function setNoFee(address _for, bool _noFee) external override onlyRouter {
    noFeeWhitelist[_for] = _noFee;
    emit SetNoFee(_for, _noFee);
  }

  function setEthFee(uint256 _ethFee) external override onlyRouter {
    ethFee = _ethFee;
    emit SetEthFee(_ethFee);
  }

  function withdrawEthFee(address payable _receiver) external override onlyRouter {
    emit WithdrawEthFee(address(this).balance);
    _receiver.transfer(address(this).balance);
  }

  function approveUnderlying(address _to, uint256 _amount) external override onlyRouter {
    underlying.approve(_to, _amount);
    emit Approve(_to, _amount);
  }

  function callExternal(
    address _destination,
    bytes4 _signature,
    bytes calldata _args,
    uint256 _value
  ) external payable override onlyRouter returns (bytes memory) {
    return _callExternal(_destination, _signature, _args, _value);
  }

  function callExternalMultiple(ExternalCallData[] calldata _calls)
    external
    payable
    override
    onlyRouter
    returns (bytes[] memory results)
  {
    uint256 len = _calls.length;
    results = new bytes[](len);
    for (uint256 i = 0; i < len; i++) {
      results[i] = _callExternal(_calls[i].destination, _calls[i].signature, _calls[i].args, _calls[i].value);
    }
  }

  function getUnderlyingBalance() external view override returns (uint256) {
    return underlying.balanceOf(address(this));
  }

  /**
   * @dev implements the permit function as for
   *      https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param owner the owner of the funds
   * @param spender the spender
   * @param value the amount
   * @param deadline the deadline timestamp, type(uint256).max for no deadline
   * @param v signature param
   * @param s signature param
   * @param r signature param
   */
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override {
    require(owner != address(0), "INVALID_OWNER");
    require(block.timestamp <= deadline, "INVALID_EXPIRATION");
    uint256 currentValidNonce = nonces[owner];
    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, currentValidNonce, deadline))
      )
    );

    require(owner == ecrecover(digest, v, r, s), "INVALID_SIGNATURE");
    nonces[owner] = currentValidNonce.add(1);
    _approve(owner, spender, value);
  }

  function _callExternal(
    address _destination,
    bytes4 _signature,
    bytes calldata _args,
    uint256 _value
  ) internal returns (bytes memory) {
    (bool success, bytes memory data) = _destination.call{ value: _value }(abi.encodePacked(_signature, _args));

    if (!success) {
      assembly {
        let output := mload(0x40)
        let size := returndatasize()
        switch size
        case 0 {
          // If there is no revert reason string, revert with the default `REVERTED_WITH_NO_REASON_STRING`
          mstore(output, 0x08c379a000000000000000000000000000000000000000000000000000000000) // error identifier
          mstore(add(output, 0x04), 0x0000000000000000000000000000000000000000000000000000000000000020) // offset
          mstore(add(output, 0x24), 0x000000000000000000000000000000000000000000000000000000000000001e) // length
          mstore(add(output, 0x44), 0x52455645525445445f574954485f4e4f5f524541534f4e5f535452494e470000) // reason
          revert(output, 100) // 100 = 4 + 3 * 32 (error identifier + 3 words for the ABI encoded error)
        }
        default {
          // If there is a revert reason string hijacked, revert with it
          revert(add(data, 32), size)
        }
      }
    }

    emit CallExternal(_destination, _signature, _args, data);

    return data;
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface PowerIndexNaiveRouterInterface {
  function migrateToNewRouter(
    address _piToken,
    address payable _newRouter,
    address[] memory _tokens
  ) external;

  function enableRouterCallback(address _piToken, bool _enable) external;

  function piTokenCallback(address sender, uint256 _withdrawAmount) external payable;
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

pragma solidity 0.6.12;

import "./WrappedPiErc20.sol";
import "./interfaces/WrappedPiErc20FactoryInterface.sol";

contract WrappedPiErc20Factory is WrappedPiErc20FactoryInterface {
  constructor() public {}

  function build(
    address _underlyingToken,
    address _router,
    string calldata _name,
    string calldata _symbol
  ) external override returns (WrappedPiErc20Interface) {
    WrappedPiErc20 piToken = new WrappedPiErc20(_underlyingToken, _router, _name, _symbol);

    emit NewWrappedPiErc20(_underlyingToken, address(piToken), msg.sender);

    return piToken;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./WrappedPiErc20Interface.sol";

interface WrappedPiErc20FactoryInterface {
  event NewWrappedPiErc20(address indexed token, address indexed wrappedToken, address indexed creator);

  function build(
    address _token,
    address _router,
    string calldata _name,
    string calldata _symbol
  ) external returns (WrappedPiErc20Interface);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/WrappedPiErc20Interface.sol";

contract MockPermitUser {
  address private token;

  constructor(address _token) public {
    token = _token;
  }

  function acceptTokens(
    address _from,
    uint256 _amount,
    uint256 _deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    WrappedPiErc20Interface(token).permit(_from, address(this), _amount, _deadline, v, r, s);
    IERC20(token).transferFrom(_from, address(this), _amount);
  }
}

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../interfaces/torn/ITornStaking.sol";

contract TornGovernance {
  using SafeMath for uint256;

  event RewardUpdateSuccessful(address indexed account);
  event RewardUpdateFailed(address indexed account, bytes indexed errorData);

  /// @notice Locked token balance for each account
  mapping(address => uint256) public lockedBalance;

  IERC20 public torn;
  ITornStaking public Staking;

  modifier updateRewards(address account) {
    try Staking.updateRewardsOnLockedBalanceChange(account, lockedBalance[account]) {
      emit RewardUpdateSuccessful(account);
    } catch (bytes memory errorData) {
      emit RewardUpdateFailed(account, errorData);
    }
    _;
  }

  constructor(address _torn) public {
    torn = IERC20(_torn);
  }

  function setStaking(address staking) public virtual {
    Staking = ITornStaking(staking);
  }

  function lockWithApproval(uint256 amount) public virtual updateRewards(msg.sender) {
    require(torn.transferFrom(msg.sender, address(this), amount), "TORN: transferFrom failed");
    lockedBalance[msg.sender] = lockedBalance[msg.sender].add(amount);
  }

  function unlock(uint256 amount) public virtual updateRewards(msg.sender) {
    //    require(getBlockTimestamp() > canWithdrawAfter[msg.sender], "Governance: tokens are locked");
    lockedBalance[msg.sender] = lockedBalance[msg.sender].sub(amount, "Governance: insufficient balance");
    require(torn.transfer(msg.sender, amount), "TORN: transfer failed");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockGeneralMasterChef {
  address token;

  constructor(address _token) public {
    token = _token;
  }

  function deposit(uint256, uint256 _amount) external {
    IERC20(token).transferFrom(msg.sender, address(42), _amount);
  }

  function withdraw(uint256, uint256) external {}

  function userInfo(uint256, address) external pure returns (uint256 amount, uint256 rewardDebt) {
    return (0, 0);
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

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MyContract is Ownable {
  uint256 internal theAnswer;
  uint256 internal theAnswer2;

  constructor() public Ownable() {}

  function setAnswer(uint256 _theAnswer) external onlyOwner returns (uint256) {
    theAnswer = _theAnswer;
    return 123;
  }

  function setAnswer2(uint256 _theAnswer2) external onlyOwner returns (uint256) {
    theAnswer2 = _theAnswer2;
    return 123;
  }

  function getAnswer() external view returns (uint256) {
    return theAnswer;
  }

  function getAnswer2() external view returns (uint256) {
    return theAnswer2;
  }

  function invalidOp() external pure {
    assert(false);
  }

  function revertWithoutString() external pure {
    revert();
  }

  function revertWithString() external pure {
    revert("some-unique-revert-string");
  }

  function revertWithLongString() external pure {
    revert("some-unique-revert-string-that-is-a-bit-longer-than-a-single-evm-slot");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IPoolRestrictions.sol";

contract MockPoolRestrictions is IPoolRestrictions, Ownable {
  /* ==========  EVENTS  ========== */

  /** @dev Emitted on changing total restrictions for token. */
  event SetTotalRestrictions(address indexed token, uint256 maxTotalSupply);

  /** @dev Emitted on changing signature restriction. */
  event SetSignatureAllowed(bytes4 indexed signature, bool allowed);

  /** @dev Emitted on changing signature restriction for specific voting contract. */
  event SetSignatureAllowedForAddress(
    address indexed voting,
    bytes4 indexed signature,
    bool allowed,
    bool overrideAllowed
  );

  /** @dev Emitted on adding or removing sender for voting execution. */
  event SetVotingSenderAllowed(address indexed voting, address indexed sender, bool allowed);

  /** @dev Emitted on adding or removing contracts without fees. */
  event SetWithoutFee(address indexed addr, bool withoutFee);

  /* ==========  Storage  ========== */

  struct TotalRestrictions {
    uint256 maxTotalSupply;
  }
  /** @dev Public records of restrictions by pool's addresses. */
  mapping(address => TotalRestrictions) public totalRestrictions;

  /** @dev Public records of general signature's restrictions. */
  mapping(bytes4 => bool) public signaturesAllowed;

  struct VotingSignature {
    bool allowed;
    bool overrideAllowed;
  }
  /** @dev Public records of signature's restrictions by specific votings. */
  mapping(address => mapping(bytes4 => VotingSignature)) public votingSignatures;

  /** @dev Public records of senders allowed by voting's addresses */
  mapping(address => mapping(address => bool)) public votingSenderAllowed;

  /** @dev Public records of operators, who doesn't pay community fee */
  mapping(address => bool) public withoutFeeAddresses;

  constructor() public Ownable() {}

  /* ==========  Configuration Actions  ========== */

  /**
   * @dev Set total restrictions for pools list.
   * @param _poolsList List of pool's addresses.
   * @param _maxTotalSupplyList List of total supply limits for each pool address.
   */
  function setTotalRestrictions(address[] calldata _poolsList, uint256[] calldata _maxTotalSupplyList)
    external
    onlyOwner
  {
    _setTotalRestrictions(_poolsList, _maxTotalSupplyList);
  }

  /**
   * @dev Set voting signatures allowing status.
   * @param _signatures List of signatures.
   * @param _allowed List of booleans (allowed or not) for each signature.
   */
  function setVotingSignatures(bytes4[] calldata _signatures, bool[] calldata _allowed) external onlyOwner {
    _setVotingSignatures(_signatures, _allowed);
  }

  /**
   * @dev Set signatures allowing status for specific voting addresses.
   * @param _votingAddress Specific voting address.
   * @param _override Override signature status by specific voting address or not.
   * @param _signatures List of signatures.
   * @param _allowed List of booleans (allowed or not) for each signature.
   */
  function setVotingSignaturesForAddress(
    address _votingAddress,
    bool _override,
    bytes4[] calldata _signatures,
    bool[] calldata _allowed
  ) external onlyOwner {
    _setVotingSignaturesForAddress(_votingAddress, _override, _signatures, _allowed);
  }

  /**
   * @dev Set senders allowing status for voting addresses.
   * @param _votingAddress Specific voting address.
   * @param _senders List of senders.
   * @param _allowed List of booleans (allowed or not) for each sender.
   */
  function setVotingAllowedForSenders(
    address _votingAddress,
    address[] calldata _senders,
    bool[] calldata _allowed
  ) external onlyOwner {
    uint256 len = _senders.length;
    _validateArrayLength(len);
    require(len == _allowed.length, "Arrays lengths are not equals");
    for (uint256 i = 0; i < len; i++) {
      votingSenderAllowed[_votingAddress][_senders[i]] = _allowed[i];
      emit SetVotingSenderAllowed(_votingAddress, _senders[i], _allowed[i]);
    }
  }

  /**
   * @dev Set contracts, which doesn't pay community fee.
   * @param _addresses List of operators.
   * @param _withoutFee Boolean for whole list of operators.
   */
  function setWithoutFee(address[] calldata _addresses, bool _withoutFee) external onlyOwner {
    uint256 len = _addresses.length;
    _validateArrayLength(len);
    for (uint256 i = 0; i < len; i++) {
      withoutFeeAddresses[_addresses[i]] = _withoutFee;
      emit SetWithoutFee(_addresses[i], _withoutFee);
    }
  }

  /* ==========  Config Queries  ========== */

  function getMaxTotalSupply(address _poolAddress) external view override returns (uint256) {
    return totalRestrictions[_poolAddress].maxTotalSupply;
  }

  function isVotingSignatureAllowed(address _votingAddress, bytes4 _signature) external view override returns (bool) {
    if (votingSignatures[_votingAddress][_signature].overrideAllowed) {
      return votingSignatures[_votingAddress][_signature].allowed;
    } else {
      return signaturesAllowed[_signature];
    }
  }

  function isVotingSenderAllowed(address _votingAddress, address _sender) external view override returns (bool) {
    return votingSenderAllowed[_votingAddress][_sender];
  }

  function isWithoutFee(address _address) external view override returns (bool) {
    return withoutFeeAddresses[_address];
  }

  /*** Internal Functions ***/

  function _setTotalRestrictions(address[] memory _poolsList, uint256[] memory _maxTotalSupplyList) internal {
    uint256 len = _poolsList.length;
    _validateArrayLength(len);
    require(len == _maxTotalSupplyList.length, "Arrays lengths are not equals");

    for (uint256 i = 0; i < len; i++) {
      totalRestrictions[_poolsList[i]] = TotalRestrictions(_maxTotalSupplyList[i]);
      emit SetTotalRestrictions(_poolsList[i], _maxTotalSupplyList[i]);
    }
  }

  function _setVotingSignatures(bytes4[] memory _signatures, bool[] memory _allowed) internal {
    uint256 len = _signatures.length;
    _validateArrayLength(len);
    require(len == _allowed.length, "Arrays lengths are not equals");

    for (uint256 i = 0; i < len; i++) {
      signaturesAllowed[_signatures[i]] = _allowed[i];
      emit SetSignatureAllowed(_signatures[i], _allowed[i]);
    }
  }

  function _setVotingSignaturesForAddress(
    address _votingAddress,
    bool _override,
    bytes4[] memory _signatures,
    bool[] memory _allowed
  ) internal {
    uint256 len = _signatures.length;
    _validateArrayLength(len);
    require(len == _allowed.length, "Arrays lengths are not equals");

    for (uint256 i = 0; i < len; i++) {
      votingSignatures[_votingAddress][_signatures[i]] = VotingSignature(_allowed[i], _override);
      emit SetSignatureAllowedForAddress(_votingAddress, _signatures[i], _allowed[i], _override);
    }
  }

  function _validateArrayLength(uint256 _len) internal pure {
    require(_len <= 100, "Array length should be less or equal 100");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IPoolRestrictions {
  function getMaxTotalSupply(address _pool) external view returns (uint256);

  function isVotingSignatureAllowed(address _votingAddress, bytes4 _signature) external view returns (bool);

  function isVotingSenderAllowed(address _votingAddress, address _sender) external view returns (bool);

  function isWithoutFee(address _addr) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@powerpool/power-oracle/contracts/interfaces/IPowerPoke.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/WrappedPiErc20Interface.sol";
import "./interfaces/IPoolRestrictions.sol";
import "./interfaces/PowerIndexRouterInterface.sol";
import "./interfaces/IRouterConnector.sol";
import "./PowerIndexNaiveRouter.sol";

/**
 * @notice PowerIndexRouter executes connectors with delegatecall to stake and redeem ERC20 tokens in
 * protocol-specified staking contracts. After calling, it saves stakeData and pokeData as connectors storage.
 * Available ERC20 token balance from piERC20 is distributed between connectors by its shares and calculated
 * as the difference between total balance and share of necessary balance(reserveRatio) for keeping in piERC20
 * for withdrawals.
 */
contract PowerIndexRouter is PowerIndexRouterInterface, PowerIndexNaiveRouter {
  using SafeERC20 for IERC20;

  uint256 internal constant COMPENSATION_PLAN_1_ID = 1;
  uint256 public constant HUNDRED_PCT = 1 ether;

  event SetReserveConfig(uint256 ratio, uint256 ratioLowerBound, uint256 ratioUpperBound, uint256 claimRewardsInterval);
  event SetPerformanceFee(uint256 performanceFee);
  event SetConnector(
    IRouterConnector indexed connector,
    uint256 share,
    bool callBeforeAfterPoke,
    uint256 indexed connectorIndex,
    bool indexed isNewConnector
  );
  event SetConnectorClaimParams(address connector, bytes claimParams);
  event SetConnectorStakeParams(address connector, bytes stakeParams);

  struct BasicConfig {
    address poolRestrictions;
    address powerPoke;
    uint256 reserveRatio;
    uint256 reserveRatioLowerBound;
    uint256 reserveRatioUpperBound;
    uint256 claimRewardsInterval;
    address performanceFeeReceiver;
    uint256 performanceFee;
  }

  WrappedPiErc20Interface public immutable piToken;
  IERC20 public immutable underlying;
  address public immutable performanceFeeReceiver;

  IPoolRestrictions public poolRestrictions;
  IPowerPoke public powerPoke;
  uint256 public reserveRatio;
  uint256 public claimRewardsInterval;
  uint256 public lastRebalancedByPokerAt;
  uint256 public reserveRatioLowerBound;
  uint256 public reserveRatioUpperBound;
  // 1 ether == 100%
  uint256 public performanceFee;
  Connector[] public connectors;

  struct RebalanceConfig {
    bool shouldPushFunds;
    StakeStatus status;
    uint256 diff;
    bool shouldClaim;
    bool forceRebalance;
    uint256 connectorIndex;
  }

  struct Connector {
    IRouterConnector connector;
    uint256 share;
    bool callBeforeAfterPoke;
    uint256 lastClaimRewardsAt;
    uint256 lastChangeStakeAt;
    bytes stakeData;
    bytes pokeData;
    bytes stakeParams;
    bytes claimParams;
  }

  struct ConnectorInput {
    bool newConnector;
    uint256 connectorIndex;
    IRouterConnector connector;
    uint256 share;
    bool callBeforeAfterPoke;
  }

  struct PokeFromState {
    uint256 minInterval;
    uint256 maxInterval;
    uint256 piTokenUnderlyingBalance;
    uint256 addToExpectedAmount;
    bool atLeastOneForceRebalance;
    bool skipCanPokeCheck;
  }

  modifier onlyEOA() {
    require(tx.origin == msg.sender, "ONLY_EOA");
    _;
  }

  modifier onlyReporter(uint256 _reporterId, bytes calldata _rewardOpts) {
    uint256 gasStart = gasleft();
    powerPoke.authorizeReporter(_reporterId, msg.sender);
    _;
    _reward(_reporterId, gasStart, COMPENSATION_PLAN_1_ID, _rewardOpts);
  }

  modifier onlyNonReporter(uint256 _reporterId, bytes calldata _rewardOpts) {
    uint256 gasStart = gasleft();
    powerPoke.authorizeNonReporter(_reporterId, msg.sender);
    _;
    _reward(_reporterId, gasStart, COMPENSATION_PLAN_1_ID, _rewardOpts);
  }

  constructor(address _piToken, BasicConfig memory _basicConfig) public PowerIndexNaiveRouter() Ownable() {
    require(_piToken != address(0), "INVALID_PI_TOKEN");
    require(_basicConfig.reserveRatioUpperBound <= HUNDRED_PCT, "UPPER_RR_GREATER_THAN_100_PCT");
    require(_basicConfig.reserveRatio >= _basicConfig.reserveRatioLowerBound, "RR_LTE_LOWER_RR");
    require(_basicConfig.reserveRatio <= _basicConfig.reserveRatioUpperBound, "RR_GTE_UPPER_RR");
    require(_basicConfig.performanceFee < HUNDRED_PCT, "PVP_FEE_GTE_HUNDRED_PCT");
    require(_basicConfig.performanceFeeReceiver != address(0), "INVALID_PVP_ADDR");
    require(_basicConfig.poolRestrictions != address(0), "INVALID_POOL_RESTRICTIONS_ADDR");

    piToken = WrappedPiErc20Interface(_piToken);
    (, bytes memory underlyingRes) = _piToken.call(abi.encodeWithSignature("underlying()"));
    underlying = IERC20(abi.decode(underlyingRes, (address)));
    poolRestrictions = IPoolRestrictions(_basicConfig.poolRestrictions);
    powerPoke = IPowerPoke(_basicConfig.powerPoke);
    reserveRatio = _basicConfig.reserveRatio;
    reserveRatioLowerBound = _basicConfig.reserveRatioLowerBound;
    reserveRatioUpperBound = _basicConfig.reserveRatioUpperBound;
    claimRewardsInterval = _basicConfig.claimRewardsInterval;
    performanceFeeReceiver = _basicConfig.performanceFeeReceiver;
    performanceFee = _basicConfig.performanceFee;
  }

  receive() external payable {}

  /*** OWNER METHODS ***/

  /**
   * @notice Set reserve ratio config
   * @param _reserveRatio Share of necessary token balance that piERC20 must hold after poke execution.
   * @param _reserveRatioLowerBound Lower bound of ERC20 token balance to force rebalance.
   * @param _reserveRatioUpperBound Upper bound of ERC20 token balance to force rebalance.
   * @param _claimRewardsInterval Time interval to claim rewards in connectors contracts.
   */
  function setReserveConfig(
    uint256 _reserveRatio,
    uint256 _reserveRatioLowerBound,
    uint256 _reserveRatioUpperBound,
    uint256 _claimRewardsInterval
  ) external virtual override onlyOwner {
    require(_reserveRatioUpperBound <= HUNDRED_PCT, "UPPER_RR_GREATER_THAN_100_PCT");
    require(_reserveRatio >= _reserveRatioLowerBound, "RR_LT_LOWER_RR");
    require(_reserveRatio <= _reserveRatioUpperBound, "RR_GT_UPPER_RR");

    reserveRatio = _reserveRatio;
    reserveRatioLowerBound = _reserveRatioLowerBound;
    reserveRatioUpperBound = _reserveRatioUpperBound;
    claimRewardsInterval = _claimRewardsInterval;
    emit SetReserveConfig(_reserveRatio, _reserveRatioLowerBound, _reserveRatioUpperBound, _claimRewardsInterval);
  }

  /**
   * @notice Set performance fee.
   * @param _performanceFee Share of rewards for distributing to performanceFeeReceiver(Protocol treasury).
   */
  function setPerformanceFee(uint256 _performanceFee) external onlyOwner {
    require(_performanceFee < HUNDRED_PCT, "PERFORMANCE_FEE_OVER_THE_LIMIT");
    performanceFee = _performanceFee;
    emit SetPerformanceFee(_performanceFee);
  }

  /**
   * @notice Set piERC20 ETH fee for deposit and withdrawal functions.
   * @param _ethFee Fee amount in ETH.
   */
  function setPiTokenEthFee(uint256 _ethFee) external onlyOwner {
    require(_ethFee <= 0.1 ether, "ETH_FEE_OVER_THE_LIMIT");
    piToken.setEthFee(_ethFee);
  }

  /**
   * @notice Set connectors configs. Items should have `newConnector` variable to create connectors and `connectorIndex`
   * to update existing connectors.
   * @param _connectorList Array of connector items.
   */
  function setConnectorList(ConnectorInput[] memory _connectorList) external onlyOwner {
    require(_connectorList.length != 0, "CONNECTORS_LENGTH_CANT_BE_NULL");

    for (uint256 i = 0; i < _connectorList.length; i++) {
      ConnectorInput memory c = _connectorList[i];

      if (c.newConnector) {
        connectors.push(
          Connector(
            c.connector,
            c.share,
            c.callBeforeAfterPoke,
            0,
            0,
            new bytes(0),
            new bytes(0),
            new bytes(0),
            new bytes(0)
          )
        );
        c.connectorIndex = connectors.length - 1;
      } else {
        connectors[c.connectorIndex].connector = c.connector;
        connectors[c.connectorIndex].share = c.share;
        connectors[c.connectorIndex].callBeforeAfterPoke = c.callBeforeAfterPoke;
      }

      emit SetConnector(c.connector, c.share, c.callBeforeAfterPoke, c.connectorIndex, c.newConnector);
    }
    _checkConnectorsTotalShare();
  }

  /**
   * @notice Set connectors claim params to pass it to connector.
   * @param _connectorIndex Index of connector
   * @param _claimParams Claim params
   */
  function setClaimParams(uint256 _connectorIndex, bytes memory _claimParams) external onlyOwner {
    connectors[_connectorIndex].claimParams = _claimParams;
    emit SetConnectorClaimParams(address(connectors[_connectorIndex].connector), _claimParams);
  }

  /**
   * @notice Set connector stake params to pass it to connector.
   * @param _connectorIndex Index of connector
   * @param _stakeParams Claim params
   */
  function setStakeParams(uint256 _connectorIndex, bytes memory _stakeParams) external onlyOwner {
    connectors[_connectorIndex].stakeParams = _stakeParams;
    emit SetConnectorStakeParams(address(connectors[_connectorIndex].connector), _stakeParams);
  }

  /**
   * @notice Set piERC20 noFee config for account address.
   * @param _for Account address.
   * @param _noFee Value for account.
   */
  function setPiTokenNoFee(address _for, bool _noFee) external onlyOwner {
    piToken.setNoFee(_for, _noFee);
  }

  /**
   * @notice Call piERC20 `withdrawEthFee`.
   * @param _receiver Receiver address.
   */
  function withdrawEthFee(address payable _receiver) external onlyOwner {
    piToken.withdrawEthFee(_receiver);
  }

  /**
   * @notice Transfer ERC20 balances and rights to a new router address.
   * @param _piToken piERC20 address.
   * @param _newRouter New router contract address.
   * @param _tokens ERC20 to transfer.
   */
  function migrateToNewRouter(
    address _piToken,
    address payable _newRouter,
    address[] memory _tokens
  ) public override onlyOwner {
    super.migrateToNewRouter(_piToken, _newRouter, _tokens);

    _newRouter.transfer(address(this).balance);

    uint256 len = _tokens.length;
    for (uint256 i = 0; i < len; i++) {
      IERC20 t = IERC20(_tokens[i]);
      t.safeTransfer(_newRouter, t.balanceOf(address(this)));
    }
  }

  /**
   * @notice Call initRouter function of the connector contract.
   * @param _connectorIndex Connector index in connectors array.
   * @param _data To pass as an argument.
   */
  function initRouterByConnector(uint256 _connectorIndex, bytes memory _data) public onlyOwner {
    (bool success, bytes memory result) = address(connectors[_connectorIndex].connector).delegatecall(
      abi.encodeWithSignature("initRouter(bytes)", _data)
    );
    require(success, string(result));
  }

  function piTokenCallback(address, uint256 _withdrawAmount) external payable virtual override {
    PokeFromState memory state = PokeFromState(0, 0, 0, _withdrawAmount, false, true);
    _rebalance(state, false, false);
  }

  /**
   * @notice Call poke by Reporter.
   * @param _reporterId Reporter ID.
   * @param _claimAndDistributeRewards Claim rewards only if interval reached.
   * @param _rewardOpts To whom and how to reward Reporter.
   */
  function pokeFromReporter(
    uint256 _reporterId,
    bool _claimAndDistributeRewards,
    bytes calldata _rewardOpts
  ) external onlyReporter(_reporterId, _rewardOpts) onlyEOA {
    _pokeFrom(_claimAndDistributeRewards, false);
  }

  /**
   * @notice Call poke by Slasher.
   * @param _reporterId Slasher ID.
   * @param _claimAndDistributeRewards Claim rewards only if interval reached.
   * @param _rewardOpts To whom and how reward Slasher.
   */
  function pokeFromSlasher(
    uint256 _reporterId,
    bool _claimAndDistributeRewards,
    bytes calldata _rewardOpts
  ) external onlyNonReporter(_reporterId, _rewardOpts) onlyEOA {
    _pokeFrom(_claimAndDistributeRewards, true);
  }

  /**
   * @notice Executes rebalance(beforePoke, rebalancePoke, claimRewards, afterPoke) for connector contract by config.
   * @param _conf Connector rebalance config.
   */
  function _rebalancePokeByConf(RebalanceConfig memory _conf) internal {
    Connector storage c = connectors[_conf.connectorIndex];

    if (c.callBeforeAfterPoke) {
      _beforePoke(c, _conf.shouldClaim);
    }

    if (_conf.status != StakeStatus.EQUILIBRIUM) {
      _rebalancePoke(c, _conf.status, _conf.diff);
    }

    // check claim interval again due to possibility of claiming by stake or redeem function(maybe already claimed)
    if (_conf.shouldClaim && claimRewardsIntervalReached(c.lastClaimRewardsAt)) {
      _claimRewards(c, _conf.status);
      c.lastClaimRewardsAt = block.timestamp;
    } else {
      require(_conf.status != StakeStatus.EQUILIBRIUM, "NOTHING_TO_DO");
    }

    if (c.callBeforeAfterPoke) {
      _afterPoke(c, _conf.status, _conf.shouldClaim);
    }
  }

  function claimRewardsIntervalReached(uint256 _lastClaimRewardsAt) public view returns (bool) {
    return _lastClaimRewardsAt + claimRewardsInterval < block.timestamp;
  }

  /**
   * @notice Rebalance every connector according to its share in an array.
   * @param _claimAndDistributeRewards Need to claim and distribute rewards.
   * @param _isSlasher Calling by Slasher.
   */
  function _pokeFrom(bool _claimAndDistributeRewards, bool _isSlasher) internal {
    PokeFromState memory state = PokeFromState(0, 0, 0, 0, false, false);
    (state.minInterval, state.maxInterval) = _getMinMaxReportInterval();

    _rebalance(state, _claimAndDistributeRewards, _isSlasher);

    require(
      _canPoke(_isSlasher, state.atLeastOneForceRebalance, state.minInterval, state.maxInterval),
      "INTERVAL_NOT_REACHED_OR_NOT_FORCE"
    );

    lastRebalancedByPokerAt = block.timestamp;
  }

  function _rebalance(
    PokeFromState memory s,
    bool _claimAndDistributeRewards,
    bool _isSlasher
  ) internal {
    if (connectors.length == 1 && reserveRatio == 0 && !_claimAndDistributeRewards) {
      if (s.addToExpectedAmount > 0) {
        _rebalancePoke(connectors[0], StakeStatus.EXCESS, s.addToExpectedAmount);
      } else {
        _rebalancePoke(connectors[0], StakeStatus.SHORTAGE, piToken.getUnderlyingBalance());
      }
      return;
    }

    s.piTokenUnderlyingBalance = piToken.getUnderlyingBalance();
    (uint256[] memory stakedBalanceList, uint256 totalStakedBalance) = _getUnderlyingStakedList();

    RebalanceConfig[] memory configs = new RebalanceConfig[](connectors.length);

    // First cycle: connectors with EXCESS balance status on staking
    for (uint256 i = 0; i < connectors.length; i++) {
      if (connectors[i].share == 0) {
        continue;
      }

      (StakeStatus status, uint256 diff, bool shouldClaim, bool forceRebalance) = getStakeAndClaimStatus(
        s.piTokenUnderlyingBalance,
        totalStakedBalance,
        stakedBalanceList[i],
        s.addToExpectedAmount,
        _claimAndDistributeRewards,
        connectors[i]
      );
      if (forceRebalance) {
        s.atLeastOneForceRebalance = true;
      }

      if (status == StakeStatus.EXCESS) {
        // Calling rebalance immediately if interval conditions reached
        if (s.skipCanPokeCheck || _canPoke(_isSlasher, forceRebalance, s.minInterval, s.maxInterval)) {
          _rebalancePokeByConf(RebalanceConfig(false, status, diff, shouldClaim, forceRebalance, i));
        }
      } else {
        // Push config for second cycle
        configs[i] = RebalanceConfig(true, status, diff, shouldClaim, forceRebalance, i);
      }
    }

    // Second cycle: connectors with EQUILIBRIUM and SHORTAGE balance status on staking
    for (uint256 i = 0; i < connectors.length; i++) {
      if (!configs[i].shouldPushFunds) {
        continue;
      }
      // Calling rebalance if interval conditions reached
      if (s.skipCanPokeCheck || _canPoke(_isSlasher, configs[i].forceRebalance, s.minInterval, s.maxInterval)) {
        _rebalancePokeByConf(configs[i]);
      }
    }
  }

  /**
   * @notice Checking: if time interval reached or have `forceRebalance`.
   */
  function _canPoke(
    bool _isSlasher,
    bool _forceRebalance,
    uint256 _minInterval,
    uint256 _maxInterval
  ) internal view returns (bool) {
    if (_forceRebalance) {
      return true;
    }
    return
      _isSlasher
        ? (lastRebalancedByPokerAt + _maxInterval < block.timestamp)
        : (lastRebalancedByPokerAt + _minInterval < block.timestamp);
  }

  /**
   * @notice Call redeem in the connector with delegatecall, save result stakeData if not null.
   */
  function _redeem(Connector storage _c, uint256 _diff) internal {
    _callStakeRedeem("redeem(uint256,(bytes,bytes,uint256,address))", _c, _diff);
  }

  /**
   * @notice Call stake in the connector with delegatecall, save result `stakeData` if not null.
   */
  function _stake(Connector storage _c, uint256 _diff) internal {
    _callStakeRedeem("stake(uint256,(bytes,bytes,uint256,address))", _c, _diff);
  }

  function _callStakeRedeem(
    string memory _method,
    Connector storage _c,
    uint256 _diff
  ) internal {
    (bool success, bytes memory result) = address(_c.connector).delegatecall(
      abi.encodeWithSignature(_method, _diff, _getDistributeData(_c))
    );
    require(success, string(result));
    bool claimed;
    (result, claimed) = abi.decode(result, (bytes, bool));
    if (result.length > 0) {
      _c.stakeData = result;
    }
    if (claimed) {
      _c.lastClaimRewardsAt = block.timestamp;
    }
    _c.lastChangeStakeAt = block.timestamp;
  }

  /**
   * @notice Call `beforePoke` in the connector with delegatecall, do not save `pokeData`.
   */
  function _beforePoke(Connector storage c, bool _willClaimReward) internal {
    (bool success, ) = address(c.connector).delegatecall(
      abi.encodeWithSignature(
        "beforePoke(bytes,(bytes,uint256,address),bool)",
        c.pokeData,
        _getDistributeData(c),
        _willClaimReward
      )
    );
    require(success, "_beforePoke call error");
  }

  /**
   * @notice Call `afterPoke` in the connector with delegatecall, save result `pokeData` if not null.
   */
  function _afterPoke(
    Connector storage _c,
    StakeStatus _stakeStatus,
    bool _rewardClaimDone
  ) internal {
    (bool success, bytes memory result) = address(_c.connector).delegatecall(
      abi.encodeWithSignature("afterPoke(uint8,bool)", uint8(_stakeStatus), _rewardClaimDone)
    );
    require(success, string(result));
    result = abi.decode(result, (bytes));
    if (result.length > 0) {
      _c.pokeData = result;
    }
  }

  /**
   * @notice Rebalance connector: stake if StakeStatus.SHORTAGE and redeem if StakeStatus.EXCESS.
   */
  function _rebalancePoke(
    Connector storage _c,
    StakeStatus _stakeStatus,
    uint256 _diff
  ) internal {
    if (_stakeStatus == StakeStatus.EXCESS) {
      _redeem(_c, _diff);
    } else if (_stakeStatus == StakeStatus.SHORTAGE) {
      _stake(_c, _diff);
    }
  }

  function redeem(uint256 _connectorIndex, uint256 _diff) external onlyOwner {
    _redeem(connectors[_connectorIndex], _diff);
  }

  function stake(uint256 _connectorIndex, uint256 _diff) external onlyOwner {
    _stake(connectors[_connectorIndex], _diff);
  }

  /**
   * @notice Explicitly collects the assigned rewards. If a reward token is the same as the underlying, it should
   * allocate it at piERC20. Otherwise, it should transfer to the router contract for further action.
   * @dev It's not the only way to claim rewards. Sometimes rewards are distributed implicitly while interacting
   * with a protocol. E.g., MasterChef distributes rewards on each `deposit()/withdraw()` action, and there is
   * no use in calling `_claimRewards()` immediately after calling one of these methods.
   */
  function _claimRewards(Connector storage c, StakeStatus _stakeStatus) internal {
    (bool success, bytes memory result) = address(c.connector).delegatecall(
      abi.encodeWithSelector(IRouterConnector.claimRewards.selector, _stakeStatus, _getDistributeData(c))
    );
    require(success, string(result));
    result = abi.decode(result, (bytes));
    if (result.length > 0) {
      c.stakeData = result;
    }
  }

  function _reward(
    uint256 _reporterId,
    uint256 _gasStart,
    uint256 _compensationPlan,
    bytes calldata _rewardOpts
  ) internal {
    powerPoke.reward(_reporterId, _gasStart.sub(gasleft()), _compensationPlan, _rewardOpts);
  }

  /*
   * @dev Getting status and diff of actual staked balance and target reserve balance.
   */
  function getStakeStatusForBalance(uint256 _stakedBalance, uint256 _share)
    external
    view
    returns (
      StakeStatus status,
      uint256 diff,
      bool forceRebalance
    )
  {
    return getStakeStatus(piToken.getUnderlyingBalance(), getUnderlyingStaked(), _stakedBalance, 0, _share);
  }

  function getStakeAndClaimStatus(
    uint256 _leftOnPiTokenBalance,
    uint256 _totalStakedBalance,
    uint256 _stakedBalance,
    uint256 _addToExpectedAmount,
    bool _claimAndDistributeRewards,
    Connector memory _c
  )
    public
    view
    returns (
      StakeStatus status,
      uint256 diff,
      bool shouldClaim,
      bool forceRebalance
    )
  {
    (status, diff, forceRebalance) = getStakeStatus(
      _leftOnPiTokenBalance,
      _totalStakedBalance,
      _stakedBalance,
      _addToExpectedAmount,
      _c.share
    );
    shouldClaim = _claimAndDistributeRewards && claimRewardsIntervalReached(_c.lastClaimRewardsAt);

    if (shouldClaim && _c.claimParams.length != 0) {
      shouldClaim = _c.connector.isClaimAvailable(_c.claimParams, _c.lastClaimRewardsAt, _c.lastChangeStakeAt);
      if (shouldClaim && !forceRebalance) {
        forceRebalance = true;
      }
    }
  }

  /*
   * @dev Getting status and diff of current staked balance and target stake balance.
   */
  function getStakeStatus(
    uint256 _leftOnPiTokenBalance,
    uint256 _totalStakedBalance,
    uint256 _stakedBalance,
    uint256 _addToExpectedAmount,
    uint256 _share
  )
    public
    view
    returns (
      StakeStatus status,
      uint256 diff,
      bool forceRebalance
    )
  {
    uint256 expectedStakeAmount;
    (status, diff, expectedStakeAmount) = getStakeStatusPure(
      reserveRatio,
      _leftOnPiTokenBalance,
      _totalStakedBalance,
      _stakedBalance,
      _share,
      _addToExpectedAmount
    );

    if (status == StakeStatus.EQUILIBRIUM) {
      return (status, diff, forceRebalance);
    }

    uint256 denominator = _leftOnPiTokenBalance.add(_totalStakedBalance);

    if (status == StakeStatus.EXCESS) {
      uint256 numerator = _leftOnPiTokenBalance.add(diff).mul(HUNDRED_PCT);
      uint256 currentRatio = numerator.div(denominator);
      forceRebalance = reserveRatioLowerBound >= currentRatio;
    } else if (status == StakeStatus.SHORTAGE) {
      if (diff > _leftOnPiTokenBalance) {
        return (status, diff, true);
      }
      uint256 numerator = _leftOnPiTokenBalance.sub(diff).mul(HUNDRED_PCT);
      uint256 currentRatio = numerator.div(denominator);
      forceRebalance = reserveRatioUpperBound <= currentRatio;
    }
  }

  function getUnderlyingStaked() public view virtual returns (uint256) {
    uint256 underlyingStaked = 0;
    for (uint256 i = 0; i < connectors.length; i++) {
      require(address(connectors[i].connector) != address(0), "CONNECTOR_IS_NULL");
      underlyingStaked += connectors[i].connector.getUnderlyingStaked();
    }
    return underlyingStaked;
  }

  function _getUnderlyingStakedList() internal view virtual returns (uint256[] memory list, uint256 total) {
    uint256[] memory underlyingStakedList = new uint256[](connectors.length);
    total = 0;
    for (uint256 i = 0; i < connectors.length; i++) {
      require(address(connectors[i].connector) != address(0), "CONNECTOR_IS_NULL");
      underlyingStakedList[i] = connectors[i].connector.getUnderlyingStaked();
      total += underlyingStakedList[i];
    }
    return (underlyingStakedList, total);
  }

  function getUnderlyingReserve() public view returns (uint256) {
    return underlying.balanceOf(address(piToken));
  }

  function calculateLockedProfit() public view returns (uint256) {
    uint256 lockedProfit = 0;
    for (uint256 i = 0; i < connectors.length; i++) {
      require(address(connectors[i].connector) != address(0), "CONNECTOR_IS_NULL");
      lockedProfit += connectors[i].connector.calculateLockedProfit(connectors[i].stakeData);
    }
    return lockedProfit;
  }

  function getUnderlyingAvailable() public view returns (uint256) {
    // _getUnderlyingReserve + getUnderlyingStaked - _calculateLockedProfit
    return getUnderlyingReserve().add(getUnderlyingStaked()).sub(calculateLockedProfit());
  }

  function getUnderlyingTotal() external view returns (uint256) {
    // _getUnderlyingReserve + getUnderlyingStaked
    return getUnderlyingReserve().add(getUnderlyingStaked());
  }

  function getPiEquivalentForUnderlying(uint256 _underlyingAmount, uint256 _piTotalSupply)
    external
    view
    virtual
    override
    returns (uint256)
  {
    return getPiEquivalentForUnderlyingPure(_underlyingAmount, getUnderlyingAvailable(), _piTotalSupply);
  }

  function getPiEquivalentForUnderlyingPure(
    uint256 _underlyingAmount,
    uint256 _totalUnderlyingWrapped,
    uint256 _piTotalSupply
  ) public pure virtual override returns (uint256) {
    if (_piTotalSupply == 0) {
      return _underlyingAmount;
    }
    // return _piTotalSupply * _underlyingAmount / _totalUnderlyingWrapped;
    return _piTotalSupply.mul(_underlyingAmount).div(_totalUnderlyingWrapped);
  }

  function getUnderlyingEquivalentForPi(uint256 _piAmount, uint256 _piTotalSupply)
    external
    view
    virtual
    override
    returns (uint256)
  {
    return getUnderlyingEquivalentForPiPure(_piAmount, getUnderlyingAvailable(), _piTotalSupply);
  }

  function getUnderlyingEquivalentForPiPure(
    uint256 _piAmount,
    uint256 _totalUnderlyingWrapped,
    uint256 _piTotalSupply
  ) public pure virtual override returns (uint256) {
    if (_piTotalSupply == 0) {
      return _piAmount;
    }
    // _piAmount * _totalUnderlyingWrapped / _piTotalSupply;
    return _totalUnderlyingWrapped.mul(_piAmount).div(_piTotalSupply);
  }

  /**
   * @notice Calculates the desired stake status.
   * @param _reserveRatioPct The reserve ratio in %, 1 ether == 100 ether.
   * @param _leftOnPiToken The underlying ERC20 tokens balance on the piERC20 contract.
   * @param _totalStakedBalance The underlying ERC20 tokens balance staked on the all connected staking contracts.
   * @param _stakedBalance The underlying ERC20 tokens balance staked on the connector staking contract.
   * @param _share Share of the connector contract.
   * @return status The stake status:
   * * SHORTAGE: There is not enough underlying ERC20 balance on the staking contract to satisfy the reserve ratio.
   *             Therefore, the connector contract should send the diff amount to the staking contract.
   * * EXCESS: There is some extra underlying ERC20 balance on the staking contract.
   *           Therefore, the connector contract should redeem the diff amount from the staking contract.
   * * EQUILIBRIUM: The reserve ratio hasn't changed, the diff amount is 0, and no need for additional
   *                stake/redeem actions.
   * @return diff The difference between `expectedStakeAmount` and `_stakedBalance`.
   * @return expectedStakeAmount The calculated expected underlying ERC20 staked balance.
   */
  function getStakeStatusPure(
    uint256 _reserveRatioPct,
    uint256 _leftOnPiToken,
    uint256 _totalStakedBalance,
    uint256 _stakedBalance,
    uint256 _share,
    uint256 _addToExpectedStakeAmount
  )
    public
    view
    returns (
      StakeStatus status,
      uint256 diff,
      uint256 expectedStakeAmount
    )
  {
    require(_reserveRatioPct <= HUNDRED_PCT, "RR_GREATER_THAN_100_PCT");
    expectedStakeAmount = getExpectedStakeAmount(_reserveRatioPct, _leftOnPiToken, _totalStakedBalance, _share);
    expectedStakeAmount = expectedStakeAmount.add(_addToExpectedStakeAmount.mul(_share).div(1 ether));

    if (expectedStakeAmount > _stakedBalance) {
      status = StakeStatus.SHORTAGE;
      diff = expectedStakeAmount.sub(_stakedBalance);
    } else if (expectedStakeAmount < _stakedBalance) {
      status = StakeStatus.EXCESS;
      diff = _stakedBalance.sub(expectedStakeAmount);
    } else {
      status = StakeStatus.EQUILIBRIUM;
      diff = 0;
    }
  }

  /**
   * @notice Calculates an expected underlying ERC20 staked balance.
   * @param _reserveRatioPct % of a reserve ratio, 1 ether == 100%.
   * @param _leftOnPiToken The underlying ERC20 tokens balance on the piERC20 contract.
   * @param _stakedBalance The underlying ERC20 tokens balance staked on the staking contract.
   * @param _share % of a total connectors share, 1 ether == 100%.
   * @return expectedStakeAmount The expected stake amount:
   *
   *                           / (100% - %reserveRatio) * (_leftOnPiToken + _stakedBalance) * %share \
   *    expectedStakeAmount = | ----------------------------------------------------------------------|
   *                           \                                    100%                             /
   */
  function getExpectedStakeAmount(
    uint256 _reserveRatioPct,
    uint256 _leftOnPiToken,
    uint256 _stakedBalance,
    uint256 _share
  ) public pure returns (uint256) {
    return
      uint256(1 ether).sub(_reserveRatioPct).mul(_stakedBalance.add(_leftOnPiToken).mul(_share).div(HUNDRED_PCT)).div(
        HUNDRED_PCT
      );
  }

  function _getMinMaxReportInterval() internal view returns (uint256 min, uint256 max) {
    return powerPoke.getMinMaxReportIntervals(address(this));
  }

  function _getDistributeData(Connector storage c) internal view returns (IRouterConnector.DistributeData memory) {
    return IRouterConnector.DistributeData(c.stakeData, c.stakeParams, performanceFee, performanceFeeReceiver);
  }

  function _checkConnectorsTotalShare() internal view {
    uint256 totalShare = 0;
    for (uint256 i = 0; i < connectors.length; i++) {
      require(address(connectors[i].connector) != address(0), "CONNECTOR_IS_NULL");
      totalShare = totalShare.add(connectors[i].share);
    }
    require(totalShare == HUNDRED_PCT, "TOTAL_SHARE_IS_NOT_HUNDRED_PCT");
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IPowerPoke {
  /*** CLIENT'S CONTRACT INTERFACE ***/
  function authorizeReporter(uint256 userId_, address pokerKey_) external view;

  function authorizeNonReporter(uint256 userId_, address pokerKey_) external view;

  function authorizeNonReporterWithDeposit(
    uint256 userId_,
    address pokerKey_,
    uint256 overrideMinDeposit_
  ) external view;

  function authorizePoker(uint256 userId_, address pokerKey_) external view;

  function authorizePokerWithDeposit(
    uint256 userId_,
    address pokerKey_,
    uint256 overrideMinStake_
  ) external view;

  function slashReporter(uint256 slasherId_, uint256 times_) external;

  function reward(
    uint256 userId_,
    uint256 gasUsed_,
    uint256 compensationPlan_,
    bytes calldata pokeOptions_
  ) external;

  /*** CLIENT OWNER INTERFACE ***/
  function transferClientOwnership(address client_, address to_) external;

  function addCredit(address client_, uint256 amount_) external;

  function withdrawCredit(
    address client_,
    address to_,
    uint256 amount_
  ) external;

  function setReportIntervals(
    address client_,
    uint256 minReportInterval_,
    uint256 maxReportInterval_
  ) external;

  function setSlasherHeartbeat(address client_, uint256 slasherHeartbeat_) external;

  function setGasPriceLimit(address client_, uint256 gasPriceLimit_) external;

  function setFixedCompensations(
    address client_,
    uint256 eth_,
    uint256 cvp_
  ) external;

  function setBonusPlan(
    address client_,
    uint256 planId_,
    bool active_,
    uint64 bonusNominator_,
    uint64 bonusDenominator_,
    uint64 perGas_
  ) external;

  function setMinimalDeposit(address client_, uint256 defaultMinDeposit_) external;

  /*** POKER INTERFACE ***/
  function withdrawRewards(uint256 userId_, address to_) external;

  function setPokerKeyRewardWithdrawAllowance(uint256 userId_, bool allow_) external;

  /*** OWNER INTERFACE ***/
  function addClient(
    address client_,
    address owner_,
    bool canSlash_,
    uint256 gasPriceLimit_,
    uint256 minReportInterval_,
    uint256 maxReportInterval_
  ) external;

  function setClientActiveFlag(address client_, bool active_) external;

  function setCanSlashFlag(address client_, bool canSlash) external;

  function setOracle(address oracle_) external;

  function pause() external;

  function unpause() external;

  /*** GETTERS ***/
  function creditOf(address client_) external view returns (uint256);

  function ownerOf(address client_) external view returns (address);

  function getMinMaxReportIntervals(address client_) external view returns (uint256 min, uint256 max);

  function getSlasherHeartbeat(address client_) external view returns (uint256);

  function getGasPriceLimit(address client_) external view returns (uint256);

  function getPokerBonus(
    address client_,
    uint256 bonusPlanId_,
    uint256 gasUsed_,
    uint256 userDeposit_
  ) external view returns (uint256);

  function getGasPriceFor(address client_) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/WrappedPiErc20Interface.sol";
import "./interfaces/PowerIndexNaiveRouterInterface.sol";

contract PowerIndexNaiveRouter is PowerIndexNaiveRouterInterface, Ownable {
  using SafeMath for uint256;

  function migrateToNewRouter(
    address _piToken,
    address payable _newRouter,
    address[] memory /*_tokens*/
  ) public virtual override onlyOwner {
    WrappedPiErc20Interface(_piToken).changeRouter(_newRouter);
  }

  function enableRouterCallback(address _piToken, bool _enable) public override onlyOwner {
    WrappedPiErc20Interface(_piToken).enableRouterCallback(_enable);
  }

  function piTokenCallback(address sender, uint256 _withdrawAmount) external payable virtual override {
    // DO NOTHING
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../PowerIndexRouter.sol";
import "../WrappedPiErc20.sol";

contract MockRouter is PowerIndexRouter {
  event MockWrapperCallback(uint256 withdrawAmount);

  constructor(address _piToken, BasicConfig memory _basicConfig) public PowerIndexRouter(_piToken, _basicConfig) {}

  function piTokenCallback(address, uint256 _withdrawAmount) external payable virtual override {
    emit MockWrapperCallback(_withdrawAmount);
  }

  function execute(address destination, bytes calldata data) external {
    destination.call(data);
  }

  function drip(address _to, uint256 _amount) external {
    piToken.callExternal(
      address(WrappedPiErc20(address(piToken)).underlying()),
      IERC20(0).transfer.selector,
      abi.encode(_to, _amount),
      0
    );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals,
    uint256 supply
  ) public ERC20(name, symbol) {
    _mint(msg.sender, supply);
    _setupDecimals(decimals);
  }

  function mockWithdrawErc20(address token, uint256 amount) public {
    ERC20(token).transfer(msg.sender, amount);
  }

  function mint(address account, uint256 amount) public {
    _mint(account, amount);
  }

  function burn(uint256 amount) public {
    _burn(msg.sender, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./MockERC20.sol";

contract MockERC20Permit is MockERC20 {
  bytes32 public immutable DOMAIN_SEPARATOR;

  bytes32 public constant PERMIT_TYPEHASH =
    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

  mapping(address => uint256) public nonces;

  string public constant version = "1";

  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    uint256 supply
  ) public MockERC20(_name, _symbol, _decimals, supply) {
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes(_name)),
        keccak256(bytes(version)),
        31337,
        address(this)
      )
    );
  }

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    require(owner != address(0), "INVALID_OWNER");
    require(block.timestamp <= deadline, "INVALID_EXPIRATION");
    uint256 currentValidNonce = nonces[owner];
    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, currentValidNonce, deadline))
      )
    );

    require(owner == ecrecover(digest, v, r, s), "INVALID_SIGNATURE");
    nonces[owner] = currentValidNonce.add(1);
    _approve(owner, spender, value);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockPancakeMasterChef {
  address token;
  bool doTransfer;

  constructor(address _token) public {
    token = _token;
    doTransfer = true;
  }

  function setDoTransfer(bool _doTransfer) external {
    doTransfer = _doTransfer;
  }

  function enterStaking(uint256 _amount) external {
    if (doTransfer) {
      IERC20(token).transferFrom(msg.sender, address(42), _amount);
    }
  }

  function leaveStaking(uint256) external {}

  function userInfo(uint256, address) external pure returns (uint256 amount, uint256 rewardDebt) {
    return (0, 0);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockBakeryMasterChef {
  function deposit(address _token, uint256 _amount) external {
    IERC20(_token).transferFrom(msg.sender, address(42), _amount);
  }

  function withdraw(address, uint256) external {}

  function poolUserInfoMap(address, address) external pure returns (uint256 amount, uint256 rewardDebt) {
    return (0, 0);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockAutoMasterChef {
  address token;
  uint256 swt;

  constructor(address _token, uint256 _swt) public {
    token = _token;
    swt = _swt;
  }

  function deposit(uint256, uint256 _amount) external {
    IERC20(token).transferFrom(msg.sender, address(42), _amount);
  }

  function withdraw(uint256, uint256) external {}

  function stakedWantTokens(uint256, address) external view returns (uint256) {
    return swt;
  }

  function poolInfo(uint256)
    external
    pure
    returns (
      address want,
      uint256 allocPoint,
      uint256 lastRewardBlock,
      uint256 accAUTOPerShare,
      address strat
    )
  {
    return (address(0), 0, 0, 0, strat);
  }

  function userInfo(uint256, address) external pure returns (uint256 amount, uint256 rewardDebt) {
    return (0, 0);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface TokenInterface is IERC20 {
  function deposit() external payable;

  function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMigrator {
  // Perform LP token migration from legacy UniswapV2 to PowerSwap.
  // Take the current LP token address and return the new LP token address.
  // Migrator should have full access to the caller's LP token.
  // Return the new LP token address.
  //
  // XXX Migrator must have allowance access to UniswapV2 LP tokens.
  // PowerSwap must mint EXACTLY the same amount of PowerSwap LP tokens or
  // else something bad will happen. Traditional UniswapV2 does not
  // do that so be careful!
  function migrate(IERC20 token, uint8 poolType) external returns (IERC20);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/sushi/IMasterChefV1.sol";
import "./AbstractConnector.sol";

abstract contract AbstractStakeRedeemConnector is AbstractConnector {
  event Stake(address indexed sender, uint256 amount, uint256 rewardReceived);
  event Redeem(address indexed sender, uint256 amount, uint256 rewardReceived);

  address public immutable STAKING;
  IERC20 public immutable UNDERLYING;
  WrappedPiErc20Interface public immutable PI_TOKEN;

  constructor(
    address _staking,
    address _underlying,
    address _piToken,
    uint256 _lockedProfitDegradation
  ) public AbstractConnector(_lockedProfitDegradation) {
    STAKING = _staking;
    UNDERLYING = IERC20(_underlying);
    PI_TOKEN = WrappedPiErc20Interface(_piToken);
  }

  /*** PERMISSIONLESS REWARD CLAIMING AND DISTRIBUTION ***/

  function claimRewards(PowerIndexRouterInterface.StakeStatus _status, DistributeData memory _distributeData)
    external
    virtual
    override
    returns (bytes memory stakeData)
  {
    if (_status == PowerIndexRouterInterface.StakeStatus.EQUILIBRIUM) {
      uint256 tokenBefore = UNDERLYING.balanceOf(address(PI_TOKEN));
      _claimImpl();
      uint256 receivedReward = UNDERLYING.balanceOf(address(PI_TOKEN)).sub(tokenBefore);
      if (receivedReward > 0) {
        (, stakeData) = _distributeReward(_distributeData, PI_TOKEN, UNDERLYING, receivedReward);
        return stakeData;
      }
    }
    // Otherwise the rewards are distributed each time deposit/withdraw methods are called,
    // so no additional actions required.
    return new bytes(0);
  }

  function stake(uint256 _amount, DistributeData memory _distributeData)
    public
    override
    returns (bytes memory result, bool claimed)
  {
    uint256 balanceBefore = UNDERLYING.balanceOf(address(PI_TOKEN));

    _approveToStaking(_amount);

    _stakeImpl(_amount);

    uint256 receivedReward = UNDERLYING.balanceOf(address(PI_TOKEN)).add(_amount).sub(balanceBefore);

    if (receivedReward > 0) {
      (, result) = _distributeReward(_distributeData, PI_TOKEN, UNDERLYING, receivedReward);
      claimed = true;
    }

    emit Stake(msg.sender, STAKING, address(UNDERLYING), _amount);
  }

  function redeem(uint256 _amount, DistributeData memory _distributeData)
    external
    override
    returns (bytes memory result, bool claimed)
  {
    uint256 balanceBefore = UNDERLYING.balanceOf(address(PI_TOKEN));

    _redeemImpl(_amount);

    uint256 receivedReward = UNDERLYING.balanceOf(address(PI_TOKEN)).sub(_amount).sub(balanceBefore);

    if (receivedReward > 0) {
      (, result) = _distributeReward(_distributeData, PI_TOKEN, UNDERLYING, receivedReward);
      claimed = true;
    }

    emit Redeem(msg.sender, STAKING, address(UNDERLYING), _amount);
  }

  /*** INTERNALS ***/
  function _approveToStaking(uint256 _amount) internal virtual {
    PI_TOKEN.approveUnderlying(STAKING, _amount);
  }

  function _claimImpl() internal virtual;

  function _stakeImpl(uint256 _amount) internal virtual;

  function _redeemImpl(uint256 _amount) internal virtual;

  function beforePoke(
    bytes memory _pokeData,
    DistributeData memory _distributeData,
    bool _willClaimReward
  ) external override {}

  function afterPoke(
    PowerIndexRouterInterface.StakeStatus, /*reserveStatus*/
    bool /*_rewardClaimDone*/
  ) external override returns (bytes memory) {
    return new bytes(0);
  }

  function initRouter(bytes calldata) external override {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IMasterChefV1 {
  function userInfo(uint256 _pid, address _user) external view returns (uint256 amount, uint256 rewardDebt);

  function pending(uint256 _pid, address _user) external view returns (uint256);

  function deposit(uint256 _pid, uint256 _amount) external;

  function withdraw(uint256 _pid, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IPancakeMasterChef.sol";
import "./AbstractStakeRedeemConnector.sol";

/**
 * Compatible with:
 * - Pancake: https://bscscan.com/address/0x73feaa1ee314f8c655e354234017be2193c9e24e
 * To get pending rewards use IPancakeStaking(0x73feaa1ee314f8c655e354234017be2193c9e24e).pendingCake(0, piToken).
 */
contract PancakeMasterChefIndexConnector is AbstractStakeRedeemConnector {
  uint256 internal constant PANCAKE_POOL_ID = 0;

  constructor(
    address _staking,
    address _underlying,
    address _piToken
  ) public AbstractStakeRedeemConnector(_staking, _underlying, _piToken, 46e12) {} //6 hours with 13ms block

  /*** VIEWERS ***/

  function getPendingRewards() external view returns (uint256 amount) {
    return IPancakeMasterChef(STAKING).pendingCake(PANCAKE_POOL_ID, address(PI_TOKEN));
  }

  /*** OVERRIDES ***/

  function getUnderlyingStaked() external view override returns (uint256) {
    if (STAKING == address(0)) {
      return 0;
    }
    (uint256 amount, ) = IPancakeMasterChef(STAKING).userInfo(PANCAKE_POOL_ID, address(PI_TOKEN));
    return amount;
  }

  function _claimImpl() internal override {
    _stakeImpl(0);
  }

  function _stakeImpl(uint256 _amount) internal override {
    _callExternal(PI_TOKEN, STAKING, IPancakeMasterChef.enterStaking.selector, abi.encode(_amount));
  }

  function _redeemImpl(uint256 _amount) internal override {
    _callExternal(PI_TOKEN, STAKING, IPancakeMasterChef.leaveStaking.selector, abi.encode(_amount));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IPancakeMasterChef {
  function userInfo(uint256 _pid, address _user) external view returns (uint256 amount, uint256 rewardDebt);

  function pendingCake(uint256 _pid, address _user) external view returns (uint256);

  function enterStaking(uint256 _amount) external;

  function leaveStaking(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/sushi/IMasterChefV1.sol";
import "./AbstractStakeRedeemConnector.sol";

/**
 * Compatible with:
 * - MDEX: https://bscscan.com/address/0x6aee12e5eb987b3be1ba8e621be7c4804925ba68,
 *   pending rewards via pending(pid, user)
 */
contract MasterChefPowerIndexConnector is AbstractStakeRedeemConnector {
  uint256 public immutable MASTER_CHEF_PID;

  constructor(
    address _staking,
    address _underlying,
    address _piToken,
    uint256 _masterChefPid
  ) public AbstractStakeRedeemConnector(_staking, _underlying, _piToken, 46e12) {
    //6 hours with 13ms block
    MASTER_CHEF_PID = _masterChefPid;
  }

  /*** VIEWERS ***/

  function getPendingRewards() external view returns (uint256 amount) {
    return IMasterChefV1(STAKING).pending(MASTER_CHEF_PID, address(PI_TOKEN));
  }

  /*** OVERRIDES ***/

  function getUnderlyingStaked() external view override returns (uint256) {
    if (STAKING == address(0)) {
      return 0;
    }
    (uint256 amount, ) = IMasterChefV1(STAKING).userInfo(MASTER_CHEF_PID, address(PI_TOKEN));
    return amount;
  }

  function _claimImpl() internal override {
    _stakeImpl(0);
  }

  function _stakeImpl(uint256 _amount) internal override {
    _callExternal(PI_TOKEN, STAKING, IMasterChefV1.deposit.selector, abi.encode(MASTER_CHEF_PID, _amount));
  }

  function _redeemImpl(uint256 _amount) internal override {
    _callExternal(PI_TOKEN, STAKING, IMasterChefV1.withdraw.selector, abi.encode(MASTER_CHEF_PID, _amount));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IBakeryMasterChef.sol";
import "./AbstractStakeRedeemConnector.sol";

/**
 * Compatible with:
 * - Bakery: https://bscscan.com/address/0x20ec291bb8459b6145317e7126532ce7ece5056f,
 *   pending rewards via pendingBake(pair, user)
 * @dev Notice that in deposit/withdraw/pending Bake method signatures, Bakery uses the staking token addresses
 *      instead of numerical pool IDs like in most masterChef forks.
 */
contract BakeryChefPowerIndexConnector is AbstractStakeRedeemConnector {
  constructor(
    address _staking,
    address _underlying,
    address _piToken
  ) public AbstractStakeRedeemConnector(_staking, _underlying, _piToken, 46e12) {} //6 hours with 13ms block

  /*** VIEWERS ***/

  function getPendingRewards() external view returns (uint256 amount) {
    return IBakeryMasterChef(STAKING).pendingBake(address(UNDERLYING), address(PI_TOKEN));
  }

  /*** OVERRIDES ***/

  function getUnderlyingStaked() external view override returns (uint256) {
    if (STAKING == address(0)) {
      return 0;
    }
    (uint256 amount, ) = IBakeryMasterChef(STAKING).poolUserInfoMap(address(UNDERLYING), address(PI_TOKEN));
    return amount;
  }

  function _claimImpl() internal override {
    _stakeImpl(0);
  }

  function _stakeImpl(uint256 _amount) internal override {
    _callExternal(PI_TOKEN, STAKING, IBakeryMasterChef.deposit.selector, abi.encode(address(UNDERLYING), _amount));
  }

  function _redeemImpl(uint256 _amount) internal override {
    _callExternal(PI_TOKEN, STAKING, IBakeryMasterChef.withdraw.selector, abi.encode(address(UNDERLYING), _amount));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IBakeryMasterChef {
  function poolUserInfoMap(address _pair, address _user) external view returns (uint256 amount, uint256 rewardDebt);

  function pendingBake(address _pair, address _user) external view returns (uint256);

  function deposit(address _pair, uint256 _amount) external;

  function withdraw(address _pair, uint256 _amount) external;
}