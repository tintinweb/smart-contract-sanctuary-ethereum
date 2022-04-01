// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.9;

library ArrayMath {
    function getArraySum(uint16[] memory _array)
        external
        pure
        returns (uint16 sum_)
    {
        sum_ = 0;
        for (uint256 i = 0; i < _array.length; i++) {
            sum_ += _array[i];
        }
    }
}