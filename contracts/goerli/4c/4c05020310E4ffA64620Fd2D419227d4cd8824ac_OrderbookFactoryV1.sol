// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import { IAddressBook } from "@frugal-wizard/addressbook/contracts/interfaces/IAddressBook.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IOrderbookV1 } from "./interfaces/IOrderbookV1.sol";
import { IOrderbookFactoryV1 } from "./interfaces/IOrderbookFactoryV1.sol";
import { OrderbookV1 } from "./OrderbookV1.sol";

/**
 * Orderbook factory.
 *
 * All orderbooks created by this factory use the same address book.
 */
contract OrderbookFactoryV1 is IOrderbookFactoryV1 {
    /**
     * The address book used by the factory.
     */
    IAddressBook private immutable _addressBook;

    /**
     * Total number of orderbooks created by this factory.
     */
    uint256 private _totalCreated;

    /**
     * Orderbooks by index.
     */
    mapping(uint256 => IOrderbookV1) _orderbooks;

    /**
     * Constructor.
     *
     * @param addressBook_ the address book used by the factory
     */
    constructor(IAddressBook addressBook_) {
        if (address(addressBook_) == address(0)) {
            revert InvalidAddressBook();
        }
        _addressBook = addressBook_;
    }

    function createOrderbook(
        IERC20  tradedToken,
        IERC20  baseToken,
        uint256 contractSize,
        uint256 priceTick
    ) external returns (IOrderbookV1) {
        IOrderbookV1 orderbook_ = new OrderbookV1(_addressBook, tradedToken, baseToken, contractSize, priceTick);
        _orderbooks[_totalCreated] = orderbook_;
        _totalCreated++;
        emit OrderbookCreated(
            10000, address(orderbook_), address(tradedToken), address(baseToken), contractSize, priceTick
        );
        return orderbook_;
    }

    function addressBook() external view returns (IAddressBook) {
        return _addressBook;
    }

    function totalCreated() external view returns (uint256) {
        return _totalCreated;
    }

    function orderbook(uint256 index) external view returns(IOrderbookV1) {
        return _orderbooks[index];
    }

    function orderbooks(uint256 index, uint256 length) external view returns(IOrderbookV1[] memory) {
        IOrderbookV1[] memory orderbooks_ = new IOrderbookV1[](length);
        for (uint256 i = 0; i < length; i++) {
            orderbooks_[i] = _orderbooks[index + i];
        }
        return orderbooks_;
    }
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

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAddressBook } from "@frugal-wizard/addressbook/contracts/interfaces/IAddressBook.sol";
import { IOrderbook } from "@theorderbookdex/orderbook-dex/contracts/interfaces/IOrderbook.sol";

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
     * @param  orderType the order type
     * @param  price     the price point
     * @param  amount    the amount of contracts
     * @return orderId   the id of the order
     */
    function placeOrder(OrderType orderType, uint256 price, uint32 amount) external returns (uint32 orderId);

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
     * The data of a price point.
     *
     * @param  orderType  the order type
     * @param  price      the price point
     * @return pricePoint the data
     */
    function pricePoint(OrderType orderType, uint256 price) external view returns (PricePoint memory pricePoint);

    /**
     * The data of an order.
     *
     * @param  orderType the order type
     * @param  price     the price point
     * @param  orderId   the id of the order
     * @return order     the data
     */
    function order(OrderType orderType, uint256 price, uint32 orderId) external view returns (Order memory order);
}

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAddressBook } from "@frugal-wizard/addressbook/contracts/interfaces/IAddressBook.sol";
import { IOrderbookFactory } from "@theorderbookdex/orderbook-dex/contracts/interfaces/IOrderbookFactory.sol";
import { IOrderbookV1 } from "./IOrderbookV1.sol";

/**
 * Orderbook factory.
 *
 * All orderbooks created by this factory use the same address book.
 */
interface IOrderbookFactoryV1 is IOrderbookFactory {
    /**
     * Error thrown when trying to deploy a factory with an invalid address book.
     */
    error InvalidAddressBook();

