// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import { IOrderbookV1, OrderType, Order } from "./interfaces/IOrderbookV1.sol";
import { OrderbookUtilV1 } from "./utils/OrderbookUtilV1.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    BuyAtMarketResult, SellAtMarketResult, PlaceBuyOrderResult, PlaceSellOrderResult, ClaimOrderResult,
    TransferOrderResult, CancelOrderResult
} from "@theorderbookdex/orderbook-dex-operator/contracts/interfaces/IOperatorLogic.sol";

/**
 * Operator logic for V1 orderbooks.
 */
library OperatorLogicV1 {
    using OrderbookUtilV1 for IOrderbookV1;

    event Failed(bytes error);
    event BoughtAtMarket(uint256 amountBought, uint256 amountPaid);
    event SoldAtMarket(uint256 amountSold, uint256 amountReceived);
    event PlacedBuyOrder(uint256 amount, bytes orderId);
    event PlacedSellOrder(uint256 amount, bytes orderId);
    event OrderClaimed(uint256 amount);
    event OrderTransfered();
    event OrderCanceled(uint256 amount);

    function buyAtMarket(address orderbook, uint256 maxAmount, uint256 maxPrice, bytes calldata extraData) external
        returns (BuyAtMarketResult memory result)
    {
        if (maxAmount > type(uint64).max) {
            maxAmount = type(uint64).max;
        }
        (uint8 maxPricePoints) = abi.decode(extraData, (uint8));
        IERC20 baseToken = IOrderbookV1(orderbook).baseToken();
        if (maxPrice == type(uint256).max) {
            baseToken.approve(orderbook, maxPrice);
        } else {
            baseToken.approve(orderbook, maxAmount * maxPrice);
        }
        try IOrderbookV1(orderbook).fill(OrderType.SELL, uint64(maxAmount), maxPrice, maxPricePoints)
            returns (uint64 amountBought, uint256 amountPaid)
        {
            result.amountBought = amountBought;
            result.amountPaid = amountPaid;
            if (amountBought > 0) {
                emit BoughtAtMarket(amountBought, amountPaid);
            }
        } catch (bytes memory error) {
            result.failed = true;
            result.error = error;
            emit Failed(error);
        }
        if (baseToken.allowance(address(this), orderbook) != 0) {
            baseToken.approve(orderbook, 0);
        }
    }

    function sellAtMarket(address orderbook, uint256 maxAmount, uint256 minPrice, bytes calldata extraData) external
        returns (SellAtMarketResult memory result)
    {
        if (maxAmount > type(uint64).max) {
            maxAmount = type(uint64).max;
        }
        (uint8 maxPricePoints) = abi.decode(extraData, (uint8));
        IERC20 tradedToken = IOrderbookV1(orderbook).tradedToken();
        tradedToken.approve(orderbook, maxAmount * IOrderbookV1(orderbook).contractSize());
        try IOrderbookV1(orderbook).fill(OrderType.BUY, uint64(maxAmount), minPrice, maxPricePoints)
            returns (uint64 amountSold, uint256 amountReceived)
        {
            result.amountSold = amountSold;
            result.amountReceived = amountReceived;
            if (amountSold > 0) {
                emit SoldAtMarket(amountSold, amountReceived);
            }
        } catch (bytes memory error) {
            result.failed = true;
            result.error = error;
            emit Failed(error);
        }
        if (tradedToken.allowance(address(this), orderbook) != 0) {
            tradedToken.approve(orderbook, 0);
        }
    }

    function placeBuyOrder(address orderbook, uint256 maxAmount, uint256 price, bytes calldata extraData) external
        returns (PlaceBuyOrderResult memory result)
    {
        if (maxAmount > type(uint32).max) {
            maxAmount = type(uint32).max;
        }
        IERC20 baseToken = IOrderbookV1(orderbook).baseToken();
        baseToken.approve(orderbook, maxAmount * price);
        uint256 askPrice = IOrderbookV1(orderbook).askPrice();
        if (askPrice == 0 || price < askPrice) {
            try IOrderbookV1(orderbook).placeOrder(OrderType.BUY, price, uint32(maxAmount))
                returns (uint32 orderId)
            {
                bytes memory encodedOrderId = abi.encode(OrderType.BUY, price, orderId);
                result.amountPlaced = maxAmount;
                result.orderId = encodedOrderId;
                emit PlacedBuyOrder(maxAmount, encodedOrderId);
            } catch (bytes memory error) {
                result.failed = true;
                result.error = error;
                emit Failed(error);
            }
        } else {
            (uint8 maxPricePoints) = abi.decode(extraData, (uint8));
            try IOrderbookV1(orderbook).fill(OrderType.SELL, uint64(maxAmount), price, maxPricePoints)
                returns (uint64 amountBought, uint256 amountPaid)
            {
                result.amountBought = amountBought;
                result.amountPaid = amountPaid;
                if (amountBought > 0) {
                    emit BoughtAtMarket(amountBought, amountPaid);
                    maxAmount -= amountBought;
                }
                if (maxAmount != 0) {
                    askPrice = IOrderbookV1(orderbook).askPrice();
                    if (askPrice == 0 || price < askPrice) {
                        try IOrderbookV1(orderbook).placeOrder(OrderType.BUY, price, uint32(maxAmount))
                            returns (uint32 orderId)
                        {
                            bytes memory encodedOrderId = abi.encode(OrderType.BUY, price, orderId);
                            result.amountPlaced = maxAmount;
                            result.orderId = encodedOrderId;
                            emit PlacedBuyOrder(maxAmount, encodedOrderId);
                        } catch (bytes memory error) {
                            result.failed = true;
                            result.error = error;
                            emit Failed(error);
                        }
                    }
                }
            } catch (bytes memory error) {
                result.failed = true;
                result.error = error;
                emit Failed(error);
            }
        }
        if (baseToken.allowance(address(this), orderbook) != 0) {
            baseToken.approve(orderbook, 0);
        }
    }

    function placeSellOrder(address orderbook, uint256 maxAmount, uint256 price, bytes calldata extraData) external
        returns (PlaceSellOrderResult memory result)
    {
        if (price == 0) {
            // We do this here because the error won't be caught later
            result.failed = true;
            result.error = abi.encodePacked(IOrderbookV1.InvalidPrice.selector);
            emit Failed(result.error);
            return result;
        }
        if (maxAmount > type(uint32).max) {
            maxAmount = type(uint32).max;
        }
        IERC20 tradedToken = IOrderbookV1(orderbook).tradedToken();
        tradedToken.approve(orderbook, maxAmount * IOrderbookV1(orderbook).contractSize());
        uint256 bidPrice = IOrderbookV1(orderbook).bidPrice();
        if (price > bidPrice) {
            try IOrderbookV1(orderbook).placeOrder(OrderType.SELL, price, uint32(maxAmount))
                returns (uint32 orderId)
            {
                bytes memory encodedOrderId = abi.encode(OrderType.SELL, price, orderId);
                result.amountPlaced = maxAmount;
                result.orderId = encodedOrderId;
                emit PlacedSellOrder(maxAmount, encodedOrderId);
            } catch (bytes memory error) {
                result.failed = true;
                result.error = error;
                emit Failed(error);
            }
        } else {
            (uint8 maxPricePoints) = abi.decode(extraData, (uint8));
            try IOrderbookV1(orderbook).fill(OrderType.BUY, uint64(maxAmount), price, maxPricePoints)
                returns (uint64 amountSold, uint256 amountReceived)
            {
                result.amountSold = amountSold;
                result.amountReceived = amountReceived;
                if (amountSold > 0) {
                    emit SoldAtMarket(amountSold, amountReceived);
                    maxAmount -= amountSold;
                }
                if (maxAmount != 0) {
                    bidPrice = IOrderbookV1(orderbook).bidPrice();
                    if (price > bidPrice) {
                        try IOrderbookV1(orderbook).placeOrder(OrderType.SELL, price, uint32(maxAmount))
                            returns (uint32 orderId)
                        {
                            bytes memory encodedOrderId = abi.encode(OrderType.SELL, price, orderId);
                            result.amountPlaced = maxAmount;
                            result.orderId = encodedOrderId;
                            emit PlacedSellOrder(maxAmount, encodedOrderId);
                        } catch (bytes memory error) {
                            result.failed = true;
                            result.error = error;
                            emit Failed(error);
                        }
                    }
                }
            } catch (bytes memory error) {
                result.failed = true;
                result.error = error;
                emit Failed(error);
            }
        }
        if (tradedToken.allowance(address(this), orderbook) != 0) {
            tradedToken.approve(orderbook, 0);
        }
    }

    function claimOrder(address orderbook, bytes calldata orderId, bytes calldata extraData) external
        returns (ClaimOrderResult memory result)
    {
        (OrderType orderType, uint256 price, uint32 orderId_) = abi.decode(orderId, (OrderType, uint256, uint32));
        (uint32 maxAmount) = abi.decode(extraData, (uint32));
        try IOrderbookV1(orderbook).claimOrder(orderType, price, orderId_, maxAmount)
            returns (uint32 amountClaimed)
        {
            result.amountClaimed = amountClaimed;
            emit OrderClaimed(amountClaimed);
        } catch (bytes memory error) {
            result.failed = true;
            result.error = error;
            emit Failed(error);
        }
    }

    function transferOrder(address orderbook, bytes calldata orderId, address recipient) external
        returns (TransferOrderResult memory result)
    {
        (OrderType orderType, uint256 price, uint32 orderId_) = abi.decode(orderId, (OrderType, uint256, uint32));
        try IOrderbookV1(orderbook).transferOrder(orderType, price, orderId_, recipient) {
            emit OrderTransfered();
        } catch (bytes memory error) {
            result.failed = true;
            result.error = error;
            emit Failed(error);
        }
    }

    function cancelOrder(address orderbook, bytes calldata orderId, bytes calldata extraData) external
        returns (CancelOrderResult memory result)
    {
        (OrderType orderType, uint256 price, uint32 orderId_) = abi.decode(orderId, (OrderType, uint256, uint32));
        (uint32 maxLastOrderId) = abi.decode(extraData, (uint32));
        try IOrderbookV1(orderbook).cancelOrder(orderType, price, orderId_, maxLastOrderId)
            returns (uint32 amountCanceled)
        {
            result.amountCanceled = amountCanceled;
            emit OrderCanceled(amountCanceled);
        } catch (bytes memory error) {
            result.failed = true;
            result.error = error;
            emit Failed(error);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAddressBook } from "@theorderbookdex/addressbook/contracts/interfaces/IAddressBook.sol";
import { IOrderbook } from "@theorderbookdex/orderbook-dex/contracts/interfaces/IOrderbook.sol";

/**
 * Order type.
 */
enum OrderType {
    SELL,
    BUY
}

/**
 * Price point data.
 */
struct PricePoint {
    /**
     * The id of the last order placed.
     *
     * This start at zero and increases sequentially.
     */
    uint32 lastOrderId;

    /**
     * The id of the last order placed that has not been deleted.
     */
    uint32 lastActualOrderId;

    /**
     * The total amount of contracts placed.
     */
    uint64 totalPlaced;

    /**
     * The total amount of contracts filled.
     */
    uint64 totalFilled;
}

/**
 * Order data.
 */
struct Order {
    /**
     * The id of the owner of the order.
     */
    uint40 owner;

    /**
     * The amount of contracts placed by the order.
     */
    uint32 amount;

    /**
     * The amount of contracts claimed in the order.
     */
    uint32 claimed;

    /**
     * The total amount of contracts placed before the order.
     */
    uint64 totalPlacedBeforeOrder;

    /**
     * The id of the order placed before this that has not been deleted.
     */
    uint32 prevOrderId;

    /**
     * The id of the next order placed after this that has not been deleted.
     */
    uint32 nextOrderId;
}

/**
 * Orderbook exchange for a token pair.
 *
 * While still possible, this contract is not designed to be interacted directly by the user.
 * It will only emit events to help track the amount of contracts available at each price point.
 * It's delegated on the operator smart contract the responsibility of emitting events that
 * help track the user's orders and transaction's results.
 *
 * Observer (view) functions will not throw errors on invalid input or output.
 * It is the consumer's responsibility to make sure both that the input and output are valid.
 * This is so that smart contracts interacting with this one can be gas efficient.
 */
interface IOrderbookV1 is IOrderbook {
    /**
     * Event emitted when an order is placed.
     *
     * @param orderType the order type
     * @param price     the price point
     * @param amount    the amount of contracts
     */
    event Placed(
        OrderType orderType,
        uint256   price,
        uint32    amount
    );

    /**
     * Event emitted when orders are filled.
     *
     * @param orderType the order type
     * @param price     the price point
     * @param amount    the amount of contracts
     */
    event Filled(
        OrderType orderType,
        uint256   price,
        uint64    amount
    );

    /**
     * Event emitted when an order is canceled.
     *
     * @param orderType the order type
     * @param price     the price point
     * @param amount    the amount of contracts canceled
     */
    event Canceled(
        OrderType orderType,
        uint256   price,
        uint32    amount
    );

    /**
     * Error thrown when trying to deploy an orderbook with an invalid address book.
     */
    error InvalidAddressBook();

    /**
     * Error thrown when trying to deploy an orderbook with an invalid token pair.
     */
    error InvalidTokenPair();

    /**
     * Error thrown when trying to deploy an orderbook with an invalid contract size.
     */
    error InvalidContractSize();

    /**
     * Error thrown when trying to deploy an orderbook with an invalid price tick.
     */
    error InvalidPriceTick();

    /**
     * Error thrown when a price is zero or not a multiple of the price tick.
     */
    error InvalidPrice();

    /**
     * Error thrown when a function is called by someone not allowed to.
     */
    error Unauthorized();

    /**
     * Error thrown when trying to place a sell order at bid or below,
     * or a buy order at ask or above.
     */
    error CannotPlaceOrder();

    /**
     * Error thrown when a function is called with an invalid amount.
     */
    error InvalidAmount();

    /**
     * Error thrown when a function is called with an invalid order id.
     */
    error InvalidOrderId();

    /**
     * Error thrown when trying to access an order that's been deleted.
     */
    error OrderDeleted();

    /**
     * Error thrown when trying to cancel an order that has already been fully filled.
     */
    error AlreadyFilled();

    /**
     * Error thrown when the last order id has gone over the provided max last order id.
     */
    error OverMaxLastOrderId();

    /**
     * Error thrown when a function is called with an invalid argument that is not covered by other errors.
     */
    error InvalidArgument();

    /**
     * Place an order.
     *
     * The sender address must be registered in the orderbook's address book.
     *
     * The sender must give an allowance to this contract for the tokens given in exchange.
     *
     * Emits a {Placed} event.
     *
     * @param orderType the order type
     * @param price     the price point
     * @param amount    the amount of contracts
     * @return          the id of the order
     */
    function placeOrder(OrderType orderType, uint256 price, uint32 amount) external returns (uint32);

    /**
     * Fill orders.
     *
     * The sender must give an allowance to this contract for the token given in exchange.
     *
     * Orders are filled up to a maximum amount of contracts and at the specified or better price.
     * This means prices below or equal to maxPrice for sell orders, and prices above or equal to
     * maxPrice for buy orders.
     *
     * A zero value is allowed for maxPrice, as this can be used to fill buy orders without a price
     * restriction.
     *
     * If there are no orders that satisfy the requirements, the call will not revert but return
     * with a zero result.
     *
     * A Filled event will be emitted for each price point filled.
     *
     * The function will stop if it fills as many price points as indicated by maxPricePoints, to
     * avoid using more gas than allotted.
     *
     * Emits a {Filled} event for each price point filled.
     *
     * @param  orderType      the order type
     * @param  maxAmount      the maximum amount of contracts to fill
     * @param  maxPrice       the maximum price of a contract
     * @param  maxPricePoints the maximum amount of price points to fill
     * @return amountFilled   the amount of contracts filled
     * @return totalPrice     the total price for the contracts filled
     */
    function fill(OrderType orderType, uint64 maxAmount, uint256 maxPrice, uint8 maxPricePoints) external
        returns (uint64 amountFilled, uint256 totalPrice);

    /**
     * Claim an order.
     *
     * This can only be called by the order owner.
     *
     * An order can only be claimed up to the point it's been filled.
     *
     * The order will be deleted after it's filled and claimed completely.
     *
     * @param  orderType     the order type
     * @param  price         the price point
     * @param  orderId       the id of the order
     * @param  maxAmount     the maximum amount of contracts to claim
     * @return amountClaimed the amount of contracts claimed
     */
    function claimOrder(OrderType orderType, uint256 price, uint32 orderId, uint32 maxAmount) external
        returns (uint32 amountClaimed);

    /**
     * Cancel an order.
     *
     * This can only be called by the order owner.
     *
     * An order can only be canceled if it's not been fully filled.
     *
     * The order will be deleted if it's not been filled. Otherwise the order amount will be
     * updated up to where it's filled.
     *
     * Emits a {Canceled} event.
     *
     * @param  orderType        the order type
     * @param  price            the price point
     * @param  orderId          the id of the order
     * @param  maxLastOrderId   the maximum last order id can be before stopping this operation
     * @return amountCanceled   the amount of contracts canceled
     */
    function cancelOrder(OrderType orderType, uint256 price, uint32 orderId, uint32 maxLastOrderId) external
        returns (uint32 amountCanceled);

    /**
     * Transfer an order.
     *
     * This can only be called by the order owner.
     *
     * @param orderType the order type
     * @param price     the price point
     * @param orderId   the id of the order
     * @param newOwner  the maximum last order id can be before stopping this operation
     */
    function transferOrder(OrderType orderType, uint256 price, uint32 orderId, address newOwner) external;

    /**
     * The address book used by the orderbook.
     *
     * @return  the address book used by the orderbook
     */
    function addressBook() external view returns (IAddressBook);

    /**
     * The token being traded.
     *
     * @return  the token being traded
     */
    function tradedToken() external view returns (IERC20);

    /**
     * The token given in exchange and used for pricing.
     *
     * @return  the token given in exchange and used for pricing
     */
    function baseToken() external view returns (IERC20);

    /**
     * The size of a contract in tradedToken.
     *
     * @return  the size of a contract in tradedToken
     */
    function contractSize() external view returns (uint256);

    /**
     * The price tick in baseToken.
     *
     * All prices are multiples of this value.
     *
     * @return  the price tick in baseToken
     */
    function priceTick() external view returns (uint256);

    /**
     * The ask price in baseToken.
     *
     * @return  the ask price in baseToken
     */
    function askPrice() external view returns (uint256);

    /**
     * The bid price in baseToken.
     *
     * @return  the bid price in baseToken
     */
    function bidPrice() external view returns (uint256);

    /**
     * The next available sell price point.
     *
     * @param price an available sell price point
     * @return      the next available sell price point
     */
    function nextSellPrice(uint256 price) external view returns (uint256);

    /**
     * The next available buy price point.
     *
     * @param price an available buy price point
     * @return      the next available buy price point
     */
    function nextBuyPrice(uint256 price) external view returns (uint256);

    /**
     * The data of a price point.
     *
     * @param orderType the order type
     * @param price     the price point
     * @return          the data
     */
    function pricePoint(OrderType orderType, uint256 price) external view returns (PricePoint memory);

    /**
     * The data of an order.
     *
     * @param orderType the order type
     * @param price     the price point
     * @param orderId   the id of the order
     * @return          the data
     */
    function order(OrderType orderType, uint256 price, uint32 orderId) external view returns (Order memory);

    /**
     * The orderbook version.
     *
     * From right to left, the first two digits is the patch version, the second two digits the minor version,
     * and the rest is the major version, for example the value 10203 corresponds to version 1.2.3.
     *
     * @return the orderbook version
     */
    function version() external pure returns (uint32);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import { IOrderbookV1, OrderType, PricePoint, Order } from "../interfaces/IOrderbookV1.sol";

library OrderbookUtilV1 {
    /**
     * Check if a price point is valid.
     *
     * @param orderbook the orderbook
     * @param price     the price point
     * @return          true if the price point is valid
     */
    function priceValid(IOrderbookV1 orderbook, uint256 price) internal view returns (bool) {
        return price != 0 && price % orderbook.priceTick() == 0;
    }

    /**
     * The id of the last order placed for a price point.
     *
     * This start at zero and increases sequentially.
     *
     * @param orderbook the orderbook
     * @param orderType the order type
     * @param price     the price point
     * @return          the id of the last order placed
     */
    function lastOrderId(IOrderbookV1 orderbook, OrderType orderType, uint256 price) internal view returns (uint32) {
        return orderbook.pricePoint(orderType, price).lastOrderId;
    }

    /**
     * The amount of contracts available for a price point.
     *
     * @param orderbook the orderbook
     * @param orderType the order type
     * @param price     the price point
     * @return          the amount of contracts available
     */
    function available(IOrderbookV1 orderbook, OrderType orderType, uint256 price) internal view returns (uint64) {
        return available(orderbook.pricePoint(orderType, price));
    }

    /**
     * The amount of contracts available for a price point.
     *
     * @param pricePoint    the price point
     * @return              the amount of contracts available
     */
    function available(PricePoint memory pricePoint) internal pure returns (uint64) {
        return pricePoint.totalPlaced - pricePoint.totalFilled;
    }

    /**
     * Check if an order id is valid.
     *
     * @param orderbook the orderbook
     * @param orderType the order type
     * @param price     the price point
     * @param orderId   the id of the order
     * @return          true if the order id is valid
     */
    function orderIdValid(IOrderbookV1 orderbook, OrderType orderType, uint256 price, uint32 orderId)
        internal view returns (bool)
    {
        return orderIdValid(orderbook.pricePoint(orderType, price), orderId);
    }

    /**
     * Check if an order id is valid.
     *
     * @param pricePoint    the price point
     * @param orderId       the id of the order
     * @return              true if the order id is valid
     */
    function orderIdValid(PricePoint memory pricePoint, uint32 orderId) internal pure returns (bool) {
        return orderId != 0 && orderId <= pricePoint.lastOrderId;
    }

    /**
     * Check if an order exists.
     *
     * @param orderbook the orderbook
     * @param orderType the order type
     * @param price     the price point
     * @param orderId   the id of the order
     * @return          true if the order exists
     */
    function orderExists(IOrderbookV1 orderbook, OrderType orderType, uint256 price, uint32 orderId)
        internal view returns (bool)
    {
        return orderExists(orderbook.order(orderType, price, orderId));
    }

    /**
     * Check if an order exists.
     *
     * @param order     the order
     * @return          true if the order exists
     */
    function orderExists(Order memory order) internal pure returns (bool) {
        return order.owner != 0;
    }

    /**
     * The owner of an order.
     *
     * @param orderbook the orderbook
     * @param orderType the order type
     * @param price     the price point
     * @param orderId   the id of the order
     * @return          the owner of the order
     */
    function orderOwner(IOrderbookV1 orderbook, OrderType orderType, uint256 price, uint32 orderId)
        internal view returns (address)
    {
        return orderOwner(orderbook, orderbook.order(orderType, price, orderId));
    }

    /**
     * The owner of an order.
     *
     * @param orderbook the orderbook
     * @param order     the order
     * @return          the owner of the order
     */
    function orderOwner(IOrderbookV1 orderbook, Order memory order) internal view returns (address) {
        if (order.owner == 0) return address(0);
        return orderbook.addressBook().addr(order.owner);
    }

    /**
     * The amount of contracts placed by an order.
     *
     * @param orderbook the orderbook
     * @param orderType the order type
     * @param price     the price point
     * @param orderId   the id of the order
     * @return          the amount of contracts placed
     */
    function orderAmount(IOrderbookV1 orderbook, OrderType orderType, uint256 price, uint32 orderId)
        internal view returns (uint32)
    {
        return orderbook.order(orderType, price, orderId).amount;
    }

    /**
     * The amount of contracts filled in an order.
     *
     * @param orderbook the orderbook
     * @param orderType the order type
     * @param price     the price point
     * @param orderId   the id of the order
     * @return          the amount of contracts filled
     */
    function orderFilled(IOrderbookV1 orderbook, OrderType orderType, uint256 price, uint32 orderId)
        internal view returns (uint32)
    {
        return orderFilled(orderbook.pricePoint(orderType, price), orderbook.order(orderType, price, orderId));
    }

    /**
     * The amount of contracts filled in an order.
     *
     * @param pricePoint    the price point
     * @param order         the order
     * @return              the amount of contracts filled
     */
    function orderFilled(PricePoint memory pricePoint, Order memory order) internal pure returns (uint32) {
        if (pricePoint.totalFilled > order.totalPlacedBeforeOrder) {
            uint64 filledAmount = pricePoint.totalFilled - order.totalPlacedBeforeOrder;
            if (filledAmount > order.amount) {
                return order.amount;
            } else {
                return uint32(filledAmount);
            }
        } else {
            return 0;
        }
    }

    /**
     * The amount of contracts claimed in an order.
     *
     * @param orderbook the orderbook
     * @param orderType the order type
     * @param price     the price point
     * @param orderId   the id of the order
     * @return          the amount of contracts claimed
     */
    function orderClaimed(IOrderbookV1 orderbook, OrderType orderType, uint256 price, uint32 orderId)
        internal view returns (uint32)
    {
        return orderbook.order(orderType, price, orderId).claimed;
    }

    /**
     * The amount of contracts unclaimed in an order.
     *
     * @param orderbook the orderbook
     * @param orderType the order type
     * @param price     the price point
     * @param orderId   the id of the order
     * @return          the amount of contracts unclaimed
     */
    function orderUnclaimed(IOrderbookV1 orderbook, OrderType orderType, uint256 price, uint32 orderId)
        internal view returns (uint32)
    {
        return orderUnclaimed(orderbook.pricePoint(orderType, price), orderbook.order(orderType, price, orderId));
    }

    /**
     * The amount of contracts unclaimed in an order.
     *
     * @param pricePoint    the price point
     * @param order         the order
     * @return              the amount of contracts unclaimed
     */
    function orderUnclaimed(PricePoint memory pricePoint, Order memory order) internal pure returns (uint32) {
        return orderFilled(pricePoint, order) - order.claimed;
    }
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * Return value of buyAtMarket call.
 */
struct BuyAtMarketResult {
    /**
     * The amount of contracts bought.
     */
    uint256 amountBought;

    /**
     * The amount of base token paid.
     */
    uint256 amountPaid;

    /**
     * True if the operation failed.
     */
    bool failed;

    /**
     * The raw error data.
     */
    bytes error;
}

/**
 * Return value of sellAtMarket call.
 */
struct SellAtMarketResult {
    /**
     * The amount of contracts sold.
     */
    uint256 amountSold;

    /**
     * The amount of traded token received.
     */
    uint256 amountReceived;

    /**
     * True if the operation failed.
     */
    bool failed;

    /**
     * The raw error data.
     */
    bytes error;
}

/**
 * Return value of placeBuyOrder call.
 */
struct PlaceBuyOrderResult {
    /**
     * The amount of contracts bought.
     *
     * This might be non zero even if the operation fails, which means it managed to buy some
     * before failing.
     */
    uint256 amountBought;

    /**
     * The amount of base token paid.
     *
     * This might be non zero even if the operation fails, which means it managed to buy some
     * before failing.
     */
    uint256 amountPaid;

    /**
     * The amount of contracts of the placed order.
     */
    uint256 amountPlaced;

    /**
     * The encoded order id.
     */
    bytes orderId;

    /**
     * True if the operation failed.
     */
    bool failed;

    /**
     * The raw error data.
     */
    bytes error;
}

/**
 * Return value of placeSellOrder call.
 */
struct PlaceSellOrderResult {
    /**
     * The amount of contracts sold.
     *
     * This might be non zero even if the operation fails, which means it managed to sell some
     * before failing.
     */
    uint256 amountSold;

    /**
     * The amount of traded token received.
     *
     * This might be non zero even if the operation fails, which means it managed to sell some
     * before failing.
     */
    uint256 amountReceived;

    /**
     * The amount of contracts of the placed order.
     */
    uint256 amountPlaced;

    /**
     * The encoded order id.
     */
    bytes orderId;

    /**
     * True if the operation failed.
     */
    bool failed;

    /**
     * The raw error data.
     */
    bytes error;
}

/**
 * Return value of claimOrder call.
 */
struct ClaimOrderResult {
    /**
     * The amount of contracts claimed.
     */
    uint256 amountClaimed;

    /**
     * True if the operation failed.
     */
    bool failed;

    /**
     * The raw error data.
     */
    bytes error;
}

/**
 * Return value of transferOrder call.
 */
struct TransferOrderResult {
    /**
     * True if the operation failed.
     */
    bool failed;

    /**
     * The raw error data.
     */
    bytes error;
}

/**
 * Return value of cancelOrder call.
 */
struct CancelOrderResult {
    /**
     * The amount of contracts canceled.
     */
    uint256 amountCanceled;

    /**
     * True if the operation failed.
     */
    bool failed;

    /**
     * The raw error data.
     */
    bytes error;
}

/**
 * Operator logic.
 *
 * All functions must not modify the contract's storage. Because of this, it's
 * preferable that the implementation is provided as a library rather than as a
 * contract.
 *
 * The first argument of all functions must always be the address of the orderbook
 * to operate on. It's the caller's responsibility to check the version of the
 * orderbook and call the appropriate operator logic.
 */
interface IOperatorLogic {
    /**
     * Event emitted to provide feedback when an error is thrown by the orderbook.
     *
     * @param error the raw error data
     */
    event Failed(bytes error);

    /**
     * Event emitted to provide feedback after a buyAtMarket call.
     *
     * @param amountBought  the amount of contracts bought
     * @param amountPaid    the amount of base token paid
     */
    event BoughtAtMarket(uint256 amountBought, uint256 amountPaid);

    /**
     * Event emitted to provide feedback after a sellAtMarket call.
     *
     * @param amountSold        the amount of contracts sold
     * @param amountReceived    the amount of traded token received
     */
    event SoldAtMarket(uint256 amountSold, uint256 amountReceived);

    /**
     * Event emitted to provide feedback after a placeBuyOrder call.
     *
     * @param amount    the amount of contracts of the placed order
     * @param orderId   the encoded order id
     */
    event PlacedBuyOrder(uint256 amount, bytes orderId);

    /**
     * Event emitted to provide feedback after a placeSellOrder call.
     *
     * @param amount    the amount of contracts of the placed order
     * @param orderId   the encoded order id
     */
    event PlacedSellOrder(uint256 amount, bytes orderId);

    /**
     * Event emitted to provide feedback after a claimOrder call.
     *
     * @param amount    the amount of contracts claimed
     */
    event OrderClaimed(uint256 amount);

    /**
     * Event emitted to provide feedback after a transferOrder call.
     */
    event OrderTransfered();

    /**
     * Event emitted to provide feedback after a cancelOrder call.
     *
     * @param amount    the amount of contracts canceled
     */
    event OrderCanceled(uint256 amount);

    /**
     * Buy at market.
     *
     * @param orderbook the orderbook
     * @param maxAmount the maximum amount of contracts to buy
     * @param maxPrice  the maximum price to pay for contract
     * @param extraData extra data that might be required by the operation
     *
     * Emits a {BoughtAtMarket} event if it manages to buy any amount.
     *
     * Emits a {Failed} if there is an error when calling the orderbook contract.
     */
    function buyAtMarket(address orderbook, uint256 maxAmount, uint256 maxPrice, bytes calldata extraData) external
        returns (BuyAtMarketResult memory result);

    /**
     * Sell at market.
     *
     * @param orderbook the orderbook
     * @param maxAmount the maximum amount of contracts to sell
     * @param minPrice  the minimum price to pay for contract
     * @param extraData extra data that might be required by the operation
     *
     * Emits a {SoldAtMarket} event if it manages to sell any amount.
     *
     * Emits a {Failed} if there is an error when calling the orderbook contract.
     */
    function sellAtMarket(address orderbook, uint256 maxAmount, uint256 minPrice, bytes calldata extraData) external
        returns (SellAtMarketResult memory result);

    /**
     * Place buy order.
     *
     * If the bid price is at or above the provided price, it will attempt to buy at market first, and place an
     * order for the remainder.
     *
     * @param orderbook the orderbook
     * @param maxAmount the maximum amount of contracts to buy
     * @param price     the price to pay for contract
     * @param extraData extra data that might be required by the operation
     *
     * Emits a {BoughtAtMarket} event if it manages to buy any amount.
     *
     * Emits a {PlacedBuyOrder} event if it manages to place an order.
     *
     * Emits a {Failed} if there is an error when calling the orderbook contract.
     */
    function placeBuyOrder(address orderbook, uint256 maxAmount, uint256 price, bytes calldata extraData) external
        returns (PlaceBuyOrderResult memory result);

    /**
     * Place sell order.
     *
     * If the ask price is at or below the provided price, it will attempt to sell at market first, and place an
     * order for the remainder.
     *
     * Emits a {SoldAtMarket} event if it manages to sell any amount.
     *
     * Emits a {PlacedSellOrder} event if it manages to place an order.
     *
     * Emits a {Failed} if there is an error when calling the orderbook contract.
     *
     * @param orderbook the orderbook
     * @param maxAmount the maximum amount of contracts to sell
     * @param price     the price to pay for contract
     * @param extraData extra data that might be required by the operation
     */
    function placeSellOrder(address orderbook, uint256 maxAmount, uint256 price, bytes calldata extraData) external
        returns (PlaceSellOrderResult memory result);

    /**
     * Claim an order.
     *
     * Emits a {OrderClaimed} event if it manages to claim any amount.
     *
     * Emits a {Failed} if there is an error when calling the orderbook contract.
     *
     * @param orderbook the orderbook
     * @param orderId   the encoded order id
     * @param extraData extra data that might be required by the operation
     */
    function claimOrder(address orderbook, bytes calldata orderId, bytes calldata extraData) external
        returns (ClaimOrderResult memory result);

    /**
     * Transfer an order.
     *
     * Emits a {OrderTransfered} event if it manages to transfer the order.
     *
     * Emits a {Failed} if there is an error when calling the orderbook contract.
     *
     * @param orderbook the orderbook
     * @param orderId   the encoded order id
     * @param recipient the recipient of the transfer
     */
    function transferOrder(address orderbook, bytes calldata orderId, address recipient) external
        returns (TransferOrderResult memory result);

    /**
     * Cancel an order.
     *
     * Emits a {OrderCanceled} event if it manages to cancel the order.
     *
     * Emits a {Failed} if there is an error when calling the orderbook contract.
     *
     * @param orderbook the orderbook
     * @param orderId   the encoded order id
     * @param extraData extra data that might be required by the operation
     */
    function cancelOrder(address orderbook, bytes calldata orderId, bytes calldata extraData) external
        returns (CancelOrderResult memory result);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Contract that keeps an address book.
 *
 * The address book maps addresses to 32 bits ids so that they can be used to reference
 * an address using less data.
 */
interface IAddressBook {
    /**
     * Event emitted when an address is registered in the address book.
     *
     * @param addr  the address
     * @param id    the id
     */
    event Registered(address indexed addr, uint40 indexed id);

    /**
     * Error thrown when an address has already been registered.
     */
    error AlreadyRegistered();

    /**
     * Register the address of the caller in the address book.
     *
     * @return  the id
     */
    function register() external returns (uint40);

    /**
     * The id of the last registered address.
     *
     * @return  the id of the last registered address
     */
    function lastId() external view returns (uint40);

    /**
     * The id matching an address.
     *
     * @param  addr the address
     * @return      the id
     */
    function id(address addr) external view returns (uint40);

    /**
     * The address matching an id.
     *
     * @param  id   the id
     * @return      the address
     */
    function addr(uint40 id) external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * Orderbook exchange for a token pair.
 */
interface IOrderbook {
    /**
     * The orderbook version.
     *
     * From right to left, the first two digits is the patch version, the second two digits the minor version,
     * and the rest is the major version, for example the value 10203 corresponds to version 1.2.3.
     *
     * @return the orderbook version
     */
    function version() external view returns (uint32);

    /**
     * The token being traded.
     *
     * @return  the token being traded
     */
    function tradedToken() external view returns (IERC20);

    /**
     * The token given in exchange and used for pricing.
     *
     * @return  the token given in exchange and used for pricing
     */
    function baseToken() external view returns (IERC20);

    /**
     * The size of a contract in tradedToken.
     *
     * @return  the size of a contract in tradedToken
     */
    function contractSize() external view returns (uint256);

    /**
     * The price tick in baseToken.
     *
     * All prices are multiples of this value.
     *
     * @return  the price tick in baseToken
     */
    function priceTick() external view returns (uint256);
}