// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @dev SignedMathHelpers contract is recommended to use only in Shortcuts passed to EnsoWallet
 *
 * Based on OpenZepplin Contracts 4.7.3:
 * - utils/math/SignedMath.sol (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SignedMath.sol)
 * - utils/math/SignedSafeMath.sol (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SignedSafeMath.sol)
 */
contract SignedMathHelpers {
    uint256 public constant VERSION = 1;

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
    function add(int256 a, int256 b) external pure returns (int256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * underflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) external pure returns (int256) {
        return a - b;
    }

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
    function mul(int256 a, int256 b) external pure returns (int256) {
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
    function div(int256 a, int256 b) external pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) external pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) external pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) external pure returns (int256) {
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) external pure returns (uint256) {
        unchecked {
            return uint256(n >= 0 ? n : -n);
        }
    }

    /**
     * @dev Returns the results a math operation if a condition is met. Otherwise returns the 'a' value without any modification.
     */
    function conditional(bool condition, bytes4 method, int256 a, int256 b) external view returns (int256) {
        if (condition) {
            (bool success, bytes memory n) = address(this).staticcall(abi.encodeWithSelector(method, a, b));
            if (success) return abi.decode(n, (int256));
        }
        return a;
    }
}