    /**
     * Create an orderbook.
     *
     * @param tradedToken  the token being traded
     * @param baseToken    the token given in exchange and used for pricing
     * @param contractSize the size of a contract in tradedToken
     * @param priceTick    the price tick in baseToken
     */
    function createOrderbook(
        IERC20  tradedToken,
        IERC20  baseToken,
        uint256 contractSize,
        uint256 priceTick
    ) external returns (IOrderbookV1);

    /**
     * The address book used by the factory.
     *
     * @return addressBook the address book used by the factory
     */
    function addressBook() external view returns (IAddressBook addressBook);

    /**
     * Total number of orderbooks created by this factory.
     *
     * @return totalCreated total number of orderbooks created by this factory
     */
    function totalCreated() external view returns (uint256 totalCreated);

    /**
     * The orderbook created by this factory at a specific index.
     *
     * Index is not validated by this function, it's the caller responsibility to verify that the index is valid.
     *
     * @param  index     the index to fetch
     * @return orderbook the orderbook created at index provided
     */
    function orderbook(uint256 index) external view returns(IOrderbookV1 orderbook);

    /**
     * The orderbooks created by this factory at a specific index range.
     *
     * Range is not validated by this function, it's the caller responsibility to verify that the range is valid.
     *
     * @param  index      the start index
     * @param  length     the range length
     * @return orderbooks the orderbook created at index provided
     */
    function orderbooks(uint256 index, uint256 length) external view returns(IOrderbookV1[] memory orderbooks);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import { IOrderbookV1, OrderType, PricePoint, Order } from "./interfaces/IOrderbookV1.sol";
import { IAddressBook } from "@frugal-wizard/addressbook/contracts/interfaces/IAddressBook.sol";
import { AddressBookUtil } from "@frugal-wizard/addressbook/contracts/utils/AddressBookUtil.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract OrderbookV1 is IOrderbookV1 {
    using AddressBookUtil for IAddressBook;
    using SafeERC20 for IERC20;

    /**
     * The address book used by the orderbook.
     */
    IAddressBook private immutable _addressBook;

    /**
     * The token being traded.
     */
    IERC20 private immutable _tradedToken;

    /**
     * The token given in exchange and used for pricing.
     */
    IERC20 private immutable _baseToken;

    /**
     * The size of a contract in tradedToken.
     */
    uint256 private immutable _contractSize;

    /**
     * The price tick in baseToken.
     */
    uint256 private immutable _priceTick;

    /**
     * The data of price points.
     */
    mapping(OrderType => mapping(uint256 => PricePoint)) private _pricePoints;

    /**
     * The data of orders.
     */
    mapping(OrderType => mapping(uint256 => mapping(uint32 => Order))) internal _orders;

    /**
     * The ask price in baseToken.
     */
    uint256 private _askPrice;

    /**
     * The bid price in baseToken.
     */
    uint256 private _bidPrice;

    /**
     * The next available sell price point.
     */
    mapping(uint256 => uint256) private _nextSellPrice;

    /**
     * The next available buy price point.
     */
    mapping(uint256 => uint256) private _nextBuyPrice;

    /**
     * Constructor.
     *
     * @param addressBook_  the address book used by the orderbook
     * @param tradedToken_  the token being traded
     * @param baseToken_    the token given in exchange and used for pricing
     * @param contractSize_ the size of a contract in tradedToken
     * @param priceTick_    the price tick in baseToken
     */
    constructor(
        IAddressBook    addressBook_,
        IERC20          tradedToken_,
        IERC20          baseToken_,
        uint256         contractSize_,
        uint256         priceTick_
    ) {
        if (address(addressBook_) == address(0)) {
            revert InvalidAddressBook();
        }
        if (address(tradedToken_) == address(0)) {
            revert InvalidTokenPair();
        }
        if (address(baseToken_) == address(0)) {
            revert InvalidTokenPair();
        }
        if (tradedToken_ == baseToken_) {
            revert InvalidTokenPair();
        }
        if (contractSize_ == 0) {
            revert InvalidContractSize();
        }
        if (priceTick_ == 0) {
            revert InvalidPriceTick();
        }
        _addressBook    = addressBook_;
        _tradedToken    = tradedToken_;
        _baseToken      = baseToken_;
        _contractSize   = contractSize_;
        _priceTick      = priceTick_;
    }

