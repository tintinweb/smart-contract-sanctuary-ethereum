// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "./actions/nTokenMintAction.sol";
import "../internal/balances/TokenHandler.sol";
import "../global/StorageLayoutV1.sol";
import "../internal/markets/CashGroup.sol";
import "../internal/markets/AssetRate.sol";
import "../internal/nToken/nTokenSupply.sol";
import "../internal/nToken/nTokenHandler.sol";
import "../math/SafeInt256.sol";
import "../../interfaces/notional/NotionalCalculations.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract CalculationViews is StorageLayoutV1, NotionalCalculations {
    using TokenHandler for Token;
    using Market for MarketParameters;
    using AssetRate for AssetRateParameters;
    using CashGroup for CashGroupParameters;
    using nTokenHandler for nTokenPortfolio;
    using AccountContextHandler for AccountContext;
    using BalanceHandler for BalanceState;
    using SafeInt256 for int256;
    using SafeMath for uint256;

    function _checkValidCurrency(uint16 currencyId) internal view {
        require(0 < currencyId && currencyId <= maxCurrencyId, "Invalid currency id");
    }

    /** General Calculation View Methods **/

    /// @notice Returns the nTokens that will be minted when some amount of asset tokens are deposited
    /// @param currencyId id number of the currency
    /// @param amountToDepositExternalPrecision amount of asset tokens in native precision
    /// @return the amount of nTokens that will be minted
    function calculateNTokensToMint(uint16 currencyId, uint88 amountToDepositExternalPrecision)
        external
        view
        override
        returns (uint256)
    {
        _checkValidCurrency(currencyId);
        Token memory token = TokenHandler.getAssetToken(currencyId);
        int256 amountToDepositInternal = token.convertToInternal(int256(amountToDepositExternalPrecision));
        nTokenPortfolio memory nToken;
        nToken.loadNTokenPortfolioView(currencyId);

        int256 tokensToMint = nTokenMintAction.calculateTokensToMint(
            nToken,
            amountToDepositInternal,
            block.timestamp
        );

        return SafeCast.toUint256(tokensToMint);
    }


    /// @notice Returns the fCash amount to send when given a cash amount, be sure to buffer these amounts
    /// slightly because the liquidity curve is sensitive to changes in block time
    /// @param currencyId id number of the currency
    /// @param netCashToAccount denominated in underlying terms in 1e8 decimal precision,
    //// positive for borrowing, negative for lending
    /// @param marketIndex market index of the fCash market
    /// @param blockTime the block time for when the trade will be calculated
    /// @return the fCash amount from the trade, positive when lending, negative when borrowing. Always in 8 decimals.
    function getfCashAmountGivenCashAmount(
        uint16 currencyId,
        int88 netCashToAccount,
        uint256 marketIndex,
        uint256 blockTime
    ) external view override returns (int256) {
        _checkValidCurrency(currencyId);
        CashGroupParameters memory cashGroup = CashGroup.buildCashGroupView(currencyId);
        return _getfCashAmountGivenCashAmount(netCashToAccount, marketIndex, blockTime, cashGroup);
    }
        
    function _getfCashAmountGivenCashAmount(
        int88 netCashToAccount,
        uint256 marketIndex,
        uint256 blockTime,
        CashGroupParameters memory cashGroup
    ) internal view returns (int256) {
        MarketParameters memory market;
        cashGroup.loadMarket(market, marketIndex, false, blockTime);

        require(market.maturity > blockTime, "Invalid block time");
        uint256 timeToMaturity = market.maturity - blockTime;
        (int256 rateScalar, int256 totalCashUnderlying, int256 rateAnchor) =
            Market.getExchangeRateFactors(market, cashGroup, timeToMaturity, marketIndex);
        int256 fee = Market.getExchangeRateFromImpliedRate(cashGroup.getTotalFee(), timeToMaturity);

        return
            Market.getfCashGivenCashAmount(
                market.totalfCash,
                netCashToAccount,
                totalCashUnderlying,
                rateScalar,
                rateAnchor,
                fee,
                0
            );
    }

    /// @notice Returns the cash amount that will be traded given an fCash amount, be sure to buffer these amounts
    /// slightly because the liquidity curve is sensitive to changes in block time
    /// @param currencyId id number of the currency
    /// @param fCashAmount amount of fCash to trade, negative for borrowing, positive for lending
    /// @param marketIndex market index of the fCash market
    /// @param blockTime the block time for when the trade will be calculated
    /// @return net asset cash amount (positive for borrowing, negative for lending) in 8 decimal precision
    /// @return underlying cash amount (positive for borrowing, negative for lending) in 8 decimal precision
    function getCashAmountGivenfCashAmount(
        uint16 currencyId,
        int88 fCashAmount,
        uint256 marketIndex,
        uint256 blockTime
    ) external view override returns (int256, int256) {
        return _getCashAmountGivenfCashAmount(currencyId, fCashAmount, marketIndex, blockTime, 0);
    }

    function _getCashAmountGivenfCashAmount(
        uint16 currencyId,
        int88 fCashAmount,
        uint256 marketIndex,
        uint256 blockTime, 
        uint256 rateLimit
    ) internal view returns (int256, int256) {
        _checkValidCurrency(currencyId);
        CashGroupParameters memory cashGroup = CashGroup.buildCashGroupView(currencyId);
        MarketParameters memory market;
        cashGroup.loadMarket(market, marketIndex, false, blockTime);

        require(market.maturity > blockTime, "Invalid block time");
        uint256 timeToMaturity = market.maturity - blockTime;

        // prettier-ignore
        (int256 assetCash, /* int fee */) =
            market.calculateTrade(cashGroup, fCashAmount, timeToMaturity, marketIndex);

        // Check the slippage here and revert
        if (rateLimit != 0) {
            if (fCashAmount < 0) {
                // Do not allow borrows over the rate limit
                require(market.lastImpliedRate <= rateLimit, "Trade failed, slippage");
            } else {
                // Do not allow lends under the rate limit
                require(market.lastImpliedRate >= rateLimit, "Trade failed, slippage");
            }
        }

        return (assetCash, cashGroup.assetRate.convertToUnderlying(assetCash));
    }

    /// @notice Returns the claimable incentives for all nToken balances
    /// @param account The address of the account which holds the tokens
    /// @param blockTime The block time when incentives will be minted
    /// @return Incentives an account is eligible to claim
    function nTokenGetClaimableIncentives(address account, uint256 blockTime)
        external
        view
        override
        returns (uint256)
    {
        AccountContext memory accountContext = AccountContextHandler.getAccountContext(account);
        BalanceState memory balanceState;
        uint256 totalIncentivesClaimable;

        if (accountContext.isBitmapEnabled()) {
            balanceState.loadBalanceState(account, accountContext.bitmapCurrencyId, accountContext);
            if (balanceState.storedNTokenBalance > 0) {
                address tokenAddress = nTokenHandler.nTokenAddress(balanceState.currencyId);
                (
                    /* uint256 totalSupply */,
                    uint256 accumulatedNOTEPerNToken,
                    /* uint256 lastAccumulatedTime */
                ) = nTokenSupply.getUpdatedAccumulatedNOTEPerNToken(tokenAddress, blockTime);

                uint256 incentivesToClaim = Incentives.calculateIncentivesToClaim(
                    balanceState,
                    tokenAddress,
                    accumulatedNOTEPerNToken,
                    balanceState.storedNTokenBalance.toUint()
                );
                totalIncentivesClaimable = totalIncentivesClaimable.add(incentivesToClaim);
            }
        }

        bytes18 currencies = accountContext.activeCurrencies;
        while (currencies != 0) {
            uint16 currencyId = uint16(bytes2(currencies) & Constants.UNMASK_FLAGS);
            balanceState.loadBalanceState(account, currencyId, accountContext);

            if (balanceState.storedNTokenBalance > 0) {
                address tokenAddress = nTokenHandler.nTokenAddress(balanceState.currencyId);
                (
                    /* uint256 totalSupply */,
                    uint256 accumulatedNOTEPerNToken,
                    /* uint256 lastAccumulatedTime */
                ) = nTokenSupply.getUpdatedAccumulatedNOTEPerNToken(tokenAddress, blockTime);

                uint256 incentivesToClaim = Incentives.calculateIncentivesToClaim(
                    balanceState,
                    tokenAddress,
                    accumulatedNOTEPerNToken,
                    balanceState.storedNTokenBalance.toUint()
                );
                totalIncentivesClaimable = totalIncentivesClaimable.add(incentivesToClaim);
            }

            currencies = currencies << 16;
        }

        return totalIncentivesClaimable;
    }

    /// @notice Returns the present value of the given fCash amount using Notional internal oracle rates
    /// @param currencyId id number of the currency
    /// @param maturity timestamp of the fCash maturity
    /// @param notional amount of fCash notional
    /// @param blockTime the block time for when the trade will be calculated
    /// @param riskAdjusted true if haircuts and buffers should be applied to the oracle rate
    /// @return presentValue of fCash in 8 decimal precision and underlying denomination
    function getPresentfCashValue(
        uint16 currencyId,
        uint256 maturity,
        int256 notional,
        uint256 blockTime,
        bool riskAdjusted
    ) external view override returns (int256 presentValue) {
        CashGroupParameters memory cg = CashGroup.buildCashGroupView(currencyId);
        if (riskAdjusted) {
            presentValue = AssetHandler.getRiskAdjustedPresentfCashValue(
                cg,
                notional,
                maturity,
                blockTime,
                cg.calculateOracleRate(maturity, blockTime)
            );
        } else {
            presentValue = AssetHandler.getPresentfCashValue(
                notional,
                maturity,
                blockTime,
                cg.calculateOracleRate(maturity, blockTime)
            );
        }
    }

    /// @notice Returns a market index value for a given maturity
    /// @param maturity an fCash maturity
    /// @param blockTime the block time for when the trade will be calculated
    /// @return marketIndex a value between 1 and 7 that represents the marketIndex (tenor)
    /// that corresponds to the maturity. Returns 0 if there is no corresponding marketIndex
    function getMarketIndex(
        uint256 maturity,
        uint256 blockTime
    ) public pure override returns (uint8 marketIndex) {
        (
            uint256 _marketIndex,
            bool isIdiosyncratic
        ) = DateTime.getMarketIndex(Constants.MAX_TRADED_MARKET_INDEX, maturity, blockTime);

        // Market Index cannot be greater than 7 by construction
        marketIndex = isIdiosyncratic ? 0 : uint8(_marketIndex);
    }

    /// @notice Returns the amount of fCash that would received if lending deposit amount.
    /// @param currencyId id number of the currency
    /// @param depositAmountExternal amount to deposit in the token's native precision. For aTokens use
    /// what is returned by the balanceOf selector (not scaledBalanceOf).
    /// @param maturity the maturity of the fCash to lend
    /// @param minLendRate the minimum lending rate (slippage protection)
    /// @param blockTime the block time for when the trade will be calculated
    /// @param useUnderlying true if specifying the underlying token, false if specifying the asset token
    /// @return fCashAmount the amount of fCash that the lender will receive
    /// @return marketIndex the corresponding market index for the lending
    /// @return encodedTrade the encoded bytes32 object to pass to batch trade
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
        marketIndex = getMarketIndex(maturity, blockTime);
        require(marketIndex > 0);

        (
            int256 underlyingInternal,
            CashGroupParameters memory cashGroup
        ) = _convertDepositAmountToUnderlyingInternal(currencyId, depositAmountExternal, useUnderlying);
        int256 fCash = _getfCashAmountGivenCashAmount(_safeInt88(underlyingInternal.neg()), marketIndex, blockTime, cashGroup);
        require(0 < fCash);

        (
            encodedTrade,
            fCashAmount
        ) = _encodeLendBorrowTrade(TradeActionType.Lend, marketIndex, fCash, minLendRate);
    }

    /// @notice Returns the amount of fCash that would received if lending deposit amount.
    /// @param currencyId id number of the currency
    /// @param borrowedAmountExternal amount to borrow in the token's native precision. For aTokens use
    /// what is returned by the balanceOf selector (not scaledBalanceOf).
    /// @param maturity the maturity of the fCash to lend
    /// @param maxBorrowRate the maximum borrow rate (slippage protection). If zero then no slippage will be applied
    /// @param blockTime the block time for when the trade will be calculated
    /// @param useUnderlying true if specifying the underlying token, false if specifying the asset token
    /// @return fCashDebt the amount of fCash that the borrower will owe, this will be stored as a negative
    /// balance in Notional
    /// @return marketIndex the corresponding market index for the lending
    /// @return encodedTrade the encoded bytes32 object to pass to batch trade
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
        marketIndex = getMarketIndex(maturity, blockTime);
        require(marketIndex > 0);

        (
            int256 underlyingInternal,
            CashGroupParameters memory cashGroup
        ) = _convertDepositAmountToUnderlyingInternal(currencyId, borrowedAmountExternal, useUnderlying);
        int256 fCash = _getfCashAmountGivenCashAmount(_safeInt88(underlyingInternal), marketIndex, blockTime, cashGroup);
        require(fCash < 0);

        (
            encodedTrade,
            fCashDebt
        ) = _encodeLendBorrowTrade(TradeActionType.Borrow, marketIndex, fCash, maxBorrowRate);
    }

    /// @notice Returns the amount of underlying cash and asset cash required to lend fCash. When specifying a
    /// trade, deposit either underlying or asset tokens (not both). Asset tokens tend to be more gas efficient.
    /// @param currencyId id number of the currency
    /// @param fCashAmount amount of fCash (in underlying) that will be received at maturity. Always 8 decimal precision.
    /// @param maturity the maturity of the fCash to lend
    /// @param minLendRate the minimum lending rate (slippage protection)
    /// @param blockTime the block time for when the trade will be calculated
    /// @return depositAmountUnderlying the amount of underlying tokens the lender must deposit
    /// @return depositAmountAsset the amount of asset tokens the lender must deposit
    /// @return marketIndex the corresponding market index for the lending
    /// @return encodedTrade the encoded bytes32 object to pass to batch trade
    function getDepositFromfCashLend(
        uint16 currencyId,
        uint256 fCashAmount,
        uint256 maturity,
        uint32 minLendRate,
        uint256 blockTime
    ) external view override returns (
        uint256 depositAmountUnderlying,
        uint256 depositAmountAsset,
        uint8 marketIndex,
        bytes32 encodedTrade
    ) {
        marketIndex = getMarketIndex(maturity, blockTime);
        require(marketIndex > 0);
        require(fCashAmount < uint256(int256(type(int88).max)));

        int88 fCash = int88(SafeInt256.toInt(fCashAmount));
        (
            int256 assetCashInternal,
            int256 underlyingCashInternal
        ) = _getCashAmountGivenfCashAmount(currencyId, fCash, marketIndex, blockTime, minLendRate);

        depositAmountUnderlying = _convertToAmountExternal(currencyId, underlyingCashInternal, true);
        depositAmountAsset = _convertToAmountExternal(currencyId, assetCashInternal, false);
        (encodedTrade, /* */) = _encodeLendBorrowTrade(TradeActionType.Lend, marketIndex, fCash, minLendRate);
    }

    /// @notice Returns the amount of underlying cash and asset cash required to borrow fCash. When specifying a
    /// trade, choose to receive either underlying or asset tokens (not both). Asset tokens tend to be more gas efficient.
    /// @param currencyId id number of the currency
    /// @param fCashBorrow amount of fCash (in underlying) that will be received at maturity. Always 8 decimal precision.
    /// @param maturity the maturity of the fCash to lend
    /// @param maxBorrowRate the maximum borrow rate (slippage protection)
    /// @param blockTime the block time for when the trade will be calculated
    /// @return borrowAmountUnderlying the amount of underlying tokens the borrower will receive
    /// @return borrowAmountAsset the amount of asset tokens the borrower will receive
    /// @return marketIndex the corresponding market index for the lending
    /// @return encodedTrade the encoded bytes32 object to pass to batch trade
    function getPrincipalFromfCashBorrow(
        uint16 currencyId,
        uint256 fCashBorrow,
        uint256 maturity,
        uint32 maxBorrowRate,
        uint256 blockTime
    ) external view override returns (
        uint256 borrowAmountUnderlying,
        uint256 borrowAmountAsset,
        uint8 marketIndex,
        bytes32 encodedTrade
    ) {
        marketIndex = getMarketIndex(maturity, blockTime);
        require(marketIndex > 0);
        require(fCashBorrow < uint256(int256(type(int88).max)));

        int88 fCash = int88(SafeInt256.toInt(fCashBorrow).neg());
        (
            int256 assetCashInternal,
            int256 underlyingCashInternal
        ) = _getCashAmountGivenfCashAmount(currencyId, fCash, marketIndex, blockTime, maxBorrowRate);

        borrowAmountUnderlying = _convertToAmountExternal(currencyId, underlyingCashInternal, true);
        borrowAmountAsset = _convertToAmountExternal(currencyId, assetCashInternal, false);
        (encodedTrade, /* */) = _encodeLendBorrowTrade(TradeActionType.Borrow, marketIndex, fCash, maxBorrowRate);
    }

    /// @notice Converts an internal cash balance to an external token denomination
    /// @param currencyId the currency id of the cash balance
    /// @param cashBalanceInternal the signed cash balance that is stored in Notional
    /// @param convertToUnderlying true if the value should be converted to underlying
    /// @return the cash balance converted to the external token denomination
    function convertCashBalanceToExternal(
        uint16 currencyId,
        int256 cashBalanceInternal,
        bool convertToUnderlying
    ) external view override returns (int256) {
        if (convertToUnderlying) {
            AssetRateParameters memory ar = AssetRate.buildAssetRateView(currencyId);
            cashBalanceInternal = ar.convertToUnderlying(cashBalanceInternal);
        }

        int256 externalAmount = SafeInt256.toInt(_convertToAmountExternal(currencyId, cashBalanceInternal.abs(), convertToUnderlying));
        return cashBalanceInternal < 0 ? externalAmount.neg() : externalAmount;
    }

    function _convertToAmountExternal(
        uint16 currencyId,
        int256 depositAmountInternal,
        bool useUnderlying
    ) private view returns (uint256) {
        int256 amountExternal;
        Token memory token = useUnderlying ?
            TokenHandler.getUnderlyingToken(currencyId) :
            TokenHandler.getAssetToken(currencyId);

        if (useUnderlying && depositAmountInternal < 0) {
            // We have to do a special rounding adjustment for underlying internal deposits from lending.
            amountExternal = token.convertToUnderlyingExternalWithAdjustment(depositAmountInternal.neg());
        } else {
            amountExternal = token.convertToExternal(depositAmountInternal).abs();
        }

        if (token.tokenType == TokenType.aToken) {
            // Special handling for aTokens, we use scaled balance internally
            Token memory underlying = TokenHandler.getUnderlyingToken(currencyId);
            amountExternal = AaveHandler.convertFromScaledBalanceExternal(underlying.tokenAddress, amountExternal);
        }

        return SafeInt256.toUint(amountExternal);
    }

    /// @notice Converts an external deposit amount to an internal deposit amount
    function _convertDepositAmountToUnderlyingInternal(
        uint16 currencyId,
        uint256 depositAmountExternal,
        bool useUnderlying
    ) private view returns (int256 underlyingInternal, CashGroupParameters memory cashGroup) {
        int256 depositAmount = SafeInt256.toInt(depositAmountExternal);
        cashGroup = CashGroup.buildCashGroupView(currencyId);

        Token memory token = useUnderlying ?
            TokenHandler.getUnderlyingToken(currencyId) :
            TokenHandler.getAssetToken(currencyId);

        if (token.tokenType == TokenType.aToken) {
            // Special handling for aTokens, we use scaled balance internally
            depositAmount = AaveHandler.convertToScaledBalanceExternal(currencyId, depositAmount);
        }

        underlyingInternal = token.convertToInternal(depositAmount);
        if (!useUnderlying) {
            // Convert asset rates to underlying internal amounts
            underlyingInternal = cashGroup.assetRate.convertToUnderlying(underlyingInternal);
        }
    }

    function _safeInt88(int256 x) private pure returns (int88) {
        require(type(int88).min <= x && x <= type(int88).max);
        return int88(x);
    }

    function _encodeLendBorrowTrade(
        TradeActionType actionType,
        uint8 marketIndex,
        int256 fCash,
        uint32 slippage
    ) private pure returns (bytes32 encodedTrade, uint88 fCashAmount) {
        uint256 absfCash = uint256(fCash.abs());
        require(absfCash <= uint256(type(uint88).max));

        encodedTrade = bytes32(
            (uint256(uint8(actionType)) << 248) |
            (uint256(marketIndex) << 240) |
            (uint256(absfCash) << 152) |
            (uint256(slippage) << 120)
        );

        fCashAmount = uint88(absfCash);
    }

    /// @notice Get a list of deployed library addresses (sorted by library name)
    function getLibInfo() external view returns (address) {
        return (address(MigrateIncentives));
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "../../global/Constants.sol";
import "../../internal/nToken/nTokenHandler.sol";
import "../../internal/nToken/nTokenCalculations.sol";
import "../../internal/markets/Market.sol";
import "../../internal/markets/CashGroup.sol";
import "../../internal/markets/AssetRate.sol";
import "../../internal/balances/BalanceHandler.sol";
import "../../internal/portfolio/PortfolioHandler.sol";
import "../../math/SafeInt256.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

library nTokenMintAction {
    using SafeInt256 for int256;
    using BalanceHandler for BalanceState;
    using CashGroup for CashGroupParameters;
    using Market for MarketParameters;
    using nTokenHandler for nTokenPortfolio;
    using PortfolioHandler for PortfolioState;
    using AssetRate for AssetRateParameters;
    using SafeMath for uint256;
    using nTokenHandler for nTokenPortfolio;

    /// @notice Converts the given amount of cash to nTokens in the same currency.
    /// @param currencyId the currency associated the nToken
    /// @param amountToDepositInternal the amount of asset tokens to deposit denominated in internal decimals
    /// @return nTokens minted by this action
    function nTokenMint(uint16 currencyId, int256 amountToDepositInternal)
        external
        returns (int256)
    {
        uint256 blockTime = block.timestamp;
        nTokenPortfolio memory nToken;
        nToken.loadNTokenPortfolioStateful(currencyId);

        int256 tokensToMint = calculateTokensToMint(nToken, amountToDepositInternal, blockTime);
        require(tokensToMint >= 0, "Invalid token amount");

        if (nToken.portfolioState.storedAssets.length == 0) {
            // If the token does not have any assets, then the markets must be initialized first.
            nToken.cashBalance = nToken.cashBalance.add(amountToDepositInternal);
            BalanceHandler.setBalanceStorageForNToken(
                nToken.tokenAddress,
                currencyId,
                nToken.cashBalance
            );
        } else {
            _depositIntoPortfolio(nToken, amountToDepositInternal, blockTime);
        }

        // NOTE: token supply does not change here, it will change after incentives have been claimed
        // during BalanceHandler.finalize
        return tokensToMint;
    }

    /// @notice Calculates the tokens to mint to the account as a ratio of the nToken
    /// present value denominated in asset cash terms.
    /// @return the amount of tokens to mint, the ifCash bitmap
    function calculateTokensToMint(
        nTokenPortfolio memory nToken,
        int256 amountToDepositInternal,
        uint256 blockTime
    ) internal view returns (int256) {
        require(amountToDepositInternal >= 0); // dev: deposit amount negative
        if (amountToDepositInternal == 0) return 0;

        if (nToken.lastInitializedTime != 0) {
            // For the sake of simplicity, nTokens cannot be minted if they have assets
            // that need to be settled. This is only done during market initialization.
            uint256 nextSettleTime = nToken.getNextSettleTime();
            // If next settle time <= blockTime then the token can be settled
            require(nextSettleTime > blockTime, "Requires settlement");
        }

        int256 assetCashPV = nTokenCalculations.getNTokenAssetPV(nToken, blockTime);
        // Defensive check to ensure PV remains positive
        require(assetCashPV >= 0);

        // Allow for the first deposit
        if (nToken.totalSupply == 0) {
            return amountToDepositInternal;
        } else {
            // assetCashPVPost = assetCashPV + amountToDeposit
            // (tokenSupply + tokensToMint) / tokenSupply == (assetCashPV + amountToDeposit) / assetCashPV
            // (tokenSupply + tokensToMint) == (assetCashPV + amountToDeposit) * tokenSupply / assetCashPV
            // (tokenSupply + tokensToMint) == tokenSupply + (amountToDeposit * tokenSupply) / assetCashPV
            // tokensToMint == (amountToDeposit * tokenSupply) / assetCashPV
            return amountToDepositInternal.mul(nToken.totalSupply).div(assetCashPV);
        }
    }

    /// @notice Portions out assetCashDeposit into amounts to deposit into individual markets. When
    /// entering this method we know that assetCashDeposit is positive and the nToken has been
    /// initialized to have liquidity tokens.
    function _depositIntoPortfolio(
        nTokenPortfolio memory nToken,
        int256 assetCashDeposit,
        uint256 blockTime
    ) private {
        (int256[] memory depositShares, int256[] memory leverageThresholds) =
            nTokenHandler.getDepositParameters(
                nToken.cashGroup.currencyId,
                nToken.cashGroup.maxMarketIndex
            );

        // Loop backwards from the last market to the first market, the reasoning is a little complicated:
        // If we have to deleverage the markets (i.e. lend instead of provide liquidity) it's quite gas inefficient
        // to calculate the cash amount to lend. We do know that longer term maturities will have more
        // slippage and therefore the residual from the perMarketDeposit will be lower as the maturities get
        // closer to the current block time. Any residual cash from lending will be rolled into shorter
        // markets as this loop progresses.
        int256 residualCash;
        MarketParameters memory market;
        for (uint256 marketIndex = nToken.cashGroup.maxMarketIndex; marketIndex > 0; marketIndex--) {
            int256 fCashAmount;
            // Loads values into the market memory slot
            nToken.cashGroup.loadMarket(
                market,
                marketIndex,
                true, // Needs liquidity to true
                blockTime
            );
            // If market has not been initialized, continue. This can occur when cash groups extend maxMarketIndex
            // before initializing
            if (market.totalLiquidity == 0) continue;

            // Checked that assetCashDeposit must be positive before entering
            int256 perMarketDeposit =
                assetCashDeposit
                    .mul(depositShares[marketIndex - 1])
                    .div(Constants.DEPOSIT_PERCENT_BASIS)
                    .add(residualCash);

            (fCashAmount, residualCash) = _lendOrAddLiquidity(
                nToken,
                market,
                perMarketDeposit,
                leverageThresholds[marketIndex - 1],
                marketIndex,
                blockTime
            );

            if (fCashAmount != 0) {
                BitmapAssetsHandler.addifCashAsset(
                    nToken.tokenAddress,
                    nToken.cashGroup.currencyId,
                    market.maturity,
                    nToken.lastInitializedTime,
                    fCashAmount
                );
            }
        }

        // nToken is allowed to store assets directly without updating account context.
        nToken.portfolioState.storeAssets(nToken.tokenAddress);

        // Defensive check to ensure that we do not somehow accrue negative residual cash.
        require(residualCash >= 0, "Negative residual cash");
        // This will occur if the three month market is over levered and we cannot lend into it
        if (residualCash > 0) {
            // Any remaining residual cash will be put into the nToken balance and added as liquidity on the
            // next market initialization
            nToken.cashBalance = nToken.cashBalance.add(residualCash);
            BalanceHandler.setBalanceStorageForNToken(
                nToken.tokenAddress,
                nToken.cashGroup.currencyId,
                nToken.cashBalance
            );
        }
    }

    /// @notice For a given amount of cash to deposit, decides how much to lend or provide
    /// given the market conditions.
    function _lendOrAddLiquidity(
        nTokenPortfolio memory nToken,
        MarketParameters memory market,
        int256 perMarketDeposit,
        int256 leverageThreshold,
        uint256 marketIndex,
        uint256 blockTime
    ) private returns (int256 fCashAmount, int256 residualCash) {
        // We start off with the entire per market deposit as residuals
        residualCash = perMarketDeposit;

        // If the market is over leveraged then we will lend to it instead of providing liquidity
        if (_isMarketOverLeveraged(nToken.cashGroup, market, leverageThreshold)) {
            (residualCash, fCashAmount) = _deleverageMarket(
                nToken.cashGroup,
                market,
                perMarketDeposit,
                blockTime,
                marketIndex
            );

            // Recalculate this after lending into the market, if it is still over leveraged then
            // we will not add liquidity and just exit.
            if (_isMarketOverLeveraged(nToken.cashGroup, market, leverageThreshold)) {
                // Returns the residual cash amount
                return (fCashAmount, residualCash);
            }
        }

        // Add liquidity to the market only if we have successfully delevered.
        // (marketIndex - 1) is the index of the nToken portfolio array where the asset is stored
        // If deleveraged, residualCash is what remains
        // If not deleveraged, residual cash is per market deposit
        fCashAmount = fCashAmount.add(
            _addLiquidityToMarket(nToken, market, marketIndex - 1, residualCash)
        );
        // No residual cash if we're adding liquidity
        return (fCashAmount, 0);
    }

    /// @notice Markets are over levered when their proportion is greater than a governance set
    /// threshold. At this point, providing liquidity will incur too much negative fCash on the nToken
    /// account for the given amount of cash deposited, putting the nToken account at risk of liquidation.
    /// If the market is over leveraged, we call `deleverageMarket` to lend to the market instead.
    function _isMarketOverLeveraged(
        CashGroupParameters memory cashGroup,
        MarketParameters memory market,
        int256 leverageThreshold
    ) private pure returns (bool) {
        int256 totalCashUnderlying = cashGroup.assetRate.convertToUnderlying(market.totalAssetCash);
        // Comparison we want to do:
        // (totalfCash) / (totalfCash + totalCashUnderlying) > leverageThreshold
        // However, the division will introduce rounding errors so we change this to:
        // totalfCash * RATE_PRECISION > leverageThreshold * (totalfCash + totalCashUnderlying)
        // Leverage threshold is denominated in rate precision.
        return (
            market.totalfCash.mul(Constants.RATE_PRECISION) >
            leverageThreshold.mul(market.totalfCash.add(totalCashUnderlying))
        );
    }

    function _addLiquidityToMarket(
        nTokenPortfolio memory nToken,
        MarketParameters memory market,
        uint256 index,
        int256 perMarketDeposit
    ) private returns (int256) {
        // Add liquidity to the market
        PortfolioAsset memory asset = nToken.portfolioState.storedAssets[index];
        // We expect that all the liquidity tokens are in the portfolio in order.
        require(
            asset.maturity == market.maturity &&
            // Ensures that the asset type references the proper liquidity token
            asset.assetType == index + Constants.MIN_LIQUIDITY_TOKEN_INDEX &&
            // Ensures that the storage state will not be overwritten
            asset.storageState == AssetStorageState.NoChange,
            "PT: invalid liquidity token"
        );

        // This will update the market state as well, fCashAmount returned here is negative
        (int256 liquidityTokens, int256 fCashAmount) = market.addLiquidity(perMarketDeposit);
        asset.notional = asset.notional.add(liquidityTokens);
        asset.storageState = AssetStorageState.Update;

        return fCashAmount;
    }

    /// @notice Lends into the market to reduce the leverage that the nToken will add liquidity at. May fail due
    /// to slippage or result in some amount of residual cash.
    function _deleverageMarket(
        CashGroupParameters memory cashGroup,
        MarketParameters memory market,
        int256 perMarketDeposit,
        uint256 blockTime,
        uint256 marketIndex
    ) private returns (int256, int256) {
        uint256 timeToMaturity = market.maturity.sub(blockTime);

        // Shift the last implied rate by some buffer and calculate the exchange rate to fCash. Hope that this
        // is sufficient to cover all potential slippage. We don't use the `getfCashGivenCashAmount` method here
        // because it is very gas inefficient.
        int256 assumedExchangeRate;
        if (market.lastImpliedRate < Constants.DELEVERAGE_BUFFER) {
            // Floor the exchange rate at zero interest rate
            assumedExchangeRate = Constants.RATE_PRECISION;
        } else {
            assumedExchangeRate = Market.getExchangeRateFromImpliedRate(
                market.lastImpliedRate.sub(Constants.DELEVERAGE_BUFFER),
                timeToMaturity
            );
        }

        int256 fCashAmount;
        {
            int256 perMarketDepositUnderlying =
                cashGroup.assetRate.convertToUnderlying(perMarketDeposit);
            // NOTE: cash * exchangeRate = fCash
            fCashAmount = perMarketDepositUnderlying.mulInRatePrecision(assumedExchangeRate);
        }
        int256 netAssetCash = market.executeTrade(cashGroup, fCashAmount, timeToMaturity, marketIndex);

        // This means that the trade failed
        if (netAssetCash == 0) {
            return (perMarketDeposit, 0);
        } else {
            // Ensure that net the per market deposit figure does not drop below zero, this should not be possible
            // given how we've calculated the exchange rate but extra caution here
            int256 residual = perMarketDeposit.add(netAssetCash);
            require(residual >= 0); // dev: insufficient cash
            return (residual, fCashAmount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "../../math/SafeInt256.sol";
import "../../global/LibStorage.sol";
import "../../global/Types.sol";
import "../../global/Constants.sol";
import "../../global/Deployments.sol";
import "./protocols/AaveHandler.sol";
import "./protocols/CompoundHandler.sol";
import "./protocols/GenericToken.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @notice Handles all external token transfers and events
library TokenHandler {
    using SafeInt256 for int256;
    using SafeMath for uint256;

    function setMaxCollateralBalance(uint256 currencyId, uint72 maxCollateralBalance) internal {
        mapping(uint256 => mapping(bool => TokenStorage)) storage store = LibStorage.getTokenStorage();
        TokenStorage storage tokenStorage = store[currencyId][false];
        tokenStorage.maxCollateralBalance = maxCollateralBalance;
    } 

    function getAssetToken(uint256 currencyId) internal view returns (Token memory) {
        return _getToken(currencyId, false);
    }

    function getUnderlyingToken(uint256 currencyId) internal view returns (Token memory) {
        return _getToken(currencyId, true);
    }

    /// @notice Gets token data for a particular currency id, if underlying is set to true then returns
    /// the underlying token. (These may not always exist)
    function _getToken(uint256 currencyId, bool underlying) private view returns (Token memory) {
        mapping(uint256 => mapping(bool => TokenStorage)) storage store = LibStorage.getTokenStorage();
        TokenStorage storage tokenStorage = store[currencyId][underlying];

        return
            Token({
                tokenAddress: tokenStorage.tokenAddress,
                hasTransferFee: tokenStorage.hasTransferFee,
                // No overflow, restricted on storage
                decimals: int256(10**tokenStorage.decimalPlaces),
                tokenType: tokenStorage.tokenType,
                maxCollateralBalance: tokenStorage.maxCollateralBalance
            });
    }

    /// @notice Sets a token for a currency id.
    function setToken(
        uint256 currencyId,
        bool underlying,
        TokenStorage memory tokenStorage
    ) internal {
        mapping(uint256 => mapping(bool => TokenStorage)) storage store = LibStorage.getTokenStorage();

        if (tokenStorage.tokenType == TokenType.Ether && currencyId == Constants.ETH_CURRENCY_ID) {
            // Hardcoded parameters for ETH just to make sure we don't get it wrong.
            TokenStorage storage ts = store[currencyId][true];
            ts.tokenAddress = address(0);
            ts.hasTransferFee = false;
            ts.tokenType = TokenType.Ether;
            ts.decimalPlaces = Constants.ETH_DECIMAL_PLACES;
            ts.maxCollateralBalance = 0;

            return;
        }

        // Check token address
        require(tokenStorage.tokenAddress != address(0), "TH: address is zero");
        // Once a token is set we cannot override it. In the case that we do need to do change a token address
        // then we should explicitly upgrade this method to allow for a token to be changed.
        Token memory token = _getToken(currencyId, underlying);
        require(
            token.tokenAddress == tokenStorage.tokenAddress || token.tokenAddress == address(0),
            "TH: token cannot be reset"
        );

        require(0 < tokenStorage.decimalPlaces 
            && tokenStorage.decimalPlaces <= Constants.MAX_DECIMAL_PLACES, "TH: invalid decimals");

        // Validate token type
        require(tokenStorage.tokenType != TokenType.Ether); // dev: ether can only be set once
        if (underlying) {
            // Underlying tokens cannot have max collateral balances, the contract only has a balance temporarily
            // during mint and redeem actions.
            require(tokenStorage.maxCollateralBalance == 0); // dev: underlying cannot have max collateral balance
            require(tokenStorage.tokenType == TokenType.UnderlyingToken); // dev: underlying token inconsistent
        } else {
            require(tokenStorage.tokenType != TokenType.UnderlyingToken); // dev: underlying token inconsistent
        }

        if (tokenStorage.tokenType == TokenType.cToken || tokenStorage.tokenType == TokenType.aToken) {
            // Set the approval for the underlying so that we can mint cTokens or aTokens
            Token memory underlyingToken = getUnderlyingToken(currencyId);

            // cTokens call transfer from the tokenAddress, but aTokens use the LendingPool
            // to initiate all transfers
            address approvalAddress = tokenStorage.tokenType == TokenType.cToken ?
                tokenStorage.tokenAddress :
                address(LibStorage.getLendingPool().lendingPool);

            // ERC20 tokens should return true on success for an approval, but Tether
            // does not return a value here so we use the NonStandard interface here to
            // check that the approval was successful.
            IEIP20NonStandard(underlyingToken.tokenAddress).approve(
                approvalAddress,
                type(uint256).max
            );
            GenericToken.checkReturnCode();
        }

        store[currencyId][underlying] = tokenStorage;
    }

    /**
     * @notice If a token is mintable then will mint it. At this point we expect to have the underlying
     * balance in the contract already.
     * @param assetToken the asset token to mint
     * @param underlyingAmountExternal the amount of underlying to transfer to the mintable token
     * @return the amount of asset tokens minted, will always be a positive integer
     */
    function mint(Token memory assetToken, uint16 currencyId, uint256 underlyingAmountExternal) internal returns (int256) {
        // aTokens return the principal plus interest value when calling the balanceOf selector. We cannot use this
        // value in internal accounting since it will not allow individual users to accrue aToken interest. Use the
        // scaledBalanceOf function call instead for internal accounting.
        bytes4 balanceOfSelector = assetToken.tokenType == TokenType.aToken ?
            AaveHandler.scaledBalanceOfSelector :
            GenericToken.defaultBalanceOfSelector;
        
        uint256 startingBalance = GenericToken.checkBalanceViaSelector(assetToken.tokenAddress, address(this), balanceOfSelector);

        if (assetToken.tokenType == TokenType.aToken) {
            Token memory underlyingToken = getUnderlyingToken(currencyId);
            AaveHandler.mint(underlyingToken, underlyingAmountExternal);
        } else if (assetToken.tokenType == TokenType.cToken) {
            CompoundHandler.mint(assetToken, underlyingAmountExternal);
        } else if (assetToken.tokenType == TokenType.cETH) {
            CompoundHandler.mintCETH(assetToken);
        } else {
            revert(); // dev: non mintable token
        }

        uint256 endingBalance = GenericToken.checkBalanceViaSelector(assetToken.tokenAddress, address(this), balanceOfSelector);
        // This is the starting and ending balance in external precision
        return SafeInt256.toInt(endingBalance.sub(startingBalance));
    }

    /**
     * @notice If a token is redeemable to underlying will redeem it and transfer the underlying balance
     * to the account
     * @param assetToken asset token to redeem
     * @param currencyId the currency id of the token
     * @param account account to transfer the underlying to
     * @param assetAmountExternal the amount to transfer in asset token denomination and external precision
     * @return the actual amount of underlying tokens transferred. this is used as a return value back to the
     * user, is not used for internal accounting purposes
     */
    function redeem(
        Token memory assetToken,
        uint256 currencyId,
        address account,
        uint256 assetAmountExternal
    ) internal returns (int256) {
        uint256 transferAmount;
        if (assetToken.tokenType == TokenType.cETH) {
            transferAmount = CompoundHandler.redeemCETH(assetToken, account, assetAmountExternal);
        } else {
            Token memory underlyingToken = getUnderlyingToken(currencyId);
            if (assetToken.tokenType == TokenType.aToken) {
                transferAmount = AaveHandler.redeem(underlyingToken, account, assetAmountExternal);
            } else if (assetToken.tokenType == TokenType.cToken) {
                transferAmount = CompoundHandler.redeem(assetToken, underlyingToken, account, assetAmountExternal);
            } else {
                revert(); // dev: non redeemable token
            }
        }
        
        // Use the negative value here to signify that assets have left the protocol
        return SafeInt256.toInt(transferAmount).neg();
    }

    /// @notice Handles transfers into and out of the system denominated in the external token decimal
    /// precision.
    function transfer(
        Token memory token,
        address account,
        uint256 currencyId,
        int256 netTransferExternal
    ) internal returns (int256 actualTransferExternal) {
        // This will be true in all cases except for deposits where the token has transfer fees. For
        // aTokens this value is set before convert from scaled balances to principal plus interest
        actualTransferExternal = netTransferExternal;

        if (token.tokenType == TokenType.aToken) {
            Token memory underlyingToken = getUnderlyingToken(currencyId);
            // aTokens need to be converted when we handle the transfer since the external balance format
            // is not the same as the internal balance format that we use
            netTransferExternal = AaveHandler.convertFromScaledBalanceExternal(
                underlyingToken.tokenAddress,
                netTransferExternal
            );
        }

        if (netTransferExternal > 0) {
            // Deposits must account for transfer fees.
            int256 netDeposit = _deposit(token, account, uint256(netTransferExternal));
            // If an aToken has a transfer fee this will still return a balance figure
            // in scaledBalanceOf terms due to the selector
            if (token.hasTransferFee) actualTransferExternal = netDeposit;
        } else if (token.tokenType == TokenType.Ether) {
            // netTransferExternal can only be negative or zero at this point
            GenericToken.transferNativeTokenOut(account, uint256(netTransferExternal.neg()));
        } else {
            GenericToken.safeTransferOut(
                token.tokenAddress,
                account,
                // netTransferExternal is zero or negative here
                uint256(netTransferExternal.neg())
            );
        }
    }

    /// @notice Handles token deposits into Notional. If there is a transfer fee then we must
    /// calculate the net balance after transfer. Amounts are denominated in the destination token's
    /// precision.
    function _deposit(
        Token memory token,
        address account,
        uint256 amount
    ) private returns (int256) {
        uint256 startingBalance;
        uint256 endingBalance;
        bytes4 balanceOfSelector = token.tokenType == TokenType.aToken ?
            AaveHandler.scaledBalanceOfSelector :
            GenericToken.defaultBalanceOfSelector;

        if (token.hasTransferFee) {
            startingBalance = GenericToken.checkBalanceViaSelector(token.tokenAddress, address(this), balanceOfSelector);
        }

        GenericToken.safeTransferIn(token.tokenAddress, account, amount);

        if (token.hasTransferFee || token.maxCollateralBalance > 0) {
            // If aTokens have a max collateral balance then it will be applied against the scaledBalanceOf. This is probably
            // the correct behavior because if collateral accrues interest over time we should not somehow go over the
            // maxCollateralBalance due to the passage of time.
            endingBalance = GenericToken.checkBalanceViaSelector(token.tokenAddress, address(this), balanceOfSelector);
        }

        if (token.maxCollateralBalance > 0) {
            int256 internalPrecisionBalance = convertToInternal(token, SafeInt256.toInt(endingBalance));
            // Max collateral balance is stored as uint72, no overflow
            require(internalPrecisionBalance <= SafeInt256.toInt(token.maxCollateralBalance)); // dev: over max collateral balance
        }

        // Math is done in uint inside these statements and will revert on negative
        if (token.hasTransferFee) {
            return SafeInt256.toInt(endingBalance.sub(startingBalance));
        } else {
            return SafeInt256.toInt(amount);
        }
    }

    function convertToInternal(Token memory token, int256 amount) internal pure returns (int256) {
        // If token decimals > INTERNAL_TOKEN_PRECISION:
        //  on deposit: resulting dust will accumulate to protocol
        //  on withdraw: protocol may lose dust amount. However, withdraws are only calculated based
        //    on a conversion from internal token precision to external token precision so therefore dust
        //    amounts cannot be specified for withdraws.
        // If token decimals < INTERNAL_TOKEN_PRECISION then this will add zeros to the
        // end of amount and will not result in dust.
        if (token.decimals == Constants.INTERNAL_TOKEN_PRECISION) return amount;
        return amount.mul(Constants.INTERNAL_TOKEN_PRECISION).div(token.decimals);
    }

    function convertToExternal(Token memory token, int256 amount) internal pure returns (int256) {
        if (token.decimals == Constants.INTERNAL_TOKEN_PRECISION) return amount;
        // If token decimals > INTERNAL_TOKEN_PRECISION then this will increase amount
        // by adding a number of zeros to the end and will not result in dust.
        // If token decimals < INTERNAL_TOKEN_PRECISION:
        //  on deposit: Deposits are specified in external token precision and there is no loss of precision when
        //      tokens are converted from external to internal precision
        //  on withdraw: this calculation will round down such that the protocol retains the residual cash balance
        return amount.mul(token.decimals).div(Constants.INTERNAL_TOKEN_PRECISION);
    }

    /// @notice Converts a token to an underlying external amount with adjustments for rounding errors when depositing
    function convertToUnderlyingExternalWithAdjustment(
        Token memory token,
        int256 underlyingInternalAmount
    ) internal pure returns (int256 underlyingExternalAmount) {
        if (token.decimals < Constants.INTERNAL_TOKEN_PRECISION) {
            // If external < 8, we could truncate down and cause an off by one error, for example we need
            // 1.00000011 cash and we deposit only 1.000000, missing 11 units. Therefore, we add a unit at the
            // lower precision (external) to get around off by one errors
            underlyingExternalAmount = convertToExternal(token, underlyingInternalAmount).add(1);
        } else {
            // If external > 8, we may not mint enough asset tokens because in the case of 1e18 precision 
            // an off by 1 error at 1e8 precision is 1e10 units of the underlying token. In this case we
            // add 1 at the internal precision which has the effect of rounding up by 1e10
            underlyingExternalAmount = convertToExternal(token, underlyingInternalAmount.add(1));
        }
    }

    function transferIncentive(address account, uint256 tokensToTransfer) internal {
        GenericToken.safeTransferOut(Deployments.NOTE_TOKEN_ADDRESS, account, tokensToTransfer);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "./Types.sol";

/**
 * @notice Storage layout for the system. Do not change this file once deployed, future storage
 * layouts must inherit this and increment the version number.
 */
contract StorageLayoutV1 {
    // The current maximum currency id
    uint16 internal maxCurrencyId;
    // Sets the state of liquidations being enabled during a paused state. Each of the four lower
    // bits can be turned on to represent one of the liquidation types being enabled.
    bytes1 internal liquidationEnabledState;
    // Set to true once the system has been initialized
    bool internal hasInitialized;

    /* Authentication Mappings */
    // This is set to the timelock contract to execute governance functions
    address public owner;
    // This is set to an address of a router that can only call governance actions
    address public pauseRouter;
    // This is set to an address of a router that can only call governance actions
    address public pauseGuardian;
    // On upgrades this is set in the case that the pause router is used to pass the rollback check
    address internal rollbackRouterImplementation;

    // A blanket allowance for a spender to transfer any of an account's nTokens. This would allow a user
    // to set an allowance on all nTokens for a particular integrating contract system.
    // owner => spender => transferAllowance
    mapping(address => mapping(address => uint256)) internal nTokenWhitelist;
    // Individual transfer allowances for nTokens used for ERC20
    // owner => spender => currencyId => transferAllowance
    mapping(address => mapping(address => mapping(uint16 => uint256))) internal nTokenAllowance;

    // Transfer operators
    // Mapping from a global ERC1155 transfer operator contract to an approval value for it
    mapping(address => bool) internal globalTransferOperator;
    // Mapping from an account => operator => approval status for that operator. This is a specific
    // approval between two addresses for ERC1155 transfers.
    mapping(address => mapping(address => bool)) internal accountAuthorizedTransferOperator;
    // Approval for a specific contract to use the `batchBalanceAndTradeActionWithCallback` method in
    // BatchAction.sol, can only be set by governance
    mapping(address => bool) internal authorizedCallbackContract;

    // Reverse mapping from token addresses to currency ids, only used for referencing in views
    // and checking for duplicate token listings.
    mapping(address => uint16) internal tokenAddressToCurrencyId;

    // Reentrancy guard
    uint256 internal reentrancyStatus;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "./Market.sol";
import "./AssetRate.sol";
import "./DateTime.sol";
import "../../global/LibStorage.sol";
import "../../global/Types.sol";
import "../../global/Constants.sol";
import "../../math/SafeInt256.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

library CashGroup {
    using SafeMath for uint256;
    using SafeInt256 for int256;
    using AssetRate for AssetRateParameters;
    using Market for MarketParameters;

    // Bit number references for each parameter in the 32 byte word (0-indexed)
    uint256 private constant MARKET_INDEX_BIT = 31;
    uint256 private constant RATE_ORACLE_TIME_WINDOW_BIT = 30;
    uint256 private constant TOTAL_FEE_BIT = 29;
    uint256 private constant RESERVE_FEE_SHARE_BIT = 28;
    uint256 private constant DEBT_BUFFER_BIT = 27;
    uint256 private constant FCASH_HAIRCUT_BIT = 26;
    uint256 private constant SETTLEMENT_PENALTY_BIT = 25;
    uint256 private constant LIQUIDATION_FCASH_HAIRCUT_BIT = 24;
    uint256 private constant LIQUIDATION_DEBT_BUFFER_BIT = 23;
    // 7 bytes allocated, one byte per market for the liquidity token haircut
    uint256 private constant LIQUIDITY_TOKEN_HAIRCUT_FIRST_BIT = 22;
    // 7 bytes allocated, one byte per market for the rate scalar
    uint256 private constant RATE_SCALAR_FIRST_BIT = 15;

    // Offsets for the bytes of the different parameters
    uint256 private constant MARKET_INDEX = (31 - MARKET_INDEX_BIT) * 8;
    uint256 private constant RATE_ORACLE_TIME_WINDOW = (31 - RATE_ORACLE_TIME_WINDOW_BIT) * 8;
    uint256 private constant TOTAL_FEE = (31 - TOTAL_FEE_BIT) * 8;
    uint256 private constant RESERVE_FEE_SHARE = (31 - RESERVE_FEE_SHARE_BIT) * 8;
    uint256 private constant DEBT_BUFFER = (31 - DEBT_BUFFER_BIT) * 8;
    uint256 private constant FCASH_HAIRCUT = (31 - FCASH_HAIRCUT_BIT) * 8;
    uint256 private constant SETTLEMENT_PENALTY = (31 - SETTLEMENT_PENALTY_BIT) * 8;
    uint256 private constant LIQUIDATION_FCASH_HAIRCUT = (31 - LIQUIDATION_FCASH_HAIRCUT_BIT) * 8;
    uint256 private constant LIQUIDATION_DEBT_BUFFER = (31 - LIQUIDATION_DEBT_BUFFER_BIT) * 8;
    uint256 private constant LIQUIDITY_TOKEN_HAIRCUT = (31 - LIQUIDITY_TOKEN_HAIRCUT_FIRST_BIT) * 8;
    uint256 private constant RATE_SCALAR = (31 - RATE_SCALAR_FIRST_BIT) * 8;

    /// @notice Returns the rate scalar scaled by time to maturity. The rate scalar multiplies
    /// the ln() portion of the liquidity curve as an inverse so it increases with time to
    /// maturity. The effect of the rate scalar on slippage must decrease with time to maturity.
    function getRateScalar(
        CashGroupParameters memory cashGroup,
        uint256 marketIndex,
        uint256 timeToMaturity
    ) internal pure returns (int256) {
        require(1 <= marketIndex && marketIndex <= cashGroup.maxMarketIndex); // dev: invalid market index

        uint256 offset = RATE_SCALAR + 8 * (marketIndex - 1);
        int256 scalar = int256(uint8(uint256(cashGroup.data >> offset))) * Constants.RATE_PRECISION;
        int256 rateScalar =
            scalar.mul(int256(Constants.IMPLIED_RATE_TIME)).div(SafeInt256.toInt(timeToMaturity));

        // Rate scalar is denominated in RATE_PRECISION, it is unlikely to underflow in the
        // division above.
        require(rateScalar > 0); // dev: rate scalar underflow
        return rateScalar;
    }

    /// @notice Haircut on liquidity tokens to account for the risk associated with changes in the
    /// proportion of cash to fCash within the pool. This is set as a percentage less than or equal to 100.
    function getLiquidityHaircut(CashGroupParameters memory cashGroup, uint256 assetType)
        internal
        pure
        returns (uint8)
    {
        require(
            Constants.MIN_LIQUIDITY_TOKEN_INDEX <= assetType &&
            assetType <= Constants.MAX_LIQUIDITY_TOKEN_INDEX
        ); // dev: liquidity haircut invalid asset type
        uint256 offset =
            LIQUIDITY_TOKEN_HAIRCUT + 8 * (assetType - Constants.MIN_LIQUIDITY_TOKEN_INDEX);
        return uint8(uint256(cashGroup.data >> offset));
    }

    /// @notice Total trading fee denominated in RATE_PRECISION with basis point increments
    function getTotalFee(CashGroupParameters memory cashGroup) internal pure returns (uint256) {
        return uint256(uint8(uint256(cashGroup.data >> TOTAL_FEE))) * Constants.BASIS_POINT;
    }

    /// @notice Percentage of the total trading fee that goes to the reserve
    function getReserveFeeShare(CashGroupParameters memory cashGroup)
        internal
        pure
        returns (int256)
    {
        return uint8(uint256(cashGroup.data >> RESERVE_FEE_SHARE));
    }

    /// @notice fCash haircut for valuation denominated in rate precision with five basis point increments
    function getfCashHaircut(CashGroupParameters memory cashGroup) internal pure returns (uint256) {
        return
            uint256(uint8(uint256(cashGroup.data >> FCASH_HAIRCUT))) * Constants.FIVE_BASIS_POINTS;
    }

    /// @notice fCash debt buffer for valuation denominated in rate precision with five basis point increments
    function getDebtBuffer(CashGroupParameters memory cashGroup) internal pure returns (uint256) {
        return uint256(uint8(uint256(cashGroup.data >> DEBT_BUFFER))) * Constants.FIVE_BASIS_POINTS;
    }

    /// @notice Time window factor for the rate oracle denominated in seconds with five minute increments.
    function getRateOracleTimeWindow(CashGroupParameters memory cashGroup)
        internal
        pure
        returns (uint256)
    {
        // This is denominated in 5 minute increments in storage
        return uint256(uint8(uint256(cashGroup.data >> RATE_ORACLE_TIME_WINDOW))) * Constants.FIVE_MINUTES;
    }

    /// @notice Penalty rate for settling cash debts denominated in basis points
    function getSettlementPenalty(CashGroupParameters memory cashGroup)
        internal
        pure
        returns (uint256)
    {
        return
            uint256(uint8(uint256(cashGroup.data >> SETTLEMENT_PENALTY))) * Constants.FIVE_BASIS_POINTS;
    }

    /// @notice Haircut for positive fCash during liquidation denominated rate precision
    /// with five basis point increments
    function getLiquidationfCashHaircut(CashGroupParameters memory cashGroup)
        internal
        pure
        returns (uint256)
    {
        return
            uint256(uint8(uint256(cashGroup.data >> LIQUIDATION_FCASH_HAIRCUT))) * Constants.FIVE_BASIS_POINTS;
    }

    /// @notice Haircut for negative fCash during liquidation denominated rate precision
    /// with five basis point increments
    function getLiquidationDebtBuffer(CashGroupParameters memory cashGroup)
        internal
        pure
        returns (uint256)
    {
        return
            uint256(uint8(uint256(cashGroup.data >> LIQUIDATION_DEBT_BUFFER))) * Constants.FIVE_BASIS_POINTS;
    }

    function loadMarket(
        CashGroupParameters memory cashGroup,
        MarketParameters memory market,
        uint256 marketIndex,
        bool needsLiquidity,
        uint256 blockTime
    ) internal view {
        require(1 <= marketIndex && marketIndex <= cashGroup.maxMarketIndex, "Invalid market");
        uint256 maturity =
            DateTime.getReferenceTime(blockTime).add(DateTime.getTradedMarket(marketIndex));

        market.loadMarket(
            cashGroup.currencyId,
            maturity,
            blockTime,
            needsLiquidity,
            getRateOracleTimeWindow(cashGroup)
        );
    }

    /// @notice Returns the linear interpolation between two market rates. The formula is
    /// slope = (longMarket.oracleRate - shortMarket.oracleRate) / (longMarket.maturity - shortMarket.maturity)
    /// interpolatedRate = slope * (assetMaturity - shortMarket.maturity) + shortMarket.oracleRate
    function interpolateOracleRate(
        uint256 shortMaturity,
        uint256 longMaturity,
        uint256 shortRate,
        uint256 longRate,
        uint256 assetMaturity
    ) internal pure returns (uint256) {
        require(shortMaturity < assetMaturity); // dev: cash group interpolation error, short maturity
        require(assetMaturity < longMaturity); // dev: cash group interpolation error, long maturity

        // It's possible that the rates are inverted where the short market rate > long market rate and
        // we will get an underflow here so we check for that
        if (longRate >= shortRate) {
            return
                (longRate - shortRate)
                    .mul(assetMaturity - shortMaturity)
                // No underflow here, checked above
                    .div(longMaturity - shortMaturity)
                    .add(shortRate);
        } else {
            // In this case the slope is negative so:
            // interpolatedRate = shortMarket.oracleRate - slope * (assetMaturity - shortMarket.maturity)
            // NOTE: this subtraction should never overflow, the linear interpolation between two points above zero
            // cannot go below zero
            return
                shortRate.sub(
                    // This is reversed to keep it it positive
                    (shortRate - longRate)
                        .mul(assetMaturity - shortMaturity)
                    // No underflow here, checked above
                        .div(longMaturity - shortMaturity)
                );
        }
    }

    /// @dev Gets an oracle rate given any valid maturity.
    function calculateOracleRate(
        CashGroupParameters memory cashGroup,
        uint256 maturity,
        uint256 blockTime
    ) internal view returns (uint256) {
        (uint256 marketIndex, bool idiosyncratic) =
            DateTime.getMarketIndex(cashGroup.maxMarketIndex, maturity, blockTime);
        uint256 timeWindow = getRateOracleTimeWindow(cashGroup);

        if (!idiosyncratic) {
            return Market.getOracleRate(cashGroup.currencyId, maturity, timeWindow, blockTime);
        } else {
            uint256 referenceTime = DateTime.getReferenceTime(blockTime);
            // DateTime.getMarketIndex returns the market that is past the maturity if idiosyncratic
            uint256 longMaturity = referenceTime.add(DateTime.getTradedMarket(marketIndex));
            uint256 longRate =
                Market.getOracleRate(cashGroup.currencyId, longMaturity, timeWindow, blockTime);

            uint256 shortMaturity;
            uint256 shortRate;
            if (marketIndex == 1) {
                // In this case the short market is the annualized asset supply rate
                shortMaturity = blockTime;
                shortRate = cashGroup.assetRate.getSupplyRate();
            } else {
                // Minimum value for marketIndex here is 2
                shortMaturity = referenceTime.add(DateTime.getTradedMarket(marketIndex - 1));

                shortRate = Market.getOracleRate(
                    cashGroup.currencyId,
                    shortMaturity,
                    timeWindow,
                    blockTime
                );
            }

            return interpolateOracleRate(shortMaturity, longMaturity, shortRate, longRate, maturity);
        }
    }

    function _getCashGroupStorageBytes(uint256 currencyId) private view returns (bytes32 data) {
        mapping(uint256 => bytes32) storage store = LibStorage.getCashGroupStorage();
        return store[currencyId];
    }

    /// @dev Helper method for validating maturities in ERC1155Action
    function getMaxMarketIndex(uint256 currencyId) internal view returns (uint8) {
        bytes32 data = _getCashGroupStorageBytes(currencyId);
        return uint8(data[MARKET_INDEX_BIT]);
    }

    /// @notice Checks all cash group settings for invalid values and sets them into storage
    function setCashGroupStorage(uint256 currencyId, CashGroupSettings calldata cashGroup)
        internal
    {
        // Due to the requirements of the yield curve we do not allow a cash group to have solely a 3 month market.
        // The reason is that borrowers will not have a further maturity to roll from their 3 month fixed to a 6 month
        // fixed. It also complicates the logic in the nToken initialization method. Additionally, we cannot have cash
        // groups with 0 market index, it has no effect.
        require(2 <= cashGroup.maxMarketIndex && cashGroup.maxMarketIndex <= Constants.MAX_TRADED_MARKET_INDEX,
            "CG: invalid market index"
        );
        require(
            cashGroup.reserveFeeShare <= Constants.PERCENTAGE_DECIMALS,
            "CG: invalid reserve share"
        );
        require(cashGroup.liquidityTokenHaircuts.length == cashGroup.maxMarketIndex);
        require(cashGroup.rateScalars.length == cashGroup.maxMarketIndex);
        // This is required so that fCash liquidation can proceed correctly
        require(cashGroup.liquidationfCashHaircut5BPS < cashGroup.fCashHaircut5BPS);
        require(cashGroup.liquidationDebtBuffer5BPS < cashGroup.debtBuffer5BPS);

        // Market indexes cannot decrease or they will leave fCash assets stranded in the future with no valuation curve
        uint8 previousMaxMarketIndex = getMaxMarketIndex(currencyId);
        require(
            previousMaxMarketIndex <= cashGroup.maxMarketIndex,
            "CG: market index cannot decrease"
        );

        // Per cash group settings
        bytes32 data =
            (bytes32(uint256(cashGroup.maxMarketIndex)) |
                (bytes32(uint256(cashGroup.rateOracleTimeWindow5Min)) << RATE_ORACLE_TIME_WINDOW) |
                (bytes32(uint256(cashGroup.totalFeeBPS)) << TOTAL_FEE) |
                (bytes32(uint256(cashGroup.reserveFeeShare)) << RESERVE_FEE_SHARE) |
                (bytes32(uint256(cashGroup.debtBuffer5BPS)) << DEBT_BUFFER) |
                (bytes32(uint256(cashGroup.fCashHaircut5BPS)) << FCASH_HAIRCUT) |
                (bytes32(uint256(cashGroup.settlementPenaltyRate5BPS)) << SETTLEMENT_PENALTY) |
                (bytes32(uint256(cashGroup.liquidationfCashHaircut5BPS)) <<
                    LIQUIDATION_FCASH_HAIRCUT) |
                (bytes32(uint256(cashGroup.liquidationDebtBuffer5BPS)) << LIQUIDATION_DEBT_BUFFER));

        // Per market group settings
        for (uint256 i = 0; i < cashGroup.liquidityTokenHaircuts.length; i++) {
            require(
                cashGroup.liquidityTokenHaircuts[i] <= Constants.PERCENTAGE_DECIMALS,
                "CG: invalid token haircut"
            );

            data =
                data |
                (bytes32(uint256(cashGroup.liquidityTokenHaircuts[i])) <<
                    (LIQUIDITY_TOKEN_HAIRCUT + i * 8));
        }

        for (uint256 i = 0; i < cashGroup.rateScalars.length; i++) {
            // Causes a divide by zero error
            require(cashGroup.rateScalars[i] != 0, "CG: invalid rate scalar");
            data = data | (bytes32(uint256(cashGroup.rateScalars[i])) << (RATE_SCALAR + i * 8));
        }

        mapping(uint256 => bytes32) storage store = LibStorage.getCashGroupStorage();
        store[currencyId] = data;
    }

    /// @notice Deserialize the cash group storage bytes into a user friendly object
    function deserializeCashGroupStorage(uint256 currencyId)
        internal
        view
        returns (CashGroupSettings memory)
    {
        bytes32 data = _getCashGroupStorageBytes(currencyId);
        uint8 maxMarketIndex = uint8(data[MARKET_INDEX_BIT]);
        uint8[] memory tokenHaircuts = new uint8[](uint256(maxMarketIndex));
        uint8[] memory rateScalars = new uint8[](uint256(maxMarketIndex));

        for (uint8 i = 0; i < maxMarketIndex; i++) {
            tokenHaircuts[i] = uint8(data[LIQUIDITY_TOKEN_HAIRCUT_FIRST_BIT - i]);
            rateScalars[i] = uint8(data[RATE_SCALAR_FIRST_BIT - i]);
        }

        return
            CashGroupSettings({
                maxMarketIndex: maxMarketIndex,
                rateOracleTimeWindow5Min: uint8(data[RATE_ORACLE_TIME_WINDOW_BIT]),
                totalFeeBPS: uint8(data[TOTAL_FEE_BIT]),
                reserveFeeShare: uint8(data[RESERVE_FEE_SHARE_BIT]),
                debtBuffer5BPS: uint8(data[DEBT_BUFFER_BIT]),
                fCashHaircut5BPS: uint8(data[FCASH_HAIRCUT_BIT]),
                settlementPenaltyRate5BPS: uint8(data[SETTLEMENT_PENALTY_BIT]),
                liquidationfCashHaircut5BPS: uint8(data[LIQUIDATION_FCASH_HAIRCUT_BIT]),
                liquidationDebtBuffer5BPS: uint8(data[LIQUIDATION_DEBT_BUFFER_BIT]),
                liquidityTokenHaircuts: tokenHaircuts,
                rateScalars: rateScalars
            });
    }

    function _buildCashGroup(uint16 currencyId, AssetRateParameters memory assetRate)
        private
        view
        returns (CashGroupParameters memory)
    {
        bytes32 data = _getCashGroupStorageBytes(currencyId);
        uint256 maxMarketIndex = uint8(data[MARKET_INDEX_BIT]);

        return
            CashGroupParameters({
                currencyId: currencyId,
                maxMarketIndex: maxMarketIndex,
                assetRate: assetRate,
                data: data
            });
    }

    /// @notice Builds a cash group using a view version of the asset rate
    function buildCashGroupView(uint16 currencyId)
        internal
        view
        returns (CashGroupParameters memory)
    {
        AssetRateParameters memory assetRate = AssetRate.buildAssetRateView(currencyId);
        return _buildCashGroup(currencyId, assetRate);
    }

    /// @notice Builds a cash group using a stateful version of the asset rate
    function buildCashGroupStateful(uint16 currencyId)
        internal
        returns (CashGroupParameters memory)
    {
        AssetRateParameters memory assetRate = AssetRate.buildAssetRateStateful(currencyId);
        return _buildCashGroup(currencyId, assetRate);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "../../global/Types.sol";
import "../../global/LibStorage.sol";
import "../../global/Constants.sol";
import "../../math/SafeInt256.sol";
import "../../../interfaces/notional/AssetRateAdapter.sol";

library AssetRate {
    using SafeInt256 for int256;
    event SetSettlementRate(uint256 indexed currencyId, uint256 indexed maturity, uint128 rate);

    // Asset rates are in 1e18 decimals (cToken exchange rates), internal balances
    // are in 1e8 decimals. Therefore we leave this as 1e18 / 1e8 = 1e10
    int256 private constant ASSET_RATE_DECIMAL_DIFFERENCE = 1e10;

    /// @notice Converts an internal asset cash value to its underlying token value.
    /// @param ar exchange rate object between asset and underlying
    /// @param assetBalance amount to convert to underlying
    function convertToUnderlying(AssetRateParameters memory ar, int256 assetBalance)
        internal
        pure
        returns (int256)
    {
        // Calculation here represents:
        // rate * balance * internalPrecision / rateDecimals * underlyingPrecision
        int256 underlyingBalance = ar.rate
            .mul(assetBalance)
            .div(ASSET_RATE_DECIMAL_DIFFERENCE)
            .div(ar.underlyingDecimals);

        return underlyingBalance;
    }

    /// @notice Converts an internal underlying cash value to its asset cash value
    /// @param ar exchange rate object between asset and underlying
    /// @param underlyingBalance amount to convert to asset cash, denominated in internal token precision
    function convertFromUnderlying(AssetRateParameters memory ar, int256 underlyingBalance)
        internal
        pure
        returns (int256)
    {
        // Calculation here represents:
        // rateDecimals * balance * underlyingPrecision / rate * internalPrecision
        int256 assetBalance = underlyingBalance
            .mul(ASSET_RATE_DECIMAL_DIFFERENCE)
            .mul(ar.underlyingDecimals)
            .div(ar.rate);

        return assetBalance;
    }

    /// @notice Returns the current per block supply rate, is used when calculating oracle rates
    /// for idiosyncratic fCash with a shorter duration than the 3 month maturity.
    function getSupplyRate(AssetRateParameters memory ar) internal view returns (uint256) {
        // If the rate oracle is not set, the asset is not interest bearing and has an oracle rate of zero.
        if (address(ar.rateOracle) == address(0)) return 0;

        uint256 rate = ar.rateOracle.getAnnualizedSupplyRate();
        // Zero supply rate is valid since this is an interest rate, we do not divide by
        // the supply rate so we do not get div by zero errors.
        require(rate >= 0); // dev: invalid supply rate

        return rate;
    }

    function _getAssetRateStorage(uint256 currencyId)
        private
        view
        returns (AssetRateAdapter rateOracle, uint8 underlyingDecimalPlaces)
    {
        mapping(uint256 => AssetRateStorage) storage store = LibStorage.getAssetRateStorage();
        AssetRateStorage storage ar = store[currencyId];
        rateOracle = AssetRateAdapter(ar.rateOracle);
        underlyingDecimalPlaces = ar.underlyingDecimalPlaces;
    }

    /// @notice Gets an asset rate using a view function, does not accrue interest so the
    /// exchange rate will not be up to date. Should only be used for non-stateful methods
    function _getAssetRateView(uint256 currencyId)
        private
        view
        returns (
            int256,
            AssetRateAdapter,
            uint8
        )
    {
        (AssetRateAdapter rateOracle, uint8 underlyingDecimalPlaces) = _getAssetRateStorage(currencyId);

        int256 rate;
        if (address(rateOracle) == address(0)) {
            // If no rate oracle is set, then set this to the identity
            rate = ASSET_RATE_DECIMAL_DIFFERENCE;
            // This will get raised to 10^x and return 1, will not end up with div by zero
            underlyingDecimalPlaces = 0;
        } else {
            rate = rateOracle.getExchangeRateView();
            require(rate > 0); // dev: invalid exchange rate
        }

        return (rate, rateOracle, underlyingDecimalPlaces);
    }

    /// @notice Gets an asset rate using a stateful function, accrues interest so the
    /// exchange rate will be up to date for the current block.
    function _getAssetRateStateful(uint256 currencyId)
        private
        returns (
            int256,
            AssetRateAdapter,
            uint8
        )
    {
        (AssetRateAdapter rateOracle, uint8 underlyingDecimalPlaces) = _getAssetRateStorage(currencyId);

        int256 rate;
        if (address(rateOracle) == address(0)) {
            // If no rate oracle is set, then set this to the identity
            rate = ASSET_RATE_DECIMAL_DIFFERENCE;
            // This will get raised to 10^x and return 1, will not end up with div by zero
            underlyingDecimalPlaces = 0;
        } else {
            rate = rateOracle.getExchangeRateStateful();
            require(rate > 0); // dev: invalid exchange rate
        }

        return (rate, rateOracle, underlyingDecimalPlaces);
    }

    /// @notice Returns an asset rate object using the view method
    function buildAssetRateView(uint256 currencyId)
        internal
        view
        returns (AssetRateParameters memory)
    {
        (int256 rate, AssetRateAdapter rateOracle, uint8 underlyingDecimalPlaces) =
            _getAssetRateView(currencyId);

        return
            AssetRateParameters({
                rateOracle: rateOracle,
                rate: rate,
                // No overflow, restricted on storage
                underlyingDecimals: int256(10**underlyingDecimalPlaces)
            });
    }

    /// @notice Returns an asset rate object using the stateful method
    function buildAssetRateStateful(uint256 currencyId)
        internal
        returns (AssetRateParameters memory)
    {
        (int256 rate, AssetRateAdapter rateOracle, uint8 underlyingDecimalPlaces) =
            _getAssetRateStateful(currencyId);

        return
            AssetRateParameters({
                rateOracle: rateOracle,
                rate: rate,
                // No overflow, restricted on storage
                underlyingDecimals: int256(10**underlyingDecimalPlaces)
            });
    }

    /// @dev Gets a settlement rate object
    function _getSettlementRateStorage(uint256 currencyId, uint256 maturity)
        private
        view
        returns (
            int256 settlementRate,
            uint8 underlyingDecimalPlaces
        )
    {
        mapping(uint256 => mapping(uint256 => SettlementRateStorage)) storage store = LibStorage.getSettlementRateStorage();
        SettlementRateStorage storage rateStorage = store[currencyId][maturity];
        settlementRate = rateStorage.settlementRate;
        underlyingDecimalPlaces = rateStorage.underlyingDecimalPlaces;
    }

    /// @notice Returns a settlement rate object using the view method
    function buildSettlementRateView(uint256 currencyId, uint256 maturity)
        internal
        view
        returns (AssetRateParameters memory)
    {
        // prettier-ignore
        (
            int256 settlementRate,
            uint8 underlyingDecimalPlaces
        ) = _getSettlementRateStorage(currencyId, maturity);

        // Asset exchange rates cannot be zero
        if (settlementRate == 0) {
            // If settlement rate has not been set then we need to fetch it
            // prettier-ignore
            (
                settlementRate,
                /* address */,
                underlyingDecimalPlaces
            ) = _getAssetRateView(currencyId);
        }

        return AssetRateParameters(
            AssetRateAdapter(address(0)),
            settlementRate,
            // No overflow, restricted on storage
            int256(10**underlyingDecimalPlaces)
        );
    }

    /// @notice Returns a settlement rate object and sets the rate if it has not been set yet
    function buildSettlementRateStateful(
        uint256 currencyId,
        uint256 maturity,
        uint256 blockTime
    ) internal returns (AssetRateParameters memory) {
        (int256 settlementRate, uint8 underlyingDecimalPlaces) =
            _getSettlementRateStorage(currencyId, maturity);

        if (settlementRate == 0) {
            // Settlement rate has not yet been set, set it in this branch
            AssetRateAdapter rateOracle;
            // If rate oracle == 0 then this will return the identity settlement rate
            // prettier-ignore
            (
                settlementRate,
                rateOracle,
                underlyingDecimalPlaces
            ) = _getAssetRateStateful(currencyId);

            if (address(rateOracle) != address(0)) {
                mapping(uint256 => mapping(uint256 => SettlementRateStorage)) storage store = LibStorage.getSettlementRateStorage();
                // Only need to set settlement rates when the rate oracle is set (meaning the asset token has
                // a conversion rate to an underlying). If not set then the asset cash always settles to underlying at a 1-1
                // rate since they are the same.
                require(0 < blockTime && maturity <= blockTime && blockTime <= type(uint40).max); // dev: settlement rate timestamp overflow
                require(0 < settlementRate && settlementRate <= type(uint128).max); // dev: settlement rate overflow

                SettlementRateStorage storage rateStorage = store[currencyId][maturity];
                rateStorage.blockTime = uint40(blockTime);
                rateStorage.settlementRate = uint128(settlementRate);
                rateStorage.underlyingDecimalPlaces = underlyingDecimalPlaces;
                emit SetSettlementRate(currencyId, maturity, uint128(settlementRate));
            }
        }

        return AssetRateParameters(
            AssetRateAdapter(address(0)),
            settlementRate,
            // No overflow, restricted on storage
            int256(10**underlyingDecimalPlaces)
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "./nTokenHandler.sol";
import "../../global/LibStorage.sol";
import "../../math/SafeInt256.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

library nTokenSupply {
    using SafeInt256 for int256;
    using SafeMath for uint256;

    /// @notice Retrieves stored nToken supply and related factors. Do not use accumulatedNOTEPerNToken for calculating
    /// incentives! Use `getUpdatedAccumulatedNOTEPerNToken` instead.
    function getStoredNTokenSupplyFactors(address tokenAddress)
        internal
        view
        returns (
            uint256 totalSupply,
            uint256 accumulatedNOTEPerNToken,
            uint256 lastAccumulatedTime
        )
    {
        mapping(address => nTokenTotalSupplyStorage) storage store = LibStorage.getNTokenTotalSupplyStorage();
        nTokenTotalSupplyStorage storage nTokenStorage = store[tokenAddress];
        totalSupply = nTokenStorage.totalSupply;
        // NOTE: DO NOT USE THIS RETURNED VALUE FOR CALCULATING INCENTIVES. The accumulatedNOTEPerNToken
        // must be updated given the block time. Use `getUpdatedAccumulatedNOTEPerNToken` instead
        accumulatedNOTEPerNToken = nTokenStorage.accumulatedNOTEPerNToken;
        lastAccumulatedTime = nTokenStorage.lastAccumulatedTime;
    }

    /// @notice Returns the updated accumulated NOTE per nToken for calculating incentives
    function getUpdatedAccumulatedNOTEPerNToken(address tokenAddress, uint256 blockTime)
        internal view
        returns (
            uint256 totalSupply,
            uint256 accumulatedNOTEPerNToken,
            uint256 lastAccumulatedTime
        )
    {
        (
            totalSupply,
            accumulatedNOTEPerNToken,
            lastAccumulatedTime
        ) = getStoredNTokenSupplyFactors(tokenAddress);

        // nToken totalSupply is never allowed to drop to zero but we check this here to avoid
        // divide by zero errors during initialization. Also ensure that lastAccumulatedTime is not
        // zero to avoid a massive accumulation amount on initialization.
        if (blockTime > lastAccumulatedTime && lastAccumulatedTime > 0 && totalSupply > 0) {
            // prettier-ignore
            (
                /* currencyId */,
                uint256 emissionRatePerYear,
                /* initializedTime */,
                /* assetArrayLength */,
                /* parameters */
            ) = nTokenHandler.getNTokenContext(tokenAddress);

            uint256 additionalNOTEAccumulatedPerNToken = _calculateAdditionalNOTE(
                // Emission rate is denominated in whole tokens, scale to 1e8 decimals here
                emissionRatePerYear.mul(uint256(Constants.INTERNAL_TOKEN_PRECISION)),
                // Time since last accumulation (overflow checked above)
                blockTime - lastAccumulatedTime,
                totalSupply
            );

            accumulatedNOTEPerNToken = accumulatedNOTEPerNToken.add(additionalNOTEAccumulatedPerNToken);
            require(accumulatedNOTEPerNToken < type(uint128).max); // dev: accumulated NOTE overflow
        }
    }

    /// @notice additionalNOTEPerNToken accumulated since last accumulation time in 1e18 precision
    function _calculateAdditionalNOTE(
        uint256 emissionRatePerYear,
        uint256 timeSinceLastAccumulation,
        uint256 totalSupply
    )
        private
        pure
        returns (uint256)
    {
        // If we use 18 decimal places as the accumulation precision then we will overflow uint128 when
        // a single nToken has accumulated 3.4 x 10^20 NOTE tokens. This isn't possible since the max
        // NOTE that can accumulate is 10^16 (100 million NOTE in 1e8 precision) so we should be safe
        // using 18 decimal places and uint128 storage slot

        // timeSinceLastAccumulation (SECONDS)
        // accumulatedNOTEPerSharePrecision (1e18)
        // emissionRatePerYear (INTERNAL_TOKEN_PRECISION)
        // DIVIDE BY
        // YEAR (SECONDS)
        // totalSupply (INTERNAL_TOKEN_PRECISION)
        return timeSinceLastAccumulation
            .mul(Constants.INCENTIVE_ACCUMULATION_PRECISION)
            .mul(emissionRatePerYear)
            .div(Constants.YEAR)
            // totalSupply > 0 is checked in the calling function
            .div(totalSupply);
    }

    /// @notice Updates the nToken token supply amount when minting or redeeming.
    /// @param tokenAddress address of the nToken
    /// @param netChange positive or negative change to the total nToken supply
    /// @param blockTime current block time
    /// @return accumulatedNOTEPerNToken updated to the given block time
    function changeNTokenSupply(
        address tokenAddress,
        int256 netChange,
        uint256 blockTime
    ) internal returns (uint256) {
        (
            uint256 totalSupply,
            uint256 accumulatedNOTEPerNToken,
            /* uint256 lastAccumulatedTime */
        ) = getUpdatedAccumulatedNOTEPerNToken(tokenAddress, blockTime);

        // Update storage variables
        mapping(address => nTokenTotalSupplyStorage) storage store = LibStorage.getNTokenTotalSupplyStorage();
        nTokenTotalSupplyStorage storage nTokenStorage = store[tokenAddress];

        int256 newTotalSupply = int256(totalSupply).add(netChange);
        // We allow newTotalSupply to equal zero here even though it is prevented from being redeemed down to
        // exactly zero by other internal logic inside nTokenRedeem. This is meant to be purely an overflow check.
        require(0 <= newTotalSupply && uint256(newTotalSupply) < type(uint96).max); // dev: nToken supply overflow

        nTokenStorage.totalSupply = uint96(newTotalSupply);
        // NOTE: overflow checked inside getUpdatedAccumulatedNOTEPerNToken so that behavior here mirrors what
        // the user would see if querying the view function
        nTokenStorage.accumulatedNOTEPerNToken = uint128(accumulatedNOTEPerNToken);

        require(blockTime < type(uint32).max); // dev: block time overflow
        nTokenStorage.lastAccumulatedTime = uint32(blockTime);

        return accumulatedNOTEPerNToken;
    }

    /// @notice Called by governance to set the new emission rate
    function setIncentiveEmissionRate(address tokenAddress, uint32 newEmissionsRate, uint256 blockTime) internal {
        // Ensure that the accumulatedNOTEPerNToken updates to the current block time before we update the
        // emission rate
        changeNTokenSupply(tokenAddress, 0, blockTime);

        mapping(address => nTokenContext) storage store = LibStorage.getNTokenContextStorage();
        nTokenContext storage context = store[tokenAddress];
        context.incentiveAnnualEmissionRate = newEmissionsRate;
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "./nTokenSupply.sol";
import "../markets/CashGroup.sol";
import "../markets/AssetRate.sol";
import "../portfolio/PortfolioHandler.sol";
import "../balances/BalanceHandler.sol";
import "../../global/LibStorage.sol";
import "../../math/SafeInt256.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

library nTokenHandler {
    using SafeInt256 for int256;

    /// @dev Mirror of the value in LibStorage, solidity compiler does not allow assigning
    /// two constants to each other.
    uint256 private constant NUM_NTOKEN_MARKET_FACTORS = 14;

    /// @notice Returns an account context object that is specific to nTokens.
    function getNTokenContext(address tokenAddress)
        internal
        view
        returns (
            uint16 currencyId,
            uint256 incentiveAnnualEmissionRate,
            uint256 lastInitializedTime,
            uint8 assetArrayLength,
            bytes5 parameters
        )
    {
        mapping(address => nTokenContext) storage store = LibStorage.getNTokenContextStorage();
        nTokenContext storage context = store[tokenAddress];

        currencyId = context.currencyId;
        incentiveAnnualEmissionRate = context.incentiveAnnualEmissionRate;
        lastInitializedTime = context.lastInitializedTime;
        assetArrayLength = context.assetArrayLength;
        parameters = context.nTokenParameters;
    }

    /// @notice Returns the nToken token address for a given currency
    function nTokenAddress(uint256 currencyId) internal view returns (address tokenAddress) {
        mapping(uint256 => address) storage store = LibStorage.getNTokenAddressStorage();
        return store[currencyId];
    }

    /// @notice Called by governance to set the nToken token address and its reverse lookup. Cannot be
    /// reset once this is set.
    function setNTokenAddress(uint16 currencyId, address tokenAddress) internal {
        mapping(uint256 => address) storage addressStore = LibStorage.getNTokenAddressStorage();
        require(addressStore[currencyId] == address(0), "PT: token address exists");

        mapping(address => nTokenContext) storage contextStore = LibStorage.getNTokenContextStorage();
        nTokenContext storage context = contextStore[tokenAddress];
        require(context.currencyId == 0, "PT: currency exists");

        // This will initialize all other context slots to zero
        context.currencyId = currencyId;
        addressStore[currencyId] = tokenAddress;
    }

    /// @notice Set nToken token collateral parameters
    function setNTokenCollateralParameters(
        address tokenAddress,
        uint8 residualPurchaseIncentive10BPS,
        uint8 pvHaircutPercentage,
        uint8 residualPurchaseTimeBufferHours,
        uint8 cashWithholdingBuffer10BPS,
        uint8 liquidationHaircutPercentage
    ) internal {
        mapping(address => nTokenContext) storage store = LibStorage.getNTokenContextStorage();
        nTokenContext storage context = store[tokenAddress];

        require(liquidationHaircutPercentage <= Constants.PERCENTAGE_DECIMALS, "Invalid haircut");
        // The pv haircut percentage must be less than the liquidation percentage or else liquidators will not
        // get profit for liquidating nToken.
        require(pvHaircutPercentage < liquidationHaircutPercentage, "Invalid pv haircut");
        // Ensure that the cash withholding buffer is greater than the residual purchase incentive or
        // the nToken may not have enough cash to pay accounts to buy its negative ifCash
        require(residualPurchaseIncentive10BPS <= cashWithholdingBuffer10BPS, "Invalid discounts");

        bytes5 parameters =
            (bytes5(uint40(residualPurchaseIncentive10BPS)) |
            (bytes5(uint40(pvHaircutPercentage)) << 8) |
            (bytes5(uint40(residualPurchaseTimeBufferHours)) << 16) |
            (bytes5(uint40(cashWithholdingBuffer10BPS)) << 24) |
            (bytes5(uint40(liquidationHaircutPercentage)) << 32));

        // Set the parameters
        context.nTokenParameters = parameters;
    }

    /// @notice Sets a secondary rewarder contract on an nToken so that incentives can come from a different
    /// contract, aside from the native NOTE token incentives.
    function setSecondaryRewarder(
        uint16 currencyId,
        IRewarder rewarder
    ) internal {
        address tokenAddress = nTokenAddress(currencyId);
        // nToken must exist for a secondary rewarder
        require(tokenAddress != address(0));
        mapping(address => nTokenContext) storage store = LibStorage.getNTokenContextStorage();
        nTokenContext storage context = store[tokenAddress];

        // Setting the rewarder to address(0) will disable it. We use a context setting here so that
        // we can save a storage read before getting the rewarder
        context.hasSecondaryRewarder = (address(rewarder) != address(0));
        LibStorage.getSecondaryIncentiveRewarder()[tokenAddress] = rewarder;
    }

    /// @notice Returns the secondary rewarder if it is set
    function getSecondaryRewarder(address tokenAddress) internal view returns (IRewarder) {
        mapping(address => nTokenContext) storage store = LibStorage.getNTokenContextStorage();
        nTokenContext storage context = store[tokenAddress];
        
        if (context.hasSecondaryRewarder) {
            return LibStorage.getSecondaryIncentiveRewarder()[tokenAddress];
        } else {
            return IRewarder(address(0));
        }
    }

    function setArrayLengthAndInitializedTime(
        address tokenAddress,
        uint8 arrayLength,
        uint256 lastInitializedTime
    ) internal {
        require(lastInitializedTime >= 0 && uint256(lastInitializedTime) < type(uint32).max); // dev: next settle time overflow
        mapping(address => nTokenContext) storage store = LibStorage.getNTokenContextStorage();
        nTokenContext storage context = store[tokenAddress];
        context.lastInitializedTime = uint32(lastInitializedTime);
        context.assetArrayLength = arrayLength;
    }

    /// @notice Returns the array of deposit shares and leverage thresholds for nTokens
    function getDepositParameters(uint256 currencyId, uint256 maxMarketIndex)
        internal
        view
        returns (int256[] memory depositShares, int256[] memory leverageThresholds)
    {
        mapping(uint256 => uint32[NUM_NTOKEN_MARKET_FACTORS]) storage store = LibStorage.getNTokenDepositStorage();
        uint32[NUM_NTOKEN_MARKET_FACTORS] storage depositParameters = store[currencyId];
        (depositShares, leverageThresholds) = _getParameters(depositParameters, maxMarketIndex, false);
    }

    /// @notice Sets the deposit parameters
    /// @dev We pack the values in alternating between the two parameters into either one or two
    // storage slots depending on the number of markets. This is to save storage reads when we use the parameters.
    function setDepositParameters(
        uint256 currencyId,
        uint32[] calldata depositShares,
        uint32[] calldata leverageThresholds
    ) internal {
        require(
            depositShares.length <= Constants.MAX_TRADED_MARKET_INDEX,
            "PT: deposit share length"
        );
        require(depositShares.length == leverageThresholds.length, "PT: leverage share length");

        uint256 shareSum;
        for (uint256 i; i < depositShares.length; i++) {
            // This cannot overflow in uint 256 with 9 max slots
            shareSum = shareSum + depositShares[i];
            require(
                leverageThresholds[i] > 0 && leverageThresholds[i] < Constants.RATE_PRECISION,
                "PT: leverage threshold"
            );
        }

        // Total deposit share must add up to 100%
        require(shareSum == uint256(Constants.DEPOSIT_PERCENT_BASIS), "PT: deposit shares sum");

        mapping(uint256 => uint32[NUM_NTOKEN_MARKET_FACTORS]) storage store = LibStorage.getNTokenDepositStorage();
        uint32[NUM_NTOKEN_MARKET_FACTORS] storage depositParameters = store[currencyId];
        _setParameters(depositParameters, depositShares, leverageThresholds);
    }

    /// @notice Sets the initialization parameters for the markets, these are read only when markets
    /// are initialized
    function setInitializationParameters(
        uint256 currencyId,
        uint32[] calldata annualizedAnchorRates,
        uint32[] calldata proportions
    ) internal {
        require(annualizedAnchorRates.length <= Constants.MAX_TRADED_MARKET_INDEX, "PT: annualized anchor rates length");
        require(proportions.length == annualizedAnchorRates.length, "PT: proportions length");

        for (uint256 i; i < proportions.length; i++) {
            // Proportions must be between zero and the rate precision
            require(annualizedAnchorRates[i] > 0, "NT: anchor rate zero");
            require(
                proportions[i] > 0 && proportions[i] < Constants.RATE_PRECISION,
                "PT: invalid proportion"
            );
        }

        mapping(uint256 => uint32[NUM_NTOKEN_MARKET_FACTORS]) storage store = LibStorage.getNTokenInitStorage();
        uint32[NUM_NTOKEN_MARKET_FACTORS] storage initParameters = store[currencyId];
        _setParameters(initParameters, annualizedAnchorRates, proportions);
    }

    /// @notice Returns the array of initialization parameters for a given currency.
    function getInitializationParameters(uint256 currencyId, uint256 maxMarketIndex)
        internal
        view
        returns (int256[] memory annualizedAnchorRates, int256[] memory proportions)
    {
        mapping(uint256 => uint32[NUM_NTOKEN_MARKET_FACTORS]) storage store = LibStorage.getNTokenInitStorage();
        uint32[NUM_NTOKEN_MARKET_FACTORS] storage initParameters = store[currencyId];
        (annualizedAnchorRates, proportions) = _getParameters(initParameters, maxMarketIndex, true);
    }

    function _getParameters(
        uint32[NUM_NTOKEN_MARKET_FACTORS] storage slot,
        uint256 maxMarketIndex,
        bool noUnset
    ) private view returns (int256[] memory, int256[] memory) {
        uint256 index = 0;
        int256[] memory array1 = new int256[](maxMarketIndex);
        int256[] memory array2 = new int256[](maxMarketIndex);
        for (uint256 i; i < maxMarketIndex; i++) {
            array1[i] = slot[index];
            index++;
            array2[i] = slot[index];
            index++;

            if (noUnset) {
                require(array1[i] > 0 && array2[i] > 0, "PT: init value zero");
            }
        }

        return (array1, array2);
    }

    function _setParameters(
        uint32[NUM_NTOKEN_MARKET_FACTORS] storage slot,
        uint32[] calldata array1,
        uint32[] calldata array2
    ) private {
        uint256 index = 0;
        for (uint256 i = 0; i < array1.length; i++) {
            slot[index] = array1[i];
            index++;

            slot[index] = array2[i];
            index++;
        }
    }

    function loadNTokenPortfolioNoCashGroup(nTokenPortfolio memory nToken, uint16 currencyId)
        internal
        view
    {
        nToken.tokenAddress = nTokenAddress(currencyId);
        // prettier-ignore
        (
            /* currencyId */,
            /* incentiveRate */,
            uint256 lastInitializedTime,
            uint8 assetArrayLength,
            bytes5 parameters
        ) = getNTokenContext(nToken.tokenAddress);

        // prettier-ignore
        (
            uint256 totalSupply,
            /* accumulatedNOTEPerNToken */,
            /* lastAccumulatedTime */
        ) = nTokenSupply.getStoredNTokenSupplyFactors(nToken.tokenAddress);

        nToken.lastInitializedTime = lastInitializedTime;
        nToken.totalSupply = int256(totalSupply);
        nToken.parameters = parameters;

        nToken.portfolioState = PortfolioHandler.buildPortfolioState(
            nToken.tokenAddress,
            assetArrayLength,
            0
        );

        // prettier-ignore
        (
            nToken.cashBalance,
            /* nTokenBalance */,
            /* lastClaimTime */,
            /* accountIncentiveDebt */
        ) = BalanceHandler.getBalanceStorage(nToken.tokenAddress, currencyId);
    }

    /// @notice Uses buildCashGroupStateful
    function loadNTokenPortfolioStateful(nTokenPortfolio memory nToken, uint16 currencyId)
        internal
    {
        loadNTokenPortfolioNoCashGroup(nToken, currencyId);
        nToken.cashGroup = CashGroup.buildCashGroupStateful(currencyId);
    }

    /// @notice Uses buildCashGroupView
    function loadNTokenPortfolioView(nTokenPortfolio memory nToken, uint16 currencyId)
        internal
        view
    {
        loadNTokenPortfolioNoCashGroup(nToken, currencyId);
        nToken.cashGroup = CashGroup.buildCashGroupView(currencyId);
    }

    /// @notice Returns the next settle time for the nToken which is 1 quarter away
    function getNextSettleTime(nTokenPortfolio memory nToken) internal pure returns (uint256) {
        if (nToken.lastInitializedTime == 0) return 0;
        return DateTime.getReferenceTime(nToken.lastInitializedTime) + Constants.QUARTER;
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "../global/Constants.sol";

library SafeInt256 {
    int256 private constant _INT256_MIN = type(int256).min;

    /// @dev Returns the multiplication of two signed integers, reverting on
    /// overflow.

    /// Counterpart to Solidity's `*` operator.

    /// Requirements:

    /// - Multiplication cannot overflow.

    function mul(int256 a, int256 b) internal pure returns (int256 c) {
        c = a * b;
        if (a == -1) require (b == 0 || c / b == a);
        else require (a == 0 || c / a == b);
    }

    /// @dev Returns the integer division of two signed integers. Reverts on
    /// division by zero. The result is rounded towards zero.

    /// Counterpart to Solidity's `/` operator. Note: this function uses a
    /// `revert` opcode (which leaves remaining gas untouched) while Solidity
    /// uses an invalid opcode to revert (consuming all remaining gas).

    /// Requirements:

    /// - The divisor cannot be zero.

    function div(int256 a, int256 b) internal pure returns (int256 c) {
        require(!(b == -1 && a == _INT256_MIN)); // dev: int256 div overflow
        // NOTE: solidity will automatically revert on divide by zero
        c = a / b;
    }

    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        //  taken from uniswap v3
        require((z = x - y) <= x == (y >= 0));
    }

    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    function neg(int256 x) internal pure returns (int256 y) {
        return mul(-1, x);
    }

    function abs(int256 x) internal pure returns (int256) {
        if (x < 0) return neg(x);
        else return x;
    }

    function subNoNeg(int256 x, int256 y) internal pure returns (int256 z) {
        z = sub(x, y);
        require(z >= 0); // dev: int256 sub to negative

        return z;
    }

    /// @dev Calculates x * RATE_PRECISION / y while checking overflows
    function divInRatePrecision(int256 x, int256 y) internal pure returns (int256) {
        return div(mul(x, Constants.RATE_PRECISION), y);
    }

    /// @dev Calculates x * y / RATE_PRECISION while checking overflows
    function mulInRatePrecision(int256 x, int256 y) internal pure returns (int256) {
        return div(mul(x, y), Constants.RATE_PRECISION);
    }

    function toUint(int256 x) internal pure returns (uint256) {
        require(x >= 0);
        return uint256(x);
    }

    function toInt(uint256 x) internal pure returns (int256) {
        require (x <= uint256(type(int256).max)); // dev: toInt overflow
        return int256(x);
    }

    function max(int256 x, int256 y) internal pure returns (int256) {
        return x > y ? x : y;
    }

    function min(int256 x, int256 y) internal pure returns (int256) {
        return x < y ? x : y;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "../../contracts/global/Types.sol";

interface NotionalCalculations {
    function calculateNTokensToMint(uint16 currencyId, uint88 amountToDepositExternalPrecision)
        external
        view
        returns (uint256);

    function getfCashAmountGivenCashAmount(
        uint16 currencyId,
        int88 netCashToAccount,
        uint256 marketIndex,
        uint256 blockTime
    ) external view returns (int256);

    function getCashAmountGivenfCashAmount(
        uint16 currencyId,
        int88 fCashAmount,
        uint256 marketIndex,
        uint256 blockTime
    ) external view returns (int256, int256);

    function nTokenGetClaimableIncentives(address account, uint256 blockTime)
        external
        view
        returns (uint256);

    function getPresentfCashValue(
        uint16 currencyId,
        uint256 maturity,
        int256 notional,
        uint256 blockTime,
        bool riskAdjusted
    ) external view returns (int256 presentValue);

    function getMarketIndex(
        uint256 maturity,
        uint256 blockTime
    ) external pure returns (uint8 marketIndex);

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

    function getDepositFromfCashLend(
        uint16 currencyId,
        uint256 fCashAmount,
        uint256 maturity,
        uint32 minLendRate,
        uint256 blockTime
    ) external view returns (
        uint256 depositAmountUnderlying,
        uint256 depositAmountAsset,
        uint8 marketIndex,
        bytes32 encodedTrade
    );

    function getPrincipalFromfCashBorrow(
        uint16 currencyId,
        uint256 fCashBorrow,
        uint256 maturity,
        uint32 maxBorrowRate,
        uint256 blockTime
    ) external view returns (
        uint256 borrowAmountUnderlying,
        uint256 borrowAmountAsset,
        uint8 marketIndex,
        bytes32 encodedTrade
    );

    function convertCashBalanceToExternal(
        uint16 currencyId,
        int256 cashBalanceInternal,
        bool useUnderlying
    ) external view returns (int256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/// @title All shared constants for the Notional system should be declared here.
library Constants {
    uint8 internal constant CETH_DECIMAL_PLACES = 8;

    // Token precision used for all internal balances, TokenHandler library ensures that we
    // limit the dust amount caused by precision mismatches
    int256 internal constant INTERNAL_TOKEN_PRECISION = 1e8;
    uint256 internal constant INCENTIVE_ACCUMULATION_PRECISION = 1e18;

    // ETH will be initialized as the first currency
    uint256 internal constant ETH_CURRENCY_ID = 1;
    uint8 internal constant ETH_DECIMAL_PLACES = 18;
    int256 internal constant ETH_DECIMALS = 1e18;
    // Used to prevent overflow when converting decimal places to decimal precision values via
    // 10**decimalPlaces. This is a safe value for int256 and uint256 variables. We apply this
    // constraint when storing decimal places in governance.
    uint256 internal constant MAX_DECIMAL_PLACES = 36;

    // Address of the reserve account
    address internal constant RESERVE = address(0);

    // Most significant bit
    bytes32 internal constant MSB =
        0x8000000000000000000000000000000000000000000000000000000000000000;

    // Each bit set in this mask marks where an active market should be in the bitmap
    // if the first bit refers to the reference time. Used to detect idiosyncratic
    // fcash in the nToken accounts
    bytes32 internal constant ACTIVE_MARKETS_MASK = (
        MSB >> ( 90 - 1) | // 3 month
        MSB >> (105 - 1) | // 6 month
        MSB >> (135 - 1) | // 1 year
        MSB >> (147 - 1) | // 2 year
        MSB >> (183 - 1) | // 5 year
        MSB >> (211 - 1) | // 10 year
        MSB >> (251 - 1)   // 20 year
    );

    // Basis for percentages
    int256 internal constant PERCENTAGE_DECIMALS = 100;
    // Max number of traded markets, also used as the maximum number of assets in a portfolio array
    uint256 internal constant MAX_TRADED_MARKET_INDEX = 7;
    // Max number of fCash assets in a bitmap, this is based on the gas costs of calculating free collateral
    // for a bitmap portfolio
    uint256 internal constant MAX_BITMAP_ASSETS = 20;
    uint256 internal constant FIVE_MINUTES = 300;

    // Internal date representations, note we use a 6/30/360 week/month/year convention here
    uint256 internal constant DAY = 86400;
    // We use six day weeks to ensure that all time references divide evenly
    uint256 internal constant WEEK = DAY * 6;
    uint256 internal constant MONTH = WEEK * 5;
    uint256 internal constant QUARTER = MONTH * 3;
    uint256 internal constant YEAR = QUARTER * 4;
    
    // These constants are used in DateTime.sol
    uint256 internal constant DAYS_IN_WEEK = 6;
    uint256 internal constant DAYS_IN_MONTH = 30;
    uint256 internal constant DAYS_IN_QUARTER = 90;

    // Offsets for each time chunk denominated in days
    uint256 internal constant MAX_DAY_OFFSET = 90;
    uint256 internal constant MAX_WEEK_OFFSET = 360;
    uint256 internal constant MAX_MONTH_OFFSET = 2160;
    uint256 internal constant MAX_QUARTER_OFFSET = 7650;

    // Offsets for each time chunk denominated in bits
    uint256 internal constant WEEK_BIT_OFFSET = 90;
    uint256 internal constant MONTH_BIT_OFFSET = 135;
    uint256 internal constant QUARTER_BIT_OFFSET = 195;

    // This is a constant that represents the time period that all rates are normalized by, 360 days
    uint256 internal constant IMPLIED_RATE_TIME = 360 * DAY;
    // Number of decimal places that rates are stored in, equals 100%
    int256 internal constant RATE_PRECISION = 1e9;
    // One basis point in RATE_PRECISION terms
    uint256 internal constant BASIS_POINT = uint256(RATE_PRECISION / 10000);
    // Used to when calculating the amount to deleverage of a market when minting nTokens
    uint256 internal constant DELEVERAGE_BUFFER = 300 * BASIS_POINT;
    // Used for scaling cash group factors
    uint256 internal constant FIVE_BASIS_POINTS = 5 * BASIS_POINT;
    // Used for residual purchase incentive and cash withholding buffer
    uint256 internal constant TEN_BASIS_POINTS = 10 * BASIS_POINT;

    // This is the ABDK64x64 representation of RATE_PRECISION
    // RATE_PRECISION_64x64 = ABDKMath64x64.fromUint(RATE_PRECISION)
    int128 internal constant RATE_PRECISION_64x64 = 0x3b9aca000000000000000000;
    int128 internal constant LOG_RATE_PRECISION_64x64 = 382276781265598821176;
    // Limit the market proportion so that borrowing cannot hit extremely high interest rates
    int256 internal constant MAX_MARKET_PROPORTION = RATE_PRECISION * 99 / 100;

    uint8 internal constant FCASH_ASSET_TYPE = 1;
    // Liquidity token asset types are 1 + marketIndex (where marketIndex is 1-indexed)
    uint8 internal constant MIN_LIQUIDITY_TOKEN_INDEX = 2;
    uint8 internal constant MAX_LIQUIDITY_TOKEN_INDEX = 8;

    // Used for converting bool to bytes1, solidity does not have a native conversion
    // method for this
    bytes1 internal constant BOOL_FALSE = 0x00;
    bytes1 internal constant BOOL_TRUE = 0x01;

    // Account context flags
    bytes1 internal constant HAS_ASSET_DEBT = 0x01;
    bytes1 internal constant HAS_CASH_DEBT = 0x02;
    bytes2 internal constant ACTIVE_IN_PORTFOLIO = 0x8000;
    bytes2 internal constant ACTIVE_IN_BALANCES = 0x4000;
    bytes2 internal constant UNMASK_FLAGS = 0x3FFF;
    uint16 internal constant MAX_CURRENCIES = uint16(UNMASK_FLAGS);

    // Equal to 100% of all deposit amounts for nToken liquidity across fCash markets.
    int256 internal constant DEPOSIT_PERCENT_BASIS = 1e8;

    // nToken Parameters: there are offsets in the nTokenParameters bytes6 variable returned
    // in nTokenHandler. Each constant represents a position in the byte array.
    uint8 internal constant LIQUIDATION_HAIRCUT_PERCENTAGE = 0;
    uint8 internal constant CASH_WITHHOLDING_BUFFER = 1;
    uint8 internal constant RESIDUAL_PURCHASE_TIME_BUFFER = 2;
    uint8 internal constant PV_HAIRCUT_PERCENTAGE = 3;
    uint8 internal constant RESIDUAL_PURCHASE_INCENTIVE = 4;

    // Liquidation parameters
    // Default percentage of collateral that a liquidator is allowed to liquidate, will be higher if the account
    // requires more collateral to be liquidated
    int256 internal constant DEFAULT_LIQUIDATION_PORTION = 40;
    // Percentage of local liquidity token cash claim delivered to the liquidator for liquidating liquidity tokens
    int256 internal constant TOKEN_REPO_INCENTIVE_PERCENT = 30;

    // Pause Router liquidation enabled states
    bytes1 internal constant LOCAL_CURRENCY_ENABLED = 0x01;
    bytes1 internal constant COLLATERAL_CURRENCY_ENABLED = 0x02;
    bytes1 internal constant LOCAL_FCASH_ENABLED = 0x04;
    bytes1 internal constant CROSS_CURRENCY_FCASH_ENABLED = 0x08;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "./nTokenHandler.sol";
import "../portfolio/BitmapAssetsHandler.sol";
import "../../math/SafeInt256.sol";
import "../../math/Bitmap.sol";

library nTokenCalculations {
    using Bitmap for bytes32;
    using SafeInt256 for int256;
    using AssetRate for AssetRateParameters;
    using CashGroup for CashGroupParameters;

    /// @notice Returns the nToken present value denominated in asset terms.
    function getNTokenAssetPV(nTokenPortfolio memory nToken, uint256 blockTime)
        internal
        view
        returns (int256)
    {
        int256 totalAssetPV;
        int256 totalUnderlyingPV;

        {
            uint256 nextSettleTime = nTokenHandler.getNextSettleTime(nToken);
            // If the first asset maturity has passed (the 3 month), this means that all the LTs must
            // be settled except the 6 month (which is now the 3 month). We don't settle LTs except in
            // initialize markets so we calculate the cash value of the portfolio here.
            if (nextSettleTime <= blockTime) {
                // NOTE: this condition should only be present for a very short amount of time, which is the window between
                // when the markets are no longer tradable at quarter end and when the new markets have been initialized.
                // We time travel back to one second before maturity to value the liquidity tokens. Although this value is
                // not strictly correct the different should be quite slight. We do this to ensure that free collateral checks
                // for withdraws and liquidations can still be processed. If this condition persists for a long period of time then
                // the entire protocol will have serious problems as markets will not be tradable.
                blockTime = nextSettleTime - 1;
            }
        }

        // This is the total value in liquid assets
        (int256 totalAssetValueInMarkets, /* int256[] memory netfCash */) = getNTokenMarketValue(nToken, blockTime);

        // Then get the total value in any idiosyncratic fCash residuals (if they exist)
        bytes32 ifCashBits = getNTokenifCashBits(
            nToken.tokenAddress,
            nToken.cashGroup.currencyId,
            nToken.lastInitializedTime,
            blockTime,
            nToken.cashGroup.maxMarketIndex
        );

        int256 ifCashResidualUnderlyingPV = 0;
        if (ifCashBits != 0) {
            // Non idiosyncratic residuals have already been accounted for
            (ifCashResidualUnderlyingPV, /* hasDebt */) = BitmapAssetsHandler.getNetPresentValueFromBitmap(
                nToken.tokenAddress,
                nToken.cashGroup.currencyId,
                nToken.lastInitializedTime,
                blockTime,
                nToken.cashGroup,
                false, // nToken present value calculation does not use risk adjusted values
                ifCashBits
            );
        }

        // Return the total present value denominated in asset terms
        return totalAssetValueInMarkets
            .add(nToken.cashGroup.assetRate.convertFromUnderlying(ifCashResidualUnderlyingPV))
            .add(nToken.cashBalance);
    }

    /**
     * @notice Handles the case when liquidity tokens should be withdrawn in proportion to their amounts
     * in the market. This will be the case when there is no idiosyncratic fCash residuals in the nToken
     * portfolio.
     * @param nToken portfolio object for nToken
     * @param nTokensToRedeem amount of nTokens to redeem
     * @param tokensToWithdraw array of liquidity tokens to withdraw from each market, proportional to
     * the account's share of the total supply
     * @param netfCash an empty array to hold net fCash values calculated later when the tokens are actually
     * withdrawn from markets
     */
    function _getProportionalLiquidityTokens(
        nTokenPortfolio memory nToken,
        int256 nTokensToRedeem
    ) private pure returns (int256[] memory tokensToWithdraw, int256[] memory netfCash) {
        uint256 numMarkets = nToken.portfolioState.storedAssets.length;
        tokensToWithdraw = new int256[](numMarkets);
        netfCash = new int256[](numMarkets);

        for (uint256 i = 0; i < numMarkets; i++) {
            int256 totalTokens = nToken.portfolioState.storedAssets[i].notional;
            tokensToWithdraw[i] = totalTokens.mul(nTokensToRedeem).div(nToken.totalSupply);
        }
    }

    /**
     * @notice Returns the number of liquidity tokens to withdraw from each market if the nToken
     * has idiosyncratic residuals during nToken redeem. In this case the redeemer will take
     * their cash from the rest of the fCash markets, redeeming around the nToken.
     * @param nToken portfolio object for nToken
     * @param nTokensToRedeem amount of nTokens to redeem
     * @param blockTime block time
     * @param ifCashBits the bits in the bitmap that represent ifCash assets
     * @return tokensToWithdraw array of tokens to withdraw from each corresponding market
     * @return netfCash array of netfCash amounts to go back to the account
     */
    function getLiquidityTokenWithdraw(
        nTokenPortfolio memory nToken,
        int256 nTokensToRedeem,
        uint256 blockTime,
        bytes32 ifCashBits
    ) internal view returns (int256[] memory, int256[] memory) {
        // If there are no ifCash bits set then this will just return the proportion of all liquidity tokens
        if (ifCashBits == 0) return _getProportionalLiquidityTokens(nToken, nTokensToRedeem);

        (
            int256 totalAssetValueInMarkets,
            int256[] memory netfCash
        ) = getNTokenMarketValue(nToken, blockTime);
        int256[] memory tokensToWithdraw = new int256[](netfCash.length);

        // NOTE: this total portfolio asset value does not include any cash balance the nToken may hold.
        // The redeemer will always get a proportional share of this cash balance and therefore we don't
        // need to account for it here when we calculate the share of liquidity tokens to withdraw. We are
        // only concerned with the nToken's portfolio assets in this method.
        int256 totalPortfolioAssetValue;
        {
            // Returns the risk adjusted net present value for the idiosyncratic residuals
            (int256 underlyingPV, /* hasDebt */) = BitmapAssetsHandler.getNetPresentValueFromBitmap(
                nToken.tokenAddress,
                nToken.cashGroup.currencyId,
                nToken.lastInitializedTime,
                blockTime,
                nToken.cashGroup,
                true, // use risk adjusted here to assess a penalty for withdrawing around the residual
                ifCashBits
            );

            // NOTE: we do not include cash balance here because the account will always take their share
            // of the cash balance regardless of the residuals
            totalPortfolioAssetValue = totalAssetValueInMarkets.add(
                nToken.cashGroup.assetRate.convertFromUnderlying(underlyingPV)
            );
        }

        // Loops through each liquidity token and calculates how much the redeemer can withdraw to get
        // the requisite amount of present value after adjusting for the ifCash residual value that is
        // not accessible via redemption.
        for (uint256 i = 0; i < tokensToWithdraw.length; i++) {
            int256 totalTokens = nToken.portfolioState.storedAssets[i].notional;
            // Redeemer's baseline share of the liquidity tokens based on total supply:
            //      redeemerShare = totalTokens * nTokensToRedeem / totalSupply
            // Scalar factor to account for residual value (need to inflate the tokens to withdraw
            // proportional to the value locked up in ifCash residuals):
            //      scaleFactor = totalPortfolioAssetValue / totalAssetValueInMarkets
            // Final math equals:
            //      tokensToWithdraw = redeemerShare * scalarFactor
            //      tokensToWithdraw = (totalTokens * nTokensToRedeem * totalPortfolioAssetValue)
            //         / (totalAssetValueInMarkets * totalSupply)
            tokensToWithdraw[i] = totalTokens
                .mul(nTokensToRedeem)
                .mul(totalPortfolioAssetValue);

            tokensToWithdraw[i] = tokensToWithdraw[i]
                .div(totalAssetValueInMarkets)
                .div(nToken.totalSupply);

            // This is the share of net fcash that will be credited back to the account
            netfCash[i] = netfCash[i].mul(tokensToWithdraw[i]).div(totalTokens);
        }

        return (tokensToWithdraw, netfCash);
    }

    /// @notice Returns the value of all the liquid assets in an nToken portfolio which are defined by
    /// the liquidity tokens held in each market and their corresponding fCash positions. The formula
    /// can be described as:
    /// totalAssetValue = sum_per_liquidity_token(cashClaim + presentValue(netfCash))
    ///     where netfCash = fCashClaim + fCash
    ///     and fCash refers the the fCash position at the corresponding maturity
    function getNTokenMarketValue(nTokenPortfolio memory nToken, uint256 blockTime)
        internal
        view
        returns (int256 totalAssetValue, int256[] memory netfCash)
    {
        uint256 numMarkets = nToken.portfolioState.storedAssets.length;
        netfCash = new int256[](numMarkets);

        MarketParameters memory market;
        for (uint256 i = 0; i < numMarkets; i++) {
            // Load the corresponding market into memory
            nToken.cashGroup.loadMarket(market, i + 1, true, blockTime);
            PortfolioAsset memory liquidityToken = nToken.portfolioState.storedAssets[i];
            uint256 maturity = liquidityToken.maturity;

            // Get the fCash claims and fCash assets. We do not use haircut versions here because
            // nTokenRedeem does not require it and getNTokenPV does not use it (a haircut is applied
            // at the end of the calculation to the entire PV instead).
            (int256 assetCashClaim, int256 fCashClaim) = AssetHandler.getCashClaims(liquidityToken, market);

            // fCash is denominated in underlying
            netfCash[i] = fCashClaim.add(
                BitmapAssetsHandler.getifCashNotional(
                    nToken.tokenAddress,
                    nToken.cashGroup.currencyId,
                    maturity
                )
            );

            // This calculates for a single liquidity token:
            // assetCashClaim + convertToAssetCash(pv(netfCash))
            int256 netAssetValueInMarket = assetCashClaim.add(
                nToken.cashGroup.assetRate.convertFromUnderlying(
                    AssetHandler.getPresentfCashValue(
                        netfCash[i],
                        maturity,
                        blockTime,
                        // No need to call cash group for oracle rate, it is up to date here
                        // and we are assured to be referring to this market.
                        market.oracleRate
                    )
                )
            );

            // Calculate the running total
            totalAssetValue = totalAssetValue.add(netAssetValueInMarket);
        }
    }

    /// @notice Returns just the bits in a bitmap that are idiosyncratic
    function getNTokenifCashBits(
        address tokenAddress,
        uint256 currencyId,
        uint256 lastInitializedTime,
        uint256 blockTime,
        uint256 maxMarketIndex
    ) internal view returns (bytes32) {
        // If max market index is less than or equal to 2, there are never ifCash assets by construction
        if (maxMarketIndex <= 2) return bytes32(0);
        bytes32 assetsBitmap = BitmapAssetsHandler.getAssetsBitmap(tokenAddress, currencyId);
        // Handles the case when there are no assets at the first initialization
        if (assetsBitmap == 0) return assetsBitmap;

        uint256 tRef = DateTime.getReferenceTime(blockTime);

        if (tRef == lastInitializedTime) {
            // This is a more efficient way to turn off ifCash assets in the common case when the market is
            // initialized immediately
            return assetsBitmap & ~(Constants.ACTIVE_MARKETS_MASK);
        } else {
            // In this branch, initialize markets has occurred past the time above. It would occur in these
            // two scenarios (both should be exceedingly rare):
            // 1. initializing a cash group with 3+ markets for the first time (not beginning on the tRef)
            // 2. somehow initialize markets has been delayed for more than 24 hours
            for (uint i = 1; i <= maxMarketIndex; i++) {
                // In this loop we get the maturity of each active market and turn off the corresponding bit
                // one by one. It is less efficient than the option above.
                uint256 maturity = tRef + DateTime.getTradedMarket(i);
                (uint256 bitNum, /* */) = DateTime.getBitNumFromMaturity(lastInitializedTime, maturity);
                assetsBitmap = assetsBitmap.setBit(bitNum, false);
            }

            return assetsBitmap;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "./AssetRate.sol";
import "./CashGroup.sol";
import "./DateTime.sol";
import "../balances/BalanceHandler.sol";
import "../../global/LibStorage.sol";
import "../../global/Types.sol";
import "../../global/Constants.sol";
import "../../math/SafeInt256.sol";
import "../../math/ABDKMath64x64.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

library Market {
    using SafeMath for uint256;
    using SafeInt256 for int256;
    using CashGroup for CashGroupParameters;
    using AssetRate for AssetRateParameters;

    // Max positive value for a ABDK64x64 integer
    int256 private constant MAX64 = 0x7FFFFFFFFFFFFFFF;

    /// @notice Add liquidity to a market, assuming that it is initialized. If not then
    /// this method will revert and the market must be initialized first.
    /// Return liquidityTokens and negative fCash to the portfolio
    function addLiquidity(MarketParameters memory market, int256 assetCash)
        internal
        returns (int256 liquidityTokens, int256 fCash)
    {
        require(market.totalLiquidity > 0, "M: zero liquidity");
        if (assetCash == 0) return (0, 0);
        require(assetCash > 0); // dev: negative asset cash

        liquidityTokens = market.totalLiquidity.mul(assetCash).div(market.totalAssetCash);
        // No need to convert this to underlying, assetCash / totalAssetCash is a unitless proportion.
        fCash = market.totalfCash.mul(assetCash).div(market.totalAssetCash);

        market.totalLiquidity = market.totalLiquidity.add(liquidityTokens);
        market.totalfCash = market.totalfCash.add(fCash);
        market.totalAssetCash = market.totalAssetCash.add(assetCash);
        _setMarketStorageForLiquidity(market);
        // Flip the sign to represent the LP's net position
        fCash = fCash.neg();
    }

    /// @notice Remove liquidity from a market, assuming that it is initialized.
    /// Return assetCash and positive fCash to the portfolio
    function removeLiquidity(MarketParameters memory market, int256 tokensToRemove)
        internal
        returns (int256 assetCash, int256 fCash)
    {
        if (tokensToRemove == 0) return (0, 0);
        require(tokensToRemove > 0); // dev: negative tokens to remove

        assetCash = market.totalAssetCash.mul(tokensToRemove).div(market.totalLiquidity);
        fCash = market.totalfCash.mul(tokensToRemove).div(market.totalLiquidity);

        market.totalLiquidity = market.totalLiquidity.subNoNeg(tokensToRemove);
        market.totalfCash = market.totalfCash.subNoNeg(fCash);
        market.totalAssetCash = market.totalAssetCash.subNoNeg(assetCash);

        _setMarketStorageForLiquidity(market);
    }

    function executeTrade(
        MarketParameters memory market,
        CashGroupParameters memory cashGroup,
        int256 fCashToAccount,
        uint256 timeToMaturity,
        uint256 marketIndex
    ) internal returns (int256 netAssetCash) {
        int256 netAssetCashToReserve;
        (netAssetCash, netAssetCashToReserve) = calculateTrade(
            market,
            cashGroup,
            fCashToAccount,
            timeToMaturity,
            marketIndex
        );

        MarketStorage storage marketStorage = _getMarketStoragePointer(market);
        _setMarketStorage(
            marketStorage,
            market.totalfCash,
            market.totalAssetCash,
            market.lastImpliedRate,
            market.oracleRate,
            market.previousTradeTime
        );
        BalanceHandler.incrementFeeToReserve(cashGroup.currencyId, netAssetCashToReserve);
    }

    /// @notice Calculates the asset cash amount the results from trading fCashToAccount with the market. A positive
    /// fCashToAccount is equivalent of lending, a negative is borrowing. Updates the market state in memory.
    /// @param market the current market state
    /// @param cashGroup cash group configuration parameters
    /// @param fCashToAccount the fCash amount that will be deposited into the user's portfolio. The net change
    /// to the market is in the opposite direction.
    /// @param timeToMaturity number of seconds until maturity
    /// @return netAssetCash, netAssetCashToReserve
    function calculateTrade(
        MarketParameters memory market,
        CashGroupParameters memory cashGroup,
        int256 fCashToAccount,
        uint256 timeToMaturity,
        uint256 marketIndex
    ) internal view returns (int256, int256) {
        // We return false if there is not enough fCash to support this trade.
        // if fCashToAccount > 0 and totalfCash - fCashToAccount <= 0 then the trade will fail
        // if fCashToAccount < 0 and totalfCash > 0 then this will always pass
        if (market.totalfCash <= fCashToAccount) return (0, 0);

        // Calculates initial rate factors for the trade
        (int256 rateScalar, int256 totalCashUnderlying, int256 rateAnchor) =
            getExchangeRateFactors(market, cashGroup, timeToMaturity, marketIndex);

        // Calculates the exchange rate from cash to fCash before any liquidity fees
        // are applied
        int256 preFeeExchangeRate;
        {
            bool success;
            (preFeeExchangeRate, success) = _getExchangeRate(
                market.totalfCash,
                totalCashUnderlying,
                rateScalar,
                rateAnchor,
                fCashToAccount
            );
            if (!success) return (0, 0);
        }

        // Given the exchange rate, returns the net cash amounts to apply to each of the
        // three relevant balances.
        (int256 netCashToAccount, int256 netCashToMarket, int256 netCashToReserve) =
            _getNetCashAmountsUnderlying(
                cashGroup,
                preFeeExchangeRate,
                fCashToAccount,
                timeToMaturity
            );
        // Signifies a failed net cash amount calculation
        if (netCashToAccount == 0) return (0, 0);

        {
            // Set the new implied interest rate after the trade has taken effect, this
            // will be used to calculate the next trader's interest rate.
            market.totalfCash = market.totalfCash.subNoNeg(fCashToAccount);
            market.lastImpliedRate = getImpliedRate(
                market.totalfCash,
                totalCashUnderlying.add(netCashToMarket),
                rateScalar,
                rateAnchor,
                timeToMaturity
            );

            // It's technically possible that the implied rate is actually exactly zero (or
            // more accurately the natural log rounds down to zero) but we will still fail
            // in this case. If this does happen we may assume that markets are not initialized.
            if (market.lastImpliedRate == 0) return (0, 0);
        }

        return
            _setNewMarketState(
                market,
                cashGroup.assetRate,
                netCashToAccount,
                netCashToMarket,
                netCashToReserve
            );
    }

    /// @notice Returns factors for calculating exchange rates
    /// @return
    ///    rateScalar: a scalar value in rate precision that defines the slope of the line
    ///    totalCashUnderlying: the converted asset cash to underlying cash for calculating
    ///    the exchange rates for the trade
    ///    rateAnchor: an offset from the x axis to maintain interest rate continuity over time
    function getExchangeRateFactors(
        MarketParameters memory market,
        CashGroupParameters memory cashGroup,
        uint256 timeToMaturity,
        uint256 marketIndex
    )
        internal
        pure
        returns (
            int256,
            int256,
            int256
        )
    {
        int256 rateScalar = cashGroup.getRateScalar(marketIndex, timeToMaturity);
        int256 totalCashUnderlying = cashGroup.assetRate.convertToUnderlying(market.totalAssetCash);

        // This would result in a divide by zero
        if (market.totalfCash == 0 || totalCashUnderlying == 0) return (0, 0, 0);

        // Get the rate anchor given the market state, this will establish the baseline for where
        // the exchange rate is set.
        int256 rateAnchor;
        {
            bool success;
            (rateAnchor, success) = _getRateAnchor(
                market.totalfCash,
                market.lastImpliedRate,
                totalCashUnderlying,
                rateScalar,
                timeToMaturity
            );
            if (!success) return (0, 0, 0);
        }

        return (rateScalar, totalCashUnderlying, rateAnchor);
    }

    /// @dev Returns net asset cash amounts to the account, the market and the reserve
    /// @return
    ///     netCashToAccount: this is a positive or negative amount of cash change to the account
    ///     netCashToMarket: this is a positive or negative amount of cash change in the market
    //      netCashToReserve: this is always a positive amount of cash accrued to the reserve
    function _getNetCashAmountsUnderlying(
        CashGroupParameters memory cashGroup,
        int256 preFeeExchangeRate,
        int256 fCashToAccount,
        uint256 timeToMaturity
    )
        private
        pure
        returns (
            int256,
            int256,
            int256
        )
    {
        // Fees are specified in basis points which is an rate precision denomination. We convert this to
        // an exchange rate denomination for the given time to maturity. (i.e. get e^(fee * t) and multiply
        // or divide depending on the side of the trade).
        // tradeExchangeRate = exp((tradeInterestRateNoFee +/- fee) * timeToMaturity)
        // tradeExchangeRate = tradeExchangeRateNoFee (* or /) exp(fee * timeToMaturity)
        // cash = fCash / exchangeRate, exchangeRate > 1
        int256 preFeeCashToAccount =
            fCashToAccount.divInRatePrecision(preFeeExchangeRate).neg();
        int256 fee = getExchangeRateFromImpliedRate(cashGroup.getTotalFee(), timeToMaturity);

        if (fCashToAccount > 0) {
            // Lending
            // Dividing reduces exchange rate, lending should receive less fCash for cash
            int256 postFeeExchangeRate = preFeeExchangeRate.divInRatePrecision(fee);
            // It's possible that the fee pushes exchange rates into negative territory. This is not possible
            // when borrowing. If this happens then the trade has failed.
            if (postFeeExchangeRate < Constants.RATE_PRECISION) return (0, 0, 0);

            // cashToAccount = -(fCashToAccount / exchangeRate)
            // postFeeExchangeRate = preFeeExchangeRate / feeExchangeRate
            // preFeeCashToAccount = -(fCashToAccount / preFeeExchangeRate)
            // postFeeCashToAccount = -(fCashToAccount / postFeeExchangeRate)
            // netFee = preFeeCashToAccount - postFeeCashToAccount
            // netFee = (fCashToAccount / postFeeExchangeRate) - (fCashToAccount / preFeeExchangeRate)
            // netFee = ((fCashToAccount * feeExchangeRate) / preFeeExchangeRate) - (fCashToAccount / preFeeExchangeRate)
            // netFee = (fCashToAccount / preFeeExchangeRate) * (feeExchangeRate - 1)
            // netFee = -(preFeeCashToAccount) * (feeExchangeRate - 1)
            // netFee = preFeeCashToAccount * (1 - feeExchangeRate)
            // RATE_PRECISION - fee will be negative here, preFeeCashToAccount < 0, fee > 0
            fee = preFeeCashToAccount.mulInRatePrecision(Constants.RATE_PRECISION.sub(fee));
        } else {
            // Borrowing
            // cashToAccount = -(fCashToAccount / exchangeRate)
            // postFeeExchangeRate = preFeeExchangeRate * feeExchangeRate

            // netFee = preFeeCashToAccount - postFeeCashToAccount
            // netFee = (fCashToAccount / postFeeExchangeRate) - (fCashToAccount / preFeeExchangeRate)
            // netFee = ((fCashToAccount / (feeExchangeRate * preFeeExchangeRate)) - (fCashToAccount / preFeeExchangeRate)
            // netFee = (fCashToAccount / preFeeExchangeRate) * (1 / feeExchangeRate - 1)
            // netFee = preFeeCashToAccount * ((1 - feeExchangeRate) / feeExchangeRate)
            // NOTE: preFeeCashToAccount is negative in this branch so we negate it to ensure that fee is a positive number
            // preFee * (1 - fee) / fee will be negative, use neg() to flip to positive
            // RATE_PRECISION - fee will be negative
            fee = preFeeCashToAccount.mul(Constants.RATE_PRECISION.sub(fee)).div(fee).neg();
        }

        int256 cashToReserve =
            fee.mul(cashGroup.getReserveFeeShare()).div(Constants.PERCENTAGE_DECIMALS);

        return (
            // postFeeCashToAccount = preFeeCashToAccount - fee
            preFeeCashToAccount.sub(fee),
            // netCashToMarket = -(preFeeCashToAccount - fee + cashToReserve)
            (preFeeCashToAccount.sub(fee).add(cashToReserve)).neg(),
            cashToReserve
        );
    }

    /// @notice Sets the new market state
    /// @return
    ///     netAssetCashToAccount: the positive or negative change in asset cash to the account
    ///     assetCashToReserve: the positive amount of cash that accrues to the reserve
    function _setNewMarketState(
        MarketParameters memory market,
        AssetRateParameters memory assetRate,
        int256 netCashToAccount,
        int256 netCashToMarket,
        int256 netCashToReserve
    ) private view returns (int256, int256) {
        int256 netAssetCashToMarket = assetRate.convertFromUnderlying(netCashToMarket);
        // Set storage checks that total asset cash is above zero
        market.totalAssetCash = market.totalAssetCash.add(netAssetCashToMarket);

        // Sets the trade time for the next oracle update
        market.previousTradeTime = block.timestamp;
        int256 assetCashToReserve = assetRate.convertFromUnderlying(netCashToReserve);
        int256 netAssetCashToAccount = assetRate.convertFromUnderlying(netCashToAccount);
        return (netAssetCashToAccount, assetCashToReserve);
    }

    /// @notice Rate anchors update as the market gets closer to maturity. Rate anchors are not comparable
    /// across time or markets but implied rates are. The goal here is to ensure that the implied rate
    /// before and after the rate anchor update is the same. Therefore, the market will trade at the same implied
    /// rate that it last traded at. If these anchors do not update then it opens up the opportunity for arbitrage
    /// which will hurt the liquidity providers.
    ///
    /// The rate anchor will update as the market rolls down to maturity. The calculation is:
    /// newExchangeRate = e^(lastImpliedRate * timeToMaturity / Constants.IMPLIED_RATE_TIME)
    /// newAnchor = newExchangeRate - ln((proportion / (1 - proportion)) / rateScalar
    ///
    /// where:
    /// lastImpliedRate = ln(exchangeRate') * (Constants.IMPLIED_RATE_TIME / timeToMaturity')
    ///      (calculated when the last trade in the market was made)
    /// @return the new rate anchor and a boolean that signifies success
    function _getRateAnchor(
        int256 totalfCash,
        uint256 lastImpliedRate,
        int256 totalCashUnderlying,
        int256 rateScalar,
        uint256 timeToMaturity
    ) internal pure returns (int256, bool) {
        // This is the exchange rate at the new time to maturity
        int256 newExchangeRate = getExchangeRateFromImpliedRate(lastImpliedRate, timeToMaturity);
        if (newExchangeRate < Constants.RATE_PRECISION) return (0, false);

        int256 rateAnchor;
        {
            // totalfCash / (totalfCash + totalCashUnderlying)
            int256 proportion =
                totalfCash.divInRatePrecision(totalfCash.add(totalCashUnderlying));

            (int256 lnProportion, bool success) = _logProportion(proportion);
            if (!success) return (0, false);

            // newExchangeRate - ln(proportion / (1 - proportion)) / rateScalar
            rateAnchor = newExchangeRate.sub(lnProportion.divInRatePrecision(rateScalar));
        }

        return (rateAnchor, true);
    }

    /// @notice Calculates the current market implied rate.
    /// @return the implied rate and a bool that is true on success
    function getImpliedRate(
        int256 totalfCash,
        int256 totalCashUnderlying,
        int256 rateScalar,
        int256 rateAnchor,
        uint256 timeToMaturity
    ) internal pure returns (uint256) {
        // This will check for exchange rates < Constants.RATE_PRECISION
        (int256 exchangeRate, bool success) =
            _getExchangeRate(totalfCash, totalCashUnderlying, rateScalar, rateAnchor, 0);
        if (!success) return 0;

        // Uses continuous compounding to calculate the implied rate:
        // ln(exchangeRate) * Constants.IMPLIED_RATE_TIME / timeToMaturity
        int128 rate = ABDKMath64x64.fromInt(exchangeRate);
        // Scales down to a floating point for LN
        int128 rateScaled = ABDKMath64x64.div(rate, Constants.RATE_PRECISION_64x64);
        // We will not have a negative log here because we check that exchangeRate > Constants.RATE_PRECISION
        // inside getExchangeRate
        int128 lnRateScaled = ABDKMath64x64.ln(rateScaled);
        // Scales up to a fixed point
        uint256 lnRate =
            ABDKMath64x64.toUInt(ABDKMath64x64.mul(lnRateScaled, Constants.RATE_PRECISION_64x64));

        // lnRate * IMPLIED_RATE_TIME / ttm
        uint256 impliedRate = lnRate.mul(Constants.IMPLIED_RATE_TIME).div(timeToMaturity);

        // Implied rates over 429% will overflow, this seems like a safe assumption
        if (impliedRate > type(uint32).max) return 0;

        return impliedRate;
    }

    /// @notice Converts an implied rate to an exchange rate given a time to maturity. The
    /// formula is E = e^rt
    function getExchangeRateFromImpliedRate(uint256 impliedRate, uint256 timeToMaturity)
        internal
        pure
        returns (int256)
    {
        int128 expValue =
            ABDKMath64x64.fromUInt(
                impliedRate.mul(timeToMaturity).div(Constants.IMPLIED_RATE_TIME)
            );
        int128 expValueScaled = ABDKMath64x64.div(expValue, Constants.RATE_PRECISION_64x64);
        int128 expResult = ABDKMath64x64.exp(expValueScaled);
        int128 expResultScaled = ABDKMath64x64.mul(expResult, Constants.RATE_PRECISION_64x64);

        return ABDKMath64x64.toInt(expResultScaled);
    }

    /// @notice Returns the exchange rate between fCash and cash for the given market
    /// Calculates the following exchange rate:
    ///     (1 / rateScalar) * ln(proportion / (1 - proportion)) + rateAnchor
    /// where:
    ///     proportion = totalfCash / (totalfCash + totalUnderlyingCash)
    /// @dev has an underscore to denote as private but is marked internal for the mock
    function _getExchangeRate(
        int256 totalfCash,
        int256 totalCashUnderlying,
        int256 rateScalar,
        int256 rateAnchor,
        int256 fCashToAccount
    ) internal pure returns (int256, bool) {
        int256 numerator = totalfCash.subNoNeg(fCashToAccount);

        // This is the proportion scaled by Constants.RATE_PRECISION
        // (totalfCash + fCash) / (totalfCash + totalCashUnderlying)
        int256 proportion =
            numerator.divInRatePrecision(totalfCash.add(totalCashUnderlying));

        // This limit is here to prevent the market from reaching extremely high interest rates via an
        // excessively large proportion (high amounts of fCash relative to cash).
        // Market proportion can only increase via borrowing (fCash is added to the market and cash is
        // removed). Over time, the returns from asset cash will slightly decrease the proportion (the
        // value of cash underlying in the market must be monotonically increasing). Therefore it is not
        // possible for the proportion to go over max market proportion unless borrowing occurs.
        if (proportion > Constants.MAX_MARKET_PROPORTION) return (0, false);

        (int256 lnProportion, bool success) = _logProportion(proportion);
        if (!success) return (0, false);

        // lnProportion / rateScalar + rateAnchor
        int256 rate = lnProportion.divInRatePrecision(rateScalar).add(rateAnchor);
        // Do not succeed if interest rates fall below 1
        if (rate < Constants.RATE_PRECISION) {
            return (0, false);
        } else {
            return (rate, true);
        }
    }

    /// @dev This method calculates the log of the proportion inside the logit function which is
    /// defined as ln(proportion / (1 - proportion)). Special handling here is required to deal with
    /// fixed point precision and the ABDK library.
    function _logProportion(int256 proportion) internal pure returns (int256, bool) {
        // This will result in divide by zero, short circuit
        if (proportion == Constants.RATE_PRECISION) return (0, false);

        // Convert proportion to what is used inside the logit function (p / (1-p))
        int256 logitP = proportion.divInRatePrecision(Constants.RATE_PRECISION.sub(proportion));

        // ABDK does not handle log of numbers that are less than 1, in order to get the right value
        // scaled by RATE_PRECISION we use the log identity:
        // (ln(logitP / RATE_PRECISION)) * RATE_PRECISION = (ln(logitP) - ln(RATE_PRECISION)) * RATE_PRECISION
        int128 abdkProportion = ABDKMath64x64.fromInt(logitP);
        // Here, abdk will revert due to negative log so abort
        if (abdkProportion <= 0) return (0, false);
        int256 result =
            ABDKMath64x64.toInt(
                ABDKMath64x64.mul(
                    ABDKMath64x64.sub(
                        ABDKMath64x64.ln(abdkProportion),
                        Constants.LOG_RATE_PRECISION_64x64
                    ),
                    Constants.RATE_PRECISION_64x64
                )
            );

        return (result, true);
    }

    /// @notice Oracle rate protects against short term price manipulation. Time window will be set to a value
    /// on the order of minutes to hours. This is to protect fCash valuations from market manipulation. For example,
    /// a trader could use a flash loan to dump a large amount of cash into the market and depress interest rates.
    /// Since we value fCash in portfolios based on these rates, portfolio values will decrease and they may then
    /// be liquidated.
    ///
    /// Oracle rates are calculated when the market is loaded from storage.
    ///
    /// The oracle rate is a lagged weighted average over a short term price window. If we are past
    /// the short term window then we just set the rate to the lastImpliedRate, otherwise we take the
    /// weighted average:
    ///     lastImpliedRatePreTrade * (currentTs - previousTs) / timeWindow +
    ///         oracleRatePrevious * (1 - (currentTs - previousTs) / timeWindow)
    function _updateRateOracle(
        uint256 previousTradeTime,
        uint256 lastImpliedRate,
        uint256 oracleRate,
        uint256 rateOracleTimeWindow,
        uint256 blockTime
    ) private pure returns (uint256) {
        require(rateOracleTimeWindow > 0); // dev: update rate oracle, time window zero

        // This can occur when using a view function get to a market state in the past
        if (previousTradeTime > blockTime) return lastImpliedRate;

        uint256 timeDiff = blockTime.sub(previousTradeTime);
        if (timeDiff > rateOracleTimeWindow) {
            // If past the time window just return the lastImpliedRate
            return lastImpliedRate;
        }

        // (currentTs - previousTs) / timeWindow
        uint256 lastTradeWeight =
            timeDiff.mul(uint256(Constants.RATE_PRECISION)).div(rateOracleTimeWindow);

        // 1 - (currentTs - previousTs) / timeWindow
        uint256 oracleWeight = uint256(Constants.RATE_PRECISION).sub(lastTradeWeight);

        uint256 newOracleRate =
            (lastImpliedRate.mul(lastTradeWeight).add(oracleRate.mul(oracleWeight))).div(
                uint256(Constants.RATE_PRECISION)
            );

        return newOracleRate;
    }

    function getOracleRate(
        uint256 currencyId,
        uint256 maturity,
        uint256 rateOracleTimeWindow,
        uint256 blockTime
    ) internal view returns (uint256) {
        mapping(uint256 => mapping(uint256 => 
            mapping(uint256 => MarketStorage))) storage store = LibStorage.getMarketStorage();
        uint256 settlementDate = DateTime.getReferenceTime(blockTime) + Constants.QUARTER;
        MarketStorage storage marketStorage = store[currencyId][maturity][settlementDate];

        uint256 lastImpliedRate = marketStorage.lastImpliedRate;
        uint256 oracleRate = marketStorage.oracleRate;
        uint256 previousTradeTime = marketStorage.previousTradeTime;

        // If the oracle rate is set to zero this can only be because the markets have past their settlement
        // date but the new set of markets has not yet been initialized. This means that accounts cannot be liquidated
        // during this time, but market initialization can be called by anyone so the actual time that this condition
        // exists for should be quite short.
        require(oracleRate > 0, "Market not initialized");

        return
            _updateRateOracle(
                previousTradeTime,
                lastImpliedRate,
                oracleRate,
                rateOracleTimeWindow,
                blockTime
            );
    }

    /// @notice Reads a market object directly from storage. `loadMarket` should be called instead of this method
    /// which ensures that the rate oracle is set properly.
    function _loadMarketStorage(
        MarketParameters memory market,
        uint256 currencyId,
        uint256 maturity,
        bool needsLiquidity,
        uint256 settlementDate
    ) private view {
        // Market object always uses the most current reference time as the settlement date
        mapping(uint256 => mapping(uint256 => 
            mapping(uint256 => MarketStorage))) storage store = LibStorage.getMarketStorage();
        MarketStorage storage marketStorage = store[currencyId][maturity][settlementDate];
        bytes32 slot;
        assembly {
            slot := marketStorage.slot
        }

        market.storageSlot = slot;
        market.maturity = maturity;
        market.totalfCash = marketStorage.totalfCash;
        market.totalAssetCash = marketStorage.totalAssetCash;
        market.lastImpliedRate = marketStorage.lastImpliedRate;
        market.oracleRate = marketStorage.oracleRate;
        market.previousTradeTime = marketStorage.previousTradeTime;

        if (needsLiquidity) {
            market.totalLiquidity = marketStorage.totalLiquidity;
        } else {
            market.totalLiquidity = 0;
        }
    }

    function _getMarketStoragePointer(
        MarketParameters memory market
    ) private pure returns (MarketStorage storage marketStorage) {
        bytes32 slot = market.storageSlot;
        assembly {
            marketStorage.slot := slot
        }
    }

    function _setMarketStorageForLiquidity(MarketParameters memory market) internal {
        MarketStorage storage marketStorage = _getMarketStoragePointer(market);
        // Oracle rate does not change on liquidity
        uint32 storedOracleRate = marketStorage.oracleRate;

        _setMarketStorage(
            marketStorage,
            market.totalfCash,
            market.totalAssetCash,
            market.lastImpliedRate,
            storedOracleRate,
            market.previousTradeTime
        );

        _setTotalLiquidity(marketStorage, market.totalLiquidity);
    }

    function setMarketStorageForInitialize(
        MarketParameters memory market,
        uint256 currencyId,
        uint256 settlementDate
    ) internal {
        // On initialization we have not yet calculated the storage slot so we get it here.
        mapping(uint256 => mapping(uint256 => 
            mapping(uint256 => MarketStorage))) storage store = LibStorage.getMarketStorage();
        MarketStorage storage marketStorage = store[currencyId][market.maturity][settlementDate];

        _setMarketStorage(
            marketStorage,
            market.totalfCash,
            market.totalAssetCash,
            market.lastImpliedRate,
            market.oracleRate,
            market.previousTradeTime
        );

        _setTotalLiquidity(marketStorage, market.totalLiquidity);
    }

    function _setTotalLiquidity(
        MarketStorage storage marketStorage,
        int256 totalLiquidity
    ) internal {
        require(totalLiquidity >= 0 && totalLiquidity <= type(uint80).max); // dev: market storage totalLiquidity overflow
        marketStorage.totalLiquidity = uint80(totalLiquidity);
    }

    function _setMarketStorage(
        MarketStorage storage marketStorage,
        int256 totalfCash,
        int256 totalAssetCash,
        uint256 lastImpliedRate,
        uint256 oracleRate,
        uint256 previousTradeTime
    ) private {
        require(totalfCash >= 0 && totalfCash <= type(uint80).max); // dev: storage totalfCash overflow
        require(totalAssetCash >= 0 && totalAssetCash <= type(uint80).max); // dev: storage totalAssetCash overflow
        require(0 < lastImpliedRate && lastImpliedRate <= type(uint32).max); // dev: storage lastImpliedRate overflow
        require(0 < oracleRate && oracleRate <= type(uint32).max); // dev: storage oracleRate overflow
        require(0 <= previousTradeTime && previousTradeTime <= type(uint32).max); // dev: storage previous trade time overflow

        marketStorage.totalfCash = uint80(totalfCash);
        marketStorage.totalAssetCash = uint80(totalAssetCash);
        marketStorage.lastImpliedRate = uint32(lastImpliedRate);
        marketStorage.oracleRate = uint32(oracleRate);
        marketStorage.previousTradeTime = uint32(previousTradeTime);
    }

    /// @notice Creates a market object and ensures that the rate oracle time window is updated appropriately.
    function loadMarket(
        MarketParameters memory market,
        uint256 currencyId,
        uint256 maturity,
        uint256 blockTime,
        bool needsLiquidity,
        uint256 rateOracleTimeWindow
    ) internal view {
        // Always reference the current settlement date
        uint256 settlementDate = DateTime.getReferenceTime(blockTime) + Constants.QUARTER;
        loadMarketWithSettlementDate(
            market,
            currencyId,
            maturity,
            blockTime,
            needsLiquidity,
            rateOracleTimeWindow,
            settlementDate
        );
    }

    /// @notice Creates a market object and ensures that the rate oracle time window is updated appropriately, this
    /// is mainly used in the InitializeMarketAction contract.
    function loadMarketWithSettlementDate(
        MarketParameters memory market,
        uint256 currencyId,
        uint256 maturity,
        uint256 blockTime,
        bool needsLiquidity,
        uint256 rateOracleTimeWindow,
        uint256 settlementDate
    ) internal view {
        _loadMarketStorage(market, currencyId, maturity, needsLiquidity, settlementDate);

        market.oracleRate = _updateRateOracle(
            market.previousTradeTime,
            market.lastImpliedRate,
            market.oracleRate,
            rateOracleTimeWindow,
            blockTime
        );
    }

    function loadSettlementMarket(
        MarketParameters memory market,
        uint256 currencyId,
        uint256 maturity,
        uint256 settlementDate
    ) internal view {
        _loadMarketStorage(market, currencyId, maturity, true, settlementDate);
    }

    /// Uses Newton's method to converge on an fCash amount given the amount of
    /// cash. The relation between cash and fcash is:
    /// cashAmount * exchangeRate * fee + fCash = 0
    /// where exchangeRate(fCash) = (rateScalar ^ -1) * ln(p / (1 - p)) + rateAnchor
    ///       p = (totalfCash - fCash) / (totalfCash + totalCash)
    ///       if cashAmount < 0: fee = feeRate ^ -1
    ///       if cashAmount > 0: fee = feeRate
    ///
    /// Newton's method is:
    /// fCash_(n+1) = fCash_n - f(fCash) / f'(fCash)
    ///
    /// f(fCash) = cashAmount * exchangeRate(fCash) * fee + fCash
    ///
    ///                                    (totalfCash + totalCash)
    /// exchangeRate'(fCash) = -  ------------------------------------------
    ///                           (totalfCash - fCash) * (totalCash + fCash)
    ///
    /// https://www.wolframalpha.com/input/?i=ln%28%28%28a-x%29%2F%28a%2Bb%29%29%2F%281-%28a-x%29%2F%28a%2Bb%29%29%29
    ///
    ///                     (cashAmount * fee) * (totalfCash + totalCash)
    /// f'(fCash) = 1 - ------------------------------------------------------
    ///                 rateScalar * (totalfCash - fCash) * (totalCash + fCash)
    ///
    /// NOTE: each iteration costs about 11.3k so this is only done via a view function.
    function getfCashGivenCashAmount(
        int256 totalfCash,
        int256 netCashToAccount,
        int256 totalCashUnderlying,
        int256 rateScalar,
        int256 rateAnchor,
        int256 feeRate,
        int256 maxDelta
    ) internal pure returns (int256) {
        require(maxDelta >= 0);
        int256 fCashChangeToAccountGuess = netCashToAccount.mulInRatePrecision(rateAnchor).neg();
        for (uint8 i = 0; i < 250; i++) {
            (int256 exchangeRate, bool success) =
                _getExchangeRate(
                    totalfCash,
                    totalCashUnderlying,
                    rateScalar,
                    rateAnchor,
                    fCashChangeToAccountGuess
                );

            require(success); // dev: invalid exchange rate
            int256 delta =
                _calculateDelta(
                    netCashToAccount,
                    totalfCash,
                    totalCashUnderlying,
                    rateScalar,
                    fCashChangeToAccountGuess,
                    exchangeRate,
                    feeRate
                );

            if (delta.abs() <= maxDelta) return fCashChangeToAccountGuess;
            fCashChangeToAccountGuess = fCashChangeToAccountGuess.sub(delta);
        }

        revert("No convergence");
    }

    /// @dev Calculates: f(fCash) / f'(fCash)
    /// f(fCash) = cashAmount * exchangeRate * fee + fCash
    ///                     (cashAmount * fee) * (totalfCash + totalCash)
    /// f'(fCash) = 1 - ------------------------------------------------------
    ///                 rateScalar * (totalfCash - fCash) * (totalCash + fCash)
    function _calculateDelta(
        int256 cashAmount,
        int256 totalfCash,
        int256 totalCashUnderlying,
        int256 rateScalar,
        int256 fCashGuess,
        int256 exchangeRate,
        int256 feeRate
    ) private pure returns (int256) {
        int256 derivative;
        // rateScalar * (totalfCash - fCash) * (totalCash + fCash)
        // Precision: TOKEN_PRECISION ^ 2
        int256 denominator =
            rateScalar.mulInRatePrecision(
                (totalfCash.sub(fCashGuess)).mul(totalCashUnderlying.add(fCashGuess))
            );

        if (fCashGuess > 0) {
            // Lending
            exchangeRate = exchangeRate.divInRatePrecision(feeRate);
            require(exchangeRate >= Constants.RATE_PRECISION); // dev: rate underflow

            // (cashAmount / fee) * (totalfCash + totalCash)
            // Precision: TOKEN_PRECISION ^ 2
            derivative = cashAmount
                .mul(totalfCash.add(totalCashUnderlying))
                .divInRatePrecision(feeRate);
        } else {
            // Borrowing
            exchangeRate = exchangeRate.mulInRatePrecision(feeRate);
            require(exchangeRate >= Constants.RATE_PRECISION); // dev: rate underflow

            // (cashAmount * fee) * (totalfCash + totalCash)
            // Precision: TOKEN_PRECISION ^ 2
            derivative = cashAmount.mulInRatePrecision(
                feeRate.mul(totalfCash.add(totalCashUnderlying))
            );
        }
        // 1 - numerator / denominator
        // Precision: TOKEN_PRECISION
        derivative = Constants.INTERNAL_TOKEN_PRECISION.sub(derivative.div(denominator));

        // f(fCash) = cashAmount * exchangeRate * fee + fCash
        // NOTE: exchangeRate at this point already has the fee taken into account
        int256 numerator = cashAmount.mulInRatePrecision(exchangeRate);
        numerator = numerator.add(fCashGuess);

        // f(fCash) / f'(fCash), note that they are both denominated as cashAmount so use TOKEN_PRECISION
        // here instead of RATE_PRECISION
        return numerator.mul(Constants.INTERNAL_TOKEN_PRECISION).div(derivative);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "./Incentives.sol";
import "./TokenHandler.sol";
import "../AccountContextHandler.sol";
import "../../global/Types.sol";
import "../../global/Constants.sol";
import "../../math/SafeInt256.sol";
import "../../math/FloatingPoint56.sol";

library BalanceHandler {
    using SafeInt256 for int256;
    using TokenHandler for Token;
    using AssetRate for AssetRateParameters;
    using AccountContextHandler for AccountContext;

    /// @notice Emitted when a cash balance changes
    event CashBalanceChange(address indexed account, uint16 indexed currencyId, int256 netCashChange);
    /// @notice Emitted when nToken supply changes (not the same as transfers)
    event nTokenSupplyChange(address indexed account, uint16 indexed currencyId, int256 tokenSupplyChange);
    /// @notice Emitted when reserve fees are accrued
    event ReserveFeeAccrued(uint16 indexed currencyId, int256 fee);
    /// @notice Emitted when reserve balance is updated
    event ReserveBalanceUpdated(uint16 indexed currencyId, int256 newBalance);
    /// @notice Emitted when reserve balance is harvested
    event ExcessReserveBalanceHarvested(uint16 indexed currencyId, int256 harvestAmount);

    /// @notice Deposits asset tokens into an account
    /// @dev Handles two special cases when depositing tokens into an account.
    ///  - If a token has transfer fees then the amount specified does not equal the amount that the contract
    ///    will receive. Complete the deposit here rather than in finalize so that the contract has the correct
    ///    balance to work with.
    ///  - Force a transfer before finalize to allow a different account to deposit into an account
    /// @return assetAmountInternal which is the converted asset amount accounting for transfer fees
    function depositAssetToken(
        BalanceState memory balanceState,
        address account,
        int256 assetAmountExternal,
        bool forceTransfer
    ) internal returns (int256 assetAmountInternal) {
        if (assetAmountExternal == 0) return 0;
        require(assetAmountExternal > 0); // dev: deposit asset token amount negative
        Token memory token = TokenHandler.getAssetToken(balanceState.currencyId);
        if (token.tokenType == TokenType.aToken) {
            // Handles special accounting requirements for aTokens
            assetAmountExternal = AaveHandler.convertToScaledBalanceExternal(
                balanceState.currencyId,
                assetAmountExternal
            );
        }

        // Force transfer is used to complete the transfer before going to finalize
        if (token.hasTransferFee || forceTransfer) {
            // If the token has a transfer fee the deposit amount may not equal the actual amount
            // that the contract will receive. We handle the deposit here and then update the netCashChange
            // accordingly which is denominated in internal precision.
            int256 assetAmountExternalPrecisionFinal = token.transfer(account, balanceState.currencyId, assetAmountExternal);
            // Convert the external precision to internal, it's possible that we lose dust amounts here but
            // this is unavoidable because we do not know how transfer fees are calculated.
            assetAmountInternal = token.convertToInternal(assetAmountExternalPrecisionFinal);
            // Transfer has been called
            balanceState.netCashChange = balanceState.netCashChange.add(assetAmountInternal);

            return assetAmountInternal;
        } else {
            assetAmountInternal = token.convertToInternal(assetAmountExternal);
            // Otherwise add the asset amount here. It may be net off later and we want to only do
            // a single transfer during the finalize method. Use internal precision to ensure that internal accounting
            // and external account remain in sync.
            // Transfer will be deferred
            balanceState.netAssetTransferInternalPrecision = balanceState
                .netAssetTransferInternalPrecision
                .add(assetAmountInternal);

            // Returns the converted assetAmountExternal to the internal amount
            return assetAmountInternal;
        }
    }

    /// @notice Handle deposits of the underlying token
    /// @dev In this case we must wrap the underlying token into an asset token, ensuring that we do not end up
    /// with any underlying tokens left as dust on the contract.
    function depositUnderlyingToken(
        BalanceState memory balanceState,
        address account,
        int256 underlyingAmountExternal
    ) internal returns (int256) {
        if (underlyingAmountExternal == 0) return 0;
        require(underlyingAmountExternal > 0); // dev: deposit underlying token negative

        Token memory underlyingToken = TokenHandler.getUnderlyingToken(balanceState.currencyId);
        // This is the exact amount of underlying tokens the account has in external precision.
        if (underlyingToken.tokenType == TokenType.Ether) {
            // Underflow checked above
            require(uint256(underlyingAmountExternal) == msg.value, "ETH Balance");
        } else {
            underlyingAmountExternal = underlyingToken.transfer(account, balanceState.currencyId, underlyingAmountExternal);
        }

        Token memory assetToken = TokenHandler.getAssetToken(balanceState.currencyId);
        int256 assetTokensReceivedExternalPrecision =
            assetToken.mint(balanceState.currencyId, SafeInt256.toUint(underlyingAmountExternal));

        // cTokens match INTERNAL_TOKEN_PRECISION so this will short circuit but we leave this here in case a different
        // type of asset token is listed in the future. It's possible if those tokens have a different precision dust may
        // accrue but that is not relevant now.
        int256 assetTokensReceivedInternal =
            assetToken.convertToInternal(assetTokensReceivedExternalPrecision);
        // Transfer / mint has taken effect
        balanceState.netCashChange = balanceState.netCashChange.add(assetTokensReceivedInternal);

        return assetTokensReceivedInternal;
    }

    /// @notice Finalizes an account's balances, handling any transfer logic required
    /// @dev This method SHOULD NOT be used for nToken accounts, for that use setBalanceStorageForNToken
    /// as the nToken is limited in what types of balances it can hold.
    function finalize(
        BalanceState memory balanceState,
        address account,
        AccountContext memory accountContext,
        bool redeemToUnderlying
    ) internal returns (int256 transferAmountExternal) {
        bool mustUpdate;
        if (balanceState.netNTokenTransfer < 0) {
            require(
                balanceState.storedNTokenBalance
                    .add(balanceState.netNTokenSupplyChange)
                    .add(balanceState.netNTokenTransfer) >= 0,
                "Neg nToken"
            );
        }

        if (balanceState.netAssetTransferInternalPrecision < 0) {
            require(
                balanceState.storedCashBalance
                    .add(balanceState.netCashChange)
                    .add(balanceState.netAssetTransferInternalPrecision) >= 0,
                "Neg Cash"
            );
        }

        // Transfer amount is checked inside finalize transfers in case when converting to external we
        // round down to zero. This returns the actual net transfer in internal precision as well.
        (
            transferAmountExternal,
            balanceState.netAssetTransferInternalPrecision
        ) = _finalizeTransfers(balanceState, account, redeemToUnderlying);
        // No changes to total cash after this point
        int256 totalCashChange = balanceState.netCashChange.add(balanceState.netAssetTransferInternalPrecision);

        if (totalCashChange != 0) {
            balanceState.storedCashBalance = balanceState.storedCashBalance.add(totalCashChange);
            mustUpdate = true;

            emit CashBalanceChange(
                account,
                uint16(balanceState.currencyId),
                totalCashChange
            );
        }

        if (balanceState.netNTokenTransfer != 0 || balanceState.netNTokenSupplyChange != 0) {
            // Final nToken balance is used to calculate the account incentive debt
            int256 finalNTokenBalance = balanceState.storedNTokenBalance
                .add(balanceState.netNTokenTransfer)
                .add(balanceState.netNTokenSupplyChange);

            // The toUint() call here will ensure that nToken balances never become negative
            Incentives.claimIncentives(balanceState, account, finalNTokenBalance.toUint());

            balanceState.storedNTokenBalance = finalNTokenBalance;

            if (balanceState.netNTokenSupplyChange != 0) {
                emit nTokenSupplyChange(
                    account,
                    uint16(balanceState.currencyId),
                    balanceState.netNTokenSupplyChange
                );
            }

            mustUpdate = true;
        }

        if (mustUpdate) {
            _setBalanceStorage(
                account,
                balanceState.currencyId,
                balanceState.storedCashBalance,
                balanceState.storedNTokenBalance,
                balanceState.lastClaimTime,
                balanceState.accountIncentiveDebt
            );
        }

        accountContext.setActiveCurrency(
            balanceState.currencyId,
            // Set active currency to true if either balance is non-zero
            balanceState.storedCashBalance != 0 || balanceState.storedNTokenBalance != 0,
            Constants.ACTIVE_IN_BALANCES
        );

        if (balanceState.storedCashBalance < 0) {
            // NOTE: HAS_CASH_DEBT cannot be extinguished except by a free collateral check where all balances
            // are examined
            accountContext.hasDebt = accountContext.hasDebt | Constants.HAS_CASH_DEBT;
        }
    }

    /// @dev Returns the amount transferred in underlying or asset terms depending on how redeem to underlying
    /// is specified.
    function _finalizeTransfers(
        BalanceState memory balanceState,
        address account,
        bool redeemToUnderlying
    ) private returns (int256 actualTransferAmountExternal, int256 assetTransferAmountInternal) {
        Token memory assetToken = TokenHandler.getAssetToken(balanceState.currencyId);
        // Dust accrual to the protocol is possible if the token decimals is less than internal token precision.
        // See the comments in TokenHandler.convertToExternal and TokenHandler.convertToInternal
        int256 assetTransferAmountExternal =
            assetToken.convertToExternal(balanceState.netAssetTransferInternalPrecision);

        if (assetTransferAmountExternal == 0) {
            return (0, 0);
        } else if (redeemToUnderlying && assetTransferAmountExternal < 0) {
            // We only do the redeem to underlying if the asset transfer amount is less than zero. If it is greater than
            // zero then we will do a normal transfer instead.

            // We use the internal amount here and then scale it to the external amount so that there is
            // no loss of precision between our internal accounting and the external account. In this case
            // there will be no dust accrual in underlying tokens since we will transfer the exact amount
            // of underlying that was received.

            actualTransferAmountExternal = assetToken.redeem(
                balanceState.currencyId,
                account,
                // No overflow, checked above
                uint256(assetTransferAmountExternal.neg())
            );

            // In this case we're transferring underlying tokens, we want to convert the internal
            // asset transfer amount to store in cash balances
            assetTransferAmountInternal = assetToken.convertToInternal(assetTransferAmountExternal);
        } else {
            // NOTE: in the case of aTokens assetTransferAmountExternal is the scaledBalanceOf in external precision, it
            // will be converted to balanceOf denomination inside transfer
            actualTransferAmountExternal = assetToken.transfer(account, balanceState.currencyId, assetTransferAmountExternal);
            // Convert the actual transferred amount
            assetTransferAmountInternal = assetToken.convertToInternal(actualTransferAmountExternal);
        }
    }

    /// @notice Special method for settling negative current cash debts. This occurs when an account
    /// has a negative fCash balance settle to cash. A settler may come and force the account to borrow
    /// at the prevailing 3 month rate
    /// @dev Use this method to avoid any nToken and transfer logic in finalize which is unnecessary.
    function setBalanceStorageForSettleCashDebt(
        address account,
        CashGroupParameters memory cashGroup,
        int256 amountToSettleAsset,
        AccountContext memory accountContext
    ) internal returns (int256) {
        require(amountToSettleAsset >= 0); // dev: amount to settle negative
        (int256 cashBalance, int256 nTokenBalance, uint256 lastClaimTime, uint256 accountIncentiveDebt) =
            getBalanceStorage(account, cashGroup.currencyId);

        // Prevents settlement of positive balances
        require(cashBalance < 0, "Invalid settle balance");
        if (amountToSettleAsset == 0) {
            // Symbolizes that the entire debt should be settled
            amountToSettleAsset = cashBalance.neg();
            cashBalance = 0;
        } else {
            // A partial settlement of the debt
            require(amountToSettleAsset <= cashBalance.neg(), "Invalid amount to settle");
            cashBalance = cashBalance.add(amountToSettleAsset);
        }

        // NOTE: we do not update HAS_CASH_DEBT here because it is possible that the other balances
        // also have cash debts
        if (cashBalance == 0 && nTokenBalance == 0) {
            accountContext.setActiveCurrency(
                cashGroup.currencyId,
                false,
                Constants.ACTIVE_IN_BALANCES
            );
        }

        _setBalanceStorage(
            account,
            cashGroup.currencyId,
            cashBalance,
            nTokenBalance,
            lastClaimTime,
            accountIncentiveDebt
        );

        // Emit the event here, we do not call finalize
        emit CashBalanceChange(account, cashGroup.currencyId, amountToSettleAsset);

        return amountToSettleAsset;
    }

    /**
     * @notice A special balance storage method for fCash liquidation to reduce the bytecode size.
     */
    function setBalanceStorageForfCashLiquidation(
        address account,
        AccountContext memory accountContext,
        uint16 currencyId,
        int256 netCashChange
    ) internal {
        (int256 cashBalance, int256 nTokenBalance, uint256 lastClaimTime, uint256 accountIncentiveDebt) =
            getBalanceStorage(account, currencyId);

        int256 newCashBalance = cashBalance.add(netCashChange);
        // If a cash balance is negative already we cannot put an account further into debt. In this case
        // the netCashChange must be positive so that it is coming out of debt.
        if (newCashBalance < 0) {
            require(netCashChange > 0, "Neg Cash");
            // NOTE: HAS_CASH_DEBT cannot be extinguished except by a free collateral check
            // where all balances are examined. In this case the has cash debt flag should
            // already be set (cash balances cannot get more negative) but we do it again
            // here just to be safe.
            accountContext.hasDebt = accountContext.hasDebt | Constants.HAS_CASH_DEBT;
        }

        bool isActive = newCashBalance != 0 || nTokenBalance != 0;
        accountContext.setActiveCurrency(currencyId, isActive, Constants.ACTIVE_IN_BALANCES);

        // Emit the event here, we do not call finalize
        emit CashBalanceChange(account, currencyId, netCashChange);

        _setBalanceStorage(
            account,
            currencyId,
            newCashBalance,
            nTokenBalance,
            lastClaimTime,
            accountIncentiveDebt
        );
    }

    /// @notice Helper method for settling the output of the SettleAssets method
    function finalizeSettleAmounts(
        address account,
        AccountContext memory accountContext,
        SettleAmount[] memory settleAmounts
    ) internal {
        for (uint256 i = 0; i < settleAmounts.length; i++) {
            SettleAmount memory amt = settleAmounts[i];
            if (amt.netCashChange == 0) continue;

            (
                int256 cashBalance,
                int256 nTokenBalance,
                uint256 lastClaimTime,
                uint256 accountIncentiveDebt
            ) = getBalanceStorage(account, amt.currencyId);

            cashBalance = cashBalance.add(amt.netCashChange);
            accountContext.setActiveCurrency(
                amt.currencyId,
                cashBalance != 0 || nTokenBalance != 0,
                Constants.ACTIVE_IN_BALANCES
            );

            if (cashBalance < 0) {
                accountContext.hasDebt = accountContext.hasDebt | Constants.HAS_CASH_DEBT;
            }

            emit CashBalanceChange(
                account,
                uint16(amt.currencyId),
                amt.netCashChange
            );

            _setBalanceStorage(
                account,
                amt.currencyId,
                cashBalance,
                nTokenBalance,
                lastClaimTime,
                accountIncentiveDebt
            );
        }
    }

    /// @notice Special method for setting balance storage for nToken
    function setBalanceStorageForNToken(
        address nTokenAddress,
        uint256 currencyId,
        int256 cashBalance
    ) internal {
        require(cashBalance >= 0); // dev: invalid nToken cash balance
        _setBalanceStorage(nTokenAddress, currencyId, cashBalance, 0, 0, 0);
    }

    /// @notice increments fees to the reserve
    function incrementFeeToReserve(uint256 currencyId, int256 fee) internal {
        require(fee >= 0); // dev: invalid fee
        // prettier-ignore
        (int256 totalReserve, /* */, /* */, /* */) = getBalanceStorage(Constants.RESERVE, currencyId);
        totalReserve = totalReserve.add(fee);
        _setBalanceStorage(Constants.RESERVE, currencyId, totalReserve, 0, 0, 0);
        emit ReserveFeeAccrued(uint16(currencyId), fee);
    }

    /// @notice harvests excess reserve balance
    function harvestExcessReserveBalance(uint16 currencyId, int256 reserve, int256 assetInternalRedeemAmount) internal {
        // parameters are validated by the caller
        reserve = reserve.subNoNeg(assetInternalRedeemAmount);
        _setBalanceStorage(Constants.RESERVE, currencyId, reserve, 0, 0, 0);
        emit ExcessReserveBalanceHarvested(currencyId, assetInternalRedeemAmount);
    }

    /// @notice sets the reserve balance, see TreasuryAction.setReserveCashBalance
    function setReserveCashBalance(uint16 currencyId, int256 newBalance) internal {
        require(newBalance >= 0); // dev: invalid balance
        _setBalanceStorage(Constants.RESERVE, currencyId, newBalance, 0, 0, 0);
        emit ReserveBalanceUpdated(currencyId, newBalance);
    }

    /// @notice Sets internal balance storage.
    function _setBalanceStorage(
        address account,
        uint256 currencyId,
        int256 cashBalance,
        int256 nTokenBalance,
        uint256 lastClaimTime,
        uint256 accountIncentiveDebt
    ) private {
        mapping(address => mapping(uint256 => BalanceStorage)) storage store = LibStorage.getBalanceStorage();
        BalanceStorage storage balanceStorage = store[account][currencyId];

        require(cashBalance >= type(int88).min && cashBalance <= type(int88).max); // dev: stored cash balance overflow
        // Allows for 12 quadrillion nToken balance in 1e8 decimals before overflow
        require(nTokenBalance >= 0 && nTokenBalance <= type(uint80).max); // dev: stored nToken balance overflow

        if (lastClaimTime == 0) {
            // In this case the account has migrated and we set the accountIncentiveDebt
            // The maximum NOTE supply is 100_000_000e8 (1e16) which is less than 2^56 (7.2e16) so we should never
            // encounter an overflow for accountIncentiveDebt
            require(accountIncentiveDebt <= type(uint56).max); // dev: account incentive debt overflow
            balanceStorage.accountIncentiveDebt = uint56(accountIncentiveDebt);
        } else {
            // In this case the last claim time has not changed and we do not update the last integral supply
            // (stored in the accountIncentiveDebt position)
            require(lastClaimTime == balanceStorage.lastClaimTime);
        }

        balanceStorage.lastClaimTime = uint32(lastClaimTime);
        balanceStorage.nTokenBalance = uint80(nTokenBalance);
        balanceStorage.cashBalance = int88(cashBalance);
    }

    /// @notice Gets internal balance storage, nTokens are stored alongside cash balances
    function getBalanceStorage(address account, uint256 currencyId)
        internal
        view
        returns (
            int256 cashBalance,
            int256 nTokenBalance,
            uint256 lastClaimTime,
            uint256 accountIncentiveDebt
        )
    {
        mapping(address => mapping(uint256 => BalanceStorage)) storage store = LibStorage.getBalanceStorage();
        BalanceStorage storage balanceStorage = store[account][currencyId];

        nTokenBalance = balanceStorage.nTokenBalance;
        lastClaimTime = balanceStorage.lastClaimTime;
        if (lastClaimTime > 0) {
            // NOTE: this is only necessary to support the deprecated integral supply values, which are stored
            // in the accountIncentiveDebt slot
            accountIncentiveDebt = FloatingPoint56.unpackFrom56Bits(balanceStorage.accountIncentiveDebt);
        } else {
            accountIncentiveDebt = balanceStorage.accountIncentiveDebt;
        }
        cashBalance = balanceStorage.cashBalance;
    }

    /// @notice Loads a balance state memory object
    /// @dev Balance state objects occupy a lot of memory slots, so this method allows
    /// us to reuse them if possible
    function loadBalanceState(
        BalanceState memory balanceState,
        address account,
        uint16 currencyId,
        AccountContext memory accountContext
    ) internal view {
        require(0 < currencyId && currencyId <= Constants.MAX_CURRENCIES); // dev: invalid currency id
        balanceState.currencyId = currencyId;

        if (accountContext.isActiveInBalances(currencyId)) {
            (
                balanceState.storedCashBalance,
                balanceState.storedNTokenBalance,
                balanceState.lastClaimTime,
                balanceState.accountIncentiveDebt
            ) = getBalanceStorage(account, currencyId);
        } else {
            balanceState.storedCashBalance = 0;
            balanceState.storedNTokenBalance = 0;
            balanceState.lastClaimTime = 0;
            balanceState.accountIncentiveDebt = 0;
        }

        balanceState.netCashChange = 0;
        balanceState.netAssetTransferInternalPrecision = 0;
        balanceState.netNTokenTransfer = 0;
        balanceState.netNTokenSupplyChange = 0;
    }

    /// @notice Used when manually claiming incentives in nTokenAction. Also sets the balance state
    /// to storage to update the accountIncentiveDebt. lastClaimTime will be set to zero as accounts
    /// are migrated to the new incentive calculation
    function claimIncentivesManual(BalanceState memory balanceState, address account)
        internal
        returns (uint256 incentivesClaimed)
    {
        incentivesClaimed = Incentives.claimIncentives(
            balanceState,
            account,
            balanceState.storedNTokenBalance.toUint()
        );

        _setBalanceStorage(
            account,
            balanceState.currencyId,
            balanceState.storedCashBalance,
            balanceState.storedNTokenBalance,
            balanceState.lastClaimTime,
            balanceState.accountIncentiveDebt
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "./TransferAssets.sol";
import "../valuation/AssetHandler.sol";
import "../../math/SafeInt256.sol";
import "../../global/LibStorage.sol";

/// @notice Handles the management of an array of assets including reading from storage, inserting
/// updating, deleting and writing back to storage.
library PortfolioHandler {
    using SafeInt256 for int256;
    using AssetHandler for PortfolioAsset;

    // Mirror of LibStorage.MAX_PORTFOLIO_ASSETS
    uint256 private constant MAX_PORTFOLIO_ASSETS = 16;

    /// @notice Primarily used by the TransferAssets library
    function addMultipleAssets(PortfolioState memory portfolioState, PortfolioAsset[] memory assets)
        internal
        pure
    {
        for (uint256 i = 0; i < assets.length; i++) {
            PortfolioAsset memory asset = assets[i];
            if (asset.notional == 0) continue;

            addAsset(
                portfolioState,
                asset.currencyId,
                asset.maturity,
                asset.assetType,
                asset.notional
            );
        }
    }

    function _mergeAssetIntoArray(
        PortfolioAsset[] memory assetArray,
        uint256 currencyId,
        uint256 maturity,
        uint256 assetType,
        int256 notional
    ) private pure returns (bool) {
        for (uint256 i = 0; i < assetArray.length; i++) {
            PortfolioAsset memory asset = assetArray[i];
            if (
                asset.assetType != assetType ||
                asset.currencyId != currencyId ||
                asset.maturity != maturity
            ) continue;

            // Either of these storage states mean that some error in logic has occurred, we cannot
            // store this portfolio
            require(
                asset.storageState != AssetStorageState.Delete &&
                asset.storageState != AssetStorageState.RevertIfStored
            ); // dev: portfolio handler deleted storage

            int256 newNotional = asset.notional.add(notional);
            // Liquidity tokens cannot be reduced below zero.
            if (AssetHandler.isLiquidityToken(assetType)) {
                require(newNotional >= 0); // dev: portfolio handler negative liquidity token balance
            }

            require(newNotional >= type(int88).min && newNotional <= type(int88).max); // dev: portfolio handler notional overflow

            asset.notional = newNotional;
            asset.storageState = AssetStorageState.Update;

            return true;
        }

        return false;
    }

    /// @notice Adds an asset to a portfolio state in memory (does not write to storage)
    /// @dev Ensures that only one version of an asset exists in a portfolio (i.e. does not allow two fCash assets of the same maturity
    /// to exist in a single portfolio). Also ensures that liquidity tokens do not have a negative notional.
    function addAsset(
        PortfolioState memory portfolioState,
        uint256 currencyId,
        uint256 maturity,
        uint256 assetType,
        int256 notional
    ) internal pure {
        if (
            // Will return true if merged
            _mergeAssetIntoArray(
                portfolioState.storedAssets,
                currencyId,
                maturity,
                assetType,
                notional
            )
        ) return;

        if (portfolioState.lastNewAssetIndex > 0) {
            bool merged = _mergeAssetIntoArray(
                portfolioState.newAssets,
                currencyId,
                maturity,
                assetType,
                notional
            );
            if (merged) return;
        }

        // At this point if we have not merged the asset then append to the array
        // Cannot remove liquidity that the portfolio does not have
        if (AssetHandler.isLiquidityToken(assetType)) {
            require(notional >= 0); // dev: portfolio handler negative liquidity token balance
        }
        require(notional >= type(int88).min && notional <= type(int88).max); // dev: portfolio handler notional overflow

        // Need to provision a new array at this point
        if (portfolioState.lastNewAssetIndex == portfolioState.newAssets.length) {
            portfolioState.newAssets = _extendNewAssetArray(portfolioState.newAssets);
        }

        // Otherwise add to the new assets array. It should not be possible to add matching assets in a single transaction, we will
        // check this again when we write to storage. Assigning to memory directly here, do not allocate new memory via struct.
        PortfolioAsset memory newAsset = portfolioState.newAssets[portfolioState.lastNewAssetIndex];
        newAsset.currencyId = currencyId;
        newAsset.maturity = maturity;
        newAsset.assetType = assetType;
        newAsset.notional = notional;
        newAsset.storageState = AssetStorageState.NoChange;
        portfolioState.lastNewAssetIndex += 1;
    }

    /// @dev Extends the new asset array if it is not large enough, this is likely to get a bit expensive if we do
    /// it too much
    function _extendNewAssetArray(PortfolioAsset[] memory newAssets)
        private
        pure
        returns (PortfolioAsset[] memory)
    {
        // Double the size of the new asset array every time we have to extend to reduce the number of times
        // that we have to extend it. This will go: 0, 1, 2, 4, 8 (probably stops there).
        uint256 newLength = newAssets.length == 0 ? 1 : newAssets.length * 2;
        PortfolioAsset[] memory extendedArray = new PortfolioAsset[](newLength);
        for (uint256 i = 0; i < newAssets.length; i++) {
            extendedArray[i] = newAssets[i];
        }

        return extendedArray;
    }

    /// @notice Takes a portfolio state and writes it to storage.
    /// @dev This method should only be called directly by the nToken. Account updates to portfolios should happen via
    /// the storeAssetsAndUpdateContext call in the AccountContextHandler.sol library.
    /// @return updated variables to update the account context with
    ///     hasDebt: whether or not the portfolio has negative fCash assets
    ///     portfolioActiveCurrencies: a byte32 word with all the currencies in the portfolio
    ///     uint8: the length of the storage array
    ///     uint40: the new nextSettleTime for the portfolio
    function storeAssets(PortfolioState memory portfolioState, address account)
        internal
        returns (
            bool,
            bytes32,
            uint8,
            uint40
        )
    {
        bool hasDebt;
        // NOTE: cannot have more than 16 assets or this byte object will overflow. Max assets is
        // set to 7 and the worst case during liquidation would be 7 liquidity tokens that generate
        // 7 additional fCash assets for a total of 14 assets. Although even in this case all assets
        // would be of the same currency so it would not change the end result of the active currency
        // calculation.
        bytes32 portfolioActiveCurrencies;
        uint256 nextSettleTime;

        for (uint256 i = 0; i < portfolioState.storedAssets.length; i++) {
            PortfolioAsset memory asset = portfolioState.storedAssets[i];
            // NOTE: this is to prevent the storage of assets that have been modified in the AssetHandler
            // during valuation.
            require(asset.storageState != AssetStorageState.RevertIfStored);

            // Mark any zero notional assets as deleted
            if (asset.storageState != AssetStorageState.Delete && asset.notional == 0) {
                deleteAsset(portfolioState, i);
            }
        }

        // First delete assets from asset storage to maintain asset storage indexes
        for (uint256 i = 0; i < portfolioState.storedAssets.length; i++) {
            PortfolioAsset memory asset = portfolioState.storedAssets[i];

            if (asset.storageState == AssetStorageState.Delete) {
                // Delete asset from storage
                uint256 currentSlot = asset.storageSlot;
                assembly {
                    sstore(currentSlot, 0x00)
                }
            } else {
                if (asset.storageState == AssetStorageState.Update) {
                    PortfolioAssetStorage storage assetStorage;
                    uint256 currentSlot = asset.storageSlot;
                    assembly {
                        assetStorage.slot := currentSlot
                    }

                    _storeAsset(asset, assetStorage);
                }

                // Update portfolio context for every asset that is in storage, whether it is
                // updated in storage or not.
                (hasDebt, portfolioActiveCurrencies, nextSettleTime) = _updatePortfolioContext(
                    asset,
                    hasDebt,
                    portfolioActiveCurrencies,
                    nextSettleTime
                );
            }
        }

        // Add new assets
        uint256 assetStorageLength = portfolioState.storedAssetLength;
        mapping(address => 
            PortfolioAssetStorage[MAX_PORTFOLIO_ASSETS]) storage store = LibStorage.getPortfolioArrayStorage();
        PortfolioAssetStorage[MAX_PORTFOLIO_ASSETS] storage storageArray = store[account];
        for (uint256 i = 0; i < portfolioState.newAssets.length; i++) {
            PortfolioAsset memory asset = portfolioState.newAssets[i];
            if (asset.notional == 0) continue;
            require(
                asset.storageState != AssetStorageState.Delete &&
                asset.storageState != AssetStorageState.RevertIfStored
            ); // dev: store assets deleted storage

            (hasDebt, portfolioActiveCurrencies, nextSettleTime) = _updatePortfolioContext(
                asset,
                hasDebt,
                portfolioActiveCurrencies,
                nextSettleTime
            );

            _storeAsset(asset, storageArray[assetStorageLength]);
            assetStorageLength += 1;
        }

        // 16 is the maximum number of assets or portfolio active currencies will overflow at 32 bytes with
        // 2 bytes per currency
        require(assetStorageLength <= 16 && nextSettleTime <= type(uint40).max); // dev: portfolio return value overflow
        return (
            hasDebt,
            portfolioActiveCurrencies,
            uint8(assetStorageLength),
            uint40(nextSettleTime)
        );
    }

    /// @notice Updates context information during the store assets method
    function _updatePortfolioContext(
        PortfolioAsset memory asset,
        bool hasDebt,
        bytes32 portfolioActiveCurrencies,
        uint256 nextSettleTime
    )
        private
        pure
        returns (
            bool,
            bytes32,
            uint256
        )
    {
        uint256 settlementDate = asset.getSettlementDate();
        // Tis will set it to the minimum settlement date
        if (nextSettleTime == 0 || nextSettleTime > settlementDate) {
            nextSettleTime = settlementDate;
        }
        hasDebt = hasDebt || asset.notional < 0;

        require(uint16(uint256(portfolioActiveCurrencies)) == 0); // dev: portfolio active currencies overflow
        portfolioActiveCurrencies = (portfolioActiveCurrencies >> 16) | (bytes32(asset.currencyId) << 240);

        return (hasDebt, portfolioActiveCurrencies, nextSettleTime);
    }

    /// @dev Encodes assets for storage
    function _storeAsset(
        PortfolioAsset memory asset,
        PortfolioAssetStorage storage assetStorage
    ) internal {
        require(0 < asset.currencyId && asset.currencyId <= Constants.MAX_CURRENCIES); // dev: encode asset currency id overflow
        require(0 < asset.maturity && asset.maturity <= type(uint40).max); // dev: encode asset maturity overflow
        require(0 < asset.assetType && asset.assetType <= Constants.MAX_LIQUIDITY_TOKEN_INDEX); // dev: encode asset type invalid
        require(type(int88).min <= asset.notional && asset.notional <= type(int88).max); // dev: encode asset notional overflow

        assetStorage.currencyId = uint16(asset.currencyId);
        assetStorage.maturity = uint40(asset.maturity);
        assetStorage.assetType = uint8(asset.assetType);
        assetStorage.notional = int88(asset.notional);
    }

    /// @notice Deletes an asset from a portfolio
    /// @dev This method should only be called during settlement, assets can only be removed from a portfolio before settlement
    /// by adding the offsetting negative position
    function deleteAsset(PortfolioState memory portfolioState, uint256 index) internal pure {
        require(index < portfolioState.storedAssets.length); // dev: stored assets bounds
        require(portfolioState.storedAssetLength > 0); // dev: stored assets length is zero
        PortfolioAsset memory assetToDelete = portfolioState.storedAssets[index];
        require(
            assetToDelete.storageState != AssetStorageState.Delete &&
            assetToDelete.storageState != AssetStorageState.RevertIfStored
        ); // dev: cannot delete asset

        portfolioState.storedAssetLength -= 1;

        uint256 maxActiveSlotIndex;
        uint256 maxActiveSlot;
        // The max active slot is the last storage slot where an asset exists, it's not clear where this will be in the
        // array so we search for it here.
        for (uint256 i; i < portfolioState.storedAssets.length; i++) {
            PortfolioAsset memory a = portfolioState.storedAssets[i];
            if (a.storageSlot > maxActiveSlot && a.storageState != AssetStorageState.Delete) {
                maxActiveSlot = a.storageSlot;
                maxActiveSlotIndex = i;
            }
        }

        if (index == maxActiveSlotIndex) {
            // In this case we are deleting the asset with the max storage slot so no swap is necessary.
            assetToDelete.storageState = AssetStorageState.Delete;
            return;
        }

        // Swap the storage slots of the deleted asset with the last non-deleted asset in the array. Mark them accordingly
        // so that when we call store assets they will be updated appropriately
        PortfolioAsset memory assetToSwap = portfolioState.storedAssets[maxActiveSlotIndex];
        (
            assetToSwap.storageSlot,
            assetToDelete.storageSlot
        ) = (
            assetToDelete.storageSlot,
            assetToSwap.storageSlot
        );
        assetToSwap.storageState = AssetStorageState.Update;
        assetToDelete.storageState = AssetStorageState.Delete;
    }

    /// @notice Returns a portfolio array, will be sorted
    function getSortedPortfolio(address account, uint8 assetArrayLength)
        internal
        view
        returns (PortfolioAsset[] memory)
    {
        PortfolioAsset[] memory assets = _loadAssetArray(account, assetArrayLength);
        // No sorting required for length of 1
        if (assets.length <= 1) return assets;

        _sortInPlace(assets);
        return assets;
    }

    /// @notice Builds a portfolio array from storage. The new assets hint parameter will
    /// be used to provision a new array for the new assets. This will increase gas efficiency
    /// so that we don't have to make copies when we extend the array.
    function buildPortfolioState(
        address account,
        uint8 assetArrayLength,
        uint256 newAssetsHint
    ) internal view returns (PortfolioState memory) {
        PortfolioState memory state;
        if (assetArrayLength == 0) return state;

        state.storedAssets = getSortedPortfolio(account, assetArrayLength);
        state.storedAssetLength = assetArrayLength;
        state.newAssets = new PortfolioAsset[](newAssetsHint);

        return state;
    }

    function _sortInPlace(PortfolioAsset[] memory assets) private pure {
        uint256 length = assets.length;
        uint256[] memory ids = new uint256[](length);
        for (uint256 k; k < length; k++) {
            PortfolioAsset memory asset = assets[k];
            // Prepopulate the ids to calculate just once
            ids[k] = TransferAssets.encodeAssetId(asset.currencyId, asset.maturity, asset.assetType);
        }

        // Uses insertion sort 
        uint256 i = 1;
        while (i < length) {
            uint256 j = i;
            while (j > 0 && ids[j - 1] > ids[j]) {
                // Swap j - 1 and j
                (ids[j - 1], ids[j]) = (ids[j], ids[j - 1]);
                (assets[j - 1], assets[j]) = (assets[j], assets[j - 1]);
                j--;
            }
            i++;
        }
    }

    function _loadAssetArray(address account, uint8 length)
        private
        view
        returns (PortfolioAsset[] memory)
    {
        // This will overflow the storage pointer
        require(length <= MAX_PORTFOLIO_ASSETS);

        mapping(address => 
            PortfolioAssetStorage[MAX_PORTFOLIO_ASSETS]) storage store = LibStorage.getPortfolioArrayStorage();
        PortfolioAssetStorage[MAX_PORTFOLIO_ASSETS] storage storageArray = store[account];
        PortfolioAsset[] memory assets = new PortfolioAsset[](length);

        for (uint256 i = 0; i < length; i++) {
            PortfolioAssetStorage storage assetStorage = storageArray[i];
            PortfolioAsset memory asset = assets[i];
            uint256 slot;
            assembly {
                slot := assetStorage.slot
            }

            asset.currencyId = assetStorage.currencyId;
            asset.maturity = assetStorage.maturity;
            asset.assetType = assetStorage.assetType;
            asset.notional = assetStorage.notional;
            asset.storageSlot = slot;
        }

        return assets;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "./Types.sol";
import "./Constants.sol";
import "../../interfaces/notional/IRewarder.sol";
import "../../interfaces/aave/ILendingPool.sol";

library LibStorage {

    /// @dev Offset for the initial slot in lib storage, gives us this number of storage slots
    /// available in StorageLayoutV1 and all subsequent storage layouts that inherit from it.
    uint256 private constant STORAGE_SLOT_BASE = 1000000;
    /// @dev Set to MAX_TRADED_MARKET_INDEX * 2, Solidity does not allow assigning constants from imported values
    uint256 private constant NUM_NTOKEN_MARKET_FACTORS = 14;
    /// @dev Theoretical maximum for MAX_PORTFOLIO_ASSETS, however, we limit this to MAX_TRADED_MARKET_INDEX
    /// in practice. It is possible to exceed that value during liquidation up to 14 potential assets.
    uint256 private constant MAX_PORTFOLIO_ASSETS = 16;

    /// @dev Storage IDs for storage buckets. Each id maps to an internal storage
    /// slot used for a particular mapping
    ///     WARNING: APPEND ONLY
    enum StorageId {
        Unused,
        AccountStorage,
        nTokenContext,
        nTokenAddress,
        nTokenDeposit,
        nTokenInitialization,
        Balance,
        Token,
        SettlementRate,
        CashGroup,
        Market,
        AssetsBitmap,
        ifCashBitmap,
        PortfolioArray,
        // WARNING: this nTokenTotalSupply storage object was used for a buggy version
        // of the incentives calculation. It should only be used for accounts who have
        // not claimed before the migration
        nTokenTotalSupply_deprecated,
        AssetRate,
        ExchangeRate,
        nTokenTotalSupply,
        SecondaryIncentiveRewarder,
        LendingPool
    }

    /// @dev Mapping from an account address to account context
    function getAccountStorage() internal pure 
        returns (mapping(address => AccountContext) storage store) 
    {
        uint256 slot = _getStorageSlot(StorageId.AccountStorage);
        assembly { store.slot := slot }
    }

    /// @dev Mapping from an nToken address to nTokenContext
    function getNTokenContextStorage() internal pure
        returns (mapping(address => nTokenContext) storage store) 
    {
        uint256 slot = _getStorageSlot(StorageId.nTokenContext);
        assembly { store.slot := slot }
    }

    /// @dev Mapping from currency id to nTokenAddress
    function getNTokenAddressStorage() internal pure
        returns (mapping(uint256 => address) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.nTokenAddress);
        assembly { store.slot := slot }
    }

    /// @dev Mapping from currency id to uint32 fixed length array of
    /// deposit factors. Deposit shares and leverage thresholds are stored striped to
    /// reduce the number of storage reads.
    function getNTokenDepositStorage() internal pure
        returns (mapping(uint256 => uint32[NUM_NTOKEN_MARKET_FACTORS]) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.nTokenDeposit);
        assembly { store.slot := slot }
    }

    /// @dev Mapping from currency id to fixed length array of initialization factors,
    /// stored striped like deposit shares.
    function getNTokenInitStorage() internal pure
        returns (mapping(uint256 => uint32[NUM_NTOKEN_MARKET_FACTORS]) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.nTokenInitialization);
        assembly { store.slot := slot }
    }

    /// @dev Mapping from account to currencyId to it's balance storage for that currency
    function getBalanceStorage() internal pure
        returns (mapping(address => mapping(uint256 => BalanceStorage)) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.Balance);
        assembly { store.slot := slot }
    }

    /// @dev Mapping from currency id to a boolean for underlying or asset token to
    /// the TokenStorage
    function getTokenStorage() internal pure
        returns (mapping(uint256 => mapping(bool => TokenStorage)) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.Token);
        assembly { store.slot := slot }
    }

    /// @dev Mapping from currency id to maturity to its corresponding SettlementRate
    function getSettlementRateStorage() internal pure
        returns (mapping(uint256 => mapping(uint256 => SettlementRateStorage)) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.SettlementRate);
        assembly { store.slot := slot }
    }

    /// @dev Mapping from currency id to maturity to its tightly packed cash group parameters
    function getCashGroupStorage() internal pure
        returns (mapping(uint256 => bytes32) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.CashGroup);
        assembly { store.slot := slot }
    }

    /// @dev Mapping from currency id to maturity to settlement date for a market
    function getMarketStorage() internal pure
        returns (mapping(uint256 => mapping(uint256 => mapping(uint256 => MarketStorage))) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.Market);
        assembly { store.slot := slot }
    }

    /// @dev Mapping from account to currency id to its assets bitmap
    function getAssetsBitmapStorage() internal pure
        returns (mapping(address => mapping(uint256 => bytes32)) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.AssetsBitmap);
        assembly { store.slot := slot }
    }

    /// @dev Mapping from account to currency id to its maturity to its corresponding ifCash balance
    function getifCashBitmapStorage() internal pure
        returns (mapping(address => mapping(uint256 => mapping(uint256 => ifCashStorage))) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.ifCashBitmap);
        assembly { store.slot := slot }
    }

    /// @dev Mapping from account to its fixed length array of portfolio assets
    function getPortfolioArrayStorage() internal pure
        returns (mapping(address => PortfolioAssetStorage[MAX_PORTFOLIO_ASSETS]) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.PortfolioArray);
        assembly { store.slot := slot }
    }

    function getDeprecatedNTokenTotalSupplyStorage() internal pure
        returns (mapping(address => nTokenTotalSupplyStorage_deprecated) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.nTokenTotalSupply_deprecated);
        assembly { store.slot := slot }
    }

    /// @dev Mapping from nToken address to its total supply values
    function getNTokenTotalSupplyStorage() internal pure
        returns (mapping(address => nTokenTotalSupplyStorage) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.nTokenTotalSupply);
        assembly { store.slot := slot }
    }

    /// @dev Returns the exchange rate between an underlying currency and asset for trading
    /// and free collateral. Mapping is from currency id to rate storage object.
    function getAssetRateStorage() internal pure
        returns (mapping(uint256 => AssetRateStorage) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.AssetRate);
        assembly { store.slot := slot }
    }

    /// @dev Returns the exchange rate between an underlying currency and ETH for free
    /// collateral purposes. Mapping is from currency id to rate storage object.
    function getExchangeRateStorage() internal pure
        returns (mapping(uint256 => ETHRateStorage) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.ExchangeRate);
        assembly { store.slot := slot }
    }

    /// @dev Returns the address of a secondary incentive rewarder for an nToken if it exists
    function getSecondaryIncentiveRewarder() internal pure
        returns (mapping(address => IRewarder) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.SecondaryIncentiveRewarder);
        assembly { store.slot := slot }
    }

    /// @dev Returns the address of the lending pool
    function getLendingPool() internal pure returns (LendingPoolStorage storage store) {
        uint256 slot = _getStorageSlot(StorageId.LendingPool);
        assembly { store.slot := slot }
    }

    /// @dev Get the storage slot given a storage ID.
    /// @param storageId An entry in `StorageId`
    /// @return slot The storage slot.
    function _getStorageSlot(StorageId storageId)
        private
        pure
        returns (uint256 slot)
    {
        // This should never overflow with a reasonable `STORAGE_SLOT_EXP`
        // because Solidity will do a range check on `storageId` during the cast.
        return uint256(storageId) + STORAGE_SLOT_BASE;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "../../global/Constants.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

library DateTime {
    using SafeMath for uint256;

    /// @notice Returns the current reference time which is how all the AMM dates are calculated.
    function getReferenceTime(uint256 blockTime) internal pure returns (uint256) {
        require(blockTime >= Constants.QUARTER);
        return blockTime - (blockTime % Constants.QUARTER);
    }

    /// @notice Truncates a date to midnight UTC time
    function getTimeUTC0(uint256 time) internal pure returns (uint256) {
        require(time >= Constants.DAY);
        return time - (time % Constants.DAY);
    }

    /// @notice These are the predetermined market offsets for trading
    /// @dev Markets are 1-indexed because the 0 index means that no markets are listed for the cash group.
    function getTradedMarket(uint256 index) internal pure returns (uint256) {
        if (index == 1) return Constants.QUARTER;
        if (index == 2) return 2 * Constants.QUARTER;
        if (index == 3) return Constants.YEAR;
        if (index == 4) return 2 * Constants.YEAR;
        if (index == 5) return 5 * Constants.YEAR;
        if (index == 6) return 10 * Constants.YEAR;
        if (index == 7) return 20 * Constants.YEAR;

        revert("Invalid index");
    }

    /// @notice Determines if the maturity falls on one of the valid on chain market dates.
    function isValidMarketMaturity(
        uint256 maxMarketIndex,
        uint256 maturity,
        uint256 blockTime
    ) internal pure returns (bool) {
        require(maxMarketIndex > 0, "CG: no markets listed");
        require(maxMarketIndex <= Constants.MAX_TRADED_MARKET_INDEX, "CG: market index bound");

        if (maturity % Constants.QUARTER != 0) return false;
        uint256 tRef = DateTime.getReferenceTime(blockTime);

        for (uint256 i = 1; i <= maxMarketIndex; i++) {
            if (maturity == tRef.add(DateTime.getTradedMarket(i))) return true;
        }

        return false;
    }

    /// @notice Determines if an idiosyncratic maturity is valid and returns the bit reference that is the case.
    function isValidMaturity(
        uint256 maxMarketIndex,
        uint256 maturity,
        uint256 blockTime
    ) internal pure returns (bool) {
        uint256 tRef = DateTime.getReferenceTime(blockTime);
        uint256 maxMaturity = tRef.add(DateTime.getTradedMarket(maxMarketIndex));
        // Cannot trade past max maturity
        if (maturity > maxMaturity) return false;

        // prettier-ignore
        (/* */, bool isValid) = DateTime.getBitNumFromMaturity(blockTime, maturity);
        return isValid;
    }

    /// @notice Returns the market index for a given maturity, if the maturity is idiosyncratic
    /// will return the nearest market index that is larger than the maturity.
    /// @return uint marketIndex, bool isIdiosyncratic
    function getMarketIndex(
        uint256 maxMarketIndex,
        uint256 maturity,
        uint256 blockTime
    ) internal pure returns (uint256, bool) {
        require(maxMarketIndex > 0, "CG: no markets listed");
        require(maxMarketIndex <= Constants.MAX_TRADED_MARKET_INDEX, "CG: market index bound");
        uint256 tRef = DateTime.getReferenceTime(blockTime);

        for (uint256 i = 1; i <= maxMarketIndex; i++) {
            uint256 marketMaturity = tRef.add(DateTime.getTradedMarket(i));
            // If market matches then is not idiosyncratic
            if (marketMaturity == maturity) return (i, false);
            // Returns the market that is immediately greater than the maturity
            if (marketMaturity > maturity) return (i, true);
        }

        revert("CG: no market found");
    }

    /// @notice Given a bit number and the reference time of the first bit, returns the bit number
    /// of a given maturity.
    /// @return bitNum and a true or false if the maturity falls on the exact bit
    function getBitNumFromMaturity(uint256 blockTime, uint256 maturity)
        internal
        pure
        returns (uint256, bool)
    {
        uint256 blockTimeUTC0 = getTimeUTC0(blockTime);

        // Maturities must always divide days evenly
        if (maturity % Constants.DAY != 0) return (0, false);
        // Maturity cannot be in the past
        if (blockTimeUTC0 >= maturity) return (0, false);

        // Overflow check done above
        // daysOffset has no remainders, checked above
        uint256 daysOffset = (maturity - blockTimeUTC0) / Constants.DAY;

        // These if statements need to fall through to the next one
        if (daysOffset <= Constants.MAX_DAY_OFFSET) {
            return (daysOffset, true);
        } else if (daysOffset <= Constants.MAX_WEEK_OFFSET) {
            // (daysOffset - MAX_DAY_OFFSET) is the days overflow into the week portion, must be > 0
            // (blockTimeUTC0 % WEEK) / DAY is the offset into the week portion
            // This returns the offset from the previous max offset in days
            uint256 offsetInDays =
                daysOffset -
                    Constants.MAX_DAY_OFFSET +
                    (blockTimeUTC0 % Constants.WEEK) /
                    Constants.DAY;
            
            return (
                // This converts the offset in days to its corresponding bit position, truncating down
                // if it does not divide evenly into DAYS_IN_WEEK
                Constants.WEEK_BIT_OFFSET + offsetInDays / Constants.DAYS_IN_WEEK,
                (offsetInDays % Constants.DAYS_IN_WEEK) == 0
            );
        } else if (daysOffset <= Constants.MAX_MONTH_OFFSET) {
            uint256 offsetInDays =
                daysOffset -
                    Constants.MAX_WEEK_OFFSET +
                    (blockTimeUTC0 % Constants.MONTH) /
                    Constants.DAY;

            return (
                Constants.MONTH_BIT_OFFSET + offsetInDays / Constants.DAYS_IN_MONTH,
                (offsetInDays % Constants.DAYS_IN_MONTH) == 0
            );
        } else if (daysOffset <= Constants.MAX_QUARTER_OFFSET) {
            uint256 offsetInDays =
                daysOffset -
                    Constants.MAX_MONTH_OFFSET +
                    (blockTimeUTC0 % Constants.QUARTER) /
                    Constants.DAY;

            return (
                Constants.QUARTER_BIT_OFFSET + offsetInDays / Constants.DAYS_IN_QUARTER,
                (offsetInDays % Constants.DAYS_IN_QUARTER) == 0
            );
        }

        // This is the maximum 1-indexed bit num, it is never valid because it is beyond the 20
        // year max maturity
        return (256, false);
    }

    /// @notice Given a bit number and a block time returns the maturity that the bit number
    /// should reference. Bit numbers are one indexed.
    function getMaturityFromBitNum(uint256 blockTime, uint256 bitNum)
        internal
        pure
        returns (uint256)
    {
        require(bitNum != 0); // dev: cash group get maturity from bit num is zero
        require(bitNum <= 256); // dev: cash group get maturity from bit num overflow
        uint256 blockTimeUTC0 = getTimeUTC0(blockTime);
        uint256 firstBit;

        if (bitNum <= Constants.WEEK_BIT_OFFSET) {
            return blockTimeUTC0 + bitNum * Constants.DAY;
        } else if (bitNum <= Constants.MONTH_BIT_OFFSET) {
            firstBit =
                blockTimeUTC0 +
                Constants.MAX_DAY_OFFSET * Constants.DAY -
                // This backs up to the day that is divisible by a week
                (blockTimeUTC0 % Constants.WEEK);
            return firstBit + (bitNum - Constants.WEEK_BIT_OFFSET) * Constants.WEEK;
        } else if (bitNum <= Constants.QUARTER_BIT_OFFSET) {
            firstBit =
                blockTimeUTC0 +
                Constants.MAX_WEEK_OFFSET * Constants.DAY -
                (blockTimeUTC0 % Constants.MONTH);
            return firstBit + (bitNum - Constants.MONTH_BIT_OFFSET) * Constants.MONTH;
        } else {
            firstBit =
                blockTimeUTC0 +
                Constants.MAX_MONTH_OFFSET * Constants.DAY -
                (blockTimeUTC0 % Constants.QUARTER);
            return firstBit + (bitNum - Constants.QUARTER_BIT_OFFSET) * Constants.QUARTER;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "../../interfaces/chainlink/AggregatorV2V3Interface.sol";
import "../../interfaces/notional/AssetRateAdapter.sol";

/// @notice Different types of internal tokens
///  - UnderlyingToken: underlying asset for a cToken (except for Ether)
///  - cToken: Compound interest bearing token
///  - cETH: Special handling for cETH tokens
///  - Ether: the one and only
///  - NonMintable: tokens that do not have an underlying (therefore not cTokens)
///  - aToken: Aave interest bearing tokens
enum TokenType {
    UnderlyingToken,
    cToken,
    cETH,
    Ether,
    NonMintable,
    aToken
}

/// @notice Specifies the different trade action types in the system. Each trade action type is
/// encoded in a tightly packed bytes32 object. Trade action type is the first big endian byte of the
/// 32 byte trade action object. The schemas for each trade action type are defined below.
enum TradeActionType {
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 fCashAmount, uint32 minImpliedRate, uint120 unused)
    Lend,
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 fCashAmount, uint32 maxImpliedRate, uint128 unused)
    Borrow,
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 assetCashAmount, uint32 minImpliedRate, uint32 maxImpliedRate, uint88 unused)
    AddLiquidity,
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 tokenAmount, uint32 minImpliedRate, uint32 maxImpliedRate, uint88 unused)
    RemoveLiquidity,
    // (uint8 TradeActionType, uint32 Maturity, int88 fCashResidualAmount, uint128 unused)
    PurchaseNTokenResidual,
    // (uint8 TradeActionType, address CounterpartyAddress, int88 fCashAmountToSettle)
    SettleCashDebt
}

/// @notice Specifies different deposit actions that can occur during BalanceAction or BalanceActionWithTrades
enum DepositActionType {
    // No deposit action
    None,
    // Deposit asset cash, depositActionAmount is specified in asset cash external precision
    DepositAsset,
    // Deposit underlying tokens that are mintable to asset cash, depositActionAmount is specified in underlying token
    // external precision
    DepositUnderlying,
    // Deposits specified asset cash external precision amount into an nToken and mints the corresponding amount of
    // nTokens into the account
    DepositAssetAndMintNToken,
    // Deposits specified underlying in external precision, mints asset cash, and uses that asset cash to mint nTokens
    DepositUnderlyingAndMintNToken,
    // Redeems an nToken balance to asset cash. depositActionAmount is specified in nToken precision. Considered a deposit action
    // because it deposits asset cash into an account. If there are fCash residuals that cannot be sold off, will revert.
    RedeemNToken,
    // Converts specified amount of asset cash balance already in Notional to nTokens. depositActionAmount is specified in
    // Notional internal 8 decimal precision.
    ConvertCashToNToken
}

/// @notice Used internally for PortfolioHandler state
enum AssetStorageState {
    NoChange,
    Update,
    Delete,
    RevertIfStored
}

/****** Calldata objects ******/

/// @notice Defines a batch lending action
struct BatchLend {
    uint16 currencyId;
    // True if the contract should try to transfer underlying tokens instead of asset tokens
    bool depositUnderlying;
    // Array of tightly packed 32 byte objects that represent trades. See TradeActionType documentation
    bytes32[] trades;
}

/// @notice Defines a balance action for batchAction
struct BalanceAction {
    // Deposit action to take (if any)
    DepositActionType actionType;
    uint16 currencyId;
    // Deposit action amount must correspond to the depositActionType, see documentation above.
    uint256 depositActionAmount;
    // Withdraw an amount of asset cash specified in Notional internal 8 decimal precision
    uint256 withdrawAmountInternalPrecision;
    // If set to true, will withdraw entire cash balance. Useful if there may be an unknown amount of asset cash
    // residual left from trading.
    bool withdrawEntireCashBalance;
    // If set to true, will redeem asset cash to the underlying token on withdraw.
    bool redeemToUnderlying;
}

/// @notice Defines a balance action with a set of trades to do as well
struct BalanceActionWithTrades {
    DepositActionType actionType;
    uint16 currencyId;
    uint256 depositActionAmount;
    uint256 withdrawAmountInternalPrecision;
    bool withdrawEntireCashBalance;
    bool redeemToUnderlying;
    // Array of tightly packed 32 byte objects that represent trades. See TradeActionType documentation
    bytes32[] trades;
}

/****** In memory objects ******/
/// @notice Internal object that represents settled cash balances
struct SettleAmount {
    uint256 currencyId;
    int256 netCashChange;
}

/// @notice Internal object that represents a token
struct Token {
    address tokenAddress;
    bool hasTransferFee;
    int256 decimals;
    TokenType tokenType;
    uint256 maxCollateralBalance;
}

/// @notice Internal object that represents an nToken portfolio
struct nTokenPortfolio {
    CashGroupParameters cashGroup;
    PortfolioState portfolioState;
    int256 totalSupply;
    int256 cashBalance;
    uint256 lastInitializedTime;
    bytes6 parameters;
    address tokenAddress;
}

/// @notice Internal object used during liquidation
struct LiquidationFactors {
    address account;
    // Aggregate free collateral of the account denominated in ETH underlying, 8 decimal precision
    int256 netETHValue;
    // Amount of net local currency asset cash before haircuts and buffers available
    int256 localAssetAvailable;
    // Amount of net collateral currency asset cash before haircuts and buffers available
    int256 collateralAssetAvailable;
    // Haircut value of nToken holdings denominated in asset cash, will be local or collateral nTokens based
    // on liquidation type
    int256 nTokenHaircutAssetValue;
    // nToken parameters for calculating liquidation amount
    bytes6 nTokenParameters;
    // ETH exchange rate from local currency to ETH
    ETHRate localETHRate;
    // ETH exchange rate from collateral currency to ETH
    ETHRate collateralETHRate;
    // Asset rate for the local currency, used in cross currency calculations to calculate local asset cash required
    AssetRateParameters localAssetRate;
    // Used during currency liquidations if the account has liquidity tokens
    CashGroupParameters collateralCashGroup;
    // Used during currency liquidations if it is only a calculation, defaults to false
    bool isCalculation;
}

/// @notice Internal asset array portfolio state
struct PortfolioState {
    // Array of currently stored assets
    PortfolioAsset[] storedAssets;
    // Array of new assets to add
    PortfolioAsset[] newAssets;
    uint256 lastNewAssetIndex;
    // Holds the length of stored assets after accounting for deleted assets
    uint256 storedAssetLength;
}

/// @notice In memory ETH exchange rate used during free collateral calculation.
struct ETHRate {
    // The decimals (i.e. 10^rateDecimalPlaces) of the exchange rate, defined by the rate oracle
    int256 rateDecimals;
    // The exchange rate from base to ETH (if rate invert is required it is already done)
    int256 rate;
    // Amount of buffer as a multiple with a basis of 100 applied to negative balances.
    int256 buffer;
    // Amount of haircut as a multiple with a basis of 100 applied to positive balances
    int256 haircut;
    // Liquidation discount as a multiple with a basis of 100 applied to the exchange rate
    // as an incentive given to liquidators.
    int256 liquidationDiscount;
}

/// @notice Internal object used to handle balance state during a transaction
struct BalanceState {
    uint16 currencyId;
    // Cash balance stored in balance state at the beginning of the transaction
    int256 storedCashBalance;
    // nToken balance stored at the beginning of the transaction
    int256 storedNTokenBalance;
    // The net cash change as a result of asset settlement or trading
    int256 netCashChange;
    // Net asset transfers into or out of the account
    int256 netAssetTransferInternalPrecision;
    // Net token transfers into or out of the account
    int256 netNTokenTransfer;
    // Net token supply change from minting or redeeming
    int256 netNTokenSupplyChange;
    // The last time incentives were claimed for this currency
    uint256 lastClaimTime;
    // Accumulator for incentives that the account no longer has a claim over
    uint256 accountIncentiveDebt;
}

/// @dev Asset rate used to convert between underlying cash and asset cash
struct AssetRateParameters {
    // Address of the asset rate oracle
    AssetRateAdapter rateOracle;
    // The exchange rate from base to quote (if invert is required it is already done)
    int256 rate;
    // The decimals of the underlying, the rate converts to the underlying decimals
    int256 underlyingDecimals;
}

/// @dev Cash group when loaded into memory
struct CashGroupParameters {
    uint16 currencyId;
    uint256 maxMarketIndex;
    AssetRateParameters assetRate;
    bytes32 data;
}

/// @dev A portfolio asset when loaded in memory
struct PortfolioAsset {
    // Asset currency id
    uint256 currencyId;
    uint256 maturity;
    // Asset type, fCash or liquidity token.
    uint256 assetType;
    // fCash amount or liquidity token amount
    int256 notional;
    // Used for managing portfolio asset state
    uint256 storageSlot;
    // The state of the asset for when it is written to storage
    AssetStorageState storageState;
}

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

/****** Storage objects ******/

/// @dev Token object in storage:
///  20 bytes for token address
///  1 byte for hasTransferFee
///  1 byte for tokenType
///  1 byte for tokenDecimals
///  9 bytes for maxCollateralBalance (may not always be set)
struct TokenStorage {
    // Address of the token
    address tokenAddress;
    // Transfer fees will change token deposit behavior
    bool hasTransferFee;
    TokenType tokenType;
    uint8 decimalPlaces;
    // Upper limit on how much of this token the contract can hold at any time
    uint72 maxCollateralBalance;
}

/// @dev Exchange rate object as it is represented in storage, total storage is 25 bytes.
struct ETHRateStorage {
    // Address of the rate oracle
    AggregatorV2V3Interface rateOracle;
    // The decimal places of precision that the rate oracle uses
    uint8 rateDecimalPlaces;
    // True of the exchange rate must be inverted
    bool mustInvert;
    // NOTE: both of these governance values are set with BUFFER_DECIMALS precision
    // Amount of buffer to apply to the exchange rate for negative balances.
    uint8 buffer;
    // Amount of haircut to apply to the exchange rate for positive balances
    uint8 haircut;
    // Liquidation discount in percentage point terms, 106 means a 6% discount
    uint8 liquidationDiscount;
}

/// @dev Asset rate oracle object as it is represented in storage, total storage is 21 bytes.
struct AssetRateStorage {
    // Address of the rate oracle
    AssetRateAdapter rateOracle;
    // The decimal places of the underlying asset
    uint8 underlyingDecimalPlaces;
}

/// @dev Governance parameters for a cash group, total storage is 9 bytes + 7 bytes for liquidity token haircuts
/// and 7 bytes for rate scalars, total of 23 bytes. Note that this is stored packed in the storage slot so there
/// are no indexes stored for liquidityTokenHaircuts or rateScalars, maxMarketIndex is used instead to determine the
/// length.
struct CashGroupSettings {
    // Index of the AMMs on chain that will be made available. Idiosyncratic fCash
    // that is dated less than the longest AMM will be tradable.
    uint8 maxMarketIndex;
    // Time window in 5 minute increments that the rate oracle will be averaged over
    uint8 rateOracleTimeWindow5Min;
    // Total fees per trade, specified in BPS
    uint8 totalFeeBPS;
    // Share of the fees given to the protocol, denominated in percentage
    uint8 reserveFeeShare;
    // Debt buffer specified in 5 BPS increments
    uint8 debtBuffer5BPS;
    // fCash haircut specified in 5 BPS increments
    uint8 fCashHaircut5BPS;
    // If an account has a negative cash balance, it can be settled by incurring debt at the 3 month market. This
    // is the basis points for the penalty rate that will be added the current 3 month oracle rate.
    uint8 settlementPenaltyRate5BPS;
    // If an account has fCash that is being liquidated, this is the discount that the liquidator can purchase it for
    uint8 liquidationfCashHaircut5BPS;
    // If an account has fCash that is being liquidated, this is the discount that the liquidator can purchase it for
    uint8 liquidationDebtBuffer5BPS;
    // Liquidity token haircut applied to cash claims, specified as a percentage between 0 and 100
    uint8[] liquidityTokenHaircuts;
    // Rate scalar used to determine the slippage of the market
    uint8[] rateScalars;
}

/// @dev Holds account level context information used to determine settlement and
/// free collateral actions. Total storage is 28 bytes
struct AccountContext {
    // Used to check when settlement must be triggered on an account
    uint40 nextSettleTime;
    // For lenders that never incur debt, we use this flag to skip the free collateral check.
    bytes1 hasDebt;
    // Length of the account's asset array
    uint8 assetArrayLength;
    // If this account has bitmaps set, this is the corresponding currency id
    uint16 bitmapCurrencyId;
    // 9 total active currencies possible (2 bytes each)
    bytes18 activeCurrencies;
}

/// @dev Holds nToken context information mapped via the nToken address, total storage is
/// 16 bytes
struct nTokenContext {
    // Currency id that the nToken represents
    uint16 currencyId;
    // Annual incentive emission rate denominated in WHOLE TOKENS (multiply by
    // INTERNAL_TOKEN_PRECISION to get the actual rate)
    uint32 incentiveAnnualEmissionRate;
    // The last block time at utc0 that the nToken was initialized at, zero if it
    // has never been initialized
    uint32 lastInitializedTime;
    // Length of the asset array, refers to the number of liquidity tokens an nToken
    // currently holds
    uint8 assetArrayLength;
    // Each byte is a specific nToken parameter
    bytes5 nTokenParameters;
    // Reserved bytes for future usage
    bytes15 _unused;
    // Set to true if a secondary rewarder is set
    bool hasSecondaryRewarder;
}

/// @dev Holds account balance information, total storage 32 bytes
struct BalanceStorage {
    // Number of nTokens held by the account
    uint80 nTokenBalance;
    // Last time the account claimed their nTokens
    uint32 lastClaimTime;
    // Incentives that the account no longer has a claim over
    uint56 accountIncentiveDebt;
    // Cash balance of the account
    int88 cashBalance;
}

/// @dev Holds information about a settlement rate, total storage 25 bytes
struct SettlementRateStorage {
    uint40 blockTime;
    uint128 settlementRate;
    uint8 underlyingDecimalPlaces;
}

/// @dev Holds information about a market, total storage is 42 bytes so this spans
/// two storage words
struct MarketStorage {
    // Total fCash in the market
    uint80 totalfCash;
    // Total asset cash in the market
    uint80 totalAssetCash;
    // Last annualized interest rate the market traded at
    uint32 lastImpliedRate;
    // Last recorded oracle rate for the market
    uint32 oracleRate;
    // Last time a trade was made
    uint32 previousTradeTime;
    // This is stored in slot + 1
    uint80 totalLiquidity;
}

struct ifCashStorage {
    // Notional amount of fCash at the slot, limited to int128 to allow for
    // future expansion
    int128 notional;
}

/// @dev A single portfolio asset in storage, total storage of 19 bytes
struct PortfolioAssetStorage {
    // Currency Id for the asset
    uint16 currencyId;
    // Maturity of the asset
    uint40 maturity;
    // Asset type (fCash or Liquidity Token marker)
    uint8 assetType;
    // Notional
    int88 notional;
}

/// @dev nToken total supply factors for the nToken, includes factors related
/// to claiming incentives, total storage 32 bytes. This is the deprecated version
struct nTokenTotalSupplyStorage_deprecated {
    // Total supply of the nToken
    uint96 totalSupply;
    // Integral of the total supply used for calculating the average total supply
    uint128 integralTotalSupply;
    // Last timestamp the supply value changed, used for calculating the integralTotalSupply
    uint32 lastSupplyChangeTime;
}

/// @dev nToken total supply factors for the nToken, includes factors related
/// to claiming incentives, total storage 32 bytes.
struct nTokenTotalSupplyStorage {
    // Total supply of the nToken
    uint96 totalSupply;
    // How many NOTE incentives should be issued per nToken in 1e18 precision
    uint128 accumulatedNOTEPerNToken;
    // Last timestamp when the accumulation happened
    uint32 lastAccumulatedTime;
}

/// @dev Used in view methods to return account balances in a developer friendly manner
struct AccountBalance {
    uint16 currencyId;
    int256 cashBalance;
    int256 nTokenBalance;
    uint256 lastClaimTime;
    uint256 accountIncentiveDebt;
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.5.0 || ^0.6.0 || ^0.7.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    return int64 (x >> 64);
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    require (x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    require (x >= 0);
    return uint64 (x >> 64);
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    int256 result = x >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    return int256 (x) << 64;
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) + y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) - y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) * y >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    if (x == MIN_64x64) {
      require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
        y <= 0x1000000000000000000000000000000000000000000000000);
      return -y << 63;
    } else {
      bool negativeResult = false;
      if (x < 0) {
        x = -x;
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint256 absoluteResult = mulu (x, uint256 (y));
      if (negativeResult) {
        require (absoluteResult <=
          0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <=
          0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (absoluteResult);
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    if (y == 0) return 0;

    require (x >= 0);

    uint256 lo = (uint256 (x) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
    uint256 hi = uint256 (x) * (y >> 128);

    require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    hi <<= 64;

    require (hi <=
      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
    return hi + lo;
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    require (y != 0);
    int256 result = (int256 (x) << 64) / y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    require (y != 0);

    bool negativeResult = false;
    if (x < 0) {
      x = -x; // We rely on overflow behavior here
      negativeResult = true;
    }
    if (y < 0) {
      y = -y; // We rely on overflow behavior here
      negativeResult = !negativeResult;
    }
    uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    require (y != 0);
    uint128 result = divuu (x, y);
    require (result <= uint128 (MAX_64x64));
    return int128 (result);
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return -x;
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return x < 0 ? -x : x;
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    require (x != 0);
    int256 result = int256 (0x100000000000000000000000000000000) / x;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    return int128 ((int256 (x) + int256 (y)) >> 1);
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    int256 m = int256 (x) * int256 (y);
    require (m >= 0);
    require (m <
        0x4000000000000000000000000000000000000000000000000000000000000000);
    return int128 (sqrtu (uint256 (m)));
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    bool negative = x < 0 && y & 1 == 1;

    uint256 absX = uint128 (x < 0 ? -x : x);
    uint256 absResult;
    absResult = 0x100000000000000000000000000000000;

    if (absX <= 0x10000000000000000) {
      absX <<= 63;
      while (y != 0) {
        if (y & 0x1 != 0) {
          absResult = absResult * absX >> 127;
        }
        absX = absX * absX >> 127;

        if (y & 0x2 != 0) {
          absResult = absResult * absX >> 127;
        }
        absX = absX * absX >> 127;

        if (y & 0x4 != 0) {
          absResult = absResult * absX >> 127;
        }
        absX = absX * absX >> 127;

        if (y & 0x8 != 0) {
          absResult = absResult * absX >> 127;
        }
        absX = absX * absX >> 127;

        y >>= 4;
      }

      absResult >>= 64;
    } else {
      uint256 absXShift = 63;
      if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
      if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
      if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
      if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
      if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
      if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

      uint256 resultShift = 0;
      while (y != 0) {
        require (absXShift < 64);

        if (y & 0x1 != 0) {
          absResult = absResult * absX >> 127;
          resultShift += absXShift;
          if (absResult > 0x100000000000000000000000000000000) {
            absResult >>= 1;
            resultShift += 1;
          }
        }
        absX = absX * absX >> 127;
        absXShift <<= 1;
        if (absX >= 0x100000000000000000000000000000000) {
            absX >>= 1;
            absXShift += 1;
        }

        y >>= 1;
      }

      require (resultShift < 64);
      absResult >>= 64 - resultShift;
    }
    int256 result = negative ? -int256 (absResult) : int256 (absResult);
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    require (x >= 0);
    return int128 (sqrtu (uint256 (x) << 64));
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    require (x > 0);

    int256 msb = 0;
    int256 xc = x;
    if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
    if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
    if (xc >= 0x10000) { xc >>= 16; msb += 16; }
    if (xc >= 0x100) { xc >>= 8; msb += 8; }
    if (xc >= 0x10) { xc >>= 4; msb += 4; }
    if (xc >= 0x4) { xc >>= 2; msb += 2; }
    if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

    int256 result = msb - 64 << 64;
    uint256 ux = uint256 (x) << uint256 (127 - msb);
    for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
      ux *= ux;
      uint256 b = ux >> 255;
      ux >>= 127 + b;
      result += bit * int256 (b);
    }

    return int128 (result);
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    require (x > 0);

    return int128 (
        uint256 (log_2 (x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128);
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    uint256 result = 0x80000000000000000000000000000000;

    if (x & 0x8000000000000000 > 0)
      result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
    if (x & 0x4000000000000000 > 0)
      result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
    if (x & 0x2000000000000000 > 0)
      result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
    if (x & 0x1000000000000000 > 0)
      result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
    if (x & 0x800000000000000 > 0)
      result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
    if (x & 0x400000000000000 > 0)
      result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
    if (x & 0x200000000000000 > 0)
      result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
    if (x & 0x100000000000000 > 0)
      result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
    if (x & 0x80000000000000 > 0)
      result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
    if (x & 0x40000000000000 > 0)
      result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
    if (x & 0x20000000000000 > 0)
      result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
    if (x & 0x10000000000000 > 0)
      result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
    if (x & 0x8000000000000 > 0)
      result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
    if (x & 0x4000000000000 > 0)
      result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
    if (x & 0x2000000000000 > 0)
      result = result * 0x1000162E525EE054754457D5995292026 >> 128;
    if (x & 0x1000000000000 > 0)
      result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
    if (x & 0x800000000000 > 0)
      result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
    if (x & 0x400000000000 > 0)
      result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
    if (x & 0x200000000000 > 0)
      result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
    if (x & 0x100000000000 > 0)
      result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
    if (x & 0x80000000000 > 0)
      result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
    if (x & 0x40000000000 > 0)
      result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
    if (x & 0x20000000000 > 0)
      result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
    if (x & 0x10000000000 > 0)
      result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
    if (x & 0x8000000000 > 0)
      result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
    if (x & 0x4000000000 > 0)
      result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
    if (x & 0x2000000000 > 0)
      result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
    if (x & 0x1000000000 > 0)
      result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
    if (x & 0x800000000 > 0)
      result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
    if (x & 0x400000000 > 0)
      result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
    if (x & 0x200000000 > 0)
      result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
    if (x & 0x100000000 > 0)
      result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
    if (x & 0x80000000 > 0)
      result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
    if (x & 0x40000000 > 0)
      result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
    if (x & 0x20000000 > 0)
      result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
    if (x & 0x10000000 > 0)
      result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
    if (x & 0x8000000 > 0)
      result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
    if (x & 0x4000000 > 0)
      result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
    if (x & 0x2000000 > 0)
      result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
    if (x & 0x1000000 > 0)
      result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
    if (x & 0x800000 > 0)
      result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
    if (x & 0x400000 > 0)
      result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
    if (x & 0x200000 > 0)
      result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
    if (x & 0x100000 > 0)
      result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
    if (x & 0x80000 > 0)
      result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
    if (x & 0x40000 > 0)
      result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
    if (x & 0x20000 > 0)
      result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
    if (x & 0x10000 > 0)
      result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
    if (x & 0x8000 > 0)
      result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
    if (x & 0x4000 > 0)
      result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
    if (x & 0x2000 > 0)
      result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
    if (x & 0x1000 > 0)
      result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
    if (x & 0x800 > 0)
      result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
    if (x & 0x400 > 0)
      result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
    if (x & 0x200 > 0)
      result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
    if (x & 0x100 > 0)
      result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
    if (x & 0x80 > 0)
      result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
    if (x & 0x40 > 0)
      result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
    if (x & 0x20 > 0)
      result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
    if (x & 0x10 > 0)
      result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
    if (x & 0x8 > 0)
      result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
    if (x & 0x4 > 0)
      result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
    if (x & 0x2 > 0)
      result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
    if (x & 0x1 > 0)
      result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

    result >>= uint256 (63 - (x >> 64));
    require (result <= uint256 (MAX_64x64));

    return int128 (result);
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    return exp_2 (
        int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    require (y != 0);

    uint256 result;

    if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      result = (x << 64) / y;
    else {
      uint256 msb = 192;
      uint256 xc = x >> 192;
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 hi = result * (y >> 128);
      uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 xh = x >> 192;
      uint256 xl = x << 64;

      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here
      lo = hi << 128;
      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here

      assert (xh == hi >> 128);

      result += xl / y;
    }

    require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    return uint128 (result);
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    if (x == 0) return 0;
    else {
      uint256 xx = x;
      uint256 r = 1;
      if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
      if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
      if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
      if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
      if (xx >= 0x100) { xx >>= 8; r <<= 4; }
      if (xx >= 0x10) { xx >>= 4; r <<= 2; }
      if (xx >= 0x8) { r <<= 1; }
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1; // Seven iterations should be enough
      uint256 r1 = x / r;
      return uint128 (r < r1 ? r : r1);
    }
  }
}

// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.7.0;

/// @notice Used as a wrapper for tokens that are interest bearing for an
/// underlying token. Follows the cToken interface, however, can be adapted
/// for other interest bearing tokens.
interface AssetRateAdapter {
    function token() external view returns (address);

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function underlying() external view returns (address);

    function getExchangeRateStateful() external returns (int256);

    function getExchangeRateView() external view returns (int256);

    function getAnnualizedSupplyRate() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

interface IRewarder {
    function claimRewards(
        address account,
        uint16 currencyId,
        uint256 nTokenBalanceBefore,
        uint256 nTokenBalanceAfter,
        int256  netNTokenSupplyChange,
        uint256 NOTETokensClaimed
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

struct LendingPoolStorage {
  ILendingPool lendingPool;
}

interface ILendingPool {

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (ReserveData memory);

  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "./TokenHandler.sol";
import "../nToken/nTokenHandler.sol";
import "../nToken/nTokenSupply.sol";
import "../../math/SafeInt256.sol";
import "../../external/MigrateIncentives.sol";
import "../../../interfaces/notional/IRewarder.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

library Incentives {
    using SafeMath for uint256;
    using SafeInt256 for int256;

    /// @notice Calculates the total incentives to claim including those claimed under the previous
    /// less accurate calculation. Once an account is migrated it will only claim incentives under
    /// the more accurate regime
    function calculateIncentivesToClaim(
        BalanceState memory balanceState,
        address tokenAddress,
        uint256 accumulatedNOTEPerNToken,
        uint256 finalNTokenBalance
    ) internal view returns (uint256 incentivesToClaim) {
        if (balanceState.lastClaimTime > 0) {
            // If lastClaimTime is set then the account had incentives under the
            // previous regime. Will calculate the final amount of incentives to claim here
            // under the previous regime.
            incentivesToClaim = MigrateIncentives.migrateAccountFromPreviousCalculation(
                tokenAddress,
                balanceState.storedNTokenBalance.toUint(),
                balanceState.lastClaimTime,
                // In this case the accountIncentiveDebt is stored as lastClaimIntegralSupply under
                // the old calculation
                balanceState.accountIncentiveDebt
            );

            // This marks the account as migrated and lastClaimTime will no longer be used
            balanceState.lastClaimTime = 0;
            // This value will be set immediately after this, set this to zero so that the calculation
            // establishes a new baseline.
            balanceState.accountIncentiveDebt = 0;
        }

        // If an account was migrated then they have no accountIncentivesDebt and should accumulate
        // incentives based on their share since the new regime calculation started.
        // If an account is just initiating their nToken balance then storedNTokenBalance will be zero
        // and they will have no incentives to claim.
        // This calculation uses storedNTokenBalance which is the balance of the account up until this point,
        // this is important to ensure that the account does not claim for nTokens that they will mint or
        // redeem on a going forward basis.

        // The calculation below has the following precision:
        //   storedNTokenBalance (INTERNAL_TOKEN_PRECISION)
        //   MUL accumulatedNOTEPerNToken (INCENTIVE_ACCUMULATION_PRECISION)
        //   DIV INCENTIVE_ACCUMULATION_PRECISION
        //  = INTERNAL_TOKEN_PRECISION - (accountIncentivesDebt) INTERNAL_TOKEN_PRECISION
        incentivesToClaim = incentivesToClaim.add(
            balanceState.storedNTokenBalance.toUint()
                .mul(accumulatedNOTEPerNToken)
                .div(Constants.INCENTIVE_ACCUMULATION_PRECISION)
                .sub(balanceState.accountIncentiveDebt)
        );

        // Update accountIncentivesDebt denominated in INTERNAL_TOKEN_PRECISION which marks the portion
        // of the accumulatedNOTE that the account no longer has a claim over. Use the finalNTokenBalance
        // here instead of storedNTokenBalance to mark the overall incentives claim that the account
        // does not have a claim over. We do not aggregate this value with the previous accountIncentiveDebt
        // because accumulatedNOTEPerNToken is already an aggregated value.

        // The calculation below has the following precision:
        //   finalNTokenBalance (INTERNAL_TOKEN_PRECISION)
        //   MUL accumulatedNOTEPerNToken (INCENTIVE_ACCUMULATION_PRECISION)
        //   DIV INCENTIVE_ACCUMULATION_PRECISION
        //   = INTERNAL_TOKEN_PRECISION
        balanceState.accountIncentiveDebt = finalNTokenBalance
            .mul(accumulatedNOTEPerNToken)
            .div(Constants.INCENTIVE_ACCUMULATION_PRECISION);
    }

    /// @notice Incentives must be claimed every time nToken balance changes.
    /// @dev BalanceState.accountIncentiveDebt is updated in place here
    function claimIncentives(
        BalanceState memory balanceState,
        address account,
        uint256 finalNTokenBalance
    ) internal returns (uint256 incentivesToClaim) {
        uint256 blockTime = block.timestamp;
        address tokenAddress = nTokenHandler.nTokenAddress(balanceState.currencyId);
        // This will updated the nToken storage and return what the accumulatedNOTEPerNToken
        // is up until this current block time in 1e18 precision
        uint256 accumulatedNOTEPerNToken = nTokenSupply.changeNTokenSupply(
            tokenAddress,
            balanceState.netNTokenSupplyChange,
            blockTime
        );

        incentivesToClaim = calculateIncentivesToClaim(
            balanceState,
            tokenAddress,
            accumulatedNOTEPerNToken,
            finalNTokenBalance
        );

        // If a secondary incentive rewarder is set, then call it
        IRewarder rewarder = nTokenHandler.getSecondaryRewarder(tokenAddress);
        if (address(rewarder) != address(0)) {
            rewarder.claimRewards(
                account,
                balanceState.currencyId,
                // When this method is called from finalize, the storedNTokenBalance has not
                // been updated to finalNTokenBalance yet so this is the balance before the change.
                balanceState.storedNTokenBalance.toUint(),
                finalNTokenBalance,
                // When the rewarder is called, totalSupply has been updated already so may need to
                // adjust its calculation using the net supply change figure here. Supply change
                // may be zero when nTokens are transferred.
                balanceState.netNTokenSupplyChange,
                incentivesToClaim
            );
        }

        if (incentivesToClaim > 0) TokenHandler.transferIncentive(account, incentivesToClaim);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "../global/LibStorage.sol";
import "./balances/BalanceHandler.sol";
import "./portfolio/BitmapAssetsHandler.sol";
import "./portfolio/PortfolioHandler.sol";

library AccountContextHandler {
    using PortfolioHandler for PortfolioState;

    bytes18 private constant TURN_OFF_PORTFOLIO_FLAGS = 0x7FFF7FFF7FFF7FFF7FFF7FFF7FFF7FFF7FFF;
    event AccountContextUpdate(address indexed account);

    /// @notice Returns the account context of a given account
    function getAccountContext(address account) internal view returns (AccountContext memory) {
        mapping(address => AccountContext) storage store = LibStorage.getAccountStorage();
        return store[account];
    }

    /// @notice Sets the account context of a given account
    function setAccountContext(AccountContext memory accountContext, address account) internal {
        mapping(address => AccountContext) storage store = LibStorage.getAccountStorage();
        store[account] = accountContext;
        emit AccountContextUpdate(account);
    }

    function isBitmapEnabled(AccountContext memory accountContext) internal pure returns (bool) {
        return accountContext.bitmapCurrencyId != 0;
    }

    /// @notice Enables a bitmap type portfolio for an account. A bitmap type portfolio allows
    /// an account to hold more fCash than a normal portfolio, except only in a single currency.
    /// Once enabled, it cannot be disabled or changed. An account can only enable a bitmap if
    /// it has no assets or debt so that we ensure no assets are left stranded.
    /// @param accountContext refers to the account where the bitmap will be enabled
    /// @param currencyId the id of the currency to enable
    /// @param blockTime the current block time to set the next settle time
    function enableBitmapForAccount(
        AccountContext memory accountContext,
        uint16 currencyId,
        uint256 blockTime
    ) internal view {
        require(!isBitmapEnabled(accountContext), "Cannot change bitmap");
        require(0 < currencyId && currencyId <= Constants.MAX_CURRENCIES, "Invalid currency id");

        // Account cannot have assets or debts
        require(accountContext.assetArrayLength == 0, "Cannot have assets");
        require(accountContext.hasDebt == 0x00, "Cannot have debt");

        // Ensure that the active currency is set to false in the array so that there is no double
        // counting during FreeCollateral
        setActiveCurrency(accountContext, currencyId, false, Constants.ACTIVE_IN_BALANCES);
        accountContext.bitmapCurrencyId = currencyId;

        // Setting this is required to initialize the assets bitmap
        uint256 nextSettleTime = DateTime.getTimeUTC0(blockTime);
        require(nextSettleTime < type(uint40).max); // dev: blockTime overflow
        accountContext.nextSettleTime = uint40(nextSettleTime);
    }

    /// @notice Returns true if the context needs to settle
    function mustSettleAssets(AccountContext memory accountContext) internal view returns (bool) {
        uint256 blockTime = block.timestamp;

        if (isBitmapEnabled(accountContext)) {
            // nextSettleTime will be set to utc0 after settlement so we
            // settle if this is strictly less than utc0
            return accountContext.nextSettleTime < DateTime.getTimeUTC0(blockTime);
        } else {
            // 0 value occurs on an uninitialized account
            // Assets mature exactly on the blockTime (not one second past) so in this
            // case we settle on the block timestamp
            return 0 < accountContext.nextSettleTime && accountContext.nextSettleTime <= blockTime;
        }
    }

    /// @notice Checks if a currency id (uint16 max) is in the 9 slots in the account
    /// context active currencies list.
    /// @dev NOTE: this may be more efficient as a binary search since we know that the array
    /// is sorted
    function isActiveInBalances(AccountContext memory accountContext, uint256 currencyId)
        internal
        pure
        returns (bool)
    {
        require(currencyId != 0 && currencyId <= Constants.MAX_CURRENCIES); // dev: invalid currency id
        bytes18 currencies = accountContext.activeCurrencies;

        if (accountContext.bitmapCurrencyId == currencyId) return true;

        while (currencies != 0x00) {
            uint256 cid = uint16(bytes2(currencies) & Constants.UNMASK_FLAGS);
            if (cid == currencyId) {
                // Currency found, return if it is active in balances or not
                return bytes2(currencies) & Constants.ACTIVE_IN_BALANCES == Constants.ACTIVE_IN_BALANCES;
            }

            currencies = currencies << 16;
        }

        return false;
    }

    /// @notice Iterates through the active currency list and removes, inserts or does nothing
    /// to ensure that the active currency list is an ordered byte array of uint16 currency ids
    /// that refer to the currencies that an account is active in.
    ///
    /// This is called to ensure that currencies are active when the account has a non zero cash balance,
    /// a non zero nToken balance or a portfolio asset.
    function setActiveCurrency(
        AccountContext memory accountContext,
        uint256 currencyId,
        bool isActive,
        bytes2 flags
    ) internal pure {
        require(0 < currencyId && currencyId <= Constants.MAX_CURRENCIES); // dev: invalid currency id

        // If the bitmapped currency is already set then return here. Turning off the bitmap currency
        // id requires other logical handling so we will do it elsewhere.
        if (isActive && accountContext.bitmapCurrencyId == currencyId) return;

        bytes18 prefix;
        bytes18 suffix = accountContext.activeCurrencies;
        uint256 shifts;

        /// There are six possible outcomes from this search:
        /// 1. The currency id is in the list
        ///      - it must be set to active, do nothing
        ///      - it must be set to inactive, shift suffix and concatenate
        /// 2. The current id is greater than the one in the search:
        ///      - it must be set to active, append to prefix and then concatenate the suffix,
        ///        ensure that we do not lose the last 2 bytes if set.
        ///      - it must be set to inactive, it is not in the list, do nothing
        /// 3. Reached the end of the list:
        ///      - it must be set to active, check that the last two bytes are not set and then
        ///        append to the prefix
        ///      - it must be set to inactive, do nothing
        while (suffix != 0x00) {
            uint256 cid = uint256(uint16(bytes2(suffix) & Constants.UNMASK_FLAGS));
            // if matches and isActive then return, already in list
            if (cid == currencyId && isActive) {
                // set flag and return
                accountContext.activeCurrencies =
                    accountContext.activeCurrencies |
                    (bytes18(flags) >> (shifts * 16));
                return;
            }

            // if matches and not active then shift suffix to remove
            if (cid == currencyId && !isActive) {
                // turn off flag, if both flags are off then remove
                suffix = suffix & ~bytes18(flags);
                if (bytes2(suffix) & ~Constants.UNMASK_FLAGS == 0x0000) suffix = suffix << 16;
                accountContext.activeCurrencies = prefix | (suffix >> (shifts * 16));
                return;
            }

            // if greater than and isActive then insert into prefix
            if (cid > currencyId && isActive) {
                prefix = prefix | (bytes18(bytes2(uint16(currencyId)) | flags) >> (shifts * 16));
                // check that the total length is not greater than 9, meaning that the last
                // two bytes of the active currencies array should be zero
                require((accountContext.activeCurrencies << 128) == 0x00); // dev: AC: too many currencies

                // append the suffix
                accountContext.activeCurrencies = prefix | (suffix >> ((shifts + 1) * 16));
                return;
            }

            // if past the point of the currency id and not active, not in list
            if (cid > currencyId && !isActive) return;

            prefix = prefix | (bytes18(bytes2(suffix)) >> (shifts * 16));
            suffix = suffix << 16;
            shifts += 1;
        }

        // If reached this point and not active then return
        if (!isActive) return;

        // if end and isActive then insert into suffix, check max length
        require(shifts < 9); // dev: AC: too many currencies
        accountContext.activeCurrencies =
            prefix |
            (bytes18(bytes2(uint16(currencyId)) | flags) >> (shifts * 16));
    }

    function _clearPortfolioActiveFlags(bytes18 activeCurrencies) internal pure returns (bytes18) {
        bytes18 result;
        // This is required to clear the suffix as we append below
        bytes18 suffix = activeCurrencies & TURN_OFF_PORTFOLIO_FLAGS;
        uint256 shifts;

        // This loop will append all currencies that are active in balances into the result.
        while (suffix != 0x00) {
            if (bytes2(suffix) & Constants.ACTIVE_IN_BALANCES == Constants.ACTIVE_IN_BALANCES) {
                // If any flags are active, then append.
                result = result | (bytes18(bytes2(suffix)) >> shifts);
                shifts += 16;
            }
            suffix = suffix << 16;
        }

        return result;
    }

    /// @notice Stores a portfolio array and updates the account context information, this method should
    /// be used whenever updating a portfolio array except in the case of nTokens
    function storeAssetsAndUpdateContext(
        AccountContext memory accountContext,
        address account,
        PortfolioState memory portfolioState,
        bool isLiquidation
    ) internal {
        // Each of these parameters is recalculated based on the entire array of assets in store assets,
        // regardless of whether or not they have been updated.
        (bool hasDebt, bytes32 portfolioCurrencies, uint8 assetArrayLength, uint40 nextSettleTime) =
            portfolioState.storeAssets(account);
        accountContext.nextSettleTime = nextSettleTime;
        require(mustSettleAssets(accountContext) == false); // dev: cannot store matured assets
        accountContext.assetArrayLength = assetArrayLength;

        // During liquidation it is possible for an array to go over the max amount of assets allowed due to
        // liquidity tokens being withdrawn into fCash.
        if (!isLiquidation) {
            require(assetArrayLength <= uint8(Constants.MAX_TRADED_MARKET_INDEX)); // dev: max assets allowed
        }

        // Sets the hasDebt flag properly based on whether or not portfolio has asset debt, meaning
        // a negative fCash balance.
        if (hasDebt) {
            accountContext.hasDebt = accountContext.hasDebt | Constants.HAS_ASSET_DEBT;
        } else {
            // Turns off the ASSET_DEBT flag
            accountContext.hasDebt = accountContext.hasDebt & ~Constants.HAS_ASSET_DEBT;
        }

        // Clear the active portfolio active flags and they will be recalculated in the next step
        accountContext.activeCurrencies = _clearPortfolioActiveFlags(accountContext.activeCurrencies);

        uint256 lastCurrency;
        while (portfolioCurrencies != 0) {
            // Portfolio currencies will not have flags, it is just an byte array of all the currencies found
            // in a portfolio. They are appended in a sorted order so we can compare to the previous currency
            // and only set it if they are different.
            uint256 currencyId = uint16(bytes2(portfolioCurrencies));
            if (currencyId != lastCurrency) {
                setActiveCurrency(accountContext, currencyId, true, Constants.ACTIVE_IN_PORTFOLIO);
            }
            lastCurrency = currencyId;

            portfolioCurrencies = portfolioCurrencies << 16;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "./Bitmap.sol";

/**
 * Packs an uint value into a "floating point" storage slot. Used for storing
 * lastClaimIntegralSupply values in balance storage. For these values, we don't need
 * to maintain exact precision but we don't want to be limited by storage size overflows.
 *
 * A floating point value is defined by the 48 most significant bits and an 8 bit number
 * of bit shifts required to restore its precision. The unpacked value will always be less
 * than the packed value with a maximum absolute loss of precision of (2 ** bitShift) - 1.
 */
library FloatingPoint56 {

    function packTo56Bits(uint256 value) internal pure returns (uint56) {
        uint256 bitShift;
        // If the value is over the uint48 max value then we will shift it down
        // given the index of the most significant bit. We store this bit shift 
        // in the least significant byte of the 56 bit slot available.
        if (value > type(uint48).max) bitShift = (Bitmap.getMSB(value) - 47);

        uint256 shiftedValue = value >> bitShift;
        return uint56((shiftedValue << 8) | bitShift);
    }

    function unpackFrom56Bits(uint256 value) internal pure returns (uint256) {
        // The least significant 8 bits will be the amount to bit shift
        uint256 bitShift = uint256(uint8(value));
        return ((value >> 8) << bitShift);
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "../global/LibStorage.sol";
import "../internal/nToken/nTokenHandler.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @notice Deployed library for migration of incentives from the old (inaccurate) calculation
 * to a newer, more accurate calculation based on SushiSwap MasterChef math. The more accurate
 * calculation is inside `Incentives.sol` and this library holds the legacy calculation. System
 * migration code can be found in `MigrateIncentivesFix.sol`
 */
library MigrateIncentives {
    using SafeMath for uint256;

    /// @notice Calculates the claimable incentives for a particular nToken and account in the
    /// previous regime. This should only ever be called ONCE for an account / currency combination
    /// to get the incentives accrued up until the migration date.
    function migrateAccountFromPreviousCalculation(
        address tokenAddress,
        uint256 nTokenBalance,
        uint256 lastClaimTime,
        uint256 lastClaimIntegralSupply
    ) external view returns (uint256) {
        (
            uint256 finalEmissionRatePerYear,
            uint256 finalTotalIntegralSupply,
            uint256 finalMigrationTime
        ) = _getMigratedIncentiveValues(tokenAddress);

        // This if statement should never be true but we return 0 just in case
        if (lastClaimTime == 0 || lastClaimTime >= finalMigrationTime) return 0;

        // No overflow here, checked above. All incentives are claimed up until finalMigrationTime
        // using the finalTotalIntegralSupply. Both these values are set on migration and will not
        // change.
        uint256 timeSinceMigration = finalMigrationTime - lastClaimTime;

        // (timeSinceMigration * INTERNAL_TOKEN_PRECISION * finalEmissionRatePerYear) / YEAR
        uint256 incentiveRate =
            timeSinceMigration
                .mul(uint256(Constants.INTERNAL_TOKEN_PRECISION))
                // Migration emission rate is stored as is, denominated in whole tokens
                .mul(finalEmissionRatePerYear).mul(uint256(Constants.INTERNAL_TOKEN_PRECISION))
                .div(Constants.YEAR);

        // Returns the average supply using the integral of the total supply.
        uint256 avgTotalSupply = finalTotalIntegralSupply.sub(lastClaimIntegralSupply).div(timeSinceMigration);
        if (avgTotalSupply == 0) return 0;

        uint256 incentivesToClaim = nTokenBalance.mul(incentiveRate).div(avgTotalSupply);
        // incentiveRate has a decimal basis of 1e16 so divide by token precision to reduce to 1e8
        incentivesToClaim = incentivesToClaim.div(uint256(Constants.INTERNAL_TOKEN_PRECISION));

        return incentivesToClaim;
    }

    function _getMigratedIncentiveValues(
        address tokenAddress
    ) private view returns (
        uint256 finalEmissionRatePerYear,
        uint256 finalTotalIntegralSupply,
        uint256 finalMigrationTime
    ) {
        mapping(address => nTokenTotalSupplyStorage_deprecated) storage store = LibStorage.getDeprecatedNTokenTotalSupplyStorage();
        nTokenTotalSupplyStorage_deprecated storage d_nTokenStorage = store[tokenAddress];

        // The total supply value is overridden as emissionRatePerYear during the initialization
        finalEmissionRatePerYear = d_nTokenStorage.totalSupply;
        finalTotalIntegralSupply = d_nTokenStorage.integralTotalSupply;
        finalMigrationTime = d_nTokenStorage.lastSupplyChangeTime;
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/// @title Hardcoded deployed contracts are listed here. These are hardcoded to reduce
/// gas costs for immutable addresses. They must be updated per environment that Notional
/// is deployed to.
library Deployments {
    address internal constant NOTE_TOKEN_ADDRESS = 0xCFEAead4947f0705A14ec42aC3D44129E1Ef3eD5;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "../../../global/Types.sol";
import "../../../global/LibStorage.sol";
import "../../../math/SafeInt256.sol";
import "../TokenHandler.sol";
import "../../../../interfaces/aave/IAToken.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

library AaveHandler {
    using SafeMath for uint256;
    using SafeInt256 for int256;
    int256 internal constant RAY = 1e27;
    int256 internal constant halfRAY = RAY / 2;

    bytes4 internal constant scaledBalanceOfSelector = IAToken.scaledBalanceOf.selector;

    /**
     * @notice Mints an amount of aTokens corresponding to the the underlying.
     * @param underlyingToken address of the underlying token to pass to Aave
     * @param underlyingAmountExternal amount of underlying to deposit, in external precision
     */
    function mint(Token memory underlyingToken, uint256 underlyingAmountExternal) internal {
        // In AaveV3 this method is renamed to supply() but deposit() is still available for
        // backwards compatibility: https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/pool/Pool.sol#L755
        // We use deposit here so that mainnet-fork tests against Aave v2 will pass.
        LibStorage.getLendingPool().lendingPool.deposit(
            underlyingToken.tokenAddress,
            underlyingAmountExternal,
            address(this),
            0
        );
    }

    /**
     * @notice Redeems and sends an amount of aTokens to the specified account
     * @param underlyingToken address of the underlying token to pass to Aave
     * @param account account to receive the underlying
     * @param assetAmountExternal amount of aTokens in scaledBalanceOf terms
     */
    function redeem(
        Token memory underlyingToken,
        address account,
        uint256 assetAmountExternal
    ) internal returns (uint256 underlyingAmountExternal) {
        underlyingAmountExternal = convertFromScaledBalanceExternal(
            underlyingToken.tokenAddress,
            SafeInt256.toInt(assetAmountExternal)
        ).toUint();
        LibStorage.getLendingPool().lendingPool.withdraw(
            underlyingToken.tokenAddress,
            underlyingAmountExternal,
            account
        );
    }

    /**
     * @notice Takes an assetAmountExternal (in this case is the Aave balanceOf representing principal plus interest)
     * and returns another assetAmountExternal value which represents the Aave scaledBalanceOf (representing a proportional
     * claim on Aave principal plus interest onto the future). This conversion ensures that depositors into Notional will
     * receive future Aave interest.
     * @dev There is no loss of precision within this function since it does the exact same calculation as Aave.
     * @param currencyId is the currency id
     * @param assetAmountExternal an Aave token amount representing principal plus interest supplied by the user. This must
     * be positive in this function, this method is only called when depositing aTokens directly
     * @return scaledAssetAmountExternal the Aave scaledBalanceOf equivalent. The decimal precision of this value will
     * be in external precision.
     */
    function convertToScaledBalanceExternal(uint256 currencyId, int256 assetAmountExternal) internal view returns (int256) {
        if (assetAmountExternal == 0) return 0;
        require(assetAmountExternal > 0);

        Token memory underlyingToken = TokenHandler.getUnderlyingToken(currencyId);
        // We know that this value must be positive
        int256 index = _getReserveNormalizedIncome(underlyingToken.tokenAddress);

        // Mimic the WadRay math performed by Aave (but do it in int256 instead)
        int256 halfIndex = index / 2;

        // Overflow will occur when: (a * RAY + halfIndex) > int256.max
        require(assetAmountExternal <= (type(int256).max - halfIndex) / RAY);

        // if index is zero then this will revert
        return (assetAmountExternal * RAY + halfIndex) / index;
    }

    /**
     * @notice Takes an assetAmountExternal (in this case is the internal scaledBalanceOf in external decimal precision)
     * and returns another assetAmountExternal value which represents the Aave balanceOf representing the principal plus interest
     * that will be transferred. This is required to maintain compatibility with Aave's ERC20 transfer functions.
     * @dev There is no loss of precision because this does exactly what Aave's calculation would do
     * @param underlyingToken token address of the underlying asset
     * @param netScaledBalanceExternal an amount representing the scaledBalanceOf in external decimal precision calculated from
     * Notional cash balances. This amount may be positive or negative depending on if assets are being deposited (positive) or
     * withdrawn (negative).
     * @return netBalanceExternal the Aave balanceOf equivalent as a signed integer
     */
    function convertFromScaledBalanceExternal(address underlyingToken, int256 netScaledBalanceExternal) internal view returns (int256 netBalanceExternal) {
        if (netScaledBalanceExternal == 0) return 0;

        // We know that this value must be positive
        int256 index = _getReserveNormalizedIncome(underlyingToken);
        // Use the absolute value here so that the halfRay rounding is applied correctly for negative values
        int256 abs = netScaledBalanceExternal.abs();

        // Mimic the WadRay math performed by Aave (but do it in int256 instead)

        // Overflow will occur when: (abs * index + halfRay) > int256.max
        // Here the first term is computed at compile time so it just does a division. If index is zero then
        // solidity will revert.
        require(abs <= (type(int256).max - halfRAY) / index);
        int256 absScaled = (abs * index + halfRAY) / RAY;

        return netScaledBalanceExternal > 0 ? absScaled : absScaled.neg();
    }

    /// @dev getReserveNormalizedIncome returns a uint256, so we know that the return value here is
    /// always positive even though we are converting to a signed int
    function _getReserveNormalizedIncome(address underlyingAsset) private view returns (int256) {
        return
            SafeInt256.toInt(
                LibStorage.getLendingPool().lendingPool.getReserveNormalizedIncome(underlyingAsset)
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "./GenericToken.sol";
import "../../../../interfaces/compound/CErc20Interface.sol";
import "../../../../interfaces/compound/CEtherInterface.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../../global/Types.sol";

library CompoundHandler {
    using SafeMath for uint256;

    // Return code for cTokens that represents no error
    uint256 internal constant COMPOUND_RETURN_CODE_NO_ERROR = 0;

    function mintCETH(Token memory token) internal {
        // Reverts on error
        CEtherInterface(token.tokenAddress).mint{value: msg.value}();
    }

    function mint(Token memory token, uint256 underlyingAmountExternal) internal returns (int256) {
        uint256 success = CErc20Interface(token.tokenAddress).mint(underlyingAmountExternal);
        require(success == COMPOUND_RETURN_CODE_NO_ERROR, "Mint");
    }

    function redeemCETH(
        Token memory assetToken,
        address account,
        uint256 assetAmountExternal
    ) internal returns (uint256 underlyingAmountExternal) {
        // Although the contract should never end with any ETH or underlying token balances, we still do this
        // starting and ending check in the case that tokens are accidentally sent to the contract address. They
        // will not be sent to some lucky address in a windfall.
        uint256 startingBalance = address(this).balance;

        uint256 success = CErc20Interface(assetToken.tokenAddress).redeem(assetAmountExternal);
        require(success == COMPOUND_RETURN_CODE_NO_ERROR, "Redeem");

        uint256 endingBalance = address(this).balance;

        underlyingAmountExternal = endingBalance.sub(startingBalance);

        // Withdraws the underlying amount out to the destination account
        GenericToken.transferNativeTokenOut(account, underlyingAmountExternal);
    }

    function redeem(
        Token memory assetToken,
        Token memory underlyingToken,
        address account,
        uint256 assetAmountExternal
    ) internal returns (uint256 underlyingAmountExternal) {
        // Although the contract should never end with any ETH or underlying token balances, we still do this
        // starting and ending check in the case that tokens are accidentally sent to the contract address. They
        // will not be sent to some lucky address in a windfall.
        uint256 startingBalance = GenericToken.checkBalanceViaSelector(underlyingToken.tokenAddress, address(this), GenericToken.defaultBalanceOfSelector);

        uint256 success = CErc20Interface(assetToken.tokenAddress).redeem(assetAmountExternal);
        require(success == COMPOUND_RETURN_CODE_NO_ERROR, "Redeem");

        uint256 endingBalance = GenericToken.checkBalanceViaSelector(underlyingToken.tokenAddress, address(this), GenericToken.defaultBalanceOfSelector);

        underlyingAmountExternal = endingBalance.sub(startingBalance);

        // Withdraws the underlying amount out to the destination account
        GenericToken.safeTransferOut(underlyingToken.tokenAddress, account, underlyingAmountExternal);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "../../../../interfaces/IEIP20NonStandard.sol";

library GenericToken {
    bytes4 internal constant defaultBalanceOfSelector = IEIP20NonStandard.balanceOf.selector;

    /**
     * @dev Manually checks the balance of an account using the method selector. Reduces bytecode size and allows
     * for overriding the balanceOf selector to use scaledBalanceOf for aTokens
     */
    function checkBalanceViaSelector(
        address token,
        address account,
        bytes4 balanceOfSelector
    ) internal returns (uint256 balance) {
        (bool success, bytes memory returnData) = token.staticcall(abi.encodeWithSelector(balanceOfSelector, account));
        require(success);
        (balance) = abi.decode(returnData, (uint256));
    }

    function transferNativeTokenOut(
        address account,
        uint256 amount
    ) internal {
        // This does not work with contracts, but is reentrancy safe. If contracts want to withdraw underlying
        // ETH they will have to withdraw the cETH token and then redeem it manually.
        payable(account).transfer(amount);
    }

    function safeTransferOut(
        address token,
        address account,
        uint256 amount
    ) internal {
        IEIP20NonStandard(token).transfer(account, amount);
        checkReturnCode();
    }

    function safeTransferIn(
        address token,
        address account,
        uint256 amount
    ) internal {
        IEIP20NonStandard(token).transferFrom(account, address(this), amount);
        checkReturnCode();
    }

    function checkReturnCode() internal pure {
        bool success;
        uint256[1] memory result;
        assembly {
            switch returndatasize()
                case 0 {
                    // This is a non-standard ERC-20
                    success := 1 // set success to true
                }
                case 32 {
                    // This is a compliant ERC-20
                    returndatacopy(result, 0, 32)
                    success := mload(result) // Set `success = returndata` of external call
                }
                default {
                    // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }

        require(success, "ERC20");
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAToken {
    /**
    * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
    * updated stored balance divided by the reserve's liquidity index at the moment of the update
    * @param user The user whose balance is calculated
    * @return The scaled balance of the user
    **/
    function scaledBalanceOf(address user) external view returns (uint256);

    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    function symbol() external view returns (string memory);
}

interface IScaledBalanceToken {
    /**
    * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
    * updated stored balance divided by the reserve's liquidity index at the moment of the update
    * @param user The user whose balance is calculated
    * @return The scaled balance of the user
    **/
    function scaledBalanceOf(address user) external view returns (uint256);

    /**
    * @dev Returns the scaled balance of the user and the scaled total supply.
    * @param user The address of the user
    * @return The scaled balance of the user
    * @return The scaled balance and the scaled total supply
    **/
    function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

    /**
    * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
    * @return The scaled total supply
    **/
    function scaledTotalSupply() external view returns (uint256);
}

interface IATokenFull is IScaledBalanceToken, IERC20 { 
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.7.0;

import "./CTokenInterface.sol";

interface CErc20Interface {

    /*** User Interface ***/

    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, CTokenInterface cTokenCollateral) external returns (uint);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.7.0;

interface CEtherInterface {
    function mint() external payable;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface IEIP20NonStandard {

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transferFrom(address src, address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `approve` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      */
    function approve(address spender, uint256 amount) external;

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.7.0;

interface CTokenInterface {

    /*** User Interface ***/

    function underlying() external view returns (address);
    function totalSupply() external view returns (uint256);
    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() external returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);
    function accrualBlockNumber() external view returns (uint256);
    function totalBorrows() external view returns (uint256);
    function totalReserves() external view returns (uint256);
    function interestRateModel() external view returns (address);
    function reserveFactorMantissa() external view returns (uint256);
    function initialExchangeRateMantissa() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "./PortfolioHandler.sol";
import "./BitmapAssetsHandler.sol";
import "../AccountContextHandler.sol";
import "../../global/Types.sol";
import "../../math/SafeInt256.sol";

/// @notice Helper library for transferring assets from one portfolio to another
library TransferAssets {
    using AccountContextHandler for AccountContext;
    using PortfolioHandler for PortfolioState;
    using SafeInt256 for int256;

    /// @notice Decodes asset ids
    function decodeAssetId(uint256 id)
        internal
        pure
        returns (
            uint256 currencyId,
            uint256 maturity,
            uint256 assetType
        )
    {
        assetType = uint8(id);
        maturity = uint40(id >> 8);
        currencyId = uint16(id >> 48);
    }

    /// @notice Encodes asset ids
    function encodeAssetId(
        uint256 currencyId,
        uint256 maturity,
        uint256 assetType
    ) internal pure returns (uint256) {
        require(currencyId <= Constants.MAX_CURRENCIES);
        require(maturity <= type(uint40).max);
        require(assetType <= Constants.MAX_LIQUIDITY_TOKEN_INDEX);

        return
            uint256(
                (bytes32(uint256(uint16(currencyId))) << 48) |
                    (bytes32(uint256(uint40(maturity))) << 8) |
                    bytes32(uint256(uint8(assetType)))
            );
    }

    /// @dev Used to flip the sign of assets to decrement the `from` account that is sending assets
    function invertNotionalAmountsInPlace(PortfolioAsset[] memory assets) internal pure {
        for (uint256 i; i < assets.length; i++) {
            assets[i].notional = assets[i].notional.neg();
        }
    }

    /// @dev Useful method for hiding the logic of updating an account. WARNING: the account
    /// context returned from this method may not be the same memory location as the account
    /// context provided if the account is settled.
    function placeAssetsInAccount(
        address account,
        AccountContext memory accountContext,
        PortfolioAsset[] memory assets
    ) internal returns (AccountContext memory) {
        // If an account has assets that require settlement then placing assets inside it
        // may cause issues.
        require(!accountContext.mustSettleAssets(), "Account must settle");

        if (accountContext.isBitmapEnabled()) {
            // Adds fCash assets into the account and finalized storage
            BitmapAssetsHandler.addMultipleifCashAssets(account, accountContext, assets);
        } else {
            PortfolioState memory portfolioState = PortfolioHandler.buildPortfolioState(
                account,
                accountContext.assetArrayLength,
                assets.length
            );
            // This will add assets in memory
            portfolioState.addMultipleAssets(assets);
            // This will store assets and update the account context in memory
            accountContext.storeAssetsAndUpdateContext(account, portfolioState, false);
        }

        return accountContext;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "../../global/Types.sol";
import "../../global/Constants.sol";
import "../markets/CashGroup.sol";
import "../markets/AssetRate.sol";
import "../markets/DateTime.sol";
import "../portfolio/PortfolioHandler.sol";
import "../../math/SafeInt256.sol";
import "../../math/ABDKMath64x64.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

library AssetHandler {
    using SafeMath for uint256;
    using SafeInt256 for int256;
    using CashGroup for CashGroupParameters;
    using AssetRate for AssetRateParameters;

    function isLiquidityToken(uint256 assetType) internal pure returns (bool) {
        return
            assetType >= Constants.MIN_LIQUIDITY_TOKEN_INDEX &&
            assetType <= Constants.MAX_LIQUIDITY_TOKEN_INDEX;
    }

    /// @notice Liquidity tokens settle every 90 days (not at the designated maturity). This method
    /// calculates the settlement date for any PortfolioAsset.
    function getSettlementDate(PortfolioAsset memory asset) internal pure returns (uint256) {
        require(asset.assetType > 0 && asset.assetType <= Constants.MAX_LIQUIDITY_TOKEN_INDEX); // dev: settlement date invalid asset type
        // 3 month tokens and fCash tokens settle at maturity
        if (asset.assetType <= Constants.MIN_LIQUIDITY_TOKEN_INDEX) return asset.maturity;

        uint256 marketLength = DateTime.getTradedMarket(asset.assetType - 1);
        // Liquidity tokens settle at tRef + 90 days. The formula to get a maturity is:
        // maturity = tRef + marketLength
        // Here we calculate:
        // tRef = (maturity - marketLength) + 90 days
        return asset.maturity.sub(marketLength).add(Constants.QUARTER);
    }

    /// @notice Returns the continuously compounded discount rate given an oracle rate and a time to maturity.
    /// The formula is: e^(-rate * timeToMaturity).
    function getDiscountFactor(uint256 timeToMaturity, uint256 oracleRate)
        internal
        pure
        returns (int256)
    {
        int128 expValue =
            ABDKMath64x64.fromUInt(oracleRate.mul(timeToMaturity).div(Constants.IMPLIED_RATE_TIME));
        expValue = ABDKMath64x64.div(expValue, Constants.RATE_PRECISION_64x64);
        expValue = ABDKMath64x64.exp(ABDKMath64x64.neg(expValue));
        expValue = ABDKMath64x64.mul(expValue, Constants.RATE_PRECISION_64x64);
        int256 discountFactor = ABDKMath64x64.toInt(expValue);

        return discountFactor;
    }

    /// @notice Present value of an fCash asset without any risk adjustments.
    function getPresentfCashValue(
        int256 notional,
        uint256 maturity,
        uint256 blockTime,
        uint256 oracleRate
    ) internal pure returns (int256) {
        if (notional == 0) return 0;

        // NOTE: this will revert if maturity < blockTime. That is the correct behavior because we cannot
        // discount matured assets.
        uint256 timeToMaturity = maturity.sub(blockTime);
        int256 discountFactor = getDiscountFactor(timeToMaturity, oracleRate);

        require(discountFactor <= Constants.RATE_PRECISION); // dev: get present value invalid discount factor
        return notional.mulInRatePrecision(discountFactor);
    }

    /// @notice Present value of an fCash asset with risk adjustments. Positive fCash value will be discounted more
    /// heavily than the oracle rate given and vice versa for negative fCash.
    function getRiskAdjustedPresentfCashValue(
        CashGroupParameters memory cashGroup,
        int256 notional,
        uint256 maturity,
        uint256 blockTime,
        uint256 oracleRate
    ) internal pure returns (int256) {
        if (notional == 0) return 0;
        // NOTE: this will revert if maturity < blockTime. That is the correct behavior because we cannot
        // discount matured assets.
        uint256 timeToMaturity = maturity.sub(blockTime);

        int256 discountFactor;
        if (notional > 0) {
            // If fCash is positive then discounting by a higher rate will result in a smaller
            // discount factor (e ^ -x), meaning a lower positive fCash value.
            discountFactor = getDiscountFactor(
                timeToMaturity,
                oracleRate.add(cashGroup.getfCashHaircut())
            );
        } else {
            uint256 debtBuffer = cashGroup.getDebtBuffer();
            // If the adjustment exceeds the oracle rate we floor the value of the fCash
            // at the notional value. We don't want to require the account to hold more than
            // absolutely required.
            if (debtBuffer >= oracleRate) return notional;

            discountFactor = getDiscountFactor(timeToMaturity, oracleRate - debtBuffer);
        }

        require(discountFactor <= Constants.RATE_PRECISION); // dev: get risk adjusted pv, invalid discount factor
        return notional.mulInRatePrecision(discountFactor);
    }

    /// @notice Returns the non haircut claims on cash and fCash by the liquidity token.
    function getCashClaims(PortfolioAsset memory token, MarketParameters memory market)
        internal
        pure
        returns (int256 assetCash, int256 fCash)
    {
        require(isLiquidityToken(token.assetType) && token.notional >= 0); // dev: invalid asset, get cash claims

        assetCash = market.totalAssetCash.mul(token.notional).div(market.totalLiquidity);
        fCash = market.totalfCash.mul(token.notional).div(market.totalLiquidity);
    }

    /// @notice Returns the haircut claims on cash and fCash
    function getHaircutCashClaims(
        PortfolioAsset memory token,
        MarketParameters memory market,
        CashGroupParameters memory cashGroup
    ) internal pure returns (int256 assetCash, int256 fCash) {
        require(isLiquidityToken(token.assetType) && token.notional >= 0); // dev: invalid asset get haircut cash claims

        require(token.currencyId == cashGroup.currencyId); // dev: haircut cash claims, currency id mismatch
        // This won't overflow, the liquidity token haircut is stored as an uint8
        int256 haircut = int256(cashGroup.getLiquidityHaircut(token.assetType));

        assetCash =
            _calcToken(market.totalAssetCash, token.notional, haircut, market.totalLiquidity);

        fCash =
            _calcToken(market.totalfCash, token.notional, haircut, market.totalLiquidity);

        return (assetCash, fCash);
    }

    /// @dev This is here to clean up the stack in getHaircutCashClaims
    function _calcToken(
        int256 numerator,
        int256 tokens,
        int256 haircut,
        int256 liquidity
    ) private pure returns (int256) {
        return numerator.mul(tokens).mul(haircut).div(Constants.PERCENTAGE_DECIMALS).div(liquidity);
    }

    /// @notice Returns the asset cash claim and the present value of the fCash asset (if it exists)
    function getLiquidityTokenValue(
        uint256 index,
        CashGroupParameters memory cashGroup,
        MarketParameters memory market,
        PortfolioAsset[] memory assets,
        uint256 blockTime,
        bool riskAdjusted
    ) internal view returns (int256, int256) {
        PortfolioAsset memory liquidityToken = assets[index];

        {
            (uint256 marketIndex, bool idiosyncratic) =
                DateTime.getMarketIndex(
                    cashGroup.maxMarketIndex,
                    liquidityToken.maturity,
                    blockTime
                );
            // Liquidity tokens can never be idiosyncratic
            require(!idiosyncratic); // dev: idiosyncratic liquidity token

            // This market will always be initialized, if a liquidity token exists that means the
            // market has some liquidity in it.
            cashGroup.loadMarket(market, marketIndex, true, blockTime);
        }

        int256 assetCashClaim;
        int256 fCashClaim;
        if (riskAdjusted) {
            (assetCashClaim, fCashClaim) = getHaircutCashClaims(liquidityToken, market, cashGroup);
        } else {
            (assetCashClaim, fCashClaim) = getCashClaims(liquidityToken, market);
        }

        // Find the matching fCash asset and net off the value, assumes that the portfolio is sorted and
        // in that case we know the previous asset will be the matching fCash asset
        if (index > 0) {
            PortfolioAsset memory maybefCash = assets[index - 1];
            if (
                maybefCash.assetType == Constants.FCASH_ASSET_TYPE &&
                maybefCash.currencyId == liquidityToken.currencyId &&
                maybefCash.maturity == liquidityToken.maturity
            ) {
                // Net off the fCashClaim here and we will discount it to present value in the second pass.
                // WARNING: this modifies the portfolio in memory and therefore we cannot store this portfolio!
                maybefCash.notional = maybefCash.notional.add(fCashClaim);
                // This state will prevent the fCash asset from being stored.
                maybefCash.storageState = AssetStorageState.RevertIfStored;
                return (assetCashClaim, 0);
            }
        }

        // If not matching fCash asset found then get the pv directly
        if (riskAdjusted) {
            int256 pv =
                getRiskAdjustedPresentfCashValue(
                    cashGroup,
                    fCashClaim,
                    liquidityToken.maturity,
                    blockTime,
                    market.oracleRate
                );

            return (assetCashClaim, pv);
        } else {
            int256 pv =
                getPresentfCashValue(fCashClaim, liquidityToken.maturity, blockTime, market.oracleRate);

            return (assetCashClaim, pv);
        }
    }

    /// @notice Returns present value of all assets in the cash group as asset cash and the updated
    /// portfolio index where the function has ended.
    /// @return the value of the cash group in asset cash
    function getNetCashGroupValue(
        PortfolioAsset[] memory assets,
        CashGroupParameters memory cashGroup,
        MarketParameters memory market,
        uint256 blockTime,
        uint256 portfolioIndex
    ) internal view returns (int256, uint256) {
        int256 presentValueAsset;
        int256 presentValueUnderlying;

        // First calculate value of liquidity tokens because we need to net off fCash value
        // before discounting to present value
        for (uint256 i = portfolioIndex; i < assets.length; i++) {
            if (!isLiquidityToken(assets[i].assetType)) continue;
            if (assets[i].currencyId != cashGroup.currencyId) break;

            (int256 assetCashClaim, int256 pv) =
                getLiquidityTokenValue(
                    i,
                    cashGroup,
                    market,
                    assets,
                    blockTime,
                    true // risk adjusted
                );

            presentValueAsset = presentValueAsset.add(assetCashClaim);
            presentValueUnderlying = presentValueUnderlying.add(pv);
        }

        uint256 j = portfolioIndex;
        for (; j < assets.length; j++) {
            PortfolioAsset memory a = assets[j];
            if (a.assetType != Constants.FCASH_ASSET_TYPE) continue;
            // If we hit a different currency id then we've accounted for all assets in this currency
            // j will mark the index where we don't have this currency anymore
            if (a.currencyId != cashGroup.currencyId) break;

            uint256 oracleRate = cashGroup.calculateOracleRate(a.maturity, blockTime);

            int256 pv =
                getRiskAdjustedPresentfCashValue(
                    cashGroup,
                    a.notional,
                    a.maturity,
                    blockTime,
                    oracleRate
                );
            presentValueUnderlying = presentValueUnderlying.add(pv);
        }

        presentValueAsset = presentValueAsset.add(
            cashGroup.assetRate.convertFromUnderlying(presentValueUnderlying)
        );

        return (presentValueAsset, j);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "../AccountContextHandler.sol";
import "../markets/CashGroup.sol";
import "../valuation/AssetHandler.sol";
import "../../math/Bitmap.sol";
import "../../math/SafeInt256.sol";
import "../../global/LibStorage.sol";
import "../../global/Constants.sol";
import "../../global/Types.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

library BitmapAssetsHandler {
    using SafeMath for uint256;
    using SafeInt256 for int256;
    using Bitmap for bytes32;
    using CashGroup for CashGroupParameters;
    using AccountContextHandler for AccountContext;

    function getAssetsBitmap(address account, uint256 currencyId) internal view returns (bytes32 assetsBitmap) {
        mapping(address => mapping(uint256 => bytes32)) storage store = LibStorage.getAssetsBitmapStorage();
        return store[account][currencyId];
    }

    function setAssetsBitmap(
        address account,
        uint256 currencyId,
        bytes32 assetsBitmap
    ) internal {
        require(assetsBitmap.totalBitsSet() <= Constants.MAX_BITMAP_ASSETS, "Over max assets");
        mapping(address => mapping(uint256 => bytes32)) storage store = LibStorage.getAssetsBitmapStorage();
        store[account][currencyId] = assetsBitmap;
    }

    function getifCashNotional(
        address account,
        uint256 currencyId,
        uint256 maturity
    ) internal view returns (int256 notional) {
        mapping(address => mapping(uint256 =>
            mapping(uint256 => ifCashStorage))) storage store = LibStorage.getifCashBitmapStorage();
        return store[account][currencyId][maturity].notional;
    }

    /// @notice Adds multiple assets to a bitmap portfolio
    function addMultipleifCashAssets(
        address account,
        AccountContext memory accountContext,
        PortfolioAsset[] memory assets
    ) internal {
        require(accountContext.isBitmapEnabled()); // dev: bitmap currency not set
        uint256 currencyId = accountContext.bitmapCurrencyId;

        for (uint256 i; i < assets.length; i++) {
            PortfolioAsset memory asset = assets[i];
            if (asset.notional == 0) continue;

            require(asset.currencyId == currencyId); // dev: invalid asset in set ifcash assets
            require(asset.assetType == Constants.FCASH_ASSET_TYPE); // dev: invalid asset in set ifcash assets
            int256 finalNotional;

            finalNotional = addifCashAsset(
                account,
                currencyId,
                asset.maturity,
                accountContext.nextSettleTime,
                asset.notional
            );

            if (finalNotional < 0)
                accountContext.hasDebt = accountContext.hasDebt | Constants.HAS_ASSET_DEBT;
        }
    }

    /// @notice Add an ifCash asset in the bitmap and mapping. Updates the bitmap in memory
    /// but not in storage.
    /// @return the updated assets bitmap and the final notional amount
    function addifCashAsset(
        address account,
        uint256 currencyId,
        uint256 maturity,
        uint256 nextSettleTime,
        int256 notional
    ) internal returns (int256) {
        bytes32 assetsBitmap = getAssetsBitmap(account, currencyId);
        mapping(address => mapping(uint256 =>
            mapping(uint256 => ifCashStorage))) storage store = LibStorage.getifCashBitmapStorage();
        ifCashStorage storage fCashSlot = store[account][currencyId][maturity];
        (uint256 bitNum, bool isExact) = DateTime.getBitNumFromMaturity(nextSettleTime, maturity);
        require(isExact); // dev: invalid maturity in set ifcash asset

        if (assetsBitmap.isBitSet(bitNum)) {
            // Bit is set so we read and update the notional amount
            int256 finalNotional = notional.add(fCashSlot.notional);
            require(type(int128).min <= finalNotional && finalNotional <= type(int128).max); // dev: bitmap notional overflow
            fCashSlot.notional = int128(finalNotional);

            // If the new notional is zero then turn off the bit
            if (finalNotional == 0) {
                assetsBitmap = assetsBitmap.setBit(bitNum, false);
            }

            setAssetsBitmap(account, currencyId, assetsBitmap);
            return finalNotional;
        }

        if (notional != 0) {
            // Bit is not set so we turn it on and update the mapping directly, no read required.
            require(type(int128).min <= notional && notional <= type(int128).max); // dev: bitmap notional overflow
            fCashSlot.notional = int128(notional);

            assetsBitmap = assetsBitmap.setBit(bitNum, true);
            setAssetsBitmap(account, currencyId, assetsBitmap);
        }

        return notional;
    }

    /// @notice Returns the present value of an asset
    function getPresentValue(
        address account,
        uint256 currencyId,
        uint256 maturity,
        uint256 blockTime,
        CashGroupParameters memory cashGroup,
        bool riskAdjusted
    ) internal view returns (int256) {
        int256 notional = getifCashNotional(account, currencyId, maturity);

        // In this case the asset has matured and the total value is just the notional amount
        if (maturity <= blockTime) {
            return notional;
        } else {
            uint256 oracleRate = cashGroup.calculateOracleRate(maturity, blockTime);
            if (riskAdjusted) {
                return AssetHandler.getRiskAdjustedPresentfCashValue(
                    cashGroup,
                    notional,
                    maturity,
                    blockTime,
                    oracleRate
                );
            } else {
                return AssetHandler.getPresentfCashValue(
                    notional,
                    maturity,
                    blockTime,
                    oracleRate
                );
            }
        }
    }

    function getNetPresentValueFromBitmap(
        address account,
        uint256 currencyId,
        uint256 nextSettleTime,
        uint256 blockTime,
        CashGroupParameters memory cashGroup,
        bool riskAdjusted,
        bytes32 assetsBitmap
    ) internal view returns (int256 totalValueUnderlying, bool hasDebt) {
        uint256 bitNum = assetsBitmap.getNextBitNum();

        while (bitNum != 0) {
            uint256 maturity = DateTime.getMaturityFromBitNum(nextSettleTime, bitNum);
            int256 pv = getPresentValue(
                account,
                currencyId,
                maturity,
                blockTime,
                cashGroup,
                riskAdjusted
            );
            totalValueUnderlying = totalValueUnderlying.add(pv);

            if (pv < 0) hasDebt = true;

            // Turn off the bit and look for the next one
            assetsBitmap = assetsBitmap.setBit(bitNum, false);
            bitNum = assetsBitmap.getNextBitNum();
        }
    }

    /// @notice Get the net present value of all the ifCash assets
    function getifCashNetPresentValue(
        address account,
        uint256 currencyId,
        uint256 nextSettleTime,
        uint256 blockTime,
        CashGroupParameters memory cashGroup,
        bool riskAdjusted
    ) internal view returns (int256 totalValueUnderlying, bool hasDebt) {
        bytes32 assetsBitmap = getAssetsBitmap(account, currencyId);
        return getNetPresentValueFromBitmap(
            account,
            currencyId,
            nextSettleTime,
            blockTime,
            cashGroup,
            riskAdjusted,
            assetsBitmap
        );
    }

    /// @notice Returns the ifCash assets as an array
    function getifCashArray(
        address account,
        uint256 currencyId,
        uint256 nextSettleTime
    ) internal view returns (PortfolioAsset[] memory) {
        bytes32 assetsBitmap = getAssetsBitmap(account, currencyId);
        uint256 index = assetsBitmap.totalBitsSet();
        PortfolioAsset[] memory assets = new PortfolioAsset[](index);
        index = 0;

        uint256 bitNum = assetsBitmap.getNextBitNum();
        while (bitNum != 0) {
            uint256 maturity = DateTime.getMaturityFromBitNum(nextSettleTime, bitNum);
            int256 notional = getifCashNotional(account, currencyId, maturity);

            PortfolioAsset memory asset = assets[index];
            asset.currencyId = currencyId;
            asset.maturity = maturity;
            asset.assetType = Constants.FCASH_ASSET_TYPE;
            asset.notional = notional;
            index += 1;

            // Turn off the bit and look for the next one
            assetsBitmap = assetsBitmap.setBit(bitNum, false);
            bitNum = assetsBitmap.getNextBitNum();
        }

        return assets;
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "../global/Types.sol";
import "../global/Constants.sol";

/// @notice Helper methods for bitmaps, they are big-endian and 1-indexed.
library Bitmap {

    /// @notice Set a bit on or off in a bitmap, index is 1-indexed
    function setBit(
        bytes32 bitmap,
        uint256 index,
        bool setOn
    ) internal pure returns (bytes32) {
        require(index >= 1 && index <= 256); // dev: set bit index bounds

        if (setOn) {
            return bitmap | (Constants.MSB >> (index - 1));
        } else {
            return bitmap & ~(Constants.MSB >> (index - 1));
        }
    }

    /// @notice Check if a bit is set
    function isBitSet(bytes32 bitmap, uint256 index) internal pure returns (bool) {
        require(index >= 1 && index <= 256); // dev: set bit index bounds
        return ((bitmap << (index - 1)) & Constants.MSB) == Constants.MSB;
    }

    /// @notice Count the total bits set
    function totalBitsSet(bytes32 bitmap) internal pure returns (uint256) {
        uint256 x = uint256(bitmap);
        x = (x & 0x5555555555555555555555555555555555555555555555555555555555555555) + (x >> 1 & 0x5555555555555555555555555555555555555555555555555555555555555555);
        x = (x & 0x3333333333333333333333333333333333333333333333333333333333333333) + (x >> 2 & 0x3333333333333333333333333333333333333333333333333333333333333333);
        x = (x & 0x0707070707070707070707070707070707070707070707070707070707070707) + (x >> 4);
        x = (x & 0x000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F) + (x >> 8 & 0x000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F);
        x = x + (x >> 16);
        x = x + (x >> 32);
        x = x  + (x >> 64);
        return (x & 0xFF) + (x >> 128 & 0xFF);
    }

    // Does a binary search over x to get the position of the most significant bit
    function getMSB(uint256 x) internal pure returns (uint256 msb) {
        // If x == 0 then there is no MSB and this method will return zero. That would
        // be the same as the return value when x == 1 (MSB is zero indexed), so instead
        // we have this require here to ensure that the values don't get mixed up.
        require(x != 0); // dev: get msb zero value
        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 0x2) msb += 1; // No need to shift xc anymore
    }

    /// @dev getMSB returns a zero indexed bit number where zero is the first bit counting
    /// from the right (little endian). Asset Bitmaps are counted from the left (big endian)
    /// and one indexed.
    function getNextBitNum(bytes32 bitmap) internal pure returns (uint256 bitNum) {
        // Short circuit the search if bitmap is all zeros
        if (bitmap == 0x00) return 0;

        return 255 - getMSB(uint256(bitmap)) + 1;
    }
}