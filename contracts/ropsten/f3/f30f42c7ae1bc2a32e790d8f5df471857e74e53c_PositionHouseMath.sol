// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library PositionHouseMath {
    function entryPriceFromNotional(
        uint256 _notional,
        uint256 _quantity,
        uint256 _baseBasicPoint
    ) public pure returns (uint256) {
        return (_notional * _baseBasicPoint) / _quantity;
    }
}