    function placeOrder(OrderType orderType, uint256 price, uint32 amount) external returns (uint32) {
        if (orderType == OrderType.SELL) {
            uint256 bidPrice_ = _bidPrice;
            if (bidPrice_ != 0 && price <= bidPrice_) {
                revert CannotPlaceOrder();
            }
        } else {
            uint256 askPrice_ = _askPrice;
            if (askPrice_ != 0 && price >= askPrice_) {
                revert CannotPlaceOrder();
            }
        }

        if (amount == 0) {
            revert InvalidAmount();
        }

        if (price == 0 || price % _priceTick != 0) {
            revert InvalidPrice();
        }

        PricePoint memory pricePoint_ = _pricePoints[orderType][price];

        if (pricePoint_.totalPlaced == pricePoint_.totalFilled) {
            addPrice(orderType, price);
        }

        pricePoint_.lastOrderId++;

        _orders[orderType][price][pricePoint_.lastOrderId] = Order(
            _addressBook.safeId(msg.sender),
            amount,
            0,
            pricePoint_.totalPlaced,
            pricePoint_.lastActualOrderId,
            0
        );

        _orders[orderType][price][pricePoint_.lastActualOrderId].nextOrderId = pricePoint_.lastOrderId;

        pricePoint_.lastActualOrderId = pricePoint_.lastOrderId;
        pricePoint_.totalPlaced += amount;

        _pricePoints[orderType][price] = pricePoint_;

        if (orderType == OrderType.SELL) {
            _tradedToken.safeTransferFrom(msg.sender, address(this), amount * _contractSize);
        } else {
            _baseToken.safeTransferFrom(msg.sender, address(this), amount * price);
        }

        emit Placed(orderType, price, amount);

        return pricePoint_.lastOrderId;
    }

    function fill(OrderType orderType, uint64 maxAmount, uint256 maxPrice, uint8 maxPricePoints) external
        returns (uint64 amountFilled, uint256 totalPrice)
    {
        uint256 price;

        if (orderType == OrderType.SELL) {
            price = _askPrice;
            if (price == 0 || price > maxPrice) {
                return (0, 0);
            }
        } else {
            price = _bidPrice;
            if (price == 0 || price < maxPrice) {
                return (0, 0);
            }
        }

        if (maxAmount == 0) {
            revert InvalidAmount();
        }

        if (maxPricePoints == 0) {
            revert InvalidArgument();
        }

        uint64 amountLeft = maxAmount;

        uint8 pricePointsFilled = 0;

        while (pricePointsFilled < maxPricePoints) {
            PricePoint memory pricePoint_ = _pricePoints[orderType][price];

            uint64 amount = pricePoint_.totalPlaced - pricePoint_.totalFilled;

            if (amount > amountLeft) {
                amount = amountLeft;
            }

            amountLeft -= amount;
            amountFilled += amount;
            totalPrice += amount * price;

            pricePoint_.totalFilled += amount;

            _pricePoints[orderType][price] = pricePoint_;

            emit Filled(orderType, price, amount);

            if (pricePoint_.totalPlaced == pricePoint_.totalFilled) {
                removePrice(orderType, price);
                if (amountLeft > 0) {
                    if (orderType == OrderType.SELL) {
                        price = _askPrice;
                        if (price == 0 || maxPrice < price) {
                            break;
                        }
                    } else {
                        price = _bidPrice;
                        if (price == 0 || maxPrice > price) {
                            break;
                        }
                    }
                } else {
                    break;
                }
            } else {
                break;
            }

            pricePointsFilled++;
        }

        if (orderType == OrderType.SELL) {
            _baseToken.safeTransferFrom(msg.sender, address(this), totalPrice);
            _tradedToken.safeTransfer(msg.sender, amountFilled * _contractSize);
        } else {
            _tradedToken.safeTransferFrom(msg.sender, address(this), amountFilled * _contractSize);
            _baseToken.safeTransfer(msg.sender, totalPrice);
        }
    }

