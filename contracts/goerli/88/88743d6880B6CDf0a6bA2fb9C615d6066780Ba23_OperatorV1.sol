// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import { OperatorV0 }
    from "@theorderbookdex/orderbook-dex-operator/contracts/OperatorV0.sol";
import { OperatorMarketTradeV1 }
    from "./OperatorMarketTradeV1.sol";
import { OperatorLimitOrderV1 }
    from "./OperatorLimitOrderV1.sol";
import { OperatorOrderHandlingV1 }
    from "./OperatorOrderHandlingV1.sol";
import { OperatorPricePointsV1 }
    from "./OperatorPricePointsV1.sol";
import { IOperatorV1 }
    from "./interfaces/IOperatorV1.sol";

/**
 * Operator V1 functionality.
 */
contract OperatorV1 is OperatorV0, OperatorMarketTradeV1, OperatorLimitOrderV1, OperatorOrderHandlingV1,
    OperatorPricePointsV1, IOperatorV1
{
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import { OperatorBase } from "./OperatorBase.sol";
import { OperatorERC20 } from "./OperatorERC20.sol";
import { IOperatorV0 } from "./interfaces/IOperatorV0.sol";

contract OperatorV0 is OperatorBase, OperatorERC20, IOperatorV0 {
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import { IOperatorMarketTradeV1, BuyAtMarketResultV1, SellAtMarketResultV1 }
    from "./interfaces/IOperatorMarketTradeV1.sol";
import { OperatorBase }
    from "@theorderbookdex/orderbook-dex-operator/contracts/OperatorBase.sol";
import { IOrderbookV1, OrderType }
    from "@theorderbookdex/orderbook-dex-v1/contracts/interfaces/IOrderbookV1.sol";
import { IERC20 }
    from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * Operator trade at market functionality for V1 orderbooks.
 */
contract OperatorMarketTradeV1 is OperatorBase, IOperatorMarketTradeV1 {
    function buyAtMarketV1(IOrderbookV1 orderbook, uint256 maxAmount, uint256 maxPrice, uint8 maxPricePoints)
        external onlyOwner returns (BuyAtMarketResultV1 memory result)
    {
        if (maxAmount > type(uint64).max) {
            maxAmount = type(uint64).max;
        }

        IERC20 baseToken = IERC20(orderbook.baseToken());
        if (maxPrice == type(uint256).max) {
            baseToken.approve(address(orderbook), maxPrice);
        } else {
            baseToken.approve(address(orderbook), maxAmount * maxPrice);
        }

        try IOrderbookV1(orderbook).fill(OrderType.SELL, uint64(maxAmount), maxPrice, maxPricePoints)
            returns (uint64 amountBought, uint256 amountPaid, uint256 fee)
        {
            result.amountBought = amountBought;
            result.amountPaid = amountPaid;
            result.fee = fee;

            if (amountBought > 0) {
                emit BoughtAtMarketV1(amountBought, amountPaid, fee);
            }

        } catch (bytes memory error) {
            result.failed = true;
            result.error = error;
            emit Failed(error);
        }

        if (baseToken.allowance(address(this), address(orderbook)) != 0) {
            baseToken.approve(address(orderbook), 0);
        }
    }

    function sellAtMarketV1(IOrderbookV1 orderbook, uint256 maxAmount, uint256 minPrice, uint8 maxPricePoints)
        external onlyOwner returns (SellAtMarketResultV1 memory result)
    {
        if (maxAmount > type(uint64).max) {
            maxAmount = type(uint64).max;
        }

        IERC20 tradedToken = IERC20(orderbook.tradedToken());
        tradedToken.approve(address(orderbook), maxAmount * orderbook.contractSize());

        try orderbook.fill(OrderType.BUY, uint64(maxAmount), minPrice, maxPricePoints)
            returns (uint64 amountSold, uint256 amountReceived, uint256 fee)
        {
            result.amountSold = amountSold;
            result.amountReceived = amountReceived;
            result.fee = fee;

            if (amountSold > 0) {
                emit SoldAtMarketV1(amountSold, amountReceived, fee);
            }

        } catch (bytes memory error) {
            result.failed = true;
            result.error = error;
            emit Failed(error);
        }

        if (tradedToken.allowance(address(this), address(orderbook)) != 0) {
            tradedToken.approve(address(orderbook), 0);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import { IOperatorLimitOrderV1, PlaceBuyOrderResultV1, PlaceSellOrderResultV1 }
    from "./interfaces/IOperatorLimitOrderV1.sol";
import { OperatorBase }
    from "@theorderbookdex/orderbook-dex-operator/contracts/OperatorBase.sol";
import { IOrderbook }
    from "@theorderbookdex/orderbook-dex/contracts/interfaces/IOrderbook.sol";
import { IOrderbookV1, OrderType }
    from "@theorderbookdex/orderbook-dex-v1/contracts/interfaces/IOrderbookV1.sol";
import { IERC20 }
    from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * Operator place limit order functionality for V1 orderbooks.
 */
contract OperatorLimitOrderV1 is OperatorBase, IOperatorLimitOrderV1 {
    function placeBuyOrderV1(IOrderbookV1 orderbook, uint256 maxAmount, uint256 price, uint8 maxPricePoints)
        external onlyOwner returns (PlaceBuyOrderResultV1 memory result)
    {
        if (maxAmount > type(uint32).max) {
            maxAmount = type(uint32).max;
        }

        IERC20 baseToken = IERC20(orderbook.baseToken());
        baseToken.approve(address(orderbook), maxAmount * price);

        uint256 askPrice = orderbook.askPrice();

        if (askPrice == 0 || price < askPrice) {
            try orderbook.placeOrder(OrderType.BUY, price, uint32(maxAmount))
                returns (uint32 orderId)
            {
                result.amountPlaced = maxAmount;
                result.orderId = orderId;
                emit PlacedBuyOrderV1(maxAmount, orderId);

            } catch (bytes memory error) {
                result.failed = true;
                result.error = error;
                emit Failed(error);
            }

        } else {
            try orderbook.fill(OrderType.SELL, uint64(maxAmount), price, maxPricePoints)
                returns (uint64 amountBought, uint256 amountPaid, uint256 fee)
            {
                result.amountBought = amountBought;
                result.amountPaid = amountPaid;
                result.fee = fee;

                if (amountBought > 0) {
                    emit BoughtAtMarketV1(amountBought, amountPaid, fee);
                    maxAmount -= amountBought;
                }

                if (maxAmount != 0) {
                    askPrice = orderbook.askPrice();

                    if (askPrice == 0 || price < askPrice) {
                        try orderbook.placeOrder(OrderType.BUY, price, uint32(maxAmount))
                            returns (uint32 orderId)
                        {
                            result.amountPlaced = maxAmount;
                            result.orderId = orderId;
                            emit PlacedBuyOrderV1(maxAmount, orderId);

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

        if (baseToken.allowance(address(this), address(orderbook)) != 0) {
            baseToken.approve(address(orderbook), 0);
        }
    }

    function placeSellOrderV1(IOrderbookV1 orderbook, uint256 maxAmount, uint256 price, uint8 maxPricePoints)
        external onlyOwner returns (PlaceSellOrderResultV1 memory result)
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

        IERC20 tradedToken = IERC20(orderbook.tradedToken());
        tradedToken.approve(address(orderbook), maxAmount * orderbook.contractSize());

        uint256 bidPrice = orderbook.bidPrice();

        if (price > bidPrice) {
            try orderbook.placeOrder(OrderType.SELL, price, uint32(maxAmount))
                returns (uint32 orderId)
            {
                result.amountPlaced = maxAmount;
                result.orderId = orderId;
                emit PlacedSellOrderV1(maxAmount, orderId);

            } catch (bytes memory error) {
                result.failed = true;
                result.error = error;
                emit Failed(error);
            }

        } else {
            try orderbook.fill(OrderType.BUY, uint64(maxAmount), price, maxPricePoints)
                returns (uint64 amountSold, uint256 amountReceived, uint256 fee)
            {
                result.amountSold = amountSold;
                result.amountReceived = amountReceived;
                result.fee = fee;

                if (amountSold > 0) {
                    emit SoldAtMarketV1(amountSold, amountReceived, fee);
                    maxAmount -= amountSold;
                }

                if (maxAmount != 0) {
                    bidPrice = IOrderbookV1(orderbook).bidPrice();

                    if (price > bidPrice) {
                        try IOrderbookV1(orderbook).placeOrder(OrderType.SELL, price, uint32(maxAmount))
                            returns (uint32 orderId)
                        {
                            result.amountPlaced = maxAmount;
                            result.orderId = orderId;
                            emit PlacedSellOrderV1(maxAmount, orderId);

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

        if (tradedToken.allowance(address(this), address(orderbook)) != 0) {
            tradedToken.approve(address(orderbook), 0);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import { IOperatorOrderHandlingV1, ClaimOrderResultV1, TransferOrderResultV1, CancelOrderResultV1 }
    from "./interfaces/IOperatorOrderHandlingV1.sol";
import { OperatorBase }
    from "@theorderbookdex/orderbook-dex-operator/contracts/OperatorBase.sol";
import { IOrderbookV1, OrderType }
    from "@theorderbookdex/orderbook-dex-v1/contracts/interfaces/IOrderbookV1.sol";

/**
 * Operator order handling functionality for V1 orderbooks.
 */
contract OperatorOrderHandlingV1 is OperatorBase, IOperatorOrderHandlingV1 {
    function claimOrderV1(
        IOrderbookV1 orderbook, OrderType orderType, uint256 price, uint32 orderId, uint32 maxAmount
    ) external onlyOwner returns (ClaimOrderResultV1 memory result) {
        try orderbook.claimOrder(orderType, price, orderId, maxAmount)
            returns (uint32 amountClaimed, uint256 fee)
        {
            result.amountClaimed = amountClaimed;
            result.fee = fee;
            emit OrderClaimedV1(amountClaimed, fee);

        } catch (bytes memory error) {
            result.failed = true;
            result.error = error;
            emit Failed(error);
        }
    }

    function transferOrderV1(
        IOrderbookV1 orderbook, OrderType orderType, uint256 price, uint32 orderId, address recipient
    ) external onlyOwner returns (TransferOrderResultV1 memory result) {
        try orderbook.transferOrder(orderType, price, orderId, recipient) {
            emit OrderTransferedV1();
        } catch (bytes memory error) {
            result.failed = true;
            result.error = error;
            emit Failed(error);
        }
    }

    function cancelOrderV1(
        IOrderbookV1 orderbook, OrderType orderType, uint256 price, uint32 orderId, uint32 maxLastOrderId
    ) external onlyOwner returns (CancelOrderResultV1 memory result) {
        try orderbook.cancelOrder(orderType, price, orderId, maxLastOrderId)
            returns (uint32 amountCanceled)
        {
            result.amountCanceled = amountCanceled;
            emit OrderCanceledV1(amountCanceled);

        } catch (bytes memory error) {
            result.failed = true;
            result.error = error;
            emit Failed(error);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import { IOperatorPricePointsV1, PricePointsResultV1, PricePointV1 }
    from "./interfaces/IOperatorPricePointsV1.sol";
import { OperatorBase }
    from "@theorderbookdex/orderbook-dex-operator/contracts/OperatorBase.sol";
import { IOrderbook }
    from "@theorderbookdex/orderbook-dex/contracts/interfaces/IOrderbook.sol";
import { IOrderbookV1, OrderType, PricePoint }
    from "@theorderbookdex/orderbook-dex-v1/contracts/interfaces/IOrderbookV1.sol";

/**
 * Operator price points observe functionality for V1 orderbooks.
 */
contract OperatorPricePointsV1 is OperatorBase, IOperatorPricePointsV1 {
    function pricePointsV1(
        IOrderbookV1 orderbook, uint256 prevSellPrice, uint8 sellPricesLimit, uint256 prevBuyPrice, uint8 buyPricesLimit
    ) external view returns (PricePointsResultV1 memory result) {
        result.sell = _sellPricePointsV1(orderbook, prevSellPrice, sellPricesLimit);
        result.buy = _buyPricePointsV1(orderbook, prevBuyPrice, buyPricesLimit);
    }

    function _sellPricePointsV1(IOrderbookV1 orderbook, uint256 prevPrice, uint8 limit)
        private view returns (PricePointV1[] memory)
    {
        PricePointV1[] memory pricePoints = new PricePointV1[](limit);

        if (limit == 0) {
            return pricePoints;
        }

        uint256 price;
        if (prevPrice == 0) {
            price = orderbook.askPrice();
        } else {
            price = orderbook.nextSellPrice(prevPrice);
        }

        uint8 index = 0;
        for (; index < limit; index++) {
            if (price == 0) break;
            pricePoints[index].price = price;
            PricePoint memory pricePoint = orderbook.pricePoint(OrderType.SELL, price);
            pricePoints[index].available = pricePoint.totalPlaced - pricePoint.totalFilled;
            price = orderbook.nextSellPrice(price);
        }

        if (index == limit) {
            return pricePoints;
        } else {
            return _slice(pricePoints, index);
        }
    }

    function _buyPricePointsV1(IOrderbookV1 orderbook, uint256 prevPrice, uint8 limit)
        private view returns (PricePointV1[] memory)
    {
        PricePointV1[] memory pricePoints = new PricePointV1[](limit);

        if (limit == 0) {
            return pricePoints;
        }

        uint256 price;
        if (prevPrice == 0) {
            price = orderbook.bidPrice();
        } else {
            price = orderbook.nextBuyPrice(prevPrice);
        }

        uint8 index = 0;
        for (; index < limit; index++) {
            if (price == 0) break;
            pricePoints[index].price = price;
            PricePoint memory pricePoint = orderbook.pricePoint(OrderType.BUY, price);
            pricePoints[index].available = pricePoint.totalPlaced - pricePoint.totalFilled;
            price = orderbook.nextBuyPrice(price);
        }

        if (index == limit) {
            return pricePoints;
        } else {
            return _slice(pricePoints, index);
        }
    }

    function _slice(PricePointV1[] memory pricePoints, uint8 limit) private pure returns (PricePointV1[] memory) {
        PricePointV1[] memory slice = new PricePointV1[](limit);
        for (uint8 i = 0; i < limit; i++) {
            slice[i] = pricePoints[i];
        }
        return slice;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import { IOperatorV0 }
    from "@theorderbookdex/orderbook-dex-operator/contracts/interfaces/IOperatorV0.sol";
import { IOperatorMarketTradeV1 }
    from "./IOperatorMarketTradeV1.sol";
import { IOperatorLimitOrderV1 }
    from "./IOperatorLimitOrderV1.sol";
import { IOperatorOrderHandlingV1 }
    from "./IOperatorOrderHandlingV1.sol";
import { IOperatorPricePointsV1 }
    from "./IOperatorPricePointsV1.sol";

interface IOperatorV1 is IOperatorV0, IOperatorMarketTradeV1, IOperatorLimitOrderV1, IOperatorOrderHandlingV1,
    IOperatorPricePointsV1
{
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import { IOperatorBase } from "./interfaces/IOperatorBase.sol";
import { OperatorOwner } from "./OperatorOwner.sol";
import { StorageSlot } from "@openzeppelin/contracts/utils/StorageSlot.sol";

/**
 * Operator implementation base contract.
 *
 * Operator implementations MUST have this contract as the first inherited.
 *
 * Operator implementations SHOULD NOT have a constructor.
 *
 * Operator implementations SHOULD NOT have state variables nor change the
 * contract state in any way.
 */
contract OperatorBase is IOperatorBase {
    /**
     * Modifier for functions that can only be called by the owner.
     *
     * All state modifying functions should be marked as onlyOwner.
     */
    modifier onlyOwner() {
        if (msg.sender != owner()) {
            revert Unauthorized();
        }
        _;
    }

    function owner() public view returns (address) {
        return OperatorOwner.getOwner();
    }

    function implementation() public view returns (address) {
        // Storage slot for the implementation as defined by EIP-1967
        return StorageSlot.getAddressSlot(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc).value;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import { OperatorBase } from "./OperatorBase.sol";
import { IOperatorBase } from "./interfaces/IOperatorBase.sol";
import { IOperatorERC20, ERC20AndAmount } from "./interfaces/IOperatorERC20.sol";
import { IAddressBook } from "@frugal-wizard/addressbook/contracts/interfaces/IAddressBook.sol";
import { IOrderbook } from "@theorderbookdex/orderbook-dex/contracts/interfaces/IOrderbook.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Proxy } from "@openzeppelin/contracts/proxy/Proxy.sol";
import { ERC1967Upgrade } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

/**
 * Operator ERC20 functionality.
 */
contract OperatorERC20 is OperatorBase, IOperatorERC20 {
    function withdrawERC20(ERC20AndAmount[] calldata tokensAndAmounts) external onlyOwner {
        for (uint256 i = 0; i < tokensAndAmounts.length; i++) {
            tokensAndAmounts[i].token.transfer(msg.sender, tokensAndAmounts[i].amount);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import { IOperatorBase } from "./IOperatorBase.sol";
import { IOperatorERC20 } from "./IOperatorERC20.sol";

interface IOperatorV0 is IOperatorBase, IOperatorERC20 {
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import { IOperatorBase }
    from "@theorderbookdex/orderbook-dex-operator/contracts/interfaces/IOperatorBase.sol";
import { IOrderbookV1 }
    from "@theorderbookdex/orderbook-dex-v1/contracts/interfaces/IOrderbookV1.sol";
import { IOperatorMarketTradeV1Events }
    from "./IOperatorMarketTradeV1Events.sol";

/**
 * Operator place limit order functionality for V1 orderbooks.
 */
interface IOperatorLimitOrderV1 is IOperatorBase, IOperatorMarketTradeV1Events {
    /**
     * Event emitted to provide feedback after a placeBuyOrder call.
     *
     * @param amount  the amount of contracts of the placed order
     * @param orderId the order id
     */
    event PlacedBuyOrderV1(uint256 amount, uint32 orderId);

    /**
     * Event emitted to provide feedback after a placeSellOrder call.
     *
     * @param amount  the amount of contracts of the placed order
     * @param orderId the order id
     */
    event PlacedSellOrderV1(uint256 amount, uint32 orderId);

    /**
     * Place buy order.
     *
     * If the bid price is at or above the provided price, it will attempt to buy at market first, and place an
     * order for the remainder.
     *
     * Emits a BoughtAtMarket event if it manages to buy any amount.
     *
     * Emits a PlacedBuyOrder event if it manages to place an order.
     *
     * Emits a Failed event if there is an error when calling the orderbook contract.
     *
     * @param orderbook      the orderbook
     * @param maxAmount      the maximum amount of contracts to buy
     * @param price          the price to pay for contract
     * @param maxPricePoints the maximum amount of price points to fill
     */
    function placeBuyOrderV1(IOrderbookV1 orderbook, uint256 maxAmount, uint256 price, uint8 maxPricePoints)
        external returns (PlaceBuyOrderResultV1 memory result);

    /**
     * Place sell order.
     *
     * If the ask price is at or below the provided price, it will attempt to sell at market first, and place an
     * order for the remainder.
     *
     * Emits a SoldAtMarket event if it manages to sell any amount.
     *
     * Emits a PlacedSellOrder event if it manages to place an order.
     *
     * Emits a Failed event if there is an error when calling the orderbook contract.
     *
     * @param orderbook      the orderbook
     * @param maxAmount      the maximum amount of contracts to sell
     * @param price          the price to pay for contract
     * @param maxPricePoints the maximum amount of price points to fill
     */
    function placeSellOrderV1(IOrderbookV1 orderbook, uint256 maxAmount, uint256 price, uint8 maxPricePoints)
        external returns (PlaceSellOrderResultV1 memory result);
}

/**
 * Return value of placeBuyOrder call.
 */
struct PlaceBuyOrderResultV1 {
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
     * The amount of traded token taken as fee.
     *
     * This might be non zero even if the operation fails, which means it managed to buy some
     * before failing.
     */
    uint256 fee;

    /**
     * The amount of contracts of the placed order.
     */
    uint256 amountPlaced;

    /**
     * The order id.
     */
    uint32 orderId;

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
struct PlaceSellOrderResultV1 {
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
     * The amount of base token taken as fee.
     *
     * This might be non zero even if the operation fails, which means it managed to buy some
     * before failing.
     */
    uint256 fee;

    /**
     * The amount of contracts of the placed order.
     */
    uint256 amountPlaced;

    /**
     * The order id.
     */
    uint32 orderId;

    /**
     * True if the operation failed.
     */
    bool failed;

    /**
     * The raw error data.
     */
    bytes error;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import { IOrderbookDEXTeamTreasury } from "./IOrderbookDEXTeamTreasury.sol";

/**
 * Orderbook exchange for a token pair.
 */
interface IOrderbook {
    /**
     * Claim collected fees.
     *
     * This can only be called by the Orderbook DEX Team Treasury contract.
     */
    function claimFees() external;

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

    /**
     * The Orderbook DEX Treasury.
     *
     * @return treasury the Orderbook DEX Treasury
     */
    function treasury() external view returns (IOrderbookDEXTeamTreasury treasury);

    /**
     * The total collected fees that have not yet been claimed.
     *
     * @return collectedTradedToken the amount in traded token
     * @return collectedBaseToken   the amount in base token
     */
    function collectedFees() external view returns (uint256 collectedTradedToken, uint256 collectedBaseToken);
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
     * Fee is taken from tokens sent back to filler.
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
     * @return fee            the fee collected
     */
    function fill(OrderType orderType, uint64 maxAmount, uint256 maxPrice, uint8 maxPricePoints) external
        returns (uint64 amountFilled, uint256 totalPrice, uint256 fee);

    /**
     * Claim an order.
     *
     * Fee is taken from tokens claimed.
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
     * @return fee           the fee collected
     */
    function claimOrder(OrderType orderType, uint256 price, uint32 orderId, uint32 maxAmount) external
        returns (uint32 amountClaimed, uint256 fee);

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

import { IOperatorBase }
    from "@theorderbookdex/orderbook-dex-operator/contracts/interfaces/IOperatorBase.sol";
import { IOrderbookV1 }
    from "@theorderbookdex/orderbook-dex-v1/contracts/interfaces/IOrderbookV1.sol";
import { IOperatorMarketTradeV1Events }
    from "./IOperatorMarketTradeV1Events.sol";

/**
 * Operator trade at market functionality for V1 orderbooks.
 */
interface IOperatorMarketTradeV1 is IOperatorBase, IOperatorMarketTradeV1Events {
    /**
     * Buy at market.
     *
     * Emits a BoughtAtMarket event if it manages to buy any amount.
     *
     * Emits a Failed event if there is an error when calling the orderbook contract.
     *
     * @param orderbook      the orderbook
     * @param maxAmount      the maximum amount of contracts to buy
     * @param maxPrice       the maximum price to pay for contract
     * @param maxPricePoints the maximum amount of price points to fill
     */
    function buyAtMarketV1(IOrderbookV1 orderbook, uint256 maxAmount, uint256 maxPrice, uint8 maxPricePoints)
        external returns (BuyAtMarketResultV1 memory result);

    /**
     * Sell at market.
     *
     * Emits a SoldAtMarket event if it manages to sell any amount.
     *
     * Emits a Failed event if there is an error when calling the orderbook contract.
     *
     * @param orderbook      the orderbook
     * @param maxAmount      the maximum amount of contracts to sell
     * @param minPrice       the minimum price to pay for contract
     * @param maxPricePoints the maximum amount of price points to fill
     */
    function sellAtMarketV1(IOrderbookV1 orderbook, uint256 maxAmount, uint256 minPrice, uint8 maxPricePoints)
        external returns (SellAtMarketResultV1 memory result);
}

/**
 * Return value of buyAtMarket call.
 */
struct BuyAtMarketResultV1 {
    /**
     * The amount of contracts bought.
     */
    uint256 amountBought;

    /**
     * The amount of base token paid.
     */
    uint256 amountPaid;

    /**
     * The amount of traded token taken as fee.
     */
    uint256 fee;

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
struct SellAtMarketResultV1 {
    /**
     * The amount of contracts sold.
     */
    uint256 amountSold;

    /**
     * The amount of base token received.
     */
    uint256 amountReceived;

    /**
     * The amount of base token taken as fee.
     */
    uint256 fee;

    /**
     * True if the operation failed.
     */
    bool failed;

    /**
     * The raw error data.
     */
    bytes error;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import { IOperatorBase }
    from "@theorderbookdex/orderbook-dex-operator/contracts/interfaces/IOperatorBase.sol";
import { IOrderbookV1, OrderType }
    from "@theorderbookdex/orderbook-dex-v1/contracts/interfaces/IOrderbookV1.sol";

/**
 * Operator order handling functionality for V1 orderbooks.
 */
interface IOperatorOrderHandlingV1 is IOperatorBase {
    /**
     * Event emitted to provide feedback after a claimOrder call.
     *
     * @param amount the amount of contracts claimed
     * @param fee    the amount of tokens taken as fee
     */
    event OrderClaimedV1(uint256 amount, uint256 fee);

    /**
     * Event emitted to provide feedback after a transferOrder call.
     */
    event OrderTransferedV1();

    /**
     * Event emitted to provide feedback after a cancelOrder call.
     *
     * @param amount the amount of contracts canceled
     */
    event OrderCanceledV1(uint256 amount);

    /**
     * Claim an order.
     *
     * Emits a OrderClaimed event if it manages to claim any amount.
     *
     * Emits a Failed event if there is an error when calling the orderbook contract.
     *
     * @param orderbook the orderbook
     * @param orderType the order type
     * @param price     the price point
     * @param orderId   the order id
     * @param maxAmount the maximum amount of contracts to claim
     */
    function claimOrderV1(
        IOrderbookV1 orderbook, OrderType orderType, uint256 price, uint32 orderId, uint32 maxAmount
    ) external returns (ClaimOrderResultV1 memory result);

    /**
     * Transfer an order.
     *
     * Emits a OrderTransfered event if it manages to transfer the order.
     *
     * Emits a Failed event if there is an error when calling the orderbook contract.
     *
     * @param orderbook the orderbook
     * @param orderType the order type
     * @param price     the price point
     * @param orderId   the order id
     * @param recipient the recipient of the transfer
     */
    function transferOrderV1(
        IOrderbookV1 orderbook, OrderType orderType, uint256 price, uint32 orderId, address recipient
    ) external returns (TransferOrderResultV1 memory result);

    /**
     * Cancel an order.
     *
     * Emits a OrderCanceled event if it manages to cancel the order.
     *
     * Emits a Failed event if there is an error when calling the orderbook contract.
     *
     * @param orderbook      the orderbook
     * @param orderType      the order type
     * @param price          the price point
     * @param orderId        the order id
     * @param maxLastOrderId the maximum last order id can be before stopping this operation
     */
    function cancelOrderV1(
        IOrderbookV1 orderbook, OrderType orderType, uint256 price, uint32 orderId, uint32 maxLastOrderId
    ) external returns (CancelOrderResultV1 memory result);
}

/**
 * Return value of claimOrder call.
 */
struct ClaimOrderResultV1 {
    /**
     * The amount of contracts claimed.
     */
    uint256 amountClaimed;

    /**
     * The amount of tokens taken as fee.
     */
    uint256 fee;

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
struct TransferOrderResultV1 {
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
struct CancelOrderResultV1 {
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import { IOperatorBase }
    from "@theorderbookdex/orderbook-dex-operator/contracts/interfaces/IOperatorBase.sol";
import { IOrderbookV1 }
    from "@theorderbookdex/orderbook-dex-v1/contracts/interfaces/IOrderbookV1.sol";

/**
 * Operator price points observe functionality for V1 orderbooks.
 */
interface IOperatorPricePointsV1 is IOperatorBase {
    /**
     * Get the available price points of an orderbook.
     *
     * This function can be called by anyone, even called using the implementation contract instead of the operator.
     *
     * @param orderbook       the orderbook
     * @param prevSellPrice   the previous sell price point (if 0 starts at ask price)
     * @param sellPricesLimit the max amount of sell price points to return
     * @param prevBuyPrice    the previous buy price point (if 0 starts at bid price)
     * @param buyPricesLimit  the max amount of buy price points to return
     */
    function pricePointsV1(
        IOrderbookV1 orderbook, uint256 prevSellPrice, uint8 sellPricesLimit, uint256 prevBuyPrice, uint8 buyPricesLimit
    ) external view returns (PricePointsResultV1 memory result);
}

/**
 * Return value of pricePoints call.
 */
struct PricePointsResultV1 {
    /**
     * The sell price point.
     */
    PricePointV1[] sell;

    /**
     * The buy price point.
     */
    PricePointV1[] buy;
}

/**
 * Price point data.
 */
struct PricePointV1 {
    /**
     * The price.
     */
    uint256 price;

    /**
     * The amount of contracts available.
     */
    uint256 available;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * Operator implementation base functionality.
 */
interface IOperatorBase {
    /**
     * Event emitted to log an error.
     *
     * @param error the raw error data
     */
    event Failed(bytes error);

    /**
     * Error thrown when a function is called by someone not allowed to.
     */
    error Unauthorized();

    /**
     * Get the operator owner.
     *
     * @return owner the operator owner
     */
    function owner() external view returns (address owner);

    /**
     * Get the implementation.
     *
     * @return implementation the operator implementation
     */
    function implementation() external view returns (address implementation);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import { StorageSlot } from "@openzeppelin/contracts/utils/StorageSlot.sol";

/**
 * Library for getting and setting the operator owner.
 */
library OperatorOwner {
    /**
     * Slot where the owner is stored.
     *
     * The XOR operation changes one bit to get a value whose preimage is, hopefully, not known.
     */
    bytes32 private constant OWNER_SLOT = keccak256("owner") ^ bytes32(uint(1));

    /**
     * Get the operator owner.
     *
     * @return owner the operator owner
     */
    function getOwner() internal view returns (address owner) {
        return StorageSlot.getAddressSlot(OWNER_SLOT).value;
    }

    /**
     * Set the operator owner.
     *
     * @param owner the operator owner
     */
    function setOwner(address owner) internal {
        StorageSlot.getAddressSlot(OWNER_SLOT).value = owner;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import { IOperatorBase } from "./IOperatorBase.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * Operator ERC20 functionality.
 */
interface IOperatorERC20 is IOperatorBase {
    /**
     * Withdraw ERC20 tokens from the operator.
     *
     * @param tokensAndAmounts the tokens and amounts to withdraw
     */
    function withdrawERC20(ERC20AndAmount[] calldata tokensAndAmounts) external;
}

/**
 * A ERC20 token and amount tuple.
 */
struct ERC20AndAmount {
    IERC20 token;
    uint256 amount;
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * Orderbook DEX Team Treasury.
 */
interface IOrderbookDEXTeamTreasury {
    /**
     * The current fee applied to orderbooks of a specific version.
     *
     * The fee is returned as a fixed point decimal value with 18 decimal digits in base 10 (same as ETH).
     *
     * This function should not use more than 10,000 gas. Failing to do so will be interpreted as the fee being 0.
     *
     * This function should not revert. Failing to do so will be interpreted as the fee being 0.
     *
     * The should not be higher than 0.005, if it is higher 0.005 will be used.
     *
     * @param  version the orderbook version
     * @return fee     the fee
     */
    function fee(uint32 version) external view returns (uint256 fee);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * Operator trade at market functionality for V1 orderbooks.
 */
interface IOperatorMarketTradeV1Events {
    /**
     * Event emitted to provide feedback after a buyAtMarket call.
     *
     * @param amountBought the amount of contracts bought
     * @param amountPaid   the amount of base token paid
     * @param fee          the amount of traded token taken as fee
     */
    event BoughtAtMarketV1(uint256 amountBought, uint256 amountPaid, uint256 fee);

    /**
     * Event emitted to provide feedback after a sellAtMarket call.
     *
     * @param amountSold     the amount of contracts sold
     * @param amountReceived the amount of base token received
     * @param fee            the amount of base token taken as fee
     */
    event SoldAtMarketV1(uint256 amountSold, uint256 amountReceived, uint256 fee);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
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