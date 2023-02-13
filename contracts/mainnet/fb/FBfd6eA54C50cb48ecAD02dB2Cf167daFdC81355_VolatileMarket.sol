// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "../OrderBook.sol";
import "./GeometricPriceBook.sol";

contract VolatileMarket is OrderBook, GeometricPriceBook {
    constructor(
        address orderToken_,
        address quoteToken_,
        address baseToken_,
        uint96 quoteUnit_,
        int24 makerFee_,
        uint24 takerFee_,
        address factory_,
        uint128 a_,
        uint128 r_
    )
        OrderBook(orderToken_, quoteToken_, baseToken_, quoteUnit_, makerFee_, takerFee_, factory_)
        GeometricPriceBook(a_, r_)
    {}

    function indexToPrice(uint16 priceIndex) public view override returns (uint128) {
        return _indexToPrice(priceIndex);
    }
}

// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@clober/library/contracts/OctopusHeap.sol";
import "@clober/library/contracts/SegmentedSegmentTree.sol";

import "./interfaces/CloberMarketFactory.sol";
import "./interfaces/CloberMarketSwapCallbackReceiver.sol";
import "./interfaces/CloberMarketFlashCallbackReceiver.sol";
import "./interfaces/CloberOrderBook.sol";
import "./interfaces/CloberOrderNFT.sol";
import "./Errors.sol";
import "./utils/Math.sol";
import "./utils/OrderKeyUtils.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/RevertOnDelegateCall.sol";

