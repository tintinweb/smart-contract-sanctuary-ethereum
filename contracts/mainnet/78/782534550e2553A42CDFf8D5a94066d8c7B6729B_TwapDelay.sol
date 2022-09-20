// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;
pragma abicoder v2;

import './interfaces/ITwapPair.sol';
import './interfaces/ITwapDelay.sol';
import './interfaces/IWETH.sol';
import './libraries/SafeMath.sol';
import './libraries/Orders.sol';
import './libraries/TokenShares.sol';
import './libraries/AddLiquidity.sol';
import './libraries/WithdrawHelper.sol';

contract TwapDelay is ITwapDelay {
    using SafeMath for uint256;
    using Orders for Orders.Data;
    using TokenShares for TokenShares.Data;

    Orders.Data internal orders;
    TokenShares.Data internal tokenShares;

    uint256 private constant ORDER_CANCEL_TIME = 24 hours;
    uint256 private constant BOT_EXECUTION_TIME = 20 minutes;
    uint256 private constant ORDER_LIFESPAN = 48 hours;
    uint16 private constant MAX_TOLERANCE = 10;

    address public override owner;
    mapping(address => bool) public override isBot;

    mapping(address => uint16) public override tolerance;

    constructor(
        address _factory,
        address _weth,
        address _bot
    ) {
        orders.factory = _factory;
        owner = msg.sender;
        isBot[_bot] = true;
        orders.gasPrice = tx.gasprice - (tx.gasprice % 1e6);
        tokenShares.weth = _weth;
        orders.delay = 30 minutes;
        orders.maxGasLimit = 5_000_000;
        orders.gasPriceInertia = 20_000_000;
        orders.maxGasPriceImpact = 1_000_000;
        orders.setTransferGasCost(address(0), Orders.ETHER_TRANSFER_CALL_COST);

        emit OwnerSet(msg.sender);
    }

    function getTransferGasCost(address token) external view override returns (uint256 gasCost) {
        return orders.transferGasCosts[token];
    }

    function getDepositOrder(uint256 orderId) external view override returns (Orders.DepositOrder memory order) {
        (order, , ) = orders.getDepositOrder(orderId);
    }

    function getWithdrawOrder(uint256 orderId) external view override returns (Orders.WithdrawOrder memory order) {
        return orders.getWithdrawOrder(orderId);
    }

    function getSellOrder(uint256 orderId) external view override returns (Orders.SellOrder memory order) {
        (order, ) = orders.getSellOrder(orderId);
    }

    function getBuyOrder(uint256 orderId) external view override returns (Orders.BuyOrder memory order) {
        (order, ) = orders.getBuyOrder(orderId);
    }

    function getDepositDisabled(address pair) external view override returns (bool) {
        return orders.getDepositDisabled(pair);
    }

    function getWithdrawDisabled(address pair) external view override returns (bool) {
        return orders.getWithdrawDisabled(pair);
    }

    function getBuyDisabled(address pair) external view override returns (bool) {
        return orders.getBuyDisabled(pair);
    }

    function getSellDisabled(address pair) external view override returns (bool) {
        return orders.getSellDisabled(pair);
    }

    function getOrderStatus(uint256 orderId) external view override returns (Orders.OrderStatus) {
        return orders.getOrderStatus(orderId);
    }

    uint256 private locked;
    modifier lock() {
        require(locked == 0, 'TD06');
        locked = 1;
        _;
        locked = 0;
    }

    function factory() external view override returns (address) {
        return orders.factory;
    }

    function totalShares(address token) external view override returns (uint256) {
        return tokenShares.totalShares[token];
    }

    function weth() external view override returns (address) {
        return tokenShares.weth;
    }

    function delay() external view override returns (uint32) {
        return orders.delay;
    }

    function lastProcessedOrderId() external view returns (uint256) {
        return orders.lastProcessedOrderId;
    }

    function newestOrderId() external view returns (uint256) {
        return orders.newestOrderId;
    }

    function getOrder(uint256 orderId) external view returns (Orders.OrderType orderType, uint32 validAfterTimestamp) {
        return orders.getOrder(orderId);
    }

    function isOrderCanceled(uint256 orderId) external view returns (bool) {
        return orders.canceled[orderId];
    }

    function maxGasLimit() external view override returns (uint256) {
        return orders.maxGasLimit;
    }

    function maxGasPriceImpact() external view override returns (uint256) {
        return orders.maxGasPriceImpact;
    }

    function gasPriceInertia() external view override returns (uint256) {
        return orders.gasPriceInertia;
    }

    function gasPrice() external view override returns (uint256) {
        return orders.gasPrice;
    }

    function setOrderDisabled(
        address pair,
        Orders.OrderType orderType,
        bool disabled
    ) external payable override {
        require(msg.sender == owner, 'TD00');
        orders.setOrderDisabled(pair, orderType, disabled);
    }

    function setOwner(address _owner) external payable override {
        require(msg.sender == owner, 'TD00');
        // require(_owner != owner, 'TD01'); // Comment out to save size
        require(_owner != address(0), 'TD02');
        owner = _owner;
        emit OwnerSet(_owner);
    }

    function setBot(address _bot, bool _isBot) external payable override {
        require(msg.sender == owner, 'TD00');
        // require(_isBot != isBot[_bot], 'TD01'); // Comment out to save size
        isBot[_bot] = _isBot;
        emit BotSet(_bot, _isBot);
    }

    function setMaxGasLimit(uint256 _maxGasLimit) external payable override {
        require(msg.sender == owner, 'TD00');
        orders.setMaxGasLimit(_maxGasLimit);
    }

    function setDelay(uint32 _delay) external payable override {
        require(msg.sender == owner, 'TD00');
        // require(_delay != orders.delay, 'TD01'); // Comment out to save size
        orders.delay = _delay;
        emit DelaySet(_delay);
    }

    function setGasPriceInertia(uint256 _gasPriceInertia) external payable override {
        require(msg.sender == owner, 'TD00');
        orders.setGasPriceInertia(_gasPriceInertia);
    }

    function setMaxGasPriceImpact(uint256 _maxGasPriceImpact) external payable override {
        require(msg.sender == owner, 'TD00');
        orders.setMaxGasPriceImpact(_maxGasPriceImpact);
    }

    function setTransferGasCost(address token, uint256 gasCost) external payable override {
        require(msg.sender == owner, 'TD00');
        orders.setTransferGasCost(token, gasCost);
    }

    function setTolerance(address pair, uint16 amount) external payable override {
        require(msg.sender == owner, 'TD00');
        require(amount <= MAX_TOLERANCE, 'TD54');
        tolerance[pair] = amount;
        emit ToleranceSet(pair, amount);
    }

    function deposit(Orders.DepositParams calldata depositParams)
        external
        payable
        override
        lock
        returns (uint256 orderId)
    {
        orders.deposit(depositParams, tokenShares);
        return orders.newestOrderId;
    }

    function withdraw(Orders.WithdrawParams calldata withdrawParams)
        external
        payable
        override
        lock
        returns (uint256 orderId)
    {
        orders.withdraw(withdrawParams);
        return orders.newestOrderId;
    }

    function sell(Orders.SellParams calldata sellParams) external payable override lock returns (uint256 orderId) {
        orders.sell(sellParams, tokenShares);
        return orders.newestOrderId;
    }

    function buy(Orders.BuyParams calldata buyParams) external payable override lock returns (uint256 orderId) {
        orders.buy(buyParams, tokenShares);
        return orders.newestOrderId;
    }

    function execute(uint256 n) external payable override lock {
        emit Execute(msg.sender, n);
        uint256 gasBefore = gasleft();
        bool orderExecuted;
        bool senderCanExecute = isBot[msg.sender] || isBot[address(0)];
        for (uint256 i; i < n; ++i) {
            if (orders.canceled[orders.lastProcessedOrderId + 1]) {
                orders.dequeueCanceledOrder();
                continue;
            }
            (Orders.OrderType orderType, uint256 validAfterTimestamp) = orders.getNextOrder();
            if (orderType == Orders.OrderType.Empty || validAfterTimestamp >= block.timestamp) {
                break;
            }
            require(senderCanExecute || block.timestamp >= validAfterTimestamp + BOT_EXECUTION_TIME, 'TD00');
            orderExecuted = true;
            if (orderType == Orders.OrderType.Deposit) {
                executeDeposit();
            } else if (orderType == Orders.OrderType.Withdraw) {
                executeWithdraw();
            } else if (orderType == Orders.OrderType.Sell) {
                executeSell();
            } else if (orderType == Orders.OrderType.Buy) {
                executeBuy();
            }
        }
        if (orderExecuted) {
            orders.updateGasPrice(gasBefore.sub(gasleft()));
        }
    }

    function executeDeposit() internal {
        uint256 gasStart = gasleft();
        (Orders.DepositOrder memory depositOrder, uint256 amountLimit0, uint256 amountLimit1) = orders
            .dequeueDepositOrder();
        (, address token0, address token1) = orders.getPairInfo(depositOrder.pairId);
        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: depositOrder.gasLimit.sub(
                Orders.ORDER_BASE_COST.add(orders.transferGasCosts[token0]).add(orders.transferGasCosts[token1])
            )
        }(abi.encodeWithSelector(this._executeDeposit.selector, depositOrder, amountLimit0, amountLimit1));
        bool refundSuccess = true;
        if (!executionSuccess) {
            refundSuccess = refundTokens(
                depositOrder.to,
                token0,
                depositOrder.share0,
                token1,
                depositOrder.share1,
                depositOrder.unwrap
            );
        }
        finalizeOrder(refundSuccess);
        (uint256 gasUsed, uint256 ethRefund) = refund(
            depositOrder.gasLimit,
            depositOrder.gasPrice,
            gasStart,
            depositOrder.to
        );
        emit OrderExecuted(orders.lastProcessedOrderId, executionSuccess, data, gasUsed, ethRefund);
    }

    function executeWithdraw() internal {
        uint256 gasStart = gasleft();
        Orders.WithdrawOrder memory withdrawOrder = orders.dequeueWithdrawOrder();
        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: withdrawOrder.gasLimit.sub(Orders.ORDER_BASE_COST.add(Orders.PAIR_TRANSFER_COST))
        }(abi.encodeWithSelector(this._executeWithdraw.selector, withdrawOrder));
        bool refundSuccess = true;
        if (!executionSuccess) {
            (address pair, , ) = orders.getPairInfo(withdrawOrder.pairId);
            refundSuccess = Orders.refundLiquidity(
                pair,
                withdrawOrder.to,
                withdrawOrder.liquidity,
                this._refundLiquidity.selector
            );
        }
        finalizeOrder(refundSuccess);
        (uint256 gasUsed, uint256 ethRefund) = refund(
            withdrawOrder.gasLimit,
            withdrawOrder.gasPrice,
            gasStart,
            withdrawOrder.to
        );
        emit OrderExecuted(orders.lastProcessedOrderId, executionSuccess, data, gasUsed, ethRefund);
    }

    function executeSell() internal {
        uint256 gasStart = gasleft();
        (Orders.SellOrder memory sellOrder, uint256 amountLimit) = orders.dequeueSellOrder();

        (, address token0, address token1) = orders.getPairInfo(sellOrder.pairId);
        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: sellOrder.gasLimit.sub(
                Orders.ORDER_BASE_COST.add(orders.transferGasCosts[sellOrder.inverse ? token1 : token0])
            )
        }(abi.encodeWithSelector(this._executeSell.selector, sellOrder, amountLimit));
        bool refundSuccess = true;
        if (!executionSuccess) {
            refundSuccess = refundToken(
                sellOrder.inverse ? token1 : token0,
                sellOrder.to,
                sellOrder.shareIn,
                sellOrder.unwrap
            );
        }
        finalizeOrder(refundSuccess);
        (uint256 gasUsed, uint256 ethRefund) = refund(sellOrder.gasLimit, sellOrder.gasPrice, gasStart, sellOrder.to);
        emit OrderExecuted(orders.lastProcessedOrderId, executionSuccess, data, gasUsed, ethRefund);
    }

    function executeBuy() internal {
        uint256 gasStart = gasleft();
        (Orders.BuyOrder memory buyOrder, uint256 amountLimit) = orders.dequeueBuyOrder();
        (, address token0, address token1) = orders.getPairInfo(buyOrder.pairId);
        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: buyOrder.gasLimit.sub(
                Orders.ORDER_BASE_COST.add(orders.transferGasCosts[buyOrder.inverse ? token1 : token0])
            )
        }(abi.encodeWithSelector(this._executeBuy.selector, buyOrder, amountLimit));
        bool refundSuccess = true;
        if (!executionSuccess) {
            refundSuccess = refundToken(
                buyOrder.inverse ? token1 : token0,
                buyOrder.to,
                buyOrder.shareInMax,
                buyOrder.unwrap
            );
        }
        finalizeOrder(refundSuccess);
        (uint256 gasUsed, uint256 ethRefund) = refund(buyOrder.gasLimit, buyOrder.gasPrice, gasStart, buyOrder.to);
        emit OrderExecuted(orders.lastProcessedOrderId, executionSuccess, data, gasUsed, ethRefund);
    }

    function finalizeOrder(bool refundSuccess) private {
        if (!refundSuccess) {
            orders.markRefundFailed();
        } else {
            orders.forgetLastProcessedOrder();
        }
    }

    function refund(
        uint256 gasLimit,
        uint256 gasPriceInOrder,
        uint256 gasStart,
        address to
    ) private returns (uint256 gasUsed, uint256 leftOver) {
        uint256 feeCollected = gasLimit.mul(gasPriceInOrder);
        gasUsed = gasStart.sub(gasleft()).add(Orders.REFUND_BASE_COST);
        uint256 actualRefund = Math.min(feeCollected, gasUsed.mul(orders.gasPrice));
        leftOver = feeCollected.sub(actualRefund);
        require(refundEth(msg.sender, actualRefund), 'TD40');
        refundEth(payable(to), leftOver);
    }

    function refundEth(address payable to, uint256 value) internal returns (bool success) {
        if (value == 0) {
            return true;
        }
        success = TransferHelper.transferETH(to, value, orders.transferGasCosts[address(0)]);
        emit EthRefund(to, success, value);
    }

    function refundToken(
        address token,
        address to,
        uint256 share,
        bool unwrap
    ) private returns (bool) {
        if (share == 0) {
            return true;
        }
        (bool success, bytes memory data) = address(this).call{ gas: orders.transferGasCosts[token] }(
            abi.encodeWithSelector(this._refundToken.selector, token, to, share, unwrap)
        );
        if (!success) {
            emit RefundFailed(to, token, share, data);
        }
        return success;
    }

    function refundTokens(
        address to,
        address token0,
        uint256 share0,
        address token1,
        uint256 share1,
        bool unwrap
    ) private returns (bool) {
        (bool success, bytes memory data) = address(this).call{
            gas: orders.transferGasCosts[token0].add(orders.transferGasCosts[token1])
        }(abi.encodeWithSelector(this._refundTokens.selector, to, token0, share0, token1, share1, unwrap));
        if (!success) {
            emit RefundFailed(to, token0, share0, data);
            emit RefundFailed(to, token1, share1, data);
        }
        return success;
    }

    function _refundTokens(
        address to,
        address token0,
        uint256 share0,
        address token1,
        uint256 share1,
        bool unwrap
    ) external payable {
        // no need to check sender, because it is checked in _refundToken
        _refundToken(token0, to, share0, unwrap);
        _refundToken(token1, to, share1, unwrap);
    }

    function _refundToken(
        address token,
        address to,
        uint256 share,
        bool unwrap
    ) public payable {
        require(msg.sender == address(this), 'TD00');
        if (token == tokenShares.weth && unwrap) {
            uint256 amount = tokenShares.sharesToAmount(token, share, 0, to);
            IWETH(tokenShares.weth).withdraw(amount);
            TransferHelper.safeTransferETH(to, amount, orders.transferGasCosts[address(0)]);
        } else {
            TransferHelper.safeTransfer(token, to, tokenShares.sharesToAmount(token, share, 0, to));
        }
    }

    function _refundLiquidity(
        address pair,
        address to,
        uint256 liquidity
    ) external payable {
        require(msg.sender == address(this), 'TD00');
        return TransferHelper.safeTransfer(pair, to, liquidity);
    }

    function _executeDeposit(
        Orders.DepositOrder calldata depositOrder,
        uint256 amountLimit0,
        uint256 amountLimit1
    ) external payable {
        require(msg.sender == address(this), 'TD00');
        require(depositOrder.validAfterTimestamp + ORDER_LIFESPAN >= block.timestamp, 'TD04');

        (
            Orders.PairInfo memory pairInfo,
            uint256 amount0Left,
            uint256 amount1Left,
            uint256 swapToken
        ) = _initialDeposit(depositOrder, amountLimit0, amountLimit1);
        if (depositOrder.swap && swapToken != 0) {
            bytes memory data = encodePriceInfo(pairInfo.pair, depositOrder.priceAccumulator, depositOrder.timestamp);
            if (amount0Left != 0 && swapToken == 1) {
                uint256 extraAmount1;
                (amount0Left, extraAmount1) = AddLiquidity.swapDeposit0(
                    pairInfo.pair,
                    pairInfo.token0,
                    amount0Left,
                    depositOrder.minSwapPrice,
                    tolerance[pairInfo.pair],
                    data
                );
                amount1Left = amount1Left.add(extraAmount1);
            } else if (amount1Left != 0 && swapToken == 2) {
                uint256 extraAmount0;
                (extraAmount0, amount1Left) = AddLiquidity.swapDeposit1(
                    pairInfo.pair,
                    pairInfo.token1,
                    amount1Left,
                    depositOrder.maxSwapPrice,
                    tolerance[pairInfo.pair],
                    data
                );
                amount0Left = amount0Left.add(extraAmount0);
            }
        }

        if (amount0Left != 0 && amount1Left != 0) {
            (amount0Left, amount1Left, ) = AddLiquidity.addLiquidityAndMint(
                pairInfo.pair,
                depositOrder.to,
                pairInfo.token0,
                pairInfo.token1,
                amount0Left,
                amount1Left
            );
        }

        AddLiquidity._refundDeposit(depositOrder.to, pairInfo.token0, pairInfo.token1, amount0Left, amount1Left);
    }

    function _initialDeposit(
        Orders.DepositOrder calldata depositOrder,
        uint256 amountLimit0,
        uint256 amountLimit1
    )
        private
        returns (
            Orders.PairInfo memory pairInfo,
            uint256 amount0Left,
            uint256 amount1Left,
            uint256 swapToken
        )
    {
        pairInfo = orders.pairs[depositOrder.pairId];
        uint256 amount0Desired = tokenShares.sharesToAmount(
            pairInfo.token0,
            depositOrder.share0,
            amountLimit0,
            depositOrder.to
        );
        uint256 amount1Desired = tokenShares.sharesToAmount(
            pairInfo.token1,
            depositOrder.share1,
            amountLimit1,
            depositOrder.to
        );
        ITwapPair(pairInfo.pair).sync();
        (amount0Left, amount1Left, swapToken) = AddLiquidity.addLiquidityAndMint(
            pairInfo.pair,
            depositOrder.to,
            pairInfo.token0,
            pairInfo.token1,
            amount0Desired,
            amount1Desired
        );
    }

    function _executeWithdraw(Orders.WithdrawOrder calldata withdrawOrder) external payable {
        require(msg.sender == address(this), 'TD00');
        require(withdrawOrder.validAfterTimestamp + ORDER_LIFESPAN >= block.timestamp, 'TD04');
        (address pair, address token0, address token1) = orders.getPairInfo(withdrawOrder.pairId);
        ITwapPair(pair).sync();
        TransferHelper.safeTransfer(pair, pair, withdrawOrder.liquidity);
        uint256 wethAmount;
        uint256 amount0;
        uint256 amount1;
        if (withdrawOrder.unwrap && (token0 == tokenShares.weth || token1 == tokenShares.weth)) {
            bool success;
            (success, wethAmount, amount0, amount1) = WithdrawHelper.withdrawAndUnwrap(
                token0,
                token1,
                pair,
                tokenShares.weth,
                withdrawOrder.to,
                orders.transferGasCosts[address(0)]
            );
            if (!success) {
                tokenShares.onUnwrapFailed(withdrawOrder.to, wethAmount);
            }
        } else {
            (amount0, amount1) = ITwapPair(pair).burn(withdrawOrder.to);
        }
        require(amount0 >= withdrawOrder.amount0Min && amount1 >= withdrawOrder.amount1Min, 'TD03');
    }

    function _executeBuy(Orders.BuyOrder calldata buyOrder, uint256 amountLimit) external payable {
        require(msg.sender == address(this), 'TD00');
        require(buyOrder.validAfterTimestamp + ORDER_LIFESPAN >= block.timestamp, 'TD04');

        (address pairAddress, address tokenIn, address tokenOut) = _getPairAndTokens(buyOrder.pairId, buyOrder.inverse);
        uint256 amountInMax = tokenShares.sharesToAmount(tokenIn, buyOrder.shareInMax, amountLimit, buyOrder.to);
        ITwapPair(pairAddress).sync();
        bytes memory priceInfo = encodePriceInfo(pairAddress, buyOrder.priceAccumulator, buyOrder.timestamp);
        uint256 amountIn;
        uint256 amountOut;
        uint256 reserveOut;
        {
            // scope for reserve out logic, avoids stack too deep errors
            (uint112 reserve0, uint112 reserve1) = ITwapPair(pairAddress).getReserves();
            // subtract 1 to prevent reserve going to 0
            reserveOut = uint256(buyOrder.inverse ? reserve0 : reserve1).sub(1);
        }
        {
            // scope for partial fill logic, avoids stack too deep errors
            address oracle = ITwapPair(pairAddress).oracle();
            uint256 swapFee = ITwapPair(pairAddress).swapFee();
            (amountIn, amountOut) = ITwapOracle(oracle).getSwapAmountInMaxOut(
                buyOrder.inverse,
                swapFee,
                buyOrder.amountOut,
                priceInfo
            );
            uint256 amountInMaxScaled;
            if (amountOut > reserveOut) {
                amountInMaxScaled = amountInMax.mul(reserveOut).ceil_div(buyOrder.amountOut);
                (amountIn, amountOut) = ITwapOracle(oracle).getSwapAmountInMinOut(
                    buyOrder.inverse,
                    swapFee,
                    reserveOut,
                    priceInfo
                );
            } else {
                amountInMaxScaled = amountInMax;
                amountOut = buyOrder.amountOut; // Truncate to desired out
            }
            require(amountInMaxScaled >= amountIn, 'TD08');
            if (amountInMax > amountIn) {
                if (tokenIn == tokenShares.weth && buyOrder.unwrap) {
                    _forceEtherTransfer(buyOrder.to, amountInMax.sub(amountIn));
                } else {
                    TransferHelper.safeTransfer(tokenIn, buyOrder.to, amountInMax.sub(amountIn));
                }
            }
            TransferHelper.safeTransfer(tokenIn, pairAddress, amountIn);
        }
        amountOut = amountOut.sub(tolerance[pairAddress]);
        uint256 amount0Out;
        uint256 amount1Out;
        if (buyOrder.inverse) {
            amount0Out = amountOut;
        } else {
            amount1Out = amountOut;
        }
        if (tokenOut == tokenShares.weth && buyOrder.unwrap) {
            ITwapPair(pairAddress).swap(amount0Out, amount1Out, address(this), priceInfo);
            _forceEtherTransfer(buyOrder.to, amountOut);
        } else {
            ITwapPair(pairAddress).swap(amount0Out, amount1Out, buyOrder.to, priceInfo);
        }
    }

    function _executeSell(Orders.SellOrder calldata sellOrder, uint256 amountLimit) external payable {
        require(msg.sender == address(this), 'TD00');
        require(sellOrder.validAfterTimestamp + ORDER_LIFESPAN >= block.timestamp, 'TD04');

        (address pairAddress, address tokenIn, address tokenOut) = _getPairAndTokens(
            sellOrder.pairId,
            sellOrder.inverse
        );
        ITwapPair(pairAddress).sync();
        bytes memory priceInfo = encodePriceInfo(pairAddress, sellOrder.priceAccumulator, sellOrder.timestamp);

        uint256 amountOut = _executeSellHelper(sellOrder, amountLimit, pairAddress, tokenIn, priceInfo);

        (uint256 amount0Out, uint256 amount1Out) = sellOrder.inverse
            ? (amountOut, uint256(0))
            : (uint256(0), amountOut);
        if (tokenOut == tokenShares.weth && sellOrder.unwrap) {
            ITwapPair(pairAddress).swap(amount0Out, amount1Out, address(this), priceInfo);
            _forceEtherTransfer(sellOrder.to, amountOut);
        } else {
            ITwapPair(pairAddress).swap(amount0Out, amount1Out, sellOrder.to, priceInfo);
        }
    }

    function _executeSellHelper(
        Orders.SellOrder calldata sellOrder,
        uint256 amountLimit,
        address pairAddress,
        address tokenIn,
        bytes memory priceInfo
    ) internal returns (uint256 amountOut) {
        uint256 reserveOut;
        {
            // scope for determining reserve out, avoids stack too deep errors
            (uint112 reserve0, uint112 reserve1) = ITwapPair(pairAddress).getReserves();
            // subtract 1 to prevent reserve going to 0
            reserveOut = uint256(sellOrder.inverse ? reserve0 : reserve1).sub(1);
        }
        {
            // scope for calculations, avoids stack too deep errors
            address oracle = ITwapPair(pairAddress).oracle();
            uint256 swapFee = ITwapPair(pairAddress).swapFee();
            uint256 amountIn = tokenShares.sharesToAmount(tokenIn, sellOrder.shareIn, amountLimit, sellOrder.to);
            amountOut = sellOrder.inverse
                ? ITwapOracle(oracle).getSwapAmount0Out(swapFee, amountIn, priceInfo)
                : ITwapOracle(oracle).getSwapAmount1Out(swapFee, amountIn, priceInfo);

            uint256 amountOutMinScaled;
            if (amountOut > reserveOut) {
                amountOutMinScaled = sellOrder.amountOutMin.mul(reserveOut).div(amountOut);
                uint256 _amountIn = amountIn;
                (amountIn, amountOut) = ITwapOracle(oracle).getSwapAmountInMinOut(
                    sellOrder.inverse,
                    swapFee,
                    reserveOut,
                    priceInfo
                );
                if (tokenIn == tokenShares.weth && sellOrder.unwrap) {
                    _forceEtherTransfer(sellOrder.to, _amountIn.sub(amountIn));
                } else {
                    TransferHelper.safeTransfer(tokenIn, sellOrder.to, _amountIn.sub(amountIn));
                }
            } else {
                amountOutMinScaled = sellOrder.amountOutMin;
            }
            amountOut = amountOut.sub(tolerance[pairAddress]);
            require(amountOut >= amountOutMinScaled, 'TD37');
            TransferHelper.safeTransfer(tokenIn, pairAddress, amountIn);
        }
    }

    function _getPairAndTokens(uint32 pairId, bool pairInversed)
        private
        view
        returns (
            address,
            address,
            address
        )
    {
        (address pairAddress, address token0, address token1) = orders.getPairInfo(pairId);
        (address tokenIn, address tokenOut) = pairInversed ? (token1, token0) : (token0, token1);
        return (pairAddress, tokenIn, tokenOut);
    }

    function _forceEtherTransfer(address to, uint256 amount) internal {
        IWETH(tokenShares.weth).withdraw(amount);
        (bool success, ) = to.call{ value: amount, gas: orders.transferGasCosts[address(0)] }('');
        if (!success) {
            tokenShares.onUnwrapFailed(to, amount);
        }
    }

    function performRefund(
        Orders.OrderType orderType,
        uint256 validAfterTimestamp,
        uint256 orderId,
        bool shouldRefundEth
    ) internal {
        require(orderType != Orders.OrderType.Empty, 'TD41');
        bool canOwnerRefund = validAfterTimestamp.add(365 days) < block.timestamp;

        if (orderType == Orders.OrderType.Deposit) {
            (Orders.DepositOrder memory depositOrder, , ) = orders.getDepositOrder(orderId);
            (, address token0, address token1) = orders.getPairInfo(depositOrder.pairId);
            address to = canOwnerRefund ? owner : depositOrder.to;
            require(
                refundTokens(to, token0, depositOrder.share0, token1, depositOrder.share1, depositOrder.unwrap),
                'TD14'
            );
            if (shouldRefundEth) {
                require(refundEth(payable(to), depositOrder.gasPrice.mul(depositOrder.gasLimit)), 'TD40');
            }
        } else if (orderType == Orders.OrderType.Withdraw) {
            Orders.WithdrawOrder memory withdrawOrder = orders.getWithdrawOrder(orderId);
            (address pair, , ) = orders.getPairInfo(withdrawOrder.pairId);
            address to = canOwnerRefund ? owner : withdrawOrder.to;
            require(Orders.refundLiquidity(pair, to, withdrawOrder.liquidity, this._refundLiquidity.selector), 'TD14');
            if (shouldRefundEth) {
                require(refundEth(payable(to), withdrawOrder.gasPrice.mul(withdrawOrder.gasLimit)), 'TD40');
            }
        } else if (orderType == Orders.OrderType.Sell) {
            (Orders.SellOrder memory sellOrder, ) = orders.getSellOrder(orderId);
            (, address token0, address token1) = orders.getPairInfo(sellOrder.pairId);
            address to = canOwnerRefund ? owner : sellOrder.to;
            require(refundToken(sellOrder.inverse ? token1 : token0, to, sellOrder.shareIn, sellOrder.unwrap), 'TD14');
            if (shouldRefundEth) {
                require(refundEth(payable(to), sellOrder.gasPrice.mul(sellOrder.gasLimit)), 'TD40');
            }
        } else if (orderType == Orders.OrderType.Buy) {
            (Orders.BuyOrder memory buyOrder, ) = orders.getBuyOrder(orderId);
            (, address token0, address token1) = orders.getPairInfo(buyOrder.pairId);
            address to = canOwnerRefund ? owner : buyOrder.to;
            require(refundToken(buyOrder.inverse ? token1 : token0, to, buyOrder.shareInMax, buyOrder.unwrap), 'TD14');
            if (shouldRefundEth) {
                require(refundEth(payable(to), buyOrder.gasPrice.mul(buyOrder.gasLimit)), 'TD40');
            }
        }
        orders.forgetOrder(orderId);
    }

    function retryRefund(uint256 orderId) external override lock {
        (Orders.OrderType orderType, uint256 validAfterTimestamp) = orders.getFailedOrderType(orderId);
        performRefund(orderType, validAfterTimestamp, orderId, false);
    }

    function cancelOrder(uint256 orderId) external override lock {
        require(orders.getOrderStatus(orderId) == Orders.OrderStatus.EnqueuedReady, 'TD52');
        (Orders.OrderType orderType, uint256 validAfterTimestamp) = orders.getOrder(orderId);
        require(validAfterTimestamp.sub(orders.delay).add(ORDER_CANCEL_TIME) < block.timestamp, 'TD1C');
        orders.canceled[orderId] = true;
        performRefund(orderType, validAfterTimestamp, orderId, true);
    }

    function encodePriceInfo(
        address pair,
        uint256 priceAccumulator,
        uint32 priceTimestamp
    ) internal view returns (bytes memory data) {
        uint256 price = ITwapOracle(ITwapPair(pair).oracle()).getAveragePrice(priceAccumulator, priceTimestamp);
        // Pack everything as 32 bytes / uint256 to simplify decoding
        data = abi.encode(price);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;
pragma abicoder v2;

import '../libraries/Orders.sol';

interface ITwapDelay {
    event OrderExecuted(uint256 indexed id, bool indexed success, bytes data, uint256 gasSpent, uint256 ethRefunded);
    event RefundFailed(address indexed to, address indexed token, uint256 amount, bytes data);
    event EthRefund(address indexed to, bool indexed success, uint256 value);
    event OwnerSet(address owner);
    event BotSet(address bot, bool isBot);
    event DelaySet(uint256 delay);
    event MaxGasLimitSet(uint256 maxGasLimit);
    event GasPriceInertiaSet(uint256 gasPriceInertia);
    event MaxGasPriceImpactSet(uint256 maxGasPriceImpact);
    event TransferGasCostSet(address token, uint256 gasCost);
    event ToleranceSet(address pair, uint16 amount);
    event OrderDisabled(address pair, Orders.OrderType orderType, bool disabled);
    event UnwrapFailed(address to, uint256 amount);
    event Execute(address sender, uint256 n);

    function factory() external returns (address);

    function owner() external returns (address);

    function isBot(address bot) external returns (bool);

    function tolerance(address pair) external returns (uint16);

    function gasPriceInertia() external returns (uint256);

    function gasPrice() external returns (uint256);

    function maxGasPriceImpact() external returns (uint256);

    function maxGasLimit() external returns (uint256);

    function delay() external returns (uint32);

    function totalShares(address token) external returns (uint256);

    function weth() external returns (address);

    function getTransferGasCost(address token) external returns (uint256);

    function getDepositOrder(uint256 orderId) external returns (Orders.DepositOrder memory order);

    function getWithdrawOrder(uint256 orderId) external returns (Orders.WithdrawOrder memory order);

    function getSellOrder(uint256 orderId) external returns (Orders.SellOrder memory order);

    function getBuyOrder(uint256 orderId) external returns (Orders.BuyOrder memory order);

    function getDepositDisabled(address pair) external returns (bool);

    function getWithdrawDisabled(address pair) external returns (bool);

    function getBuyDisabled(address pair) external returns (bool);

    function getSellDisabled(address pair) external returns (bool);

    function getOrderStatus(uint256 orderId) external view returns (Orders.OrderStatus);

    function setOrderDisabled(
        address pair,
        Orders.OrderType orderType,
        bool disabled
    ) external payable;

    function setOwner(address _owner) external payable;

    function setBot(address _bot, bool _isBot) external payable;

    function setMaxGasLimit(uint256 _maxGasLimit) external payable;

    function setDelay(uint32 _delay) external payable;

    function setGasPriceInertia(uint256 _gasPriceInertia) external payable;

    function setMaxGasPriceImpact(uint256 _maxGasPriceImpact) external payable;

    function setTransferGasCost(address token, uint256 gasCost) external payable;

    function setTolerance(address pair, uint16 amount) external payable;

    function deposit(Orders.DepositParams memory depositParams) external payable returns (uint256 orderId);

    function withdraw(Orders.WithdrawParams memory withdrawParams) external payable returns (uint256 orderId);

    function sell(Orders.SellParams memory sellParams) external payable returns (uint256 orderId);

    function buy(Orders.BuyParams memory buyParams) external payable returns (uint256 orderId);

    function execute(uint256 n) external payable;

    function retryRefund(uint256 orderId) external;

    function cancelOrder(uint256 orderId) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

import '../interfaces/IERC20.sol';
import '../interfaces/IWETH.sol';
import './SafeMath.sol';
import './TransferHelper.sol';

library TokenShares {
    using SafeMath for uint256;
    using TransferHelper for address;

    uint256 private constant PRECISION = 10**18;
    uint256 private constant TOLERANCE = 10**18 + 10**16;

    event UnwrapFailed(address to, uint256 amount);

    struct Data {
        mapping(address => uint256) totalShares;
        address weth;
    }

    function sharesToAmount(
        Data storage data,
        address token,
        uint256 share,
        uint256 amountLimit,
        address refundTo
    ) external returns (uint256) {
        if (share == 0) {
            return 0;
        }
        if (token == data.weth) {
            return share;
        }

        uint256 totalTokenShares = data.totalShares[token];
        require(totalTokenShares >= share, 'TS3A');
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 value = balance.mul(share).div(totalTokenShares);
        data.totalShares[token] = totalTokenShares.sub(share);

        if (amountLimit > 0) {
            uint256 amountLimitWithTolerance = amountLimit.mul(TOLERANCE).div(PRECISION);
            if (value > amountLimitWithTolerance) {
                TransferHelper.safeTransfer(token, refundTo, value.sub(amountLimitWithTolerance));
                return amountLimitWithTolerance;
            }
        }

        return value;
    }

    function amountToShares(
        Data storage data,
        address token,
        uint256 amount,
        bool wrap
    ) external returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        if (token == data.weth) {
            if (wrap) {
                require(msg.value >= amount, 'TS03');
                IWETH(token).deposit{ value: amount }();
            } else {
                token.safeTransferFrom(msg.sender, address(this), amount);
            }
            return amount;
        } else {
            uint256 balanceBefore = IERC20(token).balanceOf(address(this));
            uint256 totalTokenShares = data.totalShares[token];
            require(balanceBefore > 0 || totalTokenShares == 0, 'TS30');
            if (totalTokenShares == 0) {
                totalTokenShares = balanceBefore;
            }
            token.safeTransferFrom(msg.sender, address(this), amount);
            uint256 balanceAfter = IERC20(token).balanceOf(address(this));
            require(balanceAfter > balanceBefore, 'TS2C');
            if (balanceBefore > 0) {
                uint256 newShares = totalTokenShares.mul(balanceAfter).div(balanceBefore);
                data.totalShares[token] = newShares;
                return newShares - totalTokenShares;
            } else {
                data.totalShares[token] = balanceAfter;
                return balanceAfter;
            }
        }
    }

    function onUnwrapFailed(
        Data storage data,
        address to,
        uint256 amount
    ) external {
        emit UnwrapFailed(to, amount);
        IWETH(data.weth).deposit{ value: amount }();
        TransferHelper.safeTransfer(data.weth, to, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

import './ITwapERC20.sol';
import './IReserves.sol';

interface ITwapPair is ITwapERC20, IReserves {
    event Mint(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 liquidityOut, address indexed to);
    event Burn(address indexed sender, uint256 amount0Out, uint256 amount1Out, uint256 liquidityIn, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event SetMintFee(uint256 fee);
    event SetBurnFee(uint256 fee);
    event SetSwapFee(uint256 fee);
    event SetOracle(address account);
    event SetTrader(address trader);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function oracle() external view returns (address);

    function trader() external view returns (address);

    function mintFee() external view returns (uint256);

    function setMintFee(uint256 fee) external;

    function mint(address to) external returns (uint256 liquidity);

    function burnFee() external view returns (uint256);

    function setBurnFee(uint256 fee) external;

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swapFee() external view returns (uint256);

    function setSwapFee(uint256 fee) external;

    function setOracle(address account) external;

    function setTrader(address account) external;

    function collect(address to) external;

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function sync() external;

    function initialize(
        address _token0,
        address _token1,
        address _oracle,
        address _trader
    ) external;

    function getSwapAmount0In(uint256 amount1Out, bytes calldata data) external view returns (uint256 swapAmount0In);

    function getSwapAmount1In(uint256 amount0Out, bytes calldata data) external view returns (uint256 swapAmount1In);

    function getSwapAmount0Out(uint256 amount1In, bytes calldata data) external view returns (uint256 swapAmount0Out);

    function getSwapAmount1Out(uint256 amount0In, bytes calldata data) external view returns (uint256 swapAmount1Out);

    function getDepositAmount0In(uint256 amount0, bytes calldata data) external view returns (uint256 depositAmount0In);

    function getDepositAmount1In(uint256 amount1, bytes calldata data) external view returns (uint256 depositAmount1In);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;
pragma abicoder v2;

import './SafeMath.sol';
import '../libraries/Math.sol';
import '../interfaces/ITwapFactory.sol';
import '../interfaces/ITwapPair.sol';
import '../interfaces/ITwapOracle.sol';
import '../libraries/TokenShares.sol';

library Orders {
    using SafeMath for uint256;
    using TokenShares for TokenShares.Data;
    using TransferHelper for address;

    enum OrderType {
        Empty,
        Deposit,
        Withdraw,
        Sell,
        Buy
    }
    enum OrderStatus {
        NonExistent,
        EnqueuedWaiting,
        EnqueuedReady,
        ExecutedSucceeded,
        ExecutedFailed,
        Canceled
    }

    event MaxGasLimitSet(uint256 maxGasLimit);
    event GasPriceInertiaSet(uint256 gasPriceInertia);
    event MaxGasPriceImpactSet(uint256 maxGasPriceImpact);
    event TransferGasCostSet(address token, uint256 gasCost);

    event DepositEnqueued(uint256 indexed orderId, uint32 validAfterTimestamp, uint256 gasPrice);
    event WithdrawEnqueued(uint256 indexed orderId, uint32 validAfterTimestamp, uint256 gasPrice);
    event SellEnqueued(uint256 indexed orderId, uint32 validAfterTimestamp, uint256 gasPrice);
    event BuyEnqueued(uint256 indexed orderId, uint32 validAfterTimestamp, uint256 gasPrice);

    event OrderDisabled(address pair, Orders.OrderType orderType, bool disabled);

    event RefundFailed(address indexed to, address indexed token, uint256 amount, bytes data);

    uint8 private constant DEPOSIT_TYPE = 1;
    uint8 private constant WITHDRAW_TYPE = 2;
    uint8 private constant BUY_TYPE = 3;
    uint8 private constant BUY_INVERTED_TYPE = 4;
    uint8 private constant SELL_TYPE = 5;
    uint8 private constant SELL_INVERTED_TYPE = 6;

    uint8 private constant UNWRAP_NOT_FAILED = 0;
    uint8 private constant KEEP_NOT_FAILED = 1;
    uint8 private constant UNWRAP_FAILED = 2;
    uint8 private constant KEEP_FAILED = 3;

    uint256 private constant ETHER_TRANSFER_COST = 2600 + 1504; // EIP-2929 acct access cost + Gnosis Safe receive ETH cost
    uint256 private constant BUFFER_COST = 10000;
    uint256 private constant ORDER_EXECUTED_EVENT_COST = 3700;
    uint256 private constant EXECUTE_PREPARATION_COST = 55000; // dequeue + getPair in execute

    uint256 public constant ETHER_TRANSFER_CALL_COST = 10000;
    uint256 public constant PAIR_TRANSFER_COST = 55000;
    uint256 public constant REFUND_BASE_COST = 2 * ETHER_TRANSFER_COST + BUFFER_COST + ORDER_EXECUTED_EVENT_COST;
    uint256 public constant ORDER_BASE_COST = EXECUTE_PREPARATION_COST + REFUND_BASE_COST;

    // Masks used for setting order disabled
    // Different bits represent different order types
    uint8 private constant DEPOSIT_MASK = uint8(1 << uint8(OrderType.Deposit)); //   00000010
    uint8 private constant WITHDRAW_MASK = uint8(1 << uint8(OrderType.Withdraw)); // 00000100
    uint8 private constant SELL_MASK = uint8(1 << uint8(OrderType.Sell)); //         00001000
    uint8 private constant BUY_MASK = uint8(1 << uint8(OrderType.Buy)); //           00010000

    struct PairInfo {
        address pair;
        address token0;
        address token1;
    }

    struct Data {
        uint32 delay;
        uint256 newestOrderId;
        uint256 lastProcessedOrderId;
        mapping(uint256 => StoredOrder) orderQueue;
        address factory;
        uint256 maxGasLimit;
        uint256 gasPrice;
        uint256 gasPriceInertia;
        uint256 maxGasPriceImpact;
        mapping(uint32 => PairInfo) pairs;
        mapping(address => uint256) transferGasCosts;
        mapping(uint256 => bool) canceled;
        // Bit on specific positions indicates whether order type is disabled (1) or enabled (0) on specific pair
        mapping(address => uint8) orderDisabled;
    }

    struct StoredOrder {
        // slot 0
        uint8 orderType;
        uint32 validAfterTimestamp;
        uint8 unwrapAndFailure;
        uint32 timestamp;
        uint32 gasLimit;
        uint32 gasPrice;
        uint112 liquidity;
        // slot 1
        uint112 value0;
        uint112 value1;
        uint32 pairId;
        // slot2
        address to;
        uint32 minSwapPrice;
        uint32 maxSwapPrice;
        bool swap;
        // slot3
        uint256 priceAccumulator;
        // slot4
        uint112 amountLimit0;
        uint112 amountLimit1;
    }

    struct DepositOrder {
        uint32 pairId;
        uint256 share0;
        uint256 share1;
        uint256 minSwapPrice;
        uint256 maxSwapPrice;
        bool unwrap;
        bool swap;
        address to;
        uint256 gasPrice;
        uint256 gasLimit;
        uint32 validAfterTimestamp;
        uint256 priceAccumulator;
        uint32 timestamp;
    }

    struct WithdrawOrder {
        uint32 pairId;
        uint256 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        bool unwrap;
        address to;
        uint256 gasPrice;
        uint256 gasLimit;
        uint32 validAfterTimestamp;
    }

    struct SellOrder {
        uint32 pairId;
        bool inverse;
        uint256 shareIn;
        uint256 amountOutMin;
        bool unwrap;
        address to;
        uint256 gasPrice;
        uint256 gasLimit;
        uint32 validAfterTimestamp;
        uint256 priceAccumulator;
        uint32 timestamp;
    }

    struct BuyOrder {
        uint32 pairId;
        bool inverse;
        uint256 shareInMax;
        uint256 amountOut;
        bool unwrap;
        address to;
        uint256 gasPrice;
        uint256 gasLimit;
        uint32 validAfterTimestamp;
        uint256 priceAccumulator;
        uint32 timestamp;
    }

    function decodeType(uint256 internalType) internal pure returns (OrderType orderType) {
        if (internalType == DEPOSIT_TYPE) {
            orderType = OrderType.Deposit;
        } else if (internalType == WITHDRAW_TYPE) {
            orderType = OrderType.Withdraw;
        } else if (internalType == BUY_TYPE) {
            orderType = OrderType.Buy;
        } else if (internalType == BUY_INVERTED_TYPE) {
            orderType = OrderType.Buy;
        } else if (internalType == SELL_TYPE) {
            orderType = OrderType.Sell;
        } else if (internalType == SELL_INVERTED_TYPE) {
            orderType = OrderType.Sell;
        } else {
            orderType = OrderType.Empty;
        }
    }

    function getOrder(Data storage data, uint256 orderId)
        internal
        view
        returns (OrderType orderType, uint32 validAfterTimestamp)
    {
        StoredOrder storage order = data.orderQueue[orderId];
        validAfterTimestamp = order.validAfterTimestamp;
        orderType = decodeType(order.orderType);
    }

    function getOrderStatus(Data storage data, uint256 orderId) internal view returns (OrderStatus orderStatus) {
        if (orderId > data.newestOrderId) {
            return OrderStatus.NonExistent;
        }
        if (data.canceled[orderId]) {
            return OrderStatus.Canceled;
        }
        if (isRefundFailed(data, orderId)) {
            return OrderStatus.ExecutedFailed;
        }
        (OrderType orderType, uint32 validAfterTimestamp) = getOrder(data, orderId);
        if (orderType == OrderType.Empty) {
            return OrderStatus.ExecutedSucceeded;
        }
        if (validAfterTimestamp >= block.timestamp) {
            return OrderStatus.EnqueuedWaiting;
        }
        return OrderStatus.EnqueuedReady;
    }

    function getPair(
        Data storage data,
        address tokenA,
        address tokenB
    )
        internal
        returns (
            address pair,
            uint32 pairId,
            bool inverted
        )
    {
        inverted = tokenA > tokenB;
        (address token0, address token1) = inverted ? (tokenB, tokenA) : (tokenA, tokenB);
        pair = ITwapFactory(data.factory).getPair(token0, token1);
        require(pair != address(0), 'OS17');
        pairId = uint32(bytes4(keccak256(abi.encodePacked(pair))));
        if (data.pairs[pairId].pair == address(0)) {
            data.pairs[pairId] = PairInfo(pair, token0, token1);
        }
    }

    function getPairInfo(Data storage data, uint32 pairId)
        internal
        view
        returns (
            address pair,
            address token0,
            address token1
        )
    {
        PairInfo storage info = data.pairs[pairId];
        pair = info.pair;
        token0 = info.token0;
        token1 = info.token1;
    }

    function getDepositDisabled(Data storage data, address pair) internal view returns (bool) {
        return data.orderDisabled[pair] & DEPOSIT_MASK != 0;
    }

    function getWithdrawDisabled(Data storage data, address pair) internal view returns (bool) {
        return data.orderDisabled[pair] & WITHDRAW_MASK != 0;
    }

    function getSellDisabled(Data storage data, address pair) internal view returns (bool) {
        return data.orderDisabled[pair] & SELL_MASK != 0;
    }

    function getBuyDisabled(Data storage data, address pair) internal view returns (bool) {
        return data.orderDisabled[pair] & BUY_MASK != 0;
    }

    function getDepositOrder(Data storage data, uint256 index)
        public
        view
        returns (
            DepositOrder memory order,
            uint256 amountLimit0,
            uint256 amountLimit1
        )
    {
        StoredOrder memory stored = data.orderQueue[index];
        require(stored.orderType == DEPOSIT_TYPE, 'OS32');
        order.pairId = stored.pairId;
        order.share0 = stored.value0;
        order.share1 = stored.value1;
        order.minSwapPrice = float32ToUint(stored.minSwapPrice);
        order.maxSwapPrice = float32ToUint(stored.maxSwapPrice);
        order.unwrap = getUnwrap(stored.unwrapAndFailure);
        order.swap = stored.swap;
        order.to = stored.to;
        order.gasPrice = uint32ToGasPrice(stored.gasPrice);
        order.gasLimit = stored.gasLimit;
        order.validAfterTimestamp = stored.validAfterTimestamp;
        order.priceAccumulator = stored.priceAccumulator;
        order.timestamp = stored.timestamp;

        amountLimit0 = stored.amountLimit0;
        amountLimit1 = stored.amountLimit1;
    }

    function getWithdrawOrder(Data storage data, uint256 index) public view returns (WithdrawOrder memory order) {
        StoredOrder memory stored = data.orderQueue[index];
        require(stored.orderType == WITHDRAW_TYPE, 'OS32');
        order.pairId = stored.pairId;
        order.liquidity = stored.liquidity;
        order.amount0Min = stored.value0;
        order.amount1Min = stored.value1;
        order.unwrap = getUnwrap(stored.unwrapAndFailure);
        order.to = stored.to;
        order.gasPrice = uint32ToGasPrice(stored.gasPrice);
        order.gasLimit = stored.gasLimit;
        order.validAfterTimestamp = stored.validAfterTimestamp;
    }

    function getSellOrder(Data storage data, uint256 index)
        public
        view
        returns (SellOrder memory order, uint256 amountLimit)
    {
        StoredOrder memory stored = data.orderQueue[index];
        require(stored.orderType == SELL_TYPE || stored.orderType == SELL_INVERTED_TYPE, 'OS32');
        order.pairId = stored.pairId;
        order.inverse = stored.orderType == SELL_INVERTED_TYPE;
        order.shareIn = stored.value0;
        order.amountOutMin = stored.value1;
        order.unwrap = getUnwrap(stored.unwrapAndFailure);
        order.to = stored.to;
        order.gasPrice = uint32ToGasPrice(stored.gasPrice);
        order.gasLimit = stored.gasLimit;
        order.validAfterTimestamp = stored.validAfterTimestamp;
        order.priceAccumulator = stored.priceAccumulator;
        order.timestamp = stored.timestamp;

        amountLimit = stored.amountLimit0;
    }

    function getBuyOrder(Data storage data, uint256 index)
        public
        view
        returns (BuyOrder memory order, uint256 amountLimit)
    {
        StoredOrder memory stored = data.orderQueue[index];
        require(stored.orderType == BUY_TYPE || stored.orderType == BUY_INVERTED_TYPE, 'OS32');
        order.pairId = stored.pairId;
        order.inverse = stored.orderType == BUY_INVERTED_TYPE;
        order.shareInMax = stored.value0;
        order.amountOut = stored.value1;
        order.unwrap = getUnwrap(stored.unwrapAndFailure);
        order.to = stored.to;
        order.gasPrice = uint32ToGasPrice(stored.gasPrice);
        order.gasLimit = stored.gasLimit;
        order.validAfterTimestamp = stored.validAfterTimestamp;
        order.timestamp = stored.timestamp;
        order.priceAccumulator = stored.priceAccumulator;

        amountLimit = stored.amountLimit0;
    }

    function getFailedOrderType(Data storage data, uint256 orderId)
        internal
        view
        returns (OrderType orderType, uint32 validAfterTimestamp)
    {
        require(isRefundFailed(data, orderId), 'OS21');
        (orderType, validAfterTimestamp) = getOrder(data, orderId);
    }

    function getUnwrap(uint8 unwrapAndFailure) private pure returns (bool) {
        return unwrapAndFailure == UNWRAP_FAILED || unwrapAndFailure == UNWRAP_NOT_FAILED;
    }

    function getUnwrapAndFailure(bool unwrap) private pure returns (uint8) {
        return unwrap ? UNWRAP_NOT_FAILED : KEEP_NOT_FAILED;
    }

    function timestampToUint32(uint256 timestamp) private pure returns (uint32 timestamp32) {
        if (timestamp == type(uint256).max) {
            return type(uint32).max;
        }
        timestamp32 = timestamp.toUint32();
    }

    function gasPriceToUint32(uint256 gasPrice) private pure returns (uint32 gasPrice32) {
        require((gasPrice / 1e6) * 1e6 == gasPrice, 'OS3C');
        gasPrice32 = (gasPrice / 1e6).toUint32();
    }

    function uint32ToGasPrice(uint32 gasPrice32) public pure returns (uint256 gasPrice) {
        gasPrice = uint256(gasPrice32) * 1e6;
    }

    function uintToFloat32(uint256 number) internal pure returns (uint32 float32) {
        // Number is encoded on 4 bytes. 3 bytes for mantissa and 1 for exponent.
        // If the number fits in the mantissa we set the exponent to zero and return.
        if (number < 1 << 24) {
            return uint32(number << 8);
        }
        // We find the exponent by counting the number of trailing zeroes.
        // Simultaneously we remove those zeroes from the number.
        uint32 exponent;
        for (; exponent < 256 - 24; ++exponent) {
            // Last bit is one.
            if (number & 1 == 1) {
                break;
            }
            number = number >> 1;
        }
        // The number must fit in the mantissa.
        require(number < 1 << 24, 'OS1A');
        // Set the first three bytes to the number and the fourth to the exponent.
        float32 = uint32(number << 8) | exponent;
    }

    function float32ToUint(uint32 float32) internal pure returns (uint256 number) {
        // Number is encoded on 4 bytes. 3 bytes for mantissa and 1 for exponent.
        // We get the exponent by extracting the last byte.
        uint256 exponent = float32 & 0xFF;
        // Sanity check. Only triggered for values not encoded with uintToFloat32.
        require(exponent <= 256 - 24, 'OS1B');
        // We get the mantissa by extracting the first three bytes and removing the fourth.
        uint256 mantissa = (float32 & 0xFFFFFF00) >> 8;
        // We add exponent number zeroes after the mantissa.
        number = mantissa << exponent;
    }

    function setOrderDisabled(
        Data storage data,
        address pair,
        Orders.OrderType orderType,
        bool disabled
    ) external {
        require(orderType != Orders.OrderType.Empty, 'OS32');
        uint8 currentSettings = data.orderDisabled[pair];

        // zeros with 1 bit set at position specified by orderType
        uint8 mask = uint8(1 << uint8(orderType));

        // set/unset a bit accordingly to 'disabled' value
        if (disabled) {
            // OR operation to disable order
            // e.g. for disable DEPOSIT
            // currentSettings   = 00010100 (BUY and WITHDRAW disabled)
            // mask for DEPOSIT  = 00000010
            // the result of OR  = 00010110
            currentSettings = currentSettings | mask;
        } else {
            // AND operation with a mask negation to enable order
            // e.g. for enable DEPOSIT
            // currentSettings   = 00010100 (BUY and WITHDRAW disabled)
            // 0xff              = 11111111
            // mask for Deposit  = 00000010
            // mask negation     = 11111101
            // the result of AND = 00010100
            currentSettings = currentSettings & (mask ^ 0xff);
        }
        require(currentSettings != data.orderDisabled[pair], 'OS01');
        data.orderDisabled[pair] = currentSettings;

        emit OrderDisabled(pair, orderType, disabled);
    }

    function enqueueDepositOrder(
        Data storage data,
        DepositOrder memory depositOrder,
        uint256 amountIn0,
        uint256 amountIn1
    ) internal {
        ++data.newestOrderId;
        emit DepositEnqueued(data.newestOrderId, depositOrder.validAfterTimestamp, depositOrder.gasPrice);
        data.orderQueue[data.newestOrderId] = StoredOrder(
            DEPOSIT_TYPE,
            depositOrder.validAfterTimestamp,
            getUnwrapAndFailure(depositOrder.unwrap),
            depositOrder.timestamp,
            depositOrder.gasLimit.toUint32(),
            gasPriceToUint32(depositOrder.gasPrice),
            0, // liquidity
            depositOrder.share0.toUint112(),
            depositOrder.share1.toUint112(),
            depositOrder.pairId,
            depositOrder.to,
            uintToFloat32(depositOrder.minSwapPrice),
            uintToFloat32(depositOrder.maxSwapPrice),
            depositOrder.swap,
            depositOrder.priceAccumulator,
            amountIn0.toUint112(),
            amountIn1.toUint112()
        );
    }

    function enqueueWithdrawOrder(Data storage data, WithdrawOrder memory withdrawOrder) internal {
        ++data.newestOrderId;
        emit WithdrawEnqueued(data.newestOrderId, withdrawOrder.validAfterTimestamp, withdrawOrder.gasPrice);
        data.orderQueue[data.newestOrderId] = StoredOrder(
            WITHDRAW_TYPE,
            withdrawOrder.validAfterTimestamp,
            getUnwrapAndFailure(withdrawOrder.unwrap),
            0, // timestamp
            withdrawOrder.gasLimit.toUint32(),
            gasPriceToUint32(withdrawOrder.gasPrice),
            withdrawOrder.liquidity.toUint112(),
            withdrawOrder.amount0Min.toUint112(),
            withdrawOrder.amount1Min.toUint112(),
            withdrawOrder.pairId,
            withdrawOrder.to,
            0, // minSwapPrice
            0, // maxSwapPrice
            false, // swap
            0, // priceAccumulator
            0, // amountLimit0
            0 // amountLimit1
        );
    }

    function enqueueSellOrder(
        Data storage data,
        SellOrder memory sellOrder,
        uint256 amountIn
    ) internal {
        ++data.newestOrderId;
        emit SellEnqueued(data.newestOrderId, sellOrder.validAfterTimestamp, sellOrder.gasPrice);
        data.orderQueue[data.newestOrderId] = StoredOrder(
            sellOrder.inverse ? SELL_INVERTED_TYPE : SELL_TYPE,
            sellOrder.validAfterTimestamp,
            getUnwrapAndFailure(sellOrder.unwrap),
            sellOrder.timestamp,
            sellOrder.gasLimit.toUint32(),
            gasPriceToUint32(sellOrder.gasPrice),
            0, // liquidity
            sellOrder.shareIn.toUint112(),
            sellOrder.amountOutMin.toUint112(),
            sellOrder.pairId,
            sellOrder.to,
            0, // minSwapPrice
            0, // maxSwapPrice
            false, // swap
            sellOrder.priceAccumulator,
            amountIn.toUint112(),
            0 // amountLimit1
        );
    }

    function enqueueBuyOrder(
        Data storage data,
        BuyOrder memory buyOrder,
        uint256 amountInMax
    ) internal {
        ++data.newestOrderId;
        emit BuyEnqueued(data.newestOrderId, buyOrder.validAfterTimestamp, buyOrder.gasPrice);
        data.orderQueue[data.newestOrderId] = StoredOrder(
            buyOrder.inverse ? BUY_INVERTED_TYPE : BUY_TYPE,
            buyOrder.validAfterTimestamp,
            getUnwrapAndFailure(buyOrder.unwrap),
            buyOrder.timestamp,
            buyOrder.gasLimit.toUint32(),
            gasPriceToUint32(buyOrder.gasPrice),
            0, // liquidity
            buyOrder.shareInMax.toUint112(),
            buyOrder.amountOut.toUint112(),
            buyOrder.pairId,
            buyOrder.to,
            0, // minSwapPrice
            0, // maxSwapPrice
            false, // swap
            buyOrder.priceAccumulator,
            amountInMax.toUint112(),
            0 // amountLimit1
        );
    }

    function isRefundFailed(Data storage data, uint256 index) internal view returns (bool) {
        uint8 unwrapAndFailure = data.orderQueue[index].unwrapAndFailure;
        return unwrapAndFailure == UNWRAP_FAILED || unwrapAndFailure == KEEP_FAILED;
    }

    function markRefundFailed(Data storage data) internal {
        StoredOrder storage stored = data.orderQueue[data.lastProcessedOrderId];
        stored.unwrapAndFailure = stored.unwrapAndFailure == UNWRAP_NOT_FAILED ? UNWRAP_FAILED : KEEP_FAILED;
    }

    struct DepositParams {
        address token0;
        address token1;
        uint256 amount0;
        uint256 amount1;
        uint256 minSwapPrice;
        uint256 maxSwapPrice;
        bool wrap;
        bool swap;
        address to;
        uint256 gasLimit;
        uint32 submitDeadline;
    }

    function deposit(
        Data storage data,
        DepositParams calldata depositParams,
        TokenShares.Data storage tokenShares
    ) external {
        {
            // scope for checks, avoids stack too deep errors
            uint256 token0TransferCost = data.transferGasCosts[depositParams.token0];
            uint256 token1TransferCost = data.transferGasCosts[depositParams.token1];
            require(token0TransferCost != 0 && token1TransferCost != 0, 'OS0F');
            checkOrderParams(
                data,
                depositParams.to,
                depositParams.gasLimit,
                depositParams.submitDeadline,
                ORDER_BASE_COST.add(token0TransferCost).add(token1TransferCost)
            );
        }
        require(depositParams.amount0 != 0 || depositParams.amount1 != 0, 'OS25');
        (address pairAddress, uint32 pairId, bool inverted) = getPair(data, depositParams.token0, depositParams.token1);
        require(!getDepositDisabled(data, pairAddress), 'OS46');
        {
            // scope for value, avoids stack too deep errors
            uint256 value = msg.value;

            // allocate gas refund
            if (depositParams.wrap) {
                if (depositParams.token0 == tokenShares.weth) {
                    value = msg.value.sub(depositParams.amount0, 'OS1E');
                } else if (depositParams.token1 == tokenShares.weth) {
                    value = msg.value.sub(depositParams.amount1, 'OS1E');
                }
            }
            allocateGasRefund(data, value, depositParams.gasLimit);
        }

        uint256 shares0 = tokenShares.amountToShares(
            inverted ? depositParams.token1 : depositParams.token0,
            inverted ? depositParams.amount1 : depositParams.amount0,
            depositParams.wrap
        );
        uint256 shares1 = tokenShares.amountToShares(
            inverted ? depositParams.token0 : depositParams.token1,
            inverted ? depositParams.amount0 : depositParams.amount1,
            depositParams.wrap
        );

        (uint256 priceAccumulator, uint32 timestamp) = ITwapOracle(ITwapPair(pairAddress).oracle()).getPriceInfo();
        enqueueDepositOrder(
            data,
            DepositOrder(
                pairId,
                shares0,
                shares1,
                depositParams.minSwapPrice,
                depositParams.maxSwapPrice,
                depositParams.wrap,
                depositParams.swap,
                depositParams.to,
                data.gasPrice,
                depositParams.gasLimit,
                timestamp + data.delay, // validAfterTimestamp
                priceAccumulator,
                timestamp
            ),
            inverted ? depositParams.amount1 : depositParams.amount0,
            inverted ? depositParams.amount0 : depositParams.amount1
        );
    }

    struct WithdrawParams {
        address token0;
        address token1;
        uint256 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        bool unwrap;
        address to;
        uint256 gasLimit;
        uint32 submitDeadline;
    }

    function withdraw(Data storage data, WithdrawParams calldata withdrawParams) external {
        (address pair, uint32 pairId, bool inverted) = getPair(data, withdrawParams.token0, withdrawParams.token1);
        require(!getWithdrawDisabled(data, pair), 'OS0A');
        checkOrderParams(
            data,
            withdrawParams.to,
            withdrawParams.gasLimit,
            withdrawParams.submitDeadline,
            ORDER_BASE_COST.add(PAIR_TRANSFER_COST)
        );
        require(withdrawParams.liquidity != 0, 'OS22');

        allocateGasRefund(data, msg.value, withdrawParams.gasLimit);
        pair.safeTransferFrom(msg.sender, address(this), withdrawParams.liquidity);
        enqueueWithdrawOrder(
            data,
            WithdrawOrder(
                pairId,
                withdrawParams.liquidity,
                inverted ? withdrawParams.amount1Min : withdrawParams.amount0Min,
                inverted ? withdrawParams.amount0Min : withdrawParams.amount1Min,
                withdrawParams.unwrap,
                withdrawParams.to,
                data.gasPrice,
                withdrawParams.gasLimit,
                timestampToUint32(block.timestamp) + data.delay
            )
        );
    }

    struct SellParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMin;
        bool wrapUnwrap;
        address to;
        uint256 gasLimit;
        uint32 submitDeadline;
    }

    function sell(
        Data storage data,
        SellParams calldata sellParams,
        TokenShares.Data storage tokenShares
    ) external {
        uint256 tokenTransferCost = data.transferGasCosts[sellParams.tokenIn];
        require(tokenTransferCost != 0, 'OS0F');
        checkOrderParams(
            data,
            sellParams.to,
            sellParams.gasLimit,
            sellParams.submitDeadline,
            ORDER_BASE_COST.add(tokenTransferCost)
        );
        require(sellParams.amountIn != 0, 'OS24');
        (address pairAddress, uint32 pairId, bool inverted) = getPair(data, sellParams.tokenIn, sellParams.tokenOut);
        require(!getSellDisabled(data, pairAddress), 'OS13');
        uint256 value = msg.value;

        // allocate gas refund
        if (sellParams.tokenIn == tokenShares.weth && sellParams.wrapUnwrap) {
            value = msg.value.sub(sellParams.amountIn, 'OS1E');
        }

        allocateGasRefund(data, value, sellParams.gasLimit);

        uint256 shares = tokenShares.amountToShares(sellParams.tokenIn, sellParams.amountIn, sellParams.wrapUnwrap);

        (uint256 priceAccumulator, uint32 timestamp) = ITwapOracle(ITwapPair(pairAddress).oracle()).getPriceInfo();
        enqueueSellOrder(
            data,
            SellOrder(
                pairId,
                inverted,
                shares,
                sellParams.amountOutMin,
                sellParams.wrapUnwrap,
                sellParams.to,
                data.gasPrice,
                sellParams.gasLimit,
                timestamp + data.delay,
                priceAccumulator,
                timestamp
            ),
            sellParams.amountIn
        );
    }

    struct BuyParams {
        address tokenIn;
        address tokenOut;
        uint256 amountInMax;
        uint256 amountOut;
        bool wrapUnwrap;
        address to;
        uint256 gasLimit;
        uint32 submitDeadline;
    }

    function buy(
        Data storage data,
        BuyParams calldata buyParams,
        TokenShares.Data storage tokenShares
    ) external {
        uint256 tokenTransferCost = data.transferGasCosts[buyParams.tokenIn];
        require(tokenTransferCost != 0, 'OS0F');
        checkOrderParams(
            data,
            buyParams.to,
            buyParams.gasLimit,
            buyParams.submitDeadline,
            ORDER_BASE_COST.add(tokenTransferCost)
        );
        require(buyParams.amountOut != 0, 'OS23');
        (address pairAddress, uint32 pairId, bool inverted) = getPair(data, buyParams.tokenIn, buyParams.tokenOut);
        require(!getBuyDisabled(data, pairAddress), 'OS49');
        uint256 value = msg.value;

        // allocate gas refund
        if (buyParams.tokenIn == tokenShares.weth && buyParams.wrapUnwrap) {
            value = msg.value.sub(buyParams.amountInMax, 'OS1E');
        }

        allocateGasRefund(data, value, buyParams.gasLimit);

        uint256 shares = tokenShares.amountToShares(buyParams.tokenIn, buyParams.amountInMax, buyParams.wrapUnwrap);

        (uint256 priceAccumulator, uint32 timestamp) = ITwapOracle(ITwapPair(pairAddress).oracle()).getPriceInfo();
        enqueueBuyOrder(
            data,
            BuyOrder(
                pairId,
                inverted,
                shares,
                buyParams.amountOut,
                buyParams.wrapUnwrap,
                buyParams.to,
                data.gasPrice,
                buyParams.gasLimit,
                timestamp + data.delay,
                priceAccumulator,
                timestamp
            ),
            buyParams.amountInMax
        );
    }

    function checkOrderParams(
        Data storage data,
        address to,
        uint256 gasLimit,
        uint32 submitDeadline,
        uint256 minGasLimit
    ) private view {
        require(submitDeadline >= block.timestamp, 'OS04');
        require(gasLimit <= data.maxGasLimit, 'OS3E');
        require(gasLimit >= minGasLimit, 'OS3D');
        require(to != address(0), 'OS26');
    }

    function allocateGasRefund(
        Data storage data,
        uint256 value,
        uint256 gasLimit
    ) private returns (uint256 futureFee) {
        futureFee = data.gasPrice.mul(gasLimit);
        require(value >= futureFee, 'OS1E');
        if (value > futureFee) {
            TransferHelper.safeTransferETH(msg.sender, value.sub(futureFee), data.transferGasCosts[address(0)]);
        }
    }

    function updateGasPrice(Data storage data, uint256 gasUsed) external {
        uint256 scale = Math.min(gasUsed, data.maxGasPriceImpact);
        uint256 updated = data.gasPrice.mul(data.gasPriceInertia.sub(scale)).add(tx.gasprice.mul(scale)).div(
            data.gasPriceInertia
        );
        // we lower the precision for gas savings in order queue
        data.gasPrice = updated - (updated % 1e6);
    }

    function setMaxGasLimit(Data storage data, uint256 _maxGasLimit) external {
        require(_maxGasLimit != data.maxGasLimit, 'OS01');
        require(_maxGasLimit <= 10000000, 'OS2B');
        data.maxGasLimit = _maxGasLimit;
        emit MaxGasLimitSet(_maxGasLimit);
    }

    function setGasPriceInertia(Data storage data, uint256 _gasPriceInertia) external {
        require(_gasPriceInertia != data.gasPriceInertia, 'OS01');
        require(_gasPriceInertia >= 1, 'OS35');
        data.gasPriceInertia = _gasPriceInertia;
        emit GasPriceInertiaSet(_gasPriceInertia);
    }

    function setMaxGasPriceImpact(Data storage data, uint256 _maxGasPriceImpact) external {
        require(_maxGasPriceImpact != data.maxGasPriceImpact, 'OS01');
        require(_maxGasPriceImpact <= data.gasPriceInertia, 'OS33');
        data.maxGasPriceImpact = _maxGasPriceImpact;
        emit MaxGasPriceImpactSet(_maxGasPriceImpact);
    }

    function setTransferGasCost(
        Data storage data,
        address token,
        uint256 gasCost
    ) external {
        require(gasCost != data.transferGasCosts[token], 'OS01');
        data.transferGasCosts[token] = gasCost;
        emit TransferGasCostSet(token, gasCost);
    }

    function refundLiquidity(
        address pair,
        address to,
        uint256 liquidity,
        bytes4 selector
    ) internal returns (bool) {
        if (liquidity == 0) {
            return true;
        }
        (bool success, bytes memory data) = address(this).call{ gas: PAIR_TRANSFER_COST }(
            abi.encodeWithSelector(selector, pair, to, liquidity, false)
        );
        if (!success) {
            emit RefundFailed(to, pair, liquidity, data);
        }
        return success;
    }

    function getNextOrder(Data storage data) internal view returns (OrderType orderType, uint256 validAfterTimestamp) {
        return getOrder(data, data.lastProcessedOrderId + 1);
    }

    function dequeueCanceledOrder(Data storage data) internal {
        ++data.lastProcessedOrderId;
    }

    function dequeueDepositOrder(Data storage data)
        external
        returns (
            DepositOrder memory order,
            uint256 amountLimit0,
            uint256 amountLimit1
        )
    {
        ++data.lastProcessedOrderId;
        (order, amountLimit0, amountLimit1) = getDepositOrder(data, data.lastProcessedOrderId);
    }

    function dequeueWithdrawOrder(Data storage data) external returns (WithdrawOrder memory order) {
        ++data.lastProcessedOrderId;
        order = getWithdrawOrder(data, data.lastProcessedOrderId);
    }

    function dequeueSellOrder(Data storage data) external returns (SellOrder memory order, uint256 amountLimit) {
        ++data.lastProcessedOrderId;
        (order, amountLimit) = getSellOrder(data, data.lastProcessedOrderId);
    }

    function dequeueBuyOrder(Data storage data) external returns (BuyOrder memory order, uint256 amountLimit) {
        ++data.lastProcessedOrderId;
        (order, amountLimit) = getBuyOrder(data, data.lastProcessedOrderId);
    }

    function forgetOrder(Data storage data, uint256 orderId) internal {
        delete data.orderQueue[orderId];
    }

    function forgetLastProcessedOrder(Data storage data) internal {
        delete data.orderQueue[data.lastProcessedOrderId];
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    int256 private constant _INT256_MIN = -2**255;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'SM4E');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = sub(x, y, 'SM12');
    }

    function sub(
        uint256 x,
        uint256 y,
        string memory message
    ) internal pure returns (uint256 z) {
        require((z = x - y) <= x, message);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'SM2A');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SM43');
        return a / b;
    }

    function ceil_div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = div(a, b);
        if (a != mul(b, c)) {
            return add(c, 1);
        }
    }

    function toUint32(uint256 n) internal pure returns (uint32) {
        require(n <= type(uint32).max, 'SM50');
        return uint32(n);
    }

    function toUint112(uint256 n) internal pure returns (uint112) {
        require(n <= type(uint112).max, 'SM51');
        return uint112(n);
    }

    function toInt256(uint256 unsigned) internal pure returns (int256 signed) {
        require(unsigned <= uint256(type(int256).max), 'SM34');
        signed = int256(unsigned);
    }

    // int256

    function add(int256 a, int256 b) internal pure returns (int256 c) {
        c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), 'SM4D');
    }

    function sub(int256 a, int256 b) internal pure returns (int256 c) {
        c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), 'SM11');
    }

    function mul(int256 a, int256 b) internal pure returns (int256 c) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), 'SM29');

        c = a * b;
        require(c / a == b, 'SM29');
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, 'SM43');
        require(!(b == -1 && a == _INT256_MIN), 'SM42');

        return a / b;
    }

    function neg_floor_div(int256 a, int256 b) internal pure returns (int256 c) {
        c = div(a, b);
        if ((a < 0 && b > 0) || (a >= 0 && b < 0)) {
            if (a != mul(b, c)) {
                c = sub(c, 1);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

import './TransferHelper.sol';
import './SafeMath.sol';
import './Math.sol';
import '../interfaces/ITwapPair.sol';
import '../interfaces/ITwapOracle.sol';

library AddLiquidity {
    using SafeMath for uint256;

    function addLiquidity(
        address pair,
        uint256 amount0Desired,
        uint256 amount1Desired
    )
        internal
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 swapToken
        )
    {
        if (amount0Desired == 0 || amount1Desired == 0) {
            if (amount0Desired > 0) {
                swapToken = 1;
            } else if (amount1Desired > 0) {
                swapToken = 2;
            }
            return (0, 0, swapToken);
        }
        (uint256 reserve0, uint256 reserve1) = ITwapPair(pair).getReserves();
        if (reserve0 == 0 && reserve1 == 0) {
            (amount0, amount1) = (amount0Desired, amount1Desired);
        } else {
            require(reserve0 > 0 && reserve1 > 0, 'AL07');
            uint256 amount1Optimal = amount0Desired.mul(reserve1) / reserve0;
            if (amount1Optimal <= amount1Desired) {
                swapToken = 2;
                (amount0, amount1) = (amount0Desired, amount1Optimal);
            } else {
                uint256 amount0Optimal = amount1Desired.mul(reserve0) / reserve1;
                assert(amount0Optimal <= amount0Desired);
                swapToken = 1;
                (amount0, amount1) = (amount0Optimal, amount1Desired);
            }

            uint256 totalSupply = ITwapPair(pair).totalSupply();
            uint256 liquidityOut = Math.min(amount0.mul(totalSupply) / reserve0, amount1.mul(totalSupply) / reserve1);
            if (liquidityOut == 0) {
                amount0 = 0;
                amount1 = 0;
            }
        }
    }

    function addLiquidityAndMint(
        address pair,
        address to,
        address token0,
        address token1,
        uint256 amount0Desired,
        uint256 amount1Desired
    )
        external
        returns (
            uint256 amount0Left,
            uint256 amount1Left,
            uint256 swapToken
        )
    {
        uint256 amount0;
        uint256 amount1;
        (amount0, amount1, swapToken) = addLiquidity(pair, amount0Desired, amount1Desired);
        if (amount0 == 0 || amount1 == 0) {
            return (amount0Desired, amount1Desired, swapToken);
        }
        TransferHelper.safeTransfer(token0, pair, amount0);
        TransferHelper.safeTransfer(token1, pair, amount1);
        ITwapPair(pair).mint(to);

        amount0Left = amount0Desired.sub(amount0);
        amount1Left = amount1Desired.sub(amount1);
    }

    function swapDeposit0(
        address pair,
        address token0,
        uint256 amount0,
        uint256 minSwapPrice,
        uint16 tolerance,
        bytes calldata data
    ) external returns (uint256 amount0Left, uint256 amount1Left) {
        uint256 amount0In = ITwapPair(pair).getDepositAmount0In(amount0, data);
        amount1Left = ITwapPair(pair).getSwapAmount1Out(amount0In, data).sub(tolerance);
        if (amount1Left == 0) {
            return (amount0, amount1Left);
        }
        uint256 price = getPrice(amount0In, amount1Left, pair);
        require(minSwapPrice == 0 || price >= minSwapPrice, 'AL15');
        TransferHelper.safeTransfer(token0, pair, amount0In);
        ITwapPair(pair).swap(0, amount1Left, address(this), data);
        amount0Left = amount0.sub(amount0In);
    }

    function swapDeposit1(
        address pair,
        address token1,
        uint256 amount1,
        uint256 maxSwapPrice,
        uint16 tolerance,
        bytes calldata data
    ) external returns (uint256 amount0Left, uint256 amount1Left) {
        uint256 amount1In = ITwapPair(pair).getDepositAmount1In(amount1, data);
        amount0Left = ITwapPair(pair).getSwapAmount0Out(amount1In, data).sub(tolerance);
        if (amount0Left == 0) {
            return (amount0Left, amount1);
        }
        uint256 price = getPrice(amount0Left, amount1In, pair);
        require(maxSwapPrice == 0 || price <= maxSwapPrice, 'AL16');
        TransferHelper.safeTransfer(token1, pair, amount1In);
        ITwapPair(pair).swap(amount0Left, 0, address(this), data);
        amount1Left = amount1.sub(amount1In);
    }

    function getPrice(
        uint256 amount0,
        uint256 amount1,
        address pair
    ) internal view returns (uint256) {
        ITwapOracle oracle = ITwapOracle(ITwapPair(pair).oracle());
        return amount1.mul(uint256(oracle.decimalsConverter())).div(amount0);
    }

    function _refundDeposit(
        address to,
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    ) internal {
        if (amount0 > 0) {
            TransferHelper.safeTransfer(token0, to, amount0);
        }
        if (amount1 > 0) {
            TransferHelper.safeTransfer(token1, to, amount1);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;
pragma abicoder v2;

import '../interfaces/ITwapPair.sol';
import '../interfaces/IWETH.sol';
import './Orders.sol';

library WithdrawHelper {
    using SafeMath for uint256;

    function _transferToken(
        uint256 balanceBefore,
        address token,
        address to
    ) internal {
        uint256 tokenAmount = IERC20(token).balanceOf(address(this)).sub(balanceBefore);
        TransferHelper.safeTransfer(token, to, tokenAmount);
    }

    function _unwrapWeth(
        uint256 ethAmount,
        address weth,
        address to,
        uint256 gasLimit
    ) internal returns (bool) {
        IWETH(weth).withdraw(ethAmount);
        (bool success, ) = to.call{ value: ethAmount, gas: gasLimit }('');
        return success;
    }

    function withdrawAndUnwrap(
        address token0,
        address token1,
        address pair,
        address weth,
        address to,
        uint256 gasLimit
    )
        external
        returns (
            bool,
            uint256,
            uint256,
            uint256
        )
    {
        bool isToken0Weth = token0 == weth;
        address otherToken = isToken0Weth ? token1 : token0;

        uint256 balanceBefore = IERC20(otherToken).balanceOf(address(this));
        (uint256 amount0, uint256 amount1) = ITwapPair(pair).burn(address(this));
        _transferToken(balanceBefore, otherToken, to);

        bool success = _unwrapWeth(isToken0Weth ? amount0 : amount1, weth, to, gasLimit);

        return (success, isToken0Weth ? amount0 : amount1, amount0, amount1);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

// a library for performing various math operations

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x > y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

interface ITwapOracle {
    event OwnerSet(address owner);
    event UniswapPairSet(address uniswapPair);

    function decimalsConverter() external view returns (int256);

    function xDecimals() external view returns (uint8);

    function yDecimals() external view returns (uint8);

    function owner() external view returns (address);

    function uniswapPair() external view returns (address);

    function getPriceInfo() external view returns (uint256 priceAccumulator, uint32 priceTimestamp);

    function getSpotPrice() external view returns (uint256);

    function getAveragePrice(uint256 priceAccumulator, uint32 priceTimestamp) external view returns (uint256);

    function setOwner(address _owner) external;

    function setUniswapPair(address _uniswapPair) external;

    function tradeX(
        uint256 xAfter,
        uint256 xBefore,
        uint256 yBefore,
        bytes calldata data
    ) external view returns (uint256 yAfter);

    function tradeY(
        uint256 yAfter,
        uint256 yBefore,
        uint256 xBefore,
        bytes calldata data
    ) external view returns (uint256 xAfter);

    function depositTradeXIn(
        uint256 xLeft,
        uint256 xBefore,
        uint256 yBefore,
        bytes calldata data
    ) external view returns (uint256 xIn);

    function depositTradeYIn(
        uint256 yLeft,
        uint256 yBefore,
        uint256 xBefore,
        bytes calldata data
    ) external view returns (uint256 yIn);

    function getSwapAmount0Out(
        uint256 swapFee,
        uint256 amount1In,
        bytes calldata data
    ) external view returns (uint256 amount0Out);

    function getSwapAmount1Out(
        uint256 swapFee,
        uint256 amount0In,
        bytes calldata data
    ) external view returns (uint256 amount1Out);

    function getSwapAmountInMaxOut(
        bool inverse,
        uint256 swapFee,
        uint256 _amountOut,
        bytes calldata data
    ) external view returns (uint256 amountIn, uint256 amountOut);

    function getSwapAmountInMinOut(
        bool inverse,
        uint256 swapFee,
        uint256 _amountOut,
        bytes calldata data
    ) external view returns (uint256 amountIn, uint256 amountOut);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

interface ITwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
    event OwnerSet(address owner);

    function owner() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB,
        address oracle,
        address trader
    ) external returns (address pair);

    function setOwner(address) external;

    function setMintFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external;

    function setBurnFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external;

    function setSwapFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external;

    function setOracle(
        address tokenA,
        address tokenB,
        address oracle
    ) external;

    function setTrader(
        address tokenA,
        address tokenB,
        address trader
    ) external;

    function collect(
        address tokenA,
        address tokenB,
        address to
    ) external;

    function withdraw(
        address tokenA,
        address tokenB,
        uint256 amount,
        address to
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

import './IERC20.sol';

interface ITwapERC20 is IERC20 {
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

interface IReserves {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1);

    function getFees() external view returns (uint256 fee0, uint256 fee1);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH4B');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH05');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH0E');
    }

    function safeTransferETH(
        address to,
        uint256 value,
        uint256 gasLimit
    ) internal {
        (bool success, ) = to.call{ value: value, gas: gasLimit }('');
        require(success, 'TH3F');
    }

    function transferETH(
        address to,
        uint256 value,
        uint256 gasLimit
    ) internal returns (bool success) {
        (success, ) = to.call{ value: value, gas: gasLimit }('');
    }
}