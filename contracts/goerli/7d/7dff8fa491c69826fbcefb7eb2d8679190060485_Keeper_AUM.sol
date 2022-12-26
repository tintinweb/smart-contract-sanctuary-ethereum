// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PercentageMath} from "./PercentageMath.sol";

contract Keeper_AUM {
    /// -----------------------------
    ///         Storage
    /// -----------------------------

    ///@notice Threshold of deviation for updating AUM
    uint256 deviationThreshold = 50; // 0.5 %

    uint256 aum;
    uint256 nAum;

    event UpdateAUM(uint256 aum);

    /// -----------------------------
    ///         Admin ext
    /// -----------------------------

    ///@notice Change the deviation threshold
    ///@dev 50 = 0.5 % of deviation
    function updateDeviationThreshold(uint256 threshold) external {
        deviationThreshold = threshold;
    }

    function update_nAUM(uint256 _nAum) external {
        nAum = _nAum;
    }

    function store_aum(uint256 _nAum) internal {
        aum = _nAum;
    }

    /// -----------------------------
    ///         Keeper
    /// -----------------------------

    function updateProtocolAUM(uint256 num) external {
        if (aum == 0 && num != 0) {
            store_aum(num);
            emit UpdateAUM(num);
        }
        // Update if 0.5 % diff between on-chain and offchain
        if (!_isInRange(aum, num)) {
            store_aum(num);
            emit UpdateAUM(num);
        }
    }

    function checker() external view returns (bool, bytes memory) {
        if (aum == 0 && nAum != 0) {
            return (true, abi.encodeWithSelector(this.updateProtocolAUM.selector, nAum));
        }
        // Update if 0.5 % diff between on-chain and offchain
        if (_isInRange(aum, nAum)) {
            return (false, bytes("AUM is in range"));
        } else {
            return (true, abi.encodeWithSelector(this.updateProtocolAUM.selector, nAum));
        }

        // do we need a checker if we do not encode ? abi.EncodeWithSelector ?
        // write test // make a fake to deploy and test it
    }

    /// -----------------------------
    ///          Internal
    /// -----------------------------
    function _isInRange(uint256 _aum, uint256 _nAum) internal view returns (bool) {
        uint256 lowerBound = PercentageMath.percentSub(_aum, deviationThreshold);
        uint256 upperBound = PercentageMath.percentAdd(_aum, deviationThreshold);
        if (_nAum < lowerBound || _nAum > upperBound) {
            return false;
        } else {
            return true;
        }
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

/// @title PercentageMath.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Optimized version of Aave V3 math library PercentageMath to conduct percentage manipulations: https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/libraries/math/PercentageMath.sol
library PercentageMath {
    ///	CONSTANTS ///

    uint256 internal constant PERCENTAGE_FACTOR = 1e4; // 100.00%
    uint256 internal constant HALF_PERCENTAGE_FACTOR = 0.5e4; // 50.00%
    uint256 internal constant MAX_UINT256 = 2 ** 256 - 1;
    uint256 internal constant MAX_UINT256_MINUS_HALF_PERCENTAGE = 2 ** 256 - 1 - 0.5e4;

    /// INTERNAL ///

    /// @notice Executes a percentage addition (x * (1 + p)), rounded up.
    /// @param x The value to which to add the percentage.
    /// @param percentage The percentage of the value to add.
    /// @return y The result of the addition.
    function percentAdd(uint256 x, uint256 percentage) internal pure returns (uint256 y) {
        // Must revert if
        // PERCENTAGE_FACTOR + percentage > type(uint256).max
        //     or x * (PERCENTAGE_FACTOR + percentage) + HALF_PERCENTAGE_FACTOR > type(uint256).max
        // <=> percentage > type(uint256).max - PERCENTAGE_FACTOR
        //     or x > (type(uint256).max - HALF_PERCENTAGE_FACTOR) / (PERCENTAGE_FACTOR + percentage)
        // Note: PERCENTAGE_FACTOR + percentage >= PERCENTAGE_FACTOR > 0
        assembly {
            y := add(PERCENTAGE_FACTOR, percentage) // Temporary assignment to save gas.

            if or(gt(percentage, sub(MAX_UINT256, PERCENTAGE_FACTOR)), gt(x, div(MAX_UINT256_MINUS_HALF_PERCENTAGE, y)))
            {
                revert(0, 0)
            }

            y := div(add(mul(x, y), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
        }
    }

    /// @notice Executes a percentage subtraction (x * (1 - p)), rounded up.
    /// @param x The value to which to subtract the percentage.
    /// @param percentage The percentage of the value to subtract.
    /// @return y The result of the subtraction.
    function percentSub(uint256 x, uint256 percentage) internal pure returns (uint256 y) {
        // Must revert if
        // percentage > PERCENTAGE_FACTOR
        //     or x * (PERCENTAGE_FACTOR - percentage) + HALF_PERCENTAGE_FACTOR > type(uint256).max
        // <=> percentage > PERCENTAGE_FACTOR
        //     or ((PERCENTAGE_FACTOR - percentage) > 0 and x > (type(uint256).max - HALF_PERCENTAGE_FACTOR) / (PERCENTAGE_FACTOR - percentage))
        assembly {
            y := sub(PERCENTAGE_FACTOR, percentage) // Temporary assignment to save gas.

            if or(gt(percentage, PERCENTAGE_FACTOR), mul(y, gt(x, div(MAX_UINT256_MINUS_HALF_PERCENTAGE, y)))) {
                revert(0, 0)
            }

            y := div(add(mul(x, y), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
        }
    }

    /// @notice Executes a percentage multiplication (x * p), rounded up.
    /// @param x The value to multiply by the percentage.
    /// @param percentage The percentage of the value to multiply.
    /// @return y The result of the multiplication.
    function percentMul(uint256 x, uint256 percentage) internal pure returns (uint256 y) {
        // Must revert if
        // x * percentage + HALF_PERCENTAGE_FACTOR > type(uint256).max
        // <=> percentage > 0 and x > (type(uint256).max - HALF_PERCENTAGE_FACTOR) / percentage
        assembly {
            if mul(percentage, gt(x, div(MAX_UINT256_MINUS_HALF_PERCENTAGE, percentage))) { revert(0, 0) }

            y := div(add(mul(x, percentage), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
        }
    }

    /// @notice Executes a percentage division (x / p), rounded up.
    /// @param x The value to divide by the percentage.
    /// @param percentage The percentage of the value to divide.
    /// @return y The result of the division.
    function percentDiv(uint256 x, uint256 percentage) internal pure returns (uint256 y) {
        // Must revert if
        // percentage == 0
        //     or x * PERCENTAGE_FACTOR + percentage / 2 > type(uint256).max
        // <=> percentage == 0
        //     or x > (type(uint256).max - percentage / 2) / PERCENTAGE_FACTOR
        assembly {
            y := div(percentage, 2) // Temporary assignment to save gas.

            if iszero(mul(percentage, iszero(gt(x, div(sub(MAX_UINT256, y), PERCENTAGE_FACTOR))))) { revert(0, 0) }

            y := div(add(mul(PERCENTAGE_FACTOR, x), y), percentage)
        }
    }

    /// @notice Executes a weighted average (x * (1 - p) + y * p), rounded up.
    /// @param x The first value, with a weight of 1 - percentage.
    /// @param y The second value, with a weight of percentage.
    /// @param percentage The weight of y, and complement of the weight of x.
    /// @return z The result of the weighted average.
    function weightedAvg(uint256 x, uint256 y, uint256 percentage) internal pure returns (uint256 z) {
        // Must revert if
        //     percentage > PERCENTAGE_FACTOR
        // or if
        //     y * percentage + HALF_PERCENTAGE_FACTOR > type(uint256).max
        //     <=> percentage > 0 and y > (type(uint256).max - HALF_PERCENTAGE_FACTOR) / percentage
        // or if
        //     x * (PERCENTAGE_FACTOR - percentage) + y * percentage + HALF_PERCENTAGE_FACTOR > type(uint256).max
        //     <=> (PERCENTAGE_FACTOR - percentage) > 0 and x > (type(uint256).max - HALF_PERCENTAGE_FACTOR - y * percentage) / (PERCENTAGE_FACTOR - percentage)
        assembly {
            z := sub(PERCENTAGE_FACTOR, percentage) // Temporary assignment to save gas.
            if or(
                gt(percentage, PERCENTAGE_FACTOR),
                or(
                    mul(percentage, gt(y, div(MAX_UINT256_MINUS_HALF_PERCENTAGE, percentage))),
                    mul(z, gt(x, div(sub(MAX_UINT256_MINUS_HALF_PERCENTAGE, mul(y, percentage)), z)))
                )
            ) { revert(0, 0) }
            z := div(add(add(mul(x, z), mul(y, percentage)), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
        }
    }
}