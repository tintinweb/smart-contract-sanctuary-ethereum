// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Enjinstarter
pragma solidity ^0.8.15;

/**
 * @title UnitConverter
 * @author Tim Loh
 */
library UnitConverter {
    uint256 public constant TOKEN_MAX_DECIMALS = 18;

    // https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
    // slither-disable-next-line dead-code
    function scaleWeiToDecimals(uint256 weiAmount, uint256 decimals)
        external
        pure
        returns (uint256 decimalsAmount)
    {
        require(decimals <= TOKEN_MAX_DECIMALS, "UnitConverter: decimals");

        if (decimals < TOKEN_MAX_DECIMALS && weiAmount > 0) {
            uint256 decimalsDiff = TOKEN_MAX_DECIMALS - decimals;
            decimalsAmount = weiAmount / 10**decimalsDiff;
        } else {
            decimalsAmount = weiAmount;
        }
    }

    // https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
    // slither-disable-next-line dead-code
    function scaleDecimalsToWei(uint256 decimalsAmount, uint256 decimals)
        external
        pure
        returns (uint256 weiAmount)
    {
        require(decimals <= TOKEN_MAX_DECIMALS, "UnitConverter: decimals");

        if (decimals < TOKEN_MAX_DECIMALS && decimalsAmount > 0) {
            uint256 decimalsDiff = TOKEN_MAX_DECIMALS - decimals;
            weiAmount = decimalsAmount * 10**decimalsDiff;
        } else {
            weiAmount = decimalsAmount;
        }
    }
}