    function claimOrder(OrderType orderType, uint256 price, uint32 orderId, uint32 maxAmount) external
        returns (uint32 amountClaimed)
    {
        if (maxAmount == 0) {
            revert InvalidAmount();
        }

        if (price == 0 || price % _priceTick != 0) {
            revert InvalidPrice();
        }

        PricePoint memory pricePoint_ = _pricePoints[orderType][price];

        if (orderId == 0 || orderId > pricePoint_.lastOrderId) {
            revert InvalidOrderId();
        }

        Order memory order_ = _orders[orderType][price][orderId];

        if (order_.owner == 0) {
            revert OrderDeleted();
        }

        if (_addressBook.addr(order_.owner) != msg.sender) {
            revert Unauthorized();
        }

        if (pricePoint_.totalFilled < order_.totalPlacedBeforeOrder) {
            return 0;
        }

        uint64 amountFilled = pricePoint_.totalFilled - order_.totalPlacedBeforeOrder;

        if (amountFilled > order_.amount) {
            amountClaimed = order_.amount;
        } else {
            amountClaimed = uint32(amountFilled);
        }

        amountClaimed -= order_.claimed;

        if (amountClaimed > maxAmount) {
            amountClaimed = maxAmount;
        }

        if (amountClaimed > 0) {
            order_.claimed += amountClaimed;

            if (order_.claimed == order_.amount) {
                deleteOrder(orderType, price, orderId, pricePoint_, order_, true);
            } else {
                _orders[orderType][price][orderId] = order_;
            }

            if (orderType == OrderType.SELL) {
                _baseToken.safeTransfer(msg.sender, amountClaimed * price);
            } else {
                _tradedToken.safeTransfer(msg.sender, amountClaimed * _contractSize);
            }
        }
    }

    function cancelOrder(OrderType orderType, uint256 price, uint32 orderId, uint32 maxLastOrderId) external
        returns (uint32 amountCanceled)
    {
        PricePoint memory pricePoint_ = _pricePoints[orderType][price];

        if (pricePoint_.lastOrderId > maxLastOrderId) {
            revert OverMaxLastOrderId();
        }

        if (price == 0 || price % _priceTick != 0) {
            revert InvalidPrice();
        }

        if (orderId == 0 || orderId > pricePoint_.lastOrderId) {
            revert InvalidOrderId();
        }

        Order memory order_ = _orders[orderType][price][orderId];

        if (order_.owner == 0) {
            revert OrderDeleted();
        }

        if (_addressBook.addr(order_.owner) != msg.sender) {
            revert Unauthorized();
        }

        amountCanceled = order_.amount;

        if (pricePoint_.totalFilled > order_.totalPlacedBeforeOrder) {
            uint64 filledAmount = pricePoint_.totalFilled - order_.totalPlacedBeforeOrder;

            if (filledAmount >= order_.amount) {
                revert AlreadyFilled();
            }

            order_.amount = uint32(filledAmount);
            amountCanceled -= uint32(filledAmount);

            if (order_.amount == order_.claimed) {
                deleteOrder(orderType, price, orderId, pricePoint_, order_, false);
            } else {
                _orders[orderType][price][orderId] = order_;
            }
        } else {
            deleteOrder(orderType, price, orderId, pricePoint_, order_, false);
        }

        uint32 orderIdCursor = pricePoint_.lastActualOrderId;
        while (orderIdCursor > orderId) {
            Order memory orderCursor = _orders[orderType][price][orderIdCursor];
            if (orderCursor.owner == 0) continue;
            orderCursor.totalPlacedBeforeOrder -= amountCanceled;
            _orders[orderType][price][orderIdCursor] = orderCursor;
            orderIdCursor = orderCursor.prevOrderId;
        }

        pricePoint_.totalPlaced -= amountCanceled;

        _pricePoints[orderType][price] = pricePoint_;

        if (pricePoint_.totalPlaced == pricePoint_.totalFilled) {
            removePrice(orderType, price);
        }

        if (orderType == OrderType.SELL) {
            _tradedToken.safeTransfer(msg.sender, amountCanceled * _contractSize);
        } else {
            _baseToken.safeTransfer(msg.sender, amountCanceled * price);
        }

        emit Canceled(orderType, price, amountCanceled);
    }

    function transferOrder(OrderType orderType, uint256 price, uint32 orderId, address newOwner) external {
        if (price == 0 || price % _priceTick != 0) {
            revert InvalidPrice();
        }

        if (orderId == 0 || orderId > _pricePoints[orderType][price].lastOrderId) {
            revert InvalidOrderId();
        }

        Order memory order_ = _orders[orderType][price][orderId];

        if (order_.owner == 0) {
            revert OrderDeleted();
        }

        IAddressBook addressBook_ = _addressBook;

        if (addressBook_.addr(order_.owner) != msg.sender) {
            revert Unauthorized();
        }

        order_.owner = addressBook_.safeId(newOwner);

        _orders[orderType][price][orderId] = order_;
    }

