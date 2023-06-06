// SPDX-License-Identifier: UNLICENSED
// Uruloki DEX is NOT LICENSED FOR COPYING.
// Uruloki DEX (C) 2022. All Rights Reserved.

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// import "hardhat/console.sol";

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

interface IOrderMgr {
    //// Define enums
    enum OrderType {
        TargetPrice,
        PriceRange
    }
    enum OrderStatus {
        Active,
        Cancelled,
        OutOfFunds,
        Completed
    }

    //// Define structs
    // One time order, it's a base order struct
    struct OrderBase {
        address userAddress;
        address pairedTokenAddress;
        address tokenAddress;
        OrderType orderType;
        uint256 targetPrice;
        bool isBuy;
        uint256 maxPrice;
        uint256 minPrice;
        OrderStatus status;
        uint256 amount;
        bool isContinuous;
    }

    // Continuous Order, it's an extended order struct, including the base order struct
    struct Order {
        OrderBase orderBase;
        uint256 numExecutions;
        uint256 resetPercentage;
        bool hasPriceReset;
    }

    function createOneTimeOrder(
        address userAddress,
        address pairedTokenAddress,
        address tokenAddress,
        bool isBuy,
        uint256 targetPrice,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 amount
    ) external returns (uint256);

    function createContinuousOrder(
        address userAddress,
        address pairedTokenAddress,
        address tokenAddress,
        bool isBuy,
        uint256 targetPrice,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 amount,
        uint256 resetPercentage
    ) external returns (uint256);

    function updateOrder(
        uint256 orderId,
        address pairedTokenAddress,
        address tokenAddress,
        bool isBuy,
        uint256 targetPrice,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 amount,
        uint256 resetPercentage
    ) external;

    function cancelOrder(uint256 orderId) external returns (uint256);

    function orderCounter() external view returns (uint256);

    function getOrder(uint256 orderId) external view returns (Order memory);

    function setOrderStatus(
        uint256 orderId,
        IOrderMgr.OrderStatus status
    ) external;

    function incNumExecutions(uint256 orderId) external;

    function setHasPriceReset(uint256 orderId, bool flag) external;
}

interface IERC20Ext is IERC20 {
    function decimals() external view returns (uint8);
}

