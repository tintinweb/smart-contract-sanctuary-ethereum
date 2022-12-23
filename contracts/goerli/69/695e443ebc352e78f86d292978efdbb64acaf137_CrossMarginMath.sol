// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.4.1) (utils/math/SafeCast.sol)

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
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
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
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
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
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
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
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
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
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
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
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
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
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
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
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
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
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
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
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
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
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
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
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
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
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
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
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
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
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
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
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
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
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
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
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
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
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
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
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
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
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
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
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
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
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
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
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
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
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
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
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
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
     * - input must fit into 8 bits
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
pragma solidity ^0.8.0;

///@dev unit used for option amount and strike prices
uint8 constant UNIT_DECIMALS = 6;

///@dev unit scaled used to convert amounts.
uint256 constant UNIT = 10 ** 6;

///@dev int scaled used to convert amounts.
int256 constant sUNIT = int256(10 ** 6);

///@dev basis point for 100%.
uint256 constant BPS = 10000;

///@dev uint zero
uint256 constant ZERO = 0;

/// @dev int zero
int256 constant sZERO = int256(0);

///@dev maximum dispute period for oracle
uint256 constant MAX_DISPUTE_PERIOD = 6 hours;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum TokenType {
    PUT,
    PUT_SPREAD,
    CALL,
    CALL_SPREAD
}

/**
 * @dev action types
 */
