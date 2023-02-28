// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

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
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
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
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
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
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
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
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
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
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
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
     *
     * _Available since v2.5._
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
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
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
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
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
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
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
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
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
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
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
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
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
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../vault/IVault.sol";
import "../..//storage/IStorage.sol";
import "./IModule.sol";

/**
 * @title BaseModule
 * @notice Base Module contract that contains methods common to all Modules.
 */
abstract contract BaseModule is IModule {

    // Empty calldata
    bytes constant internal EMPTY_BYTES = "";

    // Mock token address for ETH
    address constant internal ETH_TOKEN = address(0);

    // The guardians storage
    IStorage internal immutable Storage;

    event ModuleCreated(bytes32 name);
    // different types of signatures
    enum Signature {
        Owner,  
        KWG,
        OwnerandGuardian, 
        OwnerandGuardianOrOwnerandKWG,
        OwnerOrKWG,
        GuardianOrKWG,
        OwnerOrGuardianOrKWG
    }

    /**
     * @notice Throws if the vault is not locked.
     */
    modifier onlyWhenLocked(address _vault) {
        require(_isLocked(_vault), "BM: vault must be locked");
        _;
    }

    /**
     * @notice Throws if the vault is locked.
     */
    modifier onlyWhenUnlocked(address _vault) {
        require(!_isLocked(_vault), "BM: vault locked");
        _;
    }

    /**
     * @notice Throws if the sender is not the module itself.
     */
    modifier onlySelf() {
        require(_isSelf(msg.sender), "BM: must be module");
        _;
    }

    /**
     * @notice Throws if the sender is not the module itself or the owner of the target vault.
     */
    modifier onlyVaultOwnerOrSelf(address _vault) {
        require(
            _isSelf(msg.sender) ||
            _isOwner(_vault, msg.sender), 
            "BM: must be vault owner/self"
        );
        _;
    }

    /**
     * @dev Throws if the sender is not the target vault of the call.
     */
    modifier onlyVault(address _vault) {
        require(
            msg.sender == _vault,
            "BM: caller must be vault"
        );
        _;
    }

    /**
     * @param _Storage deployed instance of storage contract
     * @param _name - The name of the module.
     */
    constructor(
        IStorage _Storage,
        bytes32 _name
    ) {
        Storage = _Storage;
        emit ModuleCreated(_name);
    }
    
    /**
     * @notice Helper method to check if an address is the owner of a target vault.
     * @param _vault - The target vault.
     * @param _addr - The address.
     * @return true if it is address of owner
     */
    function _isOwner(address _vault, address _addr) internal view returns (bool) {
        return IVault(_vault).owner() == _addr;
    }

    /**
     * @notice Helper method to check if a vault is locked.
     * @param _vault - The target vault.
     */
    function _isLocked(address _vault) internal view returns (bool) {
        return Storage.isLocked(_vault);
    }

    /**
     * @notice Helper method to check if an address is the module itself.
     * @param _addr - The target address.
     * @return true if locked.
     */
    function _isSelf(address _addr) internal view returns (bool) {
        return _addr == address(this);
    }

    /**
     * @notice Helper method to invoke a vault.
     * @param _vault - The target vault.
     * @param _to - The target address for the transaction.
     * @param _value - The value of the transaction.
     * @param _data - The data of the transaction.
     * @return _res result of low level call from vault.
     */
    function invokeVault(
        address _vault,
        address _to,
        uint256 _value,
        bytes memory _data
    ) 
        internal
        returns
        (bytes memory _res) 
    {
        bool success;
        (success, _res) = _vault.call(
            abi.encodeWithSignature(
                "invoke(address,uint256,bytes)",
                _to,
                _value,
                _data
            )
        );
        if (success && _res.length > 0) {
            (_res) = abi.decode(_res, (bytes));
        } else if (_res.length > 0) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        } else if (!success) {
            revert("BM: vault invoke reverted");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IModule
 * @notice Interface for a Module.
 */
interface IModule {

    /**	
     * @notice Adds a module to a vault. Cannot execute when vault is locked (or under recovery)	
     * @param _vault The target vault.	
     * @param _module The modules to authorise.	
     */	
    function addModule(address _vault, address _module, bytes32 _initData) external;

    /**
     * @notice Inits a Module for a vault by e.g. setting some vault specific parameters in storage.
     * @param _vault The target vault.
     * @param _timeDelay - time in seconds to be expired before executing a queued request.
     */
    function init(address _vault, bytes32 _timeDelay) external;


    /**
     * @notice Returns whether the module implements a callback for a given static call method.
     * @param _methodId The method id.
     */
    function supportsStaticCall(bytes4 _methodId) external view returns (bool _isSupported);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Utils
 * @notice Common utility methods used by modules.
 */
library Utils {

    // ERC20, ERC721 & ERC1155 transfers & approvals
    bytes4 private constant ERC20_TRANSFER = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 private constant ERC20_APPROVE = bytes4(keccak256("approve(address,uint256)"));
    bytes4 private constant ERC721_SET_APPROVAL_FOR_ALL = bytes4(keccak256("setApprovalForAll(address,bool)"));
    bytes4 private constant ERC721_TRANSFER_FROM = bytes4(keccak256("transferFrom(address,address,uint256)"));
    bytes4 private constant ERC721_SAFE_TRANSFER_FROM = bytes4(keccak256("safeTransferFrom(address,address,uint256)"));
    bytes4 private constant ERC721_SAFE_TRANSFER_FROM_BYTES = bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"));
    bytes4 private constant ERC1155_SAFE_TRANSFER_FROM = bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)"));

    bytes4 private constant OWNER_SIG = 0x8da5cb5b;
    /**
    * @notice Helper method to recover the signer at a given position from a list of concatenated signatures.
    * @param _signedHash The signed hash
    * @param _signatures The concatenated signatures.
    * @param _index The index of the signature to recover.
    * @return the signer public address.
    */
    function recoverSigner(bytes32 _signedHash, bytes memory _signatures, uint _index) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        // we jump 32 (0x20) as the first slot of bytes contains the length
        // we jump 65 (0x41) per signature
        // for v we load 32 bytes ending with v (the first 31 come from s) then apply a mask
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(_signatures, add(0x20,mul(0x41,_index))))
            s := mload(add(_signatures, add(0x40,mul(0x41,_index))))
            v := and(mload(add(_signatures, add(0x41,mul(0x41,_index)))), 0xff)
        }
        require(v == 27 || v == 28, "U: bad v value in signature");

        address recoveredAddress = ecrecover(_signedHash, v, r, s);
        require(recoveredAddress != address(0), "U: ecrecover returned 0");
        return recoveredAddress;
    }

    /**
    * @notice Helper method to parse data and extract the method signature.
    * @param _data The calldata.
    * @return prefix The methodID for the calldata.
    */
    function functionPrefix(bytes memory _data) internal pure returns (bytes4 prefix) {
        require(_data.length >= 4, "U: Invalid functionPrefix");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            prefix := mload(add(_data, 0x20))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./common/Utils.sol";
import "./common/BaseModule.sol";
import "./KresusRelayer.sol";
import "./SecurityManager.sol";
import "./TransactionManager.sol";

/**
 * @title KresusModule
 * @notice Single module for Kresus vault.
 */
contract KresusModule is BaseModule, KresusRelayer, SecurityManager, TransactionManager {

    bytes32 constant public NAME = "KresusModule";
    address public immutable kresusGuardian;

    /**
     * @param _storage deployed instance of storage contract
     * @param _kresusGuardian default guardian from kresus.
     * @param _kresusGuardian default guardian of kresus for recovery and unblocking
     */
    constructor (
        IStorage _storage,
        address _kresusGuardian,
        address _refundAddress
    )
        BaseModule(_storage, NAME)
        KresusRelayer(_refundAddress)
    {
        kresusGuardian = _kresusGuardian;
    }

    /**
     * @inheritdoc IModule
     */
    function init(
        address _vault,
        bytes32 _timeDelay
    )
        external
        override
        onlyVault(_vault)
    {
        enableDefaultStaticCalls(_vault);
        Storage.setTimeDelay(_vault, uint256(_timeDelay));
    }

    /**
    * @inheritdoc IModule
    */
    function addModule(
        address _vault,
        address _module,
        bytes32 _initData
    )
        external
        onlySelf()
        onlyWhenUnlocked(_vault)
    {
        IVault(_vault).authoriseModule(_module, true, _initData);
    }
    
    /**
     * @inheritdoc KresusRelayer
     */
    function getRequiredSignatures(
        address _vault,
        bytes calldata _data
    )
        public
        view
        override
        returns (bool, bool, bool, Signature)
    {
        bytes4 methodId = Utils.functionPrefix(_data);
        bool VotingEnabled = Storage.votingEnabled(_vault);
        bool _locked = Storage.isLocked(_vault);

        if (methodId == TransactionManager.enableERC1155TokenReceiver.selector ||
            methodId == KresusModule.addModule.selector ||
            methodId == SecurityManager.addGuardian.selector
        )
        {
            return((VotingEnabled == false) ? (!_locked, true, false, Signature.Owner):(!_locked, true, false, Signature.OwnerandGuardian)); 
        }

        if (methodId == SecurityManager.transferOwnership.selector){
            return((VotingEnabled == false) ? (!_locked, true, false, Signature.Owner):(!_locked, true, false, Signature.OwnerandGuardian)); 
        }
        if (methodId == SecurityManager.revokeGuardian.selector){
            return((VotingEnabled == false) ? (true, true, false, Signature.OwnerOrGuardianOrKWG):(true, true, false, Signature.OwnerandGuardianOrOwnerandKWG)); 
        }
        if (methodId == SecurityManager.lock.selector) {
            return((VotingEnabled == false) ? (!_locked, false, false, Signature.OwnerOrKWG):(!_locked, false, false, Signature.OwnerOrGuardianOrKWG)); 
        }
        if (methodId == TransactionManager.multiCall.selector){ 
            return( (VotingEnabled == false) ? (!_locked, true, true, Signature.Owner):(!_locked, true, true, Signature.OwnerandGuardian) );    
        }
        if (methodId == SecurityManager.unlock.selector) {
            return(( VotingEnabled == false) ? (_locked, true, false, Signature.KWG):(_locked, true, false, Signature.GuardianOrKWG)); 
        }
        if (methodId == SecurityManager.lock.selector) {
            return(( VotingEnabled == false) ? (!_locked, false, false, Signature.OwnerOrKWG):(!_locked, false, false, Signature.OwnerOrGuardianOrKWG)); 
        }
        if (methodId == SecurityManager.toggleVoting.selector) {
            return(( VotingEnabled == false) ? (!_locked, false, false, Signature.Owner):(!_locked, false, false, Signature.OwnerandGuardian)); 
        }
        if(methodId == SecurityManager.setTimeDelay.selector) {
            return ((VotingEnabled == false) ? (!_locked, true, false, Signature.Owner) : (!_locked, false, false, Signature.OwnerandGuardian));
        }
        revert("SM: unknown method");
    }

    /**
     * @param _vault The target vault.
     * @param _data _data The calldata for the required transaction.
     * @return Signature The required signature from {Signature} enum .
     */
    function getCancelRequiredSignatures(
        address _vault,
        bytes calldata _data
    )
        public
        view
        override
        returns(Signature)
    {
        bytes4 methodId = Utils.functionPrefix(_data);
        if(
            methodId == SecurityManager.transferOwnership.selector ||
            methodId == SecurityManager.addGuardian.selector ||
            methodId == SecurityManager.revokeGuardian.selector
        ){
            return Signature.Owner;
        }
        if(methodId == TransactionManager.multiCall.selector && !Storage.votingEnabled(_vault)) {
            return Signature.Owner;
        }
        revert("SM: unknown method");
    }

    /**
    * @notice Validates the signatures provided with a relayed transaction.
    * @param _vault The target vault.
    * @param _signHash The signed hash representing the relayed transaction.
    * @param _signatures The signatures as a concatenated bytes array.
    * @param _option An OwnerSignature enum indicating whether the owner is required, optional or disallowed.
    * @return A boolean indicating whether the signatures are valid.
    */
    function validateSignatures(
        address _vault,
        bytes32 _signHash,
        bytes memory _signatures,
        Signature _option
    ) 
        public 
        view
        override
        returns (bool)
    {
        if ((_signatures.length < 65))
        {
            return false;
        }

        address signer0 = Utils.recoverSigner(_signHash, _signatures, 0);
        address _ownerAddr = IVault(_vault).owner();
    
        if((
            _option == Signature.Owner || 
            _option == Signature.OwnerOrKWG || 
            _option == Signature.OwnerOrGuardianOrKWG
           ) 
           &&
           signer0 == _ownerAddr
        )
        {
            return true;
        }

        if((
            _option == Signature.KWG ||
            _option == Signature.OwnerOrKWG ||
            _option == Signature.GuardianOrKWG ||
            _option == Signature.OwnerOrGuardianOrKWG
           ) 
           &&
           signer0 == kresusGuardian
        )
        {
            return true;
        }

        address _guardianAddr = Storage.getGuardian(_vault);

        if((
            _option == Signature.GuardianOrKWG ||
             _option == Signature.OwnerOrGuardianOrKWG
           )
           &&
           signer0 == _guardianAddr
        )
        {
            return true;
        }

        address signer1 = Utils.recoverSigner(_signHash, _signatures, 1);

        if((
            _option == Signature.OwnerandGuardian || _option == Signature.OwnerandGuardianOrOwnerandKWG
           ) 
           && 
           signer0 == _ownerAddr 
           && 
           signer1 == _guardianAddr
        )
        {
            return true;
        }
        
        if((
            _option == Signature.OwnerandGuardianOrOwnerandKWG
           ) 
           && 
           signer0 == _ownerAddr 
           && 
           (signer1 == kresusGuardian)
        )
        {
            return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./common/Utils.sol";
import "./common/BaseModule.sol";
import "../storage/IStorage.sol";
/**
 * @title KresusRelayer
 * @notice Abstract Module to execute transactions signed by ETH-less accounts and sent by a relayer.
 */
abstract contract KresusRelayer is BaseModule {

    uint256 constant BLOCKBOUND = 10000;

    address public refundAddress;

    struct RelayerConfig {
        uint256 nonce;
        mapping(bytes32 => uint256) queuedTransactions;
        mapping(bytes32 => uint256) arrayindex;
        bytes32[] queue;
    }

    mapping (address => RelayerConfig) internal relayer;


    // Used to avoid stack too deep error
    struct StackExtension {
        Signature SignatureRequirement;
        bytes32 signHash;
        bool success;
        bytes returnData;
    }

    event TransactionExecuted(address indexed vault, bool indexed success, bytes returnData, bytes32 signedHash);
    event TransactionQueued(address indexed vault, uint256 executionTime, bytes32 signedHash);
    event Refund(address indexed vault, address indexed refundAddress, uint256 refundAmount);
    event ActionCancelled(address indexed vault);
    event AllActionsCancelled(address indexed vault);

    /**
     * @param _refundAddress the adress which the refund amount is sent.
     */
    constructor(
        address _refundAddress
    ) {
        refundAddress = _refundAddress;
    }
    
    /**
    * @notice Executes a relayed transaction.
    * @param _vault The target vault.
    * @param _data The data for the relayed transaction
    * @param _nonce The nonce used to prevent replay attacks.
    * @param _signatures The signatures as a concatenated byte array.
    * @return true if executed or queued successfully, else returns false.
    */
    function execute(
        address _vault,
        bytes calldata _data,
        uint256 _nonce,
        bytes calldata _signatures
    )
        external
        returns (bool)
    {
        // initial gas = 21k + non_zero_bytes * 16 + zero_bytes * 4
        //            ~= 21k + calldata.length * [1/3 * 16 + 2/3 * 4]
        uint256 startGas = gasleft() + 21000 + msg.data.length * 8;
        require(verifyData(_vault, _data), "KR: Target of _data != _vault");

        StackExtension memory stack;
        bool queue;
        bool _refund;
        bool allowed;
        (allowed, queue, _refund, stack.SignatureRequirement) = getRequiredSignatures(_vault, _data);

        require(allowed, "KR: Operation not allowed");

        stack.signHash = getSignHash(
            _vault,
            0,
            _data,
            _nonce
        );

        // Execute a queued tx
        if (isActionQueued(_vault, stack.signHash)){
            require(relayer[_vault].queuedTransactions[stack.signHash] < block.timestamp, "KR: Time not expired");
            (stack.success, stack.returnData) = address(this).call(_data);
            removeQueue(_vault, stack.signHash);
            emit TransactionExecuted(_vault, stack.success, stack.returnData, stack.signHash);
            if(_refund) {
                refund(_vault, startGas);
            } 
            return stack.success;
        }
        
        
        require(validateSignatures(
                _vault, 
                stack.signHash,
                _signatures, 
                stack.SignatureRequirement
            ),
            "KR: Invalid Signatures"
        );

        require(checkAndUpdateUniqueness(_vault, _nonce), "KR: Duplicate request");
        

        // Queue the Tx
        if(queue == true) {
            relayer[_vault].queuedTransactions[stack.signHash] = block.timestamp + Storage.getTimeDelay(_vault);
            relayer[_vault].queue.push(stack.signHash);
            relayer[_vault].arrayindex[stack.signHash] = relayer[_vault].queue.length-1;
            emit TransactionQueued(_vault, block.timestamp + Storage.getTimeDelay(_vault), stack.signHash);
            return true;
        }
         // Execute the tx directly without queuing
        else{
            (stack.success, stack.returnData) = address(this).call(_data); 
            emit TransactionExecuted(_vault, stack.success, stack.returnData, stack.signHash);
            if(_refund) {
                refund(_vault, startGas);
            }
            return stack.success;
        }
    }  

    /**
     * @notice cancels a transaction which was queued.
     * @param _vault The target vault.
     * @param _data The data for the relayed transaction.
     * @param _nonce The nonce used to prevent replay attacks.
     * @param _signature The signature needed to validate cancel.
     */
    function cancel(
        address _vault,
        bytes calldata _data,
        uint256 _nonce,
        bytes memory _signature
    ) 
        external 
    {
        bytes32 _actionHash = getSignHash(_vault, 0, _data, _nonce);
        bytes32 _cancelHash = getSignHash(_vault, 0, "0x", _nonce);
        require(isActionQueued(_vault, _actionHash), "KR: Invalid hash");
        Signature _sig = getCancelRequiredSignatures(_vault, _data);
        require(
            validateSignatures(
                _vault,
                _cancelHash,
                _signature,
                _sig
            ), "KR: Invalid Signatures"
        );
        removeQueue(_vault, _actionHash);
        emit ActionCancelled(_vault);
    }

    /**
     * @notice to cancel all the queued operations for a `_vault` address.
     * @param _vault The target vault.
     */
    function cancelAll(
        address _vault
    ) external onlySelf {
        uint256 len = relayer[_vault].queue.length; 
        for(uint256 i=0;i<len;i++) {
            bytes32 _actionHash = relayer[_vault].queue[i];
            require(isActionQueued(_vault, _actionHash), "KR: Invalid hash");
            relayer[_vault].queuedTransactions[_actionHash] = 0;
            relayer[_vault].arrayindex[_actionHash] = 0;
        }
        delete relayer[_vault].queue;
        emit AllActionsCancelled(_vault);
    }

    /**
    * @notice Gets the current nonce for a vault.
    * @param _vault The target vault.
    * @return nonce gets the last used nonce of the vault.
    */
    function getNonce(address _vault) external view returns (uint256 nonce) {
        return relayer[_vault].nonce;
    }

    /**
    * @notice Gets the number of valid signatures that must be provided to execute a
    * specific relayed transaction.
    * @param _vault The target vault.
    * @param _data The data of the relayed transaction.
    * @return The number of required signatures and the vault owner signature requirement.
    */
    function getRequiredSignatures(address _vault, bytes calldata _data) public view virtual returns (bool, bool, bool, Signature);

    /**
    * @notice checks validity of a signature depending on status of the vault.
    * @param _vault The target vault.
    * @param _actionHash signed hash of the request.
    * @param _data The data of the relayed transaction.
    * @param _option Type of signature.
    * @return true if it is a valid signature.
    */
    function validateSignatures(
        address _vault,
        bytes32 _actionHash,
        bytes memory _data,
        Signature _option
    ) public view virtual returns(bool);

    /**
    * @notice Gets the required signature from {Signature} enum to cancel the request.
    * @param _vault The target vault.
    * @param _data The data of the relayed transaction.
    * @return The required signature from {Signature} enum .
    */ 
    function getCancelRequiredSignatures(
        address _vault,
        bytes calldata _data
    ) public view virtual returns(Signature);

    /**
    * @notice Generates the signed hash of a relayed transaction according to ERC 1077.
    * @param _from The starting address for the relayed transaction (should be the relayer module)
    * @param _value The value for the relayed transaction.
    * @param _data The data for the relayed transaction which includes the vault address.
    * @param _nonce The nonce used to prevent replay attacks.
    */
    function getSignHash(
        address _from,
        uint256 _value,
        bytes memory _data,
        uint256 _nonce
    )
        public
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(
                    bytes1(0x19),
                    bytes1(0),
                    _from,
                    _value,
                    _data,
                    block.chainid,
                    _nonce
                ))
            )
        );
    }

    /**
    * @notice Checks if the relayed transaction is unique. If yes the state is updated.
    * @param _vault The target vault.
    * @param _nonce The nonce.
    * @return true if the transaction is unique.
    */
    function checkAndUpdateUniqueness(
        address _vault,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        // use the incremental nonce
        if (_nonce <= relayer[_vault].nonce) {
            return false;
        }
        uint256 nonceBlock = (_nonce & 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000) >> 128;
        if (nonceBlock > block.number + BLOCKBOUND) {
            return false;
        }
        relayer[_vault].nonce = _nonce;
        return true;
    }
       

    /**
    * @notice Refunds the gas used to the Relayer.
    * @param _vault The target vault.
    * @param _startGas The gas provided at the start of the execution.
    */
    function refund(
        address _vault,
        uint _startGas
    )
        internal
    {
            uint256 refundAmount;
            uint256 gasConsumed = _startGas - gasleft() + 23000;
            refundAmount = gasConsumed * tx.gasprice;
            invokeVault(_vault, refundAddress, refundAmount, EMPTY_BYTES);
            emit Refund(_vault, refundAddress, refundAmount);    
    }

    /**
    * @notice Checks that the vault address provided as the first parameter of _data matches _vault
    * @return false if the addresses are different.
    */
    function verifyData(address _vault, bytes calldata _data) internal pure returns (bool) {
        require(_data.length >= 36, "KR: Invalid dataVault");
        address dataVault = abi.decode(_data[4:], (address));
        return dataVault == _vault;
    }

    /**
    * @notice Check whether a given action is queued.
    * @param _vault The target vault.
    * @param  actionHash  Hash of the action to be checked. 
    * @return Boolean `true` if the underlying action of `actionHash` is queued, otherwise `false`.
    */
    function isActionQueued(
        address _vault,
        bytes32 actionHash
    )
        public
        view
        returns (bool)
    {
        return (relayer[_vault].queuedTransactions[actionHash] > 0);
    }

    /**
    * @notice Return execution time for a given queued action.
    * @param _vault The target vault.
    * @param  actionHash  Hash of the action to be checked.
    * @return uint256   execution time for a given queued action.
    */
    function queuedActionExectionTime(
        address _vault,
        bytes32 actionHash
    )
        external
        view
        returns (uint256)
    {
        return relayer[_vault].queuedTransactions[actionHash];
    }
    
    /**
    * @notice Removes an element at index from the array queue of a user
    * @param _vault The target vault.
    * @param  _actionHash  Hash of the action to be checked.
    * @return false if the index is invalid.
    */
    function removeQueue(address _vault, bytes32 _actionHash) internal returns(bool) {
        RelayerConfig storage _relayer = relayer[_vault];
        _relayer.queuedTransactions[_actionHash] = 0;

        uint256 index = _relayer.arrayindex[_actionHash];
        uint256 len = _relayer.queue.length;
        _relayer.arrayindex[_actionHash] = 0;
        _relayer.queue[index] = _relayer.queue[len - 1];
        _relayer.queue.pop();
        
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./common/Utils.sol";
import "./common/BaseModule.sol";
import "./KresusRelayer.sol";
import "../vault/IVault.sol";

/**
 * @title SecurityManager
 * @notice Abstract module implementing the key security features of the vault: guardians, lock and recovery.
 */
abstract contract SecurityManager is BaseModule {
    event OwnershipTransfered(address indexed vault, address indexed _newOwner);
    event Locked(address indexed vault);
    event Unlocked(address indexed vault);
    event GuardianAdded(address indexed vault, address indexed guardian);
    event GuardianRevoked(address indexed vault, address indexed guardian);
    event VotingToggled(address indexed vault, bool votingEnabled);
    event TimeDelayChanged(address indexed vault, uint256 newTimeDelay);

    /**
     * @notice Throws if the caller is not a guardian for the vault or the module itself.
     */
    modifier onlyGuardianOrSelf(address _vault) {
        require(
            _isSelf(msg.sender) || isGuardian(_vault, msg.sender),
            "SM: must be guardian/self"
        );
        _;
    }

    /**
     * @notice Lets the owner transfer the vault ownership. This is executed immediately.
     * @param _vault The target vault.
     * @param _newOwner The address to which ownership should be transferred.
     */
    function transferOwnership(
        address _vault,
        address _newOwner
    )
        external
        onlySelf()
        onlyWhenUnlocked(_vault)
    {
        validateNewOwner(_vault, _newOwner);
        IVault(_vault).setOwner(_newOwner);
        (bool success, ) = address(this).call(
            abi.encodeWithSignature("cancelAll(address)", _vault)
        );
        require(success, "SM: cancel all operation failed");
        emit OwnershipTransfered(_vault, _newOwner);
    }

    /**
     * @notice Lets a guardian lock a vault.
     * @param _vault The target vault.
     */
    function lock(address _vault) external onlySelf() onlyWhenUnlocked(_vault) {
        Storage.setLock(_vault, true);
        (bool success, ) = address(this).call(
            abi.encodeWithSignature("cancelAll(address)", _vault)
        );
        require(success, "SM: cancel all operation failed");
        // KresusRelayer(_vault).cancelAll(_vault);
        emit Locked(_vault);
    }

    /**
     * @notice Updates the TimeDelay
     * @param _vault The target vault.
     * @param _newTimeDelay The new DelayTime to update.
     */
    function setTimeDelay(
        address _vault,
        uint256 _newTimeDelay
    )
        external
        onlySelf()
        onlyWhenUnlocked(_vault)
    {
        Storage.setTimeDelay(_vault, _newTimeDelay);
        emit TimeDelayChanged(_vault, _newTimeDelay);
    }

    /**
     * @notice Lets a guardian unlock a locked vault.
     * @param _vault The target vault.
     */
    function unlock(
        address _vault
    ) 
        external
        onlySelf()
        onlyWhenLocked(_vault)
    {
        Storage.setLock(_vault, false);
        emit Unlocked(_vault);
    }

    /**
     * @notice To turn votig on and off.
     * @param _vault The target vault.
     */
    function toggleVoting(
        address _vault
    ) 
        external
        onlySelf()
        onlyWhenUnlocked(_vault)
    {
        Storage.toggleVoting(_vault);
        emit VotingToggled(_vault, Storage.votingEnabled(_vault));
    }


    /**
     * @notice Lets the owner add a guardian to its vault.
     * The first guardian is added immediately. All following additions must be confirmed
     * by calling the confirmGuardianAddition() method.
     * @param _vault The target vault.
     * @param _guardian The guardian to add.
     */
    function addGuardian(
        address _vault,
        address _guardian
    ) 
        external 
        onlySelf() 
        onlyWhenUnlocked(_vault) {
        Storage.addGuardian(_vault, _guardian);
        emit GuardianAdded(_vault, _guardian);
    }
    
    /**
     * @notice Lets the owner revoke a guardian from its vault.
     * @dev Revokation must be confirmed by calling the confirmGuardianRevokation() method.
     * @param _vault The target vault.
     * @param _guardian The guardian to revoke.
     */
    function revokeGuardian(
        address _vault,
        address _guardian
    ) external onlySelf() 
    {
        Storage.revokeGuardian(_vault);
        emit GuardianRevoked(_vault, _guardian);
    }

    /**
     * @notice Checks if an address is a guardian for a vault.
     * @param _vault The target vault.
     * @param _guardian The address to check.
     * @return _isGuardian `true` if the address is a guardian for the vault otherwise `false`.
     */
    function isGuardian(
        address _vault,
        address _guardian
    ) 
        public
        view
        returns(bool _isGuardian)
    {
        return Storage.isGuardian(_vault, _guardian);
    }

    /**
     * @notice Checks if the vault address is valid to be a new owner.
     * @param _vault The target vault.
     * @param _newOwner The target vault.
     */
    function validateNewOwner(address _vault, address _newOwner) internal view {
        require(_newOwner != address(0), "SM: new owner cannot be null");
        require(!isGuardian(_vault, _newOwner), "SM: new owner cannot be guardian");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./common/Utils.sol";
import "./common/BaseModule.sol";

/**
 * @title TransactionManager
 * @notice Module to execute transactions in sequence to e.g. transfer tokens (ETH, ERC20, ERC721, ERC1155) or call third-party contracts.
 */
abstract contract TransactionManager is BaseModule {

    // Static calls
    bytes4 private constant ERC1271_IS_VALID_SIGNATURE = bytes4(keccak256("isValidSignature(bytes32,bytes)"));
    bytes4 private constant ERC721_RECEIVED = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    bytes4 private constant ERC1155_RECEIVED = bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    bytes4 private constant ERC1155_BATCH_RECEIVED = bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    bytes4 private constant ERC165_INTERFACE = bytes4(keccak256("supportsInterface(bytes4)"));

    struct Call {
        address to;      //the target address to which transaction to be sent
        uint256 value;   //native amount to be sent.
        bytes data;      //the data for the transaction.
    }

    /**
     * @notice Makes the target vault execute a sequence of transactions
     * The method reverts if any of the inner transactions reverts.
     * @param _vault The target vault.
     * @param _transactions The sequence of transactions.
     * @return bytes array of results for  all low level calls.
     */
    function multiCall(
        address _vault,
        Call[] calldata _transactions
    )
        external 
        onlySelf()
        onlyWhenUnlocked(_vault)
        returns (bytes[] memory)
    {
        return multiCallWithApproval(_vault, _transactions);
    }
    
    /*
    * @notice Enable the static calls required to make the vault compatible with the ERC1155TokenReceiver 
    * interface (see https://eips.ethereum.org/EIPS/eip-1155#erc-1155-token-receiver). This method only 
    * needs to be called for wallets deployed in version lower or equal to 2.4.0 as the ERC1155 static calls
    * are not available by default for these versions of BaseWallet
    * @param _vault The target vault.
    */
    function enableERC1155TokenReceiver(address _vault) external onlyVaultOwnerOrSelf(_vault) onlyWhenUnlocked(_vault) {
        IVault(_vault).enableStaticCall(address(this), ERC165_INTERFACE);
        IVault(_vault).enableStaticCall(address(this), ERC1155_RECEIVED);
        IVault(_vault).enableStaticCall(address(this), ERC1155_BATCH_RECEIVED);
    }

    /**
     * @inheritdoc IModule
     */
    function supportsStaticCall(bytes4 _methodId) external pure override returns (bool _isSupported) {
        return _methodId == ERC1271_IS_VALID_SIGNATURE ||
               _methodId == ERC721_RECEIVED ||
               _methodId == ERC165_INTERFACE ||
               _methodId == ERC1155_RECEIVED ||
               _methodId == ERC1155_BATCH_RECEIVED;
    }

    /**
     * @notice Returns true if this contract implements the interface defined by
     * `interfaceId` (see https://eips.ethereum.org/EIPS/eip-165).
     */
    function supportsInterface(bytes4 _interfaceID) external pure returns (bool) {
        return  _interfaceID == ERC165_INTERFACE || _interfaceID == (ERC1155_RECEIVED ^ ERC1155_BATCH_RECEIVED);          
    }


    fallback() external {
        bytes4 methodId = Utils.functionPrefix(msg.data);
        if(methodId == ERC721_RECEIVED || methodId == ERC1155_RECEIVED || methodId == ERC1155_BATCH_RECEIVED) {
            // solhint-disable-next-line no-inline-assembly
            assembly {                
                calldatacopy(0, 0, 0x04)
                return (0, 0x20)
            }
        }
    }

    function enableDefaultStaticCalls(address _vault) internal {
        // setup the static calls that are available for free for all wallets
        IVault(_vault).enableStaticCall(address(this), ERC1271_IS_VALID_SIGNATURE);
        IVault(_vault).enableStaticCall(address(this), ERC721_RECEIVED);
    }

    function multiCallWithApproval(address _vault, Call[] calldata _transactions) internal returns (bytes[] memory) {
        bytes[] memory results = new bytes[](_transactions.length);
        for(uint i = 0; i < _transactions.length; i++) {
            results[i] = invokeVault(
                _vault,
                _transactions[i].to,
                _transactions[i].value,
                _transactions[i].data
            );
        }
        return results;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IStorage
 * @notice Interface for Storage
 */
interface IStorage {

    /**
     * @notice Lets an authorised module add a guardian to a vault.
     * @param _vault - The target vault.
     * @param _guardian - The guardian to add.
     */
    function addGuardian(address _vault, address _guardian) external;

    /**
     * @notice Lets an authorised module revoke a guardian from a vault.
     * @param _vault - The target vault.
     */
    function revokeGuardian(address _vault) external;

    /**
     * @notice Function to be used to add heir address to bequeath vault ownership.
     * @param _vault - The target vault.
     */
    function addHeir(address _vault, address _newHeir) external;

    /**
     * @notice Lets an authorised module revoke a guardian from a vault.
     * @param _vault - The target vault.
     */
    function revokeHeir(address _vault) external;

    /**
     * @notice Function to be called when voting has to be toggled.
     * @param _vault - The target vault.
     */
    function toggleVoting(address _vault) external;

    /**
     * @notice Set or unsets lock for a vault contract.
     * @param _vault - The target vault.
     * @param _lock - Lock needed to be set.
     */
    function setLock(address _vault, bool _lock) external;

    /**
     * @notice Sets a new time delay for a vault contract.
     * @param _vault - The target vault.
     * @param _newTimeDelay - The new time delay.
     */
    function setTimeDelay(address _vault, uint256 _newTimeDelay) external;

    /**
     * @notice Checks if an account is a guardian for a vault.
     * @param _vault - The target vault.
     * @param _guardian - The account address to be checked.
     * @return true if the account is a guardian for a vault.
     */
    function isGuardian(address _vault, address _guardian) external view returns (bool);

    /**
     * @notice Returns guardian address.
     * @param _vault - The target vault.
     * @return the address of the guardian account if guardian is added else returns zero address.
     */
    function getGuardian(address _vault) external view returns (address);

    /**
     * @notice Returns boolean indicating state of the vault.
     * @param _vault - The target vault.
     * @return true if the vault is locked, else returns false.
     */
    function isLocked(address _vault) external view returns (bool);

    /**
     * @notice Returns boolean indicating if voting is enabled.
     * @param _vault - The target vault.
     * @return true if voting is enabled, else returns false.
     */
    function votingEnabled(address _vault) external view returns (bool);

    /**
     * @notice Returns uint256 time delay in seconds for a vault
     * @param _vault - The target vault.
     * @return uint256 time delay in seconds for a vault.
     */
    function getTimeDelay(address _vault) external view returns (uint256);

    /**
     * @notice Returns an heir address for a vault.
     * @param _vault - The target vault.
     */
    function getHeir(address _vault) external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IVault
 * @notice Interface for the BaseVault
 */
interface IVault {
    /**
     * @notice Returns the vault owner.
     * @return The vault owner address.
     */
    function owner() external view returns (address);

    /**
     * @notice Returns the number of authorised modules.
     * @return The number of authorised modules.
     */
    function modules() external view returns (uint);

    /**
     * @notice Sets a new owner for the vault.
     * @param _newOwner The new owner.
     */
    function setOwner(address _newOwner) external;

    /**
     * @notice Checks if a module is authorised on the vault.
     * @param _module The module address to check.
     * @return `true` if the module is authorised, otherwise `false`.
     */
    function authorised(address _module) external view returns (bool);

    /**
     * @notice Returns the module responsible for a static call redirection.
     * @param _sig The signature of the static call.
     * @return the module doing the redirection
     */
    function enabled(bytes4 _sig) external view returns (address);

    /**
     * @notice Enables/Disables a module.
     * @param _module The target module.
     * @param _value Set to `true` to authorise the module.
     */
    function authoriseModule(address _module, bool _value, bytes32 _initData) external;

    /**
    * @notice Enables a static method by specifying the target module to which the call must be delegated.
    * @param _module The target module.
    * @param _method The static method signature.
    */
    function enableStaticCall(address _module, bytes4 _method) external;
}