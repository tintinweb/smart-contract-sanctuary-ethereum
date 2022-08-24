// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Multicall } from "@openzeppelin/contracts/utils/Multicall.sol";
import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { IPerpdexMarket } from "./interfaces/IPerpdexMarket.sol";
import { MarketStructs } from "./lib/MarketStructs.sol";
import { FundingLibrary } from "./lib/FundingLibrary.sol";
import { PoolLibrary } from "./lib/PoolLibrary.sol";
import { PriceLimitLibrary } from "./lib/PriceLimitLibrary.sol";
import { OrderBookLibrary } from "./lib/OrderBookLibrary.sol";
import { PoolFeeLibrary } from "./lib/PoolFeeLibrary.sol";
import { CandleLibrary } from "./lib/CandleLibrary.sol";

contract PerpdexMarket is IPerpdexMarket, ReentrancyGuard, Ownable, Multicall {
    using Address for address;
    using SafeCast for uint256;
    using SafeMath for uint256;

    event PoolFeeConfigChanged(uint24 fixedFeeRatio, uint24 atrFeeRatio, uint32 atrEmaBlocks);
    event FundingMaxPremiumRatioChanged(uint24 value);
    event FundingMaxElapsedSecChanged(uint32 value);
    event FundingRolloverSecChanged(uint32 value);
    event PriceLimitConfigChanged(
        uint24 normalOrderRatio,
        uint24 liquidationRatio,
        uint24 emaNormalOrderRatio,
        uint24 emaLiquidationRatio,
        uint32 emaSec
    );

    string public symbol;
    address public immutable exchange;
    address public immutable priceFeedBase;
    address public immutable priceFeedQuote;

    MarketStructs.PoolInfo public poolInfo;
    MarketStructs.FundingInfo public fundingInfo;
    MarketStructs.PriceLimitInfo public priceLimitInfo;
    MarketStructs.OrderBookInfo internal _orderBookInfo;
    MarketStructs.PoolFeeInfo public poolFeeInfo;
    MarketStructs.CandleList public candleList;

    uint24 public fundingMaxPremiumRatio = 1e4;
    uint32 public fundingMaxElapsedSec = 1 days;
    uint32 public fundingRolloverSec = 1 days;
    MarketStructs.PriceLimitConfig public priceLimitConfig =
        MarketStructs.PriceLimitConfig({
            normalOrderRatio: 5e4,
            liquidationRatio: 10e4,
            emaNormalOrderRatio: 20e4,
            emaLiquidationRatio: 25e4,
            emaSec: 5 minutes
        });
    MarketStructs.PoolFeeConfig public poolFeeConfig =
        MarketStructs.PoolFeeConfig({ fixedFeeRatio: 0, atrFeeRatio: 4e6, atrEmaBlocks: 16 });

    modifier onlyExchange() {
        _onlyExchange();
        _;
    }

    constructor(
        address ownerArg,
        string memory symbolArg,
        address exchangeArg,
        address priceFeedBaseArg,
        address priceFeedQuoteArg
    ) {
        _transferOwnership(ownerArg);
        require(priceFeedBaseArg == address(0) || priceFeedBaseArg.isContract(), "PM_C: base price feed invalid");
        require(priceFeedQuoteArg == address(0) || priceFeedQuoteArg.isContract(), "PM_C: quote price feed invalid");

        symbol = symbolArg;
        exchange = exchangeArg;
        priceFeedBase = priceFeedBaseArg;
        priceFeedQuote = priceFeedQuoteArg;

        FundingLibrary.initializeFunding(fundingInfo);
        PoolLibrary.initializePool(poolInfo);
    }

    function swap(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        bool isLiquidation
    ) external onlyExchange nonReentrant returns (SwapResponse memory response) {
        (uint256 maxAmount, MarketStructs.PriceLimitInfo memory updated) =
            _doMaxSwap(isBaseToQuote, isExactInput, isLiquidation, 0);
        require(amount <= maxAmount, "PM_S: too large amount");

        uint256 sharePriceBeforeX96 = getShareMarkPriceX96();

        OrderBookLibrary.SwapResponse memory swapResponse =
            OrderBookLibrary.swap(
                _orderBookInfo,
                OrderBookLibrary.PreviewSwapParams({
                    isBaseToQuote: isBaseToQuote,
                    isExactInput: isExactInput,
                    amount: amount,
                    baseBalancePerShareX96: poolInfo.baseBalancePerShareX96
                }),
                _poolMaxSwap,
                _poolSwap
            );
        response = SwapResponse({
            oppositeAmount: swapResponse.oppositeAmount,
            basePartial: swapResponse.basePartial,
            quotePartial: swapResponse.quotePartial,
            partialOrderId: swapResponse.partialKey
        });

        {
            uint256 priceX96 = isBaseToQuote ? getBidPriceX96() : getAskPriceX96();
            uint256 quote = isBaseToQuote == isExactInput ? swapResponse.oppositeAmount : amount;
            CandleLibrary.update(candleList, block.timestamp.toUint32(), priceX96, quote);
        }

        PoolFeeLibrary.update(poolFeeInfo, poolFeeConfig.atrEmaBlocks, sharePriceBeforeX96, getShareMarkPriceX96());
        PriceLimitLibrary.update(priceLimitInfo, updated);

        emit Swapped(
            isBaseToQuote,
            isExactInput,
            amount,
            response.oppositeAmount,
            swapResponse.fullLastKey,
            response.partialOrderId,
            response.basePartial,
            response.quotePartial
        );

        _processFunding();
    }

    function _poolSwap(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount
    ) private returns (uint256) {
        return
            PoolLibrary.swap(
                poolInfo,
                PoolLibrary.SwapParams({
                    isBaseToQuote: isBaseToQuote,
                    isExactInput: isExactInput,
                    amount: amount,
                    feeRatio: feeRatio()
                })
            );
    }

    function addLiquidity(uint256 baseShare, uint256 quoteBalance)
        external
        onlyExchange
        nonReentrant
        returns (
            uint256 base,
            uint256 quote,
            uint256 liquidity
        )
    {
        if (poolInfo.totalLiquidity == 0) {
            FundingLibrary.validateInitialLiquidityPrice(priceFeedBase, priceFeedQuote, baseShare, quoteBalance);
        }

        (base, quote, liquidity) = PoolLibrary.addLiquidity(
            poolInfo,
            PoolLibrary.AddLiquidityParams({ base: baseShare, quote: quoteBalance })
        );
        emit LiquidityAdded(base, quote, liquidity);
    }

    function removeLiquidity(uint256 liquidity)
        external
        onlyExchange
        nonReentrant
        returns (uint256 base, uint256 quote)
    {
        (base, quote) = PoolLibrary.removeLiquidity(
            poolInfo,
            PoolLibrary.RemoveLiquidityParams({ liquidity: liquidity })
        );
        emit LiquidityRemoved(base, quote, liquidity);
    }

    function createLimitOrder(
        bool isBid,
        uint256 base,
        uint256 priceX96,
        bool ignorePostOnlyCheck
    ) external onlyExchange nonReentrant returns (uint40 orderId) {
        if (!ignorePostOnlyCheck) {
            if (isBid) {
                require(priceX96 <= getAskPriceX96(), "PM_CLO: post only bid");
            } else {
                require(priceX96 >= getBidPriceX96(), "PM_CLO: post only ask");
            }
        }
        orderId = OrderBookLibrary.createOrder(_orderBookInfo, isBid, base, priceX96, getMarkPriceX96());
        emit LimitOrderCreated(isBid, base, priceX96, orderId);
    }

    function cancelLimitOrder(bool isBid, uint40 orderId) external onlyExchange nonReentrant {
        OrderBookLibrary.cancelOrder(_orderBookInfo, isBid, orderId);
        emit LimitOrderCanceled(isBid, orderId);
    }

    function setFundingMaxPremiumRatio(uint24 value) external onlyOwner nonReentrant {
        require(value <= 1e5, "PM_SFMPR: too large");
        fundingMaxPremiumRatio = value;
        emit FundingMaxPremiumRatioChanged(value);
    }

    function setFundingMaxElapsedSec(uint32 value) external onlyOwner nonReentrant {
        require(value <= 7 days, "PM_SFMES: too large");
        fundingMaxElapsedSec = value;
        emit FundingMaxElapsedSecChanged(value);
    }

    function setFundingRolloverSec(uint32 value) external onlyOwner nonReentrant {
        require(value <= 7 days, "PM_SFRS: too large");
        require(value >= 1 hours, "PM_SFRS: too small");
        fundingRolloverSec = value;
        emit FundingRolloverSecChanged(value);
    }

    function setPriceLimitConfig(MarketStructs.PriceLimitConfig calldata value) external onlyOwner nonReentrant {
        require(value.liquidationRatio <= 5e5, "PE_SPLC: too large liquidation");
        require(value.normalOrderRatio <= value.liquidationRatio, "PE_SPLC: invalid");
        require(value.emaLiquidationRatio < 1e6, "PE_SPLC: ema too large liq");
        require(value.emaNormalOrderRatio <= value.emaLiquidationRatio, "PE_SPLC: ema invalid");
        priceLimitConfig = value;
        emit PriceLimitConfigChanged(
            value.normalOrderRatio,
            value.liquidationRatio,
            value.emaNormalOrderRatio,
            value.emaLiquidationRatio,
            value.emaSec
        );
    }

    function setPoolFeeConfig(MarketStructs.PoolFeeConfig calldata value) external onlyOwner nonReentrant {
        require(value.fixedFeeRatio <= 5e4, "PM_SPFC: fixed fee too large");
        require(value.atrEmaBlocks <= 1e4, "PM_SPFC: atr ema blocks too big");
        poolFeeConfig = value;
        emit PoolFeeConfigChanged(value.fixedFeeRatio, value.atrFeeRatio, value.atrEmaBlocks);
    }

    function previewSwap(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        bool isLiquidation
    ) external view returns (uint256 oppositeAmount) {
        (uint256 maxAmount, ) = _doMaxSwap(isBaseToQuote, isExactInput, isLiquidation, 0);
        require(amount <= maxAmount, "PM_PS: too large amount");

        OrderBookLibrary.PreviewSwapResponse memory response =
            OrderBookLibrary.previewSwap(
                isBaseToQuote ? _orderBookInfo.bid : _orderBookInfo.ask,
                OrderBookLibrary.PreviewSwapParams({
                    isBaseToQuote: isBaseToQuote,
                    isExactInput: isExactInput,
                    amount: amount,
                    baseBalancePerShareX96: poolInfo.baseBalancePerShareX96
                }),
                _poolMaxSwap
            );

        oppositeAmount = PoolLibrary.previewSwap(
            poolInfo.base,
            poolInfo.quote,
            PoolLibrary.SwapParams({
                isBaseToQuote: isBaseToQuote,
                isExactInput: isExactInput,
                amount: response.amountPool,
                feeRatio: feeRatio()
            })
        );
        bool isOppositeBase = isBaseToQuote != isExactInput;
        if (isOppositeBase) {
            oppositeAmount += response.baseFull + response.basePartial;
        } else {
            oppositeAmount += response.quoteFull + response.quotePartial;
        }
    }

    function _poolMaxSwap(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 sharePriceX96
    ) private view returns (uint256) {
        return
            PoolLibrary.maxSwap(poolInfo.base, poolInfo.quote, isBaseToQuote, isExactInput, feeRatio(), sharePriceX96);
    }

    function maxSwap(
        bool isBaseToQuote,
        bool isExactInput,
        bool isLiquidation
    ) external view returns (uint256 amount) {
        (amount, ) = _doMaxSwap(isBaseToQuote, isExactInput, isLiquidation, 0);
    }

    function maxSwapByPrice(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 priceX96
    ) external view returns (uint256 amount) {
        uint256 sharePriceX96 = Math.mulDiv(priceX96, poolInfo.baseBalancePerShareX96, FixedPoint96.Q96);
        (amount, ) = _doMaxSwap(isBaseToQuote, isExactInput, false, sharePriceX96);
    }

    function getShareMarkPriceX96() public view returns (uint256) {
        if (poolInfo.base == 0) return 0;
        return PoolLibrary.getShareMarkPriceX96(poolInfo.base, poolInfo.quote);
    }

    function getLiquidityValue(uint256 liquidity) external view returns (uint256, uint256) {
        return PoolLibrary.getLiquidityValue(poolInfo, liquidity);
    }

    function getLiquidityDeleveraged(
        uint256 liquidity,
        uint256 cumBasePerLiquidityX96,
        uint256 cumQuotePerLiquidityX96
    ) external view returns (int256, int256) {
        return
            PoolLibrary.getLiquidityDeleveraged(
                poolInfo.cumBasePerLiquidityX96,
                poolInfo.cumQuotePerLiquidityX96,
                liquidity,
                cumBasePerLiquidityX96,
                cumQuotePerLiquidityX96
            );
    }

    function getCumDeleveragedPerLiquidityX96() external view returns (uint256, uint256) {
        return (poolInfo.cumBasePerLiquidityX96, poolInfo.cumQuotePerLiquidityX96);
    }

    function baseBalancePerShareX96() external view returns (uint256) {
        return poolInfo.baseBalancePerShareX96;
    }

    function getMarkPriceX96() public view returns (uint256) {
        if (poolInfo.base == 0) return 0;
        return PoolLibrary.getMarkPriceX96(poolInfo.base, poolInfo.quote, poolInfo.baseBalancePerShareX96);
    }

    function getAskPriceX96() public view returns (uint256 result) {
        result = PoolLibrary.getAskPriceX96(getMarkPriceX96(), feeRatio());
        uint256 obPrice = OrderBookLibrary.getBestPriceX96(_orderBookInfo.ask);
        if (obPrice != 0 && obPrice < result) {
            result = obPrice;
        }
    }

    function getBidPriceX96() public view returns (uint256 result) {
        result = PoolLibrary.getBidPriceX96(getMarkPriceX96(), feeRatio());
        uint256 obPrice = OrderBookLibrary.getBestPriceX96(_orderBookInfo.bid);
        if (obPrice != 0 && obPrice > result) {
            result = obPrice;
        }
    }

    function getLimitOrderInfo(bool isBid, uint40 orderId) external view returns (uint256 base, uint256 priceX96) {
        return OrderBookLibrary.getOrderInfo(_orderBookInfo, isBid, orderId);
    }

    function getLimitOrderExecution(bool isBid, uint40 orderId)
        external
        view
        returns (
            uint48 executionId,
            uint256 executedBase,
            uint256 executedQuote
        )
    {
        return OrderBookLibrary.getOrderExecution(_orderBookInfo, isBid, orderId);
    }

    function getCandles(
        uint32 interval,
        uint32 startTime,
        uint256 count
    ) external view returns (MarketStructs.Candle[] memory) {
        return CandleLibrary.getCandles(candleList, interval, startTime, count);
    }

    function _processFunding() internal {
        uint256 markPriceX96 = getMarkPriceX96();
        (int256 fundingRateX96, uint32 elapsedSec, int256 premiumX96) =
            FundingLibrary.processFunding(
                fundingInfo,
                FundingLibrary.ProcessFundingParams({
                    priceFeedBase: priceFeedBase,
                    priceFeedQuote: priceFeedQuote,
                    markPriceX96: markPriceX96,
                    maxPremiumRatio: fundingMaxPremiumRatio,
                    maxElapsedSec: fundingMaxElapsedSec,
                    rolloverSec: fundingRolloverSec
                })
            );
        if (fundingRateX96 == 0) return;

        PoolLibrary.applyFunding(poolInfo, fundingRateX96);
        emit FundingPaid(
            fundingRateX96,
            elapsedSec,
            premiumX96,
            markPriceX96,
            poolInfo.cumBasePerLiquidityX96,
            poolInfo.cumQuotePerLiquidityX96
        );
    }

    function _doMaxSwap(
        bool isBaseToQuote,
        bool isExactInput,
        bool isLiquidation,
        uint256 sharePriceX96
    ) private view returns (uint256 amount, MarketStructs.PriceLimitInfo memory updated) {
        if (poolInfo.totalLiquidity == 0) return (0, updated);

        if (sharePriceX96 == 0) {
            uint256 sharePriceBeforeX96 = getShareMarkPriceX96();
            updated = PriceLimitLibrary.updateDry(priceLimitInfo, priceLimitConfig, sharePriceBeforeX96);

            sharePriceX96 = PriceLimitLibrary.priceBound(
                updated.referencePrice,
                updated.emaPrice,
                priceLimitConfig,
                isLiquidation,
                !isBaseToQuote
            );
        }

        amount = PoolLibrary.maxSwap(
            poolInfo.base,
            poolInfo.quote,
            isBaseToQuote,
            isExactInput,
            feeRatio(),
            sharePriceX96
        );

        amount += OrderBookLibrary.maxSwap(
            isBaseToQuote ? _orderBookInfo.bid : _orderBookInfo.ask,
            isBaseToQuote,
            isExactInput,
            sharePriceX96,
            poolInfo.baseBalancePerShareX96
        );
    }

    function feeRatio() public view returns (uint24) {
        return
            Math
                .min(priceLimitConfig.normalOrderRatio / 2, PoolFeeLibrary.feeRatio(poolFeeInfo, poolFeeConfig))
                .toUint24();
    }

    // to reduce contract size
    function _onlyExchange() private view {
        require(exchange == msg.sender, "PM_OE: caller is not exchange");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
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
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
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
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
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
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
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
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
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
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
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
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
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
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
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
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
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
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { IPerpdexMarketMinimum } from "./IPerpdexMarketMinimum.sol";

interface IPerpdexMarket is IPerpdexMarketMinimum {
    event FundingPaid(
        int256 fundingRateX96,
        uint32 elapsedSec,
        int256 premiumX96,
        uint256 markPriceX96,
        uint256 cumBasePerLiquidityX96,
        uint256 cumQuotePerLiquidityX96
    );
    event LiquidityAdded(uint256 base, uint256 quote, uint256 liquidity);
    event LiquidityRemoved(uint256 base, uint256 quote, uint256 liquidity);
    event Swapped(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        uint256 oppositeAmount,
        uint40 fullLastOrderId,
        uint40 partialOrderId,
        uint256 basePartial,
        uint256 quotePartial
    );
    event LimitOrderCreated(bool isBid, uint256 base, uint256 priceX96, uint256 orderId);
    event LimitOrderCanceled(bool isBid, uint256 orderId);

    // getters

    function symbol() external view returns (string memory);

    function getMarkPriceX96() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import {
    BokkyPooBahsRedBlackTreeLibrary as RBTreeLibrary
} from "../../deps/BokkyPooBahsRedBlackTreeLibrary/contracts/BokkyPooBahsRedBlackTreeLibrary.sol";

library MarketStructs {
    struct FundingInfo {
        uint256 prevIndexPriceBase;
        uint256 prevIndexPriceQuote;
        uint256 prevIndexPriceTimestamp;
    }

    struct PoolInfo {
        uint256 base;
        uint256 quote;
        uint256 totalLiquidity;
        uint256 cumBasePerLiquidityX96;
        uint256 cumQuotePerLiquidityX96;
        uint256 baseBalancePerShareX96;
    }

    struct PriceLimitInfo {
        uint256 referencePrice;
        uint256 referenceTimestamp;
        uint256 emaPrice;
    }

    struct PriceLimitConfig {
        uint24 normalOrderRatio;
        uint24 liquidationRatio;
        uint24 emaNormalOrderRatio;
        uint24 emaLiquidationRatio;
        uint32 emaSec;
    }

    struct OrderInfo {
        uint256 base;
        uint256 baseSum;
        uint256 quoteSum;
        uint48 executionId;
    }

    struct OrderBookSideInfo {
        RBTreeLibrary.Tree tree;
        mapping(uint40 => OrderInfo) orderInfos;
        uint40 seqKey;
    }

    struct ExecutionInfo {
        uint256 baseBalancePerShareX96;
    }

    struct OrderBookInfo {
        OrderBookSideInfo ask;
        OrderBookSideInfo bid;
        uint48 seqExecutionId;
        mapping(uint48 => ExecutionInfo) executionInfos;
    }

    struct PoolFeeInfo {
        uint256 atrX96;
        uint256 referenceTimestamp;
        uint256 currentHighX96;
        uint256 currentLowX96;
    }

    struct PoolFeeConfig {
        uint24 fixedFeeRatio;
        uint24 atrFeeRatio;
        uint32 atrEmaBlocks;
    }

    struct Candle {
        uint128 closeX96;
        uint128 quote;
        uint128 highX96;
        uint128 lowX96;
    }

    struct CandleList {
        mapping(uint32 => mapping(uint32 => Candle)) candles;
        uint32 prevTimestamp;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import { PerpMath } from "./PerpMath.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { MarketStructs } from "./MarketStructs.sol";
import { IPerpdexPriceFeed } from "../interfaces/IPerpdexPriceFeed.sol";
import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

library FundingLibrary {
    using PerpMath for int256;
    using PerpMath for uint256;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    struct ProcessFundingParams {
        address priceFeedBase;
        address priceFeedQuote;
        uint256 markPriceX96;
        uint24 maxPremiumRatio;
        uint32 maxElapsedSec;
        uint32 rolloverSec;
    }

    uint8 public constant MAX_DECIMALS = 77; // 10^MAX_DECIMALS < 2^256

    function initializeFunding(MarketStructs.FundingInfo storage fundingInfo) external {
        fundingInfo.prevIndexPriceTimestamp = block.timestamp;
    }

    // must not revert even if priceFeed is malicious
    function processFunding(MarketStructs.FundingInfo storage fundingInfo, ProcessFundingParams memory params)
        external
        returns (
            int256 fundingRateX96,
            uint32 elapsedSec,
            int256 premiumX96
        )
    {
        uint256 currentTimestamp = block.timestamp;
        uint256 elapsedSec256 = currentTimestamp.sub(fundingInfo.prevIndexPriceTimestamp);
        if (elapsedSec256 == 0) return (0, 0, 0);

        uint256 indexPriceBase = _getIndexPriceSafe(params.priceFeedBase);
        uint256 indexPriceQuote = _getIndexPriceSafe(params.priceFeedQuote);
        uint8 decimalsBase = _getDecimalsSafe(params.priceFeedBase);
        uint8 decimalsQuote = _getDecimalsSafe(params.priceFeedQuote);
        if (
            (fundingInfo.prevIndexPriceBase == indexPriceBase && fundingInfo.prevIndexPriceQuote == indexPriceQuote) ||
            indexPriceBase == 0 ||
            indexPriceQuote == 0 ||
            decimalsBase > MAX_DECIMALS ||
            decimalsQuote > MAX_DECIMALS
        ) {
            return (0, 0, 0);
        }

        elapsedSec256 = Math.min(elapsedSec256, params.maxElapsedSec);
        elapsedSec = elapsedSec256.toUint32();

        premiumX96 = _calcPremiumX96(decimalsBase, decimalsQuote, indexPriceBase, indexPriceQuote, params.markPriceX96);

        int256 maxPremiumX96 = FixedPoint96.Q96.mulRatio(params.maxPremiumRatio).toInt256();
        premiumX96 = (-maxPremiumX96).max(maxPremiumX96.min(premiumX96));
        fundingRateX96 = premiumX96.mulDiv(elapsedSec256.toInt256(), params.rolloverSec);

        fundingInfo.prevIndexPriceBase = indexPriceBase;
        fundingInfo.prevIndexPriceQuote = indexPriceQuote;
        fundingInfo.prevIndexPriceTimestamp = currentTimestamp;
    }

    function validateInitialLiquidityPrice(
        address priceFeedBase,
        address priceFeedQuote,
        uint256 base,
        uint256 quote
    ) external view {
        uint256 indexPriceBase = _getIndexPriceSafe(priceFeedBase);
        uint256 indexPriceQuote = _getIndexPriceSafe(priceFeedQuote);
        require(indexPriceBase > 0, "FL_VILP: invalid base price");
        require(indexPriceQuote > 0, "FL_VILP: invalid quote price");
        uint8 decimalsBase = _getDecimalsSafe(priceFeedBase);
        uint8 decimalsQuote = _getDecimalsSafe(priceFeedQuote);
        require(decimalsBase <= MAX_DECIMALS, "FL_VILP: invalid base decimals");
        require(decimalsQuote <= MAX_DECIMALS, "FL_VILP: invalid quote decimals");

        uint256 markPriceX96 = Math.mulDiv(quote, FixedPoint96.Q96, base);
        int256 premiumX96 = _calcPremiumX96(decimalsBase, decimalsQuote, indexPriceBase, indexPriceQuote, markPriceX96);

        require(premiumX96.abs() <= FixedPoint96.Q96.mulRatio(1e5), "FL_VILP: too far from index");
    }

    function _getIndexPriceSafe(address priceFeed) private view returns (uint256) {
        if (priceFeed == address(0)) return 1; // indicate valid

        bytes memory payload = abi.encodeWithSignature("getPrice()");
        (bool success, bytes memory data) = address(priceFeed).staticcall(payload);
        if (!success) return 0; // invalid

        return abi.decode(data, (uint256));
    }

    function _getDecimalsSafe(address priceFeed) private view returns (uint8) {
        if (priceFeed == address(0)) return 0; // indicate valid

        bytes memory payload = abi.encodeWithSignature("decimals()");
        (bool success, bytes memory data) = address(priceFeed).staticcall(payload);
        if (!success) return 255; // invalid

        return abi.decode(data, (uint8));
    }

    // TODO: must not revert
    function _calcPremiumX96(
        uint8 decimalsBase,
        uint8 decimalsQuote,
        uint256 indexPriceBase,
        uint256 indexPriceQuote,
        uint256 markPriceX96
    ) private pure returns (int256 premiumX96) {
        uint256 priceRatioX96 = markPriceX96;

        if (decimalsBase != 0 || indexPriceBase != 1) {
            priceRatioX96 = Math.mulDiv(priceRatioX96, 10**decimalsBase, indexPriceBase);
        }
        if (decimalsQuote != 0 || indexPriceQuote != 1) {
            priceRatioX96 = Math.mulDiv(priceRatioX96, indexPriceQuote, 10**decimalsQuote);
        }

        premiumX96 = priceRatioX96.toInt256().sub(FixedPoint96.Q96.toInt256());
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import { PerpMath } from "./PerpMath.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { MarketStructs } from "./MarketStructs.sol";
import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

library PoolLibrary {
    using PerpMath for int256;
    using PerpMath for uint256;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    struct SwapParams {
        bool isBaseToQuote;
        bool isExactInput;
        uint24 feeRatio;
        uint256 amount;
    }

    struct AddLiquidityParams {
        uint256 base;
        uint256 quote;
    }

    struct RemoveLiquidityParams {
        uint256 liquidity;
    }

    uint256 public constant MINIMUM_LIQUIDITY = 1e3;

    function initializePool(MarketStructs.PoolInfo storage poolInfo) internal {
        poolInfo.baseBalancePerShareX96 = FixedPoint96.Q96;
    }

    // underestimate deleveraged tokens
    function applyFunding(MarketStructs.PoolInfo storage poolInfo, int256 fundingRateX96) internal {
        if (fundingRateX96 == 0) return;

        uint256 frAbs = fundingRateX96.abs();

        if (fundingRateX96 > 0) {
            uint256 poolQuote = poolInfo.quote;
            uint256 deleveratedQuote = Math.mulDiv(poolQuote, frAbs, FixedPoint96.Q96);
            poolInfo.quote = poolQuote.sub(deleveratedQuote);
            poolInfo.cumQuotePerLiquidityX96 = poolInfo.cumQuotePerLiquidityX96.add(
                Math.mulDiv(deleveratedQuote, FixedPoint96.Q96, poolInfo.totalLiquidity)
            );
        } else {
            uint256 poolBase = poolInfo.base;
            uint256 deleveratedBase = Math.mulDiv(poolBase, frAbs, FixedPoint96.Q96.add(frAbs));
            poolInfo.base = poolBase.sub(deleveratedBase);
            poolInfo.cumBasePerLiquidityX96 = poolInfo.cumBasePerLiquidityX96.add(
                Math.mulDiv(deleveratedBase, FixedPoint96.Q96, poolInfo.totalLiquidity)
            );
        }

        poolInfo.baseBalancePerShareX96 = Math.mulDiv(
            poolInfo.baseBalancePerShareX96,
            FixedPoint96.Q96.toInt256().sub(fundingRateX96).toUint256(),
            FixedPoint96.Q96
        );
    }

    function swap(MarketStructs.PoolInfo storage poolInfo, SwapParams memory params)
        internal
        returns (uint256 oppositeAmount)
    {
        oppositeAmount = previewSwap(poolInfo.base, poolInfo.quote, params);
        (poolInfo.base, poolInfo.quote) = calcPoolAfter(
            params.isBaseToQuote,
            params.isExactInput,
            poolInfo.base,
            poolInfo.quote,
            params.amount,
            oppositeAmount
        );
    }

    function calcPoolAfter(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 base,
        uint256 quote,
        uint256 amount,
        uint256 oppositeAmount
    ) internal pure returns (uint256 baseAfter, uint256 quoteAfter) {
        if (isExactInput) {
            if (isBaseToQuote) {
                baseAfter = base.add(amount);
                quoteAfter = quote.sub(oppositeAmount);
            } else {
                baseAfter = base.sub(oppositeAmount);
                quoteAfter = quote.add(amount);
            }
        } else {
            if (isBaseToQuote) {
                baseAfter = base.add(oppositeAmount);
                quoteAfter = quote.sub(amount);
            } else {
                baseAfter = base.sub(amount);
                quoteAfter = quote.add(oppositeAmount);
            }
        }
    }

    function addLiquidity(MarketStructs.PoolInfo storage poolInfo, AddLiquidityParams memory params)
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 poolTotalLiquidity = poolInfo.totalLiquidity;
        uint256 liquidity;

        if (poolTotalLiquidity == 0) {
            uint256 totalLiquidity = Math.sqrt(params.base.mul(params.quote));
            liquidity = totalLiquidity.sub(MINIMUM_LIQUIDITY);
            require(params.base > 0 && params.quote > 0 && liquidity > 0, "PL_AL: initial liquidity zero");

            poolInfo.base = params.base;
            poolInfo.quote = params.quote;
            poolInfo.totalLiquidity = totalLiquidity;
            return (params.base, params.quote, liquidity);
        }

        uint256 poolBase = poolInfo.base;
        uint256 poolQuote = poolInfo.quote;

        uint256 base = Math.min(params.base, Math.mulDiv(params.quote, poolBase, poolQuote));
        uint256 quote = Math.min(params.quote, Math.mulDiv(params.base, poolQuote, poolBase));
        liquidity = Math.min(
            Math.mulDiv(base, poolTotalLiquidity, poolBase),
            Math.mulDiv(quote, poolTotalLiquidity, poolQuote)
        );
        require(base > 0 && quote > 0 && liquidity > 0, "PL_AL: liquidity zero");

        poolInfo.base = poolBase.add(base);
        poolInfo.quote = poolQuote.add(quote);
        poolInfo.totalLiquidity = poolTotalLiquidity.add(liquidity);

        return (base, quote, liquidity);
    }

    function removeLiquidity(MarketStructs.PoolInfo storage poolInfo, RemoveLiquidityParams memory params)
        internal
        returns (uint256, uint256)
    {
        uint256 poolBase = poolInfo.base;
        uint256 poolQuote = poolInfo.quote;
        uint256 poolTotalLiquidity = poolInfo.totalLiquidity;
        uint256 base = Math.mulDiv(params.liquidity, poolBase, poolTotalLiquidity);
        uint256 quote = Math.mulDiv(params.liquidity, poolQuote, poolTotalLiquidity);
        require(base > 0 && quote > 0, "PL_RL: output is zero");
        poolInfo.base = poolBase.sub(base);
        poolInfo.quote = poolQuote.sub(quote);
        uint256 totalLiquidity = poolTotalLiquidity.sub(params.liquidity);
        require(totalLiquidity >= MINIMUM_LIQUIDITY, "PL_RL: min liquidity");
        poolInfo.totalLiquidity = totalLiquidity;
        return (base, quote);
    }

    function getLiquidityValue(MarketStructs.PoolInfo storage poolInfo, uint256 liquidity)
        internal
        view
        returns (uint256, uint256)
    {
        return (
            Math.mulDiv(liquidity, poolInfo.base, poolInfo.totalLiquidity),
            Math.mulDiv(liquidity, poolInfo.quote, poolInfo.totalLiquidity)
        );
    }

    // subtract fee from input before swap
    function previewSwap(
        uint256 base,
        uint256 quote,
        SwapParams memory params
    ) internal pure returns (uint256 output) {
        uint24 oneSubFeeRatio = PerpMath.subRatio(1e6, params.feeRatio);

        if (params.isExactInput) {
            uint256 amountSubFee = params.amount.mulRatio(oneSubFeeRatio);
            if (params.isBaseToQuote) {
                // output = quote.sub(FullMath.mulDivRoundingUp(base, quote, base.add(amountSubFee)));
                output = Math.mulDiv(quote, amountSubFee, base.add(amountSubFee));
            } else {
                // output = base.sub(FullMath.mulDivRoundingUp(base, quote, quote.add(amountSubFee)));
                output = Math.mulDiv(base, amountSubFee, quote.add(amountSubFee));
            }
        } else {
            if (params.isBaseToQuote) {
                // output = FullMath.mulDivRoundingUp(base, quote, quote.sub(params.amount)).sub(base);
                output = Math.mulDiv(base, params.amount, quote.sub(params.amount), Math.Rounding.Up);
            } else {
                // output = FullMath.mulDivRoundingUp(base, quote, base.sub(params.amount)).sub(quote);
                output = Math.mulDiv(quote, params.amount, base.sub(params.amount), Math.Rounding.Up);
            }
            output = output.divRatioRoundingUp(oneSubFeeRatio);
        }
    }

    function _solveQuadratic(uint256 b, uint256 cNeg) private pure returns (uint256) {
        return Math.sqrt(b.mul(b).add(cNeg.mul(4))).sub(b).div(2);
    }

    function getAskPriceX96(uint256 priceX96, uint24 feeRatio) internal pure returns (uint256) {
        uint24 oneSubFeeRatio = PerpMath.subRatio(1e6, feeRatio);
        return priceX96.divRatio(oneSubFeeRatio);
    }

    function getBidPriceX96(uint256 priceX96, uint24 feeRatio) internal pure returns (uint256) {
        uint24 oneSubFeeRatio = PerpMath.subRatio(1e6, feeRatio);
        return priceX96.mulRatioRoundingUp(oneSubFeeRatio);
    }

    // must not revert
    // Trade until the trade price including fee (dy/dx) reaches priceBoundX96
    // not pool price (y/x)
    // long: trade_price = pool_price / (1 - fee)
    // short: trade_price = pool_price * (1 - fee)
    function maxSwap(
        uint256 base,
        uint256 quote,
        bool isBaseToQuote,
        bool isExactInput,
        uint24 feeRatio,
        uint256 priceBoundX96
    ) internal pure returns (uint256 output) {
        uint24 oneSubFeeRatio = PerpMath.subRatio(1e6, feeRatio);
        uint256 k = base.mul(quote);

        if (isBaseToQuote) {
            uint256 kDivP = Math.mulDiv(k, FixedPoint96.Q96, priceBoundX96).mulRatio(oneSubFeeRatio);
            uint256 baseSqr = base.mul(base);
            if (kDivP <= baseSqr) return 0;
            uint256 cNeg = kDivP.sub(baseSqr);
            uint256 b = base.add(base.mulRatio(oneSubFeeRatio));
            output = _solveQuadratic(b.divRatio(oneSubFeeRatio), cNeg.divRatio(oneSubFeeRatio));
        } else {
            // https://www.wolframalpha.com/input?i=%28x+%2B+a%29+*+%28x+%2B+a+*+%281+-+f%29%29+%3D+kp+solve+a
            uint256 kp = Math.mulDiv(k, priceBoundX96, FixedPoint96.Q96).mulRatio(oneSubFeeRatio);
            uint256 quoteSqr = quote.mul(quote);
            if (kp <= quoteSqr) return 0;
            uint256 cNeg = kp.sub(quoteSqr);
            uint256 b = quote.add(quote.mulRatio(oneSubFeeRatio));
            output = _solveQuadratic(b.divRatio(oneSubFeeRatio), cNeg.divRatio(oneSubFeeRatio));
        }
        if (!isExactInput) {
            output = previewSwap(
                base,
                quote,
                SwapParams({ isBaseToQuote: isBaseToQuote, isExactInput: true, feeRatio: feeRatio, amount: output })
            );
        }
    }

    function getMarkPriceX96(
        uint256 base,
        uint256 quote,
        uint256 baseBalancePerShareX96
    ) internal pure returns (uint256) {
        return Math.mulDiv(getShareMarkPriceX96(base, quote), FixedPoint96.Q96, baseBalancePerShareX96);
    }

    function getShareMarkPriceX96(uint256 base, uint256 quote) internal pure returns (uint256) {
        return Math.mulDiv(quote, FixedPoint96.Q96, base);
    }

    function getLiquidityDeleveraged(
        uint256 poolCumBasePerLiquidityX96,
        uint256 poolCumQuotePerLiquidityX96,
        uint256 liquidity,
        uint256 cumBasePerLiquidityX96,
        uint256 cumQuotePerLiquidityX96
    ) internal pure returns (int256, int256) {
        int256 basePerLiquidityX96 = poolCumBasePerLiquidityX96.toInt256().sub(cumBasePerLiquidityX96.toInt256());
        int256 quotePerLiquidityX96 = poolCumQuotePerLiquidityX96.toInt256().sub(cumQuotePerLiquidityX96.toInt256());

        return (
            liquidity.toInt256().mulDiv(basePerLiquidityX96, FixedPoint96.Q96),
            liquidity.toInt256().mulDiv(quotePerLiquidityX96, FixedPoint96.Q96)
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { PerpMath } from "./PerpMath.sol";
import { MarketStructs } from "./MarketStructs.sol";

library PriceLimitLibrary {
    using PerpMath for uint256;
    using SafeMath for uint256;

    function update(MarketStructs.PriceLimitInfo storage priceLimitInfo, MarketStructs.PriceLimitInfo memory value)
        internal
    {
        if (value.referenceTimestamp == 0) return;
        priceLimitInfo.referencePrice = value.referencePrice;
        priceLimitInfo.referenceTimestamp = value.referenceTimestamp;
        priceLimitInfo.emaPrice = value.emaPrice;
    }

    // referenceTimestamp == 0 indicates not updated
    function updateDry(
        MarketStructs.PriceLimitInfo storage priceLimitInfo,
        MarketStructs.PriceLimitConfig storage config,
        uint256 price
    ) internal view returns (MarketStructs.PriceLimitInfo memory updated) {
        uint256 currentTimestamp = block.timestamp;
        uint256 refTimestamp = priceLimitInfo.referenceTimestamp;
        if (currentTimestamp <= refTimestamp) {
            updated.referencePrice = priceLimitInfo.referencePrice;
            updated.emaPrice = priceLimitInfo.emaPrice;
            return updated;
        }

        uint256 elapsed = currentTimestamp.sub(refTimestamp);

        if (priceLimitInfo.referencePrice == 0) {
            updated.emaPrice = price;
        } else {
            uint32 emaSec = config.emaSec;
            uint256 denominator = elapsed.add(emaSec);
            updated.emaPrice = Math.mulDiv(priceLimitInfo.emaPrice, emaSec, denominator).add(
                Math.mulDiv(price, elapsed, denominator)
            );
        }

        updated.referencePrice = price;
        updated.referenceTimestamp = currentTimestamp;
    }

    function priceBound(
        uint256 referencePrice,
        uint256 emaPrice,
        MarketStructs.PriceLimitConfig storage config,
        bool isLiquidation,
        bool isUpperBound
    ) internal view returns (uint256 price) {
        uint256 referenceRange =
            referencePrice.mulRatio(isLiquidation ? config.liquidationRatio : config.normalOrderRatio);
        uint256 emaRange = emaPrice.mulRatio(isLiquidation ? config.emaLiquidationRatio : config.emaNormalOrderRatio);

        if (isUpperBound) {
            return Math.min(referencePrice.add(referenceRange), emaPrice.add(emaRange));
        } else {
            return Math.max(referencePrice.sub(referenceRange), emaPrice.sub(emaRange));
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import { PerpMath } from "./PerpMath.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { MarketStructs } from "./MarketStructs.sol";
import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import {
    BokkyPooBahsRedBlackTreeLibrary as RBTreeLibrary
} from "../../deps/BokkyPooBahsRedBlackTreeLibrary/contracts/BokkyPooBahsRedBlackTreeLibrary.sol";

library OrderBookLibrary {
    using PerpMath for int256;
    using PerpMath for uint256;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using RBTreeLibrary for RBTreeLibrary.Tree;

    struct SwapResponse {
        uint256 oppositeAmount;
        uint256 basePartial;
        uint256 quotePartial;
        uint40 partialKey;
        uint40 fullLastKey;
    }

    // to avoid stack too deep
    struct PreviewSwapParams {
        bool isBaseToQuote;
        bool isExactInput;
        uint256 amount;
        uint256 baseBalancePerShareX96;
    }

    // to avoid stack too deep
    struct PreviewSwapLocalVars {
        uint128 priceX96;
        uint256 sharePriceX96;
        uint256 amountPool;
        uint40 left;
        uint40 right;
        uint256 leftBaseSum;
        uint256 leftQuoteSum;
        uint256 rightBaseSum;
        uint256 rightQuoteSum;
    }

    struct PreviewSwapResponse {
        uint256 amountPool;
        uint256 baseFull;
        uint256 quoteFull;
        uint256 basePartial;
        uint256 quotePartial;
        uint40 fullLastKey;
        uint40 partialKey;
    }

    function createOrder(
        MarketStructs.OrderBookInfo storage orderBookInfo,
        bool isBid,
        uint256 base,
        uint256 priceX96,
        uint256 markPriceX96
    ) public returns (uint40) {
        require(base > 0, "OBL_CO: base is zero");
        require(priceX96 >= markPriceX96 / 100, "OBL_CO: price too small");
        require(priceX96 <= markPriceX96 * 100, "OBL_CO: price too large");
        MarketStructs.OrderBookSideInfo storage info = isBid ? orderBookInfo.bid : orderBookInfo.ask;
        uint40 key = info.seqKey + 1;
        info.seqKey = key;
        info.orderInfos[key].base = base; // before insert for aggregation
        uint128 userData = _makeUserData(priceX96);
        uint256 slot = _getSlot(orderBookInfo);
        if (isBid) {
            info.tree.insert(key, userData, _lessThanBid, _aggregateBid, slot);
        } else {
            info.tree.insert(key, userData, _lessThanAsk, _aggregateAsk, slot);
        }
        return key;
    }

    function cancelOrder(
        MarketStructs.OrderBookInfo storage orderBookInfo,
        bool isBid,
        uint40 key
    ) public {
        MarketStructs.OrderBookSideInfo storage info = isBid ? orderBookInfo.bid : orderBookInfo.ask;
        require(_isFullyExecuted(info, key) == 0, "OBL_CO: already fully executed");
        uint256 slot = _getSlot(orderBookInfo);
        if (isBid) {
            info.tree.remove(key, _aggregateBid, slot);
        } else {
            info.tree.remove(key, _aggregateAsk, slot);
        }
        delete info.orderInfos[key];
    }

    function getOrderInfo(
        MarketStructs.OrderBookInfo storage orderBookInfo,
        bool isBid,
        uint40 key
    ) public view returns (uint256 base, uint256 priceX96) {
        MarketStructs.OrderBookSideInfo storage info = isBid ? orderBookInfo.bid : orderBookInfo.ask;
        base = info.orderInfos[key].base;
        priceX96 = _userDataToPriceX96(info.tree.nodes[key].userData);
    }

    function getOrderExecution(
        MarketStructs.OrderBookInfo storage orderBookInfo,
        bool isBid,
        uint40 key
    )
        public
        view
        returns (
            uint48 executionId,
            uint256 executedBase,
            uint256 executedQuote
        )
    {
        MarketStructs.OrderBookSideInfo storage info = isBid ? orderBookInfo.bid : orderBookInfo.ask;
        executionId = _isFullyExecuted(info, key);
        if (executionId == 0) return (0, 0, 0);

        executedBase = info.orderInfos[key].base;
        // rounding error occurs, but it is negligible.

        executedQuote = _quoteToBalance(
            _getQuote(info, key),
            orderBookInfo.executionInfos[executionId].baseBalancePerShareX96
        );
    }

    function getBestPriceX96(MarketStructs.OrderBookSideInfo storage info) external view returns (uint256) {
        if (info.tree.root == 0) return 0;
        uint40 key = info.tree.first();
        return _userDataToPriceX96(info.tree.nodes[key].userData);
    }

    function swap(
        MarketStructs.OrderBookInfo storage orderBookInfo,
        PreviewSwapParams memory params,
        function(bool, bool, uint256) view returns (uint256) maxSwapArg,
        function(bool, bool, uint256) returns (uint256) swapArg
    ) internal returns (SwapResponse memory swapResponse) {
        MarketStructs.OrderBookSideInfo storage info = params.isBaseToQuote ? orderBookInfo.bid : orderBookInfo.ask;
        PreviewSwapResponse memory response = previewSwap(info, params, maxSwapArg);

        if (response.amountPool > 0) {
            swapResponse.oppositeAmount += swapArg(params.isBaseToQuote, params.isExactInput, response.amountPool);
        }

        bool isBase = params.isBaseToQuote == params.isExactInput;
        uint256 slot = _getSlot(orderBookInfo);

        if (response.fullLastKey != 0) {
            orderBookInfo.seqExecutionId += 1;
            orderBookInfo.executionInfos[orderBookInfo.seqExecutionId] = MarketStructs.ExecutionInfo({
                baseBalancePerShareX96: params.baseBalancePerShareX96
            });
            if (params.isBaseToQuote) {
                info.tree.removeLeft(response.fullLastKey, _lessThanBid, _aggregateBid, _subtreeRemovedBid, slot);
            } else {
                info.tree.removeLeft(response.fullLastKey, _lessThanAsk, _aggregateAsk, _subtreeRemovedAsk, slot);
            }

            swapResponse.oppositeAmount += isBase ? response.quoteFull : response.baseFull;
            swapResponse.fullLastKey = response.fullLastKey;
        } else {
            require(response.baseFull == 0, "never occur");
            require(response.quoteFull == 0, "never occur");
        }

        if (response.partialKey != 0) {
            info.orderInfos[response.partialKey].base -= response.basePartial;
            require(info.orderInfos[response.partialKey].base > 0, "never occur");

            info.tree.aggregateRecursively(
                response.partialKey,
                params.isBaseToQuote ? _aggregateBid : _aggregateAsk,
                slot
            );

            swapResponse.oppositeAmount += isBase ? response.quotePartial : response.basePartial;
            swapResponse.basePartial = response.basePartial;
            swapResponse.quotePartial = response.quotePartial;
            swapResponse.partialKey = response.partialKey;
        } else {
            require(response.basePartial == 0, "never occur");
            require(response.quotePartial == 0, "never occur");
        }
    }

    function previewSwap(
        MarketStructs.OrderBookSideInfo storage info,
        PreviewSwapParams memory params,
        function(bool, bool, uint256) view returns (uint256) maxSwapArg
    ) internal view returns (PreviewSwapResponse memory response) {
        bool isBase = params.isBaseToQuote == params.isExactInput;
        uint40 key = info.tree.root;
        uint256 baseSum;
        uint256 quoteSum;

        while (key != 0) {
            PreviewSwapLocalVars memory vars;
            vars.priceX96 = _userDataToPriceX96(info.tree.nodes[key].userData);
            vars.sharePriceX96 = Math.mulDiv(vars.priceX96, params.baseBalancePerShareX96, FixedPoint96.Q96);
            vars.amountPool = maxSwapArg(params.isBaseToQuote, params.isExactInput, vars.sharePriceX96);

            // key - right is more gas efficient than left + key
            vars.left = info.tree.nodes[key].left;
            vars.right = info.tree.nodes[key].right;
            vars.leftBaseSum = baseSum + info.orderInfos[vars.left].baseSum;
            vars.leftQuoteSum = quoteSum + info.orderInfos[vars.left].quoteSum;

            uint256 rangeLeft =
                (isBase ? vars.leftBaseSum : _quoteToBalance(vars.leftQuoteSum, params.baseBalancePerShareX96)) +
                    vars.amountPool;
            if (params.amount <= rangeLeft) {
                if (vars.left == 0) {
                    response.fullLastKey = info.tree.prev(key);
                }
                key = vars.left;
                continue;
            }

            vars.rightBaseSum = baseSum + (info.orderInfos[key].baseSum - info.orderInfos[vars.right].baseSum);
            vars.rightQuoteSum = quoteSum + (info.orderInfos[key].quoteSum - info.orderInfos[vars.right].quoteSum);

            uint256 rangeRight =
                (isBase ? vars.rightBaseSum : _quoteToBalance(vars.rightQuoteSum, params.baseBalancePerShareX96)) +
                    vars.amountPool;
            if (params.amount < rangeRight) {
                response.amountPool = vars.amountPool;
                response.baseFull = vars.leftBaseSum;
                response.quoteFull = _quoteToBalance(vars.leftQuoteSum, params.baseBalancePerShareX96);
                if (isBase) {
                    response.basePartial = params.amount - rangeLeft; // < info.orderInfos[key].base
                    response.quotePartial = Math.mulDiv(response.basePartial, vars.sharePriceX96, FixedPoint96.Q96);
                } else {
                    response.quotePartial = params.amount - rangeLeft;
                    response.basePartial = Math.mulDiv(response.quotePartial, FixedPoint96.Q96, vars.sharePriceX96);
                    // round to fit order size
                    response.basePartial = Math.min(response.basePartial, info.orderInfos[key].base - 1);
                }
                response.fullLastKey = info.tree.prev(key);
                response.partialKey = key;
                return response;
            }

            {
                baseSum = vars.rightBaseSum;
                quoteSum = vars.rightQuoteSum;
                if (vars.right == 0) {
                    response.fullLastKey = key;
                }
                key = vars.right;
            }
        }

        response.baseFull = baseSum;
        response.quoteFull = _quoteToBalance(quoteSum, params.baseBalancePerShareX96);
        response.amountPool = params.amount - (isBase ? response.baseFull : response.quoteFull);
    }

    function maxSwap(
        MarketStructs.OrderBookSideInfo storage info,
        bool isBaseToQuote,
        bool isExactInput,
        uint256 sharePriceBoundX96,
        uint256 baseBalancePerShareX96
    ) public view returns (uint256 amount) {
        uint256 priceBoundX96 = Math.mulDiv(sharePriceBoundX96, FixedPoint96.Q96, baseBalancePerShareX96);
        bool isBid = isBaseToQuote;
        bool isBase = isBaseToQuote == isExactInput;
        uint40 key = info.tree.root;

        while (key != 0) {
            uint128 price = _userDataToPriceX96(info.tree.nodes[key].userData);
            uint40 left = info.tree.nodes[key].left;
            if (isBid ? price >= priceBoundX96 : price <= priceBoundX96) {
                // key - right is more gas efficient than left + key
                uint40 right = info.tree.nodes[key].right;
                amount += isBase
                    ? info.orderInfos[key].baseSum - info.orderInfos[right].baseSum
                    : info.orderInfos[key].quoteSum - info.orderInfos[right].quoteSum;
                key = right;
            } else {
                key = left;
            }
        }

        if (!isBase) {
            amount = _quoteToBalance(amount, baseBalancePerShareX96);
        }
    }

    function _isFullyExecuted(MarketStructs.OrderBookSideInfo storage info, uint40 key) private view returns (uint48) {
        uint40 root = info.tree.root;
        while (key != 0 && key != root) {
            if (info.orderInfos[key].executionId != 0) {
                return info.orderInfos[key].executionId;
            }
            key = info.tree.nodes[key].parent;
        }
        return 0;
    }

    function _makeUserData(uint256 priceX96) private pure returns (uint128) {
        return priceX96.toUint128();
    }

    function _userDataToPriceX96(uint128 userData) private pure returns (uint128) {
        return userData;
    }

    function _lessThan(
        RBTreeLibrary.Tree storage tree,
        bool isBid,
        uint40 key0,
        uint40 key1
    ) private view returns (bool) {
        uint128 price0 = _userDataToPriceX96(tree.nodes[key0].userData);
        uint128 price1 = _userDataToPriceX96(tree.nodes[key1].userData);
        if (price0 == price1) {
            return key0 < key1; // time priority
        }
        // price priority
        return isBid ? price0 > price1 : price0 < price1;
    }

    function _lessThanAsk(
        uint40 key0,
        uint40 key1,
        uint256 slot
    ) private view returns (bool) {
        MarketStructs.OrderBookInfo storage info = _getOrderBookInfoFromSlot(slot);
        return _lessThan(info.ask.tree, false, key0, key1);
    }

    function _lessThanBid(
        uint40 key0,
        uint40 key1,
        uint256 slot
    ) private view returns (bool) {
        MarketStructs.OrderBookInfo storage info = _getOrderBookInfoFromSlot(slot);
        return _lessThan(info.bid.tree, true, key0, key1);
    }

    function _aggregate(MarketStructs.OrderBookSideInfo storage info, uint40 key) private returns (bool stop) {
        uint256 prevBaseSum = info.orderInfos[key].baseSum;
        uint256 prevQuoteSum = info.orderInfos[key].quoteSum;
        uint40 left = info.tree.nodes[key].left;
        uint40 right = info.tree.nodes[key].right;

        uint256 baseSum = info.orderInfos[left].baseSum + info.orderInfos[right].baseSum + info.orderInfos[key].base;
        uint256 quoteSum = info.orderInfos[left].quoteSum + info.orderInfos[right].quoteSum + _getQuote(info, key);

        stop = baseSum == prevBaseSum && quoteSum == prevQuoteSum;
        if (!stop) {
            info.orderInfos[key].baseSum = baseSum;
            info.orderInfos[key].quoteSum = quoteSum;
        }
    }

    function _aggregateAsk(uint40 key, uint256 slot) private returns (bool stop) {
        MarketStructs.OrderBookInfo storage info = _getOrderBookInfoFromSlot(slot);
        return _aggregate(info.ask, key);
    }

    function _aggregateBid(uint40 key, uint256 slot) private returns (bool stop) {
        MarketStructs.OrderBookInfo storage info = _getOrderBookInfoFromSlot(slot);
        return _aggregate(info.bid, key);
    }

    function _subtreeRemoved(
        MarketStructs.OrderBookSideInfo storage info,
        MarketStructs.OrderBookInfo storage orderBookInfo,
        uint40 key
    ) private {
        info.orderInfos[key].executionId = orderBookInfo.seqExecutionId;
    }

    function _subtreeRemovedAsk(uint40 key, uint256 slot) private {
        MarketStructs.OrderBookInfo storage info = _getOrderBookInfoFromSlot(slot);
        return _subtreeRemoved(info.ask, info, key);
    }

    function _subtreeRemovedBid(uint40 key, uint256 slot) private {
        MarketStructs.OrderBookInfo storage info = _getOrderBookInfoFromSlot(slot);
        return _subtreeRemoved(info.bid, info, key);
    }

    // returns quoteBalance / baseBalancePerShare
    function _getQuote(MarketStructs.OrderBookSideInfo storage info, uint40 key) private view returns (uint256) {
        uint128 priceX96 = _userDataToPriceX96(info.tree.nodes[key].userData);
        return Math.mulDiv(info.orderInfos[key].base, priceX96, FixedPoint96.Q96);
    }

    function _quoteToBalance(uint256 quote, uint256 baseBalancePerShareX96) private pure returns (uint256) {
        return Math.mulDiv(quote, baseBalancePerShareX96, FixedPoint96.Q96);
    }

    function _getSlot(MarketStructs.OrderBookInfo storage d) private pure returns (uint256 slot) {
        assembly {
            slot := d.slot
        }
    }

    function _getOrderBookInfoFromSlot(uint256 slot) private pure returns (MarketStructs.OrderBookInfo storage d) {
        assembly {
            d.slot := slot
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { PerpMath } from "./PerpMath.sol";
import { MarketStructs } from "./MarketStructs.sol";

library PoolFeeLibrary {
    using PerpMath for uint256;
    using SafeCast for uint256;
    using SafeMath for uint256;

    function update(
        MarketStructs.PoolFeeInfo storage poolFeeInfo,
        uint32 atrEmaBlocks,
        uint256 prevPriceX96,
        uint256 currentPriceX96
    ) internal {
        uint256 currentTimestamp = block.timestamp;

        if (currentTimestamp <= poolFeeInfo.referenceTimestamp) {
            poolFeeInfo.currentHighX96 = Math.max(poolFeeInfo.currentHighX96, currentPriceX96);
            poolFeeInfo.currentLowX96 = Math.min(poolFeeInfo.currentLowX96, currentPriceX96);
        } else {
            poolFeeInfo.referenceTimestamp = currentTimestamp;
            poolFeeInfo.atrX96 = _calculateAtrX96(poolFeeInfo, atrEmaBlocks);
            poolFeeInfo.currentHighX96 = Math.max(prevPriceX96, currentPriceX96);
            poolFeeInfo.currentLowX96 = Math.min(prevPriceX96, currentPriceX96);
        }
    }

    function feeRatio(MarketStructs.PoolFeeInfo storage poolFeeInfo, MarketStructs.PoolFeeConfig memory config)
        internal
        view
        returns (uint256)
    {
        uint256 atrX96 = _calculateAtrX96(poolFeeInfo, config.atrEmaBlocks);
        return Math.mulDiv(config.atrFeeRatio, atrX96, FixedPoint96.Q96).add(config.fixedFeeRatio);
    }

    function _calculateAtrX96(MarketStructs.PoolFeeInfo storage poolFeeInfo, uint32 atrEmaBlocks)
        private
        view
        returns (uint256)
    {
        if (poolFeeInfo.currentLowX96 == 0) return 0;
        uint256 trX96 =
            Math.mulDiv(poolFeeInfo.currentHighX96, FixedPoint96.Q96, poolFeeInfo.currentLowX96).sub(FixedPoint96.Q96);
        uint256 denominator = atrEmaBlocks + 1;
        return Math.mulDiv(poolFeeInfo.atrX96, atrEmaBlocks, denominator).add(trX96.div(denominator));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { MarketStructs } from "./MarketStructs.sol";

library CandleLibrary {
    using SafeCast for uint256;

    uint32 public constant INTERVAL0 = 1 minutes;
    uint32 public constant INTERVAL1 = 5 minutes;
    uint32 public constant INTERVAL2 = 1 hours;
    uint32 public constant INTERVAL3 = 4 hours;
    uint32 public constant INTERVAL4 = 24 hours;

    function update(
        MarketStructs.CandleList storage list,
        uint32 timestamp,
        uint256 priceX96,
        uint256 quote
    ) external {
        uint32 prevTimestamp = list.prevTimestamp;
        list.prevTimestamp = timestamp;

        MarketStructs.Candle storage currentCandle0 = list.candles[INTERVAL0][timestamp / INTERVAL0];
        _updateLowestCandle(currentCandle0, priceX96, quote);

        (MarketStructs.Candle storage candleLow, bool finalized) =
            _getCandle(list, INTERVAL0, prevTimestamp, timestamp);
        if (!finalized) return;

        MarketStructs.Candle storage candle;
        uint32[4] memory intervals = [INTERVAL1, INTERVAL2, INTERVAL3, INTERVAL4];
        for (uint256 i = 0; i < intervals.length; ++i) {
            (candle, finalized) = _getCandle(list, intervals[i], prevTimestamp, timestamp);
            _updateCandle(candle, candleLow);
            if (!finalized) return;
            candleLow = candle;
        }
    }

    function getCandles(
        MarketStructs.CandleList storage list,
        uint32 interval,
        uint32 startTime,
        uint256 count
    ) external view returns (MarketStructs.Candle[] memory result) {
        result = new MarketStructs.Candle[](count);
        uint256 startIdx = startTime / interval;
        uint32 prevTimestamp = list.prevTimestamp;
        uint32 partialIdx = list.prevTimestamp / interval;
        for (uint256 i = 0; i < count; ++i) {
            uint32 idx = (startIdx + i).toUint32();
            if (idx == partialIdx) {
                result[i] = list.candles[INTERVAL0][prevTimestamp / INTERVAL0];
                uint32 interval2 = _getHighInterval(INTERVAL0);
                while (interval2 <= interval) {
                    MarketStructs.Candle storage candle = list.candles[interval2][prevTimestamp / interval2];
                    if (result[i].closeX96 == 0) {
                        result[i].closeX96 = candle.closeX96;
                    }
                    result[i].quote += candle.quote;
                    result[i].highX96 = Math.max(result[i].highX96, candle.highX96).toUint128();
                    result[i].lowX96 = _smartMin(result[i].lowX96, candle.lowX96).toUint128();
                    interval2 = _getHighInterval(interval2);
                }
            } else {
                result[i] = list.candles[interval][idx];
            }
        }
    }

    function _updateLowestCandle(
        MarketStructs.Candle storage candle,
        uint256 priceX96,
        uint256 quote
    ) private {
        candle.closeX96 = priceX96.toUint128();
        candle.quote += quote.toUint128();
        candle.highX96 = Math.max(candle.highX96, priceX96).toUint128();
        candle.lowX96 = _smartMin(candle.lowX96, priceX96).toUint128();
    }

    function _updateCandle(MarketStructs.Candle storage candle, MarketStructs.Candle storage candleLow) private {
        candle.closeX96 = candleLow.closeX96;
        candle.quote += candleLow.quote;
        candle.highX96 = Math.max(candle.highX96, candleLow.highX96).toUint128();
        candle.lowX96 = _smartMin(candle.lowX96, candleLow.lowX96).toUint128();
    }

    function _getCandle(
        MarketStructs.CandleList storage list,
        uint32 interval,
        uint32 prevTimestamp,
        uint256 timestamp
    ) private view returns (MarketStructs.Candle storage candle, bool finalized) {
        uint32 idx = prevTimestamp / interval;
        finalized = idx != timestamp / interval;
        candle = list.candles[interval][idx];
    }

    function _getHighInterval(uint32 interval) private pure returns (uint32) {
        if (interval == INTERVAL0) {
            return INTERVAL1;
        } else if (interval == INTERVAL1) {
            return INTERVAL2;
        } else if (interval == INTERVAL2) {
            return INTERVAL3;
        } else if (interval == INTERVAL3) {
            return INTERVAL4;
        }
        return type(uint32).max;
    }

    function _smartMin(uint256 a, uint256 b) private pure returns (uint256) {
        if (a == 0) {
            return b;
        } else if (b == 0) {
            return a;
        } else {
            return Math.min(a, b);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

interface IPerpdexMarketMinimum {
    struct SwapResponse {
        uint256 oppositeAmount;
        uint256 basePartial;
        uint256 quotePartial;
        uint40 partialOrderId;
    }

    function swap(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        bool isLiquidation
    ) external returns (SwapResponse memory response);

    function addLiquidity(uint256 baseShare, uint256 quoteBalance)
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function removeLiquidity(uint256 liquidity) external returns (uint256 baseShare, uint256 quoteBalance);

    function createLimitOrder(
        bool isBid,
        uint256 baseShare,
        uint256 priceX96,
        bool ignorePostOnlyCheck
    ) external returns (uint40 orderId);

    function cancelLimitOrder(bool isBid, uint40 orderId) external;

    // getters

    function previewSwap(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        bool isLiquidation
    ) external view returns (uint256);

    function maxSwap(
        bool isBaseToQuote,
        bool isExactInput,
        bool isLiquidation
    ) external view returns (uint256 amount);

    function maxSwapByPrice(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 priceX96
    ) external view returns (uint256 amount);

    function exchange() external view returns (address);

    function getShareMarkPriceX96() external view returns (uint256);

    function getLiquidityValue(uint256 liquidity) external view returns (uint256 baseShare, uint256 quoteBalance);

    function getLiquidityDeleveraged(
        uint256 liquidity,
        uint256 cumBasePerLiquidityX96,
        uint256 cumQuotePerLiquidityX96
    ) external view returns (int256, int256);

    function getCumDeleveragedPerLiquidityX96() external view returns (uint256, uint256);

    function baseBalancePerShareX96() external view returns (uint256);

    function getLimitOrderInfo(bool isBid, uint40 orderId) external view returns (uint256 base, uint256 priceX96);

    function getLimitOrderExecution(bool isBid, uint40 orderId)
        external
        view
        returns (
            uint48 executionId,
            uint256 executedBase,
            uint256 executedQuote
        );
}

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's Red-Black Tree Library v1.0-pre-release-a
//
// A Solidity Red-Black Tree binary search library to store and access a sorted
// list of unsigned integer data. The Red-Black algorithm rebalances the binary
// search tree, resulting in O(log n) insert, remove and search time (and ~gas)
//
// https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2020. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsRedBlackTreeLibrary {
    struct Node {
        uint40 parent;
        uint40 left;
        uint40 right;
        bool red;
        uint128 userData; // use freely. this is for gas efficiency
    }

    struct Tree {
        uint40 root;
        mapping(uint40 => Node) nodes;
    }

    uint40 private constant EMPTY = 0;

    function first(Tree storage self) internal view returns (uint40 _key) {
        _key = self.root;
        if (_key != EMPTY) {
            _key = treeMinimum(self, self.root);
        }
    }

    function last(Tree storage self) internal view returns (uint40 _key) {
        _key = self.root;
        if (_key != EMPTY) {
            _key = treeMaximum(self, self.root);
        }
    }

    function next(Tree storage self, uint40 target)
        internal
        view
        returns (uint40 cursor)
    {
        require(target != EMPTY, "RBTL_N: target is empty");
        if (self.nodes[target].right != EMPTY) {
            cursor = treeMinimum(self, self.nodes[target].right);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].right) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }

    function prev(Tree storage self, uint40 target)
        internal
        view
        returns (uint40 cursor)
    {
        require(target != EMPTY, "RBTL_P: target is empty");
        if (self.nodes[target].left != EMPTY) {
            cursor = treeMaximum(self, self.nodes[target].left);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].left) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }

    function exists(Tree storage self, uint40 key)
        internal
        view
        returns (bool)
    {
        return
            (key != EMPTY) &&
            ((key == self.root) || (self.nodes[key].parent != EMPTY));
    }

    function isEmpty(uint40 key) internal pure returns (bool) {
        return key == EMPTY;
    }

    function getEmpty() internal pure returns (uint256) {
        return EMPTY;
    }

    function getNode(Tree storage self, uint40 key)
        internal
        view
        returns (
            uint40 _returnKey,
            uint40 _parent,
            uint40 _left,
            uint40 _right,
            bool _red
        )
    {
        require(exists(self, key), "RBTL_GN: key not exist");
        return (
            key,
            self.nodes[key].parent,
            self.nodes[key].left,
            self.nodes[key].right,
            self.nodes[key].red
        );
    }

    function insert(
        Tree storage self,
        uint40 key,
        uint128 userData,
        function(uint40, uint40, uint256) view returns (bool) lessThan,
        function(uint40, uint256) returns (bool) aggregate,
        uint256 data
    ) internal {
        require(key != EMPTY, "RBTL_I: key is empty");
        require(!exists(self, key), "RBTL_I: key already exists");
        uint40 cursor = EMPTY;
        uint40 probe = self.root;
        self.nodes[key] = Node({
            parent: EMPTY,
            left: EMPTY,
            right: EMPTY,
            red: true,
            userData: userData
        });
        while (probe != EMPTY) {
            cursor = probe;
            if (lessThan(key, probe, data)) {
                probe = self.nodes[probe].left;
            } else {
                probe = self.nodes[probe].right;
            }
        }
        self.nodes[key].parent = cursor;
        if (cursor == EMPTY) {
            self.root = key;
        } else if (lessThan(key, cursor, data)) {
            self.nodes[cursor].left = key;
        } else {
            self.nodes[cursor].right = key;
        }
        aggregateRecursively(self, key, aggregate, data);
        insertFixup(self, key, aggregate, data);
    }

    function remove(
        Tree storage self,
        uint40 key,
        function(uint40, uint256) returns (bool) aggregate,
        uint256 data
    ) internal {
        require(key != EMPTY, "RBTL_R: key is empty");
        require(exists(self, key), "RBTL_R: key not exist");
        uint40 probe;
        uint40 cursor;
        if (self.nodes[key].left == EMPTY || self.nodes[key].right == EMPTY) {
            cursor = key;
        } else {
            cursor = self.nodes[key].right;
            while (self.nodes[cursor].left != EMPTY) {
                cursor = self.nodes[cursor].left;
            }
        }
        if (self.nodes[cursor].left != EMPTY) {
            probe = self.nodes[cursor].left;
        } else {
            probe = self.nodes[cursor].right;
        }
        uint40 yParent = self.nodes[cursor].parent;
        self.nodes[probe].parent = yParent;
        if (yParent != EMPTY) {
            if (cursor == self.nodes[yParent].left) {
                self.nodes[yParent].left = probe;
            } else {
                self.nodes[yParent].right = probe;
            }
        } else {
            self.root = probe;
        }
        bool doFixup = !self.nodes[cursor].red;
        if (cursor != key) {
            replaceParent(self, cursor, key);
            self.nodes[cursor].left = self.nodes[key].left;
            self.nodes[self.nodes[cursor].left].parent = cursor;
            self.nodes[cursor].right = self.nodes[key].right;
            self.nodes[self.nodes[cursor].right].parent = cursor;
            self.nodes[cursor].red = self.nodes[key].red;
            (cursor, key) = (key, cursor);
            aggregateRecursively(self, key, aggregate, data);
        }
        if (doFixup) {
            removeFixup(self, probe, aggregate, data);
        }
        aggregateRecursively(self, yParent, aggregate, data);

        // Fixed a bug that caused the parent of empty nodes to be non-zero.
        // TODO: Fix it the right way.
        if (probe == EMPTY) {
            self.nodes[probe].parent = EMPTY;
        }
    }

    // https://arxiv.org/pdf/1602.02120.pdf
    // changes from original
    // - handle empty
    // - handle parent
    // - change root to black

    // to avoid stack too deep
    struct JoinParams {
        uint40 left;
        uint40 key;
        uint40 right;
        uint8 leftBlackHeight;
        uint8 rightBlackHeight;
        uint256 data;
    }

    // destructive func
    function joinRight(
        Tree storage self,
        JoinParams memory params,
        function(uint40, uint256) returns (bool) aggregate
    ) private returns (uint40, uint8) {
        if (
            !self.nodes[params.left].red &&
            params.leftBlackHeight == params.rightBlackHeight
        ) {
            self.nodes[params.key].red = true;
            self.nodes[params.key].left = params.left;
            self.nodes[params.key].right = params.right;
            aggregate(params.key, params.data);
            return (params.key, params.leftBlackHeight);
        }

        (uint40 t, ) = joinRight(
            self,
            JoinParams({
                left: self.nodes[params.left].right,
                key: params.key,
                right: params.right,
                leftBlackHeight: params.leftBlackHeight -
                    (self.nodes[params.left].red ? 0 : 1),
                rightBlackHeight: params.rightBlackHeight,
                data: params.data
            }),
            aggregate
        );
        self.nodes[params.left].right = t;
        self.nodes[params.left].parent = EMPTY;
        aggregate(params.left, params.data);

        if (
            !self.nodes[params.left].red &&
            self.nodes[t].red &&
            self.nodes[self.nodes[t].right].red
        ) {
            self.nodes[self.nodes[t].right].red = false;
            rotateLeft(self, params.left, aggregate, params.data);
            return (t, params.leftBlackHeight);
            //            return (self.nodes[params.left].parent, tBlackHeight + 1); // TODO: replace with t
        }
        return (params.left, params.leftBlackHeight);
        //        return (params.left, tBlackHeight + (self.nodes[params.left].red ? 0 : 1));
    }

    // destructive func
    function joinLeft(
        Tree storage self,
        JoinParams memory params,
        function(uint40, uint256) returns (bool) aggregate
    ) internal returns (uint40 resultKey) {
        if (
            !self.nodes[params.right].red &&
            params.leftBlackHeight == params.rightBlackHeight
        ) {
            self.nodes[params.key].red = true;
            self.nodes[params.key].left = params.left;
            self.nodes[params.key].right = params.right;
            if (params.left != EMPTY) {
                self.nodes[params.left].parent = params.key;
            }
            if (params.right != EMPTY) {
                self.nodes[params.right].parent = params.key;
            }
            aggregate(params.key, params.data);
            return params.key;
        }

        uint40 t = joinLeft(
            self,
            JoinParams({
                left: params.left,
                key: params.key,
                right: self.nodes[params.right].left,
                leftBlackHeight: params.leftBlackHeight,
                rightBlackHeight: params.rightBlackHeight -
                    (self.nodes[params.right].red ? 0 : 1),
                data: params.data
            }),
            aggregate
        );
        self.nodes[params.right].left = t;
        self.nodes[params.right].parent = EMPTY;
        if (t != EMPTY) {
            self.nodes[t].parent = params.right;
        }
        aggregate(params.right, params.data);

        if (
            !self.nodes[params.right].red &&
            self.nodes[t].red &&
            self.nodes[self.nodes[t].left].red
        ) {
            self.nodes[self.nodes[t].left].red = false;
            rotateRight(self, params.right, aggregate, params.data);
            return t;
        }
        return params.right;
    }

    // destructive func
    function join(
        Tree storage self,
        uint40 left,
        uint40 key,
        uint40 right,
        function(uint40, uint256) returns (bool) aggregate,
        uint8 leftBlackHeight,
        uint8 rightBlackHeight,
        uint256 data
    ) private returns (uint40 t, uint8 tBlackHeight) {
        if (leftBlackHeight > rightBlackHeight) {
            (t, tBlackHeight) = joinRight(
                self,
                JoinParams({
                    left: left,
                    key: key,
                    right: right,
                    leftBlackHeight: leftBlackHeight,
                    rightBlackHeight: rightBlackHeight,
                    data: data
                }),
                aggregate
            );
            tBlackHeight = leftBlackHeight;
            if (self.nodes[t].red && self.nodes[self.nodes[t].right].red) {
                self.nodes[t].red = false;
                tBlackHeight += 1;
            }
        } else if (leftBlackHeight < rightBlackHeight) {
            t = joinLeft(
                self,
                JoinParams({
                    left: left,
                    key: key,
                    right: right,
                    leftBlackHeight: leftBlackHeight,
                    rightBlackHeight: rightBlackHeight,
                    data: data
                }),
                aggregate
            );
            tBlackHeight = rightBlackHeight;
            if (self.nodes[t].red && self.nodes[self.nodes[t].left].red) {
                self.nodes[t].red = false;
                tBlackHeight += 1;
            }
        } else {
            bool red = !self.nodes[left].red && !self.nodes[right].red;
            self.nodes[key].red = red;
            self.nodes[key].left = left;
            self.nodes[key].right = right;
            aggregate(key, data);
            (t, tBlackHeight) = (key, leftBlackHeight + (red ? 0 : 1));
        }
    }

    struct SplitParams {
        uint40 t;
        uint40 key;
        uint8 blackHeight;
        uint256 data;
    }

    // destructive func
    function splitRight(
        Tree storage self,
        SplitParams memory params,
        function(uint40, uint40, uint256) returns (bool) lessThan,
        function(uint40, uint256) returns (bool) aggregate,
        function(uint40, uint256) subtreeRemoved
    ) private returns (uint40 resultKey, uint8 resultBlackHeight) {
        if (params.t == EMPTY) return (EMPTY, params.blackHeight);
        params.blackHeight -= (self.nodes[params.t].red ? 0 : 1);
        if (params.key == params.t) {
            subtreeRemoved(params.t, params.data);
            return (self.nodes[params.t].right, params.blackHeight);
        }
        if (lessThan(params.key, params.t, params.data)) {
            (uint40 r, uint8 rBlackHeight) = splitRight(
                self,
                SplitParams({
                    t: self.nodes[params.t].left,
                    key: params.key,
                    blackHeight: params.blackHeight,
                    data: params.data
                }),
                lessThan,
                aggregate,
                subtreeRemoved
            );
            return
                join(
                    self,
                    r,
                    params.t,
                    self.nodes[params.t].right,
                    aggregate,
                    rBlackHeight,
                    params.blackHeight,
                    params.data
                );
        } else {
            subtreeRemoved(params.t, params.data);
            return
                splitRight(
                    self,
                    SplitParams({
                        t: self.nodes[params.t].right,
                        key: params.key,
                        blackHeight: params.blackHeight,
                        data: params.data
                    }),
                    lessThan,
                    aggregate,
                    subtreeRemoved
                );
        }
    }

    function removeLeft(
        Tree storage self,
        uint40 key,
        function(uint40, uint40, uint256) returns (bool) lessThan,
        function(uint40, uint256) returns (bool) aggregate,
        function(uint40, uint256) subtreeRemoved,
        uint256 data
    ) internal {
        require(key != EMPTY, "RBTL_RL: key is empty");
        require(exists(self, key), "RBTL_RL: key not exist");
        (self.root, ) = splitRight(
            self,
            SplitParams({t: self.root, key: key, blackHeight: 128, data: data}),
            lessThan,
            aggregate,
            subtreeRemoved
        );
        self.nodes[self.root].parent = EMPTY;
        self.nodes[self.root].red = false;
    }

    function aggregateRecursively(
        Tree storage self,
        uint40 key,
        function(uint40, uint256) returns (bool) aggregate,
        uint256 data
    ) internal {
        while (key != EMPTY) {
            if (aggregate(key, data)) return;
            key = self.nodes[key].parent;
        }
    }

    function treeMinimum(Tree storage self, uint40 key)
        private
        view
        returns (uint40)
    {
        while (self.nodes[key].left != EMPTY) {
            key = self.nodes[key].left;
        }
        return key;
    }

    function treeMaximum(Tree storage self, uint40 key)
        private
        view
        returns (uint40)
    {
        while (self.nodes[key].right != EMPTY) {
            key = self.nodes[key].right;
        }
        return key;
    }

    function rotateLeft(
        Tree storage self,
        uint40 key,
        function(uint40, uint256) returns (bool) aggregate,
        uint256 data
    ) private {
        uint40 cursor = self.nodes[key].right;
        uint40 keyParent = self.nodes[key].parent;
        uint40 cursorLeft = self.nodes[cursor].left;
        self.nodes[key].right = cursorLeft;
        if (cursorLeft != EMPTY) {
            self.nodes[cursorLeft].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].left) {
            self.nodes[keyParent].left = cursor;
        } else {
            self.nodes[keyParent].right = cursor;
        }
        self.nodes[cursor].left = key;
        self.nodes[key].parent = cursor;
        aggregate(key, data);
        aggregate(cursor, data);
    }

    function rotateRight(
        Tree storage self,
        uint40 key,
        function(uint40, uint256) returns (bool) aggregate,
        uint256 data
    ) private {
        uint40 cursor = self.nodes[key].left;
        uint40 keyParent = self.nodes[key].parent;
        uint40 cursorRight = self.nodes[cursor].right;
        self.nodes[key].left = cursorRight;
        if (cursorRight != EMPTY) {
            self.nodes[cursorRight].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].right) {
            self.nodes[keyParent].right = cursor;
        } else {
            self.nodes[keyParent].left = cursor;
        }
        self.nodes[cursor].right = key;
        self.nodes[key].parent = cursor;
        aggregate(key, data);
        aggregate(cursor, data);
    }

    function insertFixup(
        Tree storage self,
        uint40 key,
        function(uint40, uint256) returns (bool) aggregate,
        uint256 data
    ) private {
        uint40 cursor;
        while (key != self.root && self.nodes[self.nodes[key].parent].red) {
            uint40 keyParent = self.nodes[key].parent;
            if (keyParent == self.nodes[self.nodes[keyParent].parent].left) {
                cursor = self.nodes[self.nodes[keyParent].parent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].right) {
                        key = keyParent;
                        rotateLeft(self, key, aggregate, data);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateRight(
                        self,
                        self.nodes[keyParent].parent,
                        aggregate,
                        data
                    );
                }
            } else {
                cursor = self.nodes[self.nodes[keyParent].parent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].left) {
                        key = keyParent;
                        rotateRight(self, key, aggregate, data);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateLeft(
                        self,
                        self.nodes[keyParent].parent,
                        aggregate,
                        data
                    );
                }
            }
        }
        self.nodes[self.root].red = false;
    }

    function replaceParent(
        Tree storage self,
        uint40 a,
        uint40 b
    ) private {
        uint40 bParent = self.nodes[b].parent;
        self.nodes[a].parent = bParent;
        if (bParent == EMPTY) {
            self.root = a;
        } else {
            if (b == self.nodes[bParent].left) {
                self.nodes[bParent].left = a;
            } else {
                self.nodes[bParent].right = a;
            }
        }
    }

    function removeFixup(
        Tree storage self,
        uint40 key,
        function(uint40, uint256) returns (bool) aggregate,
        uint256 data
    ) private {
        uint40 cursor;
        while (key != self.root && !self.nodes[key].red) {
            uint40 keyParent = self.nodes[key].parent;
            if (key == self.nodes[keyParent].left) {
                cursor = self.nodes[keyParent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateLeft(self, keyParent, aggregate, data);
                    cursor = self.nodes[keyParent].right;
                }
                if (
                    !self.nodes[self.nodes[cursor].left].red &&
                    !self.nodes[self.nodes[cursor].right].red
                ) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].right].red) {
                        self.nodes[self.nodes[cursor].left].red = false;
                        self.nodes[cursor].red = true;
                        rotateRight(self, cursor, aggregate, data);
                        cursor = self.nodes[keyParent].right;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].right].red = false;
                    rotateLeft(self, keyParent, aggregate, data);
                    key = self.root;
                }
            } else {
                cursor = self.nodes[keyParent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateRight(self, keyParent, aggregate, data);
                    cursor = self.nodes[keyParent].left;
                }
                if (
                    !self.nodes[self.nodes[cursor].right].red &&
                    !self.nodes[self.nodes[cursor].left].red
                ) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].left].red) {
                        self.nodes[self.nodes[cursor].right].red = false;
                        self.nodes[cursor].red = true;
                        rotateLeft(self, cursor, aggregate, data);
                        cursor = self.nodes[keyParent].left;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].left].red = false;
                    rotateRight(self, keyParent, aggregate, data);
                    key = self.root;
                }
            }
        }
        self.nodes[key].red = false;
    }
}
// ----------------------------------------------------------------------------
// End - BokkyPooBah's Red-Black Tree Library
// ----------------------------------------------------------------------------

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";

library PerpMath {
    using SafeCast for int256;
    using SignedSafeMath for int256;
    using SafeMath for uint256;

    function formatSqrtPriceX96ToPriceX96(uint160 sqrtPriceX96) internal pure returns (uint256) {
        return Math.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
    }

    function formatX10_18ToX96(uint256 valueX10_18) internal pure returns (uint256) {
        return Math.mulDiv(valueX10_18, FixedPoint96.Q96, 1 ether);
    }

    function formatX96ToX10_18(uint256 valueX96) internal pure returns (uint256) {
        return Math.mulDiv(valueX96, 1 ether, FixedPoint96.Q96);
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function abs(int256 value) internal pure returns (uint256) {
        return value >= 0 ? value.toUint256() : neg256(value).toUint256();
    }

    function neg256(int256 a) internal pure returns (int256) {
        require(a > -2**255, "PerpMath: inversion overflow");
        return -a;
    }

    function neg256(uint256 a) internal pure returns (int256) {
        return -SafeCast.toInt256(a);
    }

    function divBy10_18(int256 value) internal pure returns (int256) {
        // no overflow here
        return value / (1 ether);
    }

    function divBy10_18(uint256 value) internal pure returns (uint256) {
        // no overflow here
        return value / (1 ether);
    }

    function subRatio(uint24 a, uint24 b) internal pure returns (uint24) {
        require(b <= a, "PerpMath: subtraction overflow");
        return a - b;
    }

    function mulRatio(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return Math.mulDiv(value, ratio, 1e6);
    }

    function mulRatioRoundingUp(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return Math.mulDiv(value, ratio, 1e6, Math.Rounding.Up);
    }

    function divRatio(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return Math.mulDiv(value, 1e6, ratio);
    }

    function divRatioRoundingUp(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return Math.mulDiv(value, 1e6, ratio, Math.Rounding.Up);
    }

    /// @param denominator cannot be 0 and is checked in Math.mulDiv()
    function mulDiv(
        int256 a,
        int256 b,
        uint256 denominator
    ) internal pure returns (int256 result) {
        uint256 unsignedA = a < 0 ? uint256(neg256(a)) : uint256(a);
        uint256 unsignedB = b < 0 ? uint256(neg256(b)) : uint256(b);
        bool negative = ((a < 0 && b > 0) || (a > 0 && b < 0)) ? true : false;

        uint256 unsignedResult = Math.mulDiv(unsignedA, unsignedB, denominator);

        result = negative ? neg256(unsignedResult) : SafeCast.toInt256(unsignedResult);

        return result;
    }

    function sign(int256 value) internal pure returns (int256) {
        return value > 0 ? int256(1) : (value < 0 ? int256(-1) : int256(0));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

interface IPerpdexPriceFeed {
    function decimals() external view returns (uint8);

    /// @dev Returns the index price of the token.
    function getPrice() external view returns (uint256);
}