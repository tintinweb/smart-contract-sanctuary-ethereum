// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BasePay.sol";

contract Pay is BasePay {

    IMerchant public immutable iMerchant;
    ISwapRouter public immutable iSwapRouter;

    address public immutable WETH9;


    constructor(address _iMerchant, address _iSwapRouter, address _WETH9){
        iMerchant = IMerchant(_iMerchant);
        iSwapRouter = ISwapRouter(_iSwapRouter);
        WETH9 = _WETH9;
    }

    function pay(
        string memory _orderId,
        uint256 _paiAmount,
        uint256 _orderAmount,
        address _merchant,
        address _currency
    ) external returns(bool) {

        require(_paiAmount > 0);
        require(_orderAmount > 0);
        require(address(0) == merchantOrders[_merchant][_orderId], "Order existed");
        require(iMerchant.isMerchant(_merchant), "Invalid merchant");
        require(iMerchant.validatorCurrency(_merchant, _currency), "Invalid token");
        require(IERC20(_currency).balanceOf(msg.sender) >= _paiAmount, "Balance insufficient");

        bool isFixedRate = iMerchant.getIsFixedRate(_merchant);

        address settleToken = iMerchant.getSettleCurrency(_merchant);
        if(_currency == settleToken) {
            require(_paiAmount == _orderAmount);
        }

        TransferHelper.safeTransferFrom(_currency, msg.sender, address(this), _paiAmount);

        uint256 paidAmount = _paiAmount;

        if (address(0) != settleToken) {

            if (_currency != settleToken) {
                paidAmount = swapExactOutputSingle(_currency, _paiAmount, settleToken, _orderAmount);
            }

            (uint256 usdcFee,uint256 tokenFee) = getPaymentFee(_orderAmount, paidAmount, isFixedRate);

            if (iMerchant.getAutoSettle(_merchant)) {
                (uint256 usdcWithdrawFee,) = getWithdrawFee(_orderAmount - usdcFee, paidAmount-tokenFee, isFixedRate);
                _autoWithdraw(_merchant, iMerchant.getSettleAccount(_merchant), settleToken, _orderAmount - usdcFee, usdcWithdrawFee);
            } else {
                merchantFunds[_merchant][settleToken] += (_orderAmount - usdcFee);
            }

            tradeFeeOf[settleToken] += usdcFee;

            emit Order(_orderId, paidAmount, _currency, _orderAmount, settleToken, usdcFee, _merchant, msg.sender, isFixedRate);

        } else {

            (uint256 usdcFee,uint256 tokenFee) = getPaymentFee(_orderAmount, paidAmount, isFixedRate);

            if (iMerchant.getAutoSettle(_merchant)) {
                (,uint256 tokenWithdrawFee) = getWithdrawFee(_orderAmount - usdcFee, paidAmount-tokenFee, isFixedRate);
                _autoWithdraw(_merchant, iMerchant.getSettleAccount(_merchant), _currency, paidAmount - tokenFee, tokenWithdrawFee);
            } else {
                merchantFunds[_merchant][_currency] += (paidAmount - tokenFee);
            }

            tradeFeeOf[_currency] += tokenFee;

            emit Order(_orderId, paidAmount, _currency, _orderAmount, _currency, tokenFee, _merchant, msg.sender, isFixedRate);

        }

        merchantOrders[_merchant][_orderId] = msg.sender;

        return true;

    }

    function payWithETH(
        string memory _orderId,
        address _merchant,
        uint256 _orderAmount
    ) external payable returns(bool) {

        require(msg.value > 0);
        require(address(msg.sender).balance >= msg.value, "Balance insufficient");
        require(address(0) == merchantOrders[_merchant][_orderId], "Order existed");
        require(iMerchant.isMerchant(_merchant), "Invalid merchant");

        uint256 _paiAmount = msg.value;
        address settleToken = iMerchant.getSettleCurrency(_merchant);

        bool isFixedRate = iMerchant.getIsFixedRate(_merchant);

        if (address(0) != settleToken) {

            _paiAmount = swapExactOutputSingle(WETH9, msg.value, settleToken, _orderAmount);

            (uint256 usdcFee,uint256 tokenFee) = getPaymentFee(_orderAmount, _paiAmount, isFixedRate);

            if (iMerchant.getAutoSettle(_merchant)) {
                (uint256 usdcWithdrawFee,) = getWithdrawFee(_orderAmount - usdcFee, _paiAmount-tokenFee, isFixedRate);
                _autoWithdraw(_merchant, iMerchant.getSettleAccount(_merchant), settleToken, _orderAmount - usdcFee, usdcWithdrawFee);
            } else {
                merchantFunds[_merchant][settleToken] += (_orderAmount - usdcFee);
            }

            tradeFeeOf[settleToken] += usdcFee;

            emit Order(_orderId, _paiAmount, WETH9, _orderAmount, settleToken, usdcFee, _merchant, msg.sender, isFixedRate);

        } else {

            (uint256 usdcFee,uint256 tokenFee) = getPaymentFee(_orderAmount, _paiAmount, isFixedRate);

            if (iMerchant.getAutoSettle(_merchant)) {
                (,uint256 tokenWithdrawFee) = getWithdrawFee(_orderAmount - usdcFee, _paiAmount-tokenFee, isFixedRate);
                _autoWithdraw(_merchant, iMerchant.getSettleAccount(_merchant), WETH9, _paiAmount - tokenFee, tokenWithdrawFee);
            } else {
                merchantFunds[_merchant][WETH9] += (_paiAmount - tokenFee);
            }

            tradeFeeOf[WETH9] += tokenFee;

            emit Order(_orderId, _paiAmount, WETH9, _orderAmount, WETH9, tokenFee, _merchant, msg.sender, isFixedRate);

        }

        merchantOrders[_merchant][_orderId] = msg.sender;

        return true;

    }

    function claimToken(
        address _token,
        uint256 _amount,
        address _to
    ) external {

        require(address(0) != _token, "Invalid currency");
        require(iMerchant.isMerchant(msg.sender), "Invalid merchant");

        address settleAccount = _to;

        if(address(0) == _to) {
            settleAccount = iMerchant.getSettleAccount(msg.sender);
            if(address(0) == settleAccount) {
                settleAccount = msg.sender;
            }
        }

        _claim(msg.sender, _token, _amount, settleAccount);

    }

    function claimEth(
        uint256 _amount,
        address _to
    ) external {

        require(iMerchant.isMerchant(msg.sender), "Invalid merchant");

        IMerchant.MerchantInfo memory merchantInfo = iMerchant.getMerchantInfo(msg.sender);

        address settleAccount = _to;

        if(address(0) == _to) {
            settleAccount = merchantInfo.settleAccount;
            if(address(0) == settleAccount) {
                settleAccount = msg.sender;
            }
        }

        _claim(msg.sender, WETH9, _amount, settleAccount);

    }

    function swapExactOutputSingle(
        address _tokenIn,
        uint256 _amountInMaximum,
        address _tokenOut,
        uint256 _amountOut
    ) private returns(uint256 _amountIn) {

        if(WETH9 != _tokenIn) {
            TransferHelper.safeApprove(_tokenIn, address(iSwapRouter), _amountInMaximum);
        }

        ISwapRouter.ExactOutputSingleParams memory params =
        ISwapRouter.ExactOutputSingleParams({
        tokenIn: _tokenIn,
        tokenOut: _tokenOut,
        fee: poolFee,
        recipient: address(this) ,
        deadline: block.timestamp,
        amountOut: _amountOut,
        amountInMaximum: _amountInMaximum,
        sqrtPriceLimitX96: 0
        });

        _amountIn = iSwapRouter.exactOutputSingle{value:msg.value}(params);

        if (_amountIn < _amountInMaximum) {
            if(WETH9 == _tokenIn) {
                iSwapRouter.refundETH();
                if(address(msg.sender).balance >= (_amountInMaximum - _amountIn)) {
                    (bool success,) = msg.sender.call{ value: (_amountInMaximum - _amountIn) }("");
                    require(success, "refund failed");
                }
            } else {
                TransferHelper.safeApprove(_tokenIn, address(iSwapRouter), 0);
                TransferHelper.safeTransfer(_tokenIn, msg.sender, _amountInMaximum - _amountIn);
            }
        }

    }

    function _autoWithdraw(
        address _merchant,
        address _settleAccount,
        address _settleToken,
        uint256 _settleAmount,
        uint256 withdrawFee
    ) internal {

        address settleAccount = _settleAccount;

        if(address(0) == settleAccount) {
            settleAccount = _merchant;
        }

        if(WETH9 != _settleToken) {
            TransferHelper.safeTransfer(_settleToken, settleAccount, _settleAmount - withdrawFee);
        } else {
            TransferHelper.safeTransferETH(settleAccount, _settleAmount - withdrawFee);
        }

        tradeFeeOf[_settleToken] += withdrawFee;

        emit Withdraw(_merchant, _settleToken, _settleAmount, settleAccount, withdrawFee);

    }

    function _claim(
        address _merchant,
        address _currency,
        uint256 _amount,
        address _settleAccount
    ) internal {

        require(merchantFunds[_merchant][_currency] >= _amount);

        if(WETH9 != _currency) {
            TransferHelper.safeTransfer(_currency, _settleAccount, _amount);
        } else {
            TransferHelper.safeTransferETH(_settleAccount, _amount);
        }

        merchantFunds[_merchant][_currency] -= _amount;

        emit Withdraw(_merchant, _currency, _amount, _settleAccount, 0);

    }
}