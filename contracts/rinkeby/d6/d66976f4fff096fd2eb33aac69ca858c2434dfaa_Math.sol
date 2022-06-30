// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

library Math {
    function average(uint256[] memory _prices) external pure returns (uint256) {
        uint256 _accumulator = 0;
        for (uint256 i = 0; i < _prices.length; i++) {
            _accumulator += _prices[i];
        }
        return _accumulator / _prices.length;
    }
}