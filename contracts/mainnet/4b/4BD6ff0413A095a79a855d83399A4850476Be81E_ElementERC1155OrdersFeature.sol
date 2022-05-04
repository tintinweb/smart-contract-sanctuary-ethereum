// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;

import "../zero-ex/src/storage/LibCommonNftOrdersStorage.sol";
import "../zero-ex/src/storage/LibERC1155OrdersStorage.sol";
import "../zero-ex/src/features/libs/LibNFTOrder.sol";
import "../zero-ex/src/features/libs/LibSignature.sol";
import "../zero-ex/src/fixins/FixinEIP712.sol";
import "../zero-ex/src/fixins/FixinTokenSpender.sol";
import "../zero-ex/src/vendor/IEtherToken.sol";
import "../zero-ex/src/vendor/IFeeRecipient.sol";
import "../zero-ex/src/vendor/ITakerCallback.sol";
import "./interfaces/IAuthenticatedProxy.sol";
import "./interfaces/IProxyRegistry.sol";
import "./interfaces/ISharedERC1155OrdersFeature.sol";

/// @dev Feature for interacting with ERC1155 orders.
contract ElementERC1155OrdersFeature is ISharedERC1155OrdersFeature, FixinEIP712, FixinTokenSpender {

    using LibNFTOrder for LibNFTOrder.ERC1155SellOrder;
    using LibNFTOrder for LibNFTOrder.ERC1155BuyOrder;
    using LibNFTOrder for LibNFTOrder.NFTSellOrder;
    using LibNFTOrder for LibNFTOrder.NFTBuyOrder;

    /// @dev Native token pseudo-address.
    address constant internal NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @dev The WETH token contract.
    IEtherToken internal immutable WETH;
    /// @dev The implementation address of this feature.
    address internal immutable _implementation;
    /// @dev User registry
    IProxyRegistry public immutable registry;

    /// @dev The magic return value indicating the success of a `receiveZeroExFeeCallback`.
    bytes4 private constant FEE_CALLBACK_MAGIC_BYTES = IFeeRecipient.receiveZeroExFeeCallback.selector;
    /// @dev The magic return value indicating the success of a `zeroExTakerCallback`.
    bytes4 private constant TAKER_CALLBACK_MAGIC_BYTES = ITakerCallback.zeroExTakerCallback.selector;

    constructor(IEtherToken weth, IProxyRegistry registryAddress) {
        WETH = weth;
        registry = registryAddress;
        _implementation = address(this);
    }

    struct SellParams {
        uint128 sellAmount;
        uint256 tokenId;
        bool unwrapNativeToken;
        address taker;
        address currentNftOwner;
        bytes takerCallbackData;
        bytes metadata;
    }

    struct BuyParams {
        uint128 buyAmount;
        uint256 ethAvailable;
        address taker;
        bytes takerCallbackData;
    }

    /// @dev Sells an ERC1155 asset to fill the given order.
    /// @param buyOrder The ERC1155 buy order.
    /// @param signature The order signature from the maker.
    /// @param erc1155TokenId The ID of the ERC1155 asset being
    ///        sold. If the given order specifies properties,
    ///        the asset must satisfy those properties. Otherwise,
    ///        it must equal the tokenId in the order.
    /// @param erc1155SellAmount The amount of the ERC1155 asset
    ///        to sell.
    /// @param unwrapNativeToken If this parameter is true and the
    ///        ERC20 token of the order is e.g. WETH, unwraps the
    ///        token before transferring it to the taker.
    /// @param callbackData If this parameter is non-zero, invokes
    ///        `zeroExERC1155OrderCallback` on `msg.sender` after
    ///        the ERC20 tokens have been transferred to `msg.sender`
    ///        but before transferring the ERC1155 asset to the buyer.
    function sellSharedERC1155(
        LibNFTOrder.ERC1155BuyOrder memory buyOrder,
        LibSignature.Signature memory signature,
        uint256 erc1155TokenId,
        uint128 erc1155SellAmount,
        bool unwrapNativeToken,
        bytes memory callbackData
    )
        public
        override
    {
        (bytes memory takerCallbackData, bytes memory metadata) = _getCallbackDataAndMetadata(callbackData);
        _sellSharedERC1155(
            buyOrder,
            signature,
            SellParams(
                erc1155SellAmount,
                erc1155TokenId,
                unwrapNativeToken,
                msg.sender, // taker
                msg.sender, // owner
                takerCallbackData,
                metadata
            )
        );
    }

    function _getCallbackDataAndMetadata(bytes memory data) private pure returns (bytes memory takerCallbackData, bytes memory metadata) {
        if (data.length > 40) {
            // if start with "ipfs:","arweave","bzz-raw:", "filecoin", set the URI
            if ((data[0] == 0x69 && data[1] == 0x70 && data[2] == 0x66 && data[3] == 0x73) ||
                (data[0] == 0x61 && data[1] == 0x72 && data[2] == 0x77 && data[3] == 0x65) ||
                (data[0] == 0x62 && data[1] == 0x7a && data[2] == 0x7a && data[3] == 0x2d) ||
                (data[0] == 0x66 && data[1] == 0x69 && data[2] == 0x6c && data[3] == 0x65)) {
                return ("", data);
            }
        }
        return (data, "");
    }

    /// @dev Buys an ERC1155 asset by filling the given order.
    /// @param sellOrder The ERC1155 sell order.
    /// @param signature The order signature.
    /// @param erc1155BuyAmount The amount of the ERC1155 asset
    ///        to buy.
    /// @param callbackData If this parameter is non-zero, invokes
    ///        `zeroExERC1155OrderCallback` on `msg.sender` after
    ///        the ERC1155 asset has been transferred to `msg.sender`
    ///        but before transferring the ERC20 tokens to the seller.
    ///        Native tokens acquired during the callback can be used
    ///        to fill the order.
    function buySharedERC1155(
        LibNFTOrder.ERC1155SellOrder memory sellOrder,
        LibSignature.Signature memory signature,
        address taker,
        uint128 erc1155BuyAmount,
        bytes memory callbackData
    )
        public
        override
        payable
    {
        uint256 ethBalanceBefore = address(this).balance - msg.value;
        _buySharedERC1155(
            sellOrder,
            signature,
            BuyParams(
                erc1155BuyAmount,
                msg.value,
                taker,
                callbackData
            )
        );
        _transferEth(payable(msg.sender), address(this).balance - ethBalanceBefore);
    }

    /// @dev Buys multiple ERC1155 assets by filling the
    ///      given orders.
    /// @param sellOrders The ERC1155 sell orders.
    /// @param signatures The order signatures.
    /// @param erc1155FillAmounts The amounts of the ERC1155 assets
    ///        to buy for each order.
    /// @param callbackData The data (if any) to pass to the taker
    ///        callback for each order. Refer to the `callbackData`
    ///        parameter to for `buyERC1155`.
    /// @param revertIfIncomplete If true, reverts if this
    ///        function fails to fill any individual order.
    /// @return successes An array of booleans corresponding to whether
    ///         each order in `orders` was successfully filled.
    function batchBuySharedERC1155s(
        LibNFTOrder.ERC1155SellOrder[] memory sellOrders,
        LibSignature.Signature[] memory signatures,
        address[] calldata takers,
        uint128[] calldata erc1155FillAmounts,
        bytes[] memory callbackData,
        bool revertIfIncomplete
    )
        public
        override
        payable
        returns (bool[] memory successes)
    {
        uint256 length = sellOrders.length;
        require(
            length == signatures.length &&
            length == takers.length &&
            length == erc1155FillAmounts.length &&
            length == callbackData.length,
            "ARRAY_LENGTH_MISMATCH"
        );
        successes = new bool[](length);

        uint256 ethBalanceBefore = address(this).balance - msg.value;
        if (revertIfIncomplete) {
            for (uint256 i = 0; i < length; i++) {
                // Will revert if _buySharedERC1155 reverts.
                _buySharedERC1155(
                    sellOrders[i],
                    signatures[i],
                    BuyParams(
                        erc1155FillAmounts[i],
                        address(this).balance - ethBalanceBefore, // Remaining ETH available
                        takers[i],
                        callbackData[i]
                    )
                );
                successes[i] = true;
            }
        } else {
            for (uint256 i = 0; i < length; i++) {
                // Delegatecall `buySharedERC1155FromProxy` to catch swallow reverts while
                // preserving execution context.
                (successes[i], ) = _implementation.delegatecall(
                    abi.encodeWithSelector(
                        this.buySharedERC1155FromProxy.selector,
                        sellOrders[i],
                        signatures[i],
                        BuyParams(
                            erc1155FillAmounts[i],
                            address(this).balance - ethBalanceBefore, // Remaining ETH available
                            takers[i],
                            callbackData[i]
                        )
                    )
                );
            }
        }

        // Refund
        _transferEth(payable(msg.sender), address(this).balance - ethBalanceBefore);
    }

    // @Note `buySharedERC1155FromProxy` is a external function, must call from an external Exchange Proxy,
    //        but should not be registered in the Exchange Proxy.
    function buySharedERC1155FromProxy(
        LibNFTOrder.ERC1155SellOrder memory sellOrder,
        LibSignature.Signature memory signature,
        BuyParams memory params
    ) external payable {
        require(_implementation != address(this), "MUST_CALL_FROM_PROXY");
        _buySharedERC1155(sellOrder, signature, params);
    }

    /// @dev Matches a pair of complementary orders that have
    ///      a non-negative spread. Each order is filled at
    ///      their respective price, and the matcher receives
    ///      a profit denominated in the ERC20 token.
    /// @param sellOrder Order selling an ERC1155 asset.
    /// @param buyOrder Order buying an ERC1155 asset.
    /// @param sellOrderSignature Signature for the sell order.
    /// @param buyOrderSignature Signature for the buy order.
    /// @return profit The amount of profit earned by the caller
    ///         of this function (denominated in the ERC20 token
    ///         of the matched orders).
    function matchSharedERC1155Orders(
        LibNFTOrder.ERC1155SellOrder memory sellOrder,
        LibNFTOrder.ERC1155BuyOrder memory buyOrder,
        LibSignature.Signature memory sellOrderSignature,
        LibSignature.Signature memory buyOrderSignature
    )
        public
        override
        returns (uint256 profit)
    {
        // The ERC1155 tokens must match
        require(sellOrder.erc1155Token == buyOrder.erc1155Token, "ERC1155_TOKEN_MISMATCH_ERROR");

        LibNFTOrder.OrderInfo memory sellOrderInfo = _getOrderInfo(sellOrder);
        LibNFTOrder.OrderInfo memory buyOrderInfo = _getOrderInfo(buyOrder);

        bool isEnglishAuction = (sellOrder.expiry >> 252 == 2);
        if (isEnglishAuction) {
            require(
                sellOrderInfo.orderAmount == sellOrderInfo.remainingAmount &&
                sellOrderInfo.orderAmount == buyOrderInfo.orderAmount &&
                sellOrderInfo.orderAmount == buyOrderInfo.remainingAmount,
                "UNMATCH_ORDER_AMOUNT"
            );
        }

        _validateSellOrder(
            sellOrder,
            sellOrderSignature,
            sellOrderInfo,
            buyOrder.maker
        );
        _validateBuyOrder(
            buyOrder,
            buyOrderSignature,
            buyOrderInfo,
            sellOrder.maker,
            sellOrder.erc1155TokenId
        );

        // fillAmount = min(sellOrder.remainingAmount, buyOrder.remainingAmount)
        uint128 erc1155FillAmount = sellOrderInfo.remainingAmount < buyOrderInfo.remainingAmount ?
            sellOrderInfo.remainingAmount : buyOrderInfo.remainingAmount;
        // Reset sellOrder.erc20TokenAmount
        if (erc1155FillAmount != sellOrderInfo.orderAmount) {
            sellOrder.erc20TokenAmount = _ceilDiv(sellOrder.erc20TokenAmount * erc1155FillAmount, sellOrderInfo.orderAmount);
        }
        // Reset buyOrder.erc20TokenAmount
        if (erc1155FillAmount != buyOrderInfo.orderAmount) {
            buyOrder.erc20TokenAmount = buyOrder.erc20TokenAmount * erc1155FillAmount / buyOrderInfo.orderAmount;
        }
        if (isEnglishAuction) {
            _resetEnglishAuctionTokenAmountAndFees(
                sellOrder,
                buyOrder.erc20TokenAmount,
                erc1155FillAmount,
                sellOrderInfo.orderAmount
            );
        }

        // Mark both orders as filled.
        _updateOrderState(sellOrderInfo.orderHash, erc1155FillAmount);
        _updateOrderState(buyOrderInfo.orderHash, erc1155FillAmount);

        // The buyer must be willing to pay at least the amount that the
        // seller is asking.
        require(buyOrder.erc20TokenAmount >= sellOrder.erc20TokenAmount, "NEGATIVE_SPREAD_ERROR");

        // The difference in ERC20 token amounts is the spread.
        uint256 spread = buyOrder.erc20TokenAmount - sellOrder.erc20TokenAmount;

        // Transfer the ERC1155 asset from seller to buyer.
        _transferNFTAsset(sellOrder, buyOrder.maker, erc1155FillAmount);

        // Handle the ERC20 side of the order:
        if (
            address(sellOrder.erc20Token) == NATIVE_TOKEN_ADDRESS &&
            buyOrder.erc20Token == WETH
        ) {
            // The sell order specifies ETH, while the buy order specifies WETH.
            // The orders are still compatible with one another, but we'll have
            // to unwrap the WETH on behalf of the buyer.

            // Step 1: Transfer WETH from the buyer to the EP.
            //         Note that we transfer `buyOrder.erc20TokenAmount`, which
            //         is the amount the buyer signaled they are willing to pay
            //         for the ERC1155 asset, which may be more than the seller's
            //         ask.
            _transferERC20TokensFrom(
                WETH,
                buyOrder.maker,
                address(this),
                buyOrder.erc20TokenAmount
            );
            // Step 2: Unwrap the WETH into ETH. We unwrap the entire
            //         `buyOrder.erc20TokenAmount`.
            //         The ETH will be used for three purposes:
            //         - To pay the seller
            //         - To pay fees for the sell order
            //         - Any remaining ETH will be sent to
            //           `msg.sender` as profit.
            WETH.withdraw(buyOrder.erc20TokenAmount);

            // Step 3: Pay the seller (in ETH).
            _transferEth(payable(sellOrder.maker), sellOrder.erc20TokenAmount);

            // Step 4: Pay fees for the buy order. Note that these are paid
            //         in _WETH_ by the _buyer_. By signing the buy order, the
            //         buyer signals that they are willing to spend a total
            //         of `erc20TokenAmount` _plus_ fees, all denominated in
            //         the `erc20Token`, which in this case is WETH.
            _payFees(
                buyOrder.asNFTBuyOrder().asNFTSellOrder(),
                buyOrder.maker, // payer
                erc1155FillAmount,
                buyOrderInfo.orderAmount,
                false           // useNativeToken
            );

            // Step 5: Pay fees for the sell order. The `erc20Token` of the
            //         sell order is ETH, so the fees are paid out in ETH.
            //         There should be `spread` wei of ETH remaining in the
            //         EP at this point, which we will use ETH to pay the
            //         sell order fees.
            uint256 sellOrderFees = _payFees(
                sellOrder.asNFTSellOrder(),
                address(this), // payer
                erc1155FillAmount,
                sellOrderInfo.orderAmount,
                true           // useNativeToken
            );

            // Step 6: The spread less the sell order fees is the amount of ETH
            //         remaining in the EP that can be sent to `msg.sender` as
            //         the profit from matching these two orders.
            profit = spread - sellOrderFees;
            if (profit > 0) {
                _transferEth(payable(msg.sender), profit);
            }
        } else {
            // ERC20 tokens must match
            require(sellOrder.erc20Token == buyOrder.erc20Token, "ERC20_TOKEN_MISMATCH");

            // Step 1: Transfer the ERC20 token from the buyer to the seller.
            //         Note that we transfer `sellOrder.erc20TokenAmount`, which
            //         is at most `buyOrder.erc20TokenAmount`.
            _transferERC20TokensFrom(
                buyOrder.erc20Token,
                buyOrder.maker,
                sellOrder.maker,
                sellOrder.erc20TokenAmount
            );

            // Step 2: Pay fees for the buy order. Note that these are paid
            //         by the buyer. By signing the buy order, the buyer signals
            //         that they are willing to spend a total of
            //         `buyOrder.erc20TokenAmount` _plus_ `buyOrder.fees`.
            _payFees(
                buyOrder.asNFTBuyOrder().asNFTSellOrder(),
                buyOrder.maker, // payer
                erc1155FillAmount,
                buyOrderInfo.orderAmount,
                false           // useNativeToken
            );

            // Step 3: Pay fees for the sell order. These are paid by the buyer
            //         as well. After paying these fees, we may have taken more
            //         from the buyer than they agreed to in the buy order. If
            //         so, we revert in the following step.
            uint256 sellOrderFees = _payFees(
                sellOrder.asNFTSellOrder(),
                buyOrder.maker, // payer
                erc1155FillAmount,
                sellOrderInfo.orderAmount,
                false           // useNativeToken
            );

            // Step 4: We calculate the profit as:
            //         profit = buyOrder.erc20TokenAmount - sellOrder.erc20TokenAmount - sellOrderFees
            //                = spread - sellOrderFees
            //         I.e. the buyer would've been willing to pay up to `profit`
            //         more to buy the asset, so instead that amount is sent to
            //         `msg.sender` as the profit from matching these two orders.
            profit = spread - sellOrderFees;
            if (profit > 0) {
                _transferERC20TokensFrom(
                    buyOrder.erc20Token,
                    buyOrder.maker,
                    msg.sender,
                    profit
                );
            }
        }

        _emitEventSellOrderFilled(
            sellOrder,
            buyOrder.maker, // taker
            erc1155FillAmount,
            sellOrderInfo.orderHash
        );

        _emitEventBuyOrderFilled(
            buyOrder,
            sellOrder.maker, // taker
            sellOrder.erc1155TokenId,
            erc1155FillAmount,
            buyOrderInfo.orderHash
        );
    }

    function _emitEventSellOrderFilled(
        LibNFTOrder.ERC1155SellOrder memory sellOrder,
        address taker,
        uint128 erc1155FillAmount,
        bytes32 orderHash
    ) private {
        emit ERC1155SellOrderFilled(
            sellOrder.maker,
            taker,
            sellOrder.erc20Token,
            sellOrder.erc20TokenAmount,
            sellOrder.erc1155Token,
            sellOrder.erc1155TokenId,
            erc1155FillAmount,
            orderHash
        );
    }

    function _emitEventBuyOrderFilled(
        LibNFTOrder.ERC1155BuyOrder memory buyOrder,
        address taker,
        uint256 erc1155TokenId,
        uint128 erc1155FillAmount,
        bytes32 orderHash
    ) private {
        emit ERC1155BuyOrderFilled(
            buyOrder.maker,
            taker,
            buyOrder.erc20Token,
            buyOrder.erc20TokenAmount,
            buyOrder.erc1155Token,
            erc1155TokenId,
            erc1155FillAmount,
            orderHash
        );
    }

    /// @dev Matches pairs of complementary orders that have
    ///      non-negative spreads. Each order is filled at
    ///      their respective price, and the matcher receives
    ///      a profit denominated in the ERC20 token.
    /// @param sellOrders Orders selling ERC1155 assets.
    /// @param buyOrders Orders buying ERC1155 assets.
    /// @param sellOrderSignatures Signatures for the sell orders.
    /// @param buyOrderSignatures Signatures for the buy orders.
    /// @return profits The amount of profit earned by the caller
    ///         of this function for each pair of matched orders
    ///         (denominated in the ERC20 token of the order pair).
    /// @return successes An array of booleans corresponding to
    ///         whether each pair of orders was successfully matched.
    function batchMatchSharedERC1155Orders(
        LibNFTOrder.ERC1155SellOrder[] memory sellOrders,
        LibNFTOrder.ERC1155BuyOrder[] memory buyOrders,
        LibSignature.Signature[] memory sellOrderSignatures,
        LibSignature.Signature[] memory buyOrderSignatures
    )
        public
        override
        returns (uint256[] memory profits, bool[] memory successes)
    {
        require(
            sellOrders.length == buyOrders.length &&
            sellOrderSignatures.length == buyOrderSignatures.length &&
            sellOrders.length == sellOrderSignatures.length
        );
        profits = new uint256[](sellOrders.length);
        successes = new bool[](sellOrders.length);

        for (uint256 i = 0; i < sellOrders.length; i++) {
            bytes memory returnData;
            // Delegatecall `matchSharedERC1155Orders` to catch reverts while
            // preserving execution context.
            (successes[i], returnData) = _implementation.delegatecall(
                abi.encodeWithSelector(
                    this.matchSharedERC1155Orders.selector,
                    sellOrders[i],
                    buyOrders[i],
                    sellOrderSignatures[i],
                    buyOrderSignatures[i]
                )
            );
            if (successes[i]) {
                // If the matching succeeded, record the profit.
                (uint256 profit) = abi.decode(returnData, (uint256));
                profits[i] = profit;
            }
        }
    }

    // Core settlement logic for selling an ERC1155 asset.
    // Used by `sellSharedERC1155` and `onERC1155Received`.
    function _sellSharedERC1155(
        LibNFTOrder.ERC1155BuyOrder memory buyOrder,
        LibSignature.Signature memory signature,
        SellParams memory params
    ) internal {
        LibNFTOrder.OrderInfo memory orderInfo = _getOrderInfo(buyOrder);

        // Check that the order can be filled.
        _validateBuyOrder(buyOrder, signature, orderInfo, params.taker, params.tokenId);

        // Check amount.
        require(params.sellAmount <= orderInfo.remainingAmount, "_sell/EXCEEDS_REMAINING_AMOUNT");

        // Update the order state.
        _updateOrderState(orderInfo.orderHash, params.sellAmount);

        // Calculate erc20 pay amount.
        uint256 erc20FillAmount = (params.sellAmount == orderInfo.orderAmount) ?
            buyOrder.erc20TokenAmount : buyOrder.erc20TokenAmount * params.sellAmount / orderInfo.orderAmount;

        if (params.unwrapNativeToken) {
            // The ERC20 token must be WETH for it to be unwrapped.
            require(buyOrder.erc20Token == WETH, "_sell/ERC20_TOKEN_MISMATCH_ERROR");

            // Transfer the WETH from the maker to the Exchange Proxy
            // so we can unwrap it before sending it to the seller.
            // TODO: Probably safe to just use WETH.transferFrom for some
            //       small gas savings
            _transferERC20TokensFrom(WETH, buyOrder.maker, address(this), erc20FillAmount);

            // Unwrap WETH into ETH.
            WETH.withdraw(erc20FillAmount);

            // Send ETH to the seller.
            _transferEth(payable(params.taker), erc20FillAmount);
        } else {
            // Transfer the ERC20 token from the buyer to the seller.
            _transferERC20TokensFrom(buyOrder.erc20Token, buyOrder.maker, params.taker, erc20FillAmount);
        }

        if (params.takerCallbackData.length > 0) {
            require(params.taker != address(this), "_sell/CANNOT_CALLBACK_SELF");

            // Invoke the callback
            bytes4 callbackResult = ITakerCallback(params.taker).zeroExTakerCallback(orderInfo.orderHash, params.takerCallbackData);

            // Check for the magic success bytes
            require(callbackResult == TAKER_CALLBACK_MAGIC_BYTES, "_sell/CALLBACK_FAILED");
        }

        // Transfer the ERC1155 asset to the buyer.
        _transferNFTAsset(buyOrder, params);

        // The buyer pays the order fees.
        LibNFTOrder.NFTSellOrder memory order;
        assembly { order := buyOrder }
        _payFees(order, buyOrder.maker, params.sellAmount, orderInfo.orderAmount, false);

        emit ERC1155BuyOrderFilled(
            buyOrder.maker,
            params.taker,
            buyOrder.erc20Token,
            erc20FillAmount,
            buyOrder.erc1155Token,
            params.tokenId,
            params.sellAmount,
            orderInfo.orderHash
        );
    }

    function _buySharedERC1155(
        LibNFTOrder.ERC1155SellOrder memory sellOrder,
        LibSignature.Signature memory signature,
        BuyParams memory params
    ) internal {
        if (params.taker == address(0)) {
            params.taker = msg.sender;
        } else {
            require(params.taker != address(this), "_buy/TAKER_CANNOT_SELF");
        }

        LibNFTOrder.OrderInfo memory orderInfo = _getOrderInfo(sellOrder);

        // Check that the order can be filled.
        _validateSellOrder(sellOrder, signature, orderInfo, params.taker);

        // Check amount.
        require(params.buyAmount <= orderInfo.remainingAmount, "_buy/EXCEEDS_REMAINING_AMOUNT");

        // Update the order state.
        _updateOrderState(orderInfo.orderHash, params.buyAmount);

        // Dutch Auction
        if (sellOrder.expiry >> 252 == 1) {
            uint256 count = (sellOrder.expiry >> 64) & 0xffffffff;
            if (count > 0) {
                _resetDutchAuctionTokenAmountAndFees(sellOrder, count);
            }
        }

        // Calculate erc20 pay amount.
        uint256 erc20FillAmount = (params.buyAmount == orderInfo.orderAmount) ?
            sellOrder.erc20TokenAmount : _ceilDiv(sellOrder.erc20TokenAmount * params.buyAmount, orderInfo.orderAmount);

        // Transfer the ERC1155 asset to the buyer.
        _transferNFTAsset(sellOrder, params.taker, params.buyAmount);

        uint256 ethAvailable = params.ethAvailable;
        if (params.takerCallbackData.length > 0) {
            require(params.taker != address(this), "_buy/CANNOT_CALLBACK_SELF");

            uint256 ethBalanceBeforeCallback = address(this).balance;

            // Invoke the callback
            bytes4 callbackResult = ITakerCallback(params.taker).zeroExTakerCallback(orderInfo.orderHash, params.takerCallbackData);

            // Update `ethAvailable` with amount acquired during
            // the callback
            ethAvailable += address(this).balance - ethBalanceBeforeCallback;

            // Check for the magic success bytes
            require(callbackResult == TAKER_CALLBACK_MAGIC_BYTES, "_buy/CALLBACK_FAILED");
        }

        if (address(sellOrder.erc20Token) == NATIVE_TOKEN_ADDRESS) {
            uint256 totalPaid = erc20FillAmount + _calcTotalFeesPaid(sellOrder.fees, params.buyAmount, orderInfo.orderAmount);
            if (ethAvailable < totalPaid) {
                // Transfer WETH from the buyer to this contract.
                uint256 withDrawAmount = totalPaid - ethAvailable;
                _transferERC20TokensFrom(WETH, msg.sender, address(this), withDrawAmount);

                // Unwrap WETH into ETH.
                WETH.withdraw(withDrawAmount);
            }

            // Transfer ETH to the seller.
            _transferEth(payable(sellOrder.maker), erc20FillAmount);

            // Fees are paid from the EP's current balance of ETH.
            _payFees(sellOrder.asNFTSellOrder(), address(this), params.buyAmount, orderInfo.orderAmount, true);
        } else if (sellOrder.erc20Token == WETH) {
            uint256 totalFeesPaid = _calcTotalFeesPaid(sellOrder.fees, params.buyAmount, orderInfo.orderAmount);
            if (ethAvailable > totalFeesPaid) {
                uint256 depositAmount = ethAvailable - totalFeesPaid;
                if (depositAmount < erc20FillAmount) {
                    // Transfer WETH from the buyer to this contract.
                    _transferERC20TokensFrom(WETH, msg.sender, address(this), (erc20FillAmount - depositAmount));
                } else {
                    depositAmount = erc20FillAmount;
                }

                // Wrap ETH.
                WETH.deposit{value: depositAmount}();

                // Transfer WETH to the seller.
                _transferERC20Tokens(WETH, sellOrder.maker, erc20FillAmount);

                // Fees are paid from the EP's current balance of ETH.
                _payFees(sellOrder.asNFTSellOrder(), address(this), params.buyAmount, orderInfo.orderAmount, true);
            } else {
                // Transfer WETH from the buyer to the seller.
                _transferERC20TokensFrom(WETH, msg.sender, sellOrder.maker, erc20FillAmount);

                if (ethAvailable > 0) {
                    if (ethAvailable < totalFeesPaid) {
                        // Transfer WETH from the buyer to this contract.
                        uint256 value = totalFeesPaid - ethAvailable;
                        _transferERC20TokensFrom(WETH, msg.sender, address(this), value);

                        // Unwrap WETH into ETH.
                        WETH.withdraw(value);
                    }

                    // Fees are paid from the EP's current balance of ETH.
                    _payFees(sellOrder.asNFTSellOrder(), address(this), params.buyAmount, orderInfo.orderAmount, true);
                } else {
                    // The buyer pays fees using WETH.
                    _payFees(sellOrder.asNFTSellOrder(), msg.sender, params.buyAmount, orderInfo.orderAmount, false);
                }
            }
        } else {
            // Transfer ERC20 token from the buyer to the seller.
            _transferERC20TokensFrom(sellOrder.erc20Token, msg.sender, sellOrder.maker, erc20FillAmount);

            // The buyer pays fees.
            _payFees(sellOrder.asNFTSellOrder(), msg.sender, params.buyAmount, orderInfo.orderAmount, false);
        }

        emit ERC1155SellOrderFilled(
            sellOrder.maker,
            msg.sender,
            sellOrder.erc20Token,
            erc20FillAmount,
            sellOrder.erc1155Token,
            sellOrder.erc1155TokenId,
            params.buyAmount,
            orderInfo.orderHash
        );
    }

    function _transferNFTAsset(LibNFTOrder.ERC1155BuyOrder memory order, SellParams memory params) private {
        _transferNFTAssetFrom(order.erc1155Token, params.currentNftOwner, order.maker, params.tokenId, params.sellAmount, params.metadata);
    }

    function _transferNFTAsset(LibNFTOrder.ERC1155SellOrder memory order, address to, uint256 amount) private {
        bytes memory data;
        for (uint256 i = 0; i < order.fees.length; i++) {
            if (order.fees[i].recipient == address(0)) {
                data = order.fees[i].feeData;
                break;
            }
        }
        _transferNFTAssetFrom(order.erc1155Token, order.maker, to, order.erc1155TokenId, amount, data);
    }

    function _transferNFTAssetFrom(address token, address from, address to, uint256 tokenId, uint256 amount, bytes memory data) private {
        /* Retrieve delegateProxy contract. */
        IAuthenticatedProxy proxy = registry.proxies(from);

        /* Proxy must exist. */
        require(address(proxy) != address(0), "!delegateProxy");

        /* require implementation. */
        require(proxy.implementation() == registry.delegateProxyImplementation(), "!implementation");

        // 0xf242432a = keccak256(abi.encode(safeTransferFrom(address,address,uint256,uint256,bytes))
        bytes memory dataToCall = abi.encodeWithSelector(0xf242432a, from, to, tokenId, amount, data);
        require(proxy.proxy(token, 0, dataToCall), "!proxy call");
    }

    /// @dev Validates that the given signature is valid for the
    ///      given maker and order hash. Reverts if the signature
    ///      is not valid.
    /// @param orderHash The hash of the order that was signed.
    /// @param signature The signature to check.
    /// @param maker The maker of the order.
    function _validateOrderSignature(
        bytes32 orderHash,
        LibSignature.Signature memory signature,
        address maker
    ) internal view {
        if (signature.signatureType == LibSignature.SignatureType.PRESIGNED) {
            require(
                LibERC1155OrdersStorage.getStorage().orderState[orderHash].preSigned ==
                LibCommonNftOrdersStorage.getStorage().hashNonces[maker] + 1,
                "PRESIGNED_INVALID_SIGNER"
            );
        } else {
            require(
                maker != address(0) && maker == ecrecover(orderHash, signature.v, signature.r, signature.s),
                "INVALID_SIGNER_ERROR"
            );
        }
    }

    /// @dev Updates storage to indicate that the given order
    ///      has been filled by the given amount.
    /// @param orderHash The hash of `order`.
    /// @param fillAmount The amount (denominated in the NFT asset)
    ///        that the order has been filled by.
    function _updateOrderState(bytes32 orderHash, uint128 fillAmount) internal {
        LibERC1155OrdersStorage.Storage storage stor = LibERC1155OrdersStorage.getStorage();
        uint128 filledAmount = stor.orderState[orderHash].filledAmount;
        // Filled amount should never overflow 128 bits
        require(filledAmount + fillAmount > filledAmount);
        stor.orderState[orderHash].filledAmount = filledAmount + fillAmount;
    }

    function _getOrderInfo(LibNFTOrder.ERC1155SellOrder memory order) internal view returns (LibNFTOrder.OrderInfo memory orderInfo) {
        orderInfo.orderAmount = order.erc1155TokenAmount;
        orderInfo.orderHash = _getERC1155SellOrderHash(order);

        // Check for listingTime.
        // Gas Optimize, listingTime only used in rare cases.
        if (order.expiry & 0xffffffff00000000 > 0) {
            if ((order.expiry >> 32) & 0xffffffff > block.timestamp) {
                orderInfo.status = LibNFTOrder.OrderStatus.INVALID;
                return orderInfo;
            }
        }

        // Check for expiryTime.
        if (order.expiry & 0xffffffff <= block.timestamp) {
            orderInfo.status = LibNFTOrder.OrderStatus.EXPIRED;
            return orderInfo;
        }

        {
            LibERC1155OrdersStorage.Storage storage stor =
            LibERC1155OrdersStorage.getStorage();

            LibERC1155OrdersStorage.OrderState storage orderState =
            stor.orderState[orderInfo.orderHash];
            orderInfo.remainingAmount = order.erc1155TokenAmount - orderState.filledAmount;

            // `orderCancellationByMaker` is indexed by maker and nonce.
            uint256 orderCancellationBitVector =
            stor.orderCancellationByMaker[order.maker][uint248(order.nonce >> 8)];
            // The bitvector is indexed by the lower 8 bits of the nonce.
            uint256 flag = 1 << (order.nonce & 255);

            if (orderInfo.remainingAmount == 0 ||
                orderCancellationBitVector & flag != 0)
            {
                orderInfo.status = LibNFTOrder.OrderStatus.UNFILLABLE;
                return orderInfo;
            }
        }

        // Otherwise, the order is fillable.
        orderInfo.status = LibNFTOrder.OrderStatus.FILLABLE;
        return orderInfo;
    }

    function _getOrderInfo(LibNFTOrder.ERC1155BuyOrder memory order) internal view returns (LibNFTOrder.OrderInfo memory orderInfo) {
        orderInfo.orderAmount = order.erc1155TokenAmount;
        orderInfo.orderHash = _getERC1155BuyOrderHash(order);

        // Only buy orders with `erc1155TokenId` == 0 can be property
        // orders.
        if (order.erc1155TokenId != 0 && order.erc1155TokenProperties.length > 0) {
            orderInfo.status = LibNFTOrder.OrderStatus.INVALID;
            return orderInfo;
        }

        // Buy orders cannot use ETH as the ERC20 token, since ETH cannot be
        // transferred from the buyer by a contract.
        if (address(order.erc20Token) == NATIVE_TOKEN_ADDRESS) {
            orderInfo.status = LibNFTOrder.OrderStatus.INVALID;
            return orderInfo;
        }

        // Check for listingTime.
        // Gas Optimize, listingTime only used in rare cases.
        if (order.expiry & 0xffffffff00000000 > 0) {
            if ((order.expiry >> 32) & 0xffffffff > block.timestamp) {
                orderInfo.status = LibNFTOrder.OrderStatus.INVALID;
                return orderInfo;
            }
        }

        // Check for expiryTime.
        if (order.expiry & 0xffffffff <= block.timestamp) {
            orderInfo.status = LibNFTOrder.OrderStatus.EXPIRED;
            return orderInfo;
        }

        {
            LibERC1155OrdersStorage.Storage storage stor =
            LibERC1155OrdersStorage.getStorage();

            LibERC1155OrdersStorage.OrderState storage orderState =
            stor.orderState[orderInfo.orderHash];
            orderInfo.remainingAmount = order.erc1155TokenAmount - orderState.filledAmount;

            // `orderCancellationByMaker` is indexed by maker and nonce.
            uint256 orderCancellationBitVector =
            stor.orderCancellationByMaker[order.maker][uint248(order.nonce >> 8)];
            // The bitvector is indexed by the lower 8 bits of the nonce.
            uint256 flag = 1 << (order.nonce & 255);

            if (orderInfo.remainingAmount == 0 ||
                orderCancellationBitVector & flag != 0)
            {
                orderInfo.status = LibNFTOrder.OrderStatus.UNFILLABLE;
                return orderInfo;
            }
        }

        // Otherwise, the order is fillable.
        orderInfo.status = LibNFTOrder.OrderStatus.FILLABLE;
        return orderInfo;
    }

    function _getERC1155SellOrderHash(LibNFTOrder.ERC1155SellOrder memory order) private view returns (bytes32 orderHash) {
        return _getEIP712Hash(
            LibNFTOrder.getERC1155SellOrderStructHash(
                order, LibCommonNftOrdersStorage.getStorage().hashNonces[order.maker]
            )
        );
    }

    function _getERC1155BuyOrderHash(LibNFTOrder.ERC1155BuyOrder memory order) private view returns (bytes32 orderHash) {
        return _getEIP712Hash(
            LibNFTOrder.getERC1155BuyOrderStructHash(
                order, LibCommonNftOrdersStorage.getStorage().hashNonces[order.maker]
            )
        );
    }

    function _validateSellOrder(
        LibNFTOrder.ERC1155SellOrder memory sellOrder,
        LibSignature.Signature memory signature,
        LibNFTOrder.OrderInfo memory orderInfo,
        address taker
    ) internal view {
        // Taker must match the order taker, if one is specified.
        require(sellOrder.taker == address(0) || sellOrder.taker == taker, "_validateOrder/ONLY_TAKER");

        // Check that the order is valid and has not expired, been cancelled,
        // or been filled.
        require(orderInfo.status == LibNFTOrder.OrderStatus.FILLABLE, "_validateOrder/ORDER_NOT_FILL");

        // Check the signature.
        _validateOrderSignature(orderInfo.orderHash, signature, sellOrder.maker);
    }

    function _validateBuyOrder(
        LibNFTOrder.ERC1155BuyOrder memory buyOrder,
        LibSignature.Signature memory signature,
        LibNFTOrder.OrderInfo memory orderInfo,
        address taker,
        uint256 tokenId
    ) internal view {
        // The ERC20 token cannot be ETH.
        require(address(buyOrder.erc20Token) != NATIVE_TOKEN_ADDRESS, "_validateBuyOrder/TOKEN_MISMATCH");

        // Taker must match the order taker, if one is specified.
        require(buyOrder.taker == address(0) || buyOrder.taker == taker, "_validateBuyOrder/ONLY_TAKER");

        // Check that the order is valid and has not expired, been cancelled,
        // or been filled.
        require(orderInfo.status == LibNFTOrder.OrderStatus.FILLABLE, "_validateOrder/ORDER_NOT_FILL");

        // Check that the asset with the given token ID satisfies the properties
        // specified by the order.
        _validateOrderProperties(buyOrder, tokenId);

        // Check the signature.
        _validateOrderSignature(orderInfo.orderHash, signature, buyOrder.maker);
    }

    function _resetDutchAuctionTokenAmountAndFees(LibNFTOrder.ERC1155SellOrder memory order, uint256 count) internal view {
        require(count <= 100000000, "COUNT_OUT_OF_SIDE");

        uint256 listingTime = (order.expiry >> 32) & 0xffffffff;
        uint256 denominator = ((order.expiry & 0xffffffff) - listingTime) * 100000000;
        uint256 multiplier = (block.timestamp - listingTime) * count;

        // Reset erc20TokenAmount
        uint256 amount = order.erc20TokenAmount;
        order.erc20TokenAmount = amount - amount * multiplier / denominator;

        // Reset fees
        for (uint256 i = 0; i < order.fees.length; i++) {
            amount = order.fees[i].amount;
            order.fees[i].amount = amount - amount * multiplier / denominator;
        }
    }

    function _resetEnglishAuctionTokenAmountAndFees(
        LibNFTOrder.ERC1155SellOrder memory sellOrder,
        uint256 buyERC20Amount,
        uint256 fillAmount,
        uint256 orderAmount
    ) internal pure {
        uint256 sellOrderFees = _calcTotalFeesPaid(sellOrder.fees, fillAmount, orderAmount);
        uint256 sellTotalAmount = sellOrderFees + sellOrder.erc20TokenAmount;
        if (buyERC20Amount != sellTotalAmount) {
            uint256 spread = buyERC20Amount - sellTotalAmount;
            uint256 sum;

            // Reset fees
            if (sellTotalAmount > 0) {
                for (uint256 i = 0; i < sellOrder.fees.length; i++) {
                    uint256 diff = spread * sellOrder.fees[i].amount / sellTotalAmount;
                    sellOrder.fees[i].amount += diff;
                    sum += diff;
                }
            }

            // Reset erc20TokenAmount
            sellOrder.erc20TokenAmount += spread - sum;
        }
    }

    function _ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // ceil(a / b) = floor((a + b - 1) / b)
        return (a + b - 1) / b;
    }

    function _calcTotalFeesPaid(LibNFTOrder.Fee[] memory fees, uint256 fillAmount, uint256 orderAmount) private pure returns (uint256 totalFeesPaid) {
        if (fillAmount == orderAmount) {
            for (uint256 i = 0; i < fees.length; i++) {
                totalFeesPaid += fees[i].amount;
            }
        } else {
            for (uint256 i = 0; i < fees.length; i++) {
                totalFeesPaid += fees[i].amount * fillAmount / orderAmount;
            }
        }
        return totalFeesPaid;
    }

    function _payFees(
        LibNFTOrder.NFTSellOrder memory order,
        address payer,
        uint128 fillAmount,
        uint128 orderAmount,
        bool useNativeToken
    ) internal returns (uint256 totalFeesPaid) {
        for (uint256 i = 0; i < order.fees.length; i++) {
            LibNFTOrder.Fee memory fee = order.fees[i];

            if (fee.recipient == address(0)) {
                require(fee.amount == 0, "_payFees/FEE.AMOUNT_ERROR");
                continue;
            }

            uint256 feeFillAmount = (fillAmount == orderAmount) ? fee.amount : fee.amount * fillAmount / orderAmount;

            if (useNativeToken) {
                // Transfer ETH to the fee recipient.
                _transferEth(payable(fee.recipient), feeFillAmount);
            } else {
                if (feeFillAmount > 0) {
                    // Transfer ERC20 token from payer to recipient.
                    _transferERC20TokensFrom(order.erc20Token, payer, fee.recipient, feeFillAmount);
                }
            }

            // Note that the fee callback is _not_ called if zero
            // `feeData` is provided. If `feeData` is provided, we assume
            // the fee recipient is a contract that implements the
            // `IFeeRecipient` interface.
            if (fee.feeData.length > 0) {
                // Invoke the callback
                bytes4 callbackResult = IFeeRecipient(fee.recipient).receiveZeroExFeeCallback(
                    useNativeToken ? NATIVE_TOKEN_ADDRESS : address(order.erc20Token),
                    feeFillAmount,
                    fee.feeData
                );

                // Check for the magic success bytes
                require(callbackResult == FEE_CALLBACK_MAGIC_BYTES, "_payFees/CALLBACK_FAILED");
            }

            // Sum the fees paid
            totalFeesPaid += feeFillAmount;
        }
        return totalFeesPaid;
    }

    function _validateOrderProperties(LibNFTOrder.ERC1155BuyOrder memory order, uint256 tokenId) internal view {
        // If no properties are specified, check that the given
        // `tokenId` matches the one specified in the order.
        if (order.erc1155TokenProperties.length == 0) {
            require(tokenId == order.erc1155TokenId, "_validateProperties/TOKEN_ID_ERR");
        } else {
            // Validate each property
            for (uint256 i = 0; i < order.erc1155TokenProperties.length; i++) {
                LibNFTOrder.Property memory property = order.erc1155TokenProperties[i];
                // `address(0)` is interpreted as a no-op. Any token ID
                // will satisfy a property with `propertyValidator == address(0)`.
                if (address(property.propertyValidator) != address(0)) {
                    // Call the property validator and throw a descriptive error
                    // if the call reverts.
                    try property.propertyValidator.validateProperty(order.erc1155Token, tokenId, property.propertyData) {
                    } catch (bytes memory /* reason */) {
                        revert("PROPERTY_VALIDATION_FAILED");
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2022 Element.Market

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;

import "./LibStorage.sol";


library LibCommonNftOrdersStorage {

    /// @dev Storage bucket for this feature.
    struct Storage {
        /* Track per-maker nonces that can be incremented by the maker to cancel orders in bulk. */
        // The current nonce for the maker represents the only valid nonce that can be signed by the maker
        // If a signature was signed with a nonce that's different from the one stored in nonces, it
        // will fail validation.
        mapping(address => uint256) hashNonces;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.STORAGE_ID_COMMON_NFT_ORDERS;
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor.slot := storageSlot }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;

import "./LibStorage.sol";


/// @dev Storage helpers for `ERC1155OrdersFeature`.
library LibERC1155OrdersStorage {

    struct OrderState {
        // The amount (denominated in the ERC1155 asset)
        // that the order has been filled by.
        uint128 filledAmount;
        // Whether the order has been pre-signed.
        uint128 preSigned;
    }

    /// @dev Storage bucket for this feature.
    struct Storage {
        // Mapping from order hash to order state:
        mapping(bytes32 => OrderState) orderState;
        // maker => nonce range => order cancellation bit vector
        mapping(address => mapping(uint248 => uint256)) orderCancellationByMaker;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.STORAGE_ID_ERC1155_ORDERS;
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor.slot := storageSlot }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../vendor/IPropertyValidator.sol";


/// @dev A library for common NFT order operations.
library LibNFTOrder {

    enum OrderStatus {
        INVALID,
        FILLABLE,
        UNFILLABLE,
        EXPIRED
    }

    struct Property {
        IPropertyValidator propertyValidator;
        bytes propertyData;
    }

    struct Fee {
        address recipient;
        uint256 amount;
        bytes feeData;
    }

    struct NFTSellOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address nft;
        uint256 nftId;
    }

    // All fields except `nftProperties` align
    // with those of NFTSellOrder
    struct NFTBuyOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address nft;
        uint256 nftId;
        Property[] nftProperties;
    }

    // All fields except `erc1155TokenAmount` align
    // with those of NFTSellOrder
    struct ERC1155SellOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address erc1155Token;
        uint256 erc1155TokenId;
        // End of fields shared with NFTOrder
        uint128 erc1155TokenAmount;
    }

    // All fields except `erc1155TokenAmount` align
    // with those of NFTBuyOrder
    struct ERC1155BuyOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address erc1155Token;
        uint256 erc1155TokenId;
        Property[] erc1155TokenProperties;
        // End of fields shared with NFTOrder
        uint128 erc1155TokenAmount;
    }

    struct OrderInfo {
        bytes32 orderHash;
        OrderStatus status;
        // `orderAmount` is 1 for all ERC721Orders, and
        // `erc1155TokenAmount` for ERC1155Orders.
        uint128 orderAmount;
        // The remaining amount of the ERC721/ERC1155 asset
        // that can be filled for the order.
        uint128 remainingAmount;
    }

    // The type hash for sell orders, which is:
    // keccak256(abi.encodePacked(
    //    "NFTSellOrder(",
    //        "address maker,",
    //        "address taker,",
    //        "uint256 expiry,",
    //        "uint256 nonce,",
    //        "address erc20Token,",
    //        "uint256 erc20TokenAmount,",
    //        "Fee[] fees,",
    //        "address nft,",
    //        "uint256 nftId,",
    //        "uint256 hashNonce",
    //    ")",
    //    "Fee(",
    //        "address recipient,",
    //        "uint256 amount,",
    //        "bytes feeData",
    //    ")"
    // ))
    uint256 private constant _NFT_SELL_ORDER_TYPE_HASH = 0xed676c7f3e8232a311454799b1cf26e75b4abc90c9bf06c9f7e8e79fcc7fe14d;

    // The type hash for buy orders, which is:
    // keccak256(abi.encodePacked(
    //    "NFTBuyOrder(",
    //        "address maker,",
    //        "address taker,",
    //        "uint256 expiry,",
    //        "uint256 nonce,",
    //        "address erc20Token,",
    //        "uint256 erc20TokenAmount,",
    //        "Fee[] fees,",
    //        "address nft,",
    //        "uint256 nftId,",
    //        "Property[] nftProperties,",
    //        "uint256 hashNonce",
    //    ")",
    //    "Fee(",
    //        "address recipient,",
    //        "uint256 amount,",
    //        "bytes feeData",
    //    ")",
    //    "Property(",
    //        "address propertyValidator,",
    //        "bytes propertyData",
    //    ")"
    // ))
    uint256 private constant _NFT_BUY_ORDER_TYPE_HASH = 0xa525d336300f566329800fcbe82fd263226dc27d6c109f060d9a4a364281521c;

    // The type hash for ERC1155 sell orders, which is:
    // keccak256(abi.encodePacked(
    //    "ERC1155SellOrder(",
    //        "address maker,",
    //        "address taker,",
    //        "uint256 expiry,",
    //        "uint256 nonce,",
    //        "address erc20Token,",
    //        "uint256 erc20TokenAmount,",
    //        "Fee[] fees,",
    //        "address erc1155Token,",
    //        "uint256 erc1155TokenId,",
    //        "uint128 erc1155TokenAmount,",
    //        "uint256 hashNonce",
    //    ")",
    //    "Fee(",
    //        "address recipient,",
    //        "uint256 amount,",
    //        "bytes feeData",
    //    ")"
    // ))
    uint256 private constant _ERC_1155_SELL_ORDER_TYPE_HASH = 0x3529b5920cc48ecbceb24e9c51dccb50fefd8db2cf05d36e356aeb1754e19eda;

    // The type hash for ERC1155 buy orders, which is:
    // keccak256(abi.encodePacked(
    //    "ERC1155BuyOrder(",
    //        "address maker,",
    //        "address taker,",
    //        "uint256 expiry,",
    //        "uint256 nonce,",
    //        "address erc20Token,",
    //        "uint256 erc20TokenAmount,",
    //        "Fee[] fees,",
    //        "address erc1155Token,",
    //        "uint256 erc1155TokenId,",
    //        "Property[] erc1155TokenProperties,",
    //        "uint128 erc1155TokenAmount,",
    //        "uint256 hashNonce",
    //    ")",
    //    "Fee(",
    //        "address recipient,",
    //        "uint256 amount,",
    //        "bytes feeData",
    //    ")",
    //    "Property(",
    //        "address propertyValidator,",
    //        "bytes propertyData",
    //    ")"
    // ))
    uint256 private constant _ERC_1155_BUY_ORDER_TYPE_HASH = 0x1a6eaae1fbed341e0974212ec17f035a9d419cadc3bf5154841cbf7fd605ba48;

    // keccak256(abi.encodePacked(
    //    "Fee(",
    //        "address recipient,",
    //        "uint256 amount,",
    //        "bytes feeData",
    //    ")"
    // ))
    uint256 private constant _FEE_TYPE_HASH = 0xe68c29f1b4e8cce0bbcac76eb1334bdc1dc1f293a517c90e9e532340e1e94115;

    // keccak256(abi.encodePacked(
    //    "Property(",
    //        "address propertyValidator,",
    //        "bytes propertyData",
    //    ")"
    // ))
    uint256 private constant _PROPERTY_TYPE_HASH = 0x6292cf854241cb36887e639065eca63b3af9f7f70270cebeda4c29b6d3bc65e8;

    // keccak256("");
    bytes32 private constant _EMPTY_ARRAY_KECCAK256 = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    // keccak256(abi.encodePacked(keccak256(abi.encode(
    //    _PROPERTY_TYPE_HASH,
    //    address(0),
    //    keccak256("")
    // ))));
    bytes32 private constant _NULL_PROPERTY_STRUCT_HASH = 0x720ee400a9024f6a49768142c339bf09d2dd9056ab52d20fbe7165faba6e142d;

    uint256 private constant ADDRESS_MASK = (1 << 160) - 1;

    function asNFTSellOrder(NFTBuyOrder memory nftBuyOrder) internal pure returns (NFTSellOrder memory order) {
        assembly { order := nftBuyOrder }
    }

    function asNFTSellOrder(ERC1155SellOrder memory erc1155SellOrder) internal pure returns (NFTSellOrder memory order) {
        assembly { order := erc1155SellOrder }
    }

    function asNFTBuyOrder(ERC1155BuyOrder memory erc1155BuyOrder) internal pure returns (NFTBuyOrder memory order) {
        assembly { order := erc1155BuyOrder }
    }

    function asERC1155SellOrder(NFTSellOrder memory nftSellOrder) internal pure returns (ERC1155SellOrder memory order) {
        assembly { order := nftSellOrder }
    }

    function asERC1155BuyOrder(NFTBuyOrder memory nftBuyOrder) internal pure returns (ERC1155BuyOrder memory order) {
        assembly { order := nftBuyOrder }
    }

    // @dev Get the struct hash of an sell order.
    /// @param order The sell order.
    /// @return structHash The struct hash of the order.
    function getNFTSellOrderStructHash(NFTSellOrder memory order, uint256 hashNonce) internal pure returns (bytes32 structHash) {
        bytes32 feesHash = _feesHash(order.fees);

        // Hash in place, equivalent to:
        // return keccak256(abi.encode(
        //     _NFT_SELL_ORDER_TYPE_HASH,
        //     order.maker,
        //     order.taker,
        //     order.expiry,
        //     order.nonce,
        //     order.erc20Token,
        //     order.erc20TokenAmount,
        //     feesHash,
        //     order.nft,
        //     order.nftId,
        //     hashNonce
        // ));
        assembly {
            if lt(order, 32) { invalid() } // Don't underflow memory.

            let typeHashPos := sub(order, 32) // order - 32
            let feesHashPos := add(order, 192) // order + (32 * 6)
            let hashNoncePos := add(order, 288) // order + (32 * 9)

            let typeHashMemBefore := mload(typeHashPos)
            let feeHashMemBefore := mload(feesHashPos)
            let hashNonceMemBefore := mload(hashNoncePos)

            mstore(typeHashPos, _NFT_SELL_ORDER_TYPE_HASH)
            mstore(feesHashPos, feesHash)
            mstore(hashNoncePos, hashNonce)
            structHash := keccak256(typeHashPos, 352 /* 32 * 11 */ )

            mstore(typeHashPos, typeHashMemBefore)
            mstore(feesHashPos, feeHashMemBefore)
            mstore(hashNoncePos, hashNonceMemBefore)
        }
        return structHash;
    }

    /// @dev Get the struct hash of an buy order.
    /// @param order The buy order.
    /// @return structHash The struct hash of the order.
    function getNFTBuyOrderStructHash(NFTBuyOrder memory order, uint256 hashNonce) internal pure returns (bytes32 structHash) {
        bytes32 propertiesHash = _propertiesHash(order.nftProperties);
        bytes32 feesHash = _feesHash(order.fees);

        // Hash in place, equivalent to:
        // return keccak256(abi.encode(
        //     _NFT_BUY_ORDER_TYPE_HASH,
        //     order.maker,
        //     order.taker,
        //     order.expiry,
        //     order.nonce,
        //     order.erc20Token,
        //     order.erc20TokenAmount,
        //     feesHash,
        //     order.nft,
        //     order.nftId,
        //     propertiesHash,
        //     hashNonce
        // ));
        assembly {
            if lt(order, 32) { invalid() } // Don't underflow memory.

            let typeHashPos := sub(order, 32) // order - 32
            let feesHashPos := add(order, 192) // order + (32 * 6)
            let propertiesHashPos := add(order, 288) // order + (32 * 9)
            let hashNoncePos := add(order, 320) // order + (32 * 10)

            let typeHashMemBefore := mload(typeHashPos)
            let feeHashMemBefore := mload(feesHashPos)
            let propertiesHashMemBefore := mload(propertiesHashPos)
            let hashNonceMemBefore := mload(hashNoncePos)

            mstore(typeHashPos, _NFT_BUY_ORDER_TYPE_HASH)
            mstore(feesHashPos, feesHash)
            mstore(propertiesHashPos, propertiesHash)
            mstore(hashNoncePos, hashNonce)
            structHash := keccak256(typeHashPos, 384 /* 32 * 12 */ )

            mstore(typeHashPos, typeHashMemBefore)
            mstore(feesHashPos, feeHashMemBefore)
            mstore(propertiesHashPos, propertiesHashMemBefore)
            mstore(hashNoncePos, hashNonceMemBefore)
        }
        return structHash;
    }

    /// @dev Get the struct hash of an ERC1155 sell order.
    /// @param order The ERC1155 sell order.
    /// @return structHash The struct hash of the order.
    function getERC1155SellOrderStructHash(ERC1155SellOrder memory order, uint256 hashNonce) internal pure returns (bytes32 structHash) {
        bytes32 feesHash = _feesHash(order.fees);

        // Hash in place, equivalent to:
        // return keccak256(abi.encode(
        //     _ERC_1155_SELL_ORDER_TYPE_HASH,
        //     order.maker,
        //     order.taker,
        //     order.expiry,
        //     order.nonce,
        //     order.erc20Token,
        //     order.erc20TokenAmount,
        //     feesHash,
        //     order.erc1155Token,
        //     order.erc1155TokenId,
        //     order.erc1155TokenAmount,
        //     hashNonce
        // ));
        assembly {
            if lt(order, 32) { invalid() } // Don't underflow memory.

            let typeHashPos := sub(order, 32) // order - 32
            let feesHashPos := add(order, 192) // order + (32 * 6)
            let hashNoncePos := add(order, 320) // order + (32 * 10)

            let typeHashMemBefore := mload(typeHashPos)
            let feesHashMemBefore := mload(feesHashPos)
            let hashNonceMemBefore := mload(hashNoncePos)

            mstore(typeHashPos, _ERC_1155_SELL_ORDER_TYPE_HASH)
            mstore(feesHashPos, feesHash)
            mstore(hashNoncePos, hashNonce)
            structHash := keccak256(typeHashPos, 384 /* 32 * 12 */ )

            mstore(typeHashPos, typeHashMemBefore)
            mstore(feesHashPos, feesHashMemBefore)
            mstore(hashNoncePos, hashNonceMemBefore)
        }
        return structHash;
    }

    /// @dev Get the struct hash of an ERC1155 buy order.
    /// @param order The ERC1155 buy order.
    /// @return structHash The struct hash of the order.
    function getERC1155BuyOrderStructHash(ERC1155BuyOrder memory order, uint256 hashNonce) internal pure returns (bytes32 structHash) {
        bytes32 propertiesHash = _propertiesHash(order.erc1155TokenProperties);
        bytes32 feesHash = _feesHash(order.fees);

        // Hash in place, equivalent to:
        // return keccak256(abi.encode(
        //     _ERC_1155_BUY_ORDER_TYPE_HASH,
        //     order.maker,
        //     order.taker,
        //     order.expiry,
        //     order.nonce,
        //     order.erc20Token,
        //     order.erc20TokenAmount,
        //     feesHash,
        //     order.erc1155Token,
        //     order.erc1155TokenId,
        //     propertiesHash,
        //     order.erc1155TokenAmount,
        //     hashNonce
        // ));
        assembly {
            if lt(order, 32) { invalid() } // Don't underflow memory.

            let typeHashPos := sub(order, 32) // order - 32
            let feesHashPos := add(order, 192) // order + (32 * 6)
            let propertiesHashPos := add(order, 288) // order + (32 * 9)
            let hashNoncePos := add(order, 352) // order + (32 * 11)

            let typeHashMemBefore := mload(typeHashPos)
            let feesHashMemBefore := mload(feesHashPos)
            let propertiesHashMemBefore := mload(propertiesHashPos)
            let hashNonceMemBefore := mload(hashNoncePos)

            mstore(typeHashPos, _ERC_1155_BUY_ORDER_TYPE_HASH)
            mstore(feesHashPos, feesHash)
            mstore(propertiesHashPos, propertiesHash)
            mstore(hashNoncePos, hashNonce)
            structHash := keccak256(typeHashPos, 416 /* 32 * 13 */ )

            mstore(typeHashPos, typeHashMemBefore)
            mstore(feesHashPos, feesHashMemBefore)
            mstore(propertiesHashPos, propertiesHashMemBefore)
            mstore(hashNoncePos, hashNonceMemBefore)
        }
        return structHash;
    }

    // Hashes the `properties` array as part of computing the
    // EIP-712 hash of an `ERC721Order` or `ERC1155Order`.
    function _propertiesHash(Property[] memory properties) private pure returns (bytes32 propertiesHash) {
        uint256 numProperties = properties.length;
        // We give `properties.length == 0` and `properties.length == 1`
        // special treatment because we expect these to be the most common.
        if (numProperties == 0) {
            propertiesHash = _EMPTY_ARRAY_KECCAK256;
        } else if (numProperties == 1) {
            Property memory property = properties[0];
            if (address(property.propertyValidator) == address(0) && property.propertyData.length == 0) {
                propertiesHash = _NULL_PROPERTY_STRUCT_HASH;
            } else {
                // propertiesHash = keccak256(abi.encodePacked(keccak256(abi.encode(
                //     _PROPERTY_TYPE_HASH,
                //     properties[0].propertyValidator,
                //     keccak256(properties[0].propertyData)
                // ))));
                bytes32 dataHash = keccak256(property.propertyData);
                assembly {
                    // Load free memory pointer
                    let mem := mload(64)
                    mstore(mem, _PROPERTY_TYPE_HASH)
                    // property.propertyValidator
                    mstore(add(mem, 32), and(ADDRESS_MASK, mload(property)))
                    // keccak256(property.propertyData)
                    mstore(add(mem, 64), dataHash)
                    mstore(mem, keccak256(mem, 96))
                    propertiesHash := keccak256(mem, 32)
                }
            }
        } else {
            bytes32[] memory propertyStructHashArray = new bytes32[](numProperties);
            for (uint256 i = 0; i < numProperties; i++) {
                propertyStructHashArray[i] = keccak256(abi.encode(
                        _PROPERTY_TYPE_HASH, properties[i].propertyValidator, keccak256(properties[i].propertyData)));
            }
            assembly {
                propertiesHash := keccak256(add(propertyStructHashArray, 32), mul(numProperties, 32))
            }
        }
    }

    // Hashes the `fees` array as part of computing the
    // EIP-712 hash of an `ERC721Order` or `ERC1155Order`.
    function _feesHash(Fee[] memory fees) private pure returns (bytes32 feesHash) {
        uint256 numFees = fees.length;
        // We give `fees.length == 0` and `fees.length == 1`
        // special treatment because we expect these to be the most common.
        if (numFees == 0) {
            feesHash = _EMPTY_ARRAY_KECCAK256;
        } else if (numFees == 1) {
            // feesHash = keccak256(abi.encodePacked(keccak256(abi.encode(
            //     _FEE_TYPE_HASH,
            //     fees[0].recipient,
            //     fees[0].amount,
            //     keccak256(fees[0].feeData)
            // ))));
            Fee memory fee = fees[0];
            bytes32 dataHash = keccak256(fee.feeData);
            assembly {
                // Load free memory pointer
                let mem := mload(64)
                mstore(mem, _FEE_TYPE_HASH)
                // fee.recipient
                mstore(add(mem, 32), and(ADDRESS_MASK, mload(fee)))
                // fee.amount
                mstore(add(mem, 64), mload(add(fee, 32)))
                // keccak256(fee.feeData)
                mstore(add(mem, 96), dataHash)
                mstore(mem, keccak256(mem, 128))
                feesHash := keccak256(mem, 32)
            }
        } else {
            bytes32[] memory feeStructHashArray = new bytes32[](numFees);
            for (uint256 i = 0; i < numFees; i++) {
                feeStructHashArray[i] = keccak256(abi.encode(_FEE_TYPE_HASH, fees[i].recipient, fees[i].amount, keccak256(fees[i].feeData)));
            }
            assembly {
                feesHash := keccak256(add(feeStructHashArray, 32), mul(numFees, 32))
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;

/// @dev A library for validating signatures.
library LibSignature {

    /// @dev Allowed signature types.
    enum SignatureType {
        EIP712,
        PRESIGNED
    }

    /// @dev Encoded EC signature.
    struct Signature {
        // How to validate the signature.
        SignatureType signatureType;
        // EC Signature data.
        uint8 v;
        // EC Signature data.
        bytes32 r;
        // EC Signature data.
        bytes32 s;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;


/// @dev EIP712 helpers for features.
abstract contract FixinEIP712 {

    bytes32 private constant DOMAIN = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant NAME = keccak256("ElementEx");
    bytes32 private constant VERSION = keccak256("1.0.0");
    uint256 private immutable CHAIN_ID;

    constructor() {
        uint256 chainId;
        assembly { chainId := chainid() }
        CHAIN_ID = chainId;
    }

    function _getEIP712Hash(bytes32 structHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(hex"1901", keccak256(abi.encode(DOMAIN, NAME, VERSION, CHAIN_ID, address(this))), structHash));
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";


/// @dev Helpers for moving tokens around.
abstract contract FixinTokenSpender {

    // Mask of the lower 20 bytes of a bytes32.
    uint256 constant private ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;

    /// @dev Transfers ERC20 tokens from `owner` to `to`.
    /// @param token The token to spend.
    /// @param owner The owner of the tokens.
    /// @param to The recipient of the tokens.
    /// @param amount The amount of `token` to transfer.
    function _transferERC20TokensFrom(IERC20 token, address owner, address to, uint256 amount) internal {
        uint256 success;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transferFrom(address,address,uint256)
            mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(owner, ADDRESS_MASK))
            mstore(add(ptr, 0x24), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x44), amount)

            success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x64, ptr, 32)

            let rdsize := returndatasize()

            // Check for ERC20 success. ERC20 tokens should return a boolean,
            // but some don't. We accept 0-length return data as success, or at
            // least 32 bytes that starts with a 32-byte boolean true.
            success := and(
                success,                             // call itself succeeded
                or(
                    iszero(rdsize),                  // no return data, or
                    and(
                        iszero(lt(rdsize, 32)),      // at least 32 bytes
                        eq(mload(ptr), 1)            // starts with uint256(1)
                    )
                )
            )
        }
        require(success != 0, "_transferERC20/TRANSFER_FAILED");
    }

    /// @dev Transfers ERC20 tokens from ourselves to `to`.
    /// @param token The token to spend.
    /// @param to The recipient of the tokens.
    /// @param amount The amount of `token` to transfer.
    function _transferERC20Tokens(IERC20 token, address to, uint256 amount) internal {
        uint256 success;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transfer(address,uint256)
            mstore(ptr, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x24), amount)

            success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x44, ptr, 32)

            let rdsize := returndatasize()

            // Check for ERC20 success. ERC20 tokens should return a boolean,
            // but some don't. We accept 0-length return data as success, or at
            // least 32 bytes that starts with a 32-byte boolean true.
            success := and(
                success,                             // call itself succeeded
                or(
                    iszero(rdsize),                  // no return data, or
                    and(
                        iszero(lt(rdsize, 32)),      // at least 32 bytes
                        eq(mload(ptr), 1)            // starts with uint256(1)
                    )
                )
            )
        }
        require(success != 0, "_transferERC20/TRANSFER_FAILED");
    }


    /// @dev Transfers some amount of ETH to the given recipient and
    ///      reverts if the transfer fails.
    /// @param recipient The recipient of the ETH.
    /// @param amount The amount of ETH to transfer.
    function _transferEth(address payable recipient, uint256 amount) internal {
        if (amount > 0) {
            (bool success,) = recipient.call{value: amount}("");
            require(success, "_transferEth/TRANSFER_FAILED");
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2022 Element.Market

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IEtherToken is IERC20 {
    /// @dev Wrap ether.
    function deposit() external payable;

    /// @dev Unwrap ether.
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;


interface IFeeRecipient {

    /// @dev A callback function invoked in the ERC721Feature for each ERC721
    ///      order fee that get paid. Integrators can make use of this callback
    ///      to implement arbitrary fee-handling logic, e.g. splitting the fee
    ///      between multiple parties.
    /// @param tokenAddress The address of the token in which the received fee is
    ///        denominated. `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE` indicates
    ///        that the fee was paid in the native token (e.g. ETH).
    /// @param amount The amount of the given token received.
    /// @param feeData Arbitrary data encoded in the `Fee` used by this callback.
    /// @return success The selector of this function (0x0190805e),
    ///         indicating that the callback succeeded.
    function receiveZeroExFeeCallback(address tokenAddress, uint256 amount, bytes calldata feeData) external returns (bytes4 success);
}

// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;


interface ITakerCallback {

    /// @dev A taker callback function invoked in ERC721OrdersFeature and
    ///      ERC1155OrdersFeature between the maker -> taker transfer and
    ///      the taker -> maker transfer.
    /// @param orderHash The hash of the order being filled when this
    ///        callback is invoked.
    /// @param data Arbitrary data used by this callback.
    /// @return success The selector of this function,
    ///         indicating that the callback succeeded.
    function zeroExTakerCallback(bytes32 orderHash, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2022 Element.Market

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;

interface IAuthenticatedProxy {

    function implementation() external view returns (address);

    /**
     * Execute a message call from the proxy contract
     *
     * @dev Can be called by the user, or by a contract authorized by the registry as long as the user has not revoked access
     * @param dest Address to which the call will be sent
     * @param howToCall 0 - Call, 1 - DelegateCall
     * @param data Calldata to send
     * @return result Result of the call (success or failure)
     */
    function proxy(address dest, uint8 howToCall, bytes calldata data) external returns (bool);

    /**
     * Execute a message call and assert success
     *
     * @dev Same functionality as `proxy`, just asserts the return value
     * @param dest Address to which the call will be sent
     * @param howToCall 0 - Call, 1 - DelegateCall
     * @param data Calldata to send
     */
    function proxyAssert(address dest, uint8 howToCall, bytes calldata data) external;
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2022 Element.Market

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;

import {IAuthenticatedProxy} from './IAuthenticatedProxy.sol';

interface IProxyRegistry {
    function delegateProxyImplementation() external view returns (address);
    function proxies(address user) external view returns (IAuthenticatedProxy proxy);
}

// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../../zero-ex/src/features/libs/LibNFTOrder.sol";
import "../../zero-ex/src/features/libs/LibSignature.sol";
import "../../zero-ex/src/features/interfaces/IERC1155OrdersEvent.sol";


/// @dev Feature for interacting with ERC1155 orders.
interface ISharedERC1155OrdersFeature is IERC1155OrdersEvent {

    /// @dev Sells an ERC1155 asset to fill the given order.
    /// @param buyOrder The ERC1155 buy order.
    /// @param signature The order signature from the maker.
    /// @param erc1155TokenId The ID of the ERC1155 asset being
    ///        sold. If the given order specifies properties,
    ///        the asset must satisfy those properties. Otherwise,
    ///        it must equal the tokenId in the order.
    /// @param erc1155SellAmount The amount of the ERC1155 asset
    ///        to sell.
    /// @param unwrapNativeToken If this parameter is true and the
    ///        ERC20 token of the order is e.g. WETH, unwraps the
    ///        token before transferring it to the taker.
    /// @param callbackData If this parameter is non-zero, invokes
    ///        `zeroExERC1155OrderCallback` on `msg.sender` after
    ///        the ERC20 tokens have been transferred to `msg.sender`
    ///        but before transferring the ERC1155 asset to the buyer.
    function sellSharedERC1155(
        LibNFTOrder.ERC1155BuyOrder calldata buyOrder,
        LibSignature.Signature calldata signature,
        uint256 erc1155TokenId,
        uint128 erc1155SellAmount,
        bool unwrapNativeToken,
        bytes calldata callbackData
    )
        external;

    /// @dev Buys an ERC1155 asset by filling the given order.
    /// @param sellOrder The ERC1155 sell order.
    /// @param signature The order signature.
    /// @param erc1155BuyAmount The amount of the ERC1155 asset
    ///        to buy.
    /// @param callbackData If this parameter is non-zero, invokes
    ///        `zeroExERC1155OrderCallback` on `msg.sender` after
    ///        the ERC1155 asset has been transferred to `msg.sender`
    ///        but before transferring the ERC20 tokens to the seller.
    ///        Native tokens acquired during the callback can be used
    ///        to fill the order.
    function buySharedERC1155(
        LibNFTOrder.ERC1155SellOrder calldata sellOrder,
        LibSignature.Signature calldata signature,
        address taker,
        uint128 erc1155BuyAmount,
        bytes calldata callbackData
    )
        external
        payable;

    /// @dev Buys multiple ERC1155 assets by filling the
    ///      given orders.
    /// @param sellOrders The ERC1155 sell orders.
    /// @param signatures The order signatures.
    /// @param erc1155FillAmounts The amounts of the ERC1155 assets
    ///        to buy for each order.
    /// @param callbackData The data (if any) to pass to the taker
    ///        callback for each order. Refer to the `callbackData`
    ///        parameter to for `buyERC1155`.
    /// @param revertIfIncomplete If true, reverts if this
    ///        function fails to fill any individual order.
    /// @return successes An array of booleans corresponding to whether
    ///         each order in `orders` was successfully filled.
    function batchBuySharedERC1155s(
        LibNFTOrder.ERC1155SellOrder[] calldata sellOrders,
        LibSignature.Signature[] calldata signatures,
        address[] calldata takers,
        uint128[] calldata erc1155FillAmounts,
        bytes[] calldata callbackData,
        bool revertIfIncomplete
    )
        external
        payable
        returns (bool[] memory successes);

    /// @dev Matches a pair of complementary orders that have
    ///      a non-negative spread. Each order is filled at
    ///      their respective price, and the matcher receives
    ///      a profit denominated in the ERC20 token.
    /// @param sellOrder Order selling an ERC1155 asset.
    /// @param buyOrder Order buying an ERC1155 asset.
    /// @param sellOrderSignature Signature for the sell order.
    /// @param buyOrderSignature Signature for the buy order.
    /// @return profit The amount of profit earned by the caller
    ///         of this function (denominated in the ERC20 token
    ///         of the matched orders).
    function matchSharedERC1155Orders(
        LibNFTOrder.ERC1155SellOrder calldata sellOrder,
        LibNFTOrder.ERC1155BuyOrder calldata buyOrder,
        LibSignature.Signature calldata sellOrderSignature,
        LibSignature.Signature calldata buyOrderSignature
    )
        external
        returns (uint256 profit);

    /// @dev Matches pairs of complementary orders that have
    ///      non-negative spreads. Each order is filled at
    ///      their respective price, and the matcher receives
    ///      a profit denominated in the ERC20 token.
    /// @param sellOrders Orders selling ERC1155 assets.
    /// @param buyOrders Orders buying ERC1155 assets.
    /// @param sellOrderSignatures Signatures for the sell orders.
    /// @param buyOrderSignatures Signatures for the buy orders.
    /// @return profits The amount of profit earned by the caller
    ///         of this function for each pair of matched orders
    ///         (denominated in the ERC20 token of the order pair).
    /// @return successes An array of booleans corresponding to
    ///         whether each pair of orders was successfully matched.
    function batchMatchSharedERC1155Orders(
        LibNFTOrder.ERC1155SellOrder[] calldata sellOrders,
        LibNFTOrder.ERC1155BuyOrder[] calldata buyOrders,
        LibSignature.Signature[] calldata sellOrderSignatures,
        LibSignature.Signature[] calldata buyOrderSignatures
    )
        external
        returns (uint256[] memory profits, bool[] memory successes);
}

// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;


/// @dev Common storage helpers
library LibStorage {

    /// @dev What to bit-shift a storage ID by to get its slot.
    ///      This gives us a maximum of 2**128 inline fields in each bucket.
    uint256 constant STORAGE_ID_PROXY = 1 << 128;
    uint256 constant STORAGE_ID_SIMPLE_FUNCTION_REGISTRY = 2 << 128;
    uint256 constant STORAGE_ID_OWNABLE = 3 << 128;
    uint256 constant STORAGE_ID_COMMON_NFT_ORDERS = 4 << 128;
    uint256 constant STORAGE_ID_ERC721_ORDERS = 5 << 128;
    uint256 constant STORAGE_ID_ERC1155_ORDERS = 6 << 128;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;


interface IPropertyValidator {

    /// @dev Checks that the given ERC721/ERC1155 asset satisfies the properties encoded in `propertyData`.
    ///      Should revert if the asset does not satisfy the specified properties.
    /// @param tokenAddress The ERC721/ERC1155 token contract address.
    /// @param tokenId The ERC721/ERC1155 tokenId of the asset to check.
    /// @param propertyData Encoded properties or auxiliary data needed to perform the check.
    function validateProperty(address tokenAddress, uint256 tokenId, bytes calldata propertyData) external view;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libs/LibNFTOrder.sol";


interface IERC1155OrdersEvent {

    /// @dev Emitted whenever an `ERC1155SellOrder` is filled.
    /// @param maker The maker of the order.
    /// @param taker The taker of the order.
    /// @param erc20Token The address of the ERC20 token.
    /// @param erc20FillAmount The amount of ERC20 token filled.
    /// @param erc1155Token The address of the ERC1155 token.
    /// @param erc1155TokenId The ID of the ERC1155 asset.
    /// @param erc1155FillAmount The amount of ERC1155 asset filled.
    /// @param orderHash The `ERC1155SellOrder` hash.
    event ERC1155SellOrderFilled(
        address maker,
        address taker,
        IERC20 erc20Token,
        uint256 erc20FillAmount,
        address erc1155Token,
        uint256 erc1155TokenId,
        uint128 erc1155FillAmount,
        bytes32 orderHash
    );

    /// @dev Emitted whenever an `ERC1155BuyOrder` is filled.
    /// @param maker The maker of the order.
    /// @param taker The taker of the order.
    /// @param erc20Token The address of the ERC20 token.
    /// @param erc20FillAmount The amount of ERC20 token filled.
    /// @param erc1155Token The address of the ERC1155 token.
    /// @param erc1155TokenId The ID of the ERC1155 asset.
    /// @param erc1155FillAmount The amount of ERC1155 asset filled.
    /// @param orderHash The `ERC1155BuyOrder` hash.
    event ERC1155BuyOrderFilled(
        address maker,
        address taker,
        IERC20 erc20Token,
        uint256 erc20FillAmount,
        address erc1155Token,
        uint256 erc1155TokenId,
        uint128 erc1155FillAmount,
        bytes32 orderHash
    );

    /// @dev Emitted when an `ERC1155SellOrder` is pre-signed.
    ///      Contains all the fields of the order.
    event ERC1155SellOrderPreSigned(
        address maker,
        address taker,
        uint256 expiry,
        uint256 nonce,
        IERC20 erc20Token,
        uint256 erc20TokenAmount,
        LibNFTOrder.Fee[] fees,
        address erc1155Token,
        uint256 erc1155TokenId,
        uint128 erc1155TokenAmount
    );

    /// @dev Emitted when an `ERC1155BuyOrder` is pre-signed.
    ///      Contains all the fields of the order.
    event ERC1155BuyOrderPreSigned(
        address maker,
        address taker,
        uint256 expiry,
        uint256 nonce,
        IERC20 erc20Token,
        uint256 erc20TokenAmount,
        LibNFTOrder.Fee[] fees,
        address erc1155Token,
        uint256 erc1155TokenId,
        LibNFTOrder.Property[] erc1155TokenProperties,
        uint128 erc1155TokenAmount
    );

    /// @dev Emitted whenever an `ERC1155Order` is cancelled.
    /// @param maker The maker of the order.
    /// @param nonce The nonce of the order that was cancelled.
    event ERC1155OrderCancelled(address maker, uint256 nonce);
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