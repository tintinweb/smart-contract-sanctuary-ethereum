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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: AGPL-1.0

pragma solidity >=0.7.5 <=0.8.10;

interface IBondCalculator {
    function valuation(address tokenIn, uint256 amount_) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5 <=0.8.10;

interface IDistributor {
    function distribute() external;

    function bounty() external view returns (uint256);

    function retrieveBounty() external returns (uint256);

    function nextRewardAt(uint256 _rate, address _recipient) external view returns (uint256);

    function nextRewardFor(address _recipient) external view returns (uint256);

    function nextRewardRate(uint256 _index) external view returns (uint256);

    function setBounty(uint256 _bounty) external;

    function addRecipient(
        address _recipient,
        uint256 _startRate,
        int256 _drs,
        int256 _dys,
        bool _locked
    ) external;

    function removeRecipient(uint256 _index) external;

    function setDiscountRateStaking(uint256 _index, int256 _drs) external;

    function setDiscountRateYield(uint256 _index, int256 _dys) external;

    function setStaking(address _addr) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IStakedTHEOToken is IERC20 {
    function rebase(uint256 theoProfit_, uint256 epoch_) external returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function balanceOf(address who) external view override returns (uint256);

    function gonsForBalance(uint256 amount) external view returns (uint256);

    function balanceForGons(uint256 gons) external view returns (uint256);

    function index() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IStaking {
    function stake(
        address _to,
        uint256 _amount,
        bool _claim
    ) external returns (uint256, uint256 _index);

    function claim(address _recipient, bool _rebasing) external returns (uint256);

    function forfeit(uint256 _index) external;

    function toggleLock() external;

    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger,
        bool _rebasing
    ) external returns (uint256);

    function wrap(address _to, uint256 _amount) external returns (uint256 gBalance_);

    function unwrap(address _to, uint256 _amount) external returns (uint256 sBalance_);

    function rebase() external;

    function index() external view returns (uint256);

    function contractBalance() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function supplyInWarmup() external view returns (uint256);

    function indexesFor(address _user) external view returns (uint256[] memory);

    function claimAll(address _recipient) external returns (uint256);

    function pushClaim(address _to, uint256 _index) external;

    function pullClaim(address _from, uint256 _index) external returns (uint256 newIndex_);

    function pushClaimForBond(address _to, uint256 _index) external returns (uint256 newIndex_);

    function basis() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ITheopetraAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event ManagerPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event SignerPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event ManagerPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);
    event SignerPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function manager() external view returns (address);

    function vault() external view returns (address);

    function whitelistSigner() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IBondCalculator.sol";

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function tokenPerformanceUpdate() external;

    function baseSupply() external view returns (uint256);

    function deltaTokenPrice() external view returns (int256);

    function deltaTreasuryYield() external view returns (int256);

    function getTheoBondingCalculator() external view returns (IBondCalculator);

