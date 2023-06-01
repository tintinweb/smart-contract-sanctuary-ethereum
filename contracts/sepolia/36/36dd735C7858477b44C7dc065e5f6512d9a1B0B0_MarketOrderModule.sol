// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IModule, OrderType, Order} from "../../../interfaces/IOrderBook.sol";
import {IFastPriceFeed} from "../../../interfaces/IFastPriceFeed.sol";
import {Constants} from "../../../common/Constants.sol";

contract MarketOrderModule is IModule {
    uint256 public maxOrderTimeout;
    uint256 public slippageBps;

    constructor(uint256 _maxOrderTimeout, uint256 _slippageBps) {
        require(_maxOrderTimeout > 0, "MarketOrderModule: invalid order timeout");
        maxOrderTimeout = _maxOrderTimeout;
        slippageBps = _slippageBps;
    }

    /// @dev this function not restricted to view
    function execute(IFastPriceFeed priceFeed, Order memory order) external view {
        uint256 acceptablePrice = abi.decode(order.data, (uint256));
        uint indexPrice = priceFeed.getPrice(order.indexToken, order.isLong);
        require(indexPrice > 0, "LimitOrderModule: invalid mark price");

        require(
            order.submissionTimestamp + maxOrderTimeout >= block.timestamp,
            "MarketOrderModule: order timed out"
        );

        if (slippageBps > 0) {
            _checkSlippage(order.isLong, acceptablePrice, indexPrice);
        }
    }

    function validate(Order memory order) external view {
        uint256 acceptablePrice = abi.decode(order.data, (uint256));
        require(acceptablePrice > 0, "MarketOrderModule: acceptable price invalid");
    }

    function _checkSlippage(
        bool isLong,
        uint256 expectedMarketPrice,
        uint256 actualMarketPrice
    ) internal view {
        if (isLong) {
            require(
                actualMarketPrice <=
                    (expectedMarketPrice * (Constants.BASIS_POINTS_DIVISOR + slippageBps)) /
                        Constants.BASIS_POINTS_DIVISOR,
                "slippage exceeded"
            );
        } else {
            require(
                (expectedMarketPrice * (Constants.BASIS_POINTS_DIVISOR - slippageBps)) /
                    Constants.BASIS_POINTS_DIVISOR <=
                    actualMarketPrice,
                "slippage exceeded"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library Constants {
    address public constant ZERO_ADDRESS = address(0);
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    uint256 public constant DEFAULT_FUNDING_RATE_FACTOR = 100;
    uint256 public constant DEFAULT_MAX_OPEN_INTEREST = 10000000000 * PRICE_PRECISION;
    uint256 public constant DEFAULT_VLP_PRICE = 100000;
    uint256 public constant FUNDING_RATE_PRECISION = 1e6;
    uint256 public constant LIQUIDATE_NONE_EXCEED = 0;
    uint256 public constant LIQUIDATE_FEE_EXCEED = 1;
    uint256 public constant LIQUIDATE_THRESHOLD_EXCEED = 2;
    uint256 public constant LIQUIDATION_FEE_DIVISOR = 1e18;
    uint256 public constant MAX_DEPOSIT_FEE = 10000; // 10%
    uint256 public constant MAX_FUNDING_RATE_FACTOR = 10000; // 1%
    uint256 public constant MAX_LIQUIDATION_FEE_USD = 100 * PRICE_PRECISION; // 100 USD
    uint256 public constant MAX_TRIGGER_GAS_FEE = 1e8 gwei;

    uint256 public constant MAX_FUNDING_RATE_INTERVAL = 48 hours;
    uint256 public constant MIN_FUNDING_RATE_INTERVAL = 1 hours;

    uint256 public constant MIN_LEVERAGE = 10000; // 1x
    uint256 public constant MIN_FEE_REWARD_BASIS_POINTS = 50000; // 50%
    uint256 public constant PRICE_PRECISION = 1e12;
    uint256 public constant LP_DECIMALS = 18;
    uint256 public constant LP_INITIAL_PRICE = 1e12; // init set to 1$
    uint256 public constant USD_VALUE_PRECISION = 1e30;

    uint256 public constant FEE_PRECISION = 10000;

    uint8 public constant ORACLE_PRICE_DECIMALS = 12;
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