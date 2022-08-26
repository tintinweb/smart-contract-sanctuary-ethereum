// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;
pragma abicoder v2;

import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { FullMath } from "../lib/FullMath.sol";
import { SigmaMath } from "../lib/SigmaMath.sol";
import { Account } from "../lib/Account.sol";
import { Constant } from "../lib/Constant.sol";
import { IIndexPrice } from "../interface/IIndexPrice.sol";
import { ILiquidityProvider } from "../interface/ILiquidityProvider.sol";
import { IAmmFactory } from "../interface/IAmmFactory.sol";
import { IPositionMgmt } from "../interface/IPositionMgmt.sol";
import { IClearingHouseConfig } from "../interface/IClearingHouseConfig.sol";
import { IMarketTaker } from "../interface/IMarketTaker.sol";
import { IAmm } from "../interface/IAmm.sol";
import { BlockContext } from "../base/BlockContext.sol";
import { MarketTakerStorageV1, Funding } from "../storage/MarketTakerStorage.sol";
import { ClearingHouseCallee } from "./ClearingHouseCallee.sol";

// never inherit any new stateful contract. never change the orders of parent stateful contracts
contract MarketTaker is IMarketTaker, BlockContext, ClearingHouseCallee, MarketTakerStorageV1 {
    using AddressUpgradeable for address;
    using SigmaMath for uint256;
    using SigmaMath for int256;

    //
    // STRUCT
    //
    struct InternalSwapAstp {
        uint24 exchangeFeeRatio;
        int256 exchangedPositionSize;
        int256 exchangedPositionNotional;
        uint256 exchangeFee;
        int256 quote;
    }

    struct InternalSwapResponse {
        int256 base;
        int256 quote;
        int256 exchangedPositionSize;
        int256 exchangedPositionNotional;
        uint256 fee;
        uint256 insuranceFundFee;
    }

    struct InternalRealizePnlParams {
        address trader;
        address baseToken;
        int256 takerPositionSize;
        int256 takerOpenNotional;
        int256 base;
        int256 quote;
    }

    //
    // CONSTANT
    //

    uint256 internal constant _FULLY_CLOSED_RATIO = 1e18;

    //
    // EXTERNAL NON-VIEW
    //

    function initialize(
        address ammFactoryArg,
        address liquidityProviderArg,
        address clearingHouseConfigArg
    ) external initializer {
        __ClearingHouseCallee_init();

        _ammFactory = ammFactoryArg;

        // MT_LPNC: LiquidityProvider is not contract
        require(liquidityProviderArg.isContract(), "MT_LPNC");
        // MT_CHNC: ClearingHouse is not contract
        require(clearingHouseConfigArg.isContract(), "MT_CHNC");

        // update states
        _liquidityProvider = liquidityProviderArg;
        _clearingHouseConfig = clearingHouseConfigArg;
    }

    function setPositionMgmt(address positionMgmtArg) external onlyOwner {
        // MT_PMNC: PositionMgmt is not contract
        require(positionMgmtArg.isContract(), "MT_PMNC");
        _positionMgmt = positionMgmtArg;
        emit PositionMgmtChanged(positionMgmtArg);
    }

    function swap(SwapParams memory params) external override returns (SwapResponse memory) {
        _requireOnlyClearingHouse();
        int256 takerPositionSize = IPositionMgmt(_positionMgmt).getTakerPositionSize(params.trader, params.baseToken);

        bool isOverPriceLimit = _isOverPriceLimit(params.baseToken);
        // if over price limit when
        // 1. closing a position, then partially close the position
        // 2. reducing a position, then revert
        if (params.isClose && takerPositionSize != 0) {
            // if trader is on long side, baseToQuote: true, exactInput: true
            // if trader is on short side, baseToQuote: false (quoteToBase), exactInput: false (exactOutput)
            // simulate the tx to see if it _isOverPriceLimit; if true, can partially close the position only once
            if (
                isOverPriceLimit ||
                _isOverPriceLimitBySimulatingClosingPosition(
                    params.baseToken,
                    takerPositionSize.abs(),
                    params.isSwapWithBase,
                    params.isSell
                )
            ) {
                uint256 timestamp = _blockTimestamp();
                // MT_AOPLO: already over price limit once
                require(timestamp != _lastOverPriceLimitTimestampMap[params.trader][params.baseToken], "MT_AOPLO");

                _lastOverPriceLimitTimestampMap[params.trader][params.baseToken] = timestamp;

                uint24 partialCloseRatio = IClearingHouseConfig(_clearingHouseConfig).getPartialCloseRatio();
                params.amount = params.amount.mulRatio(partialCloseRatio);
                params.amountLimit = params.amountLimit.mulRatio(partialCloseRatio);
            }
        } else {
            // MT_OPLBS: over price limit before swap
            require(!isOverPriceLimit, "MT_OPLBS");
        }

        // get openNotional before swap
        int256 oldTakerOpenNotional = IPositionMgmt(_positionMgmt).getTakerOpenNotional(
            params.trader,
            params.baseToken
        );
        InternalSwapResponse memory response = _swap(params);

        if (!params.isClose) {
            // over price limit after swap
            uint256 priceAf = IAmm(IAmmFactory(_ammFactory).getAmm(params.baseToken)).getPriceCurrent();
            require(!_isOverPriceLimitWithPrice(params.baseToken, priceAf), "MT_OPLAS");
        }

        // when takerPositionSize < 0, it's a short position
        // bool isReducingPosition = takerPositionSize == 0 ? false : takerPositionSize < 0 != params.isSwapWithBase;
        bool isReducingPosition = takerPositionSize == 0
            ? false
            : takerPositionSize > 0 ==
                ((params.isSwapWithBase && params.isSell) || (!params.isSwapWithBase && !params.isSell));

        // when reducing/not increasing the position size, it's necessary to realize pnl
        int256 pnlToBeRealized;
        if (isReducingPosition) {
            pnlToBeRealized = _getPnlToBeRealized(
                InternalRealizePnlParams({
                    trader: params.trader,
                    baseToken: params.baseToken,
                    takerPositionSize: takerPositionSize,
                    takerOpenNotional: oldTakerOpenNotional,
                    base: response.base,
                    quote: response.quote
                })
            );
        }
        return
            SwapResponse({
                base: response.base,
                quote: response.quote,
                exchangedPositionSize: response.exchangedPositionSize,
                exchangedPositionNotional: response.exchangedPositionNotional,
                fee: response.fee,
                insuranceFundFee: response.insuranceFundFee,
                pnlToBeRealized: pnlToBeRealized
            });
    }

    /// @inheritdoc IMarketTaker
    function settleFunding(address trader, address baseToken)
        external
        override
        returns (int256 fundingPayment, Funding.Growth memory fundingGrowthGlobal)
    {
        _requireOnlyClearingHouse();
        // MT_BTNE: base token does not exists
        require(IAmmFactory(_ammFactory).hasAmm(baseToken), "MT_BTNE");

        uint256 markTwap;
        uint256 indexTwap;
        (fundingGrowthGlobal, markTwap, indexTwap) = _getFundingGrowthGlobalAndTwaps(baseToken);

        fundingPayment = _updateFundingGrowth(
            trader,
            baseToken,
            IPositionMgmt(_positionMgmt).getBase(trader, baseToken),
            IPositionMgmt(_positionMgmt).getAccountInfo(trader, baseToken).lastTwPremiumGrowthGlobal,
            fundingGrowthGlobal
        );

        uint256 timestamp = _blockTimestamp();
        // update states before further actions in this block; once per block
        if (timestamp != _lastSettledTimestampMap[baseToken]) {
            // update fundingGrowthGlobal and _lastSettledTimestamp
            Funding.Growth storage lastFundingGrowthGlobal = _globalFundingGrowthMap[baseToken];
            (
                _lastSettledTimestampMap[baseToken],
                lastFundingGrowthGlobal.twPremium,
                lastFundingGrowthGlobal.twPremiumWithLiquidity
            ) = (timestamp, fundingGrowthGlobal.twPremium, fundingGrowthGlobal.twPremiumWithLiquidity);

            emit FundingUpdated(baseToken, markTwap, indexTwap);

            // update current price for price limit checks
            _lastUpdatedPriceMap[baseToken] = IAmm(IAmmFactory(_ammFactory).getAmm(baseToken)).getPriceCurrent();
        }

        return (fundingPayment, fundingGrowthGlobal);
    }

    //
    // EXTERNAL VIEW
    //
    /// @inheritdoc IMarketTaker
    function getLiquidityProvider() external view override returns (address) {
        return _liquidityProvider;
    }

    /// @inheritdoc IMarketTaker
    function getPositionMgmt() external view override returns (address) {
        return _positionMgmt;
    }

    /// @inheritdoc IMarketTaker
    function getClearingHouseConfig() external view override returns (address) {
        return _clearingHouseConfig;
    }

    function getPnlToBeRealized(RealizePnlParams memory params) external view override returns (int256) {
        Account.TakerInfo memory info = IPositionMgmt(_positionMgmt).getAccountInfo(params.trader, params.baseToken);

        int256 takerOpenNotional = info.takerOpenNotional;
        int256 takerPositionSize = info.takerPositionSize;
        // when takerPositionSize < 0, it's a short position; when base < 0, isSwapWithBase(shorting)
        bool isReducingPosition = takerPositionSize == 0 ? false : takerPositionSize < 0 != params.base < 0;

        return
            isReducingPosition
                ? _getPnlToBeRealized(
                    InternalRealizePnlParams({
                        trader: params.trader,
                        baseToken: params.baseToken,
                        takerPositionSize: takerPositionSize,
                        takerOpenNotional: takerOpenNotional,
                        base: params.base,
                        quote: params.quote
                    })
                )
                : 0;
    }

    function getAllPendingFundingPayment(address trader) external view override returns (int256 pendingFundingPayment) {
        address[] memory baseTokens = IPositionMgmt(_positionMgmt).getBaseTokens(trader);
        uint256 baseTokenLength = baseTokens.length;

        for (uint256 i = 0; i < baseTokenLength; i++) {
            pendingFundingPayment = pendingFundingPayment + getPendingFundingPayment(trader, baseTokens[i]);
        }
        return pendingFundingPayment;
    }

    //
    // PUBLIC VIEW
    //

    /// @inheritdoc IMarketTaker
    function getPendingFundingPayment(address trader, address baseToken) public view override returns (int256) {
        (Funding.Growth memory fundingGrowthGlobal, , ) = _getFundingGrowthGlobalAndTwaps(baseToken);

        int256 liquidityFundingPayment = ILiquidityProvider(_liquidityProvider).getLiquidityFundingPayment(
            trader,
            baseToken,
            fundingGrowthGlobal
        );

        return
            Funding.calcPendingFundingPayment(
                IPositionMgmt(_positionMgmt).getBase(trader, baseToken),
                IPositionMgmt(_positionMgmt).getAccountInfo(trader, baseToken).lastTwPremiumGrowthGlobal,
                fundingGrowthGlobal,
                liquidityFundingPayment
            );
    }

    function getTwapMarkPrice(address baseToken, uint32 twapInterval) public view override returns (uint256) {
        return IAmm(IAmmFactory(_ammFactory).getAmm(baseToken)).getTwapMarkPrice(twapInterval);
    }

    //
    // INTERNAL NON-VIEW
    //
    /// @dev customized fee: https://www.notion.so/perp/Customise-fee-tier-on-B2QFee-1b7244e1db63416c8651e8fa04128cdb
    function _swap(SwapParams memory params) internal returns (InternalSwapResponse memory) {
        InternalSwapAstp memory swapAstp;

        swapAstp.exchangeFeeRatio = IAmmFactory(_ammFactory).getExchangeFeeRatio(params.baseToken);
        address amm = IAmmFactory(_ammFactory).getAmm(params.baseToken);
        if (params.isSwapWithBase) {
            if (params.isSell) {
                uint256 quoteAmount = IAmm(amm).swap(1, 0, params.amount, params.amountLimit, params.isSell);
                swapAstp.exchangeFee = quoteAmount.mulRatio(swapAstp.exchangeFeeRatio);

                swapAstp.exchangedPositionSize = params.amount.neg256();
                swapAstp.exchangedPositionNotional = quoteAmount.toInt256();
                swapAstp.quote = (quoteAmount - swapAstp.exchangeFee).toInt256();
            } else {
                uint256 quoteAmount = IAmm(amm).swap(1, 0, params.amount, params.amountLimit, params.isSell);
                uint256 realQuoteAmount = FullMath.mulDiv(quoteAmount, 1e6, 1e6 - swapAstp.exchangeFeeRatio);
                swapAstp.exchangeFee = realQuoteAmount.mulRatio(swapAstp.exchangeFeeRatio);

                swapAstp.exchangedPositionSize = params.amount.toInt256();
                swapAstp.exchangedPositionNotional = quoteAmount.neg256();
                swapAstp.quote = (quoteAmount + swapAstp.exchangeFee).neg256();
            }
        } else {
            uint256 limit0 = IAmm(amm).getDy(0, 1, params.amount, params.isSell);
            uint256 limit1;
            if (params.isSell) {
                swapAstp.exchangeFee = params.amount.mulRatio(swapAstp.exchangeFeeRatio);
                limit1 = IAmm(amm).getDy(0, 1, (params.amount - swapAstp.exchangeFee), params.isSell);
                uint256 quoteAmount = IAmm(amm).swap(
                    0,
                    1,
                    (params.amount - swapAstp.exchangeFee),
                    (limit1 * params.amountLimit) / limit0,
                    params.isSell
                );

                swapAstp.exchangedPositionSize = quoteAmount.toInt256();
                swapAstp.exchangedPositionNotional = (params.amount - swapAstp.exchangeFee).neg256();
                swapAstp.quote = params.amount.neg256();
            } else {
                uint256 realAmount = FullMath.mulDiv(params.amount, 1e6, 1e6 - swapAstp.exchangeFeeRatio);
                swapAstp.exchangeFee = realAmount.mulRatio(swapAstp.exchangeFeeRatio);

                limit1 = IAmm(amm).getDy(0, 1, (params.amount + swapAstp.exchangeFee), params.isSell);

                uint256 quoteAmount = IAmm(amm).swap(
                    0,
                    1,
                    (params.amount + swapAstp.exchangeFee),
                    (limit1 * params.amountLimit) / limit0,
                    params.isSell
                );

                swapAstp.exchangedPositionSize = quoteAmount.neg256();
                swapAstp.exchangedPositionNotional = (params.amount + swapAstp.exchangeFee).toInt256();
                swapAstp.quote = params.amount.toInt256();
            }
        }

        // update the timestamp of the first tx in this amm
        if (_firstTradedTimestampMap[params.baseToken] == 0) {
            _firstTradedTimestampMap[params.baseToken] = _blockTimestamp();
        }

        uint24 insuranceFundFeeRatio = IAmmFactory(_ammFactory).getAmmInfo(params.baseToken).insuranceFundFeeRatio;
        uint256 insuranceFundFee = swapAstp.exchangeFee.mulRatio(insuranceFundFeeRatio);

        // save exchangeFee/totalLiquidity ratio in one tx
        uint256 totalLiquidity = IAmm(amm).getTotalLiquidity();
        // use Q96 precision to avoid in calculation result error
        uint256 lpCalcFeeRatio = ((swapAstp.exchangeFee - insuranceFundFee) * Constant.IQ96) / totalLiquidity;
        ILiquidityProvider(_liquidityProvider).updateLPCalcFeeRatio(params.baseToken, lpCalcFeeRatio);

        return
            InternalSwapResponse({
                base: swapAstp.exchangedPositionSize,
                quote: swapAstp.quote,
                exchangedPositionSize: swapAstp.exchangedPositionSize,
                exchangedPositionNotional: swapAstp.exchangedPositionNotional,
                fee: swapAstp.exchangeFee,
                insuranceFundFee: insuranceFundFee
            });
    }

    /// @dev this is the non-view version of getPendingFundingPayment()
    /// @return pendingFundingPayment the pending funding payment of a trader in one amm,
    ///         including liquidity & position
    function _updateFundingGrowth(
        address trader,
        address baseToken,
        int256 baseBalance,
        int256 twPremiumGrowthGlobal,
        Funding.Growth memory fundingGrowthGlobal
    ) internal returns (int256 pendingFundingPayment) {
        int256 liquidityFundingPayment = ILiquidityProvider(_liquidityProvider)
            .updateFundingGrowthAndLiquidityFundingPayment(trader, baseToken, fundingGrowthGlobal);

        return
            Funding.calcPendingFundingPayment(
                baseBalance,
                twPremiumGrowthGlobal,
                fundingGrowthGlobal,
                liquidityFundingPayment
            );
    }

    //
    // INTERNAL VIEW
    //
    /// @dev this function is used only when closePosition()
    ///      inspect whether a tx will go over price limit by simulating closing position before swapping
    function _isOverPriceLimitBySimulatingClosingPosition(
        address baseToken,
        uint256 amount,
        bool isSwapWithBase,
        bool isSell
    ) internal returns (bool) {
        address amm = IAmmFactory(_ammFactory).getAmm(baseToken);
        uint256 priceAfter;
        if (isSwapWithBase) {
            (priceAfter, , ) = IAmm(amm).simulatedSwap(1, 0, amount, isSell);
        } else {
            (priceAfter, , ) = IAmm(amm).simulatedSwap(0, 1, amount, isSell);
        }

        return _isOverPriceLimitWithPrice(baseToken, priceAfter);
    }

    function _isOverPriceLimit(address baseToken) internal view returns (bool) {
        uint256 currentPrice = IAmm(IAmmFactory(_ammFactory).getAmm(baseToken)).getPriceCurrent();
        return _isOverPriceLimitWithPrice(baseToken, currentPrice);
    }

    function _isOverPriceLimitWithPrice(address baseToken, uint256 price) internal view returns (bool) {
        // no over price limit if fluctuationLimitRatio >= 100%
        uint24 fluctuationLimitRatio = IClearingHouseConfig(_clearingHouseConfig).getFluctuationLimitRatio();
        if (fluctuationLimitRatio >= 1e6) {
            return false;
        }

        uint256 lastUpdatedPrice = _lastUpdatedPriceMap[baseToken];

        uint256 upperLimit = lastUpdatedPrice.mulRatio(fluctuationLimitRatio + 1e6);
        uint256 lowerLimit = lastUpdatedPrice.mulRatio(1e6 - fluctuationLimitRatio);

        if ((price <= upperLimit) && (price >= lowerLimit)) {
            return false;
        }
        return true;
    }

    /// @dev this function calculates the up-to-date globalFundingGrowth and twaps and pass them out
    /// @return fundingGrowthGlobal the up-to-date globalFundingGrowth
    /// @return markTwap only for settleFunding()
    /// @return indexTwap only for settleFunding()
    function _getFundingGrowthGlobalAndTwaps(address baseToken)
        internal
        view
        returns (
            Funding.Growth memory fundingGrowthGlobal,
            uint256 markTwap,
            uint256 indexTwap
        )
    {
        uint32 twapInterval;
        uint256 timestamp = _blockTimestamp();
        // shorten twapInterval if prior observations are not enough
        if (_firstTradedTimestampMap[baseToken] != 0) {
            twapInterval = IClearingHouseConfig(_clearingHouseConfig).getTwapInterval();
            // overflow inspection:
            // 2 ^ 32 = 4,294,967,296 > 100 years = 60 * 60 * 24 * 365 * 100 = 3,153,600,000
            uint32 deltaTimestamp = (timestamp - _firstTradedTimestampMap[baseToken]).toUint32();
            twapInterval = twapInterval > deltaTimestamp ? deltaTimestamp : twapInterval;
        }

        markTwap = getTwapMarkPrice(baseToken, twapInterval);
        indexTwap = IIndexPrice(baseToken).getIndexPrice(twapInterval);

        uint256 lastSettledTimestamp = _lastSettledTimestampMap[baseToken];
        Funding.Growth storage lastFundingGrowthGlobal = _globalFundingGrowthMap[baseToken];
        if (timestamp == lastSettledTimestamp || lastSettledTimestamp == 0) {
            // if this is the latest updated timestamp, values in _globalFundingGrowthMap are up-to-date already
            fundingGrowthGlobal = lastFundingGrowthGlobal;
        } else {
            // deltaTwPremium = (markTwap - indexTwap) * (now - lastSettledTimestamp)
            int256 deltaTwPremium = _getDeltaTwap(markTwap.formatX1e18ToX96(), indexTwap.formatX1e18ToX96()) *
                ((timestamp - lastSettledTimestamp).toInt256());
            fundingGrowthGlobal.twPremium = lastFundingGrowthGlobal.twPremium + deltaTwPremium;

            // overflow inspection:
            // assuming premium = 1 billion (1e9), time diff = 1 year (3600 * 24 * 365)
            // log(1e9 * 1e18 * (3600 * 24 * 365) * 1e18) / log(2) = 246.8078491997 < 255
            // twPremiumWithLiquidity += deltaTwPremium * balanceBase /totalLiquidity
            address amm = IAmmFactory(_ammFactory).getAmm(baseToken);
            uint256 totalLiquidity = IAmm(amm).getTotalLiquidity();
            if (totalLiquidity != 0) {
                uint256 balanceBase = IAmm(amm).getBalances(1);
                fundingGrowthGlobal.twPremiumWithLiquidity =
                    lastFundingGrowthGlobal.twPremiumWithLiquidity +
                    SigmaMath.mulDiv(balanceBase.toInt256(), deltaTwPremium, totalLiquidity);
            }
        }

        return (fundingGrowthGlobal, markTwap, indexTwap);
    }

    function _getDeltaTwap(uint256 markTwap, uint256 indexTwap) internal view returns (int256 deltaTwap) {
        uint24 maxFundingRate = IClearingHouseConfig(_clearingHouseConfig).getMaxFundingRate();
        uint256 maxDeltaTwap = indexTwap.mulRatio(maxFundingRate);
        uint256 absDeltaTwap;
        if (markTwap > indexTwap) {
            absDeltaTwap = markTwap - indexTwap;
            deltaTwap = absDeltaTwap > maxDeltaTwap ? maxDeltaTwap.toInt256() : absDeltaTwap.toInt256();
        } else {
            absDeltaTwap = indexTwap - markTwap;
            deltaTwap = absDeltaTwap > maxDeltaTwap ? maxDeltaTwap.neg256() : absDeltaTwap.neg256();
        }
    }

    function _getPnlToBeRealized(InternalRealizePnlParams memory params) internal pure returns (int256) {
        // closedRatio is based on the position size
        uint256 closedRatio = FullMath.mulDiv(params.base.abs(), _FULLY_CLOSED_RATIO, params.takerPositionSize.abs());

        int256 pnlToBeRealized;
        // if closedRatio <= 1, it's reducing or closing a position; else, it's opening a larger reverse position
        if (closedRatio <= _FULLY_CLOSED_RATIO) {
            // trader:
            // step 1: long 20 base
            // openNotionalFraction = 252.53
            // openNotional = -252.53
            // step 2: short 10 base (reduce half of the position)
            // quote = 137.5
            // closeRatio = 10/20 = 0.5
            // reducedOpenNotional = openNotional * closedRatio = -252.53 * 0.5 = -126.265
            // realizedPnl = quote + reducedOpenNotional = 137.5 + -126.265 = 11.235
            // openNotionalFraction = openNotionalFraction - quote + realizedPnl
            //                      = 252.53 - 137.5 + 11.235 = 126.265
            // openNotional = -openNotionalFraction = 126.265
            int256 reducedOpenNotional = params.takerOpenNotional.mulDiv(closedRatio.toInt256(), _FULLY_CLOSED_RATIO);
            pnlToBeRealized = params.quote + reducedOpenNotional;
        } else {
            // trader:
            // step 1: long 20 base
            // openNotionalFraction = 252.53
            // openNotional = -252.53
            // step 2: short 30 base (open a larger reverse position)
            // quote = 337.5
            // closeRatio = 30/20 = 1.5
            // closedPositionNotional = quote / closeRatio = 337.5 / 1.5 = 225
            // remainsPositionNotional = quote - closedPositionNotional = 337.5 - 225 = 112.5
            // realizedPnl = closedPositionNotional + openNotional = -252.53 + 225 = -27.53
            // openNotionalFraction = openNotionalFraction - quote + realizedPnl
            //                      = 252.53 - 337.5 + -27.53 = -112.5
            // openNotional = -openNotionalFraction = remainsPositionNotional = 112.5
            int256 closedPositionNotional = params.quote.mulDiv(int256(_FULLY_CLOSED_RATIO), closedRatio);
            pnlToBeRealized = params.takerOpenNotional + closedPositionNotional;
        }

        return pnlToBeRealized;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
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
        unchecked {
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
            uint256 twos = (0 - denominator) & denominator;
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
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;
pragma abicoder v2;

import { FullMath } from "./FullMath.sol";
import { Constant } from "./Constant.sol";

library SigmaMath {
    function copy(uint256[2] memory data) internal pure returns (uint256[2] memory) {
        uint256[2] memory result;
        for (uint8 i = 0; i < 2; i++) {
            result[i] = data[i];
        }
        return result;
    }

    function shift(uint256 x, int256 _shift) internal pure returns (uint256) {
        if (_shift > 0) {
            return x << abs(_shift);
        } else if (_shift < 0) {
            return x >> abs(_shift);
        }

        return x;
    }

    function bitwiseOr(uint256 x, uint256 y) internal pure returns (uint256) {
        return x | y;
    }

    function bitwiseAnd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x & y;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function abs(int256 value) internal pure returns (uint256) {
        return value >= 0 ? toUint256(value) : toUint256(neg256(value));
    }

    function neg256(int256 a) internal pure returns (int256) {
        require(a > -2**255, "SigmaMath: inversion overflow");
        return -a;
    }

    function neg256(uint256 a) internal pure returns (int256) {
        return -toInt256(a);
    }

    function formatX1e18ToX96(uint256 valueX10_18) internal pure returns (uint256) {
        return FullMath.mulDiv(valueX10_18, Constant.IQ96, 1 ether);
    }

    function mulRatio(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return FullMath.mulDiv(value, ratio, 1e6);
    }

    /// @param denominator cannot be 0 and is checked in FullMath.mulDiv()
    function mulDiv(
        int256 a,
        int256 b,
        uint256 denominator
    ) internal pure returns (int256 result) {
        uint256 unsignedA = a < 0 ? uint256(neg256(a)) : uint256(a);
        uint256 unsignedB = b < 0 ? uint256(neg256(b)) : uint256(b);
        bool negative = ((a < 0 && b > 0) || (a > 0 && b < 0)) ? true : false;

        uint256 unsignedResult = FullMath.mulDiv(unsignedA, unsignedB, denominator);

        result = negative ? neg256(unsignedResult) : toInt256(unsignedResult);

        return result;
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
    function toUint32(uint256 value) internal pure returns (uint32 returnValue) {
        require(((returnValue = uint32(value)) == value), "SafeCast: value doesn't fit in 32 bits");
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
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;

library Account {
    struct TakerInfo {
        int256 takerPositionSize;
        int256 takerOpenNotional;
        int256 lastTwPremiumGrowthGlobal;
    }

    struct LPInfo {
        uint256 liquidity;
        uint256 lastExchangeFeeIndex;
        int256 lastTwPremiumGrowth;
        int256 lastTwPremiumWithLiquidityGrowth;
        uint256 baseDebt;
        uint256 quoteDebt;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;

library Constant {
    address internal constant ADDRESS_ZERO = address(0);
    uint256 internal constant DECIMAL_ONE = 1e18;
    int256 internal constant DECIMAL_ONE_SIGNED = 1e18;
    uint256 internal constant IQ96 = 0x1000000000000000000000000;
    int256 internal constant IQ96_SIGNED = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;

interface IIndexPrice {
    /// @dev Returns the index price of the token.
    /// @param interval The interval represents twap interval.
    function getIndexPrice(uint256 interval) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;
pragma abicoder v2;

import { Funding } from "../lib/Funding.sol";
import { Account } from "../lib/Account.sol";

interface ILiquidityProvider {
    struct AddLiquidityParams {
        address maker;
        address baseToken;
        uint256 base;
        uint256 quote;
        uint256 minLiquidity;
        Funding.Growth fundingGrowthGlobal;
    }

    struct RemoveLiquidityParams {
        address maker;
        address baseToken;
        uint256 liquidity;
        uint256 minBase;
        uint256 minQuote;
    }

    struct AddLiquidityResponse {
        uint256 base;
        uint256 quote;
        uint256 fee;
        uint256 liquidity;
    }

    struct RemoveLiquidityResponse {
        uint256 base;
        uint256 quote;
        uint256 fee;
        int256 takerBase;
        int256 takerQuote;
    }

    /// @param trader the address of trader contract
    event MarketTakerChanged(address indexed trader);

    function addLiquidity(AddLiquidityParams calldata params) external returns (AddLiquidityResponse memory);

    function removeLiquidity(RemoveLiquidityParams calldata params) external returns (RemoveLiquidityResponse memory);

    // function updateLPOrderDebt(
    //     address trader,
    //     address baseToken,
    //     int256 base,
    //     int256 quote
    // ) external;

    function getOpenOrder(address trader, address baseToken) external view returns (Account.LPInfo memory);

    function hasOrder(address trader, address[] calldata tokens) external view returns (bool);

    function getTotalLPQuoteAmountAndPendingFee(address trader, address[] calldata baseTokens)
        external
        view
        returns (int256 totalQuoteAmountInAmms, uint256 totalPendingFee);

    /// @dev the returned quote amount does not include funding payment because
    ///      the latter is counted directly toward realizedPnl.
    ///      the return value includes maker fee.
    ///      please refer to _getTotalTokenAmountInAmm() docstring for specs
    function getTotalTokenAmountInAmmAndPendingFee(
        address trader,
        address baseToken,
        bool fetchBase
    ) external view returns (uint256 tokenAmount, uint256 totalPendingFee);

    function getTotalLPOrderDebt(
        address trader,
        address baseToken,
        bool fetchBase
    ) external view returns (uint256);

    /// @dev this is the view version of updateFundingGrowthAndLiquidityFundingPayment()
    /// @return liquidityFundingPayment the funding payment of all orders/liquidity of a maker
    function getLiquidityFundingPayment(
        address trader,
        address baseToken,
        Funding.Growth memory fundingGrowthGlobal
    ) external view returns (int256 liquidityFundingPayment);

    function getPendingFee(address trader, address baseToken) external view returns (uint256);

    /// @dev this is the non-view version of getLiquidityFundingPayment()
    /// @return liquidityFundingPayment the funding payment of all orders/liquidity of a maker
    function updateFundingGrowthAndLiquidityFundingPayment(
        address trader,
        address baseToken,
        Funding.Growth memory fundingGrowthGlobal
    ) external returns (int256 liquidityFundingPayment);

    function getMarketTaker() external view returns (address);

    function updateLPCalcFeeRatio(address baseToken, uint256 fee) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;
pragma abicoder v2;

interface IAmmFactory {
    struct AmmInfo {
        address amm;
        uint24 exchangeFeeRatio;
        uint24 insuranceFundFeeRatio;
    }

    event AmmAdded(address indexed baseToken, uint24 indexed exchangeFeeRatio, address indexed amm);

    event ExchangeFeeRatioChanged(address baseToken, uint24 exchangeFeeRatio);

    event InsuranceFundFeeRatioChanged(uint24 insuranceFundFeeRatio);

    function addAmm(
        address baseToken,
        address amm,
        uint24 exchangeFeeRatio
    ) external;

    function setExchangeFeeRatio(address baseToken, uint24 exchangeFeeRatio) external;

    function setInsuranceFundFeeRatio(address baseToken, uint24 insuranceFundFeeRatioArg) external;

    function getAmm(address baseToken) external view returns (address);

    function getExchangeFeeRatio(address baseToken) external view returns (uint24);

    function getInsuranceFundFeeRatio(address baseToken) external view returns (uint24);

    function getAmmInfo(address baseToken) external view returns (AmmInfo memory);

    function getQuoteToken() external view returns (address);

    function hasAmm(address baseToken) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;
pragma abicoder v2;

import { Account } from "../lib/Account.sol";

interface IPositionMgmt {
    /// @param vault The address of the vault contract
    event VaultChanged(address indexed vault);

    /// @dev Emit whenever a trader's `owedRealizedPnl` is updated
    /// @param trader The address of the trader
    /// @param amount The amount changed
    event PnlRealized(address indexed trader, int256 amount);

    function modifyTakerBalance(
        address trader,
        address baseToken,
        int256 base,
        int256 quote
    ) external returns (int256, int256);

    function modifyOwedRealizedPnl(address trader, int256 amount) external;

    function settleQuoteToOwedRealizedPnl(
        address trader,
        address baseToken,
        int256 amount
    ) external;

    /// @dev this function is now only called by Vault.withdraw()
    function settleOwedRealizedPnl(address trader) external returns (int256 pnl);

    /// @dev Settle account balance and deregister base token
    /// @param maker The address of the maker
    /// @param baseToken The address of the amm's base token
    /// @param realizedPnl Amount of pnl realized
    /// @param fee Amount of fee collected from amm
    function settleBalanceAndDeregister(
        address maker,
        address baseToken,
        int256 takerBase,
        int256 takerQuote,
        int256 realizedPnl,
        int256 fee
    ) external;

    /// @dev every time a trader's position value is checked, the base token list of this trader will be traversed;
    ///      thus, this list should be kept as short as possible
    /// @param trader The address of the trader
    /// @param baseToken The address of the trader's base token
    function registerBaseToken(address trader, address baseToken) external;

    /// @dev this function is expensive
    /// @param trader The address of the trader
    /// @param baseToken The address of the trader's base token
    function deregisterBaseToken(address trader, address baseToken) external;

    function updateTwPremiumGrowthGlobal(
        address trader,
        address baseToken,
        int256 lastTwPremiumGrowthGlobal
    ) external;

    function getClearingHouseConfig() external view returns (address);

    function getLiquidityProvider() external view returns (address);

    function getVault() external view returns (address);

    function getBaseTokens(address trader) external view returns (address[] memory);

    function getAccountInfo(address trader, address baseToken) external view returns (Account.TakerInfo memory);

    function getTakerOpenNotional(address trader, address baseToken) external view returns (int256);

    /// @return totalOpenNotional the amount of quote token paid for a position when opening
    function getTotalOpenNotional(address trader, address baseToken) external view returns (int256);

    function getTotalDebtValue(address trader) external view returns (uint256);

    /// @dev this is different from Vault._getTotalMarginRequirement(), which is for freeCollateral calculation
    /// @return int instead of uint, as it is compared with ClearingHouse.getAccountValue(), which is also an int
    function getMarginRequirementForLiquidation(address trader) external view returns (int256);

    /// @return owedRealizedPnl the pnl realized already but stored temporarily in PositionMgmt
    /// @return unrealizedPnl the pnl not yet realized
    /// @return pendingFee the pending fee of maker earned
    function getPnlAndPendingFee(address trader)
        external
        view
        returns (
            int256 owedRealizedPnl,
            int256 unrealizedPnl,
            uint256 pendingFee
        );

    function hasOrder(address trader) external view returns (bool);

    function getBase(address trader, address baseToken) external view returns (int256);

    function getQuote(address trader, address baseToken) external view returns (int256);

    function getTakerPositionSize(address trader, address baseToken) external view returns (int256);

    function getTotalPositionSize(address trader, address baseToken) external view returns (int256);

    /// @dev a negative returned value is only be used when calculating pnl
    /// @dev we use 15 mins twap to calc position value
    function getTotalPositionValue(address trader, address baseToken) external view returns (int256);

    /// @return sum up positions value of every amm, it calls `getTotalPositionValue` internally
    function getTotalAbsPositionValue(address trader) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;

interface IClearingHouseConfig {
    event PartialCloseRatioChanged(uint24 partialCloseRatio);

    event LiquidationPenaltyRatioChanged(uint24 liquidationPenaltyRatio);

    event MaxFundingRateChanged(uint24 maxFundingRate);

    event FluctuationLimitRatioChanged(uint24 fluctuationLimitRatio);

    event TwapIntervalChanged(uint32 twapInterval);

    event MaxAmmsPerAccountChanged(uint8 maxAmmsPerAccount);

    event SettlementTokenBalanceCapChanged(uint256 cap);

    event BackstopLiquidityProviderChanged(address indexed account, bool indexed isProvider);

    function getImRatio() external view returns (uint24);

    function getMmRatio() external view returns (uint24);

    function getPartialCloseRatio() external view returns (uint24);

    function getLiquidationPenaltyRatio() external view returns (uint24);

    function getMaxFundingRate() external view returns (uint24);

    function getFluctuationLimitRatio() external view returns (uint24);

    function getTwapInterval() external view returns (uint32);

    function getMaxAmmsPerAccount() external view returns (uint8);

    function getSettlementTokenBalanceCap() external view returns (uint256);

    function isBackstopLiquidityProvider(address account) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;
pragma abicoder v2;

import { Funding } from "../lib/Funding.sol";

interface IMarketTaker {
    /// @param amount when closing position, amount(uint256) == takerPositionSize(int256),
    ///        as amount is assigned as takerPositionSize in ClearingHouse.closePosition()
    struct SwapParams {
        address trader;
        address baseToken;
        bool isSwapWithBase;
        bool isSell;
        bool isClose;
        uint256 amount;
        uint256 amountLimit;
    }

    struct SwapResponse {
        int256 base;
        int256 quote;
        int256 exchangedPositionSize;
        int256 exchangedPositionNotional;
        uint256 fee;
        uint256 insuranceFundFee;
        int256 pnlToBeRealized;
    }

    struct RealizePnlParams {
        address trader;
        address baseToken;
        int256 base;
        int256 quote;
    }

    event FundingUpdated(address indexed baseToken, uint256 markTwap, uint256 indexTwap);

    /// @param positionMgmt The address of positionMgmt contract
    event PositionMgmtChanged(address positionMgmt);

    function swap(SwapParams memory params) external returns (SwapResponse memory);

    /// @dev this function should be called at the beginning of every high-level function, such as openPosition()
    ///      while it doesn't matter who calls this function
    ///      this function 1. settles personal funding payment 2. updates global funding growth
    ///      personal funding payment is settled whenever there is pending funding payment
    ///      the global funding growth update only happens once per unique timestamp (not blockNumber, due to Arbitrum)
    /// @return fundingPayment the funding payment of a trader in one amm should be settled into owned realized Pnl
    /// @return fundingGrowthGlobal the up-to-date globalFundingGrowth, usually used for later calculations
    function settleFunding(address trader, address baseToken)
        external
        returns (int256 fundingPayment, Funding.Growth memory fundingGrowthGlobal);

    function getAllPendingFundingPayment(address trader) external view returns (int256);

    /// @dev this is the view version of _updateFundingGrowth()
    /// @return the pending funding payment of a trader in one amm, including liquidity & position
    function getPendingFundingPayment(address trader, address baseToken) external view returns (int256);

    function getTwapMarkPrice(address baseToken, uint32 twapInterval) external view returns (uint256);

    function getPnlToBeRealized(RealizePnlParams memory params) external view returns (int256);

    function getLiquidityProvider() external view returns (address);

    function getPositionMgmt() external view returns (address);

    function getClearingHouseConfig() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;

interface IAmm {
    /// @param coinPairs 0: quote token address, 1: base token address
    struct InitializeParams {
        uint256 A;
        uint256 gamma;
        uint256 adjustmentStep;
        uint256 maHalfTime;
        uint256 initialPrice;
        address baseToken;
        address quoteToken;
        address clearingHouse;
        address marketTaker;
        address liquidityProvider;
    }

    // Events
    event TokenExchange(address indexed buyer, uint256 i, uint256 dx, uint256 j, uint256 dy, bool isSell);

    event AddLiquidity(
        address indexed provider,
        uint256 amount0,
        uint256 amount1,
        uint256 liquidity,
        uint256 totalLiquidity
    );

    event RemoveLiquidity(
        address indexed provider,
        uint256 amount0,
        uint256 amount1,
        uint256 liquidity,
        uint256 totalLiquidity
    );

    event CommitNewParameters(uint256 indexed deadline, uint256 adjustmentStep, uint256 maHalfTime);

    event NewParameters(uint256 adjustmentStep, uint256 maHalfTime);

    event RampAgamma(
        uint256 initialA,
        uint256 futureA,
        uint256 initialGamma,
        uint256 futureGamma,
        uint256 initialTime,
        uint256 futureTime
    );

    event StopRampA(uint256 currentA, uint256 currentGamma, uint256 time);

    event CalcPriceAfterSwap(
        address sender,
        uint256 amountIn,
        uint256 amountOut,
        uint256 priceAfter,
        bool isSell
    );

    event ClearingHouseChanged(address clearingHouse);

    event MarketTakerChanged(address marketTaker);

    event LiquidityProviderChanged(address liquidityProvider);

    function addLiquidity(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 minLiquidity
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function removeLiquidity(
        uint256 liquidity,
        uint256 minAmount0,
        uint256 minAmount1
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 dyLimit,
        bool isSell
    ) external returns (uint256);

    function simulatedSwap(
        uint256 i,
        uint256 j,
        uint256 dx,
        bool isSell
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function getDy(
        uint256 i,
        uint256 j,
        uint256 dx,
        bool isSell
    ) external view returns (uint256);

    function getA() external view returns (uint256);

    function getGamma() external view returns (uint256);

    function getCoins(uint256 i) external view returns (address);

    function getBalances(uint256 i) external view returns (uint256);

    function getPriceScale() external view returns (uint256);

    function getPriceOracle() external view returns (uint256);

    function getPriceLast() external view returns (uint256);

    function getPriceCurrent() external view returns (uint256);

    function getTwapMarkPrice(uint256 interval) external view returns (uint256);

    function getTotalLiquidity() external view returns (uint256);

    function calcTokenAmountsByLiquidity(uint256 liquidity) external view returns (uint256 amount0, uint256 amount1);

    function calcLiquidityByTokenAmounts(uint256 amount0Desired, uint256 amount1Desired)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;

abstract contract BlockContext {
    function _blockTimestamp() internal view virtual returns (uint256) {
        // Reply from Arbitrum
        // block.timestamp returns timestamp at the time at which the sequencer receives the tx.
        // It may not actually correspond to a particular L1 block
        return block.timestamp;
    }

    function _blockNumber() internal view virtual returns (uint256) {
        return block.number;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;

import { Funding } from "../lib/Funding.sol";

/// @notice For future upgrades, do not change MarketTakerStorageV1. Create a new
/// contract which implements MarketTakerStorageV1 and following the naming convention
/// MarketTakerStorageVX.
abstract contract MarketTakerStorageV1 {
    address internal _liquidityProvider;
    address internal _positionMgmt;
    address internal _clearingHouseConfig;
    address internal _ammFactory;

    mapping(address => uint256) internal _lastUpdatedPriceMap;
    mapping(address => uint256) internal _firstTradedTimestampMap;
    mapping(address => uint256) internal _lastSettledTimestampMap;
    mapping(address => Funding.Growth) internal _globalFundingGrowthMap;

    // first key: trader, second key: baseToken
    // value: the last timestamp when a trader exceeds price limit when closing a position/being liquidated
    mapping(address => mapping(address => uint256)) internal _lastOverPriceLimitTimestampMap;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;
pragma abicoder v2;

import { SafeOwnable } from "../base/SafeOwnable.sol";

abstract contract ClearingHouseCallee is SafeOwnable {
    address internal _clearingHouse;
    uint256[50] private __gap;

    event ClearingHouseChanged(address indexed clearingHouse);

    // solhint-disable-next-line func-order
    function __ClearingHouseCallee_init() internal initializer {
        __SafeOwnable_init();
    }

    function setClearingHouse(address clearingHouseArg) external onlyOwner {
        _clearingHouse = clearingHouseArg;
        emit ClearingHouseChanged(clearingHouseArg);
    }

    function getClearingHouse() external view returns (address) {
        return _clearingHouse;
    }

    function _requireOnlyClearingHouse() internal view {
        // CHD_OCH: only ClearingHouse
        require(_msgSender() == _clearingHouse, "CHD_OCH");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;

import { SigmaMath } from "./SigmaMath.sol";
import { Account } from "./Account.sol";
import { Constant } from "./Constant.sol";

library Funding {
    using SigmaMath for int256;
    using SigmaMath for uint256;

    //
    // STRUCT
    //

    /// @dev tw: time-weighted
    /// @param twPremium overflow inspection (as twPremium > twPremiumWithLiquidity):
    //         max = 2 ^ (255 - 96) = 2 ^ 159 = 7.307508187E47
    //         assume premium = 10000, time = 10 year = 60 * 60 * 24 * 365 * 10 -> twPremium = 3.1536E12
    struct Growth {
        int256 twPremium;
        int256 twPremiumWithLiquidity;
    }

    //
    // CONSTANT
    //

    /// @dev block-based funding is calculated as: premium * timeFraction / 1 day, for 1 day as the default period
    int256 internal constant _DEFAULT_FUNDING_PERIOD = 1 days;

    //
    // INTERNAL PURE
    //

    function calcPendingFundingPayment(
        int256 baseBalance,
        int256 twPremiumGrowthGlobal,
        Growth memory fundingGrowthGlobal,
        int256 liquidityFundingPayment
    ) internal pure returns (int256) {
        int256 positionFundingPayment = SigmaMath.mulDiv(
            baseBalance,
            (fundingGrowthGlobal.twPremium - twPremiumGrowthGlobal),
            Constant.IQ96
        );

        int256 pendingFundingPayment = (liquidityFundingPayment + positionFundingPayment) / _DEFAULT_FUNDING_PERIOD;

        // make RoundingUp to avoid bed debt
        // if pendingFundingPayment > 0: long pay 1wei more, short got 1wei less
        // if pendingFundingPayment < 0: long got 1wei less, short pay 1wei more
        if (pendingFundingPayment != 0) {
            pendingFundingPayment++;
        }

        return pendingFundingPayment;
    }

    /// @return liquidityFundingPayment the funding payment of an LP order
    function calcLiquidityFundingPayment(Account.LPInfo memory order, Funding.Growth memory fundingGrowthGlobal)
        internal
        pure
        returns (int256)
    {
        if (order.liquidity == 0) {
            return 0;
        }

        int256 fundingPaymentLP = order.liquidity.toInt256() *
            (fundingGrowthGlobal.twPremiumWithLiquidity - order.lastTwPremiumWithLiquidityGrowth);
        return fundingPaymentLP / Constant.IQ96_SIGNED;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;

import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { Constant } from "../lib/Constant.sol";

abstract contract SafeOwnable is ContextUpgradeable {
    address private _owner;
    address private _candidate;

    // __gap is reserved storage
    uint256[50] private __gap;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        // SO_CNO: caller not owner
        require(owner() == _msgSender(), "SO_CNO");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __SafeOwnable_init() internal initializer {
        __Context_init();
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(Constant.ADDRESS_ZERO, msgSender);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        // emitting event first to avoid caching values
        emit OwnershipTransferred(_owner, Constant.ADDRESS_ZERO);
        _owner = Constant.ADDRESS_ZERO;
        _candidate = Constant.ADDRESS_ZERO;
    }

    /**
     * @dev Set ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function setOwner(address newOwner) external onlyOwner {
        // SO_NW0: newOwner is 0
        require(newOwner != Constant.ADDRESS_ZERO, "SO_NW0");
        // SO_SAO: same as original
        require(newOwner != _owner, "SO_SAO");
        // SO_SAC: same as candidate
        require(newOwner != _candidate, "SO_SAC");

        _candidate = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`_candidate`).
     * Can only be called by the new owner.
     */
    function updateOwner() external {
        // SO_C0: candidate is zero
        require(_candidate != Constant.ADDRESS_ZERO, "SO_C0");
        // SO_CNC: caller is not candidate
        require(_candidate == _msgSender(), "SO_CNC");

        // emitting event first to avoid caching values
        emit OwnershipTransferred(_owner, _candidate);
        _owner = _candidate;
        _candidate = Constant.ADDRESS_ZERO;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the candidate that can become the owner.
     */
    function candidate() external view returns (address) {
        return _candidate;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}