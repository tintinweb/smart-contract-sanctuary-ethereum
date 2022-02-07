/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// this will be deployed with remix
pragma solidity >=0.8.0 <0.9.0;

// not using openzeppelin's safemath because since v0.8, the solidity compiler
// already checks for overflow in operations

/**
 * @title BasicMath
 * @dev Supplies endpoints for basic arithmetic operations
 */
contract BasicMath {
    /**
     * @dev adds two numbers
     * @param x the augend
     * @param y the addend
     */
    function Add(int256 x, int256 y) public pure returns (int256) {
        return x + y;
    }

    /**
     * @dev subtracts two numbers
     * @param x the minuend
     * @param y the subtrahend
     */
    function Sub(int256 x, int256 y) public pure returns (int256) {
        return x - y;
    }

    /**
     * @dev multiplies two numbers
     * @param x the multiplicand
     * @param y the multiplier
     */
    function Mul(int256 x, int256 y) public pure returns (int256) {
        return x * y;
    }

    /**
     * @dev divides two numbers, result is rounded down
     * @param x the dividend
     * @param y the divisor
     */
    function Div(int256 x, int256 y) public pure returns (int256) {
        // todo: check how this behaves regarding the integer
        return x / y;
    }
}