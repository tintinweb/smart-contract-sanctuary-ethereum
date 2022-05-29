/**
Copyright 2020 Compound Labs, Inc.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
© 2022 GitHub, Inc.
 */

//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./lib/IntMath.sol";

contract JumpInterestRateModel is Ownable {
    /*///////////////////////////////////////////////////////////////
                                EVENT 
    //////////////////////////////////////////////////////////////*/

    event NewJumpRateModelVars(
        uint256 indexed baseRatePerBlock,
        uint256 indexed multiplierPerBlock,
        uint256 jumpMultiplierPerBlock,
        uint256 indexed _kink
    );

    /*///////////////////////////////////////////////////////////////
                              LIBRARIES 
    //////////////////////////////////////////////////////////////*/

    using IntMath for uint256;

    /*///////////////////////////////////////////////////////////////
                              STATE
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev The Interest rate charged every block regardless of utilization rate
     */
    //solhint-disable-next-line var-name-mixedcase
    uint256 public immutable BLOCKS_PER_YEAR;

    /**
     * @dev The Interest rate charged every block regardless of utilization rate
     */
    uint256 public baseRatePerBlock;

    /**
     * @dev The Interest rate added as a percentage of the utilization rate.
     */
    uint256 public multiplierPerBlock;

    /**
     * @dev The multiplierPerBlock after hitting a specified utilization point
     */
    uint256 public jumpMultiplierPerBlock;

    /**
     * @dev The utilization point at which the jump multiplier is applied
     */
    uint256 public kink;

    /**
     *
     */
    constructor(
        uint256 baseRatePerYear,
        uint256 multiplierPerYear,
        uint256 jumpMultiplierPerYear,
        uint256 _kink,
        uint256 blocksPerYear
    ) {
        _updateJumpRateModel(
            baseRatePerYear,
            multiplierPerYear,
            jumpMultiplierPerYear,
            _kink,
            blocksPerYear
        );

        BLOCKS_PER_YEAR = blocksPerYear;
    }

    /*///////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Calculates the borrow rate for a lending market
     *
     * @param cash The avaliable liquidity to be borrowed
     * @param totalBorrowAmount The total amount being borrowed
     * @param reserves Amount of cash that belongs to the reserves.
     */
    function getBorrowRatePerBlock(
        uint256 cash,
        uint256 totalBorrowAmount,
        uint256 reserves
    ) external view returns (uint256) {
        return _getBorrowRatePerBlock(cash, totalBorrowAmount, reserves);
    }

    /**
     * @dev Calculates the supply rate for a lending market using the borrow and utilization rate.
     *
     * @param cash The avaliable liquidity to be borrowed
     * @param totalBorrowAmount The total amount being borrowed
     * @param reserves Amount of cash that belongs to the reserves.
     * @param reserveFactor The % of the interest rate that is to be used for reserves.
     */
    function getSupplyRatePerBlock(
        uint256 cash,
        uint256 totalBorrowAmount,
        uint256 reserves,
        uint256 reserveFactor
    ) external view returns (uint256) {
        uint256 investorsFactor = 1 ether - reserveFactor;
        uint256 borrowRate = _getBorrowRatePerBlock(
            cash,
            totalBorrowAmount,
            reserves
        );
        uint256 borrowRateToInvestors = borrowRate.bmul(investorsFactor);
        return
            _getUtilizationRate(cash, totalBorrowAmount, reserves).bmul(
                borrowRateToInvestors
            );
    }

    /*///////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Internal function to calculate the borrow rate for a lending market
     *
     * @param cash The avaliable liquidity to be borrowed
     * @param totalBorrowAmount The total amount being borrowed
     * @param reserves Amount of cash that belongs to the reserves.
     */
    function _getBorrowRatePerBlock(
        uint256 cash,
        uint256 totalBorrowAmount,
        uint256 reserves
    ) private view returns (uint256) {
        // Get utilization rate
        uint256 utilRate = _getUtilizationRate(
            cash,
            totalBorrowAmount,
            reserves
        );

        // Save Gas
        uint256 _kink = kink;

        // If we are below the kink threshold
        if (_kink >= utilRate)
            return utilRate.bmul(multiplierPerBlock) + baseRatePerBlock;

        // Anything equal and below the kink is charged the normal rate
        uint256 normalRate = _kink.bmul(multiplierPerBlock) + baseRatePerBlock;
        // % of the utility rate that is above the threshold
        uint256 excessUtil = utilRate - _kink;
        return excessUtil.bmul(jumpMultiplierPerBlock) + normalRate;
    }

    /**
     * @dev Calculates how much supply minus reserved is being borrowed.
     *
     * @param cash The avaliable liquidity to be borrowed
     * @param totalBorrowAmount The total amount being borrowed
     * @param reserves Amount of cash that belongs to the reserves.
     */
    function _getUtilizationRate(
        uint256 cash,
        uint256 totalBorrowAmount,
        uint256 reserves
    ) private pure returns (uint256) {
        if (totalBorrowAmount == 0) return 0;

        return totalBorrowAmount.bdiv((cash + totalBorrowAmount) - reserves);
    }

    function _updateJumpRateModel(
        uint256 baseRatePerYear,
        uint256 multiplierPerYear,
        uint256 jumpMultiplierPerYear,
        uint256 _kink,
        uint256 blocksPerYear
    ) private {
        baseRatePerBlock = baseRatePerYear / blocksPerYear;

        multiplierPerBlock = multiplierPerYear.bdiv((blocksPerYear * _kink));

        jumpMultiplierPerBlock = jumpMultiplierPerYear / blocksPerYear;

        kink = _kink;
    }

    /*///////////////////////////////////////////////////////////////
                              ONLY OWNER
    //////////////////////////////////////////////////////////////*/

    function updateJumpRateModel(
        uint256 baseRatePerYear,
        uint256 multiplierPerYear,
        uint256 jumpMultiplierPerYear,
        uint256 _kink
    ) external onlyOwner {
        _updateJumpRateModel(
            baseRatePerYear,
            multiplierPerYear,
            jumpMultiplierPerYear,
            _kink,
            BLOCKS_PER_YEAR
        );

        emit NewJumpRateModelVars(
            baseRatePerBlock,
            multiplierPerBlock,
            jumpMultiplierPerBlock,
            kink
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: CC-BY-4.0
pragma solidity 0.8.13;

/**
 * @dev We assume that all numbers passed to {bmul} and {bdiv} have a mantissa of 1e18
 *
 * @notice We copied from https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/FullMath.sol
 * @notice We modified line 67 per this post https://ethereum.stackexchange.com/questions/96642/unary-operator-cannot-be-applied-to-type-uint256
 */
// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library IntMath {
    // Base Mantissa of all numbers in Interest Protocol
    uint256 private constant BASE = 1e18;

    /**
     * @dev Adjusts the price to have 18 decimal houses to work easier with most {ERC20}.
     *
     * @param price The price of the token
     * @param decimals The current decimals the price has
     * @return uint256 the new price supporting 18 decimal houses
     */
    function toBase(uint256 price, uint8 decimals)
        internal
        pure
        returns (uint256)
    {
        uint256 baseDecimals = 18;

        if (decimals == baseDecimals) return price;

        if (decimals < baseDecimals)
            return price * 10**(baseDecimals - decimals);

        return price / 10**(decimals - baseDecimals);
    }

    /**
     * @dev Adjusts the price to have `decimal` houses to work easier with most {ERC20}.
     *
     * @param price The price of the token
     * @param decimals The current decimals the price has
     * @return uint256 the new price supporting `decimals` decimal houses
     */
    function fromBase(uint256 price, uint8 decimals)
        internal
        pure
        returns (uint256)
    {
        uint256 baseDecimals = 18;

        if (decimals == baseDecimals) return price;

        if (decimals < baseDecimals)
            return price / 10**(baseDecimals - decimals);

        return price * 10**(decimals - baseDecimals);
    }

    /**
     * @dev Function ensures that the return value keeps the right mantissa
     */
    function bmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDiv(x, y, BASE);
    }

    /**
     * @dev Function ensures that the return value keeps the right mantissa
     */
    function bdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDiv(x, BASE, y);
    }

    /**
     * @dev Returns the smallest of two numbers.
     * Taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    //solhint-disable
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = denominator & (~denominator + 1);
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /**
     * @notice This was copied from Uniswap without any modifications.
     * https://github.com/Uniswap/v2-core/blob/master/contracts/libraries/Math.sol
     * babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
     */
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}