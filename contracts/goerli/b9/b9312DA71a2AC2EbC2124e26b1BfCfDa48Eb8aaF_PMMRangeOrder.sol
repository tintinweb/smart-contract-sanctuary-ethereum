// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

library Errors {
    string public constant NOT_ALLOWED_LIQUIDATOR = "D3MM_NOT_ALLOWED_LIQUIDATOR";
    string public constant NOT_ALLOWED_ROUTER = "D3MM_NOT_ALLOWED_ROUTER";
    string public constant POOL_NOT_ONGOING = "D3MM_POOL_NOT_ONGOING";
    string public constant POOL_NOT_LIQUIDATING = "D3MM_POOL_NOT_LIQUIDATING";
    string public constant POOL_NOT_END = "D3MM_POOL_NOT_END";
    string public constant TOKEN_NOT_EXIST = "D3MM_TOKEN_NOT_EXIST";
    string public constant TOKEN_ALREADY_EXIST = "D3MM_TOKEN_ALREADY_EXIST";
    string public constant EXCEED_DEPOSIT_LIMIT = "D3MM_EXCEED_DEPOSIT_LIMIT";
    string public constant EXCEED_QUOTA = "D3MM_EXCEED_QUOTA";
    string public constant BELOW_IM_RATIO = "D3MM_BELOW_IM_RATIO";
    string public constant TOKEN_NOT_ON_WHITELIST = "D3MM_TOKEN_NOT_ON_WHITELIST";
    string public constant LATE_TO_CHANGE_EPOCH = "D3MM_LATE_TO_CHANGE_EPOCH";
    string public constant POOL_ALREADY_CLOSED = "D3MM_POOL_ALREADY_CLOSED";
    string public constant BALANCE_NOT_ENOUGH = "D3MM_BALANCE_NOT_ENOUGH";
    string public constant TOKEN_IS_OFFLIST = "D3MM_TOKEN_IS_OFFLIST";
    string public constant ABOVE_MM_RATIO = "D3MM_ABOVE_MM_RATIO";
    string public constant WRONG_MM_RATIO = "D3MM_WRONG_MM_RATIO";
    string public constant WRONG_IM_RATIO = "D3MM_WRONG_IM_RATIO";
    string public constant NOT_IN_LIQUIDATING = "D3MM_NOT_IN_LIQUIDATING";
    string public constant NOT_PASS_DEADLINE = "D3MM_NOT_PASS_DEADLINE";
    string public constant DISCOUNT_EXCEED_5 = "D3MM_DISCOUNT_EXCEED_5";
    string public constant MINRES_NOT_ENOUGH = "D3MM_MINRESERVE_NOT_ENOUGH";
    string public constant MAXPAY_NOT_ENOUGH = "D3MM_MAXPAYAMOUNT_NOT_ENOUGH";
    string public constant LIQUIDATION_NOT_DONE = "D3MM_LIQUIDATION_NOT_DONE";
    string public constant ROUTE_FAILED = "D3MM_ROUTE_FAILED";
    string public constant TOKEN_NOT_MATCH = "D3MM_TOKEN_NOT_MATCH";
    string public constant ASK_AMOUNT_EXCEED = "D3MM_ASK_AMOUTN_EXCEED";
    string public constant K_LIMIT = "D3MM_K_LIMIT_ERROR";
    string public constant ARRAY_NOT_MATCH = "D3MM_ARRAY_NOT_MATCH";
    string public constant WRONG_EPOCH_DURATION = "D3MM_WRONG_EPOCH_DURATION";
    string public constant WRONG_EXCUTE_EPOCH_UPDATE_TIME = "D3MM_WRONG_EXCUTE_EPOCH_UPDATE_TIME";
    string public constant INVALID_EPOCH_STARTTIME = "D3MM_INVALID_EPOCH_STARTTIME";
    string public constant PRICE_UP_BELOW_PRICE_DOWN = "D3MM_PRICE_UP_BELOW_PRICE_DOWN";
    string public constant AMOUNT_TOO_SMALL = "D3MM_AMOUNT_TOO_SMALL";
    string public constant FROMAMOUNT_NOT_ENOUGH = "D3MM_FROMAMOUNT_NOT_ENOUGH";
    string public constant HEARTBEAT_CHECK_FAIL = "D3MM_HEARTBEAT_CHECK_FAIL";
    string public constant HAVE_SET_TOKEN_INFO = "D3MM_HAVE_SET_TOKEN_INFO";
    
    string public constant RO_ORACLE_PROTECTION = "PMMRO_ORACLE_PRICE_PROTECTION";
    string public constant RO_VAULT_RESERVE = "PMMRO_VAULT_RESERVE_NOT_ENOUGH";
    string public constant RO_AMOUNT_ZERO = "PMMRO_AMOUNT_ZERO";
    string public constant RO_PRICE_ZERO = "PMMRO_PRICE_ZERO";
    
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

import { DecimalMath } from "../../lib/DecimalMath.sol";
import { DODOMath } from "../../lib/DODOMath.sol";

/**
 * @title PMMPricing
 * @author DODO Breeder
 *
 * @notice DODO Pricing model
 */
library PMMPricing {

    struct PMMState {
        uint256 i;
        uint256 K;
        uint256 B;
        uint256 B0;
        uint256 BMaxAmount;
    }

    function _queryBuyBaseToken(PMMState memory state, uint256 amount)
        internal
        pure
        returns (uint256 payQuote)
    {
        payQuote = _RAboveBuyBaseToken(state, amount, state.B, state.B0);
    }

    function _querySellQuoteToken(PMMState memory state, uint256 payQuoteAmount)
        internal
        pure
        returns (uint256 receiveBaseAmount)
    {
        receiveBaseAmount = _RAboveSellQuoteToken(state, payQuoteAmount);
    }


    // ============ R > 1 cases ============

    function _RAboveBuyBaseToken(
        PMMState memory state,
        uint256 amount,
        uint256 baseBalance,
        uint256 targetBaseAmount
    ) internal pure returns (uint256 payQuoteToken) {
        require(amount < baseBalance, "DODOstate.BNOT_ENOUGH");
        uint256 B2 = baseBalance - amount;
        return 
            DODOMath._GeneralIntegrate(
                targetBaseAmount, 
                baseBalance, 
                B2, 
                state.i, 
                state.K
            );
    }

    function _RAboveSellQuoteToken(PMMState memory state, uint256 payQuoteAmount)
        internal
        pure
        returns (
            uint256 receiveBaseToken
        )
    {
        return
            DODOMath._SolveQuadraticFunctionForTrade(
                state.B0,
                state.B,
                payQuoteAmount,
                DecimalMath.reciprocalFloor(state.i),
                state.K
            );
    }
}

/*

    Copyright 2022 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

library Types {
    struct D3MMState {
        // tokens in the pool
        address[] tokenList;
        // token => AssetInfo, including dToken, reserve, max deposit, accrued interest
        mapping(address => AssetInfo) assetInfo;
        // token => interest rate
        mapping(address => uint256) interestRate;
        // token => liquidation target amount
        mapping(address => uint256) liquidationTarget;
        // token => amount, how many token can owner withdraw after pool end
        mapping(address => uint256) ownerBalanceAfterPoolEnd;
        // the last time of updating accrual of interest
        uint256 accrualTimestamp;
        // the D3Factory contract
        address _D3_FACTORY_;
        // the UserQuota contract
        address _USER_QUOTA_;
        // the creator of pool
        address _CREATOR_;
        // the start time of first epoch
        uint256 _EPOCH_START_TIME_;
        // the epoch duration
        uint256 _EPOCH_DURATION_;
        // use oracle to get token price
        address _ORACLE_;
        // when collateral ratio below IM, owner cannot withdraw, LPs cannot deposit
        uint256 _INITIAL_MARGIN_RATIO_;
        // when collateral ratio below MM, pool is going to be liquidated
        uint256 _MAINTENANCE_MARGIN_RATIO_;
        // swap maintainer
        address _MAINTAINER_;
        // swap fee model
        address _MT_FEE_RATE_MODEL_;
        // all pending LP withdraw requests
        WithdrawInfo[] pendingWithdrawList;
        // record next epoch interest rates and timestamp
        Epoch nextEpoch;
        // the current status of pool, including Ongoing, Liquidating, End
        PoolStatus _POOL_STATUS_;
        // record market maker last time updating pool
        HeartBeat heartBeat;
        // price list to package prices in one slot
        PriceListInfo priceListInfo;
        // =============== Swap Storage =================

        mapping(address => TokenMMInfo) tokenMMInfoMap;
    }

    struct AssetInfo {
        address d3Token;
        uint256 reserve;
        uint256 maxDepositAmount;
        uint256 accruedInterest;
    }

    // epoch info
    struct Epoch {
        // epoch start time
        uint256 timestamp;
        // token => interest rate
        mapping(address => uint256) interestRate;
    }

    // LP withdraw request
    struct WithdrawInfo {
        // request id, a hash of lp address + deadline timestamp
        bytes32 requestId;
        // refund deadline, if owner hasn't refunded after this time, liquidator can force refund
        uint256 deadline;
        // user who requests withdrawing
        address user;
        // the token to be withdrawn
        address token;
        // this amount of D3Token will be locked after user submit withdraw request,
        // but will still generate interest during pending time
        uint256 d3TokenAmount;
    }

    // liquidation swap info
    struct LiquidationOrder {
        address fromToken;
        address toToken;
        uint256 fromAmount;
    }

    struct TokenMMInfo {
        // [ask price down(16) | ask price offSet + (16) | ask price down decimal(8) | bid price down(16) |  bid price offSet + (16) | bid price up decimal(8)]
        uint96 priceInfo;
        // [ask amounts(16) | ask amounts decimal(8) | bid amounts(16) | bid amounts decimal(8) ]
        uint64 amountInfo;
        // k is [0, 10000]
        uint16 kAsk;
        uint16 kBid;
        // [timeStamp | cumulativeflag = 0 or 1(1 bit)]
        uint64 updateTimestamp;
        uint256 cumulativeBid;
        uint256 cumulativeAsk;
    }

    // package three token price in one slot
    struct PriceListInfo {
        // odd for none-stable, even for stable,  true index = tokenIndex[address] / 2
        mapping(address => uint256) tokenIndexMap;
        uint256 numberOfNS; // quantity of not stable token
        uint256 numberOfStable; // quantity of stable token
        // [ask price down(16) | ask price offSet + (16) | ask price decimal (8)| bid price down(16) | bid price offSet + (16) | bid price decimal(8)] = 80 bit
        // one slot contain = 80 * 3, 3 token price
        // [2 | 1 | 0]
        uint256[] tokenPriceNS; // not stable token price
        uint256[] tokenPriceStable; // stable token price
    }

    struct HeartBeat {
        uint256 lastHeartBeat;
        uint256 maxInterval;
    }

    uint16 internal constant ONE_PRICE_BIT = 40;
    uint256 internal constant PRICE_QUANTITY_IN_ONE_SLOT = 3;
    uint16 internal constant ONE_AMOUNT_BIT = 24;
    uint256 internal constant SECONDS_PER_YEAR = 31536000;
    uint256 internal constant ONE = 10**18;

    // [ask amounts(16) | ask amounts decimal(8) | bid amounts(16) | bid amounts decimal(8) ]
    function parseAskAmount(uint64 amountSet)
        internal
        pure
        returns (uint256 amountWithDecimal)
    {
        uint256 askAmount = (amountSet >> (ONE_AMOUNT_BIT + 8)) & 0xffff;
        uint256 askAmountDecimal = (amountSet >> ONE_AMOUNT_BIT) & 255;
        amountWithDecimal = askAmount * (10**askAmountDecimal);
    }

    // [ask amounts(16) | ask amounts decimal(8) | bid amounts(16) | bid amounts decimal(8) ]
    function parseBidAmount(uint64 amountSet)
        internal
        pure
        returns (uint256 amountWithDecimal)
    {
        uint256 bidAmount = (amountSet >> 8) & 0xffff;
        uint256 bidAmountDecimal = amountSet & 255;
        amountWithDecimal = bidAmount * (10**bidAmountDecimal);
    }

    // [ask price down(16) | ask price offSet + (16) | ask price decimal (8)| bid price down(16) | bid price offSet + (16) | bid price decimal(8)]
    function parseAskPrice(uint96 priceSet)
        internal
        pure
        returns (uint256 askDownPriceWithDecimal, uint256 askUpPriceWithDecimal)
    {
        uint256 askDownPrice = (priceSet >> (ONE_PRICE_BIT + 24)) & 0xffff;
        uint256 askPriceOffset = (priceSet >> (ONE_PRICE_BIT + 8)) & 0xffff;
        uint256 askDownPriceDecimal = (priceSet >> (ONE_PRICE_BIT)) & 255;
        uint256 askUpPrice = (askDownPrice + askPriceOffset) < type(uint16).max
            ? askDownPrice + askPriceOffset
            : 0;
        uint256 askUpPriceDecimal = askDownPriceDecimal;
        askDownPriceWithDecimal = askDownPrice * (10**askDownPriceDecimal);
        askUpPriceWithDecimal = askUpPrice * (10**askUpPriceDecimal);
    }

    // [ask price down(16) | ask price offSet + (16) | ask price decimal (8)| bid price down(16) | bid price offSet + (16) | bid price decimal(8)]
    function parseBidPrice(uint96 priceSet)
        internal
        pure
        returns (uint256 bidDownPriceWithDecimal, uint256 bidUpPriceWithDecimal)
    {
        uint256 bidDownPrice = (priceSet >> 24) & 0xffff;
        uint256 bidPriceOffset = (priceSet >> 8) & 0xffff;
        uint256 bidDownPriceDecimal = priceSet & 255;
        uint256 bidUpPrice = (bidDownPrice + bidPriceOffset) < type(uint16).max
            ? bidDownPrice + bidPriceOffset
            : 0;
        uint256 bidUpPriceDecimal = bidDownPriceDecimal;
        bidDownPriceWithDecimal = bidDownPrice * (10**bidDownPriceDecimal);
        bidUpPriceWithDecimal = bidUpPrice * (10**bidUpPriceDecimal);
    }

    function parseK(uint16 originK) internal pure returns (uint256) {
        return uint256(originK) * (10**14);
    }

    struct RangeOrderState {
        address oracle;
        TokenMMInfo fromTokenMMInfo;
        TokenMMInfo toTokenMMInfo;
    }

    enum PoolStatus {
        Ongoing,
        Liquidating,
        End
    }
}

/*

    Copyright 2022 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

import "../lib/PMMPricing.sol";
import "../lib/Errors.sol";
import "../lib/Types.sol";
import {ID3Oracle} from "../../intf/ID3Oracle.sol";

library PMMRangeOrder {
    uint256 internal constant ONE = 10**18;

    // use fromToken bid curve and toToken ask curve
    function querySellTokens(
        Types.RangeOrderState memory roState,
        address fromToken,
        address toToken,
        uint256 fromTokenAmount
    )
        public
        view
        returns (
            uint256 fromAmount,
            uint256 receiveToToken,
            uint256 vusdAmount
        )
    {
        // contruct fromToken state and swap to vUSD
        uint256 receiveVUSD;
        {
            PMMPricing.PMMState memory fromTokenState = _contructTokenState(
                roState,
                true,
                false
            );
            receiveVUSD = PMMPricing._querySellQuoteToken(
                fromTokenState,
                fromTokenAmount
            );
        }

        // construct toToken state and swap from vUSD to toToken
        {
            PMMPricing.PMMState memory toTokenState = _contructTokenState(
                roState,
                false,
                true
            );
            receiveToToken = PMMPricing._querySellQuoteToken(
                toTokenState,
                receiveVUSD
            );
        }

        // oracle protect
        {
            uint256 oracleToAmount = ID3Oracle(roState.oracle).getMaxReceive(
                fromToken,
                toToken,
                fromTokenAmount
            );
            require(
                oracleToAmount >= receiveToToken,
                Errors.RO_ORACLE_PROTECTION
            );
        }
        return (fromTokenAmount, receiveToToken, receiveVUSD);
    }

    // use fromToken bid curve and toToken ask curve
    function queryBuyTokens(
        Types.RangeOrderState memory roState,
        address fromToken,
        address toToken,
        uint256 toTokenAmount
    )
        public
        view
        returns (
            uint256 payFromToken,
            uint256 toAmount,
            uint256 vusdAmount
        )
    {
        // contruct fromToken to vUSD
        uint256 payVUSD;
        {
            PMMPricing.PMMState memory toTokenState = _contructTokenState(
                roState,
                false,
                true
            );
            // vault reserve protect
            require(
                toTokenAmount <=
                    toTokenState.BMaxAmount -
                        roState.toTokenMMInfo.cumulativeAsk,
                Errors.RO_VAULT_RESERVE
            );
            payVUSD = PMMPricing._queryBuyBaseToken(
                toTokenState,
                toTokenAmount
            );
        }

        // construct vUSD to toToken
        {
            PMMPricing.PMMState memory fromTokenState = _contructTokenState(
                roState,
                true,
                false
            );
            payFromToken = PMMPricing._queryBuyBaseToken(
                fromTokenState,
                payVUSD
            );
        }

        // oracle protect
        {
            uint256 oracleToAmount = ID3Oracle(roState.oracle).getMaxReceive(
                fromToken,
                toToken,
                payFromToken
            );
            require(
                oracleToAmount >= toTokenAmount,
                Errors.RO_ORACLE_PROTECTION
            );
        }

        return (payFromToken, toTokenAmount, payVUSD);
    }

    // ========= internal ==========
    function _contructTokenState(
        Types.RangeOrderState memory roState,
        bool fromTokenOrNot,
        bool askOrNot
    ) internal pure returns (PMMPricing.PMMState memory tokenState) {
        Types.TokenMMInfo memory tokenMMInfo = fromTokenOrNot
            ? roState.fromTokenMMInfo
            : roState.toTokenMMInfo;

        // bMax,k
        tokenState.BMaxAmount = _calSlotAmountInfo(
            tokenMMInfo.amountInfo,
            askOrNot
        );
        // amount = 0 protection
        require(tokenState.BMaxAmount > 0, Errors.RO_AMOUNT_ZERO);
        tokenState.K = askOrNot
            ? Types.parseK(tokenMMInfo.kAsk)
            : Types.parseK(tokenMMInfo.kBid);

        // i, B0
        uint256 upPrice;
        (tokenState.i, upPrice) = _calSlotPriceInfo(
            tokenMMInfo.priceInfo,
            askOrNot
        );
        // price = 0 protection
        require(tokenState.i > 0, Errors.RO_PRICE_ZERO);
        tokenState.B0 = _calB0WithPriceLimit(
            upPrice,
            tokenState.K,
            tokenState.i,
            tokenState.BMaxAmount
        );
        // B
        tokenState.B = askOrNot
            ? tokenState.B0 - tokenMMInfo.cumulativeAsk
            : tokenState.B0 - tokenMMInfo.cumulativeBid;

        return tokenState;
    }

    // P_up = i(1 - k + k*(B0 / B0 - amount)^2), record amount = A
    // (P_up + i*k - 1) / i*k = (B0 / B0 - A)^2
    // B0 = A + A / (sqrt((P_up + i*k - i) / i*k) - 1)
    // i = priceDown
    function _calB0WithPriceLimit(
        uint256 priceUp,
        uint256 k,
        uint256 i,
        uint256 amount
    ) internal pure returns (uint256 baseTarget) {
        // (P_up + i*k - i)
        // temp1 = PriceUp + DecimalMath.mul(i, k) - i
        // temp1 price

        // i*k
        // temp2 = DecimalMath.mul(i, k)
        // temp2 price

        // (P_up + i*k - i)/i*k
        // temp3 = DecimalMath(temp1, temp2)
        // temp3 ONE

        // temp4 = sqrt(temp3 * ONE)
        // temp4 ONE

        // temp5 = temp4 - ONE
        // temp5 ONE

        // B0 = amount + DecimalMath.div(amount, temp5)
        // B0 amount
        if (k == 0) baseTarget = amount;
        else {
            uint256 temp1 = priceUp + DecimalMath.mul(i, k) - i;
            uint256 temp3 = DecimalMath.div(temp1, DecimalMath.mul(i, k));
            uint256 temp5 = DecimalMath.sqrt(temp3) - ONE;
            baseTarget = amount + DecimalMath.div(amount, temp5);
        }
    }

    // [ask amounts(16) | ask amounts decimal(8) | bid amounts(16) | bid amounts decimal(8) ]
    function _calSlotAmountInfo(uint64 amountSet, bool askOrNot)
        internal
        pure
        returns (uint256 amountWithDecimal)
    {
        amountWithDecimal = askOrNot
            ? Types.parseAskAmount(amountSet)
            : Types.parseBidAmount(amountSet);
    }

    // [ask price down(16) | ask price down decimal (8) | ask price up(16) | ask price up decimal(8) | bid price down(16) | bid price down decimal(8) | bid price up(16) | bid price up decimal(8)]
    function _calSlotPriceInfo(uint96 priceSet, bool askOrNot)
        internal
        pure
        returns (uint256, uint256)
    {
        (uint256 downPrice, uint256 upPrice) = askOrNot
            ? Types.parseAskPrice(priceSet)
            : Types.parseBidPrice(priceSet);
        require(upPrice > downPrice, Errors.PRICE_UP_BELOW_PRICE_DOWN);
        return (downPrice, upPrice);
    }
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

interface ID3Oracle {
    function getMaxReceive(address fromToken, address toToken, uint256 fromAmount) external view returns(uint256);
    function getPrice(address base) external view returns (uint256);  
    function isFeasible(address base) external view returns (bool); 
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;


import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title DecimalMath
 * @author DODO Breeder
 *
 * @notice Functions for fixed point number with 18 decimals
 */

library DecimalMath {

    uint256 internal constant ONE = 10**18;
    uint256 internal constant ONE2 = 10**36;

    function mul(uint256 target, uint256 d) internal pure returns (uint256) {
        return target * d / (10**18);
    }

    function mulFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target * d / (10**18);
    }

    function mulCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return _divCeil(target * d, 10**18);
    }

    function div(uint256 target, uint256 d) internal pure returns (uint256) {
        return target * (10**18) / d;
    }

    function divFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target * (10**18) / d;
    }

    function divCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return _divCeil(target * (10**18), d);
    }

    function reciprocalFloor(uint256 target) internal pure returns (uint256) {
        return uint256(10**36) / target;
    }

    function reciprocalCeil(uint256 target) internal pure returns (uint256) {
        return _divCeil(uint256(10**36), target);
    }

    function sqrt(uint256 target) internal pure returns (uint256) {
        return Math.sqrt(target * ONE);
    }

    function powFloor(uint256 target, uint256 e) internal pure returns (uint256) {
        if (e == 0) {
            return 10 ** 18;
        } else if (e == 1) {
            return target;
        } else {
            uint p = powFloor(target, e / 2);
            p = p * p / (10**18);
            if (e % 2 == 1) {
                p = p * target / (10**18);
            }
            return p;
        }
    }

    function _divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = a / b;
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

