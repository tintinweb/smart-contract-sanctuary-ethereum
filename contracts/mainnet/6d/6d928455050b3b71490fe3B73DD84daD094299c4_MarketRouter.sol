// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

import "./interfaces/CloberOrderBook.sol";
import "./interfaces/CloberMarketSwapCallbackReceiver.sol";
import "./interfaces/CloberRouter.sol";
import "./interfaces/CloberMarketFactory.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/CloberOrderNFT.sol";
import "./Errors.sol";

contract MarketRouter is CloberMarketSwapCallbackReceiver, CloberRouter {
    using SafeERC20 for IERC20;

    bool private constant _BID = true;
    bool private constant _ASK = false;

    CloberMarketFactory private immutable _factory;

    modifier checkDeadline(uint64 deadline) {
        if (block.timestamp > deadline) {
            revert Errors.CloberError(Errors.DEADLINE);
        }
        _;
    }

    constructor(address factory) {
        _factory = CloberMarketFactory(factory);
    }

    function cloberMarketSwapCallback(
        address inputToken,
        address,
        uint256 inputAmount,
        uint256,
        bytes calldata data
    ) external payable {
        // check if caller is registered market
        if (_factory.getMarketHost(msg.sender) == address(0)) {
            revert Errors.CloberError(Errors.ACCESS);
        }

        (address payer, bool useNative) = abi.decode(data, (address, bool));

        // transfer input tokens
        if (useNative) {
            uint256 nativeAmount = address(this).balance - msg.value;
            (inputAmount, nativeAmount) = nativeAmount > inputAmount
                ? (0, inputAmount)
                : (inputAmount - nativeAmount, nativeAmount);

            IWETH(inputToken).deposit{value: nativeAmount}();
            IWETH(inputToken).transfer(msg.sender, nativeAmount);
        }
        if (inputAmount > 0) {
            IERC20(inputToken).safeTransferFrom(payer, msg.sender, inputAmount);
        }

        if (address(this).balance > 0) {
            (bool success, ) = payer.call{value: address(this).balance}("");
            if (!success) {
                revert Errors.CloberError(Errors.FAILED_TO_SEND_VALUE);
            }
        }
    }

    function limitBid(LimitOrderParams calldata params)
        external
        payable
        checkDeadline(params.deadline)
        returns (uint256)
    {
        return _limitOrder(params, _BID);
    }

    function limitAsk(LimitOrderParams calldata params)
        external
        payable
        checkDeadline(params.deadline)
        returns (uint256)
    {
        return _limitOrder(params, _ASK);
    }

    function _limitOrder(LimitOrderParams calldata params, bool isBid) internal returns (uint256) {
        return
            CloberOrderBook(params.market).limitOrder{value: uint256(params.claimBounty) * 1 gwei}(
                params.user,
                params.priceIndex,
                params.rawAmount,
                params.baseAmount,
                (isBid ? 1 : 0) + (params.postOnly ? 2 : 0),
                abi.encode(msg.sender, params.useNative)
            );
    }

    function marketBid(MarketOrderParams calldata params) external payable checkDeadline(params.deadline) {
        _marketOrder(params, _BID);
    }

    function marketAsk(MarketOrderParams calldata params) external payable checkDeadline(params.deadline) {
        _marketOrder(params, _ASK);
    }

    function _marketOrder(MarketOrderParams calldata params, bool isBid) internal {
        CloberOrderBook(params.market).marketOrder(
            params.user,
            params.limitPriceIndex,
            params.rawAmount,
            params.baseAmount,
            (isBid ? 1 : 0) + (params.expendInput ? 2 : 0),
            abi.encode(msg.sender, params.useNative)
        );
    }

    function claim(uint64 deadline, ClaimOrderParams[] calldata paramsList) external checkDeadline(deadline) {
        _claim(paramsList);
    }

    function _claim(ClaimOrderParams[] calldata paramsList) internal {
        for (uint256 i = 0; i < paramsList.length; ++i) {
            ClaimOrderParams calldata params = paramsList[i];
            CloberOrderBook(params.market).claim(msg.sender, params.orderKeys);
        }
    }

    function limitBidAfterClaim(ClaimOrderParams[] calldata claimParamsList, LimitOrderParams calldata limitOrderParams)
        external
        payable
        checkDeadline(limitOrderParams.deadline)
        returns (uint256)
    {
        _claim(claimParamsList);
        return _limitOrder(limitOrderParams, _BID);
    }

    function limitAskAfterClaim(ClaimOrderParams[] calldata claimParamsList, LimitOrderParams calldata limitOrderParams)
        external
        payable
        checkDeadline(limitOrderParams.deadline)
        returns (uint256)
    {
        _claim(claimParamsList);
        return _limitOrder(limitOrderParams, _ASK);
    }

    function marketBidAfterClaim(
        ClaimOrderParams[] calldata claimParamsList,
        MarketOrderParams calldata marketOrderParams
    ) external payable checkDeadline(marketOrderParams.deadline) {
        _claim(claimParamsList);
        _marketOrder(marketOrderParams, _BID);
    }

    function marketAskAfterClaim(
        ClaimOrderParams[] calldata claimParamsList,
        MarketOrderParams calldata marketOrderParams
    ) external payable checkDeadline(marketOrderParams.deadline) {
        _claim(claimParamsList);
        _marketOrder(marketOrderParams, _ASK);
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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./CloberOrderKey.sol";

interface CloberRouter {
    /**
     * @notice LimitOrderParams struct contains information about a limit order.
     * @param market The address of the market for this order.
     * @param deadline The deadline for the transaction. Reverts if the block timestamp is greater than this value.
     * @param claimBounty The bounty the user is willing to pay in gwei to delegate claiming.
     * @param user The address of the user placing the order.
     * @param priceIndex The price book index.
     * @param rawAmount The raw quote amount to trade, utilized by bids.
     * @param postOnly Flag indicating if the order should only be placed if it does not fill any existing orders.
     * @param useNative Flag indicating whether the order should use the native token supplied.
     * Only works when the input in the wrapped native token.
     * @param baseAmount The base token amount to trade, utilized by asks.
     */
    struct LimitOrderParams {
        address market;
        uint64 deadline;
        uint32 claimBounty;
        address user;
        uint16 priceIndex;
        uint64 rawAmount;
        bool postOnly;
        bool useNative;
        uint256 baseAmount;
    }

    /**
     * @notice Places a limit order on the bid side.
     * @param params The limit order parameters.
     * @return The order index. If an order is not made `type(uint256).max` is returned instead.
     */
    function limitBid(LimitOrderParams calldata params) external payable returns (uint256);

    /**
     * @notice Places a limit order on the ask side.
     * @param params The limit order parameters.
     * @return The order index. If an order is not made `type(uint256).max` is returned instead.
     */
    function limitAsk(LimitOrderParams calldata params) external payable returns (uint256);

    /**
     * @notice MarketOrderParams struct contains information about a market order.
     * @param market The address of the market for this order.
     * @param deadline The deadline for the transaction. Reverts if the block timestamp is greater than this value.
     * @param user The address of the user placing the order.
     * @param limitPriceIndex Index of the price at which to limit the order.
     * @param rawAmount The raw amount to trade.
     * This value is used as the maximum input amount by bids and minimum output amount by asks.
     * @param expendInput Flag indicating whether the order should spend all of the user's
     * input tokens (true) or just until the desired output amount is met (false).
     * @param useNative Flag indicating whether the order should use the native token supplied.
     * Only works when the input in the wrapped native token.
     * @param baseAmount The base token amount to trade.
     * This value is used as the maximum input amount by asks and minimum output amount by bids.
     */
    struct MarketOrderParams {
        address market;
        uint64 deadline;
        address user;
        uint16 limitPriceIndex;
        uint64 rawAmount;
        bool expendInput;
        bool useNative;
        uint256 baseAmount;
    }

    /**
     * @notice Place a market order on the bid side.
     * @param params The market order parameters.
     */
    function marketBid(MarketOrderParams calldata params) external payable;

    /**
     * @notice Place a market order on the ask side.
     * @param params The market order parameters.
     */
    function marketAsk(MarketOrderParams calldata params) external payable;

    /**
     * @notice Struct for passing parameters to the function that claims orders.
     * @param market The market address of the orders to claim from.
     * @param orderKeys An array of OrderKey structs representing the keys of the orders being claimed.
     */
    struct ClaimOrderParams {
        address market;
        OrderKey[] orderKeys;
    }

    /**
     * @notice Claims orders across markets.
     * @param deadline The deadline for the transaction. Reverts if the block timestamp is greater than this value.
     * @param paramsList The list of ClaimOrderParams
     */
    function claim(uint64 deadline, ClaimOrderParams[] calldata paramsList) external;

    /**
     * @notice Submits a limit bid order to the order book after claiming a list of orders.
     * @param claimParamsList Array of ClaimOrderParams: The list of orders to be claimed.
     * @param limitOrderParams LimitOrderParams: The parameters for the limit order.
     * @return The order index. If an order is not made `type(uint256).max` is returned instead.
     */
    function limitBidAfterClaim(ClaimOrderParams[] calldata claimParamsList, LimitOrderParams calldata limitOrderParams)
        external
        payable
        returns (uint256);

    /**
     * @notice Submits a limit ask order to the order book after claiming a list of orders.
     * @param claimParamsList Array of ClaimOrderParams: The list of orders to be claimed.
     * @param limitOrderParams LimitOrderParams: The parameters for the limit order.
     * @return The order index. If an order is not made `type(uint256).max` is returned instead.
     */
    function limitAskAfterClaim(ClaimOrderParams[] calldata claimParamsList, LimitOrderParams calldata limitOrderParams)
        external
        payable
        returns (uint256);

    /**
     * @notice Submits a market bid order to the order book after claiming a list of orders.
     * @param claimParamsList Array of ClaimOrderParams: The list of orders to be claimed.
     * @param marketOrderParams MarketOrderParams: The parameters for the market order.
     */
    function marketBidAfterClaim(
        ClaimOrderParams[] calldata claimParamsList,
        MarketOrderParams calldata marketOrderParams
    ) external payable;

    /**
     * @notice Submits a market ask order to the order book after claiming a list of orders.
     * @param claimParamsList Array of ClaimOrderParams: The list of orders to be claimed.
     * @param marketOrderParams MarketOrderParams: The parameters for the market order.
     */
    function marketAskAfterClaim(
        ClaimOrderParams[] calldata claimParamsList,
        MarketOrderParams calldata marketOrderParams
    ) external payable;
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

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