    function setTheoBondingCalculator(address _theoBondingCalculator) external;
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math Quad Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with IEEE 754
 * quadruple-precision binary floating-point numbers (quadruple precision
 * numbers).  As long as quadruple precision numbers are 16-bytes long, they are
 * represented by bytes16 type.
 */
library ABDKMathQuad {
    /*
     * 0.
     */
    bytes16 private constant POSITIVE_ZERO = 0x00000000000000000000000000000000;

    /*
     * -0.
     */
    bytes16 private constant NEGATIVE_ZERO = 0x80000000000000000000000000000000;

    /*
     * +Infinity.
     */
    bytes16 private constant POSITIVE_INFINITY = 0x7FFF0000000000000000000000000000;

    /*
     * -Infinity.
     */
    bytes16 private constant NEGATIVE_INFINITY = 0xFFFF0000000000000000000000000000;

    /*
     * Canonical NaN value.
     */
    bytes16 private constant NaN = 0x7FFF8000000000000000000000000000;

    /*
     * Error message for failed require() calls.
     */
    string private constant REQUIRE_ERROR = "ABDKQuad: Mathematical operation failed";

    /**
     * Convert signed 256-bit integer number into quadruple precision number.
     *
     * @param x signed 256-bit integer number
     * @return quadruple precision number
     */
    function fromInt(int256 x) internal pure returns (bytes16) {
        unchecked {
            if (x == 0) return bytes16(0);
            else {
                // We rely on overflow behavior here
                uint256 result = uint256(x > 0 ? x : -x);

                uint256 msb = mostSignificantBit(result);
                if (msb < 112) result <<= 112 - msb;
                else if (msb > 112) result >>= msb - 112;

                result = (result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF) | ((16383 + msb) << 112);
                if (x < 0) result |= 0x80000000000000000000000000000000;

                return bytes16(uint128(result));
            }
        }
    }

    /**
     * Convert quadruple precision number into signed 256-bit integer number
     * rounding towards zero.  Revert on overflow.
     *
     * @param x quadruple precision number
     * @return signed 256-bit integer number
     */
    function toInt(bytes16 x) internal pure returns (int256) {
        unchecked {
            uint256 exponent = (uint128(x) >> 112) & 0x7FFF;

            require(exponent <= 16638, REQUIRE_ERROR); // Overflow
            if (exponent < 16383) return 0; // Underflow

            uint256 result = (uint256(uint128(x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF) | 0x10000000000000000000000000000;

            if (exponent < 16495) result >>= 16495 - exponent;
            else if (exponent > 16495) result <<= exponent - 16495;

            if (uint128(x) >= 0x80000000000000000000000000000000) {
                // Negative
                require(result <= 0x8000000000000000000000000000000000000000000000000000000000000000, REQUIRE_ERROR);
                return -int256(result); // We rely on overflow behavior here
            } else {
                require(result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
                return int256(result);
            }
        }
    }

    /**
     * Convert unsigned 256-bit integer number into quadruple precision number.
     *
     * @param x unsigned 256-bit integer number
     * @return quadruple precision number
     */
    function fromUInt(uint256 x) internal pure returns (bytes16) {
        unchecked {
            if (x == 0) return bytes16(0);
            else {
                uint256 result = x;

                uint256 msb = mostSignificantBit(result);
                if (msb < 112) result <<= 112 - msb;
                else if (msb > 112) result >>= msb - 112;

                result = (result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF) | ((16383 + msb) << 112);

                return bytes16(uint128(result));
            }
        }
    }

    /**
     * Convert quadruple precision number into unsigned 256-bit integer number
     * rounding towards zero.  Revert on underflow.  Note, that negative floating
     * point numbers in range (-1.0 .. 0.0) may be converted to unsigned integer
     * without error, because they are rounded to zero.
     *
     * @param x quadruple precision number
     * @return unsigned 256-bit integer number
     */
    function toUInt(bytes16 x) internal pure returns (uint256) {
        unchecked {
            uint256 exponent = (uint128(x) >> 112) & 0x7FFF;

            if (exponent < 16383) return 0; // Underflow

            require(uint128(x) < 0x80000000000000000000000000000000, REQUIRE_ERROR); // Negative

            require(exponent <= 16638, REQUIRE_ERROR); // Overflow
            uint256 result = (uint256(uint128(x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF) | 0x10000000000000000000000000000;

            if (exponent < 16495) result >>= 16495 - exponent;
            else if (exponent > 16495) result <<= exponent - 16495;

            return result;
        }
    }

    /**
     * Convert signed 128.128 bit fixed point number into quadruple precision
     * number.
     *
     * @param x signed 128.128 bit fixed point number
     * @return quadruple precision number
     */
    function from128x128(int256 x) internal pure returns (bytes16) {
        unchecked {
            if (x == 0) return bytes16(0);
            else {
                // We rely on overflow behavior here
                uint256 result = uint256(x > 0 ? x : -x);

                uint256 msb = mostSignificantBit(result);
                if (msb < 112) result <<= 112 - msb;
                else if (msb > 112) result >>= msb - 112;

                result = (result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF) | ((16255 + msb) << 112);
                if (x < 0) result |= 0x80000000000000000000000000000000;

                return bytes16(uint128(result));
            }
        }
    }

    /**
     * Convert quadruple precision number into signed 128.128 bit fixed point
     * number.  Revert on overflow.
     *
     * @param x quadruple precision number
     * @return signed 128.128 bit fixed point number
     */
    function to128x128(bytes16 x) internal pure returns (int256) {
        unchecked {
            uint256 exponent = (uint128(x) >> 112) & 0x7FFF;

            require(exponent <= 16510, REQUIRE_ERROR); // Overflow
            if (exponent < 16255) return 0; // Underflow

            uint256 result = (uint256(uint128(x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF) | 0x10000000000000000000000000000;

            if (exponent < 16367) result >>= 16367 - exponent;
            else if (exponent > 16367) result <<= exponent - 16367;

            if (uint128(x) >= 0x80000000000000000000000000000000) {
                // Negative
                require(result <= 0x8000000000000000000000000000000000000000000000000000000000000000, REQUIRE_ERROR);
                return -int256(result); // We rely on overflow behavior here
            } else {
                require(result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, REQUIRE_ERROR);
                return int256(result);
            }
        }
    }

    /**
     * Convert signed 64.64 bit fixed point number into quadruple precision
     * number.
     *
     * @param x signed 64.64 bit fixed point number
     * @return quadruple precision number
     */
    function from64x64(int128 x) internal pure returns (bytes16) {
        unchecked {
            if (x == 0) return bytes16(0);
            else {
                // We rely on overflow behavior here
                uint256 result = uint128(x > 0 ? x : -x);

                uint256 msb = mostSignificantBit(result);
                if (msb < 112) result <<= 112 - msb;
                else if (msb > 112) result >>= msb - 112;

                result = (result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF) | ((16319 + msb) << 112);
                if (x < 0) result |= 0x80000000000000000000000000000000;

                return bytes16(uint128(result));
            }
        }
    }

    /**
     * Convert quadruple precision number into signed 64.64 bit fixed point
     * number.  Revert on overflow.
     *
     * @param x quadruple precision number
     * @return signed 64.64 bit fixed point number
     */
    function to64x64(bytes16 x) internal pure returns (int128) {
        unchecked {
            uint256 exponent = (uint128(x) >> 112) & 0x7FFF;

            require(exponent <= 16446, REQUIRE_ERROR); // Overflow
            if (exponent < 16319) return 0; // Underflow

            uint256 result = (uint256(uint128(x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF) | 0x10000000000000000000000000000;

            if (exponent < 16431) result >>= 16431 - exponent;
            else if (exponent > 16431) result <<= exponent - 16431;

            if (uint128(x) >= 0x80000000000000000000000000000000) {
                // Negative
                require(result <= 0x80000000000000000000000000000000, REQUIRE_ERROR);
                return -int128(int256(result)); // We rely on overflow behavior here
            } else {
                require(result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, REQUIRE_ERROR);
                return int128(int256(result));
            }
        }
    }

    /**
     * Convert octuple precision number into quadruple precision number.
     *
     * @param x octuple precision number
     * @return quadruple precision number
     */
    function fromOctuple(bytes32 x) internal pure returns (bytes16) {
        unchecked {
            bool negative = x & 0x8000000000000000000000000000000000000000000000000000000000000000 > 0;

            uint256 exponent = (uint256(x) >> 236) & 0x7FFFF;
            uint256 significand = uint256(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            if (exponent == 0x7FFFF) {
                if (significand > 0) return NaN;
                else return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
            }

            if (exponent > 278526) return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
            else if (exponent < 245649) return negative ? NEGATIVE_ZERO : POSITIVE_ZERO;
            else if (exponent < 245761) {
                significand =
                    (significand | 0x100000000000000000000000000000000000000000000000000000000000) >>
                    (245885 - exponent);
                exponent = 0;
            } else {
                significand >>= 124;
                exponent -= 245760;
            }

            uint128 result = uint128(significand | (exponent << 112));
            if (negative) result |= 0x80000000000000000000000000000000;

            return bytes16(result);
        }
    }

    /**
     * Convert quadruple precision number into octuple precision number.
     *
     * @param x quadruple precision number
     * @return octuple precision number
     */
    function toOctuple(bytes16 x) internal pure returns (bytes32) {
        unchecked {
            uint256 exponent = (uint128(x) >> 112) & 0x7FFF;

            uint256 result = uint128(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            if (exponent == 0x7FFF)
                exponent = 0x7FFFF; // Infinity or NaN
            else if (exponent == 0) {
                if (result > 0) {
                    uint256 msb = mostSignificantBit(result);
                    result = (result << (236 - msb)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                    exponent = 245649 + msb;
                }
            } else {
                result <<= 124;
                exponent += 245760;
            }

            result |= exponent << 236;
            if (uint128(x) >= 0x80000000000000000000000000000000)
                result |= 0x8000000000000000000000000000000000000000000000000000000000000000;

            return bytes32(result);
        }
    }

    /**
     * Convert double precision number into quadruple precision number.
     *
     * @param x double precision number
     * @return quadruple precision number
     */
    function fromDouble(bytes8 x) internal pure returns (bytes16) {
        unchecked {
            uint256 exponent = (uint64(x) >> 52) & 0x7FF;

            uint256 result = uint64(x) & 0xFFFFFFFFFFFFF;

            if (exponent == 0x7FF)
                exponent = 0x7FFF; // Infinity or NaN
            else if (exponent == 0) {
                if (result > 0) {
                    uint256 msb = mostSignificantBit(result);
                    result = (result << (112 - msb)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                    exponent = 15309 + msb;
                }
            } else {
                result <<= 60;
                exponent += 15360;
            }

            result |= exponent << 112;
            if (x & 0x8000000000000000 > 0) result |= 0x80000000000000000000000000000000;

            return bytes16(uint128(result));
        }
    }

    /**
     * Convert quadruple precision number into double precision number.
     *
     * @param x quadruple precision number
     * @return double precision number
     */
    function toDouble(bytes16 x) internal pure returns (bytes8) {
        unchecked {
            bool negative = uint128(x) >= 0x80000000000000000000000000000000;

            uint256 exponent = (uint128(x) >> 112) & 0x7FFF;
            uint256 significand = uint128(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            if (exponent == 0x7FFF) {
                if (significand > 0) return 0x7FF8000000000000;
                // NaN
                else
                    return
                        negative
                            ? bytes8(0xFFF0000000000000) // -Infinity
                            : bytes8(0x7FF0000000000000); // Infinity
            }

            if (exponent > 17406)
                return
                    negative
                        ? bytes8(0xFFF0000000000000) // -Infinity
                        : bytes8(0x7FF0000000000000);
            // Infinity
            else if (exponent < 15309)
                return
                    negative
                        ? bytes8(0x8000000000000000) // -0
                        : bytes8(0x0000000000000000);
            // 0
            else if (exponent < 15361) {
                significand = (significand | 0x10000000000000000000000000000) >> (15421 - exponent);
                exponent = 0;
            } else {
                significand >>= 60;
                exponent -= 15360;
            }

            uint64 result = uint64(significand | (exponent << 52));
            if (negative) result |= 0x8000000000000000;

            return bytes8(result);
        }
    }

    /**
     * Test whether given quadruple precision number is NaN.
     *
     * @param x quadruple precision number
     * @return true if x is NaN, false otherwise
     */
    function isNaN(bytes16 x) internal pure returns (bool) {
        unchecked {
            return uint128(x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF > 0x7FFF0000000000000000000000000000;
        }
    }

    /**
     * Test whether given quadruple precision number is positive or negative
     * infinity.
     *
     * @param x quadruple precision number
     * @return true if x is positive or negative infinity, false otherwise
     */
    function isInfinity(bytes16 x) internal pure returns (bool) {
        unchecked {
            return uint128(x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0x7FFF0000000000000000000000000000;
        }
    }

    /**
     * Calculate sign of x, i.e. -1 if x is negative, 0 if x if zero, and 1 if x
     * is positive.  Note that sign (-0) is zero.  Revert if x is NaN.
     *
     * @param x quadruple precision number
     * @return sign of x
     */
    function sign(bytes16 x) internal pure returns (int8) {
        unchecked {
            uint128 absoluteX = uint128(x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            require(absoluteX <= 0x7FFF0000000000000000000000000000, REQUIRE_ERROR); // Not NaN

            if (absoluteX == 0) return 0;
            else if (uint128(x) >= 0x80000000000000000000000000000000) return -1;
            else return 1;
        }
    }

    /**
     * Calculate sign (x - y).  Revert if either argument is NaN, or both
     * arguments are infinities of the same sign.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return sign (x - y)
     */
    function cmp(bytes16 x, bytes16 y) internal pure returns (int8) {
        unchecked {
            uint128 absoluteX = uint128(x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            require(absoluteX <= 0x7FFF0000000000000000000000000000, REQUIRE_ERROR); // Not NaN

            uint128 absoluteY = uint128(y) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            require(absoluteY <= 0x7FFF0000000000000000000000000000, REQUIRE_ERROR); // Not NaN

            // Not infinities of the same sign
            require(x != y || absoluteX < 0x7FFF0000000000000000000000000000, REQUIRE_ERROR);

            if (x == y) return 0;
            else {
                bool negativeX = uint128(x) >= 0x80000000000000000000000000000000;
                bool negativeY = uint128(y) >= 0x80000000000000000000000000000000;

                if (negativeX) {
                    if (negativeY) return absoluteX > absoluteY ? -1 : int8(1);
                    else return -1;
                } else {
                    if (negativeY) return 1;
                    else return absoluteX > absoluteY ? int8(1) : -1;
                }
            }
        }
    }

    /**
     * Test whether x equals y.  NaN, infinity, and -infinity are not equal to
     * anything.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return true if x equals to y, false otherwise
     */
    function eq(bytes16 x, bytes16 y) internal pure returns (bool) {
        unchecked {
            if (x == y) {
                return uint128(x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF < 0x7FFF0000000000000000000000000000;
            } else return false;
        }
    }

    /**
     * Calculate x + y.  Special values behave in the following way:
     *
     * NaN + x = NaN for any x.
     * Infinity + x = Infinity for any finite x.
     * -Infinity + x = -Infinity for any finite x.
     * Infinity + Infinity = Infinity.
     * -Infinity + -Infinity = -Infinity.
     * Infinity + -Infinity = -Infinity + Infinity = NaN.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return quadruple precision number
     */
    function add(bytes16 x, bytes16 y) internal pure returns (bytes16) {
        unchecked {
            uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
            uint256 yExponent = (uint128(y) >> 112) & 0x7FFF;

            if (xExponent == 0x7FFF) {
                if (yExponent == 0x7FFF) {
                    if (x == y) return x;
                    else return NaN;
                } else return x;
            } else if (yExponent == 0x7FFF) return y;
            else {
                bool xSign = uint128(x) >= 0x80000000000000000000000000000000;
                uint256 xSignifier = uint128(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (xExponent == 0) xExponent = 1;
                else xSignifier |= 0x10000000000000000000000000000;

                bool ySign = uint128(y) >= 0x80000000000000000000000000000000;
                uint256 ySignifier = uint128(y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (yExponent == 0) yExponent = 1;
                else ySignifier |= 0x10000000000000000000000000000;

                if (xSignifier == 0) return y == NEGATIVE_ZERO ? POSITIVE_ZERO : y;
                else if (ySignifier == 0) return x == NEGATIVE_ZERO ? POSITIVE_ZERO : x;
                else {
                    int256 delta = int256(xExponent) - int256(yExponent);

                    if (xSign == ySign) {
                        if (delta > 112) return x;
                        else if (delta > 0) ySignifier >>= uint256(delta);
                        else if (delta < -112) return y;
                        else if (delta < 0) {
                            xSignifier >>= uint256(-delta);
                            xExponent = yExponent;
                        }

                        xSignifier += ySignifier;

                        if (xSignifier >= 0x20000000000000000000000000000) {
                            xSignifier >>= 1;
                            xExponent += 1;
                        }

                        if (xExponent == 0x7FFF) return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
                        else {
                            if (xSignifier < 0x10000000000000000000000000000) xExponent = 0;
                            else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

                            return
                                bytes16(
                                    uint128(
                                        (xSign ? 0x80000000000000000000000000000000 : 0) |
                                            (xExponent << 112) |
                                            xSignifier
                                    )
                                );
                        }
                    } else {
                        if (delta > 0) {
                            xSignifier <<= 1;
                            xExponent -= 1;
                        } else if (delta < 0) {
                            ySignifier <<= 1;
                            xExponent = yExponent - 1;
                        }

                        if (delta > 112) ySignifier = 1;
                        else if (delta > 1) ySignifier = ((ySignifier - 1) >> uint256(delta - 1)) + 1;
                        else if (delta < -112) xSignifier = 1;
                        else if (delta < -1) xSignifier = ((xSignifier - 1) >> uint256(-delta - 1)) + 1;

                        if (xSignifier >= ySignifier) xSignifier -= ySignifier;
                        else {
                            xSignifier = ySignifier - xSignifier;
                            xSign = ySign;
                        }

                        if (xSignifier == 0) return POSITIVE_ZERO;

                        uint256 msb = mostSignificantBit(xSignifier);

                        if (msb == 113) {
                            xSignifier = (xSignifier >> 1) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                            xExponent += 1;
                        } else if (msb < 112) {
                            uint256 shift = 112 - msb;
                            if (xExponent > shift) {
                                xSignifier = (xSignifier << shift) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                                xExponent -= shift;
                            } else {
                                xSignifier <<= xExponent - 1;
                                xExponent = 0;
                            }
                        } else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

                        if (xExponent == 0x7FFF) return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
                        else
                            return
                                bytes16(
                                    uint128(
                                        (xSign ? 0x80000000000000000000000000000000 : 0) |
                                            (xExponent << 112) |
                                            xSignifier
                                    )
                                );
                    }
                }
            }
        }
    }

    /**
     * Calculate x - y.  Special values behave in the following way:
     *
     * NaN - x = NaN for any x.
     * Infinity - x = Infinity for any finite x.
     * -Infinity - x = -Infinity for any finite x.
     * Infinity - -Infinity = Infinity.
     * -Infinity - Infinity = -Infinity.
     * Infinity - Infinity = -Infinity - -Infinity = NaN.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return quadruple precision number
     */
    function sub(bytes16 x, bytes16 y) internal pure returns (bytes16) {
        unchecked {
            return add(x, y ^ 0x80000000000000000000000000000000);
        }
    }

    /**
     * Calculate x * y.  Special values behave in the following way:
     *
     * NaN * x = NaN for any x.
     * Infinity * x = Infinity for any finite positive x.
     * Infinity * x = -Infinity for any finite negative x.
     * -Infinity * x = -Infinity for any finite positive x.
     * -Infinity * x = Infinity for any finite negative x.
     * Infinity * 0 = NaN.
     * -Infinity * 0 = NaN.
     * Infinity * Infinity = Infinity.
     * Infinity * -Infinity = -Infinity.
     * -Infinity * Infinity = -Infinity.
     * -Infinity * -Infinity = Infinity.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return quadruple precision number
     */
    function mul(bytes16 x, bytes16 y) internal pure returns (bytes16) {
        unchecked {
            uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
            uint256 yExponent = (uint128(y) >> 112) & 0x7FFF;

            if (xExponent == 0x7FFF) {
                if (yExponent == 0x7FFF) {
                    if (x == y) return x ^ (y & 0x80000000000000000000000000000000);
                    else if (x ^ y == 0x80000000000000000000000000000000) return x | y;
                    else return NaN;
                } else {
                    if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
                    else return x ^ (y & 0x80000000000000000000000000000000);
                }
            } else if (yExponent == 0x7FFF) {
                if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
                else return y ^ (x & 0x80000000000000000000000000000000);
            } else {
                uint256 xSignifier = uint128(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (xExponent == 0) xExponent = 1;
                else xSignifier |= 0x10000000000000000000000000000;

                uint256 ySignifier = uint128(y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (yExponent == 0) yExponent = 1;
                else ySignifier |= 0x10000000000000000000000000000;

                xSignifier *= ySignifier;
                if (xSignifier == 0)
                    return (x ^ y) & 0x80000000000000000000000000000000 > 0 ? NEGATIVE_ZERO : POSITIVE_ZERO;

                xExponent += yExponent;

                uint256 msb = xSignifier >= 0x200000000000000000000000000000000000000000000000000000000
                    ? 225
                    : xSignifier >= 0x100000000000000000000000000000000000000000000000000000000
                    ? 224
                    : mostSignificantBit(xSignifier);

                if (xExponent + msb < 16496) {
                    // Underflow
                    xExponent = 0;
                    xSignifier = 0;
                } else if (xExponent + msb < 16608) {
                    // Subnormal
                    if (xExponent < 16496) xSignifier >>= 16496 - xExponent;
                    else if (xExponent > 16496) xSignifier <<= xExponent - 16496;
                    xExponent = 0;
                } else if (xExponent + msb > 49373) {
                    xExponent = 0x7FFF;
                    xSignifier = 0;
                } else {
                    if (msb > 112) xSignifier >>= msb - 112;
                    else if (msb < 112) xSignifier <<= 112 - msb;

                    xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

                    xExponent = xExponent + msb - 16607;
                }

                return
                    bytes16(
                        uint128(uint128((x ^ y) & 0x80000000000000000000000000000000) | (xExponent << 112) | xSignifier)
                    );
            }
        }
    }

    /**
     * Calculate x / y.  Special values behave in the following way:
     *
     * NaN / x = NaN for any x.
     * x / NaN = NaN for any x.
     * Infinity / x = Infinity for any finite non-negative x.
     * Infinity / x = -Infinity for any finite negative x including -0.
     * -Infinity / x = -Infinity for any finite non-negative x.
     * -Infinity / x = Infinity for any finite negative x including -0.
     * x / Infinity = 0 for any finite non-negative x.
     * x / -Infinity = -0 for any finite non-negative x.
     * x / Infinity = -0 for any finite non-negative x including -0.
     * x / -Infinity = 0 for any finite non-negative x including -0.
     *
     * Infinity / Infinity = NaN.
     * Infinity / -Infinity = -NaN.
     * -Infinity / Infinity = -NaN.
     * -Infinity / -Infinity = NaN.
     *
     * Division by zero behaves in the following way:
     *
     * x / 0 = Infinity for any finite positive x.
     * x / -0 = -Infinity for any finite positive x.
     * x / 0 = -Infinity for any finite negative x.
     * x / -0 = Infinity for any finite negative x.
     * 0 / 0 = NaN.
     * 0 / -0 = NaN.
     * -0 / 0 = NaN.
     * -0 / -0 = NaN.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return quadruple precision number
     */
    function div(bytes16 x, bytes16 y) internal pure returns (bytes16) {
        unchecked {
            uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
            uint256 yExponent = (uint128(y) >> 112) & 0x7FFF;

            if (xExponent == 0x7FFF) {
                if (yExponent == 0x7FFF) return NaN;
                else return x ^ (y & 0x80000000000000000000000000000000);
            } else if (yExponent == 0x7FFF) {
                if (y & 0x0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF != 0) return NaN;
                else return POSITIVE_ZERO | ((x ^ y) & 0x80000000000000000000000000000000);
            } else if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) {
                if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
                else return POSITIVE_INFINITY | ((x ^ y) & 0x80000000000000000000000000000000);
            } else {
                uint256 ySignifier = uint128(y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (yExponent == 0) yExponent = 1;
                else ySignifier |= 0x10000000000000000000000000000;

                uint256 xSignifier = uint128(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (xExponent == 0) {
                    if (xSignifier != 0) {
                        uint256 shift = 226 - mostSignificantBit(xSignifier);

                        xSignifier <<= shift;

                        xExponent = 1;
                        yExponent += shift - 114;
                    }
                } else {
                    xSignifier = (xSignifier | 0x10000000000000000000000000000) << 114;
                }

                xSignifier = xSignifier / ySignifier;
                if (xSignifier == 0)
                    return (x ^ y) & 0x80000000000000000000000000000000 > 0 ? NEGATIVE_ZERO : POSITIVE_ZERO;

                assert(xSignifier >= 0x1000000000000000000000000000);

                uint256 msb = xSignifier >= 0x80000000000000000000000000000
                    ? mostSignificantBit(xSignifier)
                    : xSignifier >= 0x40000000000000000000000000000
                    ? 114
                    : xSignifier >= 0x20000000000000000000000000000
                    ? 113
                    : 112;

                if (xExponent + msb > yExponent + 16497) {
                    // Overflow
                    xExponent = 0x7FFF;
                    xSignifier = 0;
                } else if (xExponent + msb + 16380 < yExponent) {
                    // Underflow
                    xExponent = 0;
                    xSignifier = 0;
                } else if (xExponent + msb + 16268 < yExponent) {
                    // Subnormal
                    if (xExponent + 16380 > yExponent) xSignifier <<= xExponent + 16380 - yExponent;
                    else if (xExponent + 16380 < yExponent) xSignifier >>= yExponent - xExponent - 16380;

                    xExponent = 0;
                } else {
                    // Normal
                    if (msb > 112) xSignifier >>= msb - 112;

                    xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

                    xExponent = xExponent + msb + 16269 - yExponent;
                }

                return
                    bytes16(
                        uint128(uint128((x ^ y) & 0x80000000000000000000000000000000) | (xExponent << 112) | xSignifier)
                    );
            }
        }
    }

    /**
     * Calculate -x.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function neg(bytes16 x) internal pure returns (bytes16) {
        unchecked {
            return x ^ 0x80000000000000000000000000000000;
        }
    }

    /**
     * Calculate |x|.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function abs(bytes16 x) internal pure returns (bytes16) {
        unchecked {
            return x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        }
    }

    /**
     * Calculate square root of x.  Return NaN on negative x excluding -0.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function sqrt(bytes16 x) internal pure returns (bytes16) {
        unchecked {
            if (uint128(x) > 0x80000000000000000000000000000000) return NaN;
            else {
                uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
                if (xExponent == 0x7FFF) return x;
                else {
                    uint256 xSignifier = uint128(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                    if (xExponent == 0) xExponent = 1;
                    else xSignifier |= 0x10000000000000000000000000000;

                    if (xSignifier == 0) return POSITIVE_ZERO;

                    bool oddExponent = xExponent & 0x1 == 0;
                    xExponent = (xExponent + 16383) >> 1;

                    if (oddExponent) {
                        if (xSignifier >= 0x10000000000000000000000000000) xSignifier <<= 113;
                        else {
                            uint256 msb = mostSignificantBit(xSignifier);
                            uint256 shift = (226 - msb) & 0xFE;
                            xSignifier <<= shift;
                            xExponent -= (shift - 112) >> 1;
                        }
                    } else {
                        if (xSignifier >= 0x10000000000000000000000000000) xSignifier <<= 112;
                        else {
                            uint256 msb = mostSignificantBit(xSignifier);
                            uint256 shift = (225 - msb) & 0xFE;
                            xSignifier <<= shift;
                            xExponent -= (shift - 112) >> 1;
                        }
                    }

                    uint256 r = 0x10000000000000000000000000000;
                    r = (r + xSignifier / r) >> 1;
                    r = (r + xSignifier / r) >> 1;
                    r = (r + xSignifier / r) >> 1;
                    r = (r + xSignifier / r) >> 1;
                    r = (r + xSignifier / r) >> 1;
                    r = (r + xSignifier / r) >> 1;
                    r = (r + xSignifier / r) >> 1; // Seven iterations should be enough
                    uint256 r1 = xSignifier / r;
                    if (r1 < r) r = r1;

                    return bytes16(uint128((xExponent << 112) | (r & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF)));
                }
            }
        }
    }

    /**
     * Calculate binary logarithm of x.  Return NaN on negative x excluding -0.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function log_2(bytes16 x) internal pure returns (bytes16) {
        unchecked {
            if (uint128(x) > 0x80000000000000000000000000000000) return NaN;
            else if (x == 0x3FFF0000000000000000000000000000) return POSITIVE_ZERO;
            else {
                uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
                if (xExponent == 0x7FFF) return x;
                else {
                    uint256 xSignifier = uint128(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                    if (xExponent == 0) xExponent = 1;
                    else xSignifier |= 0x10000000000000000000000000000;

                    if (xSignifier == 0) return NEGATIVE_INFINITY;

                    bool resultNegative;
                    uint256 resultExponent = 16495;
                    uint256 resultSignifier;

                    if (xExponent >= 0x3FFF) {
                        resultNegative = false;
                        resultSignifier = xExponent - 0x3FFF;
                        xSignifier <<= 15;
                    } else {
                        resultNegative = true;
                        if (xSignifier >= 0x10000000000000000000000000000) {
                            resultSignifier = 0x3FFE - xExponent;
                            xSignifier <<= 15;
                        } else {
                            uint256 msb = mostSignificantBit(xSignifier);
                            resultSignifier = 16493 - msb;
                            xSignifier <<= 127 - msb;
                        }
                    }

                    if (xSignifier == 0x80000000000000000000000000000000) {
                        if (resultNegative) resultSignifier += 1;
                        uint256 shift = 112 - mostSignificantBit(resultSignifier);
                        resultSignifier <<= shift;
                        resultExponent -= shift;
                    } else {
                        uint256 bb = resultNegative ? 1 : 0;
                        while (resultSignifier < 0x10000000000000000000000000000) {
                            resultSignifier <<= 1;
                            resultExponent -= 1;

                            xSignifier *= xSignifier;
                            uint256 b = xSignifier >> 255;
                            resultSignifier += b ^ bb;
                            xSignifier >>= 127 + b;
                        }
                    }

                    return
                        bytes16(
                            uint128(
                                (resultNegative ? 0x80000000000000000000000000000000 : 0) |
                                    (resultExponent << 112) |
                                    (resultSignifier & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                            )
                        );
                }
            }
        }
    }

    /**
     * Calculate natural logarithm of x.  Return NaN on negative x excluding -0.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function ln(bytes16 x) internal pure returns (bytes16) {
        unchecked {
            return mul(log_2(x), 0x3FFE62E42FEFA39EF35793C7673007E5);
        }
    }

    /**
     * Calculate 2^x.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function pow_2(bytes16 x) internal pure returns (bytes16) {
        unchecked {
            bool xNegative = uint128(x) > 0x80000000000000000000000000000000;
            uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
            uint256 xSignifier = uint128(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            if (xExponent == 0x7FFF && xSignifier != 0) return NaN;
            else if (xExponent > 16397) return xNegative ? POSITIVE_ZERO : POSITIVE_INFINITY;
            else if (xExponent < 16255) return 0x3FFF0000000000000000000000000000;
            else {
                if (xExponent == 0) xExponent = 1;
                else xSignifier |= 0x10000000000000000000000000000;

                if (xExponent > 16367) xSignifier <<= xExponent - 16367;
                else if (xExponent < 16367) xSignifier >>= 16367 - xExponent;

                if (xNegative && xSignifier > 0x406E00000000000000000000000000000000) return POSITIVE_ZERO;

                if (!xNegative && xSignifier > 0x3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) return POSITIVE_INFINITY;

                uint256 resultExponent = xSignifier >> 128;
                xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (xNegative && xSignifier != 0) {
                    xSignifier = ~xSignifier;
                    resultExponent += 1;
                }

                uint256 resultSignifier = 0x80000000000000000000000000000000;
                if (xSignifier & 0x80000000000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
                if (xSignifier & 0x40000000000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1306FE0A31B7152DE8D5A46305C85EDEC) >> 128;
                if (xSignifier & 0x20000000000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1172B83C7D517ADCDF7C8C50EB14A791F) >> 128;
                if (xSignifier & 0x10000000000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10B5586CF9890F6298B92B71842A98363) >> 128;
                if (xSignifier & 0x8000000000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1059B0D31585743AE7C548EB68CA417FD) >> 128;
                if (xSignifier & 0x4000000000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x102C9A3E778060EE6F7CACA4F7A29BDE8) >> 128;
                if (xSignifier & 0x2000000000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10163DA9FB33356D84A66AE336DCDFA3F) >> 128;
                if (xSignifier & 0x1000000000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100B1AFA5ABCBED6129AB13EC11DC9543) >> 128;
                if (xSignifier & 0x800000000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10058C86DA1C09EA1FF19D294CF2F679B) >> 128;
                if (xSignifier & 0x400000000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1002C605E2E8CEC506D21BFC89A23A00F) >> 128;
                if (xSignifier & 0x200000000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100162F3904051FA128BCA9C55C31E5DF) >> 128;
                if (xSignifier & 0x100000000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000B175EFFDC76BA38E31671CA939725) >> 128;
                if (xSignifier & 0x80000000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100058BA01FB9F96D6CACD4B180917C3D) >> 128;
                if (xSignifier & 0x40000000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10002C5CC37DA9491D0985C348C68E7B3) >> 128;
                if (xSignifier & 0x20000000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000162E525EE054754457D5995292026) >> 128;
                if (xSignifier & 0x10000000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000B17255775C040618BF4A4ADE83FC) >> 128;
                if (xSignifier & 0x8000000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >> 128;
                if (xSignifier & 0x4000000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >> 128;
                if (xSignifier & 0x2000000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
                if (xSignifier & 0x1000000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
                if (xSignifier & 0x800000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000058B90CF1E6D97F9CA14DBCC1628) >> 128;
                if (xSignifier & 0x400000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000002C5C863B73F016468F6BAC5CA2B) >> 128;
                if (xSignifier & 0x200000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000162E430E5A18F6119E3C02282A5) >> 128;
                if (xSignifier & 0x100000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000B1721835514B86E6D96EFD1BFE) >> 128;
                if (xSignifier & 0x80000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000058B90C0B48C6BE5DF846C5B2EF) >> 128;
                if (xSignifier & 0x40000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000002C5C8601CC6B9E94213C72737A) >> 128;
                if (xSignifier & 0x20000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000162E42FFF037DF38AA2B219F06) >> 128;
                if (xSignifier & 0x10000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000B17217FBA9C739AA5819F44F9) >> 128;
                if (xSignifier & 0x8000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000058B90BFCDEE5ACD3C1CEDC823) >> 128;
                if (xSignifier & 0x4000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000002C5C85FE31F35A6A30DA1BE50) >> 128;
                if (xSignifier & 0x2000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000162E42FF0999CE3541B9FFFCF) >> 128;
                if (xSignifier & 0x1000000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
                if (xSignifier & 0x800000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000058B90BFBF8479BD5A81B51AD) >> 128;
                if (xSignifier & 0x400000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000002C5C85FDF84BD62AE30A74CC) >> 128;
                if (xSignifier & 0x200000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
                if (xSignifier & 0x100000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000B17217F7D5A7716BBA4A9AE) >> 128;
                if (xSignifier & 0x80000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000058B90BFBE9DDBAC5E109CCE) >> 128;
                if (xSignifier & 0x40000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000002C5C85FDF4B15DE6F17EB0D) >> 128;
                if (xSignifier & 0x20000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
                if (xSignifier & 0x10000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000B17217F7D20CF927C8E94C) >> 128;
                if (xSignifier & 0x8000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000058B90BFBE8F71CB4E4B33D) >> 128;
                if (xSignifier & 0x4000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000002C5C85FDF477B662B26945) >> 128;
                if (xSignifier & 0x2000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000162E42FEFA3AE53369388C) >> 128;
                if (xSignifier & 0x1000000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000B17217F7D1D351A389D40) >> 128;
                if (xSignifier & 0x800000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000058B90BFBE8E8B2D3D4EDE) >> 128;
                if (xSignifier & 0x400000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000002C5C85FDF4741BEA6E77E) >> 128;
                if (xSignifier & 0x200000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000162E42FEFA39FE95583C2) >> 128;
                if (xSignifier & 0x100000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000000B17217F7D1CFB72B45E1) >> 128;
                if (xSignifier & 0x80000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000058B90BFBE8E7CC35C3F0) >> 128;
                if (xSignifier & 0x40000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000002C5C85FDF473E242EA38) >> 128;
                if (xSignifier & 0x20000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000000162E42FEFA39F02B772C) >> 128;
                if (xSignifier & 0x10000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
                if (xSignifier & 0x8000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
                if (xSignifier & 0x4000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000002C5C85FDF473DEA871F) >> 128;
                if (xSignifier & 0x2000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000000162E42FEFA39EF44D91) >> 128;
                if (xSignifier & 0x1000000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000000B17217F7D1CF79E949) >> 128;
                if (xSignifier & 0x800000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000000058B90BFBE8E7BCE544) >> 128;
                if (xSignifier & 0x400000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
                if (xSignifier & 0x200000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000000162E42FEFA39EF366F) >> 128;
                if (xSignifier & 0x100000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
                if (xSignifier & 0x80000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000000058B90BFBE8E7BCD6D) >> 128;
                if (xSignifier & 0x40000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000000002C5C85FDF473DE6B2) >> 128;
                if (xSignifier & 0x20000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000000000162E42FEFA39EF358) >> 128;
                if (xSignifier & 0x10000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000000000B17217F7D1CF79AB) >> 128;
                if (xSignifier & 0x8000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000000000058B90BFBE8E7BCD5) >> 128;
                if (xSignifier & 0x4000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000000002C5C85FDF473DE6A) >> 128;
                if (xSignifier & 0x2000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000000000162E42FEFA39EF34) >> 128;
                if (xSignifier & 0x1000000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000000000B17217F7D1CF799) >> 128;
                if (xSignifier & 0x800000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000000000058B90BFBE8E7BCC) >> 128;
                if (xSignifier & 0x400000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000000000002C5C85FDF473DE5) >> 128;
                if (xSignifier & 0x200000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000000000162E42FEFA39EF2) >> 128;
                if (xSignifier & 0x100000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000000000000B17217F7D1CF78) >> 128;
                if (xSignifier & 0x80000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000000000058B90BFBE8E7BB) >> 128;
                if (xSignifier & 0x40000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000000000002C5C85FDF473DD) >> 128;
                if (xSignifier & 0x20000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000000000000162E42FEFA39EE) >> 128;
                if (xSignifier & 0x10000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000000000000B17217F7D1CF6) >> 128;
                if (xSignifier & 0x8000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000000000000058B90BFBE8E7A) >> 128;
                if (xSignifier & 0x4000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000000000002C5C85FDF473C) >> 128;
                if (xSignifier & 0x2000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000000000000162E42FEFA39D) >> 128;
                if (xSignifier & 0x1000000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000000000000B17217F7D1CE) >> 128;
                if (xSignifier & 0x800000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000000000000058B90BFBE8E6) >> 128;
                if (xSignifier & 0x400000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000000000000002C5C85FDF472) >> 128;
                if (xSignifier & 0x200000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000000000000162E42FEFA38) >> 128;
                if (xSignifier & 0x100000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000000000000000B17217F7D1B) >> 128;
                if (xSignifier & 0x80000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000000000000058B90BFBE8D) >> 128;
                if (xSignifier & 0x40000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000000000000002C5C85FDF46) >> 128;
                if (xSignifier & 0x20000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000000000000000162E42FEFA2) >> 128;
                if (xSignifier & 0x10000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000000000000000B17217F7D0) >> 128;
                if (xSignifier & 0x8000000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000000000000000058B90BFBE7) >> 128;
                if (xSignifier & 0x4000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000000000000002C5C85FDF3) >> 128;
                if (xSignifier & 0x2000000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000000000000000162E42FEF9) >> 128;
                if (xSignifier & 0x1000000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000000000000000B17217F7C) >> 128;
                if (xSignifier & 0x800000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000000000000000058B90BFBD) >> 128;
                if (xSignifier & 0x400000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000000000000000002C5C85FDE) >> 128;
                if (xSignifier & 0x200000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000000000000000162E42FEE) >> 128;
                if (xSignifier & 0x100000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000000000000000000B17217F6) >> 128;
                if (xSignifier & 0x80000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000000000000000058B90BFA) >> 128;
                if (xSignifier & 0x40000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000000000000000002C5C85FC) >> 128;
                if (xSignifier & 0x20000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000000000000000000162E42FD) >> 128;
                if (xSignifier & 0x10000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000000000000000000B17217E) >> 128;
                if (xSignifier & 0x8000000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000000000000000000058B90BE) >> 128;
                if (xSignifier & 0x4000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000000000000000002C5C85E) >> 128;
                if (xSignifier & 0x2000000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000000000000000000162E42E) >> 128;
                if (xSignifier & 0x1000000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000000000000000000B17216) >> 128;
                if (xSignifier & 0x800000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000000000000000000058B90A) >> 128;
                if (xSignifier & 0x400000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000000000000000000002C5C84) >> 128;
                if (xSignifier & 0x200000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000000000000000000162E41) >> 128;
                if (xSignifier & 0x100000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000000000000000000000B1720) >> 128;
                if (xSignifier & 0x80000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000000000000000000058B8F) >> 128;
                if (xSignifier & 0x40000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000000000000000000002C5C7) >> 128;
                if (xSignifier & 0x20000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000000000000000000000162E3) >> 128;
                if (xSignifier & 0x10000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000000000000000000000B171) >> 128;
                if (xSignifier & 0x8000 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000000000000000000000058B8) >> 128;
                if (xSignifier & 0x4000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000000000000000000002C5B) >> 128;
                if (xSignifier & 0x2000 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000000000000000000000162D) >> 128;
                if (xSignifier & 0x1000 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000000000000000000000B16) >> 128;
                if (xSignifier & 0x800 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000000000000000000000058A) >> 128;
                if (xSignifier & 0x400 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000000000000000000000002C4) >> 128;
                if (xSignifier & 0x200 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000000000000000000000161) >> 128;
                if (xSignifier & 0x100 > 0)
                    resultSignifier = (resultSignifier * 0x1000000000000000000000000000000B0) >> 128;
                if (xSignifier & 0x80 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000000000000000000000057) >> 128;
                if (xSignifier & 0x40 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000000000000000000000002B) >> 128;
                if (xSignifier & 0x20 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000000000000000000000015) >> 128;
                if (xSignifier & 0x10 > 0)
                    resultSignifier = (resultSignifier * 0x10000000000000000000000000000000A) >> 128;
                if (xSignifier & 0x8 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000000000000000000000004) >> 128;
                if (xSignifier & 0x4 > 0)
                    resultSignifier = (resultSignifier * 0x100000000000000000000000000000001) >> 128;

                if (!xNegative) {
                    resultSignifier = (resultSignifier >> 15) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                    resultExponent += 0x3FFF;
                } else if (resultExponent <= 0x3FFE) {
                    resultSignifier = (resultSignifier >> 15) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                    resultExponent = 0x3FFF - resultExponent;
                } else {
                    resultSignifier = resultSignifier >> (resultExponent - 16367);
                    resultExponent = 0;
                }

                return bytes16(uint128((resultExponent << 112) | resultSignifier));
            }
        }
    }

    /**
     * Calculate e^x.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function exp(bytes16 x) internal pure returns (bytes16) {
        unchecked {
            return pow_2(mul(x, 0x3FFF71547652B82FE1777D0FFDA0D23A));
        }
    }

    /**
     * Get index of the most significant non-zero bit in binary representation of
     * x.  Reverts if x is zero.
     *
     * @return index of the most significant non-zero bit in binary representation
     *         of x
     */
    function mostSignificantBit(uint256 x) private pure returns (uint256) {
        unchecked {
            require(x > 0, REQUIRE_ERROR);

            uint256 result = 0;

            if (x >= 0x100000000000000000000000000000000) {
                x >>= 128;
                result += 128;
            }
            if (x >= 0x10000000000000000) {
                x >>= 64;
                result += 64;
            }
            if (x >= 0x100000000) {
                x >>= 32;
                result += 32;
            }
            if (x >= 0x10000) {
                x >>= 16;
                result += 16;
            }
            if (x >= 0x100) {
                x >>= 8;
                result += 8;
            }
            if (x >= 0x10) {
                x >>= 4;
                result += 4;
            }
            if (x >= 0x4) {
                x >>= 2;
                result += 2;
            }
            if (x >= 0x2) result += 1; // No need to shift x anymore

            return result;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import { IERC20 } from "../Interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{ value: amount }(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5 <=0.8.10;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";

import "../Types/TheopetraAccessControlled.sol";

import "../Libraries/SafeERC20.sol";
import "../Libraries/ABDKMathQuad.sol";

import "../Interfaces/ITreasury.sol";
import "../Interfaces/IERC20.sol";
import "../Interfaces/IDistributor.sol";

import "../Interfaces/IStaking.sol";
import "../Interfaces/IStakedTHEOToken.sol";

contract StakingDistributor is IDistributor, TheopetraAccessControlled {
    /* ========== DEPENDENCIES ========== */

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeCast for uint256;

    /* ====== VARIABLES ====== */

    IERC20 private immutable THEO;
    ITreasury private immutable treasury;
    mapping(address => bool) private staking;

    uint48 public immutable epochLength;

    mapping(uint256 => Adjust) public adjustments;
    uint256 public override bounty;

    uint256 private constant rateDenominator = 1_000_000_000;

    /**
        @dev    byte representation of 1095. See also `deriveRate`.
     */
    bytes16 private constant n = 0x400911c0000000000000000000000000;
    /**
        @dev    byte representation of 1;
     */
    bytes16 private constant one = 0x3fff0000000000000000000000000000;

    event Distribute(uint256 indexed amount, uint256 indexed rate, address recipient);
    event BountyRetrieved(uint256 indexed amount, address indexed beneficiary);
    event SetBounty(uint256 indexed amount);
    event AddRecipient(address recipient, uint256 startRate, bool locked);
    event RemoveRecipient(address recipient);
    event SetStakingContract(address stakingContract);
    event UpdateDRS(address recipient, int256 drs);
    event UpdateDYS(address recipient, int256 dry);
    /* ====== STRUCTS ====== */

    /**
        @notice information for rewards to recipients
        @dev    Info::start is the starting rate for rewards in ten-thousandsths (2000 = 0.2%);
                Info::drs is the Discount Rate Return Staking. The discount rate applied to the fluctuation of the token price, as a proportion (that is, a percentage in its decimal form), with 9 decimals
                Info::dys is the discount rate applied to the fluctuation of the treasury yield, as a proportion (that is, a percentage in its decimal form), with 9 decimals
                Info::recipient is the recipient staking contract for rewards
                Info::locked is whether the staking tranche is locked (true) or unlocked (false)
                Info::nextEpochTime is the timestamp for the next epoch, when wind-down will next be applied to the starting reward rate and the maximum reward rate
     */
    struct Info {
        uint256 start;
        int256 drs;
        int256 dys;
        address recipient;
        bool locked;
        uint48 nextEpochTime;
    }
    Info[] public info;

    struct Adjust {
        bool add;
        uint256 rate;
        uint256 target;
    }

    /* ====== CONSTRUCTOR ====== */

    constructor(
        address _treasury,
        address _theo,
        uint48 _epochLength,
        ITheopetraAuthority _authority,
        address _staking
    ) TheopetraAccessControlled(ITheopetraAuthority(_authority)) {
        require(_treasury != address(0), "Zero address: Treasury");
        treasury = ITreasury(_treasury);
        require(_theo != address(0), "Zero address: THEO");
        THEO = IERC20(_theo);
        require(_staking != address(0), "Zero address: Staking");
        staking[_staking] = true;
        epochLength = _epochLength;
    }

    /* ====== Modifiers ====== */
    modifier onlyStaking() {
        require(staking[msg.sender], "Only staking");
        _;
    }

    /* ====== PUBLIC FUNCTIONS ====== */

    /**
        @notice send epoch reward to staking contract
        @dev    distribute can only be called by a Staking contract (and the Staking contract will only call if its epoch is over)
                This method distributes rewards to each recipient (minting and sending from the treasury)
                If the current time is greater than `nextEpochTime`, the starting rate is wound-down, and the `nextEpochTime` is updated.
                Wind-down occurs according to the schedules for unlocked and locked tranches where:
                Locked tranches wind-down by 1.5% per epoch (that is, per year) to a minimum of 6% (60_000_000 -- see also `rateDenominator`)
                Unlocked tranches wind-down by 0.5% per epoch (that is, per year) to a minimum of 2% (20_000_000)
     */
    function distribute() external override onlyStaking {
        for (uint256 i = 0; i < info.length; i++) {
            uint256 _rate = nextRewardRate(i);
            if (_rate > 0) {
                uint256 reward = nextRewardAt(_rate, info[i].recipient);
                ITreasury(treasury).mint(info[i].recipient, reward);
                emit Distribute(reward, _rate, info[i].recipient);
            }
            if (info[i].nextEpochTime <= block.timestamp) {
                if (info[i].locked == false && info[i].start > 20_000_000) {
                    info[i].start = info[i].start.sub(5_000_000);
                } else if (info[i].locked == true && info[i].start > 60_000_000) {
                    info[i].start = info[i].start.sub(15_000_000);
                }
                info[i].nextEpochTime = uint48(uint256(info[i].nextEpochTime).add(uint256(epochLength)));
            }
        }
    }

    /**
        @dev If the distributor bounty is > 0, mint it for the staking contract.
     */
    function retrieveBounty() external override onlyStaking returns (uint256) {
        // onlyStaking compares msg.sender to the `staking` mapping, so this is safe
        // msg.sender at this point can only be a staking contract
        if (bounty > 0) {
            treasury.mint(address(msg.sender), bounty);
            emit BountyRetrieved(bounty, address(msg.sender));
        }

        return bounty;
    }

    /* ====== VIEW FUNCTIONS ====== */

    /**
        @notice view function for next reward at given rate
        @param _rate uint
        @return uint
     */
    function nextRewardAt(uint256 _rate, address _recipient) public view override returns (uint256) {
        return IStakedTHEOToken(IStaking(_recipient).basis()).circulatingSupply().mul(_rate).div(rateDenominator);
    }

    /**
        @notice view function for next reward for specified address
        @param _recipient address
        @return uint256
     */
    function nextRewardFor(address _recipient) external view override returns (uint256) {
        uint256 reward;
        for (uint256 i = 0; i < info.length; i++) {
            if (info[i].recipient == _recipient) {
                reward = nextRewardAt(nextRewardRate(i), _recipient);
                break;
            }
        }
        return reward;
    }

    /**
     * @notice calculate the next reward rate
       @dev `apyVariable`, is calculated as: APYfixed + SCrs + SCys
            Where APYfixed is the fixed starting rate, with 9 decimals
            SCrs is the Control Return for Staking (with 9 decimals): SCrs = Drs * deltaTokenPrice
            SCys is Control Treasury for Staking (with 9 decimals): SCys = Dys * deltaTreasuryYield
            The returned rate is limited to a minimum of zero and a maximum of 1.5 times the fixed starting rate (in locked and unlocked tranches).
     * @param _index uint256
     * @return uint256 The reward rate. 9 decimals
     */
    function nextRewardRate(uint256 _index) public view override returns (uint256) {
        int256 apyVariable = (info[_index].start.toInt256())
            .add((ITreasury(treasury).deltaTokenPrice().mul(info[_index].drs)).div(10**9))
            .add((ITreasury(treasury).deltaTreasuryYield().mul(info[_index].dys)).div(10**9));

        if (apyVariable > 0) {
            uint256 _rate = deriveRate(uint256(apyVariable));
            uint256 maxRate = (info[_index].start * 15) / 10;
            return _rate < maxRate ? _rate : maxRate;
        } else {
            return 0;
        }
    }

    /* ====== POLICY FUNCTIONS ====== */

    /**
     * @notice set bounty to incentivize keepers
     * @param _bounty uint256
     */
    function setBounty(uint256 _bounty) external override onlyGovernor {
        require(_bounty <= 2e9, "Too much");
        bounty = _bounty;
        emit SetBounty(_bounty);
    }

    /**
        @notice adds recipient for distributions
        @dev    When a recipient is added, the epochLength and current block timestamp is used to calculate when the next epoch should occur
        @param _recipient address
        @param _startRate uint256 9 decimal starting rate
        @param _drs       uint256 9 decimal Discount Rate Return Staking. The discount rate applied to the fluctuation of the token price, as a proportion (that is, a percentage in its decimal form), with 9 decimals
        @param _dys       uint256 9 decimial discount rate applied to the fluctuation of the treasury yield, as a proportion (that is, a percentage in its decimal form), with 9 decimals
        @param _locked    bool is the staking tranche locked or unlocked
     */
    function addRecipient(
        address _recipient,
        uint256 _startRate,
        int256 _drs,
        int256 _dys,
        bool _locked
    ) external override onlyGovernor {
        require(_recipient != address(0), "Recipient cannot be the zero address");
        require(_startRate <= rateDenominator, "Rate cannot exceed denominator");

        info.push(
            Info({
                recipient: _recipient,
                start: _startRate,
                drs: _drs,
                dys: _dys,
                locked: _locked,
                nextEpochTime: uint48((block.timestamp).add(uint256(epochLength)))
            })
        );

        emit AddRecipient(
            _recipient,
            _startRate,
            _locked
        );
    }

    /**
        @notice set the address as a staking contract
        @dev setting the address as a staking contract will allow the staking contract to call the `distribute` function
             the contract must also be set up as a recipient to receive the rewards
        @param _addr address
     */
    function setStaking(address _addr) external override onlyGovernor {
        staking[_addr] = true;
        emit SetStakingContract(_addr);
    }

    /**
        @notice removes recipient for distributions
        @param _index uint
     */
    function removeRecipient(uint256 _index) external override {
        require(
            msg.sender == authority.governor() || msg.sender == authority.guardian(),
            "Caller is not governor or guardian"
        );
        require(info[_index].recipient != address(0), "Recipient does not exist");
        info[_index].recipient = address(0);
        info[_index].start = 0;
        info[_index].drs = 0;
        info[_index].dys = 0;
        emit RemoveRecipient(info[_index].recipient);
    }

    function setDiscountRateStaking(uint256 _index, int256 _drs) external override onlyPolicy {
        info[_index].drs = _drs;
        emit UpdateDRS(info[_index].recipient, _drs);
    }

    function setDiscountRateYield(uint256 _index, int256 _dys) external override onlyPolicy {
        info[_index].dys = _dys;
        emit UpdateDYS(info[_index].recipient, _dys);
    }

    /**
     * @notice derives the rate for a given apy for the next Epoch.
     * @dev    the rate is calculated as:
     *         1095 * e^z - 1095
     *         z = ln(apyProportion + 1) / 1095
     *         1095 is: 365(days) * 24(hours) / 8(hours per performance update)
     *         apyProportion is a proportion (that is, a percentage in its decimal form), calculated using the param _apy
     *         0x401cdcd6500000000000000000000000 is the byte representation of 10**9
     * @param _apy The APY to calculate the rate for. 9 decimals
     * @return uint256 The rate for the given APY. 9 decimals
     */
    function deriveRate(uint256 _apy) public view returns (uint256) {
        bytes16 apyProportion = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_apy), 0x401cdcd6500000000000000000000000);
        bytes16 z = ABDKMathQuad.div(ABDKMathQuad.ln(ABDKMathQuad.add(apyProportion, one)), n);
        bytes16 eToTheZ = ABDKMathQuad.exp(z);

        return
            ABDKMathQuad.toUInt(
                ABDKMathQuad.mul(ABDKMathQuad.sub(ABDKMathQuad.mul(n, eToTheZ), n), 0x401cdcd6500000000000000000000000)
            );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../Interfaces/ITheopetraAuthority.sol";

abstract contract TheopetraAccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(ITheopetraAuthority indexed authority);

    string constant UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    ITheopetraAuthority public authority;

    /* ========== Constructor ========== */

    constructor(ITheopetraAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyManager() {
        require(msg.sender == authority.manager(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    /* ========== GOV ONLY ========== */

    function setAuthority(ITheopetraAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}