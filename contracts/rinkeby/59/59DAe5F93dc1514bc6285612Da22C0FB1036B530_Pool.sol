// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import {SafeMath} from "../external/openzeppelin/contracts/math/SafeMath.sol";
import "../wallet/Constants.sol";
import "./PoolSetters.sol";
import "../token/IVufi.sol";
import "../wallet/IWallet.sol";
import "../external/Decimal.sol";
import {ReentrancyGuard} from "../utils/ReentrancyGuard.sol";
import {IERC20} from "../external/openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../external/openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract Pool is PoolSetters, ReentrancyGuard {
  using SafeMath for uint256;
  using Decimal for Decimal.D256;
  using SafeERC20 for IERC20;

  event Mint(address indexed account, uint256 value, uint256 collateralValue);
  event Redeem(address indexed account, uint256 value, uint256 collateralValuePartial, uint256 couponsPartial);

  constructor(address vufi, address collateral, address wallet, address ownerAddress) {
    _data.contracts.wallet = IWallet(wallet);
    _data.contracts.vufi = IERC20(vufi);
    _data.contracts.collateralToken = IERC20(collateral);
    _data.ownerAddress = ownerAddress;
    _data.poolLimit = Constants.POOL_LIMIT;
    _data.missingDecimals = uint256(18).sub(6);
    _data.collateralDesiredPrice = 1e6;
    _data.pricePrecision = 1e6;
  }

  /**
   * @dev Moves `value` tokens from `sender` to cellar `amount` is then deducted from the `sender`
   * in exchange gives minted vufi tokens
   *
   * In exchange on deposit one of collaterals gives back minted vufi tokens
   *
   * Requirements:
   *
   * - the protocol must be not paused.
   * - address must be in status frozen
   * - debt amount must be 0
   * - transaction must occur within limit
   * - slippage must keep with in limit
   * - amount must be bellow pool limit
   */
  function mint(uint256 collateralValue, uint256 tokenMinimumOut) external nonReentrant notMintPaused onlyFrozen(msg.sender) {
    unfreeze(msg.sender);

    require(wallet().totalDebt() == 0, "Pool: debt should be zero");
    require((IERC20(_data.contracts.collateralToken).balanceOf(address(this)).sub(_data.balance.unclaimedPoolCollateral))
    .add(collateralValue) <= _data.poolLimit, "Pool: limit reached");

    uint256 collateralChainPriceDollar = _chainlinkPrice();

    require(Decimal.ratio(collateralChainPriceDollar,
      _data.collateralDesiredPrice).greaterThan(Decimal.ratio(wallet().poolCollateralRange(),
      100)), "Pool: collateral price out of range");

    uint256 collateralAmountD18 = collateralValue.mul(10 ** _data.missingDecimals);
    uint256 mintValue = collateralAmountD18.mul(collateralChainPriceDollar).div(_data.pricePrecision);
    _data.balance.unclaimedPoolCollateral = _data.balance.unclaimedPoolCollateral.add(collateralValue);

    require(tokenMinimumOut <= mintValue, "Pool: Slippage limit reached");

    _data.contracts.collateralToken.safeTransferFrom(msg.sender, address(this), collateralValue);
    wallet().mintFromPool(msg.sender, mintValue);

    emit Mint(msg.sender, mintValue, collateralValue);
  }

  /**
   * @dev Moves `value` vufi tokens from `sender` to cellar `amount` is then deducted from the `sender`
   * in exchange gives collateral tokens then burns 'value' vufi tokens
   *
   *
   * In exchange on deposit vufi gives back collateral tokens from pool and burns vufi tokens
   *
   * Requirements:
   *
   * - the protocol must be not paused.
   * - total debt and total supply need to be over 0
   * - Collateral price must be in range
   * - Slippage must be with limit
   */
  function redeem(uint256 collateralValue, uint256 tokenRedeemOut) external nonReentrant notRedeemPaused onlyFrozen(msg.sender) {
    unfreeze(msg.sender);
    (uint256 _totalDebt, uint256 _totalSupply, uint256 _maxDeptRatio) = wallet().debtData();

    require(_totalDebt > 0 && _totalSupply > 0, "Pool: debt should be over zero");

    uint256 collateralChainPriceDollar = _chainlinkPrice();

    require(Decimal.ratio(collateralChainPriceDollar,
      _data.collateralDesiredPrice).greaterThan(Decimal.ratio(wallet().poolCollateralRange(),
      100)), "Pool: collateral price out of range");

    Decimal.D256 memory debtRatio = Decimal.ratio(_totalDebt, _totalSupply);
    Decimal.D256 memory debtRatioUpperBound = Decimal.D256({value: _maxDeptRatio});

    (uint256 collateralValuePartial, uint256 couponsPartial) = _calculateRatioRedeem(debtRatio, debtRatioUpperBound, collateralValue);

    wallet().burnFromPool(msg.sender, collateralValue);

    require(tokenRedeemOut <= collateralValuePartial, "Pool: Slippage limit reached");

    _data.balance.redeemCollateral[msg.sender] = _data.balance.redeemCollateral[msg.sender].add(collateralValuePartial);
    _data.balance.unclaimedPoolCollateral = _data.balance.unclaimedPoolCollateral.add(collateralValuePartial);
    _data.balance.lastRedeemed[msg.sender] = block.number;

    emit Redeem(msg.sender, collateralValue, collateralValuePartial, couponsPartial);
  }

  /**
  * @dev Claim `_data.balance.lastRedeemed[msg.sender]` collateral tokens from cellar to `sender`
  *
  *
  * Claim redemption
  *
  * Requirements:
  *
  * - User need to have founds
  * - User need wait `poolRedemptionDelay` amount of blocks
  */
  function collectRedemption() external nonReentrant {
    require((_data.balance.lastRedeemed[msg.sender].add(wallet().poolRedemptionDelay())) <= block.number,
      "Pool: to early to collect");

    require(_data.balance.redeemCollateral[msg.sender] > 0, "Pool: Must have minimum amount");

    uint256 collateralValue = _data.balance.redeemCollateral[msg.sender];
    _data.balance.redeemCollateral[msg.sender] = 0;
    _data.balance.unclaimedPoolCollateral = _data.balance.unclaimedPoolCollateral.sub(collateralValue);

    _data.contracts.collateralToken.safeTransfer(msg.sender, collateralValue);
  }

  /**
  * @dev Returns calculated value of ratio from `ratio(_totalDebt, _totalSupply)` or `debtRatioUpperBound`
  * and 1 ether
  *
  * Get collateral ratio
  *
  * Requirements:
  *
  * - Total supply need to be over 0
  */
  function getCollateralRatio() external view returns (uint256) {
    (uint256 _totalDebt, uint256 _totalSupply, uint256 _maxDeptRatio) = wallet().debtData();

    if(_totalSupply == 0) {
      return 0;
    }

    Decimal.D256 memory debtRatio = Decimal.ratio(_totalDebt, _totalSupply);
    Decimal.D256 memory debtRatioUpperBound = Decimal.D256({value: _maxDeptRatio});

    (uint256 collateralValuePartial, ) = _calculateRatioRedeem(debtRatio, debtRatioUpperBound, 1e6);

    return collateralValuePartial;
  }

  /**
  * @dev Return if can mint bool
  *
  */
  function canMint() external view returns(bool) {
    return wallet().totalDebt() == 0;
  }

  /**
  * @dev Return if can redeem bool
  *
  */
  function canRedeem() external view returns(bool) {
    return wallet().totalDebt() > 0;
  }

  function unfreeze(address account) internal {
    _data.accounts[account].fluidUntil = cycle().add(wallet().poolExitLookup());
  }

  function emergencyWithdraw(address token, uint256 value) external onlyOwner {
    require(token != address(0), "Pool: not empty or zero address");
    require(value > 0, "Pool: must be over 0");

    IERC20(token).safeTransfer(address(wallet()), value);
  }

  function _calculateRatioRedeem(
    Decimal.D256 memory debtRatio,
    Decimal.D256 memory debtRatioUpperBound,
    uint256 collateralValue
  ) internal pure returns(uint256, uint256) {
    if (debtRatio.greaterThan(debtRatioUpperBound)) {
      uint256 collateralValuePartial = (Decimal.one().sub(debtRatioUpperBound)).mul(collateralValue).asUint256();
      uint256 couponsPartial = debtRatioUpperBound.mul(collateralValue).asUint256();

      return (collateralValuePartial, couponsPartial);
    } else {
      uint256 collateralValuePartial = (Decimal.one().sub(debtRatio)).mul(collateralValue).asUint256();
      uint256 couponsPartial = debtRatio.mul(collateralValue).asUint256();

      return (collateralValuePartial, couponsPartial);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

//library Constants {
//  /* Cycle */
//  uint256 internal constant CURRENT_CYCLE_OFFSET = 0;
//  uint256 internal constant CURRENT_CYCLE_START = 1625152453;
//  uint256 internal constant CURRENT_CYCLE_PERIOD = 600; // 1 hour
//
//  /* Governance */
//  uint256 internal constant GOVERNANCE_PERIOD = 1; // 200 cycles
//  uint256 internal constant GOVERNANCE_EXPIRATION = 50; // 50 cycles
//  uint256 internal constant GOVERNANCE_QUORUM = 1e16; // 20%
//  uint256 internal constant GOVERNANCE_PROPOSAL_THRESHOLD = 5e15; // 0.5%
//  uint256 internal constant GOVERNANCE_SUPER_MAJORITY = 66e16; // 66%
//  uint256 internal constant GOVERNANCE_EMERGENCY_DELAY = 10; // 100 cycles
//
//  /* Pool */
//  uint256 internal constant POOL_EXIT_LOCKUP_CYCLES = 1;
//  uint256 internal constant POOL_LIMIT = 41000000000000;
//  uint256 internal constant POOL_COLLATERAL_RANGE = 60; // 60%
//  uint256 internal constant POOL_REDEMPTION_DELAY = 3;
//
//  /* WALLET */
//  uint256 internal constant ADVANCE_INCENTIVE = 150e18; // 150 VUFI
//  uint256 internal constant WALLET_EXIT_LOCKUP_CYCLES = 120; // 120 cycles fluid
//
//  /* Wallet */
//  uint256 internal constant INITIAL_STAKE_MULTIPLE = 1e6; // 100 VUFI -> 100M VUFI
//  uint256 internal constant WALLET_COUPONS_RATIO = 20; // 20%
//
//  /* Reword */
//  uint256 internal constant NEXT_REWORD_CYCLE = 168; // 24 cycle
//  uint256 internal constant NEXT_REWORD_AMOUNT = 100000000e18; // 100000000
//
//  /* Bootstrapping */
//  uint256 internal constant BOOTSTRAPPING_PERIOD = 3;
//  uint256 internal constant BOOTSTRAPPING_PRICE = 154e16; //  1.10 USDC
//  uint256 internal constant BOOTSTRAPPING_SPEEDUP_FACTOR = 3; // 30 days @ 1 hours
//
//  /* Regulator */
//  uint256 internal constant SUPPLY_CHANGE_LIMIT = 3e16; // 3%
//  uint256 internal constant COUPON_SUPPLY_CHANGE_LIMIT = 6e16; // 6%
//  uint256 internal constant TREASURY_RATIO = 250; // 2.5%
//  // TODO: change address from V to own
//  address internal constant TREASURY_ADDRESS = address(0xA5fC823743492c9cbe9F0a399873b89c60165e7B);
//
//  /* Market */
//  // TODO: update ratio cap
//  uint256 internal constant DEBT_RATIO_CAP = 90e16; // 35%
//
//  /* Oracle */
//  uint256 internal constant ORACLE_RESERVE_MINIMUM = 1e10; // 10,000 USDC
//  uint256 internal constant DOLLAR_SPENDING_MAX = 5e16; // 5%
//
//  /* Dollar spending power */
//  uint256 internal constant MANUAL_START_CPI = 273012 * 1e13;
//  uint256 internal constant MANUAL_CHANGE_LIMIT = 1160; // 0.116%
//  uint256 internal constant NEXT_SPENDING_UPDATE = 720;
//  bool internal constant ONLY_MANUAL_CPI = true;
//  uint256 internal constant VALIDATE_TOLERANCE_CPI = 20e18; // 20%
//  address internal constant ORACLE_CPI_ADDRESS = 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e;
//  bytes32 internal constant ORACLE_CPI_JOB_ID = "29fa9aa13bf1468788b7cc4a500a45b8";
//  uint256 internal constant ORACLE_CPI_FEE = 0.1 * 10 ** 18;
//}

library Constants {
  /* Cycle */
  uint256 internal constant CURRENT_CYCLE_OFFSET = 0;
  uint256 internal constant CURRENT_CYCLE_START = 1629516827;
  uint256 internal constant CURRENT_CYCLE_PERIOD = 3600; // 1 hour

  /* Governance */
  uint256 internal constant GOVERNANCE_PERIOD = 200; // 200 cycles
  uint256 internal constant GOVERNANCE_EXPIRATION = 50; // 50 cycles
  uint256 internal constant GOVERNANCE_QUORUM = 20e16; // 10%
  uint256 internal constant GOVERNANCE_PROPOSAL_THRESHOLD = 5e15; // 0.5%
  uint256 internal constant GOVERNANCE_SUPER_MAJORITY = 66e16; // 66%
  uint256 internal constant GOVERNANCE_EMERGENCY_DELAY = 100; // 100 cycles

  /* Pool */
  uint256 internal constant POOL_EXIT_LOCKUP_CYCLES = 1;
  uint256 internal constant POOL_LIMIT = 41000000000000;
  uint256 internal constant POOL_COLLATERAL_RANGE = 60; // 60%
  uint256 internal constant POOL_REDEMPTION_DELAY = 3;

  /* WALLET */
  uint256 internal constant ADVANCE_INCENTIVE = 150e18; // 150 VUFI
  uint256 internal constant WALLET_EXIT_LOCKUP_CYCLES = 120; // 120 cycles fluid

  /* Wallet */
  uint256 internal constant INITIAL_STAKE_MULTIPLE = 1e6; // 100 VUFI -> 100M VUFI
  uint256 internal constant WALLET_COUPONS_RATIO = 20; // 20%

  /* Reword */
  uint256 internal constant NEXT_REWORD_CYCLE = 168; // 24 cycle
  uint256 internal constant NEXT_REWORD_AMOUNT = 70000e18; // 100000
  uint256 internal constant POOL_REWARD_TAKE = 100000e18; // 100000
  bool internal constant NEXT_REWARDS_ENDED = false;

  /* Bootstrapping */
  uint256 internal constant BOOTSTRAPPING_PERIOD = 7;
  uint256 internal constant BOOTSTRAPPING_PRICE = 11e17; //  1.10 USDC
  uint256 internal constant BOOTSTRAPPING_SLOWDOWN_FACTOR = 24; // 7 days @ 24 hours

  /* Regulator */
  uint256 internal constant SUPPLY_CHANGE_LIMIT = 3e16; // 3%
  uint256 internal constant COUPON_SUPPLY_CHANGE_LIMIT = 6e16; // 6%
  uint256 internal constant TREASURY_RATIO = 250; // 2.5%
  uint256 internal constant MAXIMUM_BURN_FROM_WALLET = 50; // 50%
  uint256 internal constant CYCLE_EACH_COUPONS = 2400; // 0.24%
  // TODO: update address of treasury
  address internal constant TREASURY_ADDRESS = 0xc0C114C32082D732d57c633ACE36E4348bA4A82e;

  /* Market */
  uint256 internal constant DEBT_RATIO_CAP = 50e16; // 50%
  uint256 internal constant CURVE_TIME_N = 17e6; // 17%
  uint256 internal constant CURVE_TIME_A = 2e7; // 0.2
  uint256 internal constant CURVE_PRICE_N = 3; // 300%
  uint256 internal constant CURVE_PRICE_A = 1;

  /* Oracle */
  uint256 internal constant ORACLE_RESERVE_MINIMUM = 1e10; // 10,000 USDC
  uint256 internal constant DOLLAR_SPENDING_MAX = 5e16; // 5%

  /* Dollar spending power */
  uint256 internal constant MANUAL_START_CPI = 27301200000 * 1e10;
  uint256 internal constant MANUAL_CHANGE_LIMIT = 1160; // 0.116%
  uint256 internal constant NEXT_SPENDING_UPDATE = 720;
  bool internal constant ONLY_MANUAL_CPI = true;
  uint256 internal constant VALIDATE_TOLERANCE_CPI = 20e18; // 20%
  address internal constant ORACLE_CPI_ADDRESS = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
  bytes32 internal constant ORACLE_CPI_JOB_ID = "6d1bfe27e7034b1d87b5270556b17277";
  uint256 internal constant ORACLE_CPI_FEE = 0.1 * 10 ** 18;
  address internal constant ORACLE_USDC_USD = 0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB;
  address internal constant ORACLE_LINK_ADDRESS = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import {SafeMath} from "../external/openzeppelin/contracts/math/SafeMath.sol";
import "./PoolData.sol";
import "./PoolGetters.sol";
import {AccountStore} from "../wallet/Data.sol";
import {Constants} from "../wallet/Constants.sol";

contract PoolSetters is PoolData, PoolGetters {
  /**
   * Global
   */
  function togglePauseRedeem() external onlyOwner {
    _data.paused.redeem = !_data.paused.redeem;
  }

  function togglePauseMint() external onlyOwner {
    _data.paused.mint = !_data.paused.mint;
  }

  function setPoolLimit(uint256 value) external onlyOwner {
    _data.poolLimit = value;
  }

  function setOwner(address _newOwner) external onlyOwner {
    _data.ownerAddress = _newOwner;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
import {IERC20} from "../external/openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVufi is IERC20 {
  function mint(address to, uint256 amount) external;
  function burn(uint256 amount) external;
  function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {AccountStore} from "./Data.sol";
import {Decimal} from "../external/Decimal.sol";

interface IWallet {
  function onlyManual() external pure returns (bool);
  function manualDollarSpending() external view returns (address);
  function chainDollarSpending() external view returns (address);
  function cycle() external view returns (uint256);
  function cycleTime() external virtual view returns (uint256);
  function mintFromPool(address account, uint256 amount) external;
  function burnFromPool(address account, uint256 amount) external;
  function vufi() external view returns (address);
  function chainUsdcUsd() external view returns (address);
  function statusOf(address account) external view returns (AccountStore.Status);
  function totalDebt() external view returns (uint256);
  function poolCollateralRange() external view returns (uint256);
  function poolExitLookup() external pure returns (uint256);
  function debtData() external view returns (uint256, uint256, uint256);
  function poolRedemptionDelay() external view returns (uint256);
  function manualChangeLimit() external view returns (uint256);
  function dollarSpendingMax() external pure returns (Decimal.D256 memory);
  function lockedUntil(address account) external view returns (uint256);
  function setLockedUntil(address account, uint256 lockedUntil) external;
  function upgradeFromGovernance(address newImplementation) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import {SafeMath} from "./openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
  using SafeMath for uint256;

  // ============ Constants ============

  uint256 internal constant BASE = 10 ** 18;

  // ============ Structs ============


  struct D256 {
    uint256 value;
  }

  // ============ Static Functions ============

  function zero()
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : 0});
  }

  function one()
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : BASE});
  }

  function from(
    uint256 a
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : a.mul(BASE)});
  }

  function ratio(
    uint256 a,
    uint256 b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : getPartial(a, BASE, b)});
  }

  // ============ Self Functions ============

  function add(
    D256 memory self,
    uint256 b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : self.value.add(b.mul(BASE))});
  }

  function sub(
    D256 memory self,
    uint256 b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : self.value.sub(b.mul(BASE))});
  }

  function sub(
    D256 memory self,
    uint256 b,
    string memory reason
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : self.value.sub(b.mul(BASE), reason)});
  }

  function mul(
    D256 memory self,
    uint256 b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : self.value.mul(b)});
  }

  function div(
    D256 memory self,
    uint256 b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : self.value.div(b)});
  }

  function pow(
    D256 memory self,
    uint256 b
  )
  internal
  pure
  returns (D256 memory)
  {
    if (b == 0) {
      return from(1);
    }

    D256 memory temp = D256({value : self.value});
    for (uint256 i = 1; i < b; i++) {
      temp = mul(temp, self);
    }

    return temp;
  }

  function add(
    D256 memory self,
    D256 memory b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : self.value.add(b.value)});
  }

  function sub(
    D256 memory self,
    D256 memory b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : self.value.sub(b.value)});
  }

  function sub(
    D256 memory self,
    D256 memory b,
    string memory reason
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : self.value.sub(b.value, reason)});
  }

  function mul(
    D256 memory self,
    D256 memory b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : getPartial(self.value, b.value, BASE)});
  }

  function div(
    D256 memory self,
    D256 memory b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : getPartial(self.value, BASE, b.value)});
  }

  function equals(D256 memory self, D256 memory b) internal pure returns (bool) {
    return self.value == b.value;
  }

  function greaterThan(D256 memory self, D256 memory b) internal pure returns (bool) {
    return compareTo(self, b) == 2;
  }

  function lessThan(D256 memory self, D256 memory b) internal pure returns (bool) {
    return compareTo(self, b) == 0;
  }

  function greaterThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
    return compareTo(self, b) > 0;
  }

  function lessThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
    return compareTo(self, b) < 2;
  }

  function isZero(D256 memory self) internal pure returns (bool) {
    return self.value == 0;
  }

  function asUint256(D256 memory self) internal pure returns (uint256) {
    return self.value.div(BASE);
  }

  // ============ Core Methods ============

  function getPartial(
    uint256 target,
    uint256 numerator,
    uint256 denominator
  )
  private
  pure
  returns (uint256)
  {
    return target.mul(numerator).div(denominator);
  }

  function compareTo(
    D256 memory a,
    D256 memory b
  )
  private
  pure
  returns (uint256)
  {
    if (a.value == b.value) {
      return 1;
    }
    return a.value > b.value ? 2 : 0;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

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

  constructor () {
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

pragma solidity 0.7.6;

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

pragma solidity 0.7.6;

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "../token/IVufi.sol";
import "../wallet/IWallet.sol";
import {IERC20} from "../external/openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PoolAccount {
  enum Status {
    Frozen,
    Fluid,
    Locked
  }

  struct State {
    uint256 fluidUntil;
  }
}

contract PoolEntrepotStore {
  struct Contracts {
    IWallet wallet;
    IERC20 vufi;
    IERC20 collateralToken;
    IERC20 univ2;
    address weth;
  }

  struct Paused {
    bool mint;
    bool redeem;
  }

  struct Balance {
    mapping (address => uint256) redeemCollateral;
    uint256 unclaimedPoolCollateral;
    mapping (address => uint256) lastRedeemed;
  }

  struct Data {
    Contracts contracts;
    Balance balance;
    Paused paused;
    address ownerAddress;
    uint256 poolLimit;
    uint256 missingDecimals;
    uint256 collateralDesiredPrice;
    uint256 pricePrecision;

    mapping(address => PoolAccount.State) accounts;
  }
}

contract PoolData {
  PoolEntrepotStore.Data internal _data;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import {SafeMath} from "../external/openzeppelin/contracts/math/SafeMath.sol";
import "./PoolData.sol";
import "../wallet/IWallet.sol";
import {IChainlinkPriceConsumer} from "../oracle/IChainlinkPriceConsumer.sol";

contract PoolGetters is PoolData {
  using SafeMath for uint256;

  /**
  * modifiers
  */
  modifier onlyOwner() {
    require(
      msg.sender == address(wallet()) || msg.sender == _data.ownerAddress,
      "Pool: Not wallet"
    );

    _;
  }

  modifier notMintPaused() {
    require(
      !mintPaused(),
      "Pool: mint paused"
    );

    _;
  }

  modifier notRedeemPaused() {
    require(
      !redeemPaused(),
      "Pool: redeem paused"
    );

    _;
  }

  modifier onlyFrozen(address account) {
    require(
      statusOf(account) == PoolAccount.Status.Frozen,
      "Pool: Not frozen"
    );

    _;
  }

  function redeemCollateralBalance(address account) external view returns (uint256) {
    return _data.balance.redeemCollateral[account];
  }

  function vufi() public view returns (address) {
    return address(_data.contracts.vufi);
  }

  function owner() public view returns (address) {
    return _data.ownerAddress;
  }

  function collateralToken() public view returns (address) {
    return address(_data.contracts.collateralToken);
  }

  function statusOf(address account) public view returns (PoolAccount.Status) {
    return cycle() >= _data.accounts[account].fluidUntil ?
    PoolAccount.Status.Frozen :
    PoolAccount.Status.Fluid;
  }

  /**
   * Global
  */
  function getCollateralPrice() external view returns (uint256) {
    return _chainlinkPrice();
  }

  /**
   * Struct Paused
  */
  function mintPaused() public view returns (bool) {
    return _data.paused.mint;
  }

  function redeemPaused() public view returns (bool) {
    return _data.paused.redeem;
  }

  function wallet() public view virtual returns (IWallet) {
    return IWallet(_data.contracts.wallet);
  }

  /**
  * Account
  */
  function fluidUntil(address account) public view returns (uint256) {
    return _data.accounts[account].fluidUntil;
  }

  /**
  * Cycle
  */
  function cycle() internal view returns (uint256) {
    return wallet().cycle();
  }

  /**
  * Oracle
  */
  function chainUsdcUsd() internal virtual view returns (address) {
    return wallet().chainUsdcUsd();
  }

  function _chainPricingCollateral() internal view returns(IChainlinkPriceConsumer) {
    return IChainlinkPriceConsumer(chainUsdcUsd());
  }

  function _chainlinkPrice() internal view returns (uint256) {
    uint8 _decimals = _chainPricingCollateral().getDecimals();
    return uint256(_chainPricingCollateral().getLatestPrice()).mul(_data.pricePrecision).div(uint256(10)**_decimals);
  }

  function poolCollateralRange() internal view returns (uint256) {
    return wallet().poolCollateralRange();
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "../token/IVufi.sol";
import "../oracle/IOracle.sol";
import "../external/IFractionalExponents.sol";
import {IGovernance} from "./IGovernance.sol";

contract RewardStore {
  struct Global {
    uint256 rate;
    uint256 stored;
    uint256 lastCycle;
    uint256 nextCycle;
  }
}

contract CycleStore {
  struct Global {
    uint256 start;
    uint256 period;
    uint256 current;
    uint256 nextCpi;
    uint256 lastCpi;
    uint256 belowPriceStart;
    bool belowPrice;
  }

  struct Coupons {
    uint256 outstanding;
  }

  struct Store {
    uint256 peged;
    uint256 rewards;
    uint256 pegToCoupons;
    Coupons coupons;
  }
}

contract AccountStore {
  enum Status {
    Frozen,
    Fluid,
    Locked
  }

  struct Store {
    uint256 deposited;
    uint256 balance;
    mapping(uint256 => uint256) coupons;
    mapping(address => uint256) couponAllowances;
    uint256 fluidUntil;
    uint256 lockedUntil;
    uint256 rewards;
    uint256 rewardsPaid;
  }
}

contract Implementation {
  struct Store {
    bool _initialized;
  }
}

contract EntrepotStore {
  struct Contracts {
    IVufi vufi;
    IOracle oracle;
    IGovernance governance;
    address exponents;
    address pool;
    address usdc;
    address gov;
    address vufiShares;
    address sharedPool;
    address factory;
    address chainUsdcUsd;
    address manualDollarSpending;
    address chainDollarSpending;
  }

  struct Balance {
    uint256 supply;
    uint256 peg;
    uint256 deposited;
    uint256 depositedShares;
    uint256 redeemable;
    uint256 debt;
    uint256 coupons;
    uint256 totalRewords;
    uint256 pegToCoupons;
  }

  struct DataJoin {
    Contracts contracts;
    Balance balance;
    CycleStore.Global cycle;
    RewardStore.Global reward;

    mapping(address => AccountStore.Store) accounts;
    mapping(uint256 => CycleStore.Store) cycles;
  }
}

contract Data {
  EntrepotStore.DataJoin internal _data;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "../external/Decimal.sol";

abstract contract IOracle {
  function setup() public virtual;
  function capture() public virtual returns (Decimal.D256 memory, bool);
  function pair() external virtual view returns (address);
  function targetPrice() external virtual view returns (Decimal.D256 memory);
  function updateDollarSpendingPower() public virtual returns (uint256);
  function setWallet(address wallet) external virtual;
  function setPair(address pair) external virtual;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

interface IFractionalExponents {
  function power(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) external view returns (uint256, uint8);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

interface IGovernance {
    function startFor(address proposal) external view returns (uint256);
    function periodFor(address proposal) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

interface IChainlinkPriceConsumer {
  function getLatestPrice() external view returns (int);
  function getDecimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

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