import { DecimalMath } from "./DecimalMath.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title DODOMath
 * @author DODO Breeder
 *
 * @notice Functions for complex calculating. Including ONE Integration and TWO Quadratic solutions
 */
library DODOMath {

    /*
        Integrate dodo curve from V1 to V2
        require V0>=V1>=V2>0
        res = (1-k)i(V1-V2)+ikV0*V0(1/V2-1/V1)
        let V1-V2=delta
        res = i*delta*(1-k+k(V0^2/V1/V2))

        i is the price of V-res trading pair

        support k=1 & k=0 case

        [round down]
    */
    function _GeneralIntegrate(
        uint256 V0,
        uint256 V1,
        uint256 V2,
        uint256 i,
        uint256 k
    ) internal pure returns (uint256) {
        require(V0 > 0, "TARGET_IS_ZERO");
        uint256 fairAmount = i * (V1 - V2); // i*delta
        if (k == 0) {
            return fairAmount / DecimalMath.ONE;
        }
        uint256 V0V0V1V2 = DecimalMath.divFloor(V0 * V0 / V1, V2);
        uint256 penalty = DecimalMath.mulFloor(k, V0V0V1V2); // k(V0^2/V1/V2)
        return (DecimalMath.ONE - k + penalty) * fairAmount / DecimalMath.ONE2;
    }

    /*
        Follow the integration expression above, we have:
        i*deltaB = (Q2-Q1)*(1-k+kQ0^2/Q1/Q2)
        Given Q1 and deltaB, solve Q2
        This is a quadratic function and the standard version is
        aQ2^2 + bQ2 + c = 0, where
        a=1-k
        -b=(1-k)Q1-kQ0^2/Q1+i*deltaB
        c=-kQ0^2 
        and Q2=(-b+sqrt(b^2+4(1-k)kQ0^2))/2(1-k)
        note: another root is negative, abondan

        if deltaBSig=true, then Q2>Q1, user sell Q and receive B
        if deltaBSig=false, then Q2<Q1, user sell B and receive Q
        return |Q1-Q2|

        as we only support sell amount as delta, the deltaB is always negative
        the input ideltaB is actually -ideltaB in the equation

        i is the price of delta-V trading pair

        support k=1 & k=0 case

        [round down]
    */
    function _SolveQuadraticFunctionForTrade(
        uint256 V0,
        uint256 V1,
        uint256 delta,
        uint256 i,
        uint256 k
    ) internal pure returns (uint256) {
        require(V0 > 0, "TARGET_IS_ZERO");
        if (delta == 0) {
            return 0;
        }

        if (k == 0) {
            // why v1
            return DecimalMath.mulFloor(i, delta) > V1 ? V1 : DecimalMath.mulFloor(i, delta);
        }

        if (k == DecimalMath.ONE) {
            // if k==1
            // Q2=Q1/(1+ideltaBQ1/Q0/Q0)
            // temp = ideltaBQ1/Q0/Q0
            // Q2 = Q1/(1+temp)
            // Q1-Q2 = Q1*(1-1/(1+temp)) = Q1*(temp/(1+temp))
            // uint256 temp = i.mul(delta).mul(V1).div(V0.mul(V0));
            uint256 temp;
            uint256 idelta = i * (delta);
            if (idelta == 0) {
                temp = 0;
            } else if ((idelta * V1) / idelta == V1) {
                temp = (idelta * V1) / (V0*(V0));
            } else {
                temp = delta * (V1) / (V0)* (i) / (V0);
            }
            return V1 * (temp) / (temp + (DecimalMath.ONE));
        }

        // calculate -b value and sig
        // b = kQ0^2/Q1-i*deltaB-(1-k)Q1
        // part1 = (1-k)Q1 >=0
        // part2 = kQ0^2/Q1-i*deltaB >=0
        // bAbs = abs(part1-part2)
        // if part1>part2 => b is negative => bSig is false
        // if part2>part1 => b is positive => bSig is true
        uint256 part2 = k*(V0)/(V1)*(V0) + (i* (delta)); // kQ0^2/Q1-i*deltaB 
        uint256 bAbs = (DecimalMath.ONE-k) * (V1); // (1-k)Q1

        bool bSig;
        if (bAbs >= part2) {
            bAbs = bAbs - part2;
            bSig = false;
        } else {
            bAbs = part2 - bAbs;
            bSig = true;
        }
        bAbs = bAbs / (DecimalMath.ONE);

        // calculate sqrt
        uint256 squareRoot =
            DecimalMath.mulFloor(
                (DecimalMath.ONE - k) * (4),
                DecimalMath.mulFloor(k, V0) * (V0)
            ); // 4(1-k)kQ0^2
        squareRoot = Math.sqrt((bAbs * bAbs) + squareRoot); // sqrt(b*b+4(1-k)kQ0*Q0)

        // final res
        uint256 denominator = (DecimalMath.ONE - k) * 2; // 2(1-k)
        uint256 numerator;
        if (bSig) {
            numerator = squareRoot - bAbs;
        } else {
            numerator = bAbs + squareRoot;
        }

        uint256 V2 = DecimalMath.divCeil(numerator, denominator);
        if (V2 > V1) {
            return 0;
        } else {
            return V1 - V2;
        }
    }

}