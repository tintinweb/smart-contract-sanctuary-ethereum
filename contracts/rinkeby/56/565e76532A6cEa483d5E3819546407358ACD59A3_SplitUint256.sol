// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Split Uint256 based percentage
/// @notice Split uint256 based on param as percentage of 1st part
/// And 1st is rounded to floor, e.g.
/// Split 1 with 0 (, 100) -> 0, 1
/// Split 1 with 1 (, 99) -> 0, 1
/// Split 1 with 49 (, 51) -> 0, 1
/// Split 1 with 50 (, 50) -> 0, 1
/// Split 1 with 51 (, 49) -> 0, 1
/// Split 1 with 99 (, 1) -> 0, 1
/// Split 1 with 100 (, 0) -> 1, 0

/// Split 2 with 0 (, 100) -> 0, 2
/// Split 2 with 1 (, 99) -> 0, 2
/// Split 2 with 49 (, 51) -> 0, 2
/// Split 2 with 50 (, 50) -> 1, 1
/// Split 2 with 51 (, 49) -> 1, 1
/// Split 2 with 99 (, 1) -> 1, 1
/// Split 2 with 100 (, 0) -> 2, 0

/// Split 3 with 0 (, 100) -> 0, 3
/// Split 3 with 1 (, 99) -> 0, 3
/// Split 3 with 33 (, 67) -> 0, 3
/// Split 3 with 34 (, 66) -> 1, 2
/// Split 3 with 49 (, 51) -> 1, 2
/// Split 3 with 50 (, 50) -> 1, 2
/// Split 3 with 51 (, 49) -> 1, 2
/// Split 3 with 66 (, 49) -> 1, 2
/// Split 3 with 67 (, 49) -> 2, 1
/// Split 3 with 99 (, 1) -> 2, 1
/// Split 3 with 100 (, 0) -> 3, 0
library SplitUint256 {
    /// @param numberToSplit Numbers to split, [0, ]
    /// @param percentOf1stPart percent value for 1st part, [0, 100], 2nd part would be `100 - percentOf1stPart`
    function splitByPercent(uint256 numberToSplit, uint8 percentOf1stPart)
        public
        pure
        returns (uint256, uint256)
    {
        uint256 moneyToProposer = (numberToSplit * uint8(percentOf1stPart)) /
            100;
        uint256 moneyToResponder = numberToSplit - moneyToProposer;
        return (moneyToProposer, moneyToResponder);
    }
}