abstract contract OrderBook is CloberOrderBook, ReentrancyGuard, RevertOnDelegateCall {
    using SafeERC20 for IERC20;
    using OctopusHeap for OctopusHeap.Core;
    using SegmentedSegmentTree for SegmentedSegmentTree.Core;
    using PackedUint256 for uint256;
    using DirtyUint64 for uint64;
    using SignificantBit for uint256;
    using OrderKeyUtils for OrderKey;

    uint256 private constant _CLAIM_BOUNTY_UNIT = 1 gwei;
    uint256 private constant _PRICE_PRECISION = 10**18;
    uint256 private constant _FEE_PRECISION = 1000000; // 1 = 0.0001%
    uint256 private constant _MAX_ORDER = 2**15; // 32768
    uint256 private constant _MAX_ORDER_M = 2**15 - 1; // % 32768
    uint24 private constant _PROTOCOL_FEE = 200000; // 20%
    bool private constant _BID = true;
    bool private constant _ASK = false;

    struct Queue {
        SegmentedSegmentTree.Core tree;
        uint256 index; // index of where the next order would go
    }

    IERC20 private immutable _quoteToken;
    IERC20 private immutable _baseToken;
    uint256 private immutable _quotePrecisionComplement; // 10**(18 - d)
    uint256 private immutable _basePrecisionComplement; // 10**(18 - d)
    uint256 public immutable override quoteUnit;
    CloberMarketFactory private immutable _factory;
    int24 public immutable override makerFee;
    uint24 public immutable override takerFee;
    address public immutable override orderToken;

    OctopusHeap.Core private _askHeap;
    OctopusHeap.Core private _bidHeap;

    mapping(uint16 => Queue) internal _askQueues; // priceIndex => Queue
    mapping(uint16 => Queue) internal _bidQueues; // priceIndex => Queue

    mapping(uint16 => uint256) internal _askClaimable;
    mapping(uint16 => uint256) internal _bidClaimable;

    uint128 private _quoteFeeBalance; // dirty slot
    uint128 private _baseFeeBalance;
    mapping(address => uint256) public override uncollectedHostFees;
    mapping(address => uint256) public override uncollectedProtocolFees;
    mapping(uint256 => Order) private _orders;

    constructor(
        address orderToken_,
        address quoteToken_,
        address baseToken_,
        uint96 quoteUnit_,
        int24 makerFee_,
        uint24 takerFee_,
        address factory_
    ) {
        orderToken = orderToken_;
        quoteUnit = quoteUnit_;

        _factory = CloberMarketFactory(factory_);

        _quoteToken = IERC20(quoteToken_);
        _baseToken = IERC20(baseToken_);
        _quotePrecisionComplement = _getDecimalComplement(quoteToken_);
        _basePrecisionComplement = _getDecimalComplement(baseToken_);

        makerFee = makerFee_;
        takerFee = takerFee_;

        _askHeap.init();
        _bidHeap.init();

        // make slot dirty
        _quoteFeeBalance = 1;
    }

    function _getDecimalComplement(address token) internal view returns (uint256) {
        return 10**(18 - IERC20Metadata(token).decimals());
    }

    function limitOrder(
        address user,
        uint16 priceIndex,
        uint64 rawAmount,
        uint256 baseAmount,
        uint8 options,
        bytes calldata data
    ) external payable nonReentrant revertOnDelegateCall returns (uint256 orderIndex) {
        options = options & 0x03; // clear unused bits
        if (msg.value / _CLAIM_BOUNTY_UNIT > type(uint32).max) {
            revert Errors.CloberError(Errors.OVERFLOW_UNDERFLOW);
        }
        bool isBid = (options & 1) == 1;

        uint256 inputAmount;
        uint256 outputAmount;
        uint256 bountyRefundAmount = msg.value % _CLAIM_BOUNTY_UNIT;
        {
            uint256 requestedAmount = isBid ? rawToQuote(rawAmount) : baseAmount;
            // decode option to check if postOnly
            if (options & 2 == 2) {
                OctopusHeap.Core storage heap = _getHeap(!isBid);
                if (!heap.isEmpty() && (isBid ? priceIndex : ~priceIndex) >= heap.root()) {
                    revert Errors.CloberError(Errors.POST_ONLY);
                }
            } else {
                (inputAmount, outputAmount) = _take(user, requestedAmount, priceIndex, !isBid, true, options);
                requestedAmount -= inputAmount;
            }

            uint64 remainingRequestedRawAmount = isBid
                ? quoteToRaw(requestedAmount, false)
                : baseToRaw(requestedAmount, priceIndex, false);
            if (remainingRequestedRawAmount > 0) {
                // requestedAmount was repurposed as requiredAmount to avoid "Stack too deep".
                (requestedAmount, orderIndex) = _makeOrder(
                    user,
                    priceIndex,
                    remainingRequestedRawAmount,
                    uint32(msg.value / _CLAIM_BOUNTY_UNIT),
                    isBid,
                    options
                );
                inputAmount += requestedAmount;
                _mintToken(user, isBid, priceIndex, orderIndex);
            } else {
                orderIndex = type(uint256).max;
                // refund claimBounty if an order was not made.
                bountyRefundAmount = msg.value;
            }
        }

        (IERC20 inputToken, IERC20 outputToken) = isBid ? (_quoteToken, _baseToken) : (_baseToken, _quoteToken);

        _transferToken(outputToken, user, outputAmount);

        _callback(inputToken, outputToken, inputAmount, outputAmount, bountyRefundAmount, data);
    }

    function getExpectedAmount(
        uint16 limitPriceIndex,
        uint64 rawAmount,
        uint256 baseAmount,
        uint8 options
    ) external view returns (uint256 inputAmount, uint256 outputAmount) {
        inputAmount = 0;
        bool isTakingBidSide = (options & 1) == 0;
        bool expendInput = (options & 2) == 2;
        uint256 requestedAmount = isTakingBidSide == expendInput ? baseAmount : rawToQuote(rawAmount);

        OctopusHeap.Core storage core = _getHeap(isTakingBidSide);
        if (isTakingBidSide) {
            // @dev limitPriceIndex is changed to its value in storage, be careful when using this value
            limitPriceIndex = ~limitPriceIndex;
        }

        if (!expendInput) {
            // Increase requestedAmount by fee when expendInput is false
            requestedAmount = _calculateTakeAmountBeforeFees(requestedAmount);
        }

        if (requestedAmount == 0) return (0, 0);

        (uint256 word, uint256[] memory heap) = core.getRootWordAndHeap();
        if (word == 0) return (0, 0);
        uint16 currentIndex = uint16(heap[0] & 0xff00) | word.leastSignificantBit();
        while (word > 0) {
            if (limitPriceIndex < currentIndex) break;
            if (isTakingBidSide) currentIndex = ~currentIndex;

            (uint256 _inputAmount, uint256 _outputAmount, ) = _expectTake(
                isTakingBidSide,
                requestedAmount,
                currentIndex,
                expendInput
            );
            inputAmount += _inputAmount;
            outputAmount += _outputAmount;

            uint256 filledAmount = expendInput ? _inputAmount : _outputAmount;
            if (requestedAmount > filledAmount && filledAmount > 0) {
                unchecked {
                    requestedAmount -= filledAmount;
                }
            } else {
                break;
            }

            do {
                (word, heap) = core.popInMemory(word, heap);
                if (word == 0) break;
                currentIndex = uint16(heap[0] & 0xff00) | word.leastSignificantBit();
            } while (getDepth(isTakingBidSide, isTakingBidSide ? ~currentIndex : currentIndex) == 0);
        }
        outputAmount -= _calculateTakerFeeAmount(outputAmount, true);
    }

    function marketOrder(
        address user,
        uint16 limitPriceIndex,
        uint64 rawAmount,
        uint256 baseAmount,
        uint8 options,
        bytes calldata data
    ) external nonReentrant revertOnDelegateCall {
        options = (options | 0x80) & 0x83; // Set the most significant bit to 1 for market orders and clear unused bits
        bool isBid = (options & 1) == 1;

        uint256 inputAmount;
        uint256 outputAmount;
        uint256 quoteAmount = rawToQuote(rawAmount);
        {
            bool expendInput = (options & 2) == 2;
            (inputAmount, outputAmount) = _take(
                user,
                // Bid & expendInput => quote
                // Bid & !expendInput => base
                // Ask & expendInput => base
                // Ask & !expendInput => quote
                isBid == expendInput ? quoteAmount : baseAmount,
                limitPriceIndex,
                !isBid,
                expendInput,
                options
            );
        }
        IERC20 inputToken;
        IERC20 outputToken;
        {
            uint256 inputThreshold;
            uint256 outputThreshold;
            (inputToken, outputToken, inputThreshold, outputThreshold) = isBid
                ? (_quoteToken, _baseToken, quoteAmount, baseAmount)
                : (_baseToken, _quoteToken, baseAmount, quoteAmount);
            if (inputAmount > inputThreshold || outputAmount < outputThreshold) {
                revert Errors.CloberError(Errors.SLIPPAGE);
            }
        }
        _transferToken(outputToken, user, outputAmount);

        _callback(inputToken, outputToken, inputAmount, outputAmount, 0, data);
    }

    function cancel(address receiver, OrderKey[] calldata orderKeys) external nonReentrant revertOnDelegateCall {
        if (orderKeys.length == 0) {
            revert Errors.CloberError(Errors.EMPTY_INPUT);
        }
        uint256 quoteToTransfer;
        uint256 baseToTransfer;
        uint256 totalCanceledBounty;
        for (uint256 i = 0; i < orderKeys.length; ++i) {
            OrderKey calldata orderKey = orderKeys[i];
            (
                uint64 remainingAmount,
                uint256 minusFee,
                uint256 claimedTokenAmount,
                uint32 refundedClaimBounty
            ) = _cancel(receiver, orderKey);

            // overflow when length == 2**224 > 2 * size(priceIndex) * _MAX_ORDER, absolutely never happening
            unchecked {
                totalCanceledBounty += refundedClaimBounty;
            }

            if (orderKey.isBid) {
                quoteToTransfer += (remainingAmount > 0 ? rawToQuote(remainingAmount) : 0) + minusFee;
                baseToTransfer += claimedTokenAmount;
            } else {
                baseToTransfer +=
                    (remainingAmount > 0 ? rawToBase(remainingAmount, orderKey.priceIndex, false) : 0) +
                    minusFee;
                quoteToTransfer += claimedTokenAmount;
            }
        }
        _transferToken(_quoteToken, receiver, quoteToTransfer);
        _transferToken(_baseToken, receiver, baseToTransfer);
        _sendGWeiValue(receiver, totalCanceledBounty);

        // remove priceIndices that have no open orders
        _cleanHeap(_BID);
        _cleanHeap(_ASK);
    }

    function _cancel(address receiver, OrderKey calldata orderKey)
        internal
        returns (
            uint64 remainingAmount,
            uint256 minusFee,
            uint256 claimedTokenAmount,
            uint32 refundedClaimBounty
        )
    {
        Queue storage queue = _getQueue(orderKey.isBid, orderKey.priceIndex);
        _checkOrderIndexValidity(orderKey.orderIndex, queue.index);
        uint256 orderId = orderKey.encode();
        Order memory mOrder = _orders[orderId];

        if (mOrder.amount == 0) return (0, 0, 0, 0);
        if (msg.sender != mOrder.owner && msg.sender != orderToken) {
            revert Errors.CloberError(Errors.ACCESS);
        }

        // repurpose `remainingAmount` to temporarily store `claimedRawAmount`
        (claimedTokenAmount, minusFee, remainingAmount) = _claim(queue, mOrder, orderKey, receiver);

        _orders[orderId].amount = 0;
        remainingAmount = mOrder.amount - remainingAmount;

        if (remainingAmount > 0) {
            queue.tree.update(
                orderKey.orderIndex & _MAX_ORDER_M,
                queue.tree.get(orderKey.orderIndex & _MAX_ORDER_M) - remainingAmount
            );
            emit CancelOrder(mOrder.owner, remainingAmount, orderKey.orderIndex, orderKey.priceIndex, orderKey.isBid);
            _burnToken(orderId);
        }

        refundedClaimBounty = mOrder.claimBounty;
    }

    function claim(address claimer, OrderKey[] calldata orderKeys) external nonReentrant revertOnDelegateCall {
        uint256 totalBounty;
        for (uint256 i = 0; i < orderKeys.length; ++i) {
            OrderKey calldata orderKey = orderKeys[i];
            Queue storage queue = _getQueue(orderKey.isBid, orderKey.priceIndex);
            if (_isInvalidOrderIndex(orderKey.orderIndex, queue.index)) {
                continue;
            }

            uint256 orderId = orderKey.encode();
            Order memory mOrder = _orders[orderId];
            if (mOrder.amount == 0) {
                continue;
            }

            (uint256 claimedTokenAmount, uint256 minusFee, uint64 claimedRawAmount) = _claim(
                queue,
                mOrder,
                orderKey,
                claimer
            );
            if (claimedRawAmount == 0) {
                continue;
            }

            _orders[orderId].amount = mOrder.amount - claimedRawAmount;

            if (mOrder.amount == claimedRawAmount) {
                // overflow when length == 2**224 > 2 * size(priceIndex) * _MAX_ORDER, absolutely never happening
                unchecked {
                    totalBounty += mOrder.claimBounty;
                }
            }
            (uint256 totalQuoteAmount, uint256 totalBaseAmount) = orderKey.isBid
                ? (minusFee, claimedTokenAmount)
                : (claimedTokenAmount, minusFee);

            _transferToken(_quoteToken, mOrder.owner, totalQuoteAmount);
            _transferToken(_baseToken, mOrder.owner, totalBaseAmount);
        }
        _sendGWeiValue(claimer, totalBounty);
    }

    function flash(
        address borrower,
        uint256 quoteAmount,
        uint256 baseAmount,
        bytes calldata data
    ) external nonReentrant {
        uint256 beforeQuoteAmount = _thisBalance(_quoteToken);
        uint256 beforeBaseAmount = _thisBalance(_baseToken);
        uint256 feePrecision = _FEE_PRECISION;
        uint256 quoteFeeAmount = Math.divide(quoteAmount * takerFee, feePrecision, true);
        uint256 baseFeeAmount = Math.divide(baseAmount * takerFee, feePrecision, true);
        _transferToken(_quoteToken, borrower, quoteAmount);
        _transferToken(_baseToken, borrower, baseAmount);

        CloberMarketFlashCallbackReceiver(msg.sender).cloberMarketFlashCallback(
            address(_quoteToken),
            address(_baseToken),
            quoteAmount,
            baseAmount,
            quoteFeeAmount,
            baseFeeAmount,
            data
        );

        uint256 afterQuoteAmount = _thisBalance(_quoteToken);
        uint256 afterBaseAmount = _thisBalance(_baseToken);
        if (
            afterQuoteAmount < beforeQuoteAmount + quoteFeeAmount || afterBaseAmount < beforeBaseAmount + baseFeeAmount
        ) {
            revert Errors.CloberError(Errors.INSUFFICIENT_BALANCE);
        }

        uint256 earnedQuoteAmount;
        uint256 earnedBaseAmount;
        unchecked {
            earnedQuoteAmount = afterQuoteAmount - beforeQuoteAmount;
            earnedBaseAmount = afterBaseAmount - beforeBaseAmount;
        }
        _addToFeeBalance(false, earnedQuoteAmount);
        _addToFeeBalance(true, earnedBaseAmount);

        emit Flash(msg.sender, borrower, quoteAmount, baseAmount, earnedQuoteAmount, earnedBaseAmount);
    }

    function quoteToken() external view returns (address) {
        return address(_quoteToken);
    }

    function baseToken() external view returns (address) {
        return address(_baseToken);
    }

    function getDepth(bool isBid, uint16 priceIndex) public view returns (uint64) {
        (uint16 groupIndex, uint8 elementIndex) = _splitClaimableIndex(priceIndex);
        return
            _getQueue(isBid, priceIndex).tree.total() -
            _getClaimable(isBid)[groupIndex].get64Unsafe(elementIndex).toClean();
    }

    function getFeeBalance() external view returns (uint128, uint128) {
        unchecked {
            return (_quoteFeeBalance - 1, _baseFeeBalance);
        }
    }

    function isEmpty(bool isBid) external view returns (bool) {
        return _getHeap(isBid).isEmpty();
    }

    function getOrder(OrderKey calldata orderKey) external view returns (Order memory) {
        return _getOrder(orderKey);
    }

    function bestPriceIndex(bool isBid) external view returns (uint16 priceIndex) {
        priceIndex = (isBid ? _bidHeap : _askHeap).root();
        if (isBid) {
            priceIndex = ~priceIndex;
        }
    }

    function indexToPrice(uint16 priceIndex) public view virtual returns (uint128);

    function _cleanHeap(bool isBid) private {
        OctopusHeap.Core storage heap = _getHeap(isBid);
        while (!heap.isEmpty()) {
            if (getDepth(isBid, isBid ? ~heap.root() : heap.root()) == 0) {
                heap.pop();
            } else {
                break;
            }
        }
    }

    function _checkOrderIndexValidity(uint256 orderIndex, uint256 currentIndex) internal pure {
        if (_isInvalidOrderIndex(orderIndex, currentIndex)) {
            revert Errors.CloberError(Errors.INVALID_ID);
        }
    }

    function _isInvalidOrderIndex(uint256 orderIndex, uint256 currentIndex) internal pure returns (bool) {
        // valid active order indices are smaller than the currentIndex
        return currentIndex <= orderIndex;
    }

    function _getOrder(OrderKey memory orderKey) internal view returns (Order storage) {
        _checkOrderIndexValidity(orderKey.orderIndex, _getQueue(orderKey.isBid, orderKey.priceIndex).index);

        return _orders[orderKey.encode()];
    }

    function _getHeap(bool isBid) internal view returns (OctopusHeap.Core storage) {
        return isBid ? _bidHeap : _askHeap;
    }

    function _getQueue(bool isBid, uint16 priceIndex) internal view returns (Queue storage) {
        return (isBid ? _bidQueues : _askQueues)[priceIndex];
    }

    function _getClaimable(bool isBid) internal view returns (mapping(uint16 => uint256) storage) {
        return isBid ? _bidClaimable : _askClaimable;
    }

    function _splitClaimableIndex(uint16 priceIndex) internal pure returns (uint16 groupIndex, uint8 elementIndex) {
        uint256 casted = priceIndex;
        assembly {
            elementIndex := and(priceIndex, 3) // mod 4
            groupIndex := shr(2, casted) // div 4
        }
    }

    function _getClaimRangeRight(Queue storage queue, uint256 orderIndex) internal view returns (uint64 rangeRight) {
        uint256 l = queue.index & _MAX_ORDER_M;
        uint256 r = (orderIndex + 1) & _MAX_ORDER_M;
        rangeRight = (l < r) ? queue.tree.query(l, r) : queue.tree.total() - queue.tree.query(r, l);
    }

    function _calculateClaimableAmountAndFees(
        bool isBidOrder,
        uint64 claimedRawAmount,
        uint16 priceIndex
    )
        internal
        view
        returns (
            uint256 claimableAmount,
            int256 makerFeeAmount,
            uint256 takerFeeAmount
        )
    {
        uint256 baseAmount = rawToBase(claimedRawAmount, priceIndex, false);
        uint256 quoteAmount = rawToQuote(claimedRawAmount);

        uint256 takeAmount;
        (takeAmount, claimableAmount) = isBidOrder ? (quoteAmount, baseAmount) : (baseAmount, quoteAmount);
        // rounding down to prevent insufficient balance
        takerFeeAmount = _calculateTakerFeeAmount(takeAmount, false);

        uint256 feePrecision = _FEE_PRECISION;
        if (makerFee > 0) {
            // rounding up maker fee when makerFee > 0
            uint256 feeAmountAbs = Math.divide(claimableAmount * uint24(makerFee), feePrecision, true);
            // feeAmountAbs < type(uint256).max * _MAX_FEE / feePrecision < type(int256).max
            makerFeeAmount = int256(feeAmountAbs);
            unchecked {
                // makerFee < _MAX_FEE < feePrecision => feeAmountAbs < claimableAmount
                claimableAmount -= feeAmountAbs;
            }
        } else {
            // rounding down maker fee when makerFee < 0
            makerFeeAmount = -int256((takeAmount * uint24(-makerFee)) / feePrecision);
        }
    }

    function _calculateTakeAmountBeforeFees(uint256 amountAfterFees) internal view returns (uint256 amountBeforeFees) {
        uint256 feePrecision = _FEE_PRECISION;
        uint256 divisor;
        unchecked {
            divisor = feePrecision - takerFee;
        }
        amountBeforeFees = Math.divide(amountAfterFees * feePrecision, divisor, true);
    }

    function _calculateTakerFeeAmount(uint256 takeAmount, bool roundingUp) internal view returns (uint256) {
        // takerFee is always positive
        return Math.divide(takeAmount * takerFee, _FEE_PRECISION, roundingUp);
    }

    function rawToBase(
        uint64 rawAmount,
        uint16 priceIndex,
        bool roundingUp
    ) public view returns (uint256) {
        return
            Math.divide(
                (rawToQuote(rawAmount) * _PRICE_PRECISION) * _quotePrecisionComplement,
                _basePrecisionComplement * indexToPrice(priceIndex),
                roundingUp
            );
    }

    function rawToQuote(uint64 rawAmount) public view returns (uint256) {
        return quoteUnit * rawAmount;
    }

    function baseToRaw(
        uint256 baseAmount,
        uint16 priceIndex,
        bool roundingUp
    ) public view returns (uint64) {
        uint256 rawAmount = Math.divide(
            (baseAmount * indexToPrice(priceIndex)) * _basePrecisionComplement,
            _PRICE_PRECISION * _quotePrecisionComplement * quoteUnit,
            roundingUp
        );
        if (rawAmount > type(uint64).max) {
            revert Errors.CloberError(Errors.OVERFLOW_UNDERFLOW);
        }
        return uint64(rawAmount);
    }

    function quoteToRaw(uint256 quoteAmount, bool roundingUp) public view returns (uint64) {
        uint256 rawAmount = Math.divide(quoteAmount, quoteUnit, roundingUp);
        if (rawAmount > type(uint64).max) {
            revert Errors.CloberError(Errors.OVERFLOW_UNDERFLOW);
        }
        return uint64(rawAmount);
    }

    function _expectTake(
        bool isTakingBidSide,
        uint256 remainingAmount,
        uint16 currentIndex,
        bool expendInput
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint64
        )
    {
        uint64 takenRawAmount;
        {
            uint64 depth = getDepth(isTakingBidSide, currentIndex);
            // Rounds down if expendInput, rounds up if !expendInput
            // Bid & expendInput => taking ask & expendInput => rounds down (user specified quote)
            // Bid & !expendInput => taking ask & !expendInput => rounds up (user specified base)
            // Ask & expendInput => taking bid & expendInput => rounds down (user specified base)
            // Ask & !expendInput => taking bid & !expendInput => rounds up (user specified quote)
            uint64 remainingRawAmount;
            remainingRawAmount = isTakingBidSide == expendInput
                ? baseToRaw(remainingAmount, currentIndex, !expendInput)
                : quoteToRaw(remainingAmount, !expendInput);
            takenRawAmount = depth > remainingRawAmount ? remainingRawAmount : depth;
            if (takenRawAmount == 0) {
                return (0, 0, 0);
            }
        }

        (uint256 inputAmount, uint256 outputAmount) = isTakingBidSide
            ? (rawToBase(takenRawAmount, currentIndex, isTakingBidSide), rawToQuote(takenRawAmount))
            : (rawToQuote(takenRawAmount), rawToBase(takenRawAmount, currentIndex, isTakingBidSide));

        return (inputAmount, outputAmount, takenRawAmount);
    }

    function _take(
        address user,
        uint256 requestedAmount,
        uint16 limitPriceIndex,
        bool isTakingBidSide,
        bool expendInput,
        uint8 options
    ) internal returns (uint256 inputAmount, uint256 outputAmount) {
        inputAmount = 0;
        outputAmount = 0;
        if (requestedAmount == 0) {
            revert Errors.CloberError(Errors.EMPTY_INPUT);
        }
        OctopusHeap.Core storage heap = _getHeap(isTakingBidSide);
        if (isTakingBidSide) {
            // @dev limitPriceIndex is changed to its value in storage, be careful when using this value
            limitPriceIndex = ~limitPriceIndex;
        }

        if (!expendInput) {
            // Increase requestedAmount by fee when expendInput is false
            requestedAmount = _calculateTakeAmountBeforeFees(requestedAmount);
        }

        mapping(uint16 => uint256) storage claimable = _getClaimable(isTakingBidSide);
        while (requestedAmount > 0 && !heap.isEmpty()) {
            uint16 currentIndex = heap.root();
            if (limitPriceIndex < currentIndex) break;
            if (isTakingBidSide) currentIndex = ~currentIndex;

            uint64 takenRawAmount;
            {
                uint256 _inputAmount;
                uint256 _outputAmount;
                (_inputAmount, _outputAmount, takenRawAmount) = _expectTake(
                    isTakingBidSide,
                    requestedAmount,
                    currentIndex,
                    expendInput
                );
                if (takenRawAmount == 0) break;
                inputAmount += _inputAmount;
                outputAmount += _outputAmount;

                uint256 filledAmount = expendInput ? _inputAmount : _outputAmount;
                if (requestedAmount > filledAmount) {
                    unchecked {
                        requestedAmount -= filledAmount;
                    }
                } else {
                    requestedAmount = 0;
                }
            }
            {
                (uint16 groupIndex, uint8 elementIndex) = _splitClaimableIndex(currentIndex);
                uint256 claimableGroup = claimable[groupIndex];
                claimable[groupIndex] = claimableGroup.update64Unsafe(
                    elementIndex, // elementIndex < 4
                    claimableGroup.get64Unsafe(elementIndex).addClean(takenRawAmount)
                );
            }
            if (getDepth(isTakingBidSide, currentIndex) == 0) _cleanHeap(isTakingBidSide);

            emit TakeOrder(msg.sender, user, currentIndex, takenRawAmount, options);
        }
        outputAmount -= _calculateTakerFeeAmount(outputAmount, true);
    }

    function _makeOrder(
        address user,
        uint16 priceIndex,
        uint64 rawAmount,
        uint32 claimBounty,
        bool isBid,
        uint8 options
    ) internal returns (uint256 requiredAmount, uint256 orderIndex) {
        if (isBid) {
            _addIndexToHeap(_bidHeap, ~priceIndex);
        } else {
            _addIndexToHeap(_askHeap, priceIndex);
        }

        Queue storage queue = _getQueue(isBid, priceIndex);
        orderIndex = queue.index;
        if (orderIndex >= _MAX_ORDER) {
            OrderKey memory staleOrderKey;
            unchecked {
                staleOrderKey = OrderKey(isBid, priceIndex, orderIndex - _MAX_ORDER);
            }
            uint64 staleOrderAmount = _orders[staleOrderKey.encode()].amount;
            if (staleOrderAmount > 0) {
                uint64 claimedRawAmount = _calculateClaimableRawAmount(queue, staleOrderAmount, staleOrderKey);
                if (claimedRawAmount != staleOrderAmount) {
                    revert Errors.CloberError(Errors.QUEUE_REPLACE_FAILED);
                }
            }
        }

        uint64 staleOrderedAmount = queue.tree.get(orderIndex & _MAX_ORDER_M);
        if (staleOrderedAmount > 0) {
            mapping(uint16 => uint256) storage claimable = _getClaimable(isBid);
            (uint16 groupIndex, uint8 elementIndex) = _splitClaimableIndex(priceIndex);
            claimable[groupIndex] = claimable[groupIndex].sub64Unsafe(elementIndex, staleOrderedAmount);
        }
        queue.index = orderIndex + 1;
        queue.tree.update(orderIndex & _MAX_ORDER_M, rawAmount);
        _orders[OrderKeyUtils.encode(isBid, priceIndex, orderIndex)] = Order({
            claimBounty: claimBounty,
            amount: rawAmount,
            owner: user
        });

        requiredAmount = isBid ? rawToQuote(rawAmount) : rawToBase(rawAmount, priceIndex, true);
        emit MakeOrder(msg.sender, user, rawAmount, claimBounty, orderIndex, priceIndex, options);
    }

    function _calculateClaimableRawAmount(
        Queue storage queue,
        uint64 orderAmount,
        OrderKey memory orderKey
    ) private view returns (uint64 claimableRawAmount) {
        if (orderKey.orderIndex + _MAX_ORDER < queue.index) {
            // replaced order
            return orderAmount;
        }
        (uint16 groupIndex, uint8 elementIndex) = _splitClaimableIndex(orderKey.priceIndex);
        uint64 totalClaimable = _getClaimable(orderKey.isBid)[groupIndex].get64Unsafe(elementIndex).toClean();
        uint64 rangeRight = _getClaimRangeRight(queue, orderKey.orderIndex);

        if (rangeRight >= totalClaimable + orderAmount) return 0;
        if (rangeRight <= totalClaimable) {
            claimableRawAmount = orderAmount;
        } else {
            claimableRawAmount = totalClaimable + orderAmount - rangeRight;
        }
    }

    // @dev Always check if `mOrder.amount == 0` before calling this function
    function _claim(
        Queue storage queue,
        Order memory mOrder,
        OrderKey memory orderKey,
        address claimer
    )
        private
        returns (
            uint256 transferAmount,
            uint256 minusFee,
            uint64 claimedRawAmount
        )
    {
        uint256 claimBounty;

        claimedRawAmount = _calculateClaimableRawAmount(queue, mOrder.amount, orderKey);
        if (claimedRawAmount == 0) return (0, 0, 0);
        if (claimedRawAmount == mOrder.amount) {
            // claiming fully
            claimBounty = _CLAIM_BOUNTY_UNIT * mOrder.claimBounty;
            _burnToken(orderKey.encode());
        }

        uint256 takerFeeAmount;
        int256 makerFeeAmount;
        (transferAmount, makerFeeAmount, takerFeeAmount) = _calculateClaimableAmountAndFees(
            orderKey.isBid,
            claimedRawAmount,
            orderKey.priceIndex
        );

        emit ClaimOrder(
            claimer,
            mOrder.owner,
            claimedRawAmount,
            claimBounty,
            orderKey.orderIndex,
            orderKey.priceIndex,
            orderKey.isBid
        );

        uint256 feeAmountAbs = uint256(makerFeeAmount > 0 ? makerFeeAmount : -makerFeeAmount);
        if (makerFeeAmount > 0) {
            _addToFeeBalance(!orderKey.isBid, takerFeeAmount);
            _addToFeeBalance(orderKey.isBid, feeAmountAbs);
            // minusFee will be zero when makerFee is positive
        } else {
            // If the order is bid, 'minusFee' should be quote
            _addToFeeBalance(!orderKey.isBid, takerFeeAmount - feeAmountAbs);
            minusFee = feeAmountAbs;
        }
    }

    function _addToFeeBalance(bool isBase, uint256 feeAmount) internal {
        // Protocol should collect fees before overflow
        if (isBase) {
            _baseFeeBalance += uint128(feeAmount);
        } else {
            _quoteFeeBalance += uint128(feeAmount);
        }
    }

    function _addIndexToHeap(OctopusHeap.Core storage heap, uint16 index) internal {
        if (!heap.has(index)) {
            heap.push(index);
        }
    }

    function _callback(
        IERC20 inputToken,
        IERC20 outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 bountyRefundAmount,
        bytes calldata data
    ) internal {
        uint256 beforeInputBalance = _thisBalance(inputToken);
        CloberMarketSwapCallbackReceiver(msg.sender).cloberMarketSwapCallback{value: bountyRefundAmount}(
            address(inputToken),
            address(outputToken),
            inputAmount,
            outputAmount,
            data
        );

        if (_thisBalance(inputToken) < beforeInputBalance + inputAmount) {
            revert Errors.CloberError(Errors.INSUFFICIENT_BALANCE);
        }
    }

    function _thisBalance(IERC20 token) internal view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function _transferToken(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            token.safeTransfer(to, amount);
        }
    }

    function _sendGWeiValue(address to, uint256 amountInGWei) internal {
        if (amountInGWei > 0) {
            (bool success, ) = to.call{value: amountInGWei * _CLAIM_BOUNTY_UNIT}("");
            if (!success) {
                revert Errors.CloberError(Errors.FAILED_TO_SEND_VALUE);
            }
        }
    }

    function collectFees(address token, address destination) external nonReentrant {
        address treasury = _factory.daoTreasury();
        address quote = address(_quoteToken);
        if ((token != quote && token != address(_baseToken)) || (destination != treasury && destination != _host())) {
            revert Errors.CloberError(Errors.ACCESS);
        }
        uint256 amount;
        if (token == quote) {
            unchecked {
                amount = _quoteFeeBalance - 1;
            }
            _quoteFeeBalance = 1; // leave it as dirty
        } else {
            amount = _baseFeeBalance;
            _baseFeeBalance = 0;
        }
        // rounding up protocol fee
        uint256 protocolFeeAmount = Math.divide(amount * _PROTOCOL_FEE, _FEE_PRECISION, true);
        uint256 hostFeeAmount;
        unchecked {
            // `protocolFeeAmount` is always less than or equal to `amount`: _PROTOCOL_FEE < _FEE_PRECISION
            hostFeeAmount = amount - protocolFeeAmount;
        }
        (
            mapping(address => uint256) storage remainFees,
            mapping(address => uint256) storage transferFees,
            uint256 transferAmount,
            uint256 remainAmount
        ) = destination == treasury
                ? (uncollectedHostFees, uncollectedProtocolFees, protocolFeeAmount, hostFeeAmount)
                : (uncollectedProtocolFees, uncollectedHostFees, hostFeeAmount, protocolFeeAmount);
        transferAmount += transferFees[token];
        transferFees[token] = 0;
        remainFees[token] += remainAmount;

        _transferToken(IERC20(token), destination, transferAmount);
    }

    function _host() internal view returns (address) {
        return _factory.getMarketHost(address(this));
    }

    function _mintToken(
        address to,
        bool isBid,
        uint16 priceIndex,
        uint256 orderIndex
    ) internal {
        CloberOrderNFT(orderToken).onMint(to, OrderKeyUtils.encode(isBid, priceIndex, orderIndex));
    }

    function _burnToken(uint256 orderId) internal {
        CloberOrderNFT(orderToken).onBurn(orderId);
        _orders[orderId].owner = address(0);
    }

    function changeOrderOwner(OrderKey calldata orderKey, address newOwner) external nonReentrant revertOnDelegateCall {
        if (msg.sender != orderToken) {
            revert Errors.CloberError(Errors.ACCESS);
        }
        // Even though the orderIndex of the orderKey is always valid,
        // it would be prudent to verify its validity to ensure compatibility with any future changes.
        _getOrder(orderKey).owner = newOwner;
    }
}

// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "../Errors.sol";

abstract contract GeometricPriceBook {
    uint256 private immutable _a;
    uint256 private immutable _r0;
    uint256 private immutable _r1;
    uint256 private immutable _r2;
    uint256 private immutable _r3;
    uint256 private immutable _r4;
    uint256 private immutable _r5;
    uint256 private immutable _r6;
    uint256 private immutable _r7;
    uint256 private immutable _r8;
    uint256 private immutable _r9;
    uint256 private immutable _r10;
    uint256 private immutable _r11;
    uint256 private immutable _r12;
    uint256 private immutable _r13;
    uint256 private immutable _r14;
    uint256 private immutable _r15;
    uint256 private immutable _r16;

    constructor(uint128 a_, uint128 r_) {
        uint256 castedR = uint256(r_);
        if ((a_ * castedR) / 10**18 <= a_) {
            revert Errors.CloberError(Errors.INVALID_COEFFICIENTS);
        }
        _a = a_;
        _r0 = ((1 << 64) * castedR) / 10**18;
        _r1 = (_r0 * _r0) >> 64;
        _r2 = (_r1 * _r1) >> 64;
        _r3 = (_r2 * _r2) >> 64;
        _r4 = (_r3 * _r3) >> 64;
        _r5 = (_r4 * _r4) >> 64;
        _r6 = (_r5 * _r5) >> 64;
        _r7 = (_r6 * _r6) >> 64;
        _r8 = (_r7 * _r7) >> 64;
        _r9 = (_r8 * _r8) >> 64;
        _r10 = (_r9 * _r9) >> 64;
        _r11 = (_r10 * _r10) >> 64;
        _r12 = (_r11 * _r11) >> 64;
        _r13 = (_r12 * _r12) >> 64;
        _r14 = (_r13 * _r13) >> 64;
        _r15 = (_r14 * _r14) >> 64;
        _r16 = (_r15 * _r15) >> 64;

        if (_r16 * _a >= 1 << 192) {
            revert Errors.CloberError(Errors.INVALID_COEFFICIENTS);
        }
    }

    function _indexToPrice(uint16 priceIndex) internal view virtual returns (uint128) {
        uint256 price;
        unchecked {
            price = (priceIndex & 0x8000 != 0) ? (_a * _r15) >> 64 : _a;
            if (priceIndex & 0x4000 != 0) price = (price * _r14) >> 64;
            if (priceIndex & 0x2000 != 0) price = (price * _r13) >> 64;
            if (priceIndex & 0x1000 != 0) price = (price * _r12) >> 64;
            if (priceIndex & 0x800 != 0) price = (price * _r11) >> 64;
            if (priceIndex & 0x400 != 0) price = (price * _r10) >> 64;
            if (priceIndex & 0x200 != 0) price = (price * _r9) >> 64;
            if (priceIndex & 0x100 != 0) price = (price * _r8) >> 64;
            if (priceIndex & 0x80 != 0) price = (price * _r7) >> 64;
            if (priceIndex & 0x40 != 0) price = (price * _r6) >> 64;
            if (priceIndex & 0x20 != 0) price = (price * _r5) >> 64;
            if (priceIndex & 0x10 != 0) price = (price * _r4) >> 64;
            if (priceIndex & 0x8 != 0) price = (price * _r3) >> 64;
            if (priceIndex & 0x4 != 0) price = (price * _r2) >> 64;
            if (priceIndex & 0x2 != 0) price = (price * _r1) >> 64;
            if (priceIndex & 0x1 != 0) price = (price * _r0) >> 64;
        }

        return uint128(price);
    }

    function _priceToIndex(uint128 price, bool roundingUp)
        internal
        view
        virtual
        returns (uint16 index, uint128 correctedPrice)
    {
        if (price < _a || price >= (_a * _r16) >> 64) {
            revert Errors.CloberError(Errors.INVALID_PRICE);
        }
        index = 0;
        uint256 _correctedPrice = _a;
        uint256 shiftedPrice = (uint256(price) + 1) << 64;

        unchecked {
            if (shiftedPrice > _r15 * _correctedPrice) {
                index = index | 0x8000;
                _correctedPrice = (_correctedPrice * _r15) >> 64;
            }
            if (shiftedPrice > _r14 * _correctedPrice) {
                index = index | 0x4000;
                _correctedPrice = (_correctedPrice * _r14) >> 64;
            }
            if (shiftedPrice > _r13 * _correctedPrice) {
                index = index | 0x2000;
                _correctedPrice = (_correctedPrice * _r13) >> 64;
            }
            if (shiftedPrice > _r12 * _correctedPrice) {
                index = index | 0x1000;
                _correctedPrice = (_correctedPrice * _r12) >> 64;
            }
            if (shiftedPrice > _r11 * _correctedPrice) {
                index = index | 0x0800;
                _correctedPrice = (_correctedPrice * _r11) >> 64;
            }
            if (shiftedPrice > _r10 * _correctedPrice) {
                index = index | 0x0400;
                _correctedPrice = (_correctedPrice * _r10) >> 64;
            }
            if (shiftedPrice > _r9 * _correctedPrice) {
                index = index | 0x0200;
                _correctedPrice = (_correctedPrice * _r9) >> 64;
            }
            if (shiftedPrice > _r8 * _correctedPrice) {
                index = index | 0x0100;
                _correctedPrice = (_correctedPrice * _r8) >> 64;
            }
            if (shiftedPrice > _r7 * _correctedPrice) {
                index = index | 0x0080;
                _correctedPrice = (_correctedPrice * _r7) >> 64;
            }
            if (shiftedPrice > _r6 * _correctedPrice) {
                index = index | 0x0040;
                _correctedPrice = (_correctedPrice * _r6) >> 64;
            }
            if (shiftedPrice > _r5 * _correctedPrice) {
                index = index | 0x0020;
                _correctedPrice = (_correctedPrice * _r5) >> 64;
            }
            if (shiftedPrice > _r4 * _correctedPrice) {
                index = index | 0x0010;
                _correctedPrice = (_correctedPrice * _r4) >> 64;
            }
            if (shiftedPrice > _r3 * _correctedPrice) {
                index = index | 0x0008;
                _correctedPrice = (_correctedPrice * _r3) >> 64;
            }
            if (shiftedPrice > _r2 * _correctedPrice) {
                index = index | 0x0004;
                _correctedPrice = (_correctedPrice * _r2) >> 64;
            }
            if (shiftedPrice > _r1 * _correctedPrice) {
                index = index | 0x0002;
                _correctedPrice = (_correctedPrice * _r1) >> 64;
            }
            if (shiftedPrice > _r0 * _correctedPrice) {
                index = index | 0x0001;
                _correctedPrice = (_correctedPrice * _r0) >> 64;
            }
        }
        if (roundingUp && _correctedPrice < price) {
            unchecked {
                if (index == type(uint16).max) {
                    revert Errors.CloberError(Errors.INVALID_PRICE);
                }
                index += 1;
            }
            correctedPrice = _indexToPrice(index);
        } else {
            correctedPrice = uint128(_correctedPrice);
        }
    }
}

// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

library Errors {
    error CloberError(uint256 errorCode); // 0x1d25260a

    uint256 public constant ACCESS = 0;
    uint256 public constant FAILED_TO_SEND_VALUE = 1;
    uint256 public constant INSUFFICIENT_BALANCE = 2;
    uint256 public constant OVERFLOW_UNDERFLOW = 3;
    uint256 public constant EMPTY_INPUT = 4;
    uint256 public constant DELEGATE_CALL = 5;
    uint256 public constant DEADLINE = 6;
    uint256 public constant NOT_IMPLEMENTED_INTERFACE = 7;
    uint256 public constant INVALID_FEE = 8;
    uint256 public constant REENTRANCY = 9;
    uint256 public constant POST_ONLY = 10;
    uint256 public constant SLIPPAGE = 11;
    uint256 public constant QUEUE_REPLACE_FAILED = 12;
    uint256 public constant INVALID_COEFFICIENTS = 13;
    uint256 public constant INVALID_ID = 14;
    uint256 public constant INVALID_QUOTE_TOKEN = 15;
    uint256 public constant INVALID_PRICE = 16;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface CloberMarketFactory {
    /**
     * @notice Emitted when a new volatile market is created.
     * @param market The address of the new market.
     * @param orderToken The address of the new market's order token.
     * @param quoteToken The address of the new market's quote token.
     * @param baseToken The address of the new market's base token.
     * @param quoteUnit The amount that one raw amount represents in quote tokens.
     * @param nonce The nonce for this market.
     * @param makerFee The maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @param takerFee The taker fee.
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @param a The scale factor of the price points.
     * @param r The common ratio between price points.
     */
    event CreateVolatileMarket(
        address indexed market,
        address orderToken,
        address quoteToken,
        address baseToken,
        uint256 quoteUnit,
        uint256 nonce,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 r
    );

    /**
     * @notice Emitted when a new stable market is created.
     * @param market The address of the new market.
     * @param orderToken The address of the new market's order token.
     * @param quoteToken The address of the new market's quote token.
     * @param baseToken The address of the new market's base token.
     * @param quoteUnit The amount that one raw amount represents in quote tokens.
     * @param nonce The nonce for this market.
     * @param makerFee The maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @param takerFee The taker fee.
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @param a The starting price point.
     * @param d The common difference between price points.
     */
    event CreateStableMarket(
        address indexed market,
        address orderToken,
        address quoteToken,
        address baseToken,
        uint256 quoteUnit,
        uint256 nonce,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 d
    );

    /**
     * @notice Emitted when the address of the owner has changed.
     * @param previousOwner The address of the previous owner.
     * @param newOwner The address of the new owner.
     */
    event ChangeOwner(address previousOwner, address newOwner);

    /**
     * @notice Emitted when the DAO Treasury address has changed.
     * @param previousTreasury The address of the previous DAO Treasury.
     * @param newTreasury The address of the new DAO Treasury.
     */
    event ChangeDaoTreasury(address previousTreasury, address newTreasury);

    /**
     * @notice Emitted when the host address has changed.
     * @param market The address of the market that had a change of hosts.
     * @param previousHost The address of the previous host.
     * @param newHost The address of a new host.
     */
    event ChangeHost(address indexed market, address previousHost, address newHost);

    /**
     * @notice Returns the address of the VolatileMarketDeployer.
     * @return The address of the VolatileMarketDeployer.
     */
    function volatileMarketDeployer() external view returns (address);

    /**
     * @notice Returns the address of the StableMarketDeployer.
     * @return The address of the StableMarketDeployer.
     */
    function stableMarketDeployer() external view returns (address);

    /**
     * @notice Returns the address of the OrderCanceler.
     * @return The address of the OrderCanceler.
     */
    function canceler() external view returns (address);

    /**
     * @notice Returns whether the specified token address has been registered as a quote token.
     * @param token The address of the token to check.
     * @return bool Whether the token is registered as a quote token.
     */
    function registeredQuoteTokens(address token) external view returns (bool);

    /**
     * @notice Returns the address of the factory owner
     * @return The address of the factory owner
     */
    function owner() external view returns (address);

    /**
     * @notice Returns the address of the factory owner candidate
     * @return The address of the factory owner candidate
     */
    function futureOwner() external view returns (address);

    /**
     * @notice Returns the address of the DAO Treasury
     * @return The address of the DAO Treasury
     */
    function daoTreasury() external view returns (address);

    /**
     * @notice Returns the current nonce
     * @return The current nonce
     */
    function nonce() external view returns (uint256);

    /**
     * @notice Creates a new market with a VolatilePriceBook.
     * @param host The address of the new market's host.
     * @param quoteToken The address of the new market's quote token.
     * @param baseToken The address of the new market's base token.
     * @param quoteUnit The amount that one raw amount represents in quote tokens.
     * @param makerFee The maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @param takerFee The taker fee.
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @param a The scale factor of the price points.
     * @param r The common ratio between price points.
     * @return The address of the created market.
     */
    function createVolatileMarket(
        address host,
        address quoteToken,
        address baseToken,
        uint96 quoteUnit,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 r
    ) external returns (address);

    /**
     * @notice Creates a new market with a StablePriceBook
     * @param host The address of the new market's host
     * @param quoteToken The address of the new market's quote token
     * @param baseToken The address of the new market's base token
     * @param quoteUnit The amount that one raw amount represents in quote tokens
     * @param makerFee The maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @param takerFee The taker fee.
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @param a The starting price point.
     * @param d The common difference between price points.
     * @return The address of the created market.
     */
    function createStableMarket(
        address host,
        address quoteToken,
        address baseToken,
        uint96 quoteUnit,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 d
    ) external returns (address);

    /**
     * @notice Change the DAO Treasury address.
     * @dev Only the factory owner can call this function.
     * @param treasury The new address of the DAO Treasury.
     */
    function changeDaoTreasury(address treasury) external;

    /**
     * @notice Sets the new owner address for this contract.
     * @dev Only the factory owner can call this function.
     * @param newOwner The new owner address for this contract.
     */
    function prepareChangeOwner(address newOwner) external;

    /**
     * @notice Changes the owner of this contract to the address set by `prepareChangeOwner`.
     * @dev Only the future owner can call this function.
     */
    function executeChangeOwner() external;

    /**
     * @notice Returns the host address of the given market.
     * @param market The address of the target market.
     * @return The host address of the market.
     */
    function getMarketHost(address market) external view returns (address);

    /**
     * @notice Prepares to set a new host address for the given market address.
     * @dev Only the market host can call this function.
     * @param market The market address for which the host will be changed.
     * @param newHost The new host address for the given market.
     */
    function prepareHandOverHost(address market, address newHost) external;

    /**
     * @notice Changes the host address of the given market to the address set by `prepareHandOverHost`.
     * @dev Only the future market host can call this function.
     * @param market The market address for which the host will be changed.
     */
    function executeHandOverHost(address market) external;

    /**
     * @notice Computes the OrderNFT contract address.
     * @param marketNonce The nonce to compute the OrderNFT contract address via CREATE2.
     */
    function computeTokenAddress(uint256 marketNonce) external view returns (address);

    enum MarketType {
        NONE,
        VOLATILE,
        STABLE
    }

    /**
     * @notice MarketInfo struct that contains information about a market.
     * @param host The address of the market host.
     * @param marketType The market type, either VOLATILE or STABLE.
     * @param a The starting price point.
     * @param factor The either the common ratio or common difference between price points.
     * @param futureHost The address set by `prepareHandOverHost` to change the market host.
     */
    struct MarketInfo {
        address host;
        MarketType marketType;
        uint128 a;
        uint128 factor;
        address futureHost;
    }

    /**
     * @notice Returns key information about the market.
     * @param market The address of the market.
     * @return marketInfo The MarketInfo structure of the given market.
     */
    function getMarketInfo(address market) external view returns (MarketInfo memory marketInfo);

    /**
     * @notice Allows the specified token to be used as the quote token.
     * @dev Only the factory owner can call this function.
     * @param token The address of the token to register.
     */
    function registerQuoteToken(address token) external;

    /**
     * @notice Revokes the token's right to be used as a quote token.
     * @dev Only the factory owner can call this function.
     * @param token The address of the token to unregister.
     */
    function unregisterQuoteToken(address token) external;

    /**
     * @notice Returns the order token name.
     * @param quoteToken The address of the market's quote token.
     * @param baseToken The address of the market's base token.
     * @param marketNonce The market nonce.
     * @return The order token name.
     */
    function formatOrderTokenName(
        address quoteToken,
        address baseToken,
        uint256 marketNonce
    ) external view returns (string memory);

    /**
     * @notice Returns the order token symbol.
     * @param quoteToken The address of a new market's quote token.
     * @param baseToken The address of a new market's base token.
     * @param marketNonce The market nonce.
     * @return The order token symbol.
     */
    function formatOrderTokenSymbol(
        address quoteToken,
        address baseToken,
        uint256 marketNonce
    ) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface CloberMarketSwapCallbackReceiver {
    /**
     * @notice Contracts placing orders on the OrderBook must implement this method.
     * In this method, the contract has to send the required token, or the transaction will revert.
     * If there is a claim bounty to be refunded, it will be transferred via msg.value.
     * @param inputToken The address of the token the user has to send.
     * @param outputToken The address of the token the user has received.
     * @param inputAmount The amount of tokens the user has to send.
     * @param outputAmount The amount of tokens the user has received.
     * @param data The user's custom callback data.
     */
    function cloberMarketSwapCallback(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        bytes calldata data
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface CloberMarketFlashCallbackReceiver {
    /**
     * @notice To use `flash()`, the user must implement this method.
     * The user will receive the requested tokens via the `OrderBook.flash()` function before this method.
     * In this method, the user must repay the loaned tokens plus fees, or the transaction will revert.
     * @param quoteToken The quote token address.
     * @param baseToken The base token address.
     * @param quoteAmount The amount of quote tokens the user has borrowed.
     * @param baseAmount The amount of base tokens the user has borrowed.
     * @param quoteFeeAmount The fee amount in quote tokens for borrowing quote tokens.
     * @param baseFeeAmount The fee amount in base tokens for borrowing base tokens.
     * @param data The user's custom callback data.
     */
    function cloberMarketFlashCallback(
        address quoteToken,
        address baseToken,
        uint256 quoteAmount,
        uint256 baseAmount,
        uint256 quoteFeeAmount,
        uint256 baseFeeAmount,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./CloberOrderKey.sol";

interface CloberOrderBook {
    /**
     * @notice Emitted when an order is created.
     * @param sender The address who sent the tokens to make the order.
     * @param user The address with the rights to claim the proceeds of the order.
     * @param rawAmount The ordered raw amount.
     * @param orderIndex The order index.
     * @param priceIndex The price book index.
     * @param options LSB: 0 - Ask, 1 - Bid.
     */
    event MakeOrder(
        address indexed sender,
        address indexed user,
        uint64 rawAmount,
        uint32 claimBounty,
        uint256 orderIndex,
        uint16 priceIndex,
        uint8 options
    );

    /**
     * @notice Emitted when an order takes from the order book.
     * @param sender The address who sent the tokens to take the order.
     * @param user The recipient address of the traded token.
     * @param priceIndex The price book index.
     * @param rawAmount The ordered raw amount.
     * @param options MSB: 0 - Limit, 1 - Market / LSB: 0 - Ask, 1 - Bid.
     */
    event TakeOrder(address indexed sender, address indexed user, uint16 priceIndex, uint64 rawAmount, uint8 options);

    /**
     * @notice Emitted when an order is canceled.
     * @param user The owner of the order.
     * @param rawAmount The raw amount remaining that was canceled.
     * @param orderIndex The order index.
     * @param priceIndex The price book index.
     * @param isBid The flag indicating whether it's a bid order or an ask order.
     */
    event CancelOrder(address indexed user, uint64 rawAmount, uint256 orderIndex, uint16 priceIndex, bool isBid);

    /**
     * @notice Emitted when the proceeds of an order is claimed.
     * @param claimer The address that initiated the claim.
     * @param user The owner of the order.
     * @param rawAmount The ordered raw amount.
     * @param bountyAmount The size of the claim bounty.
     * @param orderIndex The order index.
     * @param priceIndex The price book index.
     * @param isBase The flag indicating whether the user receives the base token or the quote token.
     */
    event ClaimOrder(
        address indexed claimer,
        address indexed user,
        uint64 rawAmount,
        uint256 bountyAmount,
        uint256 orderIndex,
        uint16 priceIndex,
        bool isBase
    );

    /**
     * @notice Emitted when a flash-loan is taken.
     * @param caller The caller address of the flash-loan.
     * @param borrower The address of the flash loan token receiver.
     * @param quoteAmount The amount of quote tokens the user has borrowed.
     * @param baseAmount The amount of base tokens the user has borrowed.
     * @param earnedQuote The amount of quote tokens the protocol earned in quote tokens.
     * @param earnedBase The amount of base tokens the protocol earned in base tokens.
     */
    event Flash(
        address indexed caller,
        address indexed borrower,
        uint256 quoteAmount,
        uint256 baseAmount,
        uint256 earnedQuote,
        uint256 earnedBase
    );

    /**
     * @notice A struct that represents an order.
     * @param amount The raw amount not filled yet. In case of a stale order, the amount not claimed yet.
     * @param claimBounty The bounty amount in gwei that can be collected by the party that fully claims the order.
     * @param owner The address of the order owner.
     */
    struct Order {
        uint64 amount;
        uint32 claimBounty;
        address owner;
    }

    /**
     * @notice Take orders better or equal to the given priceIndex and make an order with the remaining tokens.
     * @dev `msg.value` will be used as the claimBounty.
     * @param user The taker/maker address.
     * @param priceIndex The price book index.
     * @param rawAmount The raw quote amount to trade, utilized by bids.
     * @param baseAmount The base token amount to trade, utilized by asks.
     * @param options LSB: 0 - Ask, 1 - Bid. Second bit: 1 - Post only.
     * @param data Custom callback data
     * @return The order index. If an order is not made `type(uint256).max` is returned instead.
     */
    function limitOrder(
        address user,
        uint16 priceIndex,
        uint64 rawAmount,
        uint256 baseAmount,
        uint8 options,
        bytes calldata data
    ) external payable returns (uint256);

    /**
     * @notice Returns the expected input amount and output amount.
     * @param limitPriceIndex The price index to take until.
     * @param rawAmount The raw amount to trade.
     * Bid & expendInput => Used as input amount.
     * Bid & !expendInput => Not used.
     * Ask & expendInput => Not used.
     * Ask & !expendInput => Used as output amount.
     * @param baseAmount The base token amount to trade.
     * Bid & expendInput => Not used.
     * Bid & !expendInput => Used as output amount.
     * Ask & expendInput => Used as input amount.
     * Ask & !expendInput => Not used.
     * @param options LSB: 0 - Ask, 1 - Bid. Second bit: 1 - expend input.
     */
    function getExpectedAmount(
        uint16 limitPriceIndex,
        uint64 rawAmount,
        uint256 baseAmount,
        uint8 options
    ) external view returns (uint256, uint256);

    /**
     * @notice Take opens orders until certain conditions are met.
     * @param user The taker address.
     * @param limitPriceIndex The price index to take until.
     * @param rawAmount The raw amount to trade.
     * This value is used as the maximum input amount by bids and minimum output amount by asks.
     * @param baseAmount The base token amount to trade.
     * This value is used as the maximum input amount by asks and minimum output amount by bids.
     * @param options LSB: 0 - Ask, 1 - Bid. Second bit: 1 - expend input.
     * @param data Custom callback data.
     */
    function marketOrder(
        address user,
        uint16 limitPriceIndex,
        uint64 rawAmount,
        uint256 baseAmount,
        uint8 options,
        bytes calldata data
    ) external;

    /**
     * @notice Cancel orders.
     * @dev The length of orderKeys must be controlled by the caller to avoid block gas limit exceeds.
     * @param receiver The address to receive canceled tokens.
     * @param orderKeys The order keys of the orders to cancel.
     */
    function cancel(address receiver, OrderKey[] calldata orderKeys) external;

    /**
     * @notice Claim the proceeds of orders.
     * @dev The length of orderKeys must be controlled by the caller to avoid block gas limit exceeds.
     * @param claimer The address to receive the claim bounties.
     * @param orderKeys The order keys of the orders to claim.
     */
    function claim(address claimer, OrderKey[] calldata orderKeys) external;

    /**
     * @notice Flash loan the tokens in the OrderBook.
     * @param borrower The address to receive the loan.
     * @param quoteAmount The quote token amount to borrow.
     * @param baseAmount The base token amount to borrow.
     * @param data The user's custom callback data.
     */
    function flash(
        address borrower,
        uint256 quoteAmount,
        uint256 baseAmount,
        bytes calldata data
    ) external;

    /**
     * @notice Returns the quote unit amount.
     * @return The amount that one raw amount represent in quote tokens.
     */
    function quoteUnit() external view returns (uint256);

    /**
     * @notice Returns the maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @return The maker fee. 100 = 1bp.
     */
    function makerFee() external view returns (int24);

    /**
     * @notice Returns the take fee
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @return The taker fee. 100 = 1bps.
     */
    function takerFee() external view returns (uint24);

    /**
     * @notice Returns the address of the order NFT contract.
     * @return The address of the order NFT contract.
     */
    function orderToken() external view returns (address);

    /**
     * @notice Returns the address of the quote token.
     * @return The address of the quote token.
     */
    function quoteToken() external view returns (address);

    /**
     * @notice Returns the address of the base token.
     * @return The address of the base token.
     */
    function baseToken() external view returns (address);

    /**
     * @notice Returns the current total open amount at the given price.
     * @param isBid The flag to choose which side to check the depth for.
     * @param priceIndex The price book index.
     * @return The total open amount.
     */
    function getDepth(bool isBid, uint16 priceIndex) external view returns (uint64);

    /**
     * @notice Returns the fee balance that has not been collected yet.
     * @return quote The current fee balance for the quote token.
     * @return base The current fee balance for the base token.
     */
    function getFeeBalance() external view returns (uint128 quote, uint128 base);

    /**
     * @notice Returns the amount of tokens that can be collected by the host.
     * @param token The address of the token to be collected.
     * @return The amount of tokens that can be collected by the host.
     */
    function uncollectedHostFees(address token) external view returns (uint256);

    /**
     * @notice Returns the amount of tokens that can be collected by the dao treasury.
     * @param token The address of the token to be collected.
     * @return The amount of tokens that can be collected by the dao treasury.
     */
    function uncollectedProtocolFees(address token) external view returns (uint256);

    /**
     * @notice Returns whether the order book is empty or not.
     * @param isBid The flag to choose which side to check the emptiness of.
     * @return Whether the order book is empty or not on that side.
     */
    function isEmpty(bool isBid) external view returns (bool);

    /**
     * @notice Returns the order information.
     * @param orderKey The order key of the order.
     * @return The order struct of the given order key.
     */
    function getOrder(OrderKey calldata orderKey) external view returns (Order memory);

    /**
     * @notice Returns the lowest ask price index or the highest bid price index.
     * @param isBid Returns the lowest ask price if false, highest bid price if true.
     * @return The current price index. If the order book is empty, it will revert.
     */
    function bestPriceIndex(bool isBid) external view returns (uint16);

    /**
     * @notice Converts a raw amount to its corresponding base amount using a given price index.
     * @param rawAmount The raw amount to be converted.
     * @param priceIndex The index of the price to be used for the conversion.
     * @param roundingUp Specifies whether the result should be rounded up or down.
     * @return The converted base amount.
     */
    function rawToBase(
        uint64 rawAmount,
        uint16 priceIndex,
        bool roundingUp
    ) external view returns (uint256);

    /**
     * @notice Converts a raw amount to its corresponding quote amount.
     * @param rawAmount The raw amount to be converted.
     * @return The converted quote amount.
     */
    function rawToQuote(uint64 rawAmount) external view returns (uint256);

    /**
     * @notice Converts a base amount to its corresponding raw amount using a given price index.
     * @param baseAmount The base amount to be converted.
     * @param priceIndex The index of the price to be used for the conversion.
     * @param roundingUp Specifies whether the result should be rounded up or down.
     * @return The converted raw amount.
     */
    function baseToRaw(
        uint256 baseAmount,
        uint16 priceIndex,
        bool roundingUp
    ) external view returns (uint64);

    /**
     * @notice Converts a quote amount to its corresponding raw amount.
     * @param quoteAmount The quote amount to be converted.
     * @param roundingUp Specifies whether the result should be rounded up or down.
     * @return The converted raw amount.
     */
    function quoteToRaw(uint256 quoteAmount, bool roundingUp) external view returns (uint64);

    /**
     * @notice Collects fees for either the protocol or host.
     * @param token The token address to collect. It should be the quote token or the base token.
     * @param destination The destination address to transfer fees.
     * It should be the dao treasury address or the host address.
     */
    function collectFees(address token, address destination) external;

    /**
     * @notice Change the owner of the order.
     * @dev Only the OrderToken contract can call this function.
     * @param orderKey The order key of the order.
     * @param newOwner The new owner address.
     */
    function changeOrderOwner(OrderKey calldata orderKey, address newOwner) external;
}

// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

library Math {
    function divide(
        uint256 a,
        uint256 b,
        bool roundingUp
    ) internal pure returns (uint256 ret) {
        // In the OrderBook contract code, b is never zero.
        assembly {
            ret := add(div(a, b), and(gt(mod(a, b), 0), roundingUp))
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "./CloberOrderKey.sol";

interface CloberOrderNFT is IERC721, IERC721Metadata {
    /**
     * @notice Returns the base URI for the metadata of this NFT collection.
     * @return The base URI for the metadata of this NFT collection.
     */
    function baseURI() external view returns (string memory);

    /**
     * @notice Returns the address of the market contract that manages this token.
     * @return The address of the market contract that manages this token.
     */
    function market() external view returns (address);

    /**
     * @notice Returns the address of contract owner.
     * @return The address of the contract owner.
     */
    function owner() external view returns (address);

    /**
     * @notice Called when a new token is minted.
     * @param to The receiver address of the minted token.
     * @param tokenId The id of the token minted.
     */
    function onMint(address to, uint256 tokenId) external;

    /**
     * @notice Called when a token is burned.
     * @param tokenId The id of the token burned.
     */
    function onBurn(uint256 tokenId) external;

    /**
     * @notice Changes the base URI for the metadata of this NFT collection.
     * @param newBaseURI The new base URI for the metadata of this NFT collection.
     */
    function changeBaseURI(string memory newBaseURI) external;

    /**
     * @notice Decodes a token id into an order key.
     * @param id The id to decode.
     * @return The order key corresponding to the given id.
     */
    function decodeId(uint256 id) external pure returns (OrderKey memory);

    /**
     * @notice Encodes an order key to a token id.
     * @param orderKey The order key to encode.
     * @return The id corresponding to the given order key.
     */
    function encodeId(OrderKey memory orderKey) external pure returns (uint256);

    /**
     * @notice Cancels orders with token ids.
     * @dev Only the OrderCanceler can call this function.
     * @param from The address of the owner of the tokens.
     * @param tokenIds The ids of the tokens to cancel.
     * @param receiver The address to send the underlying assets to.
     */
    function cancel(
        address from,
        uint256[] calldata tokenIds,
        address receiver
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity >=0.8.0;

import "../Errors.sol";

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Clober (https://github.com/clober-dex/core/blob/main/contracts/utils/ReentrancyGuard.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 internal _locked = 1;

    modifier nonReentrant() virtual {
        if (_locked != 1) {
            revert Errors.CloberError(Errors.REENTRANCY);
        }

        _locked = 2;

        _;

        _locked = 1;
    }
}

// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "../Errors.sol";
import "../interfaces/CloberOrderKey.sol";

library OrderKeyUtils {
    function encode(OrderKey memory orderKey) internal pure returns (uint256) {
        return encode(orderKey.isBid, orderKey.priceIndex, orderKey.orderIndex);
    }

    function encode(
        bool isBid,
        uint16 priceIndex,
        uint256 orderIndex
    ) internal pure returns (uint256 id) {
        if (orderIndex > type(uint232).max) {
            revert Errors.CloberError(Errors.INVALID_ID);
        }
        assembly {
            id := add(orderIndex, add(shl(232, priceIndex), shl(248, isBid)))
        }
    }

    function decode(uint256 id) internal pure returns (OrderKey memory) {
        uint8 isBid;
        uint16 priceIndex;
        uint232 orderIndex;
        assembly {
            orderIndex := id
            priceIndex := shr(232, id)
            isBid := shr(248, id)
        }
        if (isBid > 1) {
            revert Errors.CloberError(Errors.INVALID_ID);
        }
        return OrderKey({isBid: isBid == 1, priceIndex: priceIndex, orderIndex: orderIndex});
    }
}

// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "../Errors.sol";

contract RevertOnDelegateCall {
    address private immutable _thisAddress;

    modifier revertOnDelegateCall() {
        _revertOnDelegateCall();
        _;
    }

    function _revertOnDelegateCall() internal view {
        // revert when calling this contract via DELEGATECALL
        if (address(this) != _thisAddress) {
            revert Errors.CloberError(Errors.DELEGATE_CALL);
        }
    }

    constructor() {
        _thisAddress = address(this);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "./PackedUint256.sol";
import "./SignificantBit.sol";

/**
🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙

            Octopus Heap
               by Clober

      ⢀⣀⣠⣀⣀⡀
    ⣠⣾⣿⣿⣿⣿⣿⣿⣷⣦⡀
   ⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡀   ⣠⣶⣾⣷⣶⣄
   ⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧  ⢰⣿⠟⠉⠻⣿⣿⣷
   ⠈⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⢷⣄⠘⠿   ⢸⣿⣿⡆
    ⠈⠿⣿⣿⣿⣿⣿⣀⣸⣿⣷⣤⣴⠟    ⢀⣼⣿⣿⠁
      ⠈⠙⣛⣿⣿⣿⣿⣿⣿⣿⣿⣦⣀⣀⣀⣴⣾⣿⣿⡟
   ⢀⣠⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠋⣠⣤⣀
  ⣴⣿⣿⣿⠿⠟⠛⠛⢛⣿⣿⣿⣿⣿⣿⣧⡈⠉⠁   ⠈⠉⢻⣿⣧
 ⣼⣿⣿⠋    ⢠⣾⣿⣿⠟⠉⠻⣿⣿⣿⣦⣄     ⣸⣿⣿⠃
 ⣿⣿⡇     ⣿⣿⡿⠃   ⠈⠛⢿⣿⣿⣿⣿⣶⣿⣿⣿⡿⠋
 ⢿⣿⣧⡀ ⣶⣄⠘⣿⣿⡇  ⠠⠶⣿⣶⡄⠈⠙⠛⠻⠟⠛⠛⠁
 ⠈⠻⣿⣿⣿⣿⠏ ⢻⣿⣿⣄    ⣸⣿⡇
           ⠻⣿⣿⣿⣶⣾⣿⣿⠃
            ⠈⠙⠛⠛⠛⠋

🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙
*/

library OctopusHeap {
    using PackedUint256 for uint256;
    using SignificantBit for uint256;

    error OctopusHeapError(uint256 errorCode);
    uint256 private constant _ALREADY_INITIALIZED_ERROR = 0;
    uint256 private constant _HEAP_EMPTY_ERROR = 1;
    uint256 private constant _ALREADY_EXISTS_ERROR = 2;

    uint8 private constant _BODY_PARTS = 9; // 1 head and 8 arms
    uint256 private constant _INIT_VALUE = 0xed2eb01c00;
    uint16 private constant _HEAD_SIZE = 31; // number of nodes in head
    uint16 private constant _HEAD_SIZE_P = 5;
    uint16 private constant _ROOT_HEAP_INDEX = 1; // root node index

    struct Core {
        uint256[_BODY_PARTS] heap;
        mapping(uint8 => uint256) bitmap;
    }

    function init(Core storage core) internal {
        if (core.heap[0] > 0) {
            revert OctopusHeapError(_ALREADY_INITIALIZED_ERROR);
        }
        for (uint256 i = 0; i < _BODY_PARTS; ++i) {
            core.heap[i] = _INIT_VALUE;
        }
    }

    function has(Core storage core, uint16 value) internal view returns (bool) {
        (uint8 wordIndex, uint8 bitIndex) = _split(value);
        uint256 mask = 1 << bitIndex;
        return core.bitmap[wordIndex] & mask == mask;
    }

    function isEmpty(Core storage core) internal view returns (bool) {
        return core.heap[0] == _INIT_VALUE;
    }

    function getRootWordAndHeap(Core storage core) internal view returns (uint256 word, uint256[] memory heap) {
        heap = new uint256[](9);
        for (uint256 i = 0; i < 9; ++i) {
            heap[i] = core.heap[i];
        }
        word = core.bitmap[uint8(heap[0] >> 8)];
    }

    function _split(uint16 value) private pure returns (uint8 wordIndex, uint8 bitIndex) {
        assembly {
            bitIndex := value
            wordIndex := shr(8, value)
        }
    }

    function _getWordIndex(Core storage core, uint16 heapIndex) private view returns (uint8) {
        if (heapIndex <= _HEAD_SIZE) {
            return core.heap[0].get8Unsafe(heapIndex);
        }
        return core.heap[heapIndex >> _HEAD_SIZE_P].get8Unsafe(heapIndex & _HEAD_SIZE);
    }

    function _getWordIndex(
        uint256 head,
        uint256 arm,
        uint16 heapIndex
    ) private pure returns (uint8) {
        if (heapIndex <= _HEAD_SIZE) {
            return head.get8Unsafe(heapIndex);
        }
        return arm.get8Unsafe(heapIndex & _HEAD_SIZE);
    }

    // returns new values for the part of the heap affected by updating value at heapIndex to new value
    function _updateWordIndex(
        uint256 head,
        uint256 arm,
        uint16 heapIndex,
        uint8 newWordIndex
    ) private pure returns (uint256, uint256) {
        if (heapIndex <= _HEAD_SIZE) {
            return (head.update8Unsafe(heapIndex, newWordIndex), arm);
        } else {
            return (head, arm.update8Unsafe(heapIndex & _HEAD_SIZE, newWordIndex));
        }
    }

    function _root(Core storage core) private view returns (uint8 wordIndex, uint8 bitIndex) {
        wordIndex = uint8(core.heap[0] >> 8);
        uint256 word = core.bitmap[wordIndex];
        bitIndex = word.leastSignificantBit();
    }

    function _convertRawIndexToHeapIndex(uint8 rawIndex) private pure returns (uint16) {
        unchecked {
            uint16 heapIndex = uint16(rawIndex) + 1;
            if (heapIndex <= 35) {
                return heapIndex;
            } else if (heapIndex < 64) {
                return (heapIndex & 3) + ((heapIndex >> 2) << 5) - 224;
            } else if (heapIndex < 128) {
                return (heapIndex & 7) + ((heapIndex >> 3) << 5) - 220;
            } else if (heapIndex < 256) {
                return (heapIndex & 15) + (((heapIndex >> 4)) << 5) - 212;
            } else {
                return 60;
            }
        }
    }

    function _getParentHeapIndex(uint16 heapIndex) private pure returns (uint16 parentHeapIndex) {
        if (heapIndex <= _HEAD_SIZE) {
            // current node and parent node are both on the head
            assembly {
                parentHeapIndex := shr(1, heapIndex)
            }
        } else if (heapIndex & 0x1c == 0) {
            // current node is on an arm but the parent is on the head
            assembly {
                parentHeapIndex := add(add(14, shr(4, heapIndex)), shr(1, and(heapIndex, 2)))
            }
        } else {
            // current node and parent node are both on an arm
            uint16 offset;
            assembly {
                offset := sub(and(heapIndex, 0xffe0), 0x04)
                parentHeapIndex := add(shr(1, sub(heapIndex, offset)), offset)
            }
        }
    }

    function _getLeftChildHeapIndex(uint16 heapIndex) private pure returns (uint16 childHeapIndex) {
        if (heapIndex < 16) {
            // current node and child node are both on the head
            assembly {
                childHeapIndex := shl(1, heapIndex)
            }
        } else if (heapIndex < 32) {
            // current node is on the head but the child is on an arm
            assembly {
                heapIndex := sub(heapIndex, 14)
                childHeapIndex := add(shl(1, and(heapIndex, 1)), shl(5, shr(1, heapIndex)))
            }
        } else {
            // current node and child node are both on an arm
            uint16 offset;
            assembly {
                offset := sub(and(heapIndex, 0xffe0), 0x04)
                childHeapIndex := add(shl(1, sub(heapIndex, offset)), offset)
            }
        }
    }

    function root(Core storage core) internal view returns (uint16) {
        if (isEmpty(core)) {
            revert OctopusHeapError(_HEAP_EMPTY_ERROR);
        }
        (uint8 wordIndex, uint8 bitIndex) = _root(core);
        return (uint16(wordIndex) << 8) | bitIndex;
    }

    function push(Core storage core, uint16 value) internal {
        (uint8 wordIndex, uint8 bitIndex) = _split(value);
        uint256 mask = 1 << bitIndex;

        uint256 word = core.bitmap[wordIndex];
        if (word & mask > 0) {
            revert OctopusHeapError(_ALREADY_EXISTS_ERROR);
        }
        if (word == 0) {
            uint256 head = core.heap[0];
            uint256 arm;
            uint16 heapIndex = _convertRawIndexToHeapIndex(uint8(head)); // uint8() to get length
            uint16 bodyPartIndex;
            if (heapIndex > _HEAD_SIZE) {
                bodyPartIndex = heapIndex >> _HEAD_SIZE_P;
                arm = core.heap[bodyPartIndex];
            }
            while (heapIndex != _ROOT_HEAP_INDEX) {
                uint16 parentHeapIndex = _getParentHeapIndex(heapIndex);
                uint8 parentWordIndex = _getWordIndex(head, arm, parentHeapIndex);
                if (parentWordIndex > wordIndex) {
                    (head, arm) = _updateWordIndex(head, arm, heapIndex, parentWordIndex);
                } else {
                    break;
                }
                heapIndex = parentHeapIndex;
            }
            (head, arm) = _updateWordIndex(head, arm, heapIndex, wordIndex);
            unchecked {
                if (uint8(head) == 255) {
                    core.heap[0] = head - 255; // increment length by 1
                } else {
                    core.heap[0] = head + 1; // increment length by 1
                }
            }
            if (bodyPartIndex > 0) {
                core.heap[bodyPartIndex] = arm;
            }
        }
        core.bitmap[wordIndex] = word | mask;
    }

    function _pop(
        Core storage core,
        uint256 head,
        uint256[] memory arms
    )
        private
        view
        returns (
            uint256,
            uint16,
            uint256
        )
    {
        uint8 newLength;
        uint256 arm;
        uint16 bodyPartIndex;
        unchecked {
            newLength = uint8(head) - 1;
        }
        if (newLength == 0) return (_INIT_VALUE, 0, 0);
        uint16 heapIndex = _convertRawIndexToHeapIndex(newLength);
        uint8 wordIndex = arms.length == 0
            ? _getWordIndex(core, heapIndex)
            : _getWordIndex(head, arms[heapIndex >> _HEAD_SIZE_P], heapIndex);
        heapIndex = 1;
        uint16 childRawIndex = 1;
        uint16 childHeapIndex = 2;
        while (childRawIndex < newLength) {
            uint8 leftChildWordIndex = _getWordIndex(head, arm, childHeapIndex);
            uint8 rightChildWordIndex = _getWordIndex(head, arm, childHeapIndex + 1);
            if (leftChildWordIndex > wordIndex && rightChildWordIndex > wordIndex) {
                break;
            } else if (leftChildWordIndex > rightChildWordIndex) {
                (head, arm) = _updateWordIndex(head, arm, heapIndex, rightChildWordIndex);
                unchecked {
                    heapIndex = childHeapIndex + 1;
                    childRawIndex = (childRawIndex << 1) + 3; // leftChild(childRawIndex + 1)
                }
            } else {
                (head, arm) = _updateWordIndex(head, arm, heapIndex, leftChildWordIndex);
                heapIndex = childHeapIndex;
                unchecked {
                    childRawIndex = (childRawIndex << 1) + 1; // leftChild(childRawIndex)
                }
            }
            childHeapIndex = _getLeftChildHeapIndex(heapIndex);
            // child in arm
            if (childHeapIndex > _HEAD_SIZE && bodyPartIndex == 0) {
                bodyPartIndex = childHeapIndex >> _HEAD_SIZE_P;
                arm = arms.length == 0 ? core.heap[bodyPartIndex] : arms[bodyPartIndex];
            }
        }
        (head, arm) = _updateWordIndex(head, arm, heapIndex, wordIndex);
        unchecked {
            if (uint8(head) == 0) {
                head += 255; // decrement length by 1
            } else {
                --head; // decrement length by 1
            }
        }
        return (head, bodyPartIndex, arm);
    }

    function popInMemory(
        Core storage core,
        uint256 word,
        uint256[] memory heap
    ) internal view returns (uint256, uint256[] memory) {
        uint8 rootBitIndex = word.leastSignificantBit();
        uint256 mask = 1 << rootBitIndex;
        if (word != mask) return (word & (~mask), heap);
        (uint256 head, uint16 bodyPartIndex, uint256 arm) = _pop(core, heap[0], heap);
        heap[0] = head;
        if (head == _INIT_VALUE) return (0, heap);
        if (bodyPartIndex > 0) {
            heap[bodyPartIndex] = arm;
        }
        return (core.bitmap[uint8(head >> 8)], heap);
    }

    function pop(Core storage core) internal {
        (uint8 rootWordIndex, uint8 rootBitIndex) = _root(core);
        uint256 mask = 1 << rootBitIndex;
        uint256 word = core.bitmap[rootWordIndex];
        if (word == mask) {
            (uint256 head, uint16 bodyPartIndex, uint256 arm) = _pop(core, core.heap[0], new uint256[](0));
            core.heap[0] = head;
            if (bodyPartIndex > 0) {
                core.heap[bodyPartIndex] = arm;
            }
        }
        core.bitmap[rootWordIndex] = word & (~mask);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "./PackedUint256.sol";
import "./DirtyUint64.sol";

/**
🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲

                  Segmented Segment Tree
                               by Clober

____________/\\\_______________/\\\\\____________/\\\____
 __________/\\\\\___________/\\\\////___________/\\\\\____
  ________/\\\/\\\________/\\\///______________/\\\/\\\____
   ______/\\\/\/\\\______/\\\\\\\\\\\_________/\\\/\/\\\____
    ____/\\\/__\/\\\_____/\\\\///////\\\_____/\\\/__\/\\\____
     __/\\\\\\\\\\\\\\\\_\/\\\______\//\\\__/\\\\\\\\\\\\\\\\_
      _\///////////\\\//__\//\\\______/\\\__\///////////\\\//__
       ___________\/\\\_____\///\\\\\\\\\/_____________\/\\\____
        ___________\///________\/////////_______________\///_____

          4 Layers of 64-bit nodes, hence 464

🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲
*/

library SegmentedSegmentTree {
    using PackedUint256 for uint256;
    using DirtyUint64 for uint64;

    error SegmentedSegmentTreeError(uint256 errorCode);
    uint256 private constant _INDEX_ERROR = 0;
    uint256 private constant _OVERFLOW_ERROR = 1;

    //    uint8 private constant _R = 2; // There are `2` root node groups
    //    uint8 private constant _C = 4; // There are `4` children (each child is a node group of its own) for each node
    uint8 private constant _L = 4; // There are `4` layers of node groups
    uint256 private constant _P = 4; // uint256 / uint64 = `4`
    uint256 private constant _P_M = 3; // % 4 = & `3`
    uint256 private constant _P_P = 2; // 2 ** `2` = 4
    uint256 private constant _N_P = 4; // C * P = 2 ** `4`
    uint256 private constant _MAX_NODES = 2**15; // (R * P) * ((C * P) ** (L - 1)) = `32768`
    uint256 private constant _MAX_NODES_P_MINUS_ONE = 14; // MAX_NODES / R = 2 ** `14`

    struct Core {
        mapping(uint256 => uint256)[_L] layers;
    }

    struct LayerIndex {
        uint256 group;
        uint256 node;
    }

    function get(Core storage core, uint256 index) internal view returns (uint64 ret) {
        if (index >= _MAX_NODES) {
            revert SegmentedSegmentTreeError(_INDEX_ERROR);
        }
        unchecked {
            ret = core.layers[_L - 1][index >> _P_P].get64(index & _P_M).toClean();
        }
    }

    function total(Core storage core) internal view returns (uint64) {
        return
            DirtyUint64.sumPackedUnsafe(core.layers[0][0], 0, _P) +
            DirtyUint64.sumPackedUnsafe(core.layers[0][1], 0, _P);
    }

    function query(
        Core storage core,
        uint256 left,
        uint256 right
    ) internal view returns (uint64 sum) {
        if (left == right) {
            return 0;
        }
        // right should be greater than left
        if (left >= right) {
            revert SegmentedSegmentTreeError(_INDEX_ERROR);
        }
        if (right > _MAX_NODES) {
            revert SegmentedSegmentTreeError(_INDEX_ERROR);
        }

        LayerIndex[] memory leftIndices = _getLayerIndices(left);
        LayerIndex[] memory rightIndices = _getLayerIndices(right);
        uint256 ret;
        uint256 deficit;

        unchecked {
            uint256 leftNodeIndex;
            uint256 rightNodeIndex;
            for (uint256 l = _L - 1; ; --l) {
                LayerIndex memory leftIndex = leftIndices[l];
                LayerIndex memory rightIndex = rightIndices[l];
                leftNodeIndex += leftIndex.node;
                rightNodeIndex += rightIndex.node;

                if (rightIndex.group == leftIndex.group) {
                    ret += DirtyUint64.sumPackedUnsafe(core.layers[l][leftIndex.group], leftNodeIndex, rightNodeIndex);
                    break;
                }

                if (rightIndex.group - leftIndex.group < 4) {
                    ret += DirtyUint64.sumPackedUnsafe(core.layers[l][leftIndex.group], leftNodeIndex, _P);

                    ret += DirtyUint64.sumPackedUnsafe(core.layers[l][rightIndex.group], 0, rightNodeIndex);

                    for (uint256 group = leftIndex.group + 1; group < rightIndex.group; group++) {
                        ret += DirtyUint64.sumPackedUnsafe(core.layers[l][group], 0, _P);
                    }
                    break;
                }

                if (leftIndex.group % 4 == 0) {
                    deficit += DirtyUint64.sumPackedUnsafe(core.layers[l][leftIndex.group], 0, leftNodeIndex);
                    leftNodeIndex = 0;
                } else if (leftIndex.group % 4 == 1) {
                    deficit += DirtyUint64.sumPackedUnsafe(core.layers[l][leftIndex.group - 1], 0, _P);
                    deficit += DirtyUint64.sumPackedUnsafe(core.layers[l][leftIndex.group], 0, leftNodeIndex);
                    leftNodeIndex = 0;
                } else if (leftIndex.group % 4 == 2) {
                    ret += DirtyUint64.sumPackedUnsafe(core.layers[l][leftIndex.group], leftNodeIndex, _P);
                    ret += DirtyUint64.sumPackedUnsafe(core.layers[l][leftIndex.group + 1], 0, _P);
                    leftNodeIndex = 1;
                } else {
                    ret += DirtyUint64.sumPackedUnsafe(core.layers[l][leftIndex.group], leftNodeIndex, _P);
                    leftNodeIndex = 1;
                }

                if (rightIndex.group % 4 == 0) {
                    ret += DirtyUint64.sumPackedUnsafe(core.layers[l][rightIndex.group], 0, rightNodeIndex);
                    rightNodeIndex = 0;
                } else if (rightIndex.group % 4 == 1) {
                    ret += DirtyUint64.sumPackedUnsafe(core.layers[l][rightIndex.group - 1], 0, _P);
                    ret += DirtyUint64.sumPackedUnsafe(core.layers[l][rightIndex.group], 0, rightNodeIndex);
                    rightNodeIndex = 0;
                } else if (rightIndex.group % 4 == 2) {
                    deficit += DirtyUint64.sumPackedUnsafe(core.layers[l][rightIndex.group], rightNodeIndex, _P);
                    deficit += DirtyUint64.sumPackedUnsafe(core.layers[l][rightIndex.group + 1], 0, _P);
                    rightNodeIndex = 1;
                } else {
                    deficit += DirtyUint64.sumPackedUnsafe(core.layers[l][rightIndex.group], rightNodeIndex, _P);
                    rightNodeIndex = 1;
                }
            }
            ret -= deficit;
        }
        sum = uint64(ret);
    }

    function update(
        Core storage core,
        uint256 index,
        uint64 value
    ) internal returns (uint64 replaced) {
        if (index >= _MAX_NODES) {
            revert SegmentedSegmentTreeError(_INDEX_ERROR);
        }
        LayerIndex[] memory indices = _getLayerIndices(index);
        unchecked {
            LayerIndex memory bottomIndex = indices[_L - 1];
            replaced = core.layers[_L - 1][bottomIndex.group].get64Unsafe(bottomIndex.node).toClean();
            if (replaced >= value) {
                uint64 diff = replaced - value;
                for (uint256 l = 0; l < _L; ++l) {
                    LayerIndex memory layerIndex = indices[l];
                    uint256 node = core.layers[l][layerIndex.group];
                    core.layers[l][layerIndex.group] = node.update64(
                        layerIndex.node,
                        node.get64(layerIndex.node).subClean(diff)
                    );
                }
            } else {
                uint64 diff = value - replaced;
                if (total(core) > type(uint64).max - diff) revert SegmentedSegmentTreeError(_OVERFLOW_ERROR);
                for (uint256 l = 0; l < _L; ++l) {
                    LayerIndex memory layerIndex = indices[l];
                    uint256 node = core.layers[l][layerIndex.group];
                    core.layers[l][layerIndex.group] = node.update64(
                        layerIndex.node,
                        node.get64(layerIndex.node).addClean(diff)
                    );
                }
            }
        }
    }

    function _getLayerIndices(uint256 index) private pure returns (LayerIndex[] memory) {
        unchecked {
            LayerIndex[] memory indices = new LayerIndex[](_L);
            uint256 shifter = _MAX_NODES_P_MINUS_ONE;
            for (uint256 l = 0; l < _L; ++l) {
                indices[l] = LayerIndex({group: index >> shifter, node: (index >> (shifter - _P_P)) & _P_M});
                shifter = shifter - _N_P;
            }
            return indices;
        }
    }
}

/*
 * Segmented Segment Tree is a Segment Tree
 * that has been compressed so that `C` nodes
 * are compressed into a single uint256.
 *
 * Each node in a non-leaf node group is the sum of the
 * total sum of each child node group that it represents.
 * Each non-leaf node represents `E` node groups.
 *
 * A node group consists of `S` uint256.
 *
 * By expressing the index in `N` notation,
 * we can find the index in each respective layer
 *
 * S: Size of each node group
 * C: Compression Coefficient
 * E: Expansion Coefficient
 * L: Number of Layers
 * N: Notation, S * C * E
 *
 * `E` will not be considered for this version of the implementation. (E = 2)
 */

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

/**
 * @notice A struct that represents a unique key for an order.
 * @param isBid The flag indicating whether it's a bid order or an ask order.
 * @param priceIndex The price book index.
 * @param orderIndex The order index.
 */
struct OrderKey {
    bool isBid;
    uint16 priceIndex;
    uint256 orderIndex;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

library PackedUint256 {
    error PackedUint256Error(uint256 errorCode);
    uint256 private constant _UINT8_INDEX_ERROR = 0;
    uint256 private constant _UINT16_INDEX_ERROR = 1;
    uint256 private constant _UINT32_INDEX_ERROR = 2;
    uint256 private constant _UINT64_INDEX_ERROR = 3;

    uint256 private constant _MAX_UINT64 = type(uint64).max;
    uint256 private constant _MAX_UINT32 = type(uint32).max;
    uint256 private constant _MAX_UINT16 = type(uint16).max;
    uint256 private constant _MAX_UINT8 = type(uint8).max;

    function get8Unsafe(uint256 packed, uint256 index) internal pure returns (uint8 ret) {
        assembly {
            ret := shr(shl(3, index), packed)
        }
    }

    function get8(uint256 packed, uint256 index) internal pure returns (uint8 ret) {
        if (index > 31) {
            revert PackedUint256Error(_UINT8_INDEX_ERROR);
        }
        assembly {
            ret := shr(shl(3, index), packed)
        }
    }

    function get16Unsafe(uint256 packed, uint256 index) internal pure returns (uint16 ret) {
        assembly {
            ret := shr(shl(4, index), packed)
        }
    }

    function get16(uint256 packed, uint256 index) internal pure returns (uint16 ret) {
        if (index > 15) {
            revert PackedUint256Error(_UINT16_INDEX_ERROR);
        }
        assembly {
            ret := shr(shl(4, index), packed)
        }
    }

    function get32Unsafe(uint256 packed, uint256 index) internal pure returns (uint32 ret) {
        assembly {
            ret := shr(shl(5, index), packed)
        }
    }

    function get32(uint256 packed, uint256 index) internal pure returns (uint32 ret) {
        if (index > 7) {
            revert PackedUint256Error(_UINT32_INDEX_ERROR);
        }
        assembly {
            ret := shr(shl(5, index), packed)
        }
    }

    function get64Unsafe(uint256 packed, uint256 index) internal pure returns (uint64 ret) {
        assembly {
            ret := shr(shl(6, index), packed)
        }
    }

    function get64(uint256 packed, uint256 index) internal pure returns (uint64 ret) {
        if (index > 3) {
            revert PackedUint256Error(_UINT64_INDEX_ERROR);
        }
        assembly {
            ret := shr(shl(6, index), packed)
        }
    }

    function add8Unsafe(
        uint256 packed,
        uint256 index,
        uint8 value
    ) internal pure returns (uint256 ret) {
        uint256 casted = value;
        assembly {
            ret := add(packed, shl(shl(3, index), casted))
        }
    }

    function add8(
        uint256 packed,
        uint256 index,
        uint8 value
    ) internal pure returns (uint256 ret) {
        if (index > 31) {
            revert PackedUint256Error(_UINT8_INDEX_ERROR);
        }
        uint8 current = get8Unsafe(packed, index);
        current += value;
        ret = update8Unsafe(packed, index, current);
    }

    function add16Unsafe(
        uint256 packed,
        uint256 index,
        uint16 value
    ) internal pure returns (uint256 ret) {
        uint256 casted = value;
        assembly {
            ret := add(packed, shl(shl(4, index), casted))
        }
    }

    function add16(
        uint256 packed,
        uint256 index,
        uint16 value
    ) internal pure returns (uint256 ret) {
        if (index > 15) {
            revert PackedUint256Error(_UINT16_INDEX_ERROR);
        }
        uint16 current = get16Unsafe(packed, index);
        current += value;
        ret = update16Unsafe(packed, index, current);
    }

    function add32Unsafe(
        uint256 packed,
        uint256 index,
        uint32 value
    ) internal pure returns (uint256 ret) {
        uint256 casted = value;
        assembly {
            ret := add(packed, shl(shl(5, index), casted))
        }
    }

    function add32(
        uint256 packed,
        uint256 index,
        uint32 value
    ) internal pure returns (uint256 ret) {
        if (index > 7) {
            revert PackedUint256Error(_UINT32_INDEX_ERROR);
        }
        uint32 current = get32Unsafe(packed, index);
        current += value;
        ret = update32Unsafe(packed, index, current);
    }

    function add64Unsafe(
        uint256 packed,
        uint256 index,
        uint64 value
    ) internal pure returns (uint256 ret) {
        uint256 casted = value;
        assembly {
            ret := add(packed, shl(shl(6, index), casted))
        }
    }

    function add64(
        uint256 packed,
        uint256 index,
        uint64 value
    ) internal pure returns (uint256 ret) {
        if (index > 3) {
            revert PackedUint256Error(_UINT64_INDEX_ERROR);
        }
        uint64 current = get64Unsafe(packed, index);
        current += value;
        ret = update64Unsafe(packed, index, current);
    }

    function sub8Unsafe(
        uint256 packed,
        uint256 index,
        uint8 value
    ) internal pure returns (uint256 ret) {
        uint256 casted = value;
        assembly {
            ret := sub(packed, shl(shl(3, index), casted))
        }
    }

    function sub8(
        uint256 packed,
        uint256 index,
        uint8 value
    ) internal pure returns (uint256 ret) {
        if (index > 31) {
            revert PackedUint256Error(_UINT8_INDEX_ERROR);
        }
        uint8 current = get8Unsafe(packed, index);
        current -= value;
        ret = update8Unsafe(packed, index, current);
    }

    function sub16Unsafe(
        uint256 packed,
        uint256 index,
        uint16 value
    ) internal pure returns (uint256 ret) {
        uint256 casted = value;
        assembly {
            ret := sub(packed, shl(shl(4, index), casted))
        }
    }

    function sub16(
        uint256 packed,
        uint256 index,
        uint16 value
    ) internal pure returns (uint256 ret) {
        if (index > 15) {
            revert PackedUint256Error(_UINT16_INDEX_ERROR);
        }
        uint16 current = get16Unsafe(packed, index);
        current -= value;
        ret = update16Unsafe(packed, index, current);
    }

    function sub32Unsafe(
        uint256 packed,
        uint256 index,
        uint32 value
    ) internal pure returns (uint256 ret) {
        uint256 casted = value;
        assembly {
            ret := sub(packed, shl(shl(5, index), casted))
        }
    }

    function sub32(
        uint256 packed,
        uint256 index,
        uint32 value
    ) internal pure returns (uint256 ret) {
        if (index > 7) {
            revert PackedUint256Error(_UINT32_INDEX_ERROR);
        }
        uint32 current = get32Unsafe(packed, index);
        current -= value;
        ret = update32Unsafe(packed, index, current);
    }

    function sub64Unsafe(
        uint256 packed,
        uint256 index,
        uint64 value
    ) internal pure returns (uint256 ret) {
        uint256 casted = value;
        assembly {
            ret := sub(packed, shl(shl(6, index), casted))
        }
    }

    function sub64(
        uint256 packed,
        uint256 index,
        uint64 value
    ) internal pure returns (uint256 ret) {
        if (index > 3) {
            revert PackedUint256Error(_UINT64_INDEX_ERROR);
        }
        uint64 current = get64Unsafe(packed, index);
        current -= value;
        ret = update64Unsafe(packed, index, current);
    }

    function update8Unsafe(
        uint256 packed,
        uint256 index,
        uint8 value
    ) internal pure returns (uint256 ret) {
        unchecked {
            index = index << 3;
            packed = packed - (packed & (_MAX_UINT8 << index));
        }
        uint256 casted = value;
        assembly {
            ret := add(packed, shl(index, casted))
        }
    }

    function update8(
        uint256 packed,
        uint256 index,
        uint8 value
    ) internal pure returns (uint256 ret) {
        if (index > 31) {
            revert PackedUint256Error(_UINT8_INDEX_ERROR);
        }
        unchecked {
            index = index << 3;
            packed = packed - (packed & (_MAX_UINT8 << index));
        }
        uint256 casted = value;
        assembly {
            ret := add(packed, shl(index, casted))
        }
    }

    function update16Unsafe(
        uint256 packed,
        uint256 index,
        uint16 value
    ) internal pure returns (uint256 ret) {
        unchecked {
            index = index << 4;
            packed = packed - (packed & (_MAX_UINT16 << index));
        }
        uint256 casted = value;
        assembly {
            ret := add(packed, shl(index, casted))
        }
    }

    function update16(
        uint256 packed,
        uint256 index,
        uint16 value
    ) internal pure returns (uint256 ret) {
        if (index > 15) {
            revert PackedUint256Error(_UINT16_INDEX_ERROR);
        }
        unchecked {
            index = index << 4;
            packed = packed - (packed & (_MAX_UINT16 << index));
        }
        uint256 casted = value;
        assembly {
            ret := add(packed, shl(index, casted))
        }
    }

    function update32Unsafe(
        uint256 packed,
        uint256 index,
        uint32 value
    ) internal pure returns (uint256 ret) {
        unchecked {
            index = index << 5;
            packed = packed - (packed & (_MAX_UINT32 << index));
        }
        uint256 casted = value;
        assembly {
            ret := add(packed, shl(index, casted))
        }
    }

    function update32(
        uint256 packed,
        uint256 index,
        uint32 value
    ) internal pure returns (uint256 ret) {
        if (index > 7) {
            revert PackedUint256Error(_UINT32_INDEX_ERROR);
        }
        unchecked {
            index = index << 5;
            packed = packed - (packed & (_MAX_UINT32 << index));
        }
        uint256 casted = value;
        assembly {
            ret := add(packed, shl(index, casted))
        }
    }

    function update64Unsafe(
        uint256 packed,
        uint256 index,
        uint64 value
    ) internal pure returns (uint256 ret) {
        unchecked {
            index = index << 6;
            packed = packed - (packed & (_MAX_UINT64 << index));
        }
        uint256 casted = value;
        assembly {
            ret := add(packed, shl(index, casted))
        }
    }

    function update64(
        uint256 packed,
        uint256 index,
        uint64 value
    ) internal pure returns (uint256 ret) {
        if (index > 3) {
            revert PackedUint256Error(_UINT64_INDEX_ERROR);
        }
        unchecked {
            index = index << 6;
            packed = packed - (packed & (_MAX_UINT64 << index));
        }
        uint256 casted = value;
        assembly {
            ret := add(packed, shl(index, casted))
        }
    }

    function total32(uint256 packed) internal pure returns (uint256) {
        unchecked {
            uint256 ret = _MAX_UINT32 & packed;
            for (uint256 i = 0; i < 7; ++i) {
                packed = packed >> 32;
                ret += _MAX_UINT32 & packed;
            }
            return ret;
        }
    }

    function total64(uint256 packed) internal pure returns (uint256) {
        unchecked {
            uint256 ret = _MAX_UINT64 & packed;
            for (uint256 i = 0; i < 3; ++i) {
                packed = packed >> 64;
                ret += _MAX_UINT64 & packed;
            }
            return ret;
        }
    }

    function sum32(
        uint256 packed,
        uint256 from,
        uint256 to
    ) internal pure returns (uint256) {
        unchecked {
            packed = packed >> (from << 5);
            uint256 ret = 0;
            for (uint256 i = from; i < to; ++i) {
                ret += _MAX_UINT32 & packed;
                packed = packed >> 32;
            }
            return ret;
        }
    }

    function sum64(
        uint256 packed,
        uint256 from,
        uint256 to
    ) internal pure returns (uint256) {
        unchecked {
            packed = packed >> (from << 6);
            uint256 ret = 0;
            for (uint256 i = from; i < to; ++i) {
                ret += _MAX_UINT64 & packed;
                packed = packed >> 64;
            }
            return ret;
        }
    }
}

// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

library SignificantBit {
    /**
     * @notice Finds the index of the least significant bit.
     * @param x The value to compute the least significant bit for. Must be a non-zero value.
     * @return ret The index of the least significant bit.
     */
    function leastSignificantBit(uint256 x) internal pure returns (uint8 ret) {
        unchecked {
            require(x > 0);
            ret = 0;
            uint256 mask = type(uint128).max;
            uint8 shifter = 128;
            while (x & 1 == 0) {
                if (x & mask == 0) {
                    ret += shifter;
                    x >>= shifter;
                }
                shifter >>= 1;
                mask >>= shifter;
            }
        }
    }
}

// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

library DirtyUint64 {
    error DirtyUint64Error(uint256 errorCode);
    uint256 private constant _OVERFLOW_ERROR = 0;
    uint256 private constant _UNDERFLOW_ERROR = 1;

    function toDirtyUnsafe(uint64 cleanUint) internal pure returns (uint64 dirtyUint) {
        assembly {
            dirtyUint := add(cleanUint, 1)
        }
    }

    function toDirty(uint64 cleanUint) internal pure returns (uint64 dirtyUint) {
        assembly {
            dirtyUint := add(cleanUint, 1)
        }
        if (dirtyUint == 0) {
            revert DirtyUint64Error(_OVERFLOW_ERROR);
        }
    }

    function toClean(uint64 dirtyUint) internal pure returns (uint64 cleanUint) {
        assembly {
            cleanUint := sub(dirtyUint, gt(dirtyUint, 0))
        }
    }

    function addClean(uint64 current, uint64 cleanUint) internal pure returns (uint64) {
        assembly {
            current := add(add(current, iszero(current)), cleanUint)
        }
        if (current < cleanUint) {
            revert DirtyUint64Error(_OVERFLOW_ERROR);
        }
        return current;
    }

    function addDirty(uint64 current, uint64 dirtyUint) internal pure returns (uint64) {
        assembly {
            current := sub(add(add(current, iszero(current)), add(dirtyUint, iszero(dirtyUint))), 1)
        }
        if (current < dirtyUint) {
            revert DirtyUint64Error(_OVERFLOW_ERROR);
        }
        return current;
    }

    function subClean(uint64 current, uint64 cleanUint) internal pure returns (uint64 ret) {
        assembly {
            current := add(current, iszero(current))
            ret := sub(current, cleanUint)
        }
        if (current < ret || ret == 0) {
            revert DirtyUint64Error(_UNDERFLOW_ERROR);
        }
    }

    function subDirty(uint64 current, uint64 dirtyUint) internal pure returns (uint64 ret) {
        assembly {
            current := add(current, iszero(current))
            ret := sub(add(current, 1), add(dirtyUint, iszero(dirtyUint)))
        }
        if (current < ret || ret == 0) {
            revert DirtyUint64Error(_UNDERFLOW_ERROR);
        }
    }

    function sumPackedUnsafe(
        uint256 packed,
        uint256 from,
        uint256 to
    ) internal pure returns (uint64 ret) {
        packed = packed >> (from << 6);
        unchecked {
            for (uint256 i = from; i < to; ++i) {
                assembly {
                    let element := and(packed, 0xffffffffffffffff)
                    ret := add(ret, add(element, iszero(element)))
                    packed := shr(64, packed)
                }
            }
        }
        assembly {
            ret := sub(ret, sub(to, from))
        }
    }
}