contract UrulokiDEX is ReentrancyGuard {
    //// Define events

    event OneTimeOrderCreated(uint256 orderId);
    event ContinuousOrderCreated(uint256 orderId);
    event OneTimeOrderEdited(uint256 orderId);
    event ContinuousOrderEdited(uint256 orderId);
    event OrderCanceled(uint256 orderId);
    event OrderExecuted(uint256 orderId, uint256 amount, uint256 price);
    event ExecutedOutOfPrice(uint256 orderId, bool isBuy, uint256 price);
    event ExecutedOneTimeOrder(
        uint256 orderId,
        bool isBuy,
        uint256 pairAmount,
        uint256 tokenAmount,
        uint256 price
    );
    event ExecutedContinuousOrder(
        uint256 orderId,
        bool isBuy,
        uint256 price
    );
    event FundsWithdrawn(
        address userAddress,
        address tokenAddress,
        uint256 amount
    );
    event FundsWithdrawnFromContinuousOrder(
        uint256 orderId,
        address userAddress,
        address tokenAddress,
        uint256 amount
    );
    event BackendOwner(address newOwner);
    event OutOfFunds(uint256 orderId);

    //// Define constants
    address private constant UNISWAP_V2_ROUTER = 0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008;
        // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint256 public constant PRICE_PRECISION = 10 ** 18;

    //// Define variables
    mapping(address => mapping(address => uint256)) public balances;
    // total fundsAmount locked by active continuous orders
    // mapping(address => mapping(address => uint256)) public lockBalances;
    IUniswapV2Router private uniswapRouter =
        IUniswapV2Router(UNISWAP_V2_ROUTER);

    address public backend_owner;
    address public orderMgrAddress;
    IOrderMgr _orderMgr;

    constructor() {
        backend_owner = msg.sender;
    }

    modifier validateOneTimeOrder(
        address pairedTokenAddress,
        address tokenAddress,
        bool isBuy,
        uint256 amount
    ) {
        // if buying token, pair token is spendable else if sell, the token is spendable
        if (!isBuy) {
            // Check if the user has enough balance
            require(
                balances[msg.sender][tokenAddress] >= amount,
                "Insufficient balance"
            );
            // Update the user's balance
            balances[msg.sender][tokenAddress] -= amount;
        } else {
            // Check if the user has enough balance
            require(
                balances[msg.sender][pairedTokenAddress] >= amount,
                "Insufficient balance"
            );
            // Update the user's balance
            balances[msg.sender][pairedTokenAddress] -= amount;
        }
        _;
    }

    // set backend owner address
    function setBackendOwner(address new_owner) public {
        require(msg.sender == backend_owner, "Not admin");
        backend_owner = new_owner;
        emit BackendOwner(backend_owner);
    }

    function setOrderMgr(address _orderMgrAddress) public {
        require(msg.sender == backend_owner, "setOrderMgr: not allowed");
        require(
            _orderMgrAddress != address(0),
            "setOrderMgr: invalid orderMgrAddress"
        );
        orderMgrAddress = _orderMgrAddress;
        _orderMgr = IOrderMgr(_orderMgrAddress);
    }

    /**
     * @notice allows users to make a deposit
     * @dev token should be transferred from the user wallet to the contract
     * @param tokenAddress token address
     * @param amount deposit amount
     */
    function addFunds(
        address tokenAddress,
        uint256 amount
    ) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");

        // Validates address
        // require(
        //     !address(msg.sender).isContract(),
        //     "Contract address not allowed"
        // );
        IERC20 token = IERC20(tokenAddress);
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
        // Update the user's balance
        balances[msg.sender][tokenAddress] += amount;
    }

    /**
     * @dev funds withdrawal external call
     * @param tokenAddress token address
     * @param amount token amount
     */
    function withdrawFunds(
        address tokenAddress,
        uint256 amount
    ) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");

        // Check if the user has enough balance to withdraw
        require(
            balances[msg.sender][tokenAddress] >= amount,
            "Insufficient balance"
        );

        // Update the user's balance
        balances[msg.sender][tokenAddress] -= amount;

        // Transfer ERC20 token to the user
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(msg.sender, amount), "Transfer failed");
        // Emit event
        emit FundsWithdrawn(msg.sender, tokenAddress, amount);
    }

    /**
     * @notice create non-continuous price range order
     * @param pairedTokenAddress pair address
     * @param tokenAddress token address
     * @param isBuy buy or sell
     * @param minPrice minimum price
     * @param maxPrice maximum price
     * @param amount token amount
     */
    function createNonContinuousPriceRangeOrder(
        address pairedTokenAddress,
        address tokenAddress,
        bool isBuy,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 amount
    )
        external
        nonReentrant
        validateOneTimeOrder(pairedTokenAddress, tokenAddress, isBuy, amount)
    {
        uint256 id = _orderMgr.createOneTimeOrder(
            msg.sender,
            pairedTokenAddress,
            tokenAddress,
            isBuy,
            0,
            minPrice,
            maxPrice,
            amount
        );
        // Emit an event
        emit OneTimeOrderCreated(id);
    }

    /**
     * @notice creates a non-continuous order with a target price
     * @dev target price order is only executed when the market price is equal to the target price
     * @param pairedTokenAddress pair address
     * @param tokenAddress token address
     * @param targetPrice target price
     * @param isBuy buy or sell order
     * @param amount token amount
     */
    function createNonContinuousTargetPriceOrder(
        address pairedTokenAddress,
        address tokenAddress,
        bool isBuy,
        uint256 targetPrice,
        uint256 amount
    )
        external
        nonReentrant
        validateOneTimeOrder(pairedTokenAddress, tokenAddress, isBuy, amount)
    {
        // Validates address
        // require(
        //     !address(msg.sender).isContract(),
        //     "Contract address not allowed"
        // );

        // Create a new order
        uint256 id = _orderMgr.createOneTimeOrder(
            msg.sender,
            pairedTokenAddress,
            tokenAddress,
            isBuy,
            targetPrice,
            0,
            0,
            amount
        );

        // Emit event
        emit OneTimeOrderCreated(id);
    }

    /**
     * @notice creates a continuous order with price range
     * @param pairedTokenAddress pair address
     * @param tokenAddress token address
     * @param isBuy buy or sell order
     * @param minPrice minimum price
     * @param maxPrice maximum price
     * @param amount token amount - this will be the amount of tokens to buy or sell, based on the token address provided
     * @param resetPercentage decimal represented as an int with 2 places of precision
     */
    function createContinuousPriceRangeOrder(
        address pairedTokenAddress,
        address tokenAddress,
        bool isBuy,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 amount,
        uint256 resetPercentage
    ) external nonReentrant {
        uint256 id = _orderMgr.createContinuousOrder(
            msg.sender,
            pairedTokenAddress,
            tokenAddress,
            isBuy,
            0,
            minPrice,
            maxPrice,
            amount,
            resetPercentage
        );

        // address spendableToken = isBuy ? pairedTokenAddress : tokenAddress;
        // lockBalances[msg.sender][spendableToken] += fundAmount;
        // lockBalances[msg.sender][spendableToken] -= amount;

        // Emit an event
        emit ContinuousOrderCreated(id);
    }

    /**
     * @notice creates a continuous order with price range
     * @param pairedTokenAddress pair address
     * @param tokenAddress token address
     * @param isBuy buy or sell order
     * @param targetPrice target price
     * @param amount token amount - this will be the amount of tokens to buy or sell, based on the token address provided
     * @param resetPercentage decimal represented as an int with 2 places of precision
     */
    function createContinuousTargetPriceOrder(
        address pairedTokenAddress,
        address tokenAddress,
        bool isBuy,
        uint256 targetPrice,
        uint256 amount,
        uint256 resetPercentage
    ) external nonReentrant {
        // Create the ContinuousOrder struct
        uint256 id = _orderMgr.createContinuousOrder(
            msg.sender,
            pairedTokenAddress,
            tokenAddress,
            isBuy,
            targetPrice,
            0,
            0,
            amount,
            resetPercentage
        );

        // address spendableToken = isBuy ? pairedTokenAddress : tokenAddress;
        // lockBalances[msg.sender][spendableToken] += fundAmount;
        // lockBalances[msg.sender][spendableToken] -= amount;

        // Emit an event
        emit ContinuousOrderCreated(id);
    }

    /**
     * @dev cancel exist order
     * @param orderId order id
     */
    function cancelOrder(uint256 orderId) external {
        // Validate order owner
        IOrderMgr.Order memory order = _orderMgr.getOrder(orderId);
        require(
            order.orderBase.userAddress == msg.sender,
            "msg.sender is not order owner"
        );

        _orderMgr.cancelOrder(orderId);
        if (!order.orderBase.isContinuous)
            if (order.orderBase.isBuy) {
                balances[msg.sender][order.orderBase.pairedTokenAddress] += order
                    .orderBase
                    .amount;
            } else {
                balances[msg.sender][order.orderBase.tokenAddress] += order
                    .orderBase
                    .amount;
            }

        // Emit event
        emit OrderCanceled(orderId);
    }

    /**
     * @notice process a one-time order
     * @param orderId id of the order
     */
    // function processOneTimeOrder(uint256 orderId) external {
    //     // require(msg.sender == backend_owner, "Not backend owner");
    //     IOrderMgr.Order memory order = _orderMgr.getOrder(orderId);

    //     // Is continous order
    //     require(order.orderBase.isContinuous == false, "Not one time order");

    //     // Check if the order is active
    //     require(
    //         order.orderBase.status == IOrderMgr.OrderStatus.Active,
    //         "Order not active"
    //     );

    //     _processOneTimeOrder(order, orderId);
    // }

    /**
     * @notice process a one-time order
     * @dev internal function
     * @param orderId id of the order
     */
    function _processOneTimeOrder(IOrderMgr.Order memory order, uint256 orderId) internal returns (bool) {
        // Get the price in amount
        uint256 price = _getPairPrice(
            order.orderBase.tokenAddress,
            order.orderBase.pairedTokenAddress,
            10 ** IERC20Ext(order.orderBase.tokenAddress).decimals()
        );
        address fromToken;
        address toToken;
        uint256 toAmount;
        uint256 fromAmount = order.orderBase.amount;

        // Check if the order type is PriceRange
        if (order.orderBase.orderType == IOrderMgr.OrderType.PriceRange) {
            // require(
            //     order.orderBase.minPrice <= price &&
            //         price <= order.orderBase.maxPrice,
            //     "order out of range"
            // );
            if (
                order.orderBase.minPrice > price || price > order.orderBase.maxPrice
            ) {
                emit ExecutedOutOfPrice(orderId, order.orderBase.isBuy, price);
                return false;
            }
        }

        if (order.orderBase.isBuy) {
            // Check if the order type is TargetPrice
            if (order.orderBase.orderType == IOrderMgr.OrderType.TargetPrice) {
                // require(
                //     price <= order.orderBase.targetPrice,
                //     "order out of target"
                // );
                if (
                    price > order.orderBase.targetPrice
                ) {
                    emit ExecutedOutOfPrice(orderId, order.orderBase.isBuy, price);
                    return false;
                }
            }
            fromToken = order.orderBase.pairedTokenAddress;
            toToken = order.orderBase.tokenAddress;
        } else {
            // Check if the order type is TargetPrice
            if (order.orderBase.orderType == IOrderMgr.OrderType.TargetPrice) {
                // require(
                //     price >= order.orderBase.targetPrice,
                //     "order out of target"
                // );
                if (price < order.orderBase.targetPrice) {
                    emit ExecutedOutOfPrice(orderId, order.orderBase.isBuy, price);
                    return false;
                }
            }
            fromToken = order.orderBase.tokenAddress;
            toToken = order.orderBase.pairedTokenAddress;
        }

        toAmount = _swapTokens(fromToken, toToken, fromAmount);
        balances[order.orderBase.userAddress][toToken] += toAmount;

        _orderMgr.setOrderStatus(orderId, IOrderMgr.OrderStatus.Completed);
        emit ExecutedOneTimeOrder(
            orderId,
            order.orderBase.isBuy,
            fromAmount,
            toAmount,
            price
        );
        return true;
    }

    /**
     * @notice process a continuous order
     * @param orderId id of the order
     */
    // function processContinuousOrder(uint256 orderId) external {
    //     IOrderMgr.Order memory order = _orderMgr.getOrder(orderId);

    //     // Is continous order
    //     require(order.orderBase.isContinuous == true, "Not continuous order");

    //     // Check if the order is active
    //     require(
    //         order.orderBase.status != IOrderMgr.OrderStatus.Cancelled,
    //         "Order not active"
    //     );

    //     _processContinuousOrder(order, orderId);
    // }

    /**
     * @notice process a continuous order
     * @dev internal function
     * @param orderId id of the order
     */
    function _processContinuousOrder(IOrderMgr.Order memory order, uint256 orderId) internal returns (bool){
        if (order.orderBase.targetPrice == 0) {
            // Price range order
            return _processContinuousPriceRangeOrder(order, orderId);
        } else {
            // Target price order
            return _processContinuousTargetPriceOrder(order, orderId);
        }
    }

    /**
     * @dev internal function to process a continuous price range order
     * @param order the order memory instance
     * @param orderId order id
     */
    function _processContinuousPriceRangeOrder(
        IOrderMgr.Order memory order,
        uint256 orderId
    ) internal returns(bool) {
        // Get the price in amount
        uint256 price = _getPairPrice(
            order.orderBase.tokenAddress,
            order.orderBase.pairedTokenAddress,
            10 ** IERC20Ext(order.orderBase.tokenAddress).decimals()
        );

        if (order.hasPriceReset) {
            // require(
            //     price > order.orderBase.minPrice &&
            //         price < order.orderBase.maxPrice,
            //     "Price is not fit 1"
            // );
            if (
                !(
                price > order.orderBase.minPrice 
                && price < order.orderBase.maxPrice
                )
            ) {
                emit ExecutedOutOfPrice(orderId, order.orderBase.isBuy, price);
                return false;
            }
            address fromToken;
            address toToken;
            if (order.orderBase.isBuy) {
                fromToken = order.orderBase.pairedTokenAddress;
                toToken = order.orderBase.tokenAddress;
            } else {
                fromToken = order.orderBase.tokenAddress;
                toToken = order.orderBase.pairedTokenAddress;
            }
            if (
                balances[order.orderBase.userAddress][fromToken] >=
                order.orderBase.amount
            ) {
                uint256 toAmount = _swapTokens(
                    fromToken,
                    toToken,
                    order.orderBase.amount
                );
                balances[order.orderBase.userAddress][toToken] += toAmount;
                balances[order.orderBase.userAddress][fromToken] -= order
                    .orderBase
                    .amount;

                _orderMgr.setOrderStatus(orderId, IOrderMgr.OrderStatus.Active);
                _orderMgr.incNumExecutions(orderId);
                _orderMgr.setHasPriceReset(orderId, false);
            } else {
                _orderMgr.setOrderStatus(
                    orderId,
                    IOrderMgr.OrderStatus.OutOfFunds
                );
                emit OutOfFunds(orderId);
            }
        } else {
            uint256 lowerDiff = (order.orderBase.minPrice *
                order.resetPercentage) / 100;
            uint256 upperDiff = (order.orderBase.maxPrice *
                order.resetPercentage) / 100;
            // require(
            //     price < order.orderBase.minPrice - lowerDiff ||
            //         price > order.orderBase.maxPrice + upperDiff,
            //     "Price is not fit 2"
            // );
            if (
                !(price < order.orderBase.minPrice - lowerDiff
                || price > order.orderBase.maxPrice + upperDiff)
            ) {
                emit ExecutedOutOfPrice(orderId, order.orderBase.isBuy, price);
                return false;
            }
            _orderMgr.setHasPriceReset(orderId, true);
        }
        emit ExecutedContinuousOrder(orderId, order.orderBase.isBuy, price);
        return true;
    }

    /**
     * @dev internal function to process a continuous target price order
     * @param order the order memory instance
     * @param orderId order id
     */
    function _processContinuousTargetPriceOrder(
        IOrderMgr.Order memory order,
        uint256 orderId
    ) internal returns (bool) {
        // Get the price in amount
        uint256 price = _getPairPrice(
            order.orderBase.tokenAddress,
            order.orderBase.pairedTokenAddress,
            10 ** IERC20Ext(order.orderBase.tokenAddress).decimals()
        );

        if (order.orderBase.isBuy) {
            if (order.hasPriceReset) {
                // check token price
                // require(
                //     price <= order.orderBase.targetPrice,
                //     "Price is not fit 1"
                // );

                if (price > order.orderBase.targetPrice) {
                    emit ExecutedOutOfPrice(orderId, order.orderBase.isBuy, price);
                    return false;
                }
                address fromToken;
                address toToken;

                fromToken = order.orderBase.pairedTokenAddress;
                toToken = order.orderBase.tokenAddress;

                if (
                    balances[order.orderBase.userAddress][fromToken] >=
                    order.orderBase.amount
                ) {
                    uint256 toAmount = _swapTokens(
                        fromToken,
                        toToken,
                        order.orderBase.amount
                    );
                    balances[order.orderBase.userAddress][toToken] += toAmount;
                    balances[order.orderBase.userAddress][fromToken] -= order
                        .orderBase
                        .amount;

                    _orderMgr.setOrderStatus(
                        orderId,
                        IOrderMgr.OrderStatus.Active
                    );
                    _orderMgr.incNumExecutions(orderId);
                    _orderMgr.setHasPriceReset(orderId, false);
                } else {
                    _orderMgr.setOrderStatus(
                        orderId,
                        IOrderMgr.OrderStatus.OutOfFunds
                    );
                    emit OutOfFunds(orderId);
                }
            } else {
                uint256 diff = (order.orderBase.targetPrice *
                    order.resetPercentage) / 100;
                // check price by resetPercentage
                // require(
                //     price >= order.orderBase.targetPrice + diff,
                //     "Price is not fit 2"
                // );
                if (price < order.orderBase.targetPrice + diff) {
                    emit ExecutedOutOfPrice(orderId, order.orderBase.isBuy, price);
                    return false;
                }
                _orderMgr.setHasPriceReset(orderId, true);
            }
        } else {
            if (order.hasPriceReset) {
                // check token price
                // require(
                //     price >= order.orderBase.targetPrice,
                //     "Price is not fit 3"
                // );

                if (price < order.orderBase.targetPrice) {
                    emit ExecutedOutOfPrice(orderId, order.orderBase.isBuy, price);
                    return false;
                }
                address fromToken;
                address toToken;

                fromToken = order.orderBase.tokenAddress;
                toToken = order.orderBase.pairedTokenAddress;

                if (
                    balances[order.orderBase.userAddress][fromToken] >=
                    order.orderBase.amount
                ) {
                    uint256 toAmount = _swapTokens(
                        fromToken,
                        toToken,
                        order.orderBase.amount
                    );
                    balances[order.orderBase.userAddress][toToken] += toAmount;
                    balances[order.orderBase.userAddress][fromToken] -= order
                        .orderBase
                        .amount;

                    _orderMgr.setOrderStatus(
                        orderId,
                        IOrderMgr.OrderStatus.Active
                    );
                    _orderMgr.incNumExecutions(orderId);
                    _orderMgr.setHasPriceReset(orderId, false);
                } else {
                    _orderMgr.setOrderStatus(
                        orderId,
                        IOrderMgr.OrderStatus.OutOfFunds
                    );
                    emit OutOfFunds(orderId);
                }
            } else {
                uint256 diff = (order.orderBase.targetPrice *
                    order.resetPercentage) / 100;
                // check price by resetPercentage
                // require(
                //     price <= order.orderBase.targetPrice - diff,
                //     "Price is not fit 4"
                // );
                if (price > order.orderBase.targetPrice - diff) {
                    emit ExecutedOutOfPrice(orderId, order.orderBase.isBuy, price);
                    return false;
                }
                _orderMgr.setHasPriceReset(orderId, true);
            }
        }
        emit ExecutedContinuousOrder(orderId, order.orderBase.isBuy, price);
        return true;
    }

    function processOrders(uint256[] memory orderIds) external {
        IOrderMgr.Order memory order;
        for (uint256 i = 0; i < orderIds.length; i++) {
            order = _orderMgr.getOrder(orderIds[i]);
            uint256 orderId = orderIds[i];
            if (order.orderBase.tokenAddress == address(0))
                continue;

            if (order.orderBase.isContinuous == true) {
                if (order.orderBase.status == IOrderMgr.OrderStatus.Cancelled)
                    continue;
                _processContinuousOrder(order, orderId);
            } else {
                if (order.orderBase.status != IOrderMgr.OrderStatus.Active)
                    continue;
                _processOneTimeOrder(order, orderId);
            }
        }
    }

    function _swapTokens(
        address _fromTokenAddress,
        address _toTokenAddress,
        uint256 _amount
    ) internal returns (uint256) {
        IERC20 fromToken = IERC20(_fromTokenAddress);
        // Already transferred when adding Funds and deducted from balances when creating an order
        // fromToken.transferFrom(msg.sender, address(this), _amount);
        fromToken.approve(address(uniswapRouter), _amount);

        address[] memory path = new address[](2);
        path[0] = _fromTokenAddress;
        path[1] = _toTokenAddress;
        uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this), // recipient is the contract, not caller in this case
            block.timestamp
        );
        return amounts[1];
    }

    function _getPairPrice(
        address _fromTokenAddress,
        address _toTokenAddress,
        uint256 _amount
    ) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = _fromTokenAddress;
        path[1] = _toTokenAddress;

        uint[] memory amountsOut = uniswapRouter.getAmountsOut(_amount, path);

        return amountsOut[1];
    }

    function getPairPrice(
        address _fromTokenAddress,
        address _toTokenAddress
    ) external view returns (uint256) {
        return
            _getPairPrice(
                _fromTokenAddress,
                _toTokenAddress,
                10 ** IERC20Ext(_fromTokenAddress).decimals()
            );
    }

    /*
     * @notice edit a continuous order with price range
     * @param orderId order id
     * @param pairedTokenAddress pair address
     * @param tokenAddress token address
     * @param isBuy buy or sell order
     * @param targetPrice target price
     * @param amount token amount - this will be the amount of tokens to buy or sell, based on the token address provided
     * @param resetPercentage decimal represented as an int with 2 places of precision
     */
    function editContinuousTargetPriceOrder(
        uint256 orderId,
        address pairedTokenAddress,
        address tokenAddress,
        bool isBuy,
        uint256 targetPrice,
        uint256 amount,
        uint256 resetPercentage
    ) external {
        IOrderMgr.Order memory order = _orderMgr.getOrder(orderId);
        // Validate order owner
        require(
            order.orderBase.userAddress == msg.sender,
            "msg.sender is not order owner"
        );
        // Is continous order
        require(order.orderBase.isContinuous == true, "Incorrect order type");

        _orderMgr.updateOrder(
            orderId,
            pairedTokenAddress,
            tokenAddress,
            isBuy,
            targetPrice,
            0,
            0,
            amount,
            resetPercentage
        );

        // Emit an event
        emit ContinuousOrderEdited(orderId);
    }

    /**
     * @notice edit a continuous order with price range
     * @param orderId order id
     * @param pairedTokenAddress pair address
     * @param tokenAddress token address
     * @param isBuy buy or sell order
     * @param minPrice minimum price
     * @param maxPrice maximum price
     * @param amount token amount - this will be the amount of tokens to buy or sell, based on the token address provided
     * @param resetPercentage decimal represented as an int with 2 places of precision
     */
    function editContinuousPriceRangeOrder(
        uint256 orderId,
        address pairedTokenAddress,
        address tokenAddress,
        bool isBuy,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 amount,
        uint256 resetPercentage
    ) external {
        IOrderMgr.Order memory order = _orderMgr.getOrder(orderId);
        // Validate order owner
        require(
            order.orderBase.userAddress == msg.sender,
            "msg.sender is not order owner"
        );
        // Is continous order
        require(order.orderBase.isContinuous == true, "Incorrect order type");

        _orderMgr.updateOrder(
            orderId,
            pairedTokenAddress,
            tokenAddress,
            isBuy,
            0,
            minPrice,
            maxPrice,
            amount,
            resetPercentage
        );

        // Emit an event
        emit ContinuousOrderEdited(orderId);
    }

    /**
     * @notice edit non-continuous price range order
     * @param orderId order id
     * @param pairedTokenAddress pair address
     * @param tokenAddress token address
     * @param isBuy buy or sell
     * @param minPrice minimum price
     * @param maxPrice maximum price
     * @param amount token amount
     */
    function editNonContinuousPriceRangeOrder(
        uint256 orderId,
        address pairedTokenAddress,
        address tokenAddress,
        bool isBuy,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 amount
    ) external {
        IOrderMgr.Order memory order = _orderMgr.getOrder(orderId);
        // Validate order owner
        require(
            order.orderBase.userAddress == msg.sender,
            "msg.sender is not order owner"
        );
        // Is continous order
        require(order.orderBase.isContinuous == false, "Incorrect order type");

        _orderMgr.updateOrder(
            orderId,
            pairedTokenAddress,
            tokenAddress,
            isBuy,
            0,
            minPrice,
            maxPrice,
            amount,
            0
        );
        // Emit an event
        emit OneTimeOrderEdited(orderId);
    }

    /**
     * @notice edit a non-continuous order with a target price
     * @dev target price order is only executed when the market price is equal to the target price
     * @param orderId order id
     * @param pairedTokenAddress pair address
     * @param tokenAddress token address
     * @param targetPrice target price
     * @param isBuy buy or sell order
     * @param amount token amount
     */
    function editNonContinuousTargetPriceOrder(
        uint256 orderId,
        address pairedTokenAddress,
        address tokenAddress,
        uint256 targetPrice,
        bool isBuy,
        uint256 amount
    ) external {
        IOrderMgr.Order memory order = _orderMgr.getOrder(orderId);
        // Validate order owner
        require(
            order.orderBase.userAddress == msg.sender,
            "msg.sender is not order owner"
        );
        // Is continous order
        require(order.orderBase.isContinuous == false, "Incorrect order type");

        _orderMgr.updateOrder(
            orderId,
            pairedTokenAddress,
            tokenAddress,
            isBuy,
            targetPrice,
            0,
            0,
            amount,
            0
        );

        // Emit event
        emit OneTimeOrderEdited(orderId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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