    function deleteOrder(
        OrderType orderType, uint256 price, uint32 orderId,
        PricePoint memory pricePoint_, Order memory order_,
        bool updatePricePoint
    ) internal {
        if (pricePoint_.lastActualOrderId == orderId) {
            pricePoint_.lastActualOrderId = order_.prevOrderId;
            if (updatePricePoint) {
                _pricePoints[orderType][price] = pricePoint_;
            }
        }
        if (order_.prevOrderId != 0) {
            _orders[orderType][price][order_.prevOrderId].nextOrderId = order_.nextOrderId;
        }
        if (order_.nextOrderId != 0) {
            _orders[orderType][price][order_.nextOrderId].prevOrderId = order_.prevOrderId;
        }
        delete _orders[orderType][price][orderId];
    }

    function addPrice(OrderType orderType, uint256 price) internal {
        if (orderType == OrderType.SELL) {
            addSellPrice(price);
        } else {
            addBuyPrice(price);
        }
    }

    function removePrice(OrderType orderType, uint256 price) internal {
        if (orderType == OrderType.SELL) {
            removeSellPrice(price);
        } else {
            removeBuyPrice(price);
        }
    }

    function addSellPrice(uint256 price) internal {
        uint256 askPrice_ = _askPrice;

        if (askPrice_ == 0) {
            _askPrice = price;

        } else {
            if (askPrice_ > price) {
                _nextSellPrice[price] = askPrice_;
                _askPrice = price;

            } else {
                uint256 priceCursor = askPrice_;
                uint256 nextPrice = _nextSellPrice[priceCursor];
                while (nextPrice != 0 && price > nextPrice) {
                    priceCursor = nextPrice;
                    nextPrice = _nextSellPrice[priceCursor];
                }
                _nextSellPrice[priceCursor] = price;
                if (nextPrice != 0) {
                    _nextSellPrice[price] = nextPrice;
                }
            }
        }
    }

    function removeSellPrice(uint256 price) internal {
        uint256 askPrice_ = _askPrice;

        if (askPrice_ == price) {
            _askPrice = _nextSellPrice[price];
            delete _nextSellPrice[price];

        } else {
            uint256 priceCursor = askPrice_;
            uint256 nextPrice = _nextSellPrice[priceCursor];
            while (nextPrice != price) {
                priceCursor = nextPrice;
                nextPrice = _nextSellPrice[priceCursor];
            }
            _nextSellPrice[priceCursor] = _nextSellPrice[price];
            delete _nextSellPrice[price];
        }
    }

    function addBuyPrice(uint256 price) internal {
        uint256 bidPrice_ = _bidPrice;

        if (bidPrice_ == 0) {
            _bidPrice = price;

        } else {
            if (bidPrice_ < price) {
                _nextBuyPrice[price] = bidPrice_;
                _bidPrice = price;

            } else {
                uint256 priceCursor = bidPrice_;
                uint256 nextPrice = _nextBuyPrice[priceCursor];
                while (nextPrice != 0 && price < nextPrice) {
                    priceCursor = nextPrice;
                    nextPrice = _nextBuyPrice[priceCursor];
                }
                _nextBuyPrice[priceCursor] = price;
                if (nextPrice != 0) {
                    _nextBuyPrice[price] = nextPrice;
                }
            }
        }
    }

    function removeBuyPrice(uint256 price) internal {
        uint256 bidPrice_ = _bidPrice;

        if (bidPrice_ == price) {
            _bidPrice = _nextBuyPrice[price];
            delete _nextBuyPrice[price];

        } else {
            uint256 priceCursor = bidPrice_;
            uint256 nextPrice = _nextBuyPrice[priceCursor];
            while (nextPrice != price) {
                priceCursor = nextPrice;
                nextPrice = _nextBuyPrice[priceCursor];
            }
            _nextBuyPrice[priceCursor] = _nextBuyPrice[price];
            delete _nextBuyPrice[price];
        }
    }