enum ActionType {
    AddCollateral,
    RemoveCollateral,
    MintShort,
    BurnShort,
    MergeOptionToken,
    SplitOptionToken,
    AddLong,
    RemoveLong,
    SettleAccount,
    // actions that influece more than one subAccounts:
    MintShortIntoAccount, // increase short (debt) position in one subAccount, increase long token directly to another subAccount
    TransferCollateral, // transfer collateral direclty to another subAccount
    TransferLong, // transfer long directly to another subAccount
    TransferShort // transfer short directly to another subAccount
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// for easier import
import "../core/oracles/errors.sol";
import "../core/engines/full-margin/errors.sol";
import "../core/engines/advanced-margin/errors.sol";
import "../core/engines/cross-margin/errors.sol";

/* ------------------------ *
 *      Shared Errors       *
 * -----------------------  */

error NoAccess();

/* ------------------------ *
 *      Grappa Errors       *
 * -----------------------  */

/// @dev asset already registered
error GP_AssetAlreadyRegistered();

/// @dev margin engine already registered
error GP_EngineAlreadyRegistered();

/// @dev oracle already registered
error GP_OracleAlreadyRegistered();

/// @dev registring oracle doesn't comply with the max dispute period constraint.
error GP_BadOracle();

/// @dev amounts length speicified to batch settle doesn't match with tokenIds
error GP_WrongArgumentLength();

/// @dev cannot settle an unexpired option
error GP_NotExpired();

/// @dev settlement price is not finalized yet
error GP_PriceNotFinalized();

/// @dev cannot mint token after expiry
error GP_InvalidExpiry();

/// @dev put and call should not contain "short stirkes"
error GP_BadStrikes();

/// @dev burn or mint can only be called by corresponding engine.
error GP_Not_Authorized_Engine();

/* ---------------------------- *
 *   Common BaseEngine Errors   *
 * ---------------------------  */

/// @dev can only merge subaccount with put or call.
error BM_CannotMergeSpread();

/// @dev only spread position can be split
error BM_CanOnlySplitSpread();

/// @dev type of existing short token doesn't match the incoming token
error BM_MergeTypeMismatch();

/// @dev product type of existing short token doesn't match the incoming token
error BM_MergeProductMismatch();

/// @dev expiry of existing short token doesn't match the incoming token
error BM_MergeExpiryMismatch();

/// @dev cannot merge type with the same strike. (should use burn instead)
error BM_MergeWithSameStrike();

/// @dev account is not healthy / account is underwater
error BM_AccountUnderwater();

/// @dev msg.sender is not authorized to ask margin account to pull token from {from} address
error BM_InvalidFromAddress();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./enums.sol";

/**
 * @dev struct representing the current balance for a given collateral
 * @param collateralId grappa asset id
 * @param amount amount the asset
 */
struct Balance {
    uint8 collateralId;
    uint80 amount;
}

/**
 * @dev struct containing assets detail for an product
 * @param underlying    underlying address
 * @param strike        strike address
 * @param collateral    collateral address
 * @param collateralDecimals collateral asset decimals
 */
struct ProductDetails {
    address oracle;
    uint8 oracleId;
    address engine;
    uint8 engineId;
    address underlying;
    uint8 underlyingId;
    uint8 underlyingDecimals;
    address strike;
    uint8 strikeId;
    uint8 strikeDecimals;
    address collateral;
    uint8 collateralId;
    uint8 collateralDecimals;
}

// todo: update doc
struct ActionArgs {
    ActionType action;
    bytes data;
}

struct BatchExecute {
    address subAccount;
    ActionArgs[] actions;
}

/**
 * @dev asset detail stored per asset id
 * @param addr address of the asset
 * @param decimals token decimals
 */
struct AssetDetail {
    address addr;
    uint8 decimals;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* ------------------------ *
 *  Advanced Margin Errors
 * -----------------------  */

/// @dev full margin doesn't support this action (add long and remove long)
error AM_UnsupportedAction();

/// @dev collateral id is wrong: the id doesn't match the existing collateral
error AM_WrongCollateralId();

/// @dev trying to merge an long with a non-existant short position
error AM_ShortDoesnotExist();

/// @dev can only merge same amount of long and short
error AM_MergeAmountMisMatch();

/// @dev can only split same amount of existing spread into short + long
error AM_SplitAmountMisMatch();

/// @dev invalid tokenId specify to mint / burn actions
error AM_InvalidToken();

/// @dev no config set for this asset.
error AM_NoConfig();

/// @dev cannot liquidate or takeover position: account is healthy
error AM_AccountIsHealthy();

/// @dev cannot override a non-empty subaccount id
error AM_AccountIsNotEmpty();

/// @dev amounts to repay in liquidation are not valid. Missing call, put or not proportional to the amount in subaccount.
error AM_WrongRepayAmounts();

/// @dev cannot remove collateral because there are expired longs
error AM_ExpiredShortInAccount();

// Vol Oracle

/// @dev cannot re-set aggregator
error VO_AggregatorAlreadySet();

/// @dev no aggregator set
error VO_AggregatorNotSet();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../libraries/TokenIdUtil.sol";
import "../../../libraries/ArrayUtil.sol";

// cross margin types
import "./types.sol";

library AccountUtil {
    using TokenIdUtil for uint192;
    using TokenIdUtil for uint256;

    function append(CrossMarginDetail[] memory x, CrossMarginDetail memory v)
        internal
        pure
        returns (CrossMarginDetail[] memory y)
    {
        y = new CrossMarginDetail[](x.length + 1);
        uint256 i;
        for (i; i < x.length;) {
            y[i] = x[i];
            unchecked {
                ++i;
            }
        }
        y[i] = v;
    }

    function append(Position[] memory x, Position memory v) internal pure returns (Position[] memory y) {
        y = new Position[](x.length + 1);
        uint256 i;
        for (i; i < x.length;) {
            y[i] = x[i];
            unchecked {
                ++i;
            }
        }
        y[i] = v;
    }

    function concat(Position[] memory a, Position[] memory b) internal pure returns (Position[] memory y) {
        y = new Position[](a.length + b.length);
        uint256 v;
        uint256 i;
        for (i; i < a.length;) {
            y[v] = a[i];
            unchecked {
                ++i;
                ++v;
            }
        }
        for (i = 0; i < b.length;) {
            y[v] = b[i];
            unchecked {
                ++i;
                ++v;
            }
        }
    }

    /// @dev currently unused
    function find(Position[] memory x, uint256 v) internal pure returns (bool f, Position memory p, uint256 i) {
        for (i; i < x.length;) {
            if (x[i].tokenId == v) {
                p = x[i];
                f = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    function find(PositionOptim[] memory x, uint192 v) internal pure returns (bool f, PositionOptim memory p, uint256 i) {
        for (i; i < x.length;) {
            if (x[i].tokenId == v) {
                p = x[i];
                f = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    function indexOf(Position[] memory x, uint256 v) internal pure returns (bool f, uint256 i) {
        for (i; i < x.length;) {
            if (x[i].tokenId == v) {
                f = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    function indexOf(PositionOptim[] memory x, uint192 v) internal pure returns (bool f, uint256 i) {
        for (i; i < x.length;) {
            if (x[i].tokenId == v) {
                f = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    function sum(PositionOptim[] memory x) internal pure returns (uint64 s) {
        for (uint256 i; i < x.length;) {
            s += x[i].amount;
            unchecked {
                ++i;
            }
        }
    }

    function getPositions(PositionOptim[] memory x) internal pure returns (Position[] memory y) {
        y = new Position[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = Position(x[i].tokenId.expand(), x[i].amount);
            unchecked {
                ++i;
            }
        }
    }

    function getPositionOptims(Position[] memory x) internal pure returns (PositionOptim[] memory y) {
        y = new PositionOptim[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = getPositionOptim(x[i]);
            unchecked {
                ++i;
            }
        }
    }

    function pushPosition(PositionOptim[] storage x, Position memory y) internal {
        x.push(getPositionOptim(y));
    }

    function removePositionAt(PositionOptim[] storage x, uint256 y) internal {
        if (y >= x.length) return;
        x[y] = x[x.length - 1];
        x.pop();
    }

    function getPositionOptim(Position memory x) internal pure returns (PositionOptim memory) {
        return PositionOptim(x.tokenId.compress(), x.amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {SafeCast} from "openzeppelin/utils/math/SafeCast.sol";

import {IGrappa} from "../../../interfaces/IGrappa.sol";
import {IOracle} from "../../../interfaces/IOracle.sol";

// shard libraries
import {NumberUtil} from "../../../libraries/NumberUtil.sol";
import {ProductIdUtil} from "../../../libraries/ProductIdUtil.sol";
import {TokenIdUtil} from "../../../libraries/TokenIdUtil.sol";
import {BalanceUtil} from "../../../libraries/BalanceUtil.sol";
import {ArrayUtil} from "../../../libraries/ArrayUtil.sol";

// cross margin libraries
import {AccountUtil} from "./AccountUtil.sol";

// Cross margin types
import "./types.sol";

import "../../../config/constants.sol";
import "../../../config/enums.sol";
import "../../../config/errors.sol";

/**
 * @title   CrossMarginMath
 * @notice  this library is in charge of calculating the min collateral for a given cross margin account
 * @dev     deployed as a separate contract to save space
 */
library CrossMarginMath {
    using BalanceUtil for Balance[];
    using AccountUtil for CrossMarginDetail[];
    using AccountUtil for Position[];
    using AccountUtil for PositionOptim[];
    using ArrayUtil for uint256[];
    using ArrayUtil for int256[];
    using SafeCast for int256;
    using SafeCast for uint256;
    using TokenIdUtil for uint256;

    /*///////////////////////////////////////////////////////////////
                         Portfolio Margin Requirements
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice get minimum collateral for a given amount of shorts & longs
     * @dev typically used for calculating a portfolios margin requirements
     * @param grappa interface to query grappa contract
     * @param shorts is array of Position structs
     * @param longs is array of Position structs
     * @return amounts is an array of Balance struct representing full collateralization
     */
    function getMinCollateralForPositions(IGrappa grappa, Position[] calldata shorts, Position[] calldata longs)
        external
        view
        returns (Balance[] memory amounts)
    {
        // groups shorts and longs by underlying + strike + collateral + expiry
        CrossMarginDetail[] memory details = _getPositionDetails(grappa, shorts, longs);

        // portfolio has no longs or shorts
        if (details.length == ZERO) return amounts;

        bool found;
        uint256 index;

        for (uint256 i; i < details.length;) {
            CrossMarginDetail memory detail = details[i];

            // checks that the combination has positions, otherwiser skips
            if (detail.callWeights.length != ZERO || detail.putWeights.length != ZERO) {
                // gets the amount of numeraire and underlying needed
                (uint256 numeraireNeeded, uint256 underlyingNeeded) = getMinCollateral(detail);

                if (numeraireNeeded != ZERO) {
                    (found, index) = amounts.indexOf(detail.numeraireId);

                    if (found) amounts[index].amount += numeraireNeeded.toUint80();
                    else amounts = amounts.append(Balance(detail.numeraireId, numeraireNeeded.toUint80()));
                }

                if (underlyingNeeded != ZERO) {
                    (found, index) = amounts.indexOf(detail.underlyingId);

                    if (found) amounts[index].amount += underlyingNeeded.toUint80();
                    else amounts = amounts.append(Balance(detail.underlyingId, underlyingNeeded.toUint80()));
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                         Cross Margin Calculations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice get minimum collateral
     * @dev detail is composed of positions with the same underlying + strike + expiry
     * @param _detail margin details
     * @return numeraireNeeded with {numeraire asset's} decimals
     * @return underlyingNeeded with {underlying asset's} decimals
     */
    function getMinCollateral(CrossMarginDetail memory _detail)
        public
        pure
        returns (uint256 numeraireNeeded, uint256 underlyingNeeded)
    {
        _verifyInputs(_detail);

        (uint256[] memory scenarios, int256[] memory payouts) = _getScenariosAndPayouts(_detail);

        (numeraireNeeded, underlyingNeeded) = _getCollateralNeeds(_detail, scenarios, payouts);

        // if options collateralizied in underlying, forcing numeraire to be converted to underlying
        // only applied to calls since puts cannot be collateralized in underlying
        if (numeraireNeeded > ZERO && _detail.putStrikes.length == ZERO) {
            numeraireNeeded = ZERO;

            underlyingNeeded = _convertCallNumeraireToUnderlying(scenarios, payouts, underlyingNeeded);
        } else {
            numeraireNeeded = NumberUtil.convertDecimals(numeraireNeeded, UNIT_DECIMALS, _detail.numeraireDecimals);
        }

        underlyingNeeded = NumberUtil.convertDecimals(underlyingNeeded, UNIT_DECIMALS, _detail.underlyingDecimals);
    }

    /**
     * @notice checks inputs for calculating margin, reverts if bad inputs
     * @param _detail margin details
     */
    function _verifyInputs(CrossMarginDetail memory _detail) internal pure {
        if (_detail.callStrikes.length != _detail.callWeights.length) revert CMM_InvalidCallLengths();
        if (_detail.putStrikes.length != _detail.putWeights.length) revert CMM_InvalidPutLengths();

        uint256 i;
        for (i; i < _detail.putWeights.length;) {
            if (_detail.putWeights[i] == sZERO) revert CMM_InvalidPutWeight();

            unchecked {
                ++i;
            }
        }

        for (i = ZERO; i < _detail.callWeights.length;) {
            if (_detail.callWeights[i] == sZERO) revert CMM_InvalidCallWeight();

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice setting up values needed to calculate margin requirements
     * @param _detail margin details
     * @return scenarios array of all the strikes
     * @return payouts payouts for a given scenario
     */
    function _getScenariosAndPayouts(CrossMarginDetail memory _detail)
        internal
        pure
        returns (uint256[] memory scenarios, int256[] memory payouts)
    {
        bool hasPuts = _detail.putStrikes.length > ZERO;
        bool hasCalls = _detail.callStrikes.length > ZERO;

        scenarios = _detail.putStrikes.concat(_detail.callStrikes).sort();

        // payouts at each scenario (strike)
        payouts = new int256[](scenarios.length);

        uint256 lastScenario;

        for (uint256 i; i < scenarios.length;) {
            // deduping scenarios, leaving payout as zero
            if (scenarios[i] != lastScenario) {
                if (hasPuts) {
                    payouts[i] = _detail.putStrikes.subEachBy(scenarios[i]).maximum(sZERO).dot(_detail.putWeights) / sUNIT;
                }

                if (hasCalls) {
                    payouts[i] += _detail.callStrikes.subEachFrom(scenarios[i]).maximum(sZERO).dot(_detail.callWeights) / sUNIT;
                }

                lastScenario = scenarios[i];
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice get numeraire and underlying needed to fully collateralize
     * @dev calculates left side and right side of the payout profile
     * @param _detail margin details
     * @param scenarios of all the options
     * @param payouts are the payouts at a given scenario
     * @return numeraireNeeded with {numeraire asset's} decimals
     * @return underlyingNeeded with {underlying asset's} decimals
     */
    function _getCollateralNeeds(CrossMarginDetail memory _detail, uint256[] memory scenarios, int256[] memory payouts)
        internal
        pure
        returns (uint256 numeraireNeeded, uint256 underlyingNeeded)
    {
        bool hasPuts = _detail.putStrikes.length > ZERO;
        bool hasCalls = _detail.callStrikes.length > ZERO;

        (int256 minPayout, uint256 minPayoutIndex) = payouts.minWithIndex();

        // if put options exist, get amount of numeraire needed (left side of payout profile)
        if (hasPuts) numeraireNeeded = _getNumeraireNeeded(minPayout, _detail.putStrikes, _detail.putWeights);

        // if call options exist, get amount of underlying needed (right side of payout profile)
        if (hasCalls) underlyingNeeded = _getUnderlyingNeeded(_detail.callWeights);

        // crediting the numeraire if underlying has a positive payout
        numeraireNeeded =
            _getUnderlyingAdjustedNumeraireNeeded(scenarios, minPayout, minPayoutIndex, numeraireNeeded, underlyingNeeded);
    }

    /**
     * @notice calculates the amount of numeraire is needed for put options
     * @dev only called if there are put options, usually denominated in cash
     * @param minPayout minimum payout across scenarios
     * @param putStrikes put option strikes
     * @param putWeights number of put options at a coorisponding strike
     * @return numeraireNeeded amount of numeraire asset needed
     */
    function _getNumeraireNeeded(int256 minPayout, uint256[] memory putStrikes, int256[] memory putWeights)
        internal
        pure
        returns (uint256 numeraireNeeded)
    {
        int256 _numeraireNeeded = putStrikes.dot(putWeights) / sUNIT;

        if (_numeraireNeeded > minPayout) _numeraireNeeded = minPayout;

        if (_numeraireNeeded < sZERO) numeraireNeeded = uint256(-_numeraireNeeded);
    }

    /**
     * @notice calculates the amount of underlying is needed for call options
     * @dev only called if there are call options
     * @param callWeights number of call options at a coorisponding strike
     * @return underlyingNeeded amount of underlying needed
     */
    function _getUnderlyingNeeded(int256[] memory callWeights) internal pure returns (uint256 underlyingNeeded) {
        int256 totalCalls = callWeights.sum();

        if (totalCalls < sZERO) underlyingNeeded = uint256(-totalCalls);
    }

    /**
     * @notice crediting the numeraire if underlying has a positive payout
     * @dev checks if subAccount has positive underlying value, if it does then cash requirements can be lowered
     * @param scenarios of all the options
     * @param minPayout minimum payout across scenarios
     * @param minPayoutIndex minimum payout across scenarios index
     * @param numeraireNeeded current numeraire needed
     * @param underlyingNeeded underlying needed
     * @return numeraireNeeded adjusted numerarie needed
     */
    function _getUnderlyingAdjustedNumeraireNeeded(
        uint256[] memory scenarios,
        int256 minPayout,
        uint256 minPayoutIndex,
        uint256 numeraireNeeded,
        uint256 underlyingNeeded
    ) internal pure returns (uint256) {
        // negating to focus on negative payouts which require positive collateral
        minPayout = -minPayout;

        if (numeraireNeeded.toInt256() < minPayout) {
            uint256 underlyingPayoutAtMinStrike = (scenarios[minPayoutIndex] * underlyingNeeded) / UNIT;

            if (underlyingPayoutAtMinStrike.toInt256() > minPayout) {
                numeraireNeeded = ZERO;
            } else {
                // check directly above means minPayout > underlyingPayoutAtMinStrike
                numeraireNeeded = uint256(minPayout) - underlyingPayoutAtMinStrike;
            }
        }

        return numeraireNeeded;
    }

    /**
     * @notice converts numerarie needed entirely in underlying
     * @dev only used if options collateralizied in underlying
     * @param scenarios of all the options
     * @param payouts payouts at coorisponding scenarios
     * @param underlyingNeeded current underlying needed
     * @return underlyingOnlyNeeded adjusted underlying needed
     */
    function _convertCallNumeraireToUnderlying(uint256[] memory scenarios, int256[] memory payouts, uint256 underlyingNeeded)
        internal
        pure
        returns (uint256 underlyingOnlyNeeded)
    {
        int256 maxPayoutsOverScenarios;
        int256[] memory payoutsOverScenarios = new int256[](scenarios.length);

        for (uint256 i; i < scenarios.length;) {
            payoutsOverScenarios[i] = (-payouts[i] * sUNIT) / int256(scenarios[i]);

            if (payoutsOverScenarios[i] > maxPayoutsOverScenarios) maxPayoutsOverScenarios = payoutsOverScenarios[i];

            unchecked {
                ++i;
            }
        }

        underlyingOnlyNeeded = underlyingNeeded;

        if (maxPayoutsOverScenarios > sZERO) underlyingOnlyNeeded += uint256(maxPayoutsOverScenarios);
    }

    /*///////////////////////////////////////////////////////////////
                         Setup CrossMarginDetail
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  converts Position struct arrays to in-memory detail struct arrays
     */
    function _getPositionDetails(IGrappa grappa, Position[] calldata shorts, Position[] calldata longs)
        internal
        view
        returns (CrossMarginDetail[] memory details)
    {
        details = new CrossMarginDetail[](ZERO);

        // used to reference which detail struct should be updated for a given position
        bytes32[] memory usceLookUp = new bytes32[](ZERO);

        Position[] memory positions = shorts.concat(longs);
        uint256 shortLength = shorts.length;

        for (uint256 i; i < positions.length;) {
            (, uint40 productId, uint64 expiry,,) = positions[i].tokenId.parseTokenId();

            ProductDetails memory product = _getProductDetails(grappa, productId);

            bytes32 pos = keccak256(abi.encode(product.underlyingId, product.strikeId, expiry));

            (bool found, uint256 index) = ArrayUtil.indexOf(usceLookUp, pos);

            CrossMarginDetail memory detail;

            if (found) {
                detail = details[index];
            } else {
                usceLookUp = ArrayUtil.append(usceLookUp, pos);

                detail.underlyingId = product.underlyingId;
                detail.underlyingDecimals = product.underlyingDecimals;
                detail.numeraireId = product.strikeId;
                detail.numeraireDecimals = product.strikeDecimals;
                detail.expiry = expiry;

                details = details.append(detail);
            }

            int256 amount = int256(int64(positions[i].amount));

            if (i < shortLength) amount = -amount;

            _processDetailWithToken(detail, positions[i].tokenId, amount);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice merges option and amounts into the set
     * @dev if weight turns into zero, we remove it from the set
     */
    function _processDetailWithToken(CrossMarginDetail memory detail, uint256 tokenId, int256 amount) internal pure {
        (TokenType tokenType,,, uint64 strike,) = tokenId.parseTokenId();

        bool found;
        uint256 index;

        // adjust or append to callStrikes array or callWeights array.
        if (tokenType == TokenType.CALL) {
            (found, index) = detail.callStrikes.indexOf(strike);

            if (found) {
                detail.callWeights[index] += amount;

                if (detail.callWeights[index] == sZERO) {
                    detail.callWeights = detail.callWeights.remove(index);
                    detail.callStrikes = detail.callStrikes.remove(index);
                }
            } else {
                detail.callStrikes = detail.callStrikes.append(strike);
                detail.callWeights = detail.callWeights.append(amount);
            }
        } else if (tokenType == TokenType.PUT) {
            // adjust or append to putStrikes array or putWeights array.
            (found, index) = detail.putStrikes.indexOf(strike);

            if (found) {
                detail.putWeights[index] += amount;

                if (detail.putWeights[index] == sZERO) {
                    detail.putWeights = detail.putWeights.remove(index);
                    detail.putStrikes = detail.putStrikes.remove(index);
                }
            } else {
                detail.putStrikes = detail.putStrikes.append(strike);
                detail.putWeights = detail.putWeights.append(amount);
            }
        }
    }

    /**
     * @notice gets product asset specific details from grappa in one call
     */
    function _getProductDetails(IGrappa grappa, uint40 productId) internal view returns (ProductDetails memory info) {
        (,, uint8 underlyingId, uint8 strikeId,) = ProductIdUtil.parseProductId(productId);

        (,, address underlying, uint8 underlyingDecimals, address strike, uint8 strikeDecimals,,) =
            grappa.getDetailFromProductId(productId);

        info.underlying = underlying;
        info.underlyingId = underlyingId;
        info.underlyingDecimals = underlyingDecimals;
        info.strike = strike;
        info.strikeId = strikeId;
        info.strikeDecimals = strikeDecimals;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* --------------------- *
 *  Cross Margin Errors
 * --------------------- */

/// @dev cross margin doesn't support this action
error CM_UnsupportedAction();

/// @dev cannot override a non-empty subaccount id
error CM_AccountIsNotEmpty();

/// @dev unsupported token type
error CM_UnsupportedTokenType();

/// @dev can only add long tokens that are not expired
error CM_Option_Expired();

/// @dev can only add long tokens from authorized engines
error CM_Not_Authorized_Engine();

/// @dev collateral id is wrong: the id doesn't match the existing collateral
error CM_WrongCollateralId();

/// @dev invalid collateral:
error CM_CannotMintOptionWithThisCollateral();

/// @dev invalid tokenId specify to mint / burn actions
error CM_InvalidToken();

/* --------------------- *
 *  Cross Margin Math Errors
 * --------------------- */

/// @dev invalid put length given strikes
error CMM_InvalidPutLengths();

/// @dev invalid call length given strikes
error CMM_InvalidCallLengths();

/// @dev invalid put length of zero
error CMM_InvalidPutWeight();

/// @dev invalid call length of zero
error CMM_InvalidCallWeight();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../config/enums.sol";
import "../../../config/types.sol";

/**
 * @dev base unit of cross margin account. This is the data stored in the state
 *      storage packing is utilized to save gas.
 * @param shorts an array of short positions
 * @param longs an array of long positions
 * @param collaterals an array of collateral balances
 */
struct CrossMarginAccount {
    PositionOptim[] shorts;
    PositionOptim[] longs;
    Balance[] collaterals;
}

/**
 * @dev struct used in memory to represent a cross margin account's option set
 *      this is a grouping of like underlying, collateral, strike (asset), and expiry
 *      used to calculate margin requirements
 * @param putWeights            amount of put options held in account (shorts and longs)
 * @param putStrikes            strikes of put options held in account (shorts and longs)
 * @param callWeights           amount of call options held in account (shorts and longs)
 * @param callStrikes           strikes of call options held in account (shorts and longs)
 * @param underlyingId          grappa id for underlying asset
 * @param underlyingDecimals    decimal points of underlying asset
 * @param numeraireId           grappa id for numeraire (aka strike) asset
 * @param numeraireDecimals     decimal points of numeraire (aka strike) asset
 * @param spotPrice             current spot price of underlying in terms of strike asset
 * @param expiry                expiry of the option
 */
struct CrossMarginDetail {
    int256[] putWeights;
    uint256[] putStrikes;
    int256[] callWeights;
    uint256[] callStrikes;
    uint8 underlyingId;
    uint8 underlyingDecimals;
    uint8 numeraireId;
    uint8 numeraireDecimals;
    uint256 expiry;
}

/**
 * @dev a compressed Position struct, compresses tokenId to save storage space
 * @param tokenId option token
 * @param amount number option tokens
 */
struct PositionOptim {
    uint192 tokenId;
    uint64 amount;
}

/**
 * @dev an uncompressed Position struct, expanding tokenId to uint256
 * @param tokenId grappa option token id
 * @param amount number option tokens
 */
struct Position {
    uint256 tokenId;
    uint64 amount;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* ------------------------ *
 *    Full Margin Errors
 * -----------------------  */

/// @dev full margin doesn't support this action
error FM_UnsupportedAction();

/// @dev invalid collateral:
///         call can only be collateralized by underlying
///         put can only be collateralized by strike
error FM_CannotMintOptionWithThisCollateral();

/// @dev collateral id is wrong: the id doesn't match the existing collateral
error FM_WrongCollateralId();

/// @dev invalid tokenId specify to mint / burn actions
error FM_InvalidToken();

/// @dev trying to merge an long with a non-existant short position
error FM_ShortDoesnotExist();

/// @dev can only merge same amount of long and short
error FM_MergeAmountMisMatch();

/// @dev can only split same amount of existing spread into short + long
error FM_SplitAmountMisMatch();

/// @dev trying to collateralized the position with different collateral than specified in productId
error FM_CollateraliMisMatch();

/// @dev cannot override a non-empty subaccount id
error FM_AccountIsNotEmpty();

/// @dev cannot remove collateral because there are expired longs
error FM_ExpiredShortInAccount();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error OC_CannotReportForFuture();

error OC_PriceNotReported();

error OC_PriceReported();

///@dev cannot dispute the settlement price after dispute period is over
error OC_DisputePeriodOver();

///@dev cannot force-set an settlement price until grace period is passed and no one has set the price.
error OC_GracePeriodNotOver();

///@dev already disputed
error OC_PriceDisputed();

///@dev owner trying to set a dispute period that is invalid
error OC_InvalidDisputePeriod();

// Chainlink oracle

error CL_AggregatorNotSet();

error CL_StaleAnswer();

error CL_RoundIdTooSmall();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../config/types.sol";

interface IGrappa {
    function getDetailFromProductId(uint40 _productId)
        external
        view
        returns (
            address oracle,
            address engine,
            address underlying,
            uint8 underlyingDecimals,
            address strike,
            uint8 strikeDecimals,
            address collateral,
            uint8 collateralDecimals
        );

    function checkEngineAccess(uint256 _tokenId, address _engine) external view;

    function checkEngineAccessAndTokenId(uint256 _tokenId, address _engine) external view;

    function engineIds(address _engine) external view returns (uint8 id);

    function assets(uint8 _id) external view returns (address addr, uint8 decimals);

    function engines(uint8 _id) external view returns (address engine);

    function oracles(uint8 _id) external view returns (address oracle);

    function getPayout(uint256 tokenId, uint64 amount)
        external
        view
        returns (address engine, address collateral, uint256 payout);

    /**
     * @notice burn option token and get out cash value at expiry
     * @param _account who to settle for
     * @param _tokenId  tokenId of option token to burn
     * @param _amount   amount to settle
     * @return payout amount paid out
     */
    function settleOption(address _account, uint256 _tokenId, uint256 _amount) external returns (uint256 payout);

    /**
     * @notice burn array of option tokens and get out cash value at expiry
     * @param _account who to settle for
     * @param _tokenIds array of tokenIds to burn
     * @param _amounts   array of amounts to burn
     */
    function batchSettleOptions(address _account, uint256[] memory _tokenIds, uint256[] memory _amounts)
        external
        returns (Balance[] memory payouts);

    function batchGetPayouts(uint256[] memory _tokenIds, uint256[] memory _amounts) external returns (Balance[] memory payouts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /**
     * @notice  get spot price of _base, denominated in _quote.
     * @param _base base asset. for ETH/USD price, ETH is the base asset
     * @param _quote quote asset. for ETH/USD price, USD is the quote asset
     * @return price with 6 decimals
     */
    function getSpotPrice(address _base, address _quote) external view returns (uint256);

    /**
     * @dev get expiry price of underlying, denominated in strike asset.
     * @param _base base asset. for ETH/USD price, ETH is the base asset
     * @param _quote quote asset. for ETH/USD price, USD is the quote asset
     * @param _expiry expiry timestamp
     *
     * @return price with 6 decimals
     */
    function getPriceAtExpiry(address _base, address _quote, uint256 _expiry)
        external
        view
        returns (uint256 price, bool isFinalized);

    /**
     * @dev return the maximum dispute period for the oracle
     * @dev this will only be checked during oracle registration, as a soft constraint on integrating oracles.
     */
    function maxDisputePeriod() external view returns (uint256 disputePeriod);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeCast} from "openzeppelin/utils/math/SafeCast.sol";

library ArrayUtil {
    using SafeCast for uint256;
    using SafeCast for int256;

    error IndexOutOfBounds();

    /**
     * @dev Returns minimal element in array
     * @return m
     */
    function min(int256[] memory x) internal pure returns (int256 m) {
        m = x[0];
        for (uint256 i; i < x.length;) {
            if (x[i] < m) {
                m = x[i];
            }
            unchecked {
                ++i;
            }
        }
    }

    function minWithIndex(int256[] memory x) internal pure returns (int256 m, uint256 idx) {
        m = x[0];
        idx = 0;
        for (uint256 i; i < x.length;) {
            if (x[i] < m) {
                m = x[i];
                idx = i;
            }
            unchecked {
                ++i;
            }
        }
    }

    function min(uint256[] memory x) internal pure returns (uint256 m) {
        m = x[0];
        for (uint256 i; i < x.length;) {
            if (x[i] < m) {
                m = x[i];
            }
            unchecked {
                ++i;
            }
        }
    }

    function minMax(uint256[] memory x) internal pure returns (uint256 min_, uint256 max_) {
        (min_, max_) = (x[0], x[0]);
        for (uint256 i; i < x.length;) {
            if (x[i] < min_) {
                min_ = x[i];
            }
            if (x[i] > max_) {
                max_ = x[i];
            }
            unchecked {
                ++i;
            }
        }
    }

    // /**
    //  * @dev Returns minimal element's index
    //  * @return m
    //  */
    // function imin(uint256[] memory x) internal pure returns (uint256 m) {
    //     m = 0;
    //     for (uint256 i; i < x.length; i++) {
    //         if (x[i] < x[m]) {
    //             m = i;
    //         }
    //     }
    //     return m;
    // }

    /**
     * @dev Returns maximal element in array
     * @return m
     */
    function max(int256[] memory x) internal pure returns (int256 m) {
        m = x[0];
        for (uint256 i; i < x.length;) {
            if (x[i] > m) {
                m = x[i];
            }

            unchecked {
                ++i;
            }
        }
    }

    function max(uint256[] memory x) internal pure returns (uint256 m) {
        m = x[0];
        for (uint256 i; i < x.length;) {
            if (x[i] > m) {
                m = x[i];
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Returns maximal elements comparedTo value
     * @return y array
     */
    function maximum(int256[] memory x, int256 z) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i; i < x.length;) {
            if (x[i] > z) y[i] = x[i];
            else y[i] = z;

            unchecked {
                ++i;
            }
        }
    }

    // /**
    //  * @dev Returns maximal element's index
    //  * @return m maximal
    //  */
    // function imax(uint256[] memory x) internal pure returns (uint256 m) {
    //     for (uint256 i; i < x.length; i++) {
    //         if (x[i] > x[m]) {
    //             m = i;
    //         }
    //     }
    // }

    /**
     * @dev Removes element at index in a new unsigned int array, does not change x memory in place
     * @return y new array
     */
    function remove(uint256[] memory x, uint256 z) internal pure returns (uint256[] memory y) {
        if (z >= x.length) return x;
        y = new uint256[](x.length - 1);
        for (uint256 i; i < x.length;) {
            unchecked {
                if (i < z) y[i] = x[i];
                else if (i > z) y[i - 1] = x[i];
                ++i;
            }
        }
    }

    /**
     * @dev Removes element at index in a new signed int array, does not change x memory in place
     * @return y new array
     */
    function remove(int256[] memory x, uint256 z) internal pure returns (int256[] memory y) {
        if (z >= x.length) return x;
        y = new int256[](x.length - 1);
        for (uint256 i; i < x.length;) {
            unchecked {
                if (i < z) y[i] = x[i];
                else if (i > z) y[i - 1] = x[i];
                ++i;
            }
        }
    }

    /**
     * @dev Returns index of element
     * @return found
     * @return index
     */
    function indexOf(int256[] memory x, int256 v) internal pure returns (bool, uint256) {
        for (uint256 i; i < x.length;) {
            if (x[i] == v) {
                return (true, i);
            }

            unchecked {
                ++i;
            }
        }
        return (false, 0);
    }

    function indexOf(bytes32[] memory x, bytes32 v) internal pure returns (bool, uint256) {
        for (uint256 i; i < x.length;) {
            if (x[i] == v) {
                return (true, i);
            }

            unchecked {
                ++i;
            }
        }
        return (false, 0);
    }

    function indexOf(uint256[] memory x, uint256 v) internal pure returns (bool, uint256) {
        for (uint256 i; i < x.length;) {
            if (x[i] == v) {
                return (true, i);
            }

            unchecked {
                ++i;
            }
        }
        return (false, 0);
    }

    /**
     * @dev Compute sum of all elements
     * @return s sum
     */
    function sum(int256[] memory x) internal pure returns (int256 s) {
        for (uint256 i; i < x.length;) {
            s += x[i];

            unchecked {
                ++i;
            }
        }
    }

    function sum(uint256[] memory x) internal pure returns (uint256 s) {
        for (uint256 i; i < x.length;) {
            s += x[i];

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev put the min of last p elements in array at position p.
     */

    function argSort(uint256[] memory x) internal pure returns (uint256[] memory y, uint256[] memory ixArray) {
        ixArray = new uint256[](x.length);
        // fill in index array
        for (uint256 i; i < x.length;) {
            ixArray[i] = i;

            unchecked {
                ++i;
            }
        }
        // initialize copy of x
        y = new uint256[](x.length);
        populate(y, x, 0);
        // sort
        quickSort(y, int256(0), int256(y.length - 1), ixArray);
    }

    function sort(uint256[] memory x) internal pure returns (uint256[] memory y) {
        y = new uint256[](x.length);
        populate(y, x, 0);
        quickSort(y, int256(0), int256(y.length - 1));
    }

    /*
    @dev quicksort implementation, sorts arr input IN PLACE
    */
    function quickSort(uint256[] memory arr, int256 left, int256 right) internal pure {
        if (left == right) return;
        int256 i = left;
        int256 j = right;
        unchecked {
            uint256 pivot = arr[uint256(left + (right - left) / 2)];
            while (i <= j) {
                while (arr[uint256(i)] < pivot) {
                    ++i;
                }
                while (pivot < arr[uint256(j)]) {
                    --j;
                }
                if (i <= j) {
                    (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                    ++i;
                    --j;
                }
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }

    /*
    @dev quicksort implementation with indexes, sorts input arr and indexArray IN PLACE
    */
    function quickSort(uint256[] memory arr, int256 left, int256 right, uint256[] memory indexArray) internal pure {
        if (left == right) return;
        int256 i = left;
        int256 j = right;
        unchecked {
            uint256 pivot = arr[uint256(left + (right - left) / 2)];
            while (i <= j) {
                while (arr[uint256(i)] < pivot) {
                    ++i;
                }
                while (pivot < arr[uint256(j)]) {
                    --j;
                }
                if (i <= j) {
                    (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                    (indexArray[uint256(i)], indexArray[uint256(j)]) = (indexArray[uint256(j)], indexArray[uint256(i)]);
                    ++i;
                    --j;
                }
            }
            if (left < j) quickSort(arr, left, j, indexArray);
            if (i < right) quickSort(arr, i, right, indexArray);
        }
    }

    /**
     *  sort functions for int ***
     */

    function argSort(int256[] memory x) internal pure returns (int256[] memory y, uint256[] memory ixArray) {
        ixArray = new uint256[](x.length);
        // fill in index array
        for (uint256 i; i < x.length;) {
            ixArray[i] = i;

            unchecked {
                ++i;
            }
        }
        // initialize copy of x
        y = new int256[](x.length);
        populate(y, x, 0);
        // sort
        quickSort(y, int256(0), int256(y.length - 1), ixArray);
    }

    function sort(int256[] memory x) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        populate(y, x, 0);
        quickSort(y, int256(0), int256(y.length - 1));
    }

    // quicksort implementation, sorts arr in place
    function quickSort(int256[] memory arr, int256 left, int256 right) internal pure {
        if (left == right) return;
        int256 i = left;
        int256 j = right;
        unchecked {
            int256 pivot = arr[uint256(left + (right - left) / 2)];

            while (i <= j) {
                while (arr[uint256(i)] < pivot) {
                    ++i;
                }
                while (pivot < arr[uint256(j)]) {
                    --j;
                }
                if (i <= j) {
                    (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                    ++i;
                    --j;
                }
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }

    // quicksort implementation with indexes, sorts arr and indexArray in place
    function quickSort(int256[] memory arr, int256 left, int256 right, uint256[] memory indexArray) internal pure {
        if (left == right) return;
        int256 i = left;
        int256 j = right;
        unchecked {
            int256 pivot = arr[uint256(left + (right - left) / 2)];
            while (i <= j) {
                while (arr[uint256(i)] < pivot) {
                    ++i;
                }
                while (pivot < arr[uint256(j)]) {
                    --j;
                }
                if (i <= j) {
                    (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                    (indexArray[uint256(i)], indexArray[uint256(j)]) = (indexArray[uint256(j)], indexArray[uint256(i)]);
                    ++i;
                    --j;
                }
            }
        }
        if (left < j) quickSort(arr, left, j, indexArray);
        if (i < right) quickSort(arr, i, right, indexArray);
    }

    /**
     * End Sort Functions for Int ******
     */

    function sortByIndexes(int256[] memory x, uint256[] memory z) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = x[z[i]];

            unchecked {
                ++i;
            }
        }
    }

    function append(bytes32[] memory x, bytes32 e) internal pure returns (bytes32[] memory y) {
        y = new bytes32[](x.length + 1);
        uint256 i;
        for (i; i < x.length;) {
            y[i] = x[i];

            unchecked {
                ++i;
            }
        }
        y[i] = e;
    }

    function append(int256[] memory x, int256 v) internal pure returns (int256[] memory y) {
        y = new int256[](x.length + 1);
        uint256 i;
        for (i; i < x.length;) {
            y[i] = x[i];

            unchecked {
                ++i;
            }
        }
        y[i] = v;
    }

    function append(uint256[] memory x, uint256 v) internal pure returns (uint256[] memory y) {
        y = new uint256[](x.length + 1);
        uint256 i;
        for (i; i < x.length;) {
            y[i] = x[i];

            unchecked {
                ++i;
            }
        }
        y[i] = v;
    }

    function concat(int256[] memory a, int256[] memory b) internal pure returns (int256[] memory y) {
        y = new int256[](a.length + b.length);
        uint256 v;
        uint256 i;
        for (i; i < a.length;) {
            y[v] = a[i];

            unchecked {
                ++i;
                ++v;
            }
        }
        for (i = 0; i < b.length;) {
            y[v] = b[i];

            unchecked {
                ++i;
                ++v;
            }
        }
    }

    function concat(uint256[] memory a, uint256[] memory b) internal pure returns (uint256[] memory y) {
        y = new uint256[](a.length + b.length);
        uint256 v;
        uint256 i;
        for (i; i < a.length;) {
            y[v] = a[i];

            unchecked {
                ++i;
                ++v;
            }
        }
        for (i = 0; i < b.length;) {
            y[v] = b[i];

            unchecked {
                ++i;
                ++v;
            }
        }
    }

    /*
    @dev this function modifies memory x IN PLACE. Fills x with value v
    */
    function fill(int256[] memory x, int256 v) internal pure {
        for (uint256 i; i < x.length;) {
            x[i] = v;

            unchecked {
                ++i;
            }
        }
    }

    /*
    @dev modifies memory a IN PLACE. Populates a starting at index z with values from b.
    */
    function populate(uint256[] memory a, uint256[] memory b, uint256 z) internal pure {
        for (uint256 i; i < a.length;) {
            a[z + i] = b[i];

            unchecked {
                ++i;
            }
        }
    }

    /*
    @dev modifies memory a IN PLACE. Populates a starting at index z with values from b.
    */
    function populate(int256[] memory a, int256[] memory b, uint256 z) internal pure {
        for (uint256 i; i < a.length;) {
            a[z + i] = b[i];

            unchecked {
                ++i;
            }
        }
    }

    function at(int256[] memory x, int256 i) internal pure returns (int256) {
        int256 len = x.length.toInt256();
        if (i > 0) {
            if (i > len) revert IndexOutOfBounds();
            return x[uint256(i)];
        } else {
            if (i < -len) revert IndexOutOfBounds();
            return x[(len + i).toUint256()];
        }
    }

    function at(uint256[] memory x, int256 i) internal pure returns (uint256) {
        int256 len = x.length.toInt256();
        if (i > 0) {
            if (i > len) revert IndexOutOfBounds();
            return x[uint256(i)];
        } else {
            if (i < -len) revert IndexOutOfBounds();
            return x[(len + i).toUint256()];
        }
    }

    function slice(int256[] memory x, int256 _start, int256 _end) internal pure returns (int256[] memory a) {
        int256 len = x.length.toInt256();
        if (_start < 0) _start = len + _start;
        if (_end <= 0) _end = len + _end;
        if (_end < _start) return new int256[](0);

        uint256 start = _start.toUint256();
        uint256 end = _end.toUint256();

        a = new int256[](end - start);
        uint256 y = 0;
        for (uint256 i = start; i < end;) {
            a[y] = x[i];

            unchecked {
                ++i;
                ++y;
            }
        }
    }

    function subEachFrom(uint256[] memory x, uint256 z) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = z.toInt256() - x[i].toInt256();

            unchecked {
                ++i;
            }
        }
    }

    function subEachBy(uint256[] memory x, uint256 z) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = x[i].toInt256() - z.toInt256();

            unchecked {
                ++i;
            }
        }
    }

    function addEachBy(int256[] memory x, int256 z) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = x[i] + z;

            unchecked {
                ++i;
            }
        }
    }

    function add(int256[] memory a, int256[] memory b) internal pure returns (int256[] memory y) {
        y = new int256[](a.length);
        for (uint256 i; i < a.length;) {
            y[i] = a[i] + b[i];

            unchecked {
                i++;
            }
        }
    }

    function eachMulDivDown(int256[] memory x, int256 z, int256 d) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = (x[i] * z) / d;

            unchecked {
                ++i;
            }
        }
    }

    function eachMulDivUp(int256[] memory x, int256 z, int256 d) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = ((x[i] * z) / d) + 1;

            unchecked {
                ++i;
            }
        }
    }

    function eachMul(int256[] memory x, int256 z) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = x[i] * z;

            unchecked {
                ++i;
            }
        }
    }

    function eachDiv(int256[] memory x, int256 z) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = x[i] / z;

            unchecked {
                ++i;
            }
        }
    }

    function dot(int256[] memory a, int256[] memory b) internal pure returns (int256 s) {
        for (uint256 i; i < a.length;) {
            s += a[i] * b[i];

            unchecked {
                ++i;
            }
        }
    }

    function dot(uint256[] memory a, int256[] memory b) internal pure returns (int256 s) {
        for (uint256 i; i < a.length;) {
            s += int256(a[i]) * b[i];

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev converting array of variable types
     */

    function toInt256(uint256[] memory x) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = x[i].toInt256();

            unchecked {
                ++i;
            }
        }
    }

    function toUint256(int256[] memory x) internal pure returns (uint256[] memory y) {
        y = new uint256[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = x[i].toUint256();

            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../config/types.sol";

/**
 * Operations on Balance struct
 */
library BalanceUtil {
    function append(Balance[] memory x, Balance memory v) internal pure returns (Balance[] memory y) {
        y = new Balance[](x.length + 1);
        uint256 i;
        for (i; i < x.length;) {
            y[i] = x[i];
            unchecked {
                ++i;
            }
        }
        y[i] = v;
    }

    function find(Balance[] memory x, uint8 v) internal pure returns (bool f, Balance memory b, uint256 i) {
        for (i; i < x.length;) {
            if (x[i].collateralId == v) {
                b = x[i];
                f = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    function indexOf(Balance[] memory x, uint8 v) internal pure returns (bool f, uint256 i) {
        for (i; i < x.length;) {
            if (x[i].collateralId == v) {
                f = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    function remove(Balance[] storage x, uint256 y) internal {
        if (y >= x.length) return;
        x[y] = x[x.length - 1];
        x.pop();
    }

    function sum(Balance[] memory x) internal pure returns (uint80 s) {
        for (uint256 i; i < x.length;) {
            s += x[i].amount;
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library NumberUtil {
    /**
     * @dev use it in uncheck so overflow will still be checked.
     */
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(x == 0 || (x * y) / x == y)
            if iszero(or(iszero(x), eq(div(z, x), y))) { revert(0, 0) }
        }
    }

    /**
     * @notice convert decimals of an amount
     *
     * @param  amount      number to convert
     * @param fromDecimals the decimals amount has
     * @param toDecimals   the target decimals
     *
     * @return newAmount number with toDecimals decimals
     */
    function convertDecimals(uint256 amount, uint8 fromDecimals, uint8 toDecimals) internal pure returns (uint256) {
        if (fromDecimals == toDecimals) return amount;

        if (fromDecimals > toDecimals) {
            uint8 diff;
            unchecked {
                diff = fromDecimals - toDecimals;
                // div cannot underflow because diff 10**diff != 0
                return amount / (10 ** diff);
            }
        } else {
            uint8 diff;
            unchecked {
                diff = toDecimals - fromDecimals;
            }
            return amount * (10 ** diff);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable max-line-length

/**
 * @title ProductIdUtil
 * @dev used to parse and compose productId
 * Product Id =
 * * ----------------- | ----------------- | ---------------------- | ------------------ | ---------------------- *
 * | oracleId (8 bits) | engineId (8 bits) | underlying ID (8 bits) | strike ID (8 bits) | collateral ID (8 bits) |
 * * ----------------- | ----------------- | ---------------------- | ------------------ | ---------------------- *
 *
 */
library ProductIdUtil {
    /**
     * @dev parse product id into composing asset ids
     *
     * productId (40 bits) =
     *
     * @param _productId product id
     */
    function parseProductId(uint40 _productId)
        internal
        pure
        returns (uint8 oracleId, uint8 engineId, uint8 underlyingId, uint8 strikeId, uint8 collateralId)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            oracleId := shr(32, _productId)
            engineId := shr(24, _productId)
            underlyingId := shr(16, _productId)
            strikeId := shr(8, _productId)
        }
        collateralId = uint8(_productId);
    }

    /**
     * @dev parse collateral id from product Id.
     *      since collateral id is uint8 of the last 8 bits of productId, we can just cast to uint8
     */
    function getCollateralId(uint40 _productId) internal pure returns (uint8) {
        return uint8(_productId);
    }

    /**
     * @notice    get product id from underlying, strike and collateral address
     * @dev       function will still return even if some of the assets are not registered
     * @param underlyingId  underlying id
     * @param strikeId      strike id
     * @param collateralId  collateral id
     */
    function getProductId(uint8 oracleId, uint8 engineId, uint8 underlyingId, uint8 strikeId, uint8 collateralId)
        internal
        pure
        returns (uint40 id)
    {
        unchecked {
            id = (uint40(oracleId) << 32) + (uint40(engineId) << 24) + (uint40(underlyingId) << 16) + (uint40(strikeId) << 8)
                + (uint40(collateralId));
        }
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable max-line-length

pragma solidity ^0.8.0;

import "../config/enums.sol";
import "../config/errors.sol";

/**
 * Token ID =
 *
 *  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
 *  | tokenType (24 bits) | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) | shortStrike (64 bits) |
 *  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
 */

/**
 * Compressed Token ID =
 *
 *  * ------------------- | ------------------- | ---------------- | -------------------- *
 *  | tokenType (24 bits) | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) |
 *  * ------------------- | ------------------- | ---------------- | -------------------- *
 */
library TokenIdUtil {
    function getTokenId(TokenType tokenType, uint40 productId, uint256 expiry, uint256 longStrike, uint256 shortStrike)
        internal
        pure
        returns (uint256 tokenId)
    {
        tokenId = formatTokenId(tokenType, productId, uint64(expiry), uint64(longStrike), uint64(shortStrike));
    }

    /**
     * @notice calculate ERC1155 token id for given option parameters. See table above for tokenId
     * @param tokenType TokenType enum
     * @param productId if of the product
     * @param expiry timestamp of option expiry
     * @param longStrike strike price of the long option, with 6 decimals
     * @param shortStrike strike price of the short (upper bond for call and lower bond for put) if this is a spread. 6 decimals
     * @return tokenId token id
     */
    function formatTokenId(TokenType tokenType, uint40 productId, uint64 expiry, uint64 longStrike, uint64 shortStrike)
        internal
        pure
        returns (uint256 tokenId)
    {
        unchecked {
            tokenId = (uint256(tokenType) << 232) + (uint256(productId) << 192) + (uint256(expiry) << 128)
                + (uint256(longStrike) << 64) + uint256(shortStrike);
        }
    }

    /**
     * @notice calculate non-complaint ERC1155 token id for given option parameters. See table above for shorttokenId
     * @param tokenType TokenType enum
     * @param productId if of the product
     * @param expiry timestamp of option expiry
     * @param longStrike strike price of the long option, with 6 decimals
     * @return tokenId token id
     */
    function formatShortTokenId(TokenType tokenType, uint40 productId, uint64 expiry, uint64 longStrike)
        internal
        pure
        returns (uint192 tokenId)
    {
        unchecked {
            tokenId = (uint192(tokenType) << 168) + (uint192(productId) << 128) + (uint192(expiry) << 64) + uint192(longStrike);
        }
    }

    /**
     * @notice derive option, product, expiry and strike price from ERC1155 token id
     * @dev    See table above for tokenId composition
     * @param tokenId token id
     * @return tokenType TokenType enum
     * @return productId 32 bits product id
     * @return expiry timestamp of option expiry
     * @return longStrike strike price of the long option, with 6 decimals
     * @return shortStrike strike price of the short (upper bond for call and lower bond for put) if this is a spread. 6 decimals
     */
    function parseTokenId(uint256 tokenId)
        internal
        pure
        returns (TokenType tokenType, uint40 productId, uint64 expiry, uint64 longStrike, uint64 shortStrike)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tokenType := shr(232, tokenId)
            productId := shr(192, tokenId)
            expiry := shr(128, tokenId)
            longStrike := shr(64, tokenId)
            shortStrike := tokenId
        }
    }

    /**
     * @notice parse collateral id from tokenId
     * @dev more efficient than parsing tokenId and than parse productId
     * @param tokenId token id
     * @return collatearlId
     */
    function parseCollateralId(uint256 tokenId) internal pure returns (uint8 collatearlId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // collateralId is the last bits of productId
            collatearlId := shr(192, tokenId)
        }
    }

    /**
     * @notice parse engine id from tokenId
     * @dev more efficient than parsing tokenId and than parse productId
     * @param tokenId token id
     * @return engineId
     */
    function parseEngineId(uint256 tokenId) internal pure returns (uint8 engineId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // collateralId is the last bits of productId
            engineId := shr(216, tokenId) // 192 to get product id, another 24 to get engineId
        }
    }

    /**
     * @notice derive option, product, expiry and strike price from short token id (no shortStrike)
     * @dev    See table above for tokenId composition
     * @param tokenId token id
     * @return tokenType TokenType enum
     * @return productId 32 bits product id
     * @return expiry timestamp of option expiry
     * @return longStrike strike price of the long option, with 6 decimals
     */
    function parseShortTokenId(uint192 tokenId)
        internal
        pure
        returns (TokenType tokenType, uint40 productId, uint64 expiry, uint64 longStrike)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tokenType := shr(168, tokenId)
            productId := shr(128, tokenId)
            expiry := shr(64, tokenId)
            longStrike := tokenId
        }
    }

    /**
     * @notice derive option type from ERC1155 token id
     * @param tokenId token id
     * @return tokenType TokenType enum
     */
    function parseTokenType(uint256 tokenId) internal pure returns (TokenType tokenType) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tokenType := shr(232, tokenId)
        }
    }

    /**
     * @notice derive if option is expired from ERC1155 token id
     * @param tokenId token id
     * @return expired bool
     */
    function isExpired(uint256 tokenId) internal view returns (bool expired) {
        uint64 expiry;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            expiry := shr(128, tokenId)
        }

        expired = block.timestamp >= expiry;
    }

    /**
     * @notice convert an spread tokenId back to put or call.
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   oldId =   | spread type (24 b)  | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) | shortStrike (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   newId =   | call or put type    | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) | 0           (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   this function will: override tokenType, remove shortStrike.
     * @param _tokenId token id to change
     */
    function convertToVanillaId(uint256 _tokenId) internal pure returns (uint256 newId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newId := shr(64, _tokenId) // step 1: >> 64 to wipe out shortStrike
            newId := shl(64, newId) // step 2: << 64 go back

            newId := sub(newId, shl(232, 1)) // step 3: new tokenType = spread type - 1
        }
    }

    /**
     * @notice convert an spread tokenId back to put or call.
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   oldId =   | call or put type    | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) | 0           (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   newId =   | spread type         | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) | shortStrike (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     *
     * this function convert put or call type to spread type, add shortStrike.
     * @param _tokenId token id to change
     * @param _shortStrike strike to add
     */
    function convertToSpreadId(uint256 _tokenId, uint256 _shortStrike) internal pure returns (uint256 newId) {
        // solhint-disable-next-line no-inline-assembly
        unchecked {
            newId = _tokenId + _shortStrike;
            return newId + (1 << 232); // new type (spread type) = old type + 1
        }
    }

    /**
     * @notice Compresses tokenId by removing shortStrike.
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   oldId =   | call or put type    | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) | 0           (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     *                  * ------------------- | ------------------- | ---------------- | -------------------- *
     * @dev   newId =   | call or put type    | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- *
     *
     * @param _tokenId token id to change
     */
    function compress(uint256 _tokenId) internal pure returns (uint192 newId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newId := shr(64, _tokenId) // >> 64 to wipe out shortStrike
        }
    }

    /**
     * @notice convert a shortened tokenId back ERC1155 compliant.
     *                  * ------------------- | ------------------- | ---------------- | -------------------- *
     * @dev   oldId =   | call or put type    | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- *
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   newId =   | call or put type    | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) | 0           (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     *
     * @param _tokenId token id to change
     */
    function expand(uint192 _tokenId) internal pure returns (uint256 newId) {
        newId = uint256(_tokenId);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newId := shl(64, newId)
        }
    }
}