// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @notice Simple contract exposing a modifier used on setup functions
/// to prevent them from being called more than once
/// @author Solid World DAO
abstract contract PostConstruct {
    error AlreadyInitialized();

    bool private _initialized;

    modifier postConstruct() {
        if (_initialized) {
            revert AlreadyInitialized();
        }
        _initialized = true;
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6 <0.9.0;

interface IEACAggregatorProxy {
    function decimals() external view returns (uint8);

    function latestAnswer() external view returns (int);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./IRewardsDistributor.sol";
import "../../libraries/RewardsDataTypes.sol";

/// @title IRewardsController
/// @author Aave
/// @notice Defines the basic interface for a Rewards Controller.
interface IRewardsController is IRewardsDistributor {
    error UnauthorizedClaimer(address claimer, address user);
    error NotSolidStaking(address sender);
    error InvalidRewardOracle(address reward, address rewardOracle);

    /// @dev Emitted when a new address is whitelisted as claimer of rewards on behalf of a user
    /// @param user The address of the user
    /// @param claimer The address of the claimer
    event ClaimerSet(address indexed user, address indexed claimer);

    /// @dev Emitted when rewards are claimed
    /// @param user The address of the user rewards has been claimed on behalf of
    /// @param reward The address of the token reward is claimed
    /// @param to The address of the receiver of the rewards
    /// @param claimer The address of the claimer
    /// @param amount The amount of rewards claimed
    event RewardsClaimed(
        address indexed user,
        address indexed reward,
        address indexed to,
        address claimer,
        uint amount
    );

    /// @dev Emitted when the reward oracle is updated
    /// @param reward The address of the token reward
    /// @param rewardOracle The address of oracle
    event RewardOracleUpdated(address indexed reward, address indexed rewardOracle);

    /// @param rewardsVault The address of the account that secures ERC20 rewards.
    event RewardsVaultUpdated(address indexed rewardsVault);

    /// @param solidStaking Used to fetch the total amount staked and the stake of an user for a given asset
    event SolidStakingUpdated(address indexed solidStaking);

    /// @dev Whitelists an address to claim the rewards on behalf of another address
    /// @param user The address of the user
    /// @param claimer The address of the claimer
    function setClaimer(address user, address claimer) external;

    /// @dev Sets an Aave Oracle contract to enforce rewards with a source of value.
    /// @notice At the moment of reward configuration, the Incentives Controller performs
    /// a check to see if the reward asset oracle is compatible with IEACAggregator proxy.
    /// This check is enforced for integrators to be able to show incentives at
    /// the current Aave UI without the need to setup an external price registry
    /// @param reward The address of the reward to set the price aggregator
    /// @param rewardOracle The address of price aggregator that follows IEACAggregatorProxy interface
    function setRewardOracle(address reward, IEACAggregatorProxy rewardOracle) external;

    /// @param rewardsVault The address of the account that secures ERC20 rewards.
    function setRewardsVault(address rewardsVault) external;

    /// @param solidStaking Used to fetch the total amount staked and the stake of an user for a given asset
    function setSolidStaking(address solidStaking) external;

    /// @dev Get the price aggregator oracle address
    /// @param reward The address of the reward
    /// @return The price oracle of the reward
    function getRewardOracle(address reward) external view returns (address);

    /// @return Account that secures ERC20 rewards.
    function getRewardsVault() external view returns (address);

    /// @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
    /// @param user The address of the user
    /// @return The claimer address
    function getClaimer(address user) external view returns (address);

    /// @dev Configure assets to incentivize with an emission of rewards per second until the end of distribution.
    /// @param config The assets configuration input, the list of structs contains the following fields:
    ///   uint104 emissionPerSecond: The emission per second following rewards unit decimals.
    ///   uint256 totalStaked: The total amount staked of the asset
    ///   uint40 distributionEnd: The end of the distribution of the incentives for an asset
    ///   address asset: The asset address to incentivize
    ///   address reward: The reward token address
    ///   IEACAggregatorProxy rewardOracle: The Price Oracle of a reward to visualize the incentives at the UI Frontend.
    ///                                     Must follow Chainlink Aggregator IEACAggregatorProxy interface to be compatible.
    function configureAssets(RewardsDataTypes.DistributionConfig[] memory config) external;

    /// @dev Called by the corresponding asset on transfer hook in order to update the rewards distribution.
    /// @param asset The incentivized asset address
    /// @param user The address of the user whose asset balance has changed
    /// @param oldUserStake The amount of assets staked by the user, prior to stake change
    /// @param oldTotalStaked The total amount staked of the asset, prior to stake change
    function handleUserStakeChanged(
        address asset,
        address user,
        uint oldUserStake,
        uint oldTotalStaked
    ) external;

    /// @dev Claims all rewards for a user to the desired address, on all the assets of the pool, accumulating the pending rewards
    /// @param assets The list of assets to check eligible distributions before claiming rewards
    /// @param to The address that will be receiving the rewards
    /// @return rewardsList List of addresses of the reward tokens
    /// @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardList"
    function claimAllRewards(address[] calldata assets, address to)
        external
        returns (address[] memory rewardsList, uint[] memory claimedAmounts);

    /// @dev Claims all rewards for a user on behalf, on all the assets of the pool, accumulating the pending rewards. The caller must
    /// be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
    /// @param assets The list of assets to check eligible distributions before claiming rewards
    /// @param user The address to check and claim rewards
    /// @param to The address that will be receiving the rewards
    /// @return rewardsList List of addresses of the reward tokens
    /// @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardsList"
    function claimAllRewardsOnBehalf(
        address[] calldata assets,
        address user,
        address to
    ) external returns (address[] memory rewardsList, uint[] memory claimedAmounts);

    /// @dev Claims all reward for msg.sender, on all the assets of the pool, accumulating the pending rewards
    /// @param assets The list of assets to check eligible distributions before claiming rewards
    /// @return rewardsList List of addresses of the reward tokens
    /// @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardsList"
    function claimAllRewardsToSelf(address[] calldata assets)
        external
        returns (address[] memory rewardsList, uint[] memory claimedAmounts);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @title IRewardsDistributor
/// @author Aave
/// @notice Defines the basic interface for a Rewards Distributor.
interface IRewardsDistributor {
    error NotEmissionManager(address sender);
    error InvalidInput();
    error InvalidAssetDecimals(address asset);
    error IndexOverflow(uint newIndex);
    error DistributionNonExistent(address asset, address reward);

    /// @param asset The address of the incentivized asset
    /// @param reward The address of the reward token
    error UpdateDistributionNotApplicable(address asset, address reward);

    /// @dev Emitted when the configuration of the rewards of an asset is updated.
    /// @param asset The address of the incentivized asset
    /// @param reward The address of the reward token
    /// @param oldEmission The old emissions per second value of the reward distribution
    /// @param newEmission The new emissions per second value of the reward distribution
    /// @param oldDistributionEnd The old end timestamp of the reward distribution
    /// @param newDistributionEnd The new end timestamp of the reward distribution
    /// @param assetIndex The index of the asset distribution
    event AssetConfigUpdated(
        address indexed asset,
        address indexed reward,
        uint oldEmission,
        uint newEmission,
        uint oldDistributionEnd,
        uint newDistributionEnd,
        uint assetIndex
    );

    /// @dev Emitted when rewards of an asset are accrued on behalf of a user.
    /// @param asset The address of the incentivized asset
    /// @param reward The address of the reward token
    /// @param user The address of the user that rewards are accrued on behalf of
    /// @param assetIndex The index of the asset distribution
    /// @param userIndex The index of the asset distribution on behalf of the user
    /// @param rewardsAccrued The amount of rewards accrued
    event Accrued(
        address indexed asset,
        address indexed reward,
        address indexed user,
        uint assetIndex,
        uint userIndex,
        uint rewardsAccrued
    );

    /// @dev Emitted when the emission manager address is updated.
    /// @param oldEmissionManager The address of the old emission manager
    /// @param newEmissionManager The address of the new emission manager
    event EmissionManagerUpdated(
        address indexed oldEmissionManager,
        address indexed newEmissionManager
    );

    /// @dev Sets the end date for the distribution
    /// @param asset The asset to incentivize
    /// @param reward The reward token that incentives the asset
    /// @param newDistributionEnd The end date of the incentivization, in unix time format
    function setDistributionEnd(
        address asset,
        address reward,
        uint32 newDistributionEnd
    ) external;

    /// @dev Sets the emission per second of a set of reward distributions
    /// @param asset The asset is being incentivized
    /// @param rewards List of reward addresses are being distributed
    /// @param newEmissionsPerSecond List of new reward emissions per second
    function setEmissionPerSecond(
        address asset,
        address[] calldata rewards,
        uint88[] calldata newEmissionsPerSecond
    ) external;

    /// @dev Updates weekly reward distributions
    /// @param assets List of incentivized assets getting updated
    /// @param rewards List of reward tokens getting updated
    /// @param rewardAmounts List of carbon reward amounts getting distributed
    function updateCarbonRewardDistribution(
        address[] calldata assets,
        address[] calldata rewards,
        uint[] calldata rewardAmounts
    ) external;

    /// @param asset The incentivized asset
    /// @param reward The reward token of the incentivized asset
    /// @return true, if distribution can be updated for the asset - reward pair
    function canUpdateCarbonRewardDistribution(address asset, address reward)
        external
        view
        returns (bool);

    /// @dev Gets the end date for the distribution
    /// @param asset The incentivized asset
    /// @param reward The reward token of the incentivized asset
    /// @return The timestamp with the end of the distribution, in unix time format
    function getDistributionEnd(address asset, address reward) external view returns (uint);

    /// @dev Returns the index of a user on a reward distribution
    /// @param user Address of the user
    /// @param asset The incentivized asset
    /// @param reward The reward token of the incentivized asset
    /// @return The current user asset index, not including new distributions
    function getUserIndex(
        address user,
        address asset,
        address reward
    ) external view returns (uint);

    /// @dev Returns the configuration of the distribution reward for a certain asset
    /// @param asset The incentivized asset
    /// @param reward The reward token of the incentivized asset
    /// @return The index of the asset distribution
    /// @return The emission per second of the reward distribution
    /// @return The timestamp of the last update of the index
    /// @return The timestamp of the distribution end
    function getRewardDistribution(address asset, address reward)
        external
        view
        returns (
            uint,
            uint,
            uint,
            uint
        );

    /// @dev Returns the list of available reward token addresses of an incentivized asset
    /// @param asset The incentivized asset
    /// @return List of rewards addresses of the input asset
    function getRewardsByAsset(address asset) external view returns (address[] memory);

    /// @dev Returns the list of available reward addresses
    /// @return List of rewards supported in this contract
    function getAllRewards() external view returns (address[] memory);

    /// @dev Returns the accrued rewards balance of a user, not including virtually accrued rewards since last distribution.
    /// @param user The address of the user
    /// @param reward The address of the reward token
    /// @return Unclaimed rewards, not including new distributions
    function getAccruedRewardAmountForUser(address user, address reward)
        external
        view
        returns (uint);

    /// @dev Returns a single rewards balance of a user, including virtually accrued and unrealized claimable rewards.
    /// @param assets List of incentivized assets to check eligible distributions
    /// @param user The address of the user
    /// @param reward The address of the reward token
    /// @return The rewards amount
    function getUnclaimedRewardAmountForUserAndAssets(
        address[] calldata assets,
        address user,
        address reward
    ) external view returns (uint);

    /// @dev Returns a list all rewards of a user, including already accrued and unrealized claimable rewards
    /// @param assets List of incentivized assets to check eligible distributions
    /// @param user The address of the user
    /// @return The list of reward addresses
    /// @return The list of unclaimed amount of rewards
    function getAllUnclaimedRewardAmountsForUserAndAssets(address[] calldata assets, address user)
        external
        view
        returns (address[] memory, uint[] memory);

    /// @dev Returns the decimals of an asset to calculate the distribution delta
    /// @param asset The address to retrieve decimals
    /// @return The decimals of an underlying asset
    function getAssetDecimals(address asset) external view returns (uint8);

    /// @dev Returns the address of the emission manager
    /// @return The address of the EmissionManager
    function getEmissionManager() external view returns (address);

    /// @dev Updates the address of the emission manager
    /// @param emissionManager The address of the new EmissionManager
    function setEmissionManager(address emissionManager) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @title Permissionless view actions
/// @notice Contains view functions that can be called by anyone
/// @author Solid World DAO
interface ISolidStakingViewActions {
    /// @dev Computes the amount of tokens that the `account` has staked
    /// @param token the token to check
    /// @param account the account to check
    /// @return the amount of `token` tokens that the `account` has staked
    function balanceOf(address token, address account) external view returns (uint);

    /// @dev Computes the total amount of tokens that have been staked
    /// @param token the token to check
    /// @return the total amount of `token` tokens that have been staked
    function totalStaked(address token) external view returns (uint);

    /// @dev Returns the list of tokens that can be staked
    /// @return the list of tokens that can be staked
    function getTokens() external view returns (address[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Gnosis Protocol v2 Safe ERC20 Transfer Library
/// @author Gnosis Developers
/// @dev Gas-efficient version of Openzeppelin's SafeERC20 contract.
library GPv2SafeERC20 {
    /// @dev Wrapper around a call to the ERC20 function `transfer` that reverts
    /// also when the token returns `false`.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        bytes4 selector_ = token.transfer.selector;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freeMemoryPointer, 36), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        require(getLastTransferResult(token), "GPv2: failed transfer");
    }

    /// @dev Wrapper around a call to the ERC20 function `transferFrom` that
    /// reverts also when the token returns `false`.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        bytes4 selector_ = token.transferFrom.selector;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freeMemoryPointer, 68), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        require(getLastTransferResult(token), "GPv2: failed transferFrom");
    }

    /// @dev Verifies that the last return was a successful `transfer*` call.
    /// This is done by checking that the return data is either empty, or
    /// is a valid ABI encoded boolean.
    function getLastTransferResult(IERC20 token) private view returns (bool success) {
        // NOTE: Inspecting previous return data requires assembly. Note that
        // we write the return data to memory 0 in the case where the return
        // data size is 32, this is OK since the first 64 bytes of memory are
        // reserved by Solidy as a scratch space that can be used within
        // assembly blocks.
        // <https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html>
        // solhint-disable-next-line no-inline-assembly
        assembly {
            /// @dev Revert with an ABI encoded Solidity error with a message
            /// that fits into 32-bytes.
            ///
            /// An ABI encoded Solidity error has the following memory layout:
            ///
            /// ------------+----------------------------------
            ///  byte range | value
            /// ------------+----------------------------------
            ///  0x00..0x04 |        selector("Error(string)")
            ///  0x04..0x24 |      string offset (always 0x20)
            ///  0x24..0x44 |                    string length
            ///  0x44..0x64 | string value, padded to 32-bytes
            function revertWithMessage(length, message) {
                mstore(0x00, "\x08\xc3\x79\xa0")
                mstore(0x04, 0x20)
                mstore(0x24, length)
                mstore(0x44, message)
                revert(0x00, 0x64)
            }

            switch returndatasize()
            // Non-standard ERC20 transfer without return.
            case 0 {
                // NOTE: When the return data size is 0, verify that there
                // is code at the address. This is done in order to maintain
                // compatibility with Solidity calling conventions.
                // <https://docs.soliditylang.org/en/v0.7.6/control-structures.html#external-function-calls>
                if iszero(extcodesize(token)) {
                    revertWithMessage(20, "GPv2: not a contract")
                }

                success := 1
            }
            // Standard ERC20 transfer returning boolean success value.
            case 32 {
                returndatacopy(0, 0, returndatasize())

                // NOTE: For ABI encoding v1, any non-zero value is accepted
                // as `true` for a boolean. In order to stay compatible with
                // OpenZeppelin's `SafeERC20` library which is known to work
                // with the existing ERC20 implementation we care about,
                // make sure we return success for any non-zero return value
                // from the `transfer*` call.
                success := iszero(iszero(mload(0)))
            }
            default {
                revertWithMessage(31, "GPv2: malformed transfer result")
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "../interfaces/rewards/IEACAggregatorProxy.sol";

library RewardsDataTypes {
    struct DistributionConfig {
        uint88 emissionPerSecond;
        uint totalStaked;
        uint32 distributionEnd;
        address asset;
        address reward;
        IEACAggregatorProxy rewardOracle;
    }

    struct AssetStakedAmounts {
        address asset;
        uint userStake;
        uint totalStaked;
    }

    struct AssetData {
        mapping(address => RewardDistribution) rewardDistribution;
        mapping(uint128 => address) availableRewards;
        uint128 availableRewardsCount;
        uint8 decimals;
    }

    struct RewardDistribution {
        uint104 index;
        uint88 emissionPerSecond;
        uint32 lastUpdateTimestamp;
        uint32 distributionEnd;
        mapping(address => UserReward) userReward;
    }

    struct UserReward {
        uint104 index;
        uint128 accrued;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./RewardsDistributor.sol";
import "../interfaces/rewards/IRewardsController.sol";
import "../PostConstruct.sol";
import "../libraries/GPv2SafeERC20.sol";

contract RewardsController is IRewardsController, RewardsDistributor, PostConstruct {
    /// @dev user => claimer
    mapping(address => address) internal _authorizedClaimers;

    /// @dev reward => rewardOracle
    mapping(address => IEACAggregatorProxy) internal _rewardOracle;

    /// @dev Account that secures ERC20 rewards.
    /// @dev It must approve `RewardsController` to spend the rewards it holds.
    address internal REWARDS_VAULT;

    modifier onlyAuthorizedClaimers(address claimer, address user) {
        if (_authorizedClaimers[user] != claimer && address(solidStakingViewActions) != claimer) {
            revert UnauthorizedClaimer(claimer, user);
        }
        _;
    }

    function setup(
        ISolidStakingViewActions _solidStakingViewActions,
        address rewardsVault,
        address emissionManager
    ) external postConstruct {
        solidStakingViewActions = _solidStakingViewActions;
        REWARDS_VAULT = rewardsVault;
        _setEmissionManager(emissionManager);
    }

    /// @inheritdoc IRewardsController
    function getRewardsVault() external view override returns (address) {
        return REWARDS_VAULT;
    }

    /// @inheritdoc IRewardsController
    function getClaimer(address user) external view override returns (address) {
        return _authorizedClaimers[user];
    }

    /// @inheritdoc IRewardsController
    function getRewardOracle(address reward) external view override returns (address) {
        return address(_rewardOracle[reward]);
    }

    /// @inheritdoc IRewardsController
    function configureAssets(RewardsDataTypes.DistributionConfig[] memory config)
        external
        override
        onlyEmissionManager
    {
        for (uint i; i < config.length; i++) {
            config[i].totalStaked = solidStakingViewActions.totalStaked(config[i].asset);
            _setRewardOracle(config[i].reward, config[i].rewardOracle);
        }
        _configureAssets(config);
    }

    /// @inheritdoc IRewardsController
    function setRewardOracle(address reward, IEACAggregatorProxy rewardOracle)
        external
        onlyEmissionManager
    {
        _setRewardOracle(reward, rewardOracle);
    }

    /// @inheritdoc IRewardsController
    function setClaimer(address user, address caller) external override onlyEmissionManager {
        _authorizedClaimers[user] = caller;
        emit ClaimerSet(user, caller);
    }

    /// @inheritdoc IRewardsController
    function setRewardsVault(address rewardsVault) external override onlyEmissionManager {
        REWARDS_VAULT = rewardsVault;
        emit RewardsVaultUpdated(rewardsVault);
    }

    function setSolidStaking(address solidStaking) external override onlyEmissionManager {
        solidStakingViewActions = ISolidStakingViewActions(solidStaking);
        emit SolidStakingUpdated(solidStaking);
    }

    /// @inheritdoc IRewardsController
    function handleUserStakeChanged(
        address asset,
        address user,
        uint oldUserStake,
        uint oldTotalStaked
    ) external override {
        if (msg.sender != address(solidStakingViewActions)) {
            revert NotSolidStaking(msg.sender);
        }

        _updateAllRewardDistributionsAndUserRewardsForAsset(
            asset,
            user,
            oldUserStake,
            oldTotalStaked
        );
    }

    /// @inheritdoc IRewardsController
    function claimAllRewards(address[] calldata assets, address to)
        external
        override
        returns (address[] memory rewardsList, uint[] memory claimedAmounts)
    {
        if (to == address(0)) {
            revert InvalidInput();
        }

        return _claimAllRewards(assets, msg.sender, msg.sender, to);
    }

    /// @inheritdoc IRewardsController
    function claimAllRewardsOnBehalf(
        address[] calldata assets,
        address user,
        address to
    )
        external
        override
        onlyAuthorizedClaimers(msg.sender, user)
        returns (address[] memory rewardsList, uint[] memory claimedAmounts)
    {
        if (to == address(0) || user == address(0)) {
            revert InvalidInput();
        }

        return _claimAllRewards(assets, msg.sender, user, to);
    }

    /// @inheritdoc IRewardsController
    function claimAllRewardsToSelf(address[] calldata assets)
        external
        override
        returns (address[] memory rewardsList, uint[] memory claimedAmounts)
    {
        return _claimAllRewards(assets, msg.sender, msg.sender, msg.sender);
    }

    /// @inheritdoc RewardsDistributor
    function _getAssetStakedAmounts(address[] calldata assets, address user)
        internal
        view
        override
        returns (RewardsDataTypes.AssetStakedAmounts[] memory assetStakedAmounts)
    {
        assetStakedAmounts = new RewardsDataTypes.AssetStakedAmounts[](assets.length);
        for (uint i; i < assets.length; i++) {
            assetStakedAmounts[i].asset = assets[i];
            assetStakedAmounts[i].userStake = solidStakingViewActions.balanceOf(assets[i], user);
            assetStakedAmounts[i].totalStaked = solidStakingViewActions.totalStaked(assets[i]);
        }
        return assetStakedAmounts;
    }

    /// @dev Claims all accrued rewards for a user on behalf, for the specified asset, accumulating the pending rewards.
    /// @param assets List of assets to check eligible distributions before claiming rewards
    /// @param claimer Address of the claimer on behalf of user
    /// @param user Address to check and claim rewards
    /// @param to Address that will be receiving the rewards
    /// @return
    ///   rewardsList List of reward addresses
    ///   claimedAmount List of claimed amounts, follows "rewardsList" items order
    function _claimAllRewards(
        address[] calldata assets,
        address claimer,
        address user,
        address to
    ) internal returns (address[] memory rewardsList, uint[] memory claimedAmounts) {
        uint rewardsListLength = _rewardsList.length;
        rewardsList = new address[](rewardsListLength);
        claimedAmounts = new uint[](rewardsListLength);

        _updateAllRewardDistributionsAndUserRewardsForAssets(
            user,
            _getAssetStakedAmounts(assets, user)
        );

        for (uint i; i < assets.length; i++) {
            address asset = assets[i];
            for (uint j; j < rewardsListLength; j++) {
                if (rewardsList[j] == address(0)) {
                    rewardsList[j] = _rewardsList[j];
                }
                uint rewardAmount = _assetData[asset]
                    .rewardDistribution[rewardsList[j]]
                    .userReward[user]
                    .accrued;
                if (rewardAmount != 0) {
                    claimedAmounts[j] += rewardAmount;
                    _assetData[asset]
                        .rewardDistribution[rewardsList[j]]
                        .userReward[user]
                        .accrued = 0;
                }
            }
        }
        for (uint i; i < rewardsListLength; i++) {
            _transferRewards(to, rewardsList[i], claimedAmounts[i]);
            emit RewardsClaimed(user, rewardsList[i], to, claimer, claimedAmounts[i]);
        }
        return (rewardsList, claimedAmounts);
    }

    /// @dev Function to transfer rewards to the desired account
    /// @param to Account address to send the rewards
    /// @param reward Address of the reward token
    /// @param amount Amount of rewards to transfer
    function _transferRewards(
        address to,
        address reward,
        uint amount
    ) internal {
        GPv2SafeERC20.safeTransferFrom(IERC20(reward), REWARDS_VAULT, to, amount);
    }

    /// @dev Update the Price Oracle of a reward token. The Price Oracle must follow Chainlink IEACAggregatorProxy interface.
    /// @notice The Price Oracle of a reward is used for displaying correct data about the incentives at the UI frontend.
    /// @param reward The address of the reward token
    /// @param rewardOracle The address of the price oracle
    function _setRewardOracle(address reward, IEACAggregatorProxy rewardOracle) internal {
        if (rewardOracle.latestAnswer() <= 0) {
            revert InvalidRewardOracle(reward, address(rewardOracle));
        }

        _rewardOracle[reward] = rewardOracle;
        emit RewardOracleUpdated(reward, address(rewardOracle));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/rewards/IRewardsDistributor.sol";
import "../libraries/RewardsDataTypes.sol";
import "../interfaces/staking/ISolidStakingViewActions.sol";

abstract contract RewardsDistributor is IRewardsDistributor {
    using SafeCast for uint;

    // asset => AssetData
    mapping(address => RewardsDataTypes.AssetData) internal _assetData;
    // reward => enabled
    mapping(address => bool) internal _isRewardEnabled;

    address[] internal _rewardsList;
    address[] internal _assetsList;
    address internal _emissionManager;

    /// @dev Used to fetch the total amount staked and the stake of an user for a given asset
    ISolidStakingViewActions public solidStakingViewActions;

    modifier onlyEmissionManager() {
        if (msg.sender != _emissionManager) {
            revert NotEmissionManager(msg.sender);
        }
        _;
    }

    modifier distributionExists(address asset, address reward) {
        RewardsDataTypes.RewardDistribution storage rewardDistribution = _assetData[asset]
            .rewardDistribution[reward];
        uint decimals = _assetData[asset].decimals;
        if (decimals == 0 || rewardDistribution.lastUpdateTimestamp == 0) {
            revert DistributionNonExistent(asset, reward);
        }
        _;
    }

    /// @inheritdoc IRewardsDistributor
    function getRewardDistribution(address asset, address reward)
        public
        view
        override
        returns (
            uint,
            uint,
            uint,
            uint
        )
    {
        return (
            _assetData[asset].rewardDistribution[reward].index,
            _assetData[asset].rewardDistribution[reward].emissionPerSecond,
            _assetData[asset].rewardDistribution[reward].lastUpdateTimestamp,
            _assetData[asset].rewardDistribution[reward].distributionEnd
        );
    }

    /// @inheritdoc IRewardsDistributor
    function getDistributionEnd(address asset, address reward)
        external
        view
        override
        returns (uint)
    {
        return _assetData[asset].rewardDistribution[reward].distributionEnd;
    }

    /// @inheritdoc IRewardsDistributor
    function getRewardsByAsset(address asset) external view override returns (address[] memory) {
        uint128 rewardsCount = _assetData[asset].availableRewardsCount;
        address[] memory rewards = new address[](rewardsCount);

        for (uint128 i; i < rewardsCount; i++) {
            rewards[i] = _assetData[asset].availableRewards[i];
        }
        return rewards;
    }

    /// @inheritdoc IRewardsDistributor
    function getAllRewards() external view override returns (address[] memory) {
        return _rewardsList;
    }

    /// @inheritdoc IRewardsDistributor
    function getUserIndex(
        address user,
        address asset,
        address reward
    ) public view override returns (uint) {
        return _assetData[asset].rewardDistribution[reward].userReward[user].index;
    }

    /// @inheritdoc IRewardsDistributor
    function getAccruedRewardAmountForUser(address user, address reward)
        external
        view
        override
        returns (uint)
    {
        uint totalAccrued;
        for (uint i; i < _assetsList.length; i++) {
            totalAccrued += _assetData[_assetsList[i]]
                .rewardDistribution[reward]
                .userReward[user]
                .accrued;
        }

        return totalAccrued;
    }

    /// @inheritdoc IRewardsDistributor
    function getUnclaimedRewardAmountForUserAndAssets(
        address[] calldata assets,
        address user,
        address reward
    ) external view override returns (uint unclaimedAmount) {
        RewardsDataTypes.AssetStakedAmounts[] memory assetStakedAmounts = _getAssetStakedAmounts(
            assets,
            user
        );

        for (uint i; i < assetStakedAmounts.length; i++) {
            if (assetStakedAmounts[i].userStake == 0) {
                unclaimedAmount += _assetData[assetStakedAmounts[i].asset]
                    .rewardDistribution[reward]
                    .userReward[user]
                    .accrued;
            } else {
                unclaimedAmount +=
                    _computePendingRewardAmountForUser(user, reward, assetStakedAmounts[i]) +
                    _assetData[assetStakedAmounts[i].asset]
                        .rewardDistribution[reward]
                        .userReward[user]
                        .accrued;
            }
        }

        return unclaimedAmount;
    }

    /// @inheritdoc IRewardsDistributor
    function getAllUnclaimedRewardAmountsForUserAndAssets(address[] calldata assets, address user)
        external
        view
        override
        returns (address[] memory rewardsList, uint[] memory unclaimedAmounts)
    {
        RewardsDataTypes.AssetStakedAmounts[] memory assetStakedAmounts = _getAssetStakedAmounts(
            assets,
            user
        );
        rewardsList = new address[](_rewardsList.length);
        unclaimedAmounts = new uint[](rewardsList.length);

        for (uint i; i < assetStakedAmounts.length; i++) {
            for (uint r; r < rewardsList.length; r++) {
                rewardsList[r] = _rewardsList[r];
                unclaimedAmounts[r] += _assetData[assetStakedAmounts[i].asset]
                    .rewardDistribution[rewardsList[r]]
                    .userReward[user]
                    .accrued;

                if (assetStakedAmounts[i].userStake == 0) {
                    continue;
                }
                unclaimedAmounts[r] += _computePendingRewardAmountForUser(
                    user,
                    rewardsList[r],
                    assetStakedAmounts[i]
                );
            }
        }
        return (rewardsList, unclaimedAmounts);
    }

    /// @inheritdoc IRewardsDistributor
    function setDistributionEnd(
        address asset,
        address reward,
        uint32 newDistributionEnd
    ) external override onlyEmissionManager distributionExists(asset, reward) {
        uint oldDistributionEnd = _setDistributionEnd(asset, reward, newDistributionEnd);
        uint index = _assetData[asset].rewardDistribution[reward].index;

        emit AssetConfigUpdated(
            asset,
            reward,
            _assetData[asset].rewardDistribution[reward].emissionPerSecond,
            _assetData[asset].rewardDistribution[reward].emissionPerSecond,
            oldDistributionEnd,
            newDistributionEnd,
            index
        );
    }

    /// @inheritdoc IRewardsDistributor
    function setEmissionPerSecond(
        address asset,
        address[] calldata rewards,
        uint88[] calldata newEmissionsPerSecond
    ) external override onlyEmissionManager {
        if (rewards.length != newEmissionsPerSecond.length) {
            revert InvalidInput();
        }

        for (uint i; i < rewards.length; i++) {
            (
                uint oldEmissionPerSecond,
                uint newIndex,
                uint distributionEnd
            ) = _setEmissionPerSecond(asset, rewards[i], newEmissionsPerSecond[i]);

            emit AssetConfigUpdated(
                asset,
                rewards[i],
                oldEmissionPerSecond,
                newEmissionsPerSecond[i],
                distributionEnd,
                distributionEnd,
                newIndex
            );
        }
    }

    /// @inheritdoc IRewardsDistributor
    function updateCarbonRewardDistribution(
        address[] calldata assets,
        address[] calldata rewards,
        uint[] calldata rewardAmounts
    ) external override onlyEmissionManager {
        if (assets.length != rewards.length || rewards.length != rewardAmounts.length) {
            revert InvalidInput();
        }

        for (uint i; i < assets.length; i++) {
            if (!_canUpdateCarbonRewardDistribution(assets[i], rewards[i])) {
                revert UpdateDistributionNotApplicable(assets[i], rewards[i]);
            }

            uint32 newDistributionEnd = _computeNewCarbonRewardDistributionEnd(
                assets[i],
                rewards[i]
            );
            uint88 newEmissionsPerSecond = uint88(
                rewardAmounts[i] / (newDistributionEnd - block.timestamp)
            );

            (uint oldEmissionPerSecond, uint newIndex, ) = _setEmissionPerSecond(
                assets[i],
                rewards[i],
                newEmissionsPerSecond
            );
            uint oldDistributionEnd = _setDistributionEnd(
                assets[i],
                rewards[i],
                newDistributionEnd
            );
            emit AssetConfigUpdated(
                assets[i],
                rewards[i],
                oldEmissionPerSecond,
                newEmissionsPerSecond,
                oldDistributionEnd,
                newDistributionEnd,
                newIndex
            );
        }
    }

    /// @inheritdoc IRewardsDistributor
    function getAssetDecimals(address asset) external view returns (uint8) {
        return _assetData[asset].decimals;
    }

    /// @inheritdoc IRewardsDistributor
    function getEmissionManager() external view returns (address) {
        return _emissionManager;
    }

    /// @inheritdoc IRewardsDistributor
    function setEmissionManager(address emissionManager) external onlyEmissionManager {
        _setEmissionManager(emissionManager);
    }

    /// @inheritdoc IRewardsDistributor
    function canUpdateCarbonRewardDistribution(address asset, address reward)
        external
        view
        distributionExists(asset, reward)
        returns (bool)
    {
        return _canUpdateCarbonRewardDistribution(asset, reward);
    }

    function _canUpdateCarbonRewardDistribution(address asset, address reward)
        internal
        view
        returns (bool)
    {
        uint32 currentDistributionEnd = _assetData[asset]
            .rewardDistribution[reward]
            .distributionEnd;
        uint32 nextDistributionEnd = _computeNewCarbonRewardDistributionEnd(asset, reward);

        bool isInitializedDistribution = currentDistributionEnd != 0;
        bool isBetweenDistributions = block.timestamp >= currentDistributionEnd &&
            block.timestamp < nextDistributionEnd;

        return isInitializedDistribution && isBetweenDistributions;
    }

    function _computeNewCarbonRewardDistributionEnd(address asset, address reward)
        internal
        view
        returns (uint32 newDistributionEnd)
    {
        uint32 currentDistributionEnd = _assetData[asset]
            .rewardDistribution[reward]
            .distributionEnd;

        newDistributionEnd = currentDistributionEnd + 1 weeks;
    }

    /// @dev Configure the _assetData for a specific emission
    /// @param distributionConfig The array of each asset configuration
    function _configureAssets(RewardsDataTypes.DistributionConfig[] memory distributionConfig)
        internal
    {
        for (uint i; i < distributionConfig.length; i++) {
            uint8 decimals = IERC20Metadata(distributionConfig[i].asset).decimals();

            if (decimals == 0) {
                revert InvalidAssetDecimals(distributionConfig[i].asset);
            }

            if (_assetData[distributionConfig[i].asset].decimals == 0) {
                _assetsList.push(distributionConfig[i].asset);
            }

            _assetData[distributionConfig[i].asset].decimals = decimals;

            RewardsDataTypes.RewardDistribution storage rewardDistribution = _assetData[
                distributionConfig[i].asset
            ].rewardDistribution[distributionConfig[i].reward];

            if (rewardDistribution.lastUpdateTimestamp == 0) {
                uint128 rewardCount = _assetData[distributionConfig[i].asset].availableRewardsCount;
                _assetData[distributionConfig[i].asset].availableRewards[
                    rewardCount
                ] = distributionConfig[i].reward;
                _assetData[distributionConfig[i].asset].availableRewardsCount++;
            }

            if (_isRewardEnabled[distributionConfig[i].reward] == false) {
                _isRewardEnabled[distributionConfig[i].reward] = true;
                _rewardsList.push(distributionConfig[i].reward);
            }

            (uint newAssetIndex, ) = _updateRewardDistribution(
                rewardDistribution,
                distributionConfig[i].totalStaked,
                10**decimals
            );

            uint88 oldEmissionsPerSecond = rewardDistribution.emissionPerSecond;
            uint32 oldDistributionEnd = rewardDistribution.distributionEnd;
            rewardDistribution.emissionPerSecond = distributionConfig[i].emissionPerSecond;
            rewardDistribution.distributionEnd = distributionConfig[i].distributionEnd;

            emit AssetConfigUpdated(
                distributionConfig[i].asset,
                distributionConfig[i].reward,
                oldEmissionsPerSecond,
                distributionConfig[i].emissionPerSecond,
                oldDistributionEnd,
                distributionConfig[i].distributionEnd,
                newAssetIndex
            );
        }
    }

    /// @dev Updates rewards distribution and user rewards for all rewards configured for the specified assets
    /// @param user The address of the user
    /// @param assetStakedAmounts List of structs with the user stake and total staked of a set of assets
    function _updateAllRewardDistributionsAndUserRewardsForAssets(
        address user,
        RewardsDataTypes.AssetStakedAmounts[] memory assetStakedAmounts
    ) internal {
        for (uint i; i < assetStakedAmounts.length; i++) {
            _updateAllRewardDistributionsAndUserRewardsForAsset(
                assetStakedAmounts[i].asset,
                user,
                assetStakedAmounts[i].userStake,
                assetStakedAmounts[i].totalStaked
            );
        }
    }

    /// @dev Updates rewards distribution and user rewards for all rewards configured for the specified asset
    /// @dev When call origin is (un)staking, `userStake` and `totalStaked` are prior to the (un)stake action
    /// @dev When call origin is rewards claiming, `userStake` and `totalStaked` are current values
    /// @param asset The address of the incentivized asset
    /// @param user The user address
    /// @param userStake The amount of assets staked by the user
    /// @param totalStaked The total amount staked of the asset
    function _updateAllRewardDistributionsAndUserRewardsForAsset(
        address asset,
        address user,
        uint userStake,
        uint totalStaked
    ) internal {
        uint assetUnit;
        uint numAvailableRewards = _assetData[asset].availableRewardsCount;
        unchecked {
            assetUnit = 10**_assetData[asset].decimals;
        }

        if (numAvailableRewards == 0) {
            return;
        }
        unchecked {
            for (uint128 r; r < numAvailableRewards; r++) {
                address reward = _assetData[asset].availableRewards[r];
                RewardsDataTypes.RewardDistribution storage rewardDistribution = _assetData[asset]
                    .rewardDistribution[reward];

                (uint newAssetIndex, bool rewardDistributionUpdated) = _updateRewardDistribution(
                    rewardDistribution,
                    totalStaked,
                    assetUnit
                );

                (uint rewardsAccrued, bool userRewardUpdated) = _updateUserReward(
                    rewardDistribution,
                    user,
                    userStake,
                    newAssetIndex,
                    assetUnit
                );

                if (rewardDistributionUpdated || userRewardUpdated) {
                    emit Accrued(asset, reward, user, newAssetIndex, newAssetIndex, rewardsAccrued);
                }
            }
        }
    }

    /// @dev Updates the state of the distribution for the specified reward
    /// @param rewardDistribution Storage pointer to the distribution reward config
    /// @param totalStaked The total amount staked of the asset
    /// @param assetUnit One unit of asset (10**decimals)
    /// @return The new distribution index
    /// @return True if the index was updated, false otherwise
    function _updateRewardDistribution(
        RewardsDataTypes.RewardDistribution storage rewardDistribution,
        uint totalStaked,
        uint assetUnit
    ) internal returns (uint, bool) {
        (uint oldIndex, uint newIndex) = _computeNewAssetIndex(
            rewardDistribution,
            totalStaked,
            assetUnit
        );
        bool indexUpdated;
        if (newIndex != oldIndex) {
            if (newIndex > type(uint104).max) {
                revert IndexOverflow(newIndex);
            }

            indexUpdated = true;

            rewardDistribution.index = uint104(newIndex);
            rewardDistribution.lastUpdateTimestamp = block.timestamp.toUint32();
        } else {
            rewardDistribution.lastUpdateTimestamp = block.timestamp.toUint32();
        }

        return (newIndex, indexUpdated);
    }

    /// @dev Updates the state of the distribution for the specific user
    /// @param rewardDistribution Storage pointer to the distribution reward config
    /// @param user The address of the user
    /// @param userStake The amount of assets staked by the user
    /// @param newAssetIndex The new index of the asset distribution
    /// @param assetUnit One unit of asset (10**decimals)
    /// @return The rewards accrued since the last update
    function _updateUserReward(
        RewardsDataTypes.RewardDistribution storage rewardDistribution,
        address user,
        uint userStake,
        uint newAssetIndex,
        uint assetUnit
    ) internal returns (uint, bool) {
        uint userIndex = rewardDistribution.userReward[user].index;
        uint rewardsAccrued;
        bool dataUpdated;
        if ((dataUpdated = userIndex != newAssetIndex)) {
            if (newAssetIndex > type(uint104).max) {
                revert IndexOverflow(newAssetIndex);
            }

            rewardDistribution.userReward[user].index = uint104(newAssetIndex);
            if (userStake != 0) {
                rewardsAccrued = _computeAccruedRewardAmount(
                    userStake,
                    newAssetIndex,
                    userIndex,
                    assetUnit
                );

                rewardDistribution.userReward[user].accrued += rewardsAccrued.toUint128();
            }
        }
        return (rewardsAccrued, dataUpdated);
    }

    /// @dev Calculates the pending (not yet accrued) reward amount since the last user action
    /// @param user The address of the user
    /// @param reward The address of the reward token
    /// @param assetStakedAmounts struct with the user stake and total staked of the incentivized asset
    /// @return The pending rewards for the user since the last user action
    function _computePendingRewardAmountForUser(
        address user,
        address reward,
        RewardsDataTypes.AssetStakedAmounts memory assetStakedAmounts
    ) internal view returns (uint) {
        RewardsDataTypes.RewardDistribution storage rewardDistribution = _assetData[
            assetStakedAmounts.asset
        ].rewardDistribution[reward];
        uint assetUnit = 10**_assetData[assetStakedAmounts.asset].decimals;
        (, uint nextIndex) = _computeNewAssetIndex(
            rewardDistribution,
            assetStakedAmounts.totalStaked,
            assetUnit
        );

        return
            _computeAccruedRewardAmount(
                assetStakedAmounts.userStake,
                nextIndex,
                rewardDistribution.userReward[user].index,
                assetUnit
            );
    }

    /// @dev Internal function for the calculation of user's rewards on a distribution
    /// @param userStake The amount of assets staked by the user on a distribution
    /// @param assetIndex Current index of the asset reward distribution
    /// @param userIndex Index stored for the user, representing his staking moment
    /// @param assetUnit One unit of asset (10**decimals)
    /// @return accruedRewardAmount The accrued reward amount
    function _computeAccruedRewardAmount(
        uint userStake,
        uint assetIndex,
        uint userIndex,
        uint assetUnit
    ) internal pure returns (uint accruedRewardAmount) {
        accruedRewardAmount = userStake * (assetIndex - userIndex);

        assembly {
            accruedRewardAmount := div(accruedRewardAmount, assetUnit)
        }
    }

    /// @dev Calculates the next value of an specific distribution index, with validations
    /// @param totalStaked The total amount staked of the asset
    /// @param assetUnit One unit of asset (10**decimals)
    /// @return The new index.
    function _computeNewAssetIndex(
        RewardsDataTypes.RewardDistribution storage rewardDistribution,
        uint totalStaked,
        uint assetUnit
    ) internal view returns (uint, uint) {
        uint oldIndex = rewardDistribution.index;
        uint distributionEnd = rewardDistribution.distributionEnd;
        uint emissionPerSecond = rewardDistribution.emissionPerSecond;
        uint lastUpdateTimestamp = rewardDistribution.lastUpdateTimestamp;

        if (
            emissionPerSecond == 0 ||
            totalStaked == 0 ||
            lastUpdateTimestamp == block.timestamp ||
            lastUpdateTimestamp >= distributionEnd
        ) {
            return (oldIndex, oldIndex);
        }

        uint currentTimestamp = block.timestamp > distributionEnd
            ? distributionEnd
            : block.timestamp;
        uint timeDelta = currentTimestamp - lastUpdateTimestamp;
        uint firstTerm = emissionPerSecond * timeDelta * assetUnit;
        assembly {
            firstTerm := div(firstTerm, totalStaked)
        }
        return (oldIndex, (firstTerm + oldIndex));
    }

    /// @dev Get user stake and total staked of all the assets specified by the assets parameter
    /// @param assets List of assets to retrieve user stake and total staked
    /// @param user Address of the user
    /// @return assetStakedAmounts contains a list of structs with user stake and total staked of the given assets
    function _getAssetStakedAmounts(address[] calldata assets, address user)
        internal
        view
        virtual
        returns (RewardsDataTypes.AssetStakedAmounts[] memory assetStakedAmounts);

    /// @dev Updates the address of the emission manager
    /// @param emissionManager The address of the new EmissionManager
    function _setEmissionManager(address emissionManager) internal {
        address previousEmissionManager = _emissionManager;
        _emissionManager = emissionManager;
        emit EmissionManagerUpdated(previousEmissionManager, emissionManager);
    }

    function _setEmissionPerSecond(
        address asset,
        address reward,
        uint88 newEmissionsPerSecond
    )
        internal
        returns (
            uint oldEmissionPerSecond,
            uint newIndex,
            uint distributionEnd
        )
    {
        RewardsDataTypes.AssetData storage assetConfig = _assetData[asset];
        RewardsDataTypes.RewardDistribution storage rewardDistribution = _assetData[asset]
            .rewardDistribution[reward];
        uint decimals = assetConfig.decimals;
        if (decimals == 0 || rewardDistribution.lastUpdateTimestamp == 0) {
            revert DistributionNonExistent(asset, reward);
        }

        distributionEnd = rewardDistribution.distributionEnd;

        (newIndex, ) = _updateRewardDistribution(
            rewardDistribution,
            solidStakingViewActions.totalStaked(asset),
            10**decimals
        );

        oldEmissionPerSecond = rewardDistribution.emissionPerSecond;
        rewardDistribution.emissionPerSecond = newEmissionsPerSecond;
    }

    function _setDistributionEnd(
        address asset,
        address reward,
        uint32 newDistributionEnd
    ) internal returns (uint oldDistributionEnd) {
        oldDistributionEnd = _assetData[asset].rewardDistribution[reward].distributionEnd;
        _assetData[asset].rewardDistribution[reward].distributionEnd = newDistributionEnd;
    }
}