    function addressBook() external view returns (IAddressBook) {
        return _addressBook;
    }

    function tradedToken() external view returns (address) {
        return address(_tradedToken);
    }

    function baseToken() external view returns (address) {
        return address(_baseToken);
    }

    function contractSize() external view returns (uint256) {
        return _contractSize;
    }

    function priceTick() external view returns (uint256) {
        return _priceTick;
    }

    function askPrice() external view returns (uint256) {
        return _askPrice;
    }

    function bidPrice() external view returns (uint256) {
        return _bidPrice;
    }

    function nextSellPrice(uint256 price) external view returns (uint256) {
        return _nextSellPrice[price];
    }

    function nextBuyPrice(uint256 price) external view returns (uint256) {
        return _nextBuyPrice[price];
    }

    function pricePoint(OrderType orderType, uint256 price) external view returns (PricePoint memory) {
        return _pricePoints[orderType][price];
    }

    function order(OrderType orderType, uint256 price, uint32 orderId) external view returns (Order memory) {
        return _orders[orderType][price][orderId];
    }

    function version() external pure returns (uint32) {
        return 10000;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAddressBook } from "../interfaces/IAddressBook.sol";

library AddressBookUtil {
    /**
     * Error thrown when an address has not been registered.
     */
    error NotRegistered();

    /**
     * Error thrown when an id is not valid.
     */
    error InvalidId();

    /**
     * Get the id matching an address, reverts if not registered.
     *
     * @param  addressBook the address book
     * @param  addr        the address
     * @return             the id
     */
    function safeId(IAddressBook addressBook, address addr) internal view returns (uint40) {
        uint40 id = addressBook.id(addr);
        if (id == 0) {
            revert NotRegistered();
        }
        return id;
    }

    /**
     * Get the address matching an id, reverts if not a valid id.
     *
     * @param  addressBook the address book
     * @param  id          the id
     * @return             the address
     */
    function safeAddr(IAddressBook addressBook, uint40 id) internal view returns (address) {
        if (id == 0 || id > addressBook.lastId()) {
            revert InvalidId();
        }
        return addressBook.addr(id);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * Orderbook factory.
 */
interface IOrderbookFactory {
    /**
     * Event emitted when an orderbook is created.
     *
     * @param orderbook    the orderbook created
     * @param tradedToken  the token being traded
     * @param baseToken    the token given in exchange and used for pricing
     * @param contractSize the size of a contract in tradedToken
     * @param priceTick    the price tick in baseToken
     */
    event OrderbookCreated(
        uint32          version,
        address indexed orderbook,
        address indexed tradedToken,
        address indexed baseToken,
        uint256         contractSize,
        uint256         priceTick
    );
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

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
     * @return version the orderbook version
     */
    function version() external view returns (uint32 version);

    /**
     * The token being traded.
     *
     * @return tradedToken the token being traded
     */
    function tradedToken() external view returns (address tradedToken);

    /**
     * The token given in exchange and used for pricing.
     *
     * @return baseToken the token given in exchange and used for pricing
     */
    function baseToken() external view returns (address baseToken);

    /**
     * The size of a contract in tradedToken.
     *
     * @return contractSize the size of a contract in tradedToken
     */
    function contractSize() external view returns (uint256 contractSize);

    /**
     * The price tick in baseToken.
     *
     * All prices are multiples of this value.
     *
     * @return priceTick the price tick in baseToken
     */
    function priceTick() external view returns (uint256 priceTick);

    /**
     * The ask price in baseToken.
     *
     * @return askPrice the ask price in baseToken
     */
    function askPrice() external view returns (uint256 askPrice);

    /**
     * The bid price in baseToken.
     *
     * @return bidPrice the bid price in baseToken
     */
    function bidPrice() external view returns (uint256 bidPrice);

    /**
     * The next available sell price point.
     *
     * @param  price         an available sell price point
     * @return nextSellPrice the next available sell price point
     */
    function nextSellPrice(uint256 price) external view returns (uint256 nextSellPrice);

    /**
     * The next available buy price point.
     *
     * @param  price        an available buy price point
     * @return nextBuyPrice the next available buy price point
     */
    function nextBuyPrice(uint256 price) external view returns (uint256 nextBuyPrice);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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