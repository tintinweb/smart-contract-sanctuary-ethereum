// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

/// @dev Market object as represented in memory
struct MarketParameters {
    bytes32 storageSlot;
    uint256 maturity;
    // Total amount of fCash available for purchase in the market.
    int256 totalfCash;
    // Total amount of cash available for purchase in the market.
    int256 totalAssetCash;
    // Total amount of liquidity tokens (representing a claim on liquidity) in the market.
    int256 totalLiquidity;
    // This is the previous annualized interest rate in RATE_PRECISION that the market traded
    // at. This is used to calculate the rate anchor to smooth interest rates over time.
    uint256 lastImpliedRate;
    // Time lagged version of lastImpliedRate, used to value fCash assets at market rates while
    // remaining resistent to flash loan attacks.
    uint256 oracleRate;
    // This is the timestamp of the previous trade
    uint256 previousTradeTime;
}


interface INotionalV2 {
   function getfCashLendFromDeposit(
        uint16 currencyId,
        uint256 depositAmountExternal,
        uint256 maturity,
        uint32 minLendRate,
        uint256 blockTime,
        bool useUnderlying
    ) external view returns (
        uint88 fCashAmount,
        uint8 marketIndex,
        bytes32 encodedTrade
    );

    function getfCashBorrowFromPrincipal(
        uint16 currencyId,
        uint256 borrowedAmountExternal,
        uint256 maturity,
        uint32 maxBorrowRate,
        uint256 blockTime,
        bool useUnderlying
    ) external view returns (
        uint88 fCashDebt,
        uint8 marketIndex,
        bytes32 encodedTrade
    );

}

interface INotionalV2Complete is INotionalV2 {
    function getCurrencyId(address tokenAddress) external view returns (uint16 currencyId);

    function getActiveMarkets(uint16 currencyId) external view returns (MarketParameters[] memory);

    function updateAssetRate(uint16 currencyId, address rateOracle) external;
    
    function upgradeTo(address newAddress) external;

    function owner() external view returns(address);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { INotionalV2 } from "../interfaces/external/INotionalV2.sol";


contract NotionalV2Mock is INotionalV2 {
    uint88 fCashEstimation;

    function setFCashEstimation(uint88 _fCashEstimation) public {
        fCashEstimation = _fCashEstimation;
    }

   function getfCashLendFromDeposit(
        uint16 currencyId,
        uint256 depositAmountExternal,
        uint256 maturity,
        uint32 minLendRate,
        uint256 blockTime,
        bool useUnderlying
    ) external view override returns (
        uint88 fCashAmount,
        uint8 marketIndex,
        bytes32 encodedTrade
    ) {
        fCashAmount = fCashEstimation;
    }

    function getfCashBorrowFromPrincipal(
        uint16 currencyId,
        uint256 borrowedAmountExternal,
        uint256 maturity,
        uint32 maxBorrowRate,
        uint256 blockTime,
        bool useUnderlying
    ) external view override returns (
        uint88 fCashDebt,
        uint8 marketIndex,
        bytes32 encodedTrade
    ) {
        fCashDebt = fCashEstimation;
    }
}