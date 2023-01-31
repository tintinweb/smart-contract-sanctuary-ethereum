// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IAdminACLV0 {
    /**
     * @notice Token ID `_tokenId` minted to `_to`.
     * @param previousSuperAdmin The previous superAdmin address.
     * @param newSuperAdmin The new superAdmin address.
     * @param genArt721CoreAddressesToUpdate Array of genArt721Core
     * addresses to update to the new superAdmin, for indexing purposes only.
     */
    event SuperAdminTransferred(
        address indexed previousSuperAdmin,
        address indexed newSuperAdmin,
        address[] genArt721CoreAddressesToUpdate
    );

    /// Type of the Admin ACL contract, e.g. "AdminACLV0"
    function AdminACLType() external view returns (string memory);

    /// super admin address
    function superAdmin() external view returns (address);

    /**
     * @notice Calls transferOwnership on other contract from this contract.
     * This is useful for updating to a new AdminACL contract.
     * @dev this function should be gated to only superAdmin-like addresses.
     */
    function transferOwnershipOn(
        address _contract,
        address _newAdminACL
    ) external;

    /**
     * @notice Calls renounceOwnership on other contract from this contract.
     * @dev this function should be gated to only superAdmin-like addresses.
     */
    function renounceOwnershipOn(address _contract) external;

    /**
     * @notice Checks if sender `_sender` is allowed to call function with selector
     * `_selector` on contract `_contract`.
     */
    function allowed(
        address _sender,
        address _contract,
        bytes4 _selector
    ) external returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

/**
 * @title This interface is a mixin for IFilteredMinterExpSettlementV<version>
 * interfaces to use when defining settlement minter interfaces.
 * @author Art Blocks Inc.
 */
interface IFilteredMinterDAExpSettlement_Mixin {
    /// Auction details cleared for project `projectId`.
    /// At time of reset, the project has had `numPurchases` purchases on this
    /// minter, with a most recent purchase price of `latestPurchasePrice`. If
    /// the number of purchases is 0, the latest purchase price will have a
    /// dummy value of 0.
    event ResetAuctionDetails(
        uint256 indexed projectId,
        uint256 numPurchases,
        uint256 latestPurchasePrice
    );

    /// sellout price updated for project `projectId`.
    /// @dev does not use generic event because likely will trigger additional
    /// actions in indexing layer
    event SelloutPriceUpdated(
        uint256 indexed _projectId,
        uint256 _selloutPrice
    );

    /// artist and admin have withdrawn revenues from settleable purchases for
    /// project `projectId`.
    /// @dev does not use generic event because likely will trigger additional
    /// actions in indexing layer
    event ArtistAndAdminRevenuesWithdrawn(uint256 indexed _projectId);

    /// receipt has an updated state
    event ReceiptUpdated(
        address indexed _purchaser,
        uint256 indexed _projectId,
        uint256 _numPurchased,
        uint256 _netPosted
    );

    /// returns latest purchase price for project `_projectId`, or 0 if no
    /// purchases have been made.
    function getProjectLatestPurchasePrice(
        uint256 _projectId
    ) external view returns (uint256 latestPurchasePrice);

    /// returns the number of settleable invocations for project `_projectId`.
    function getNumSettleableInvocations(
        uint256 _projectId
    ) external view returns (uint256 numSettleableInvocations);

    /// Returns the current excess settlement funds on project `_projectId`
    /// for address `_walletAddress`.
    function getProjectExcessSettlementFunds(
        uint256 _projectId,
        address _walletAddress
    ) external view returns (uint256 excessSettlementFundsInWei);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "./IFilteredMinterDAExpSettlement_Mixin.sol";
import "./IFilteredMinterV1.sol";
import "./IFilteredMinterDAExpV0.sol";

pragma solidity ^0.8.0;

/**
 * @title This interface combines the set of interfaces that add support for
 * a Dutch Auction with Settlement minter.
 * @author Art Blocks Inc.
 */
interface IFilteredMinterDAExpSettlementV0 is
    IFilteredMinterDAExpSettlement_Mixin,
    IFilteredMinterV1,
    IFilteredMinterDAExpV0
{

}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "./IFilteredMinterV0.sol";

pragma solidity ^0.8.0;

/**
 * @title This interface extends the IFilteredMinterV0 interface in order to
 * add support for exponential descending auctions.
 * @author Art Blocks Inc.
 */
interface IFilteredMinterDAExpV0 is IFilteredMinterV0 {
    /// Auction details updated for project `projectId`.
    event SetAuctionDetails(
        uint256 indexed projectId,
        uint256 _auctionTimestampStart,
        uint256 _priceDecayHalfLifeSeconds,
        uint256 _startPrice,
        uint256 _basePrice
    );

    /// Auction details cleared for project `projectId`.
    event ResetAuctionDetails(uint256 indexed projectId);

    /// Maximum and minimum allowed price decay half lifes updated.
    event AuctionHalfLifeRangeSecondsUpdated(
        uint256 _minimumPriceDecayHalfLifeSeconds,
        uint256 _maximumPriceDecayHalfLifeSeconds
    );

    function minimumPriceDecayHalfLifeSeconds() external view returns (uint256);

