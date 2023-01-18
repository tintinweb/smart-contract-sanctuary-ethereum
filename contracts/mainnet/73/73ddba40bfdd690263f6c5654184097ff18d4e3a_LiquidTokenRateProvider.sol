/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRateProvider {
    function getRate() external view returns (uint256);
}

interface ILiquidToken {
    function ratio() external view returns (uint256);
}

contract LiquidTokenRateProvider is IRateProvider {
    ILiquidToken public immutable liquidToken;

    constructor(ILiquidToken _liquidToken) {
        liquidToken = _liquidToken;
    }

    /**
     * @return the value of RateProvider's liquidToken in terms of its underlying
     */
    function getRate() external view override returns (uint256) {
        return liquidToken.ratio();
    }
}