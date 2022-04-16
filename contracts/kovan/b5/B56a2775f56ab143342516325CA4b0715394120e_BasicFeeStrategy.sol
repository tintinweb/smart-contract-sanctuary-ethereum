// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SignedMath } from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import { SignedMathHelpers } from "../_utils/SignedMathHelpers.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IFeeStrategy } from "../_interfaces/IFeeStrategy.sol";
import { IPerpetualTranche } from "../_interfaces/IPerpetualTranche.sol";

/*
 *  @title BasicFeeStrategy
 *
 *  @notice Basic fee strategy using fixed percentage of perpetual ERC-20 token amounts.
 *
 *  @dev IMPORTANT: If mint or burn fee is negative, the other must overcompensate in the positive direction.
 *       Otherwise, user could extract from the fee collector by constant mint/burn transactions.
 */
contract BasicFeeStrategy is IFeeStrategy {
    using SignedMath for int256;
    using SignedMathHelpers for int256;
    using SafeCast for uint256;

    // @dev {10 ** PCT_DECIMALS} is considered 100%
    uint256 public constant PCT_DECIMALS = 6;

    // @notice Address of the parent perpetual ERC-20 token contract which uses this strategy.
    IPerpetualTranche public immutable perp;

    /// @inheritdoc IFeeStrategy
    IERC20 public immutable override feeToken;

    // @notice Fixed percentage of the mint amount to be used as fee.
    int256 public immutable mintFeePct;

    // @notice Fixed percentage of the burn amount to be used as fee.
    int256 public immutable burnFeePct;

    // @notice Fixed percentage of the fee collector's balance to be used as the fee,
    //         for rolling over the entire supply of the perp tokens.
    // @dev NOTE: This is different from the mint/burn fees which are just a percentage of
    //      the perp token amounts.
    int256 public immutable rolloverFeePct;

    // @dev Constructor for the fee strategy.
    // @param perp_ Address of the perpetual ERC-20 token contract.
    // @param feeToken_ Address of the fee ERC-20 token contract.
    // @param mintFeePct_ Mint fee percentage.
    // @param burnFeePct_ Burn fee percentage.
    // @param rolloverFeePct_ Rollover fee percentage.
    constructor(
        IPerpetualTranche perp_,
        IERC20 feeToken_,
        int256 mintFeePct_,
        int256 burnFeePct_,
        int256 rolloverFeePct_
    ) {
        perp = perp_;
        feeToken = feeToken_;
        mintFeePct = mintFeePct_;
        burnFeePct = burnFeePct_;
        rolloverFeePct = rolloverFeePct_;
    }

    /// @inheritdoc IFeeStrategy
    function computeMintFee(uint256 mintAmt) external view override returns (int256) {
        uint256 absoluteFee = (mintFeePct.abs() * mintAmt) / (10**PCT_DECIMALS);
        return mintFeePct.sign() * absoluteFee.toInt256();
    }

    /// @inheritdoc IFeeStrategy
    function computeBurnFee(uint256 burnAmt) external view override returns (int256) {
        uint256 absoluteFee = (burnFeePct.abs() * burnAmt) / (10**PCT_DECIMALS);
        return burnFeePct.sign() * absoluteFee.toInt256();
    }

    /// @inheritdoc IFeeStrategy
    function computeRolloverFee(uint256 rolloverAmt) external view override returns (int256) {
        uint256 share = (feeToken.balanceOf(perp.feeCollector()) * rolloverAmt) / perp.totalSupply();
        uint256 absoluteFee = (rolloverFeePct.abs() * share) / (10**PCT_DECIMALS);
        return rolloverFeePct.sign() * absoluteFee.toInt256();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/*
 *  @title SignedMathHelpers
 *
 *  @notice Library with helper functions for signed integer math.
 *
 */
library SignedMathHelpers {
    function sign(int256 a) internal pure returns (int256) {
        return (a > 0) ? int256(1) : ((a < 0) ? int256(-1) : int256(0));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: GPL-3.0-or-later

// solhint-disable-next-line compiler-version
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFeeStrategy {
    // @notice Address of the fee token.
    function feeToken() external view returns (IERC20);

    // @notice Computes the fee to mint given amount of perp tokens.
    // @dev Fee can be either positive or negative. When positive it's paid by the minting users to the system.
    //      When negative its paid to the minting users by the system.
    // @param amount The amount of perp tokens to be minted.
    // @return The mint fee in fee tokens.
    function computeMintFee(uint256 amount) external view returns (int256);

    // @notice Computes the fee to burn given amount of perp tokens.
    // @dev Fee can be either positive or negative. When positive it's paid by the burning users to the system.
    //      When negative its paid to the burning users by the system.
    // @param amount The amount of perp tokens to be burnt.
    // @return The burn fee in fee tokens.
    function computeBurnFee(uint256 amount) external view returns (int256);

    // @notice Computes the fee to rollover given amount of perp tokens.
    // @dev Fee can be either positive or negative. When positive it's paid by the users rolling over to the system.
    //      When negative its paid to the users rolling over by the system.
    // @param amount The Perp-denominated value of the tranches being rotated in.
    // @return The rollover fee in fee tokens.
    function computeRolloverFee(uint256 amount) external view returns (int256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

// solhint-disable-next-line compiler-version
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IBondIssuer } from "./IBondIssuer.sol";
import { IFeeStrategy } from "./IFeeStrategy.sol";
import { IPricingStrategy } from "./IPricingStrategy.sol";
import { IBondController } from "./buttonwood/IBondController.sol";
import { ITranche } from "./buttonwood/ITranche.sol";

interface IPerpetualTranche is IERC20 {
    //--------------------------------------------------------------------------
    // Events

    // @notice Event emitted when the bond issuer is updated.
    // @param issuer Address of the issuer contract.
    event UpdatedBondIssuer(IBondIssuer issuer);

    // @notice Event emitted when the fee strategy is updated.
    // @param strategy Address of the strategy contract.
    event UpdatedFeeStrategy(IFeeStrategy strategy);

    // @notice Event emitted when the pricing strategy is updated.
    // @param strategy Address of the strategy contract.
    event UpdatedPricingStrategy(IPricingStrategy strategy);

    // @notice Event emitted when maturity tolerance parameters are updated.
    // @param min The minimum maturity time.
    // @param max The maximum maturity time.
    event UpdatedTolerableTrancheMaturiy(uint256 min, uint256 max);

    // @notice Event emitted when the defined tranche yields are updated.
    // @param hash The tranche class hash.
    // @param yield The yield factor for any tranche belonging to that class.
    event UpdatedDefinedTrancheYields(bytes32 hash, uint256 yield);

    // @notice Event emitted when the applied yield for a given tranche is set.
    // @param tranche The address of the tranche token.
    // @param yield The yield factor applied.
    event TrancheYieldApplied(ITranche tranche, uint256 yield);

    // @notice Event emitted when a new tranche is added to the queue head.
    // @param strategy Address of the tranche added to the queue.
    event TrancheEnqueued(ITranche tranche);

    // @notice Event emitted when a tranche is removed from the queue tail.
    // @param strategy Address of the tranche removed from the queue.
    event TrancheDequeued(ITranche tranche);

    // @notice Event emitted the reserve's current token balance is recorded after change.
    // @param token Address of token.
    // @param balance The recorded ERC-20 balance of the token held by the reserve.
    event ReserveSynced(IERC20 token, uint256 balance);

    //--------------------------------------------------------------------------
    // Methods

    // @notice Deposits tranche tokens into the system and mint perp tokens.
    // @param trancheIn The address of the tranche token to be deposited.
    // @param trancheInAmt The amount of tranche tokens deposited.
    // @return mintAmt The amount of perp tokens minted to the caller.
    // @return fee The fee paid by the caller.
    function deposit(ITranche trancheIn, uint256 trancheInAmt) external returns (uint256 mintAmt, int256 mintFee);

    // @notice Redeem tranche tokens by burning perp tokens.
    // @param trancheOut The tranche token to be redeemed.
    // @param amountRequested The amount of perp tokens requested to be burnt.
    // @return burnAmt The amount of perp tokens burnt from the caller.
    // @return fee The fee paid by the caller.
    function redeem(ITranche trancheOut, uint256 amountRequested) external returns (uint256 burnAmt, int256 burnFee);

    // @notice Rotates newer tranches in for older tranches.
    // @param trancheIn The tranche token deposited.
    // @param trancheOut The tranche token to be redeemed.
    // @param trancheInAmt The amount of trancheIn tokens deposited.
    // @return trancheOutAmt The amount of trancheOut tokens redeemed.
    // @return rolloverFee The fee paid by the caller.
    function rollover(
        ITranche trancheIn,
        ITranche trancheOut,
        uint256 trancheInAmt
    ) external returns (uint256 trancheOutAmt, int256 rolloverFee);

    // @notice Burn perp tokens without redemption.
    // @param amount Amount of perp tokens to be burnt.
    // @return True if burn is successful.
    function burn(uint256 amount) external returns (bool);

    // @notice The parent bond whose tranches are currently accepted to mint perp tokens.
    // @return Address of the deposit bond.
    function getDepositBond() external returns (IBondController);

    // @notice Tranche up for redemption next.
    // @return Address of the tranche token.
    function getRedemptionTranche() external returns (ITranche);

    // @notice Total count of tokens in the redemption queue.
    function getRedemptionQueueCount() external returns (uint256);

    // @notice The token address from the redemption queue by index.
    // @param index The index of a token.
    function getRedemptionQueueAt(uint256 index) external returns (address);

    // @notice Checks if the given `trancheIn` can be rolled out for `trancheOut`.
    // @param trancheIn The tranche token deposited.
    // @param trancheOut The tranche token to be redeemed.
    function isAcceptableRollover(ITranche trancheIn, ITranche trancheOut) external returns (bool);

    // @notice The strategy contract with the fee computation logic.
    // @return Address of the strategy contract.
    function feeStrategy() external view returns (IFeeStrategy);

    // @notice The contract where the protocol holds funds which back the perp token supply.
    // @return Address of the reserve.
    function reserve() external view returns (address);

    // @notice The contract where the protocol holds the cash from fees.
    // @return Address of the fee collector.
    function feeCollector() external view returns (address);

    // @notice The fee token currently used to receive fees in.
    // @return Address of the fee token.
    function feeToken() external view returns (IERC20);

    // @notice The yield to be applied given the tranche.
    // @param tranche The address of the tranche token.
    // @return The yield applied.
    function trancheYield(ITranche tranche) external view returns (uint256);

    // @notice The computes the class hash of a given tranche.
    // @dev This is used to identify different tranche tokens instances of the same class.
    // @param tranche The address of the tranche token.
    // @return The class hash.
    function trancheClass(ITranche t) external view returns (bytes32);

    // @notice The price of the given tranche.
    // @param tranche The address of the tranche token.
    // @return The computed price.
    function tranchePrice(ITranche tranche) external view returns (uint256);

    // @notice Computes the amount of perp token amount that can be exchanged for given tranche and amount.
    // @param tranche The address of the tranche token.
    // @param trancheAmt The amount of tranche tokens.
    // @return The perp token amount.
    function tranchesToPerps(ITranche tranche, uint256 trancheAmt) external view returns (uint256);

    // @notice Computes the amount of tranche tokens amount that can be exchanged for given perp token amount.
    // @param tranche The address of the tranche token.
    // @param trancheAmt The amount of perp tokens.
    // @return The tranche token amount.
    function perpsToTranches(ITranche tranche, uint256 amount) external view returns (uint256);

    // @notice Computes the maximum amount of tranche tokens amount that
    //         can be exchanged for the requested perp token amount covered by the systems tranche balance.
    //         If the system doesn't have enough tranche tokens to cover the exchange,
    //         it computes the remainder perp tokens which cannot be exchanged.
    // @param tranche The address of the tranche token.
    // @param amountRequested The amount of perp tokens to exchange.
    // @param trancheAmtCovered The maximum tranche amount covered the exchange.
    // @return trancheAmtUsed The tranche tokens used for the exchange.
    // @return remainder The number of perp tokens which cannot be exchanged.
    function perpsToCoveredTranches(
        ITranche tranche,
        uint256 amountRequested,
        uint256 trancheAmtCovered
    ) external view returns (uint256 trancheAmtUsed, uint256 remainder);

    // @notice Total count of tokens held in the reserve.
    function reserveCount() external view returns (uint256);

    // @notice The token address from the reserve list by index.
    // @param index The index of a token.
    function reserveAt(uint256 index) external view returns (address);

    // @notice Checks if the given token is part of the reserve list.
    // @param token The address of a token to check.
    function inReserve(IERC20 token) external view returns (bool);

    // @notice Updates time dependent queue state.
    function updateQueue() external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

// solhint-disable-next-line compiler-version
import { IBondController } from "./buttonwood/IBondController.sol";

interface IBondIssuer {
    /// @notice Event emitted when a new bond is issued by the issuer.
    /// @param bond The newly issued bond.
    event BondIssued(IBondController bond);

    // @notice Issues a new bond if sufficient time has elapsed since the last issue.
    function issue() external;

    // @notice Checks if a given bond has been issued by the issuer.
    // @param Address of the bond to check.
    // @return if the bond has been issued by the issuer.
    function isInstance(IBondController bond) external view returns (bool);

    // @notice Fetches the most recently issued bond.
    // @return Address of the most recent bond.
    function getLatestBond() external returns (IBondController);

    // @notice Returns the total number of bonds issued by this issuer.
    // @return Number of bonds.
    function totalIssued() external view returns (uint256);

    // @notice The bond address from the issued list by index.
    // @return Address of the bond.
    function issuedBondAt(uint256 index) external view returns (IBondController);
}

// SPDX-License-Identifier: GPL-3.0-or-later

// solhint-disable-next-line compiler-version
import { ITranche } from "./buttonwood/ITranche.sol";

interface IPricingStrategy {
    // @notice Computes the price of a given tranche.
    // @param tranche The tranche to compute price of.
    // @return The price as a fixed point number with `decimals()`.
    function computeTranchePrice(ITranche tranche) external view returns (uint256);

    // @notice Number of price decimals.
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0-or-later

// solhint-disable-next-line compiler-version
import { ITranche } from "./ITranche.sol";

interface IBondController {
    function collateralToken() external view returns (address);

    function maturityDate() external view returns (uint256);

    function creationDate() external view returns (uint256);

    function totalDebt() external view returns (uint256);

    function feeBps() external view returns (uint256);

    function isMature() external view returns (bool);

    function tranches(uint256 i) external view returns (ITranche token, uint256 ratio);

    function trancheCount() external view returns (uint256 count);

    function deposit(uint256 amount) external;

    function redeem(uint256[] memory amounts) external;

    function mature() external;

    function redeemMature(address tranche, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

// solhint-disable-next-line compiler-version
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITranche is IERC20 {
    function bond() external view returns (address);
}