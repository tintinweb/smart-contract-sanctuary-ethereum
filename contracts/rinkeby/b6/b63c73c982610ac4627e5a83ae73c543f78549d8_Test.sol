/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.11;

/**
 * @notice Fraction
 * @member numerator
 * @member denominator
 */
struct Fraction {
    uint256 n;
    uint256 d;
}

contract Test {
    /**
     * @param f Fraction
     * @return Fraction
     */
    function foo(Fraction calldata f) external pure returns (Fraction memory) {
        return Fraction({n: f.n + 1, d: f.d + 1});
    }

    /**
     * @param f Fraction
     * @return Fraction
     */
    function bar(Fraction calldata f) external returns (Fraction memory) {
        return Fraction({n: f.n + 1, d: f.d + 1});
    }
}