    function maximumPriceDecayHalfLifeSeconds() external view returns (uint256);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IFilteredMinterV0 {
    /**
     * @notice Price per token in wei updated for project `_projectId` to
     * `_pricePerTokenInWei`.
     */
    event PricePerTokenInWeiUpdated(
        uint256 indexed _projectId,
        uint256 indexed _pricePerTokenInWei
    );

    /**
     * @notice Currency updated for project `_projectId` to symbol
     * `_currencySymbol` and address `_currencyAddress`.
     */
    event ProjectCurrencyInfoUpdated(
        uint256 indexed _projectId,
        address indexed _currencyAddress,
        string _currencySymbol
    );

    /// togglePurchaseToDisabled updated
    event PurchaseToDisabledUpdated(
        uint256 indexed _projectId,
        bool _purchaseToDisabled
    );

    // getter function of public variable
    function minterType() external view returns (string memory);

    function genArt721CoreAddress() external returns (address);

    function minterFilterAddress() external returns (address);

    // Triggers a purchase of a token from the desired project, to the
    // TX-sending address.
    function purchase(
        uint256 _projectId
    ) external payable returns (uint256 tokenId);

    // Triggers a purchase of a token from the desired project, to the specified
    // receiving address.
    function purchaseTo(
        address _to,
        uint256 _projectId
    ) external payable returns (uint256 tokenId);

    // Toggles the ability for `purchaseTo` to be called directly with a
    // specified receiving address that differs from the TX-sending address.
    function togglePurchaseToDisabled(uint256 _projectId) external;

    // Called to make the minter contract aware of the max invocations for a
    // given project.
    function setProjectMaxInvocations(uint256 _projectId) external;

    // Gets if token price is configured, token price in wei, currency symbol,
    // and currency address, assuming this is project's minter.
    // Supersedes any defined core price.
    function getPriceInfo(
        uint256 _projectId
    )
        external
        view
        returns (
            bool isConfigured,
            uint256 tokenPriceInWei,
            string memory currencySymbol,
            address currencyAddress
        );
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "./IFilteredMinterV0.sol";

pragma solidity ^0.8.0;

/**
 * @title This interface extends the IFilteredMinterV0 interface in order to
 * add support for generic project minter configuration updates.
 * @dev keys represent strings of finite length encoded in bytes32 to minimize
 * gas.
 * @author Art Blocks Inc.
 */
interface IFilteredMinterV1 is IFilteredMinterV0 {
    /// ANY
    /**
     * @notice Generic project minter configuration event. Removes key `_key`
     * for project `_projectId`.
     */
    event ConfigKeyRemoved(uint256 indexed _projectId, bytes32 _key);

    /// BOOL
    /**
     * @notice Generic project minter configuration event. Sets value of key
     * `_key` to `_value` for project `_projectId`.
     */
    event ConfigValueSet(uint256 indexed _projectId, bytes32 _key, bool _value);

    /// UINT256
    /**
     * @notice Generic project minter configuration event. Sets value of key
     * `_key` to `_value` for project `_projectId`.
     */
    event ConfigValueSet(
        uint256 indexed _projectId,
        bytes32 _key,
        uint256 _value
    );

    /**
     * @notice Generic project minter configuration event. Adds value `_value`
     * to the set of uint256 at key `_key` for project `_projectId`.
     */
    event ConfigValueAddedToSet(
        uint256 indexed _projectId,
        bytes32 _key,
        uint256 _value
    );

    /**
     * @notice Generic project minter configuration event. Removes value
     * `_value` to the set of uint256 at key `_key` for project `_projectId`.
     */
    event ConfigValueRemovedFromSet(
        uint256 indexed _projectId,
        bytes32 _key,
        uint256 _value
    );

    /// ADDRESS
    /**
     * @notice Generic project minter configuration event. Sets value of key
     * `_key` to `_value` for project `_projectId`.
     */
    event ConfigValueSet(
        uint256 indexed _projectId,
        bytes32 _key,
        address _value
    );

    /**
     * @notice Generic project minter configuration event. Adds value `_value`
     * to the set of addresses at key `_key` for project `_projectId`.
     */
    event ConfigValueAddedToSet(
        uint256 indexed _projectId,
        bytes32 _key,
        address _value
    );

    /**
     * @notice Generic project minter configuration event. Removes value
     * `_value` to the set of addresses at key `_key` for project `_projectId`.
     */
    event ConfigValueRemovedFromSet(
        uint256 indexed _projectId,
        bytes32 _key,
        address _value
    );

    /// BYTES32
    /**
     * @notice Generic project minter configuration event. Sets value of key
     * `_key` to `_value` for project `_projectId`.
     */
    event ConfigValueSet(
        uint256 indexed _projectId,
        bytes32 _key,
        bytes32 _value
    );

    /**
     * @notice Generic project minter configuration event. Adds value `_value`
     * to the set of bytes32 at key `_key` for project `_projectId`.
     */
    event ConfigValueAddedToSet(
        uint256 indexed _projectId,
        bytes32 _key,
        bytes32 _value
    );

    /**
     * @notice Generic project minter configuration event. Removes value
     * `_value` to the set of bytes32 at key `_key` for project `_projectId`.
     */
    event ConfigValueRemovedFromSet(
        uint256 indexed _projectId,
        bytes32 _key,
        bytes32 _value
    );

    /**
     * @dev Strings not supported. Recommend conversion of (short) strings to
     * bytes32 to remain gas-efficient.
     */
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "./IFilteredMinterV1.sol";

pragma solidity ^0.8.0;

/**
 * @title This interface extends the IFilteredMinterV1 interface in order to
 * add support for manually setting project max invocations.
 * @author Art Blocks Inc.
 */
interface IFilteredMinterV2 is IFilteredMinterV1 {
    /**
     * @notice Local max invocations for project `_projectId`, tied to core contract `_coreContractAddress`,
     * updated to `_maxInvocations`.
     */
    event ProjectMaxInvocationsLimitUpdated(
        uint256 indexed _projectId,
        uint256 _maxInvocations
    );

    // Sets the local max invocations for a given project, checking that the provided max invocations is
    // less than or equal to the global max invocations for the project set on the core contract.
    // This does not impact the max invocations value defined on the core contract.
    function manuallyLimitProjectMaxInvocations(
        uint256 _projectId,
        uint256 _maxInvocations
    ) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";
/// use the Royalty Registry's IManifold interface for token royalties
import "./IManifold.sol";

/**
 * @title This interface is intended to house interface items that are common
 * across all GenArt721CoreContractV3 flagship and derivative implementations.
 * This interface extends the IManifold royalty interface in order to
 * add support the Royalty Registry by default.
 * @author Art Blocks Inc.
 */
interface IGenArt721CoreContractV3_Base is IManifold {
    /**
     * @notice Token ID `_tokenId` minted to `_to`.
     */
    event Mint(address indexed _to, uint256 indexed _tokenId);

    /**
     * @notice currentMinter updated to `_currentMinter`.
     * @dev Implemented starting with V3 core
     */
    event MinterUpdated(address indexed _currentMinter);

    /**
     * @notice Platform updated on bytes32-encoded field `_field`.
     */
    event PlatformUpdated(bytes32 indexed _field);

    /**
     * @notice Project ID `_projectId` updated on bytes32-encoded field
     * `_update`.
     */
    event ProjectUpdated(uint256 indexed _projectId, bytes32 indexed _update);

    event ProposedArtistAddressesAndSplits(
        uint256 indexed _projectId,
        address _artistAddress,
        address _additionalPayeePrimarySales,
        uint256 _additionalPayeePrimarySalesPercentage,
        address _additionalPayeeSecondarySales,
        uint256 _additionalPayeeSecondarySalesPercentage
    );

    event AcceptedArtistAddressesAndSplits(uint256 indexed _projectId);

    // version and type of the core contract
    // coreVersion is a string of the form "0.x.y"
    function coreVersion() external view returns (string memory);

    // coreType is a string of the form "GenArt721CoreV3"
    function coreType() external view returns (string memory);

    // owner (pre-V3 was named admin) of contract
    // this is expected to be an Admin ACL contract for V3
    function owner() external view returns (address);

    // Admin ACL contract for V3, will be at the address owner()
    function adminACLContract() external returns (IAdminACLV0);

    // backwards-compatible (pre-V3) admin - equal to owner()
    function admin() external view returns (address);

    /**
     * Function determining if _sender is allowed to call function with
     * selector _selector on contract `_contract`. Intended to be used with
     * peripheral contracts such as minters, as well as internally by the
     * core contract itself.
     */
    function adminACLAllowed(
        address _sender,
        address _contract,
        bytes4 _selector
    ) external returns (bool);

    // getter function of public variable
    function nextProjectId() external view returns (uint256);

    // getter function of public mapping
    function tokenIdToProjectId(
        uint256 tokenId
    ) external view returns (uint256 projectId);

    // @dev this is not available in V0
    function isMintWhitelisted(address minter) external view returns (bool);

    function projectIdToArtistAddress(
        uint256 _projectId
    ) external view returns (address payable);

    function projectIdToAdditionalPayeePrimarySales(
        uint256 _projectId
    ) external view returns (address payable);

    function projectIdToAdditionalPayeePrimarySalesPercentage(
        uint256 _projectId
    ) external view returns (uint256);

    // @dev new function in V3
    function projectStateData(
        uint256 _projectId
    )
        external
        view
        returns (
            uint256 invocations,
            uint256 maxInvocations,
            bool active,
            bool paused,
            uint256 completedTimestamp,
            bool locked
        );

    // function to set a token's hash (must be guarded)
    function setTokenHash_8PT(uint256 _tokenId, bytes32 _hash) external;

    // @dev gas-optimized signature in V3 for `mint`
    function mint_Ecf(
        address _to,
        uint256 _projectId,
        address _by
    ) external returns (uint256 tokenId);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";
import "./IGenArt721CoreContractV3_Base.sol";

interface IGenArt721CoreContractV3_Engine is IGenArt721CoreContractV3_Base {
    // @dev new function in V3
    function getPrimaryRevenueSplits(
        uint256 _projectId,
        uint256 _price
    )
        external
        view
        returns (
            uint256 renderProviderRevenue_,
            address payable renderProviderAddress_,
            uint256 platformProviderRevenue_,
            address payable platformProviderAddress_,
            uint256 artistRevenue_,
            address payable artistAddress_,
            uint256 additionalPayeePrimaryRevenue_,
            address payable additionalPayeePrimaryAddress_
        );

    // @dev The render provider primary sales payment address
    function renderProviderPrimarySalesAddress()
        external
        view
        returns (address payable);

    // @dev The platform provider primary sales payment address
    function platformProviderPrimarySalesAddress()
        external
        view
        returns (address payable);

    // @dev Percentage of primary sales allocated to the render provider
    function renderProviderPrimarySalesPercentage()
        external
        view
        returns (uint256);

    // @dev Percentage of primary sales allocated to the platform provider
    function platformProviderPrimarySalesPercentage()
        external
        view
        returns (uint256);

    // @dev The render provider secondary sales royalties payment address
    function renderProviderSecondarySalesAddress()
        external
        view
        returns (address payable);

    // @dev The platform provider secondary sales royalties payment address
    function platformProviderSecondarySalesAddress()
        external
        view
        returns (address payable);

    // @dev Basis points of secondary sales allocated to the render provider
    function renderProviderSecondarySalesBPS() external view returns (uint256);

    // @dev Basis points of secondary sales allocated to the platform provider
    function platformProviderSecondarySalesBPS()
        external
        view
        returns (uint256);

    // function to read the hash for a given tokenId
    function tokenIdToHash(uint256 _tokenId) external view returns (bytes32);

    // function to read the hash-seed for a given tokenId
    function tokenIdToHashSeed(
        uint256 _tokenId
    ) external view returns (bytes12);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";
import "./IGenArt721CoreContractV3_Base.sol";

/**
 * @title This interface extends IGenArt721CoreContractV3_Base with functions
 * that are part of the Art Blocks Flagship core contract.
 * @author Art Blocks Inc.
 */
// This interface extends IGenArt721CoreContractV3_Base with functions that are
// in part of the Art Blocks Flagship core contract.
interface IGenArt721CoreContractV3 is IGenArt721CoreContractV3_Base {
    // @dev new function in V3
    function getPrimaryRevenueSplits(
        uint256 _projectId,
        uint256 _price
    )
        external
        view
        returns (
            uint256 artblocksRevenue_,
            address payable artblocksAddress_,
            uint256 artistRevenue_,
            address payable artistAddress_,
            uint256 additionalPayeePrimaryRevenue_,
            address payable additionalPayeePrimaryAddress_
        );

    // @dev Art Blocks primary sales payment address
    function artblocksPrimarySalesAddress()
        external
        view
        returns (address payable);

    /**
     * @notice Backwards-compatible (pre-V3) function returning Art Blocks
     * primary sales payment address (now called artblocksPrimarySalesAddress).
     */
    function artblocksAddress() external view returns (address payable);

    // @dev Percentage of primary sales allocated to Art Blocks
    function artblocksPrimarySalesPercentage() external view returns (uint256);

    /**
     * @notice Backwards-compatible (pre-V3) function returning Art Blocks
     * primary sales percentage (now called artblocksPrimarySalesPercentage).
     */
    function artblocksPercentage() external view returns (uint256);

    // @dev Art Blocks secondary sales royalties payment address
    function artblocksSecondarySalesAddress()
        external
        view
        returns (address payable);

    // @dev Basis points of secondary sales allocated to Art Blocks
    function artblocksSecondarySalesBPS() external view returns (uint256);

    /**
     * @notice Backwards-compatible (pre-V3) function  that gets artist +
     * artist's additional payee royalty data for token ID `_tokenId`.
     * WARNING: Does not include Art Blocks portion of royalties.
     */
    function getRoyaltyData(
        uint256 _tokenId
    )
        external
        view
        returns (
            address artistAddress,
            address additionalPayee,
            uint256 additionalPayeePercentage,
            uint256 royaltyFeeByID
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @dev Royalty Registry interface, used to support the Royalty Registry.
/// @dev Source: https://github.com/manifoldxyz/royalty-registry-solidity/blob/main/contracts/specs/IManifold.sol

/// @author: manifold.xyz

/**
 * @dev Royalty interface for creator core classes
 */
interface IManifold {
    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     *
     *  bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
     *
     *  => 0xbb3bafd6 = 0xbb3bafd6
     */
    function getRoyalties(
        uint256 tokenId
    ) external view returns (address payable[] memory, uint256[] memory);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "./IFilteredMinterV2.sol";

pragma solidity ^0.8.0;

/**
 * @title This interface defines any events or functions required for a minter
 * to conform to the MinterBase contract.
 * @dev The MinterBase contract was not implemented from the beginning of the
 * MinterSuite contract suite, therefore early versions of some minters may not
 * conform to this interface.
 * @author Art Blocks Inc.
 */
interface IMinterBaseV0 {
    // Function that returns if a minter is configured to integrate with a V3 flagship or V3 engine contract.
    // Returns true only if the minter is configured to integrate with an engine contract.
    function isEngine() external returns (bool isEngine);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IMinterFilterV0 {
    /**
     * @notice Approved minter `_minterAddress`.
     */
    event MinterApproved(address indexed _minterAddress, string _minterType);

    /**
     * @notice Revoked approval for minter `_minterAddress`
     */
    event MinterRevoked(address indexed _minterAddress);

    /**
     * @notice Minter `_minterAddress` of type `_minterType`
     * registered for project `_projectId`.
     */
    event ProjectMinterRegistered(
        uint256 indexed _projectId,
        address indexed _minterAddress,
        string _minterType
    );

    /**
     * @notice Any active minter removed for project `_projectId`.
     */
    event ProjectMinterRemoved(uint256 indexed _projectId);

    function genArt721CoreAddress() external returns (address);

    function setMinterForProject(uint256, address) external;

    function removeMinterForProject(uint256) external;

    function mint(
        address _to,
        uint256 _projectId,
        address sender
    ) external returns (uint256);

    function getMinterForProject(uint256) external view returns (address);

    function projectHasMinter(uint256) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "../../interfaces/0.8.x/IMinterBaseV0.sol";
import "../../interfaces/0.8.x/IGenArt721CoreContractV3_Base.sol";
import "../../interfaces/0.8.x/IGenArt721CoreContractV3.sol";
import "../../interfaces/0.8.x/IGenArt721CoreContractV3_Engine.sol";

import "@openzeppelin-4.7/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.0;

/**
 * @title Art Blocks Minter Base Class
 * @notice A base class for Art Blocks minter contracts that provides common
 * functionality used across minter contracts.
 * This contract is not intended to be deployed directly, but rather to be
 * inherited by other minter contracts.
 * From a design perspective, this contract is intended to remain simple and
 * easy to understand. It is not intended to cause a complex inheritance tree,
 * and instead should keep minter contracts as readable as possible for
 * collectors and developers.
 * @dev Semantic versioning is used in the solidity file name, and is therefore
 * controlled by contracts importing the appropriate filename version.
 * @author Art Blocks Inc.
 */
abstract contract MinterBase is IMinterBaseV0 {
    /// state variable that tracks whether this contract's associated core
    /// contract is an Engine contract, where Engine contracts have an
    /// additional revenue split for the platform provider
    bool public immutable isEngine;

    // @dev we do not track an initialization state, as the only state variable
    // is immutable, which the compiler enforces to be assigned during
    // construction.

    /**
     * @notice Initializes contract to ensure state variable `isEngine` is set
     * appropriately based on the minter's associated core contract address.
     * @param genArt721Address Art Blocks core contract address for
     * which this contract will be a minter.
     */
    constructor(address genArt721Address) {
        // set state variable isEngine
        isEngine = _getV3CoreIsEngine(genArt721Address);
    }

    /**
     * @notice splits ETH funds between sender (if refund), providers,
     * artist, and artist's additional payee for a token purchased on
     * project `_projectId`.
     * WARNING: This function uses msg.value and msg.sender to determine
     * refund amounts, and therefore may not be applicable to all use cases
     * (e.g. do not use with Dutch Auctions with on-chain settlement).
     * @dev possible DoS during splits is acknowledged, and mitigated by
     * business practices, including end-to-end testing on mainnet, and
     * admin-accepted artist payment addresses.
     * @param projectId Project ID for which funds shall be split.
     * @param pricePerTokenInWei Current price of token, in Wei.
     */
    function splitFundsETH(
        uint256 projectId,
        uint256 pricePerTokenInWei,
        address genArt721CoreAddress
    ) internal {
        if (msg.value > 0) {
            bool success_;
            // send refund to sender
            uint256 refund = msg.value - pricePerTokenInWei;
            if (refund > 0) {
                (success_, ) = msg.sender.call{value: refund}("");
                require(success_, "Refund failed");
            }
            // split revenues
            splitRevenuesETH(
                projectId,
                pricePerTokenInWei,
                genArt721CoreAddress
            );
        }
    }

    /**
     * @notice splits ETH revenues between providers, artist, and artist's
     * additional payee for revenue generated by project `_projectId`.
     * @dev possible DoS during splits is acknowledged, and mitigated by
     * business practices, including end-to-end testing on mainnet, and
     * admin-accepted artist payment addresses.
     * @param projectId Project ID for which funds shall be split.
     * @param valueInWei Value to be split, in Wei.
     */
    function splitRevenuesETH(
        uint256 projectId,
        uint256 valueInWei,
        address genArtCoreContract
    ) internal {
        if (valueInWei <= 0) {
            return; // return early
        }
        bool success;
        // split funds between platforms, artist, and artist's
        // additional payee
        uint256 renderProviderRevenue_;
        address payable renderProviderAddress_;
        uint256 artistRevenue_;
        address payable artistAddress_;
        uint256 additionalPayeePrimaryRevenue_;
        address payable additionalPayeePrimaryAddress_;
        if (isEngine) {
            // get engine splits
            uint256 platformProviderRevenue_;
            address payable platformProviderAddress_;
            (
                renderProviderRevenue_,
                renderProviderAddress_,
                platformProviderRevenue_,
                platformProviderAddress_,
                artistRevenue_,
                artistAddress_,
                additionalPayeePrimaryRevenue_,
                additionalPayeePrimaryAddress_
            ) = IGenArt721CoreContractV3_Engine(genArtCoreContract)
                .getPrimaryRevenueSplits(projectId, valueInWei);
            // Platform Provider payment (only possible if engine)
            if (platformProviderRevenue_ > 0) {
                (success, ) = platformProviderAddress_.call{
                    value: platformProviderRevenue_
                }("");
                require(success, "Platform Provider payment failed");
            }
        } else {
            // get flagship splits
            (
                renderProviderRevenue_, // artblocks revenue
                renderProviderAddress_, // artblocks address
                artistRevenue_,
                artistAddress_,
                additionalPayeePrimaryRevenue_,
                additionalPayeePrimaryAddress_
            ) = IGenArt721CoreContractV3(genArtCoreContract)
                .getPrimaryRevenueSplits(projectId, valueInWei);
        }
        // Render Provider / Art Blocks payment
        if (renderProviderRevenue_ > 0) {
            (success, ) = renderProviderAddress_.call{
                value: renderProviderRevenue_
            }("");
            require(success, "Render Provider payment failed");
        }
        // artist payment
        if (artistRevenue_ > 0) {
            (success, ) = artistAddress_.call{value: artistRevenue_}("");
            require(success, "Artist payment failed");
        }
        // additional payee payment
        if (additionalPayeePrimaryRevenue_ > 0) {
            (success, ) = additionalPayeePrimaryAddress_.call{
                value: additionalPayeePrimaryRevenue_
            }("");
            require(success, "Additional Payee payment failed");
        }
    }

    /**
     * @notice splits ERC-20 funds between providers, artist, and artist's
     * additional payee, for a token purchased on project `_projectId`.
     * @dev possible DoS during splits is acknowledged, and mitigated by
     * business practices, including end-to-end testing on mainnet, and
     * admin-accepted artist payment addresses.
     */
    function splitFundsERC20(
        uint256 projectId,
        uint256 pricePerTokenInWei,
        address currencyAddress,
        address genArtCoreContract
    ) internal {
        IERC20 _projectCurrency = IERC20(currencyAddress);
        // split remaining funds between foundation, artist, and artist's
        // additional payee
        uint256 renderProviderRevenue_;
        address payable renderProviderAddress_;
        uint256 artistRevenue_;
        address payable artistAddress_;
        uint256 additionalPayeePrimaryRevenue_;
        address payable additionalPayeePrimaryAddress_;
        if (isEngine) {
            // get engine splits
            uint256 platformProviderRevenue_;
            address payable platformProviderAddress_;
            (
                renderProviderRevenue_,
                renderProviderAddress_,
                platformProviderRevenue_,
                platformProviderAddress_,
                artistRevenue_,
                artistAddress_,
                additionalPayeePrimaryRevenue_,
                additionalPayeePrimaryAddress_
            ) = IGenArt721CoreContractV3_Engine(genArtCoreContract)
                .getPrimaryRevenueSplits(projectId, pricePerTokenInWei);
            // Platform Provider payment (only possible if engine)
            if (platformProviderRevenue_ > 0) {
                _projectCurrency.transferFrom(
                    msg.sender,
                    platformProviderAddress_,
                    platformProviderRevenue_
                );
            }
        } else {
            // get flagship splits
            (
                renderProviderRevenue_, // artblocks revenue
                renderProviderAddress_, // artblocks address
                artistRevenue_,
                artistAddress_,
                additionalPayeePrimaryRevenue_,
                additionalPayeePrimaryAddress_
            ) = IGenArt721CoreContractV3(genArtCoreContract)
                .getPrimaryRevenueSplits(projectId, pricePerTokenInWei);
        }
        // Art Blocks payment
        if (renderProviderRevenue_ > 0) {
            _projectCurrency.transferFrom(
                msg.sender,
                renderProviderAddress_,
                renderProviderRevenue_
            );
        }
        // artist payment
        if (artistRevenue_ > 0) {
            _projectCurrency.transferFrom(
                msg.sender,
                artistAddress_,
                artistRevenue_
            );
        }
        // additional payee payment
        if (additionalPayeePrimaryRevenue_ > 0) {
            _projectCurrency.transferFrom(
                msg.sender,
                additionalPayeePrimaryAddress_,
                additionalPayeePrimaryRevenue_
            );
        }
    }

    /**
     * @notice Returns whether a V3 core contract is an Art Blocks Engine
     * contract or not. Return value of false indicates that the core is a
     * flagship contract.
     * @dev this function reverts if a core contract does not return the
     * expected number of return values from getPrimaryRevenueSplits() for
     * either a flagship or engine core contract.
     * @dev this function uses the length of the return data (in bytes) to
     * determine whether the core is an engine or not.
     * @param genArt721CoreV3 The address of the deployed core contract.
     */
    function _getV3CoreIsEngine(
        address genArt721CoreV3
    ) private returns (bool) {
        // call getPrimaryRevenueSplits() on core contract
        bytes memory payload = abi.encodeWithSignature(
            "getPrimaryRevenueSplits(uint256,uint256)",
            0,
            0
        );
        (bool success, bytes memory returnData) = genArt721CoreV3.call(payload);
        require(success, "getPrimaryRevenueSplits() call failed");
        // determine whether core is engine or not, based on return data length
        uint256 returnDataLength = returnData.length;
        if (returnDataLength == 6 * 32) {
            // 6 32-byte words returned if flagship (not engine)
            // @dev 6 32-byte words are expected because the non-engine core
            // contracts return a payout address and uint256 payment value for
            // the artist, and artist's additional payee, and Art Blocks.
            // also note that per Solidity ABI encoding, the address return
            // values are padded to 32 bytes.
            return false;
        } else if (returnDataLength == 8 * 32) {
            // 8 32-byte words returned if engine
            // @dev 8 32-byte words are expected because the engine core
            // contracts return a payout address and uint256 payment value for
            // the artist, artist's additional payee, render provider
            // typically Art Blocks, and platform provider (partner).
            // also note that per Solidity ABI encoding, the address return
            // values are padded to 32 bytes.
            return true;
        } else {
            // unexpected return value length
            revert("Unexpected revenue split bytes");
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "../../../interfaces/0.8.x/IGenArt721CoreContractV3_Base.sol";
import "../../../interfaces/0.8.x/IMinterFilterV0.sol";
import "../../../interfaces/0.8.x/IFilteredMinterDAExpSettlementV0.sol";
import "../MinterBase_v0_1_1.sol";

import "@openzeppelin-4.7/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin-4.7/contracts/utils/math/SafeCast.sol";

pragma solidity 0.8.17;

/**
 * @title Filtered Minter contract that allows tokens to be minted with ETH.
 * Pricing is achieved using an automated Dutch-auction mechanism, with a
 * settlement mechanism for tokens purchased before the auction ends.
 * This is designed to be used with GenArt721CoreContractV3 flagship or
 * engine contracts.
 * @author Art Blocks Inc.
 * @notice Privileged Roles and Ownership:
 * This contract is designed to be managed, with limited powers.
 * Privileged roles and abilities are controlled by the core contract's Admin
 * ACL contract and a project's artist. Both of these roles hold extensive
 * power and can modify minter details.
 * Care must be taken to ensure that the admin ACL contract and artist
 * addresses are secure behind a multi-sig or other access control mechanism.
 * Additionally, the purchaser of a token has some trust assumptions regarding
 * settlement, beyond typical minter Art Blocks trust assumptions. In general,
 * Artists and Admin are trusted to not abuse their powers in a way that
 * would artifically inflate the sellout price of a project. They are
 * incentivized to not do so, as it would diminish their reputation and
 * ability to sell future projects. Agreements between Admin and Artist
 * may or may not be in place to further dissuade artificial inflation of an
 * auction's sellout price.
 * ----------------------------------------------------------------------------
 * The following functions are restricted to the core contract's Admin ACL
 * contract:
 * - setAllowablePriceDecayHalfLifeRangeSeconds (note: this range is only
 *   enforced when creating new auctions)
 * - resetAuctionDetails (note: this will prevent minting until a new auction
 *   is created)
 * - adminEmergencyReduceSelloutPrice
 * ----------------------------------------------------------------------------
 * The following functions are restricted to a project's artist or the core
 * contract's Admin ACL contract:
 * - withdrawArtistAndAdminRevenues (note: this may only be called after an
 *   auction has sold out or has reached base price)
 * ----------------------------------------------------------------------------
 * The following functions are restricted to a project's artist:
 * - setAuctionDetails (note: this may only be called when there is no active
 *   auction, and must start at a price less than or equal to any previously
 *   made purchases)
 * ----------------------------------------------------------------------------
 * Additional admin and artist privileged roles may be described on other
 * contracts that this minter integrates with.
 *
 * @dev Note that while this minter makes use of `block.timestamp` and it is
 * technically possible that this value is manipulated by block producers via
 * denial of service (in PoS), such manipulation will not have material impact
 * on the price values of this minter given the business practices for how
 * pricing is congfigured for this minter and that variations on the order of
 * less than a minute should not meaningfully impact price given the minimum
 * allowable price decay rate that this minter intends to support.
 */
contract MinterDAExpSettlementV1 is
    ReentrancyGuard,
    MinterBase,
    IFilteredMinterDAExpSettlementV0
{
    using SafeCast for uint256;

    /// Core contract address this minter interacts with
    address public immutable genArt721CoreAddress;
    /// The core contract integrates with V3 contracts
    IGenArt721CoreContractV3_Base private immutable genArtCoreContract_Base;

    /// Minter filter address this minter interacts with
    address public immutable minterFilterAddress;

    /// Minter filter this minter may interact with.
    IMinterFilterV0 private immutable minterFilter;

    /// minterType for this minter
    string public constant minterType = "MinterDAExpSettlementV1";

    uint256 constant ONE_MILLION = 1_000_000;

    struct ProjectConfig {
        // on this minter, hasMaxBeenInvoked is updated only during every
        // purchase, and is only true if this minter minted the final token.
        // this enables the minter to know when a sellout price is greater than
        // the auction's base price.
        bool maxHasBeenInvoked;
        // set to true only after artist + admin revenues have been collected
        bool auctionRevenuesCollected;
        // number of tokens minted that have potential of future settlement.
        // max uint24 > 16.7 million tokens > 1 million tokens/project max
        uint24 numSettleableInvocations;
        // max uint64 ~= 1.8e19 sec ~= 570 billion years
        uint64 timestampStart;
        uint64 priceDecayHalfLifeSeconds;
        // Prices are packed internally as uint128, resulting in a maximum
        // allowed price of ~3.4e20 ETH. This is many orders of magnitude
        // greater than current ETH supply.
        uint128 startPrice;
        // base price is non-zero for all configured auctions on this minter
        uint128 basePrice;
        // This value is only zero if no purchases have been made on this
        // minter.
        // When non-zero, this value is used as a reference when an auction is
        // reset by admin, and then a new auction is configured by an artist.
        // In that case, the new auction will be required to have a starting
        // price less than or equal to this value, if one or more purchases
        // have been made on this minter.
        uint256 latestPurchasePrice;
    }

    mapping(uint256 => ProjectConfig) public projectConfig;

    /// Minimum price decay half life: price must decay with a half life of at
    /// least this amount (must cut in half at least every N seconds).
    uint256 public minimumPriceDecayHalfLifeSeconds = 300; // 5 minutes
    /// Maximum price decay half life: price may decay with a half life of no
    /// more than this amount (may cut in half at no more than every N seconds).
    uint256 public maximumPriceDecayHalfLifeSeconds = 3600; // 60 minutes

    struct Receipt {
        // max uint232 allows for > 1e51 ETH (much more than max supply)
        uint232 netPosted;
        // max uint24 still allows for > max project supply of 1 million tokens
        uint24 numPurchased;
    }
    /// user address => project ID => receipt
    mapping(address => mapping(uint256 => Receipt)) receipts;

    // modifier to restrict access to only AdminACL or the artist
    modifier onlyCoreAdminACLOrArtist(uint256 _projectId, bytes4 _selector) {
        require(
            (msg.sender ==
                genArtCoreContract_Base.projectIdToArtistAddress(_projectId)) ||
                (
                    genArtCoreContract_Base.adminACLAllowed(
                        msg.sender,
                        address(this),
                        _selector
                    )
                ),
            "Only Artist or Admin ACL"
        );
        _;
    }

    // modifier to restrict access to only AdminACL allowed calls
    // @dev defers which ACL contract is used to the core contract
    modifier onlyCoreAdminACL(bytes4 _selector) {
        require(
            genArtCoreContract_Base.adminACLAllowed(
                msg.sender,
                address(this),
                _selector
            ),
            "Only Core AdminACL allowed"
        );
        _;
    }

    modifier onlyArtist(uint256 _projectId) {
        require(
            (msg.sender ==
                genArtCoreContract_Base.projectIdToArtistAddress(_projectId)),
            "Only Artist"
        );
        _;
    }

    /**
     * @notice Initializes contract to be a Filtered Minter for
     * `_minterFilter`, integrated with Art Blocks core contract
     * at address `_genArt721Address`.
     * @param _genArt721Address Art Blocks core contract address for
     * which this contract will be a minter.
     * @param _minterFilter Minter filter for which
     * this will a filtered minter.
     */
    constructor(
        address _genArt721Address,
        address _minterFilter
    ) ReentrancyGuard() MinterBase(_genArt721Address) {
        genArt721CoreAddress = _genArt721Address;
        // always populate immutable engine contracts, but only use appropriate
        // interface based on isEngine in the rest of the contract
        genArtCoreContract_Base = IGenArt721CoreContractV3_Base(
            _genArt721Address
        );
        minterFilterAddress = _minterFilter;
        minterFilter = IMinterFilterV0(_minterFilter);
        require(
            minterFilter.genArt721CoreAddress() == _genArt721Address,
            "Illegal contract pairing"
        );
    }

    /**
     * @notice This function is not implemented on this minter, and exists only
     * for interface conformance reasons. This minter checks if max invocations
     * have been reached during every purchase to determine if a sellout has
     * occurred. Therefore, the local caching of max invocations is not
     * beneficial or necessary.
     */
    function setProjectMaxInvocations(uint256 /*_projectId*/) external pure {
        // not implemented because maxInvocations must be checked during every mint
        // to know if final price should be set
        revert(
            "setProjectMaxInvocations not implemented - updated during every mint"
        );
    }

    /**
     * @notice Warning: Disabling purchaseTo is not supported on this minter.
     * This method exists purely for interface-conformance purposes.
     */
    function togglePurchaseToDisabled(
        uint256 _projectId
    ) external view onlyArtist(_projectId) {
        revert("Action not supported");
    }

    /**
     * @notice projectId => has project reached its maximum number of
     * invocations while being minted with this minter?
     * Note that this returns a local cache of the core contract's
     * state, and may be out of sync with the core contract. This is
     * intentional. A false negative will only result in a gas cost increase,
     * since the core contract will still enforce max invocations during during
     * minting. A false negative will also only occur if the max invocations
     * was either reduced on the core contract to equal current invocations, or
     * if the max invocations was reached by minting on a different minter.
     * In both of these cases, we expect the net purchase price (after
     * settlement) shall be the base price of the project's auction. This
     * prevents an artist from benefiting by reducing max invocations on the
     * core mid-auction, or by minting on a different minter.
     * Note that if an artist wishes to reduce the max invocations on the core
     * to something less than the current invocations, but more than max
     * invocations (with the hope of increasing the sellout price), an admin
     * function is provided to manually reduce the sellout price to a lower
     * value, if desired, in the `adminEmergencyReduceSelloutPrice`
     * function.
     * @param _projectId projectId to be queried
     *
     */
    function projectMaxHasBeenInvoked(
        uint256 _projectId
    ) external view returns (bool) {
        return projectConfig[_projectId].maxHasBeenInvoked;
    }

    /**
     * @notice projectId => auction parameters
     */
    function projectAuctionParameters(
        uint256 _projectId
    )
        external
        view
        returns (
            uint256 timestampStart,
            uint256 priceDecayHalfLifeSeconds,
            uint256 startPrice,
            uint256 basePrice
        )
    {
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        return (
            _projectConfig.timestampStart,
            _projectConfig.priceDecayHalfLifeSeconds,
            _projectConfig.startPrice,
            _projectConfig.basePrice
        );
    }

    /**
     * @notice Sets the minimum and maximum values that are settable for
     * `_priceDecayHalfLifeSeconds` across all projects.
     * @param _minimumPriceDecayHalfLifeSeconds Minimum price decay half life
     * (in seconds).
     * @param _maximumPriceDecayHalfLifeSeconds Maximum price decay half life
     * (in seconds).
     */
    function setAllowablePriceDecayHalfLifeRangeSeconds(
        uint256 _minimumPriceDecayHalfLifeSeconds,
        uint256 _maximumPriceDecayHalfLifeSeconds
    )
        external
        onlyCoreAdminACL(
            this.setAllowablePriceDecayHalfLifeRangeSeconds.selector
        )
    {
        require(
            _maximumPriceDecayHalfLifeSeconds >
                _minimumPriceDecayHalfLifeSeconds,
            "Maximum half life must be greater than minimum"
        );
        require(
            _minimumPriceDecayHalfLifeSeconds > 0,
            "Half life of zero not allowed"
        );
        minimumPriceDecayHalfLifeSeconds = _minimumPriceDecayHalfLifeSeconds;
        maximumPriceDecayHalfLifeSeconds = _maximumPriceDecayHalfLifeSeconds;
        emit AuctionHalfLifeRangeSecondsUpdated(
            _minimumPriceDecayHalfLifeSeconds,
            _maximumPriceDecayHalfLifeSeconds
        );
    }

    ////// Auction Functions
    /**
     * @notice Sets auction details for project `_projectId`.
     * @param _projectId Project ID to set auction details for.
     * @param _auctionTimestampStart Timestamp at which to start the auction.
     * @param _priceDecayHalfLifeSeconds The half life with which to decay the
     *  price (in seconds).
     * @param _startPrice Price at which to start the auction, in Wei.
     * If a previous auction existed on this minter and at least one settleable
     * purchase has been made, this value must be less than or equal to the
     * price when the previous auction was paused. This enforces an overall
     * monatonically decreasing auction. Must be greater than or equal to
     * max(uint128) for internal storage packing purposes.
     * @param _basePrice Resting price of the auction, in Wei. Must be greater
     * than or equal to max(uint128) for internal storage packing purposes.
     * @dev Note that setting the auction price explicitly to `0` is
     * intentionally not allowed. This allows the minter to use the assumption
     * that a price of `0` indicates that the auction is not configured.
     * @dev Note that prices must be <= max(128) for internal storage packing
     * efficiency purposes only. This function's interface remains unchanged
     * for interface conformance purposes.
     */
    function setAuctionDetails(
        uint256 _projectId,
        uint256 _auctionTimestampStart,
        uint256 _priceDecayHalfLifeSeconds,
        uint256 _startPrice,
        uint256 _basePrice
    ) external onlyArtist(_projectId) {
        // CHECKS
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        require(
            _projectConfig.timestampStart == 0 ||
                block.timestamp < _projectConfig.timestampStart,
            "No modifications mid-auction"
        );
        require(
            block.timestamp < _auctionTimestampStart,
            "Only future auctions"
        );
        require(
            _startPrice > _basePrice,
            "Auction start price must be greater than auction end price"
        );
        // require _basePrice is non-zero to simplify logic of this minter
        require(_basePrice > 0, "Base price must be non-zero");
        // If previous purchases have been made, require monotonically
        // decreasing purchase prices to preserve settlement and revenue
        // claiming logic. Since base price is always non-zero, if
        // latestPurchasePrice is zero, then no previous purchases have been
        // made, and startPrice may be set to any value.
        require(
            _projectConfig.latestPurchasePrice == 0 || // never purchased
                _startPrice <= _projectConfig.latestPurchasePrice,
            "Auction start price must be <= latest purchase price"
        );
        require(
            (_priceDecayHalfLifeSeconds >= minimumPriceDecayHalfLifeSeconds) &&
                (_priceDecayHalfLifeSeconds <=
                    maximumPriceDecayHalfLifeSeconds),
            "Price decay half life must fall between min and max allowable values"
        );
        // EFFECTS
        _projectConfig.timestampStart = _auctionTimestampStart.toUint64();
        _projectConfig.priceDecayHalfLifeSeconds = _priceDecayHalfLifeSeconds
            .toUint64();
        _projectConfig.startPrice = _startPrice.toUint128();
        _projectConfig.basePrice = _basePrice.toUint128();

        emit SetAuctionDetails(
            _projectId,
            _auctionTimestampStart,
            _priceDecayHalfLifeSeconds,
            _startPrice,
            _basePrice
        );
    }

    /**
     * @notice Resets auction details for project `_projectId`, zero-ing out all
     * relevant auction fields. Not intended to be used in normal auction
     * operation, but rather only in case of the need to reset an ongoing
     * auction. An expected time this might occur would be when a frontend
     * issue was occuring, and many typical users are actively being prevented
     * from easily minting (even though minting would technically be possible
     * directly from the contract).
     * This function is only callable by the core admin during an active
     * auction, before revenues have been collected.
     * The price at the time of the reset will be the maximum starting price
     * when re-configuring the next auction if one or more settleable purchases
     * have been made.
     * This is to ensure that purchases up through the block that this is
     * called on will remain settleable, and that revenue claimed does not
     * surpass (payments - excess_settlement_funds) for a given project.
     * @param _projectId Project ID to set auction details for.
     */
    function resetAuctionDetails(
        uint256 _projectId
    ) external onlyCoreAdminACL(this.resetAuctionDetails.selector) {
        // CHECKS
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        require(_projectConfig.startPrice != 0, "Auction must be configured");
        // no reset after revenues collected, since that solidifies amount due
        require(
            !_projectConfig.auctionRevenuesCollected,
            "Only before revenues collected"
        );
        // EFFECTS
        // reset to initial values
        _projectConfig.timestampStart = 0;
        _projectConfig.priceDecayHalfLifeSeconds = 0;
        _projectConfig.startPrice = 0;
        _projectConfig.basePrice = 0;
        // Since auction revenues have not been collected, we can safely assume
        // that numSettleableInvocations is the number of purchases made on
        // this minter. A dummy value of 0 is used for latest purchase price if
        // no purchases have been made.
        emit ResetAuctionDetails(
            _projectId,
            _projectConfig.numSettleableInvocations,
            _projectConfig.latestPurchasePrice
        );
    }

    /**
     * @notice This represents an admin stepping in and reducing the sellout
     * price of an auction. This is only callable by the core admin, only
     * after the auction is complete, but before project revenues are
     * withdrawn.
     * This is only intended to be used in the case where for some reason,
     * whether malicious or accidental, the sellout price was too high.
     * Examples of this include:
     *  - The artist reducing a project's maxInvocations on the core contract
     *    after an auction has started, but before it ends, eliminating the
     *    ability of purchasers to fairly determine market price under the
     *    original, expected auction parameters.
     *  - Any other reason the admin deems to be a valid reason to reduce the
     *    sellout price of an auction, prior to marking it as valid.
     * @param _projectId Project ID to reduce auction sellout price for.
     * @param _newSelloutPrice New sellout price to set for the auction. Must
     * be less than the current sellout price.
     */
    function adminEmergencyReduceSelloutPrice(
        uint256 _projectId,
        uint256 _newSelloutPrice
    )
        external
        onlyCoreAdminACL(this.adminEmergencyReduceSelloutPrice.selector)
    {
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        require(_projectConfig.maxHasBeenInvoked, "Auction must be complete");
        // @dev no need to check that auction max invocations has been reached,
        // because if it was, the sellout price will be zero, and the following
        // check will fail.
        require(
            _newSelloutPrice < _projectConfig.latestPurchasePrice,
            "May only reduce sellout price"
        );
        require(
            _newSelloutPrice >= _projectConfig.basePrice,
            "May only reduce sellout price to base price or greater"
        );
        // ensure latestPurchasePrice is non-zero if any purchases on minter
        // @dev only possible to fail this if auction is in a reset state
        require(_newSelloutPrice > 0, "Only sellout prices > 0");
        require(
            !_projectConfig.auctionRevenuesCollected,
            "Only before revenues collected"
        );
        _projectConfig.latestPurchasePrice = _newSelloutPrice;
        emit SelloutPriceUpdated(_projectId, _newSelloutPrice);
    }

    /**
     * @notice This withdraws project revenues for the artist and admin.
     * This function is only callable by the artist or admin, and only after
     * one of the following is true:
     * - the auction has sold out above base price
     * - the auction has reached base price
     * Note that revenues are not claimable if in a temporary state after
     * an auction is reset.
     * Revenues may only be collected a single time per project.
     * After revenues are collected, auction parameters will never be allowed
     * to be reset, and excess settlement funds will become immutable and fully
     * deterministic.
     */
    function withdrawArtistAndAdminRevenues(
        uint256 _projectId
    )
        external
        nonReentrant
        onlyCoreAdminACLOrArtist(
            _projectId,
            this.withdrawArtistAndAdminRevenues.selector
        )
    {
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        // CHECKS
        // require revenues to not have already been collected
        require(
            !_projectConfig.auctionRevenuesCollected,
            "Revenues already collected"
        );
        // get the current net price of the auction - reverts if no auction
        // is configured.
        // @dev _getPrice is guaranteed <= _projectConfig.latestPurchasePrice,
        // since this minter enforces monotonically decreasing purchase prices.
        uint256 _price = _getPrice(_projectId);
        // if the price is not base price, require that the auction have
        // reached max invocations. This prevents premature withdrawl
        // before final auction price is possible to know.
        if (_price != _projectConfig.basePrice) {
            // prefer to use locally cached value of maxHasBeenInvoked, which
            // is only updated when a purchase is made. This is to handle the
            // case where an artist reduced max invocations to current
            // invocations on the core contract mid-auction. In that case, the
            // the following _projectConfig.maxHasBeenInvoked check will fail
            // (only a local cache is used). This is a valid state, and in that
            // somewhat suspicious case, the artist must wait until the auction
            // reaches base price before withdrawing funds, at which point the
            // latestPurchasePrice will be set to base price, maximizing
            // purchaser excess settlement amounts, and minimizing artist/admin
            // revenue.
            require(
                _projectConfig.maxHasBeenInvoked,
                "Active auction not yet sold out"
            );
        } else {
            // update the latest purchase price to the base price, to ensure
            // the base price is used for all future settlement calculations
            _projectConfig.latestPurchasePrice = _projectConfig.basePrice;
        }
        // EFFECTS
        _projectConfig.auctionRevenuesCollected = true;
        // if the price is base price, the auction is valid and may be claimed
        // calculate the artist and admin revenues (no check requuired)
        uint256 netRevenues = _projectConfig.numSettleableInvocations * _price;
        // INTERACTIONS
        splitRevenuesETH(_projectId, netRevenues, genArt721CoreAddress);
        emit ArtistAndAdminRevenuesWithdrawn(_projectId);
    }

    /**
     * @notice Purchases a token from project `_projectId`.
     * @param _projectId Project ID to mint a token on.
     * @return tokenId Token ID of minted token
     */
    function purchase(
        uint256 _projectId
    ) external payable returns (uint256 tokenId) {
        tokenId = purchaseTo_do6(msg.sender, _projectId);
        return tokenId;
    }

    /**
     * @notice gas-optimized version of purchase(uint256).
     */
    function purchase_H4M(
        uint256 _projectId
    ) external payable returns (uint256 tokenId) {
        tokenId = purchaseTo_do6(msg.sender, _projectId);
        return tokenId;
    }

    /**
     * @notice Purchases a token from project `_projectId` and sets
     * the token's owner to `_to`.
     * @param _to Address to be the new token's owner.
     * @param _projectId Project ID to mint a token on.
     * @return tokenId Token ID of minted token
     */
    function purchaseTo(
        address _to,
        uint256 _projectId
    ) external payable returns (uint256 tokenId) {
        return purchaseTo_do6(_to, _projectId);
    }

    /**
     * @notice gas-optimized version of purchaseTo(address, uint256).
     */
    function purchaseTo_do6(
        address _to,
        uint256 _projectId
    ) public payable nonReentrant returns (uint256 tokenId) {
        // CHECKS
        ProjectConfig storage _projectConfig = projectConfig[_projectId];

        // Note that `maxHasBeenInvoked` is only checked here to reduce gas
        // consumption after a project has been fully minted.
        // `_projectConfig.maxHasBeenInvoked` is locally cached during every
        // purchase to reduce gas consumption and enable recording of sellout
        // price, but if not in sync with the core contract's value,
        // the core contract also enforces its own max invocation check during
        // minting.
        require(
            !_projectConfig.maxHasBeenInvoked,
            "Maximum number of invocations reached"
        );

        // _getPrice reverts if auction is unconfigured or has not started
        uint256 currentPriceInWei = _getPrice(_projectId);

        // EFFECTS
        // update the purchaser's receipt and require sufficient net payment
        Receipt storage receipt = receipts[msg.sender][_projectId];

        // in memory copy + update
        uint256 netPosted = receipt.netPosted + msg.value;
        uint256 numPurchased = receipt.numPurchased + 1;

        // require sufficient payment on project
        require(
            netPosted >= numPurchased * currentPriceInWei,
            "Must send minimum value to mint"
        );

        // update Receipt in storage
        // @dev overflow checks are not required since the added values cannot
        // be enough to overflow due to maximum invocations or supply of ETH
        receipt.netPosted = uint232(netPosted);
        receipt.numPurchased = uint24(numPurchased);

        // emit event indicating new receipt state
        emit ReceiptUpdated(msg.sender, _projectId, numPurchased, netPosted);

        // update latest purchase price (on this minter) in storage
        // @dev this is used to enforce monotonically decreasing purchase price
        // across multiple auctions
        _projectConfig.latestPurchasePrice = currentPriceInWei;

        tokenId = minterFilter.mint(_to, _projectId, msg.sender);

        // Note that this requires that the core contract's maxInvocations
        // be accurate to ensure that the minters maxHasBeenInvoked is
        // accurate, so we get the value from the core contract directly.
        uint256 maxInvocations;
        (, maxInvocations, , , , ) = genArtCoreContract_Base.projectStateData(
            _projectId
        );
        // okay if this underflows because if statement will always eval false.
        // this is only for gas optimization and recording sellout price in
        // an event (core enforces maxInvocations).
        unchecked {
            if (tokenId % ONE_MILLION == maxInvocations - 1) {
                _projectConfig.maxHasBeenInvoked = true;
                emit SelloutPriceUpdated(_projectId, currentPriceInWei);
            }
        }

        // INTERACTIONS
        if (_projectConfig.auctionRevenuesCollected) {
            // if revenues have been collected, split funds immediately.
            // @dev note that we are guaranteed to be at auction base price,
            // since we know we didn't sellout prior to this tx.
            // note that we don't refund msg.sender here, since a separate
            // settlement mechanism is provided on this minter, unrelated to
            // msg.value
            splitRevenuesETH(
                _projectId,
                currentPriceInWei,
                genArt721CoreAddress
            );
        } else {
            // increment the number of settleable invocations that will be
            // claimable by the artist and admin once auction is validated.
            // do not split revenue here since will be claimed at a later time.
            _projectConfig.numSettleableInvocations++;
        }

        return tokenId;
    }

    /**
     * @notice Reclaims the sender's payment above current settled price for
     * project `_projectId`. The current settled price is the the price paid
     * for the most recently purchased token, or the base price if the artist
     * has withdrawn revenues after the auction reached base price.
     * This function is callable at any point, but is expected to typically be
     * called after auction has sold out above base price or after the auction
     * has been purchased at base price. This minimizes the amount of gas
     * required to send all excess settlement funds to the sender.
     * Sends excess settlement funds to msg.sender.
     * @param _projectId Project ID to reclaim excess settlement funds on.
     */
    function reclaimProjectExcessSettlementFunds(uint256 _projectId) external {
        reclaimProjectExcessSettlementFundsTo(payable(msg.sender), _projectId);
    }

    /**
     * @notice Reclaims the sender's payment above current settled price for
     * project `_projectId`. The current settled price is the the price paid
     * for the most recently purchased token, or the base price if the artist
     * has withdrawn revenues after the auction reached base price.
     * This function is callable at any point, but is expected to typically be
     * called after auction has sold out above base price or after the auction
     * has been purchased at base price. This minimizes the amount of gas
     * required to send all excess settlement funds.
     * Sends excess settlement funds to address `_to`.
     * @param _to Address to send excess settlement funds to.
     * @param _projectId Project ID to reclaim excess settlement funds on.
     */
    function reclaimProjectExcessSettlementFundsTo(
        address payable _to,
        uint256 _projectId
    ) public nonReentrant {
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        Receipt storage receipt = receipts[msg.sender][_projectId];
        uint256 numPurchased = receipt.numPurchased;
        // CHECKS
        // input validation
        require(_to != address(0), "No claiming to the zero address");
        // require that a user has purchased at least one token on this project
        require(numPurchased > 0, "No purchases made by this address");
        // get the latestPurchasePrice, which returns the sellout price if the
        // auction sold out before reaching base price, or returns the base
        // price if auction has reached base price and artist has withdrawn
        // revenues.
        // @dev if user is eligible for a reclaiming, they have purchased a
        // token, therefore we are guaranteed to have a populated
        // latestPurchasePrice
        uint256 currentSettledTokenPrice = _projectConfig.latestPurchasePrice;

        // EFFECTS
        // calculate the excess settlement funds amount
        // implicit overflow/underflow checks in solidity ^0.8
        uint256 requiredAmountPosted = numPurchased * currentSettledTokenPrice;
        uint256 excessSettlementFunds = receipt.netPosted -
            requiredAmountPosted;
        // update Receipt in storage
        receipt.netPosted = requiredAmountPosted.toUint232();
        // emit event indicating new receipt state
        emit ReceiptUpdated(
            msg.sender,
            _projectId,
            numPurchased,
            requiredAmountPosted
        );

        // INTERACTIONS
        bool success_;
        (success_, ) = _to.call{value: excessSettlementFunds}("");
        require(success_, "Reclaiming failed");
    }

    /**
     * @notice Reclaims the sender's payment above current settled price for
     * projects in `_projectIds`. The current settled price is the the price
     * paid for the most recently purchased token, or the base price if the
     * artist has withdrawn revenues after the auction reached base price.
     * This function is callable at any point, but is expected to typically be
     * called after auction has sold out above base price or after the auction
     * has been purchased at base price. This minimizes the amount of gas
     * required to send all excess settlement funds to the sender.
     * Sends total of all excess settlement funds to msg.sender in a single
     * chunk. Entire transaction reverts if any excess settlement calculation
     * fails.
     * @param _projectIds Array of project IDs to reclaim excess settlement
     * funds on.
     */
    function reclaimProjectsExcessSettlementFunds(
        uint256[] calldata _projectIds
    ) external {
        reclaimProjectsExcessSettlementFundsTo(
            payable(msg.sender),
            _projectIds
        );
    }

    /**
     * @notice Reclaims the sender's payment above current settled price for
     * projects in `_projectIds`. The current settled price is the the price
     * paid for the most recently purchased token, or the base price if the
     * artist has withdrawn revenues after the auction reached base price.
     * This function is callable at any point, but is expected to typically be
     * called after auction has sold out above base price or after the auction
     * has been purchased at base price. This minimizes the amount of gas
     * required to send all excess settlement funds to the sender.
     * Sends total of all excess settlement funds to `_to` in a single
     * chunk. Entire transaction reverts if any excess settlement calculation
     * fails.
     * @param _to Address to send excess settlement funds to.
     * @param _projectIds Array of project IDs to reclaim excess settlement
     * funds on.
     */
    function reclaimProjectsExcessSettlementFundsTo(
        address payable _to,
        uint256[] memory _projectIds
    ) public nonReentrant {
        // CHECKS
        // input validation
        require(_to != address(0), "No claiming to the zero address");
        // EFFECTS
        // for each project, tally up the excess settlement funds and update
        // the receipt in storage
        uint256 excessSettlementFunds;
        uint256 projectIdsLength = _projectIds.length;
        for (uint256 i; i < projectIdsLength; ) {
            uint256 projectId = _projectIds[i];
            ProjectConfig storage _projectConfig = projectConfig[projectId];
            Receipt storage receipt = receipts[msg.sender][projectId];
            uint256 numPurchased = receipt.numPurchased;
            // input validation
            // require that a user has purchased at least one token on this project
            require(numPurchased > 0, "No purchases made by this address");
            // get the latestPurchasePrice, which returns the sellout price if the
            // auction sold out before reaching base price, or returns the base
            // price if auction has reached base price and artist has withdrawn
            // revenues.
            // @dev if user is eligible for a claim, they have purchased a token,
            // therefore we are guaranteed to have a populated
            // latestPurchasePrice
            uint256 currentSettledTokenPrice = _projectConfig
                .latestPurchasePrice;
            // calculate the excessSettlementFunds amount
            // implicit overflow/underflow checks in solidity ^0.8
            uint256 requiredAmountPosted = numPurchased *
                currentSettledTokenPrice;
            excessSettlementFunds += (receipt.netPosted - requiredAmountPosted);
            // reduce the netPosted (in storage) to value after excess settlement
            // funds deducted
            receipt.netPosted = requiredAmountPosted.toUint232();
            // emit event indicating new receipt state
            emit ReceiptUpdated(
                msg.sender,
                projectId,
                numPurchased,
                requiredAmountPosted
            );
            // gas efficiently increment i
            // won't overflow due to for loop, as well as gas limts
            unchecked {
                ++i;
            }
        }

        // INTERACTIONS
        // send excess settlement funds in a single chunk for all
        // projects
        bool success_;
        (success_, ) = _to.call{value: excessSettlementFunds}("");
        require(success_, "Reclaiming failed");
    }

    /**
     * @notice Gets price of minting a token on project `_projectId` given
     * the project's AuctionParameters and current block timestamp.
     * Reverts if auction has not yet started or auction is unconfigured.
     * Returns auction last purchase price if auction sold out before reaching
     * base price.
     * @param _projectId Project ID to get price of token for.
     * @return current price of token in Wei
     * @dev This method calculates price decay using a linear interpolation
     * of exponential decay based on the artist-provided half-life for price
     * decay, `_priceDecayHalfLifeSeconds`.
     */
    function _getPrice(uint256 _projectId) private view returns (uint256) {
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        // if auction sold out on this minter, return the latest purchase
        // price (which is the sellout price). This is the price that is due
        // after an auction is complete.
        if (_projectConfig.maxHasBeenInvoked) {
            return _projectConfig.latestPurchasePrice;
        }
        // otherwise calculate price based on current block timestamp and
        // auction configuration (will revert if auction has not started)
        // move parameters to memory if used more than once
        uint256 _timestampStart = uint256(_projectConfig.timestampStart);
        uint256 _priceDecayHalfLifeSeconds = uint256(
            _projectConfig.priceDecayHalfLifeSeconds
        );
        uint256 _basePrice = _projectConfig.basePrice;

        require(block.timestamp > _timestampStart, "Auction not yet started");
        require(_priceDecayHalfLifeSeconds > 0, "Only configured auctions");
        uint256 decayedPrice = _projectConfig.startPrice;
        uint256 elapsedTimeSeconds;
        unchecked {
            // already checked that block.timestamp > _timestampStart above
            elapsedTimeSeconds = block.timestamp - _timestampStart;
        }
        // Divide by two (via bit-shifting) for the number of entirely completed
        // half-lives that have elapsed since auction start time.
        unchecked {
            // already required _priceDecayHalfLifeSeconds > 0
            decayedPrice >>= elapsedTimeSeconds / _priceDecayHalfLifeSeconds;
        }
        // Perform a linear interpolation between partial half-life points, to
        // approximate the current place on a perfect exponential decay curve.
        unchecked {
            // value of expression is provably always less than decayedPrice,
            // so no underflow is possible when the subtraction assignment
            // operator is used on decayedPrice.
            decayedPrice -=
                (decayedPrice *
                    (elapsedTimeSeconds % _priceDecayHalfLifeSeconds)) /
                _priceDecayHalfLifeSeconds /
                2;
        }
        if (decayedPrice < _basePrice) {
            // Price may not decay below stay `basePrice`.
            return _basePrice;
        }
        return decayedPrice;
    }

    /**
     * @notice Gets the current excess settlement funds on project `_projectId`
     * for address `_walletAddress`. The returned value is expected to change
     * throughtout an auction, since the latest purchase price is used when
     * determining excess settlement funds.
     * A user may claim excess settlement funds by calling the function
     * `reclaimProjectExcessSettlementFunds(_projectId)`.
     * @param _projectId Project ID to query.
     * @param _walletAddress Account address for which the excess posted funds
     * is being queried.
     * @return excessSettlementFundsInWei Amount of excess settlement funds, in
     * wei
     */
    function getProjectExcessSettlementFunds(
        uint256 _projectId,
        address _walletAddress
    ) external view returns (uint256 excessSettlementFundsInWei) {
        // input validation
        require(_walletAddress != address(0), "No zero address");
        // load struct from storage
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        Receipt storage receipt = receipts[_walletAddress][_projectId];
        // require that a user has purchased at least one token on this project
        require(receipt.numPurchased > 0, "No purchases made by this address");
        // get the latestPurchasePrice, which returns the sellout price if the
        // auction sold out before reaching base price, or returns the base
        // price if auction has reached base price and artist has withdrawn
        // revenues.
        // @dev if user is eligible for a reclaiming, they have purchased a
        // token, therefore we are guaranteed to have a populated
        // latestPurchasePrice
        uint256 currentSettledTokenPrice = _projectConfig.latestPurchasePrice;

        // EFFECTS
        // calculate the excess settlement funds amount and return
        // implicit overflow/underflow checks in solidity ^0.8
        uint256 requiredAmountPosted = receipt.numPurchased *
            currentSettledTokenPrice;
        excessSettlementFundsInWei = receipt.netPosted - requiredAmountPosted;
        return excessSettlementFundsInWei;
    }

    /**
     * @notice Gets the latest purchase price for project `_projectId`, or 0 if
     * no purchases have been made.
     */
    function getProjectLatestPurchasePrice(
        uint256 _projectId
    ) external view returns (uint256 latestPurchasePrice) {
        return projectConfig[_projectId].latestPurchasePrice;
    }

    /**
     * @notice Gets the number of settleable invocations for project `_projectId`.
     */
    function getNumSettleableInvocations(
        uint256 _projectId
    ) external view returns (uint256 numSettleableInvocations) {
        return projectConfig[_projectId].numSettleableInvocations;
    }

    /**
     * @notice Gets if price of token is configured, price of minting a
     * token on project `_projectId`, and currency symbol and address to be
     * used as payment. Supersedes any core contract price information.
     * @param _projectId Project ID to get price information for.
     * @return isConfigured true only if project's auction parameters have been
     * configured on this minter
     * @return tokenPriceInWei current price of token on this minter - invalid
     * if auction has not yet been configured
     * @return currencySymbol currency symbol for purchases of project on this
     * minter. This minter always returns "ETH"
     * @return currencyAddress currency address for purchases of project on
     * this minter. This minter always returns null address, reserved for ether
     */
    function getPriceInfo(
        uint256 _projectId
    )
        external
        view
        returns (
            bool isConfigured,
            uint256 tokenPriceInWei,
            string memory currencySymbol,
            address currencyAddress
        )
    {
        ProjectConfig storage _projectConfig = projectConfig[_projectId];

        isConfigured = (_projectConfig.startPrice > 0);
        if (block.timestamp <= _projectConfig.timestampStart) {
            // Provide a reasonable value for `tokenPriceInWei` when it would
            // otherwise revert, using the starting price before auction starts.
            tokenPriceInWei = _projectConfig.startPrice;
        } else if (_projectConfig.startPrice == 0) {
            // In the case of unconfigured auction, return price of zero when
            // it would otherwise revert
            tokenPriceInWei = 0;
        } else {
            tokenPriceInWei = _getPrice(_projectId);
        }
        currencySymbol = "ETH";
        currencyAddress = address(0);
    }
}