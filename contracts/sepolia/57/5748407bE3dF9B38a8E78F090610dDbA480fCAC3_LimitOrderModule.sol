// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IModule, OrderType, Order} from "../../../interfaces/IOrderBook.sol";
import {IFastPriceFeed} from "../../../interfaces/IFastPriceFeed.sol";

contract LimitOrderModule is IModule {
    function execute(IFastPriceFeed priceFeed, Order memory order) external view {
        (uint256 limitPrice, bool triggerAboveThreshold) = abi.decode(order.data, (uint256, bool));
        bool maximized = order.isLong;
        // TODO: check maximized
        uint256 markPrice = priceFeed.getPrice(order.indexToken, maximized);
        require(markPrice > 0, "LimitOrderModule: invalid mark price");

        bool isPriceValid = triggerAboveThreshold
            ? markPrice >= limitPrice
            : markPrice <= limitPrice;
        require(isPriceValid, "LimitOrderModule: not triggered");
    }

    function validate(Order memory order) external pure {
        (uint256 limitPrice, ) = abi.decode(order.data, (uint256, bool));
        require(limitPrice > 0, "LimitOrderModule: limit price invalid");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IFastPriceFeed {
    function getPrice(address token, bool isMax) external view returns (uint256);

    function tokenDecimals(address token) external view returns (uint8);

    function getChainlinkPrice(address token) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IFastPriceFeed} from "./IFastPriceFeed.sol";

enum OrderType {
    MARKET,
    LIMIT
}

struct Order {
    address account;
    address indexToken;
    address collateralToken;
    uint256 sizeDelta;
    /// @notice when increase, collateralAmount is desired amount of collateral used as margin.
    /// When decrease, collateralAmount is value in USD of collateral user want to reduce from
    /// their position
    uint256 collateralAmount;
    uint256 collateralDelta;
    uint256 executionFee;
    /// @notice To prevent front-running, order MUST be executed on next block
    uint256 submissionBlock;
    uint256 submissionTimestamp;
    // long or short
    bool isLong;
    bool isIncrease;
    OrderType orderType;
    // extra data for each order type
    bytes data;
    ExternalCollateralParams externalCollateralParams;
}

struct ExternalCollateralParams {
    address collateralModule;
    address asset;
    uint256 tokenId;
}

/// @notice Order module, will parse orders and call to corresponding handler.
/// After execution complete, module will pass result to position manager to
/// update related position
/// Will be some kind of: StopLimitHandler, LimitHandler, MarketHandler...
interface IModule {
    function execute(IFastPriceFeed priceFeed, Order memory order) external;

    function validate(Order memory order) external view;
}

interface IOrderBook {
    function placeOrder(
        OrderType _orderType,
        address _indexToken,
        address _collateralToken,
        uint256 _side,
        uint256 _sizeChanged,
        bytes calldata _data
    ) external payable;

    function executeOrder(uint256 _orderId, address payable _feeTo) external;

    function executeOrders(uint256[] calldata _orderIds, address payable _feeTo) external;

    function cancelOrder(uint256 _orderId) external;
}