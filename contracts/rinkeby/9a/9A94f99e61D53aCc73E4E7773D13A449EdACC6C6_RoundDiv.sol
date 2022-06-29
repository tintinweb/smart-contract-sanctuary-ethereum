// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

library RoundDiv {
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
    function roundDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // require(b != 0, "Denominator can not be 0!"); // not needed anlonger from solidity version 0.8.x onwards
        return (a + b / 2) / b;
    }
}