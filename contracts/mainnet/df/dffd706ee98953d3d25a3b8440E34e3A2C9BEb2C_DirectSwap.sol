// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "../lib/weth/IWETH.sol";
import "../lib/uniswapv3/ISwapRouterUniV3.sol";
import { ICurvePool, ICurveEthPool } from "../lib/curve/ICurve.sol";
import { ICurveV2Pool, ICurveV2EthPool, IGenericFactoryZap } from "../lib/curve/ICurveV2.sol";
import { IBalancerV2Vault } from "../lib/balancerv2/IBalancerV2Vault.sol";
import "../fee/FeeModel.sol";
import "./IRouter.sol";

contract DirectSwap is FeeModel, IRouter {
    using SafeMath for uint256;

    address private constant ETH_IDENTIFIER = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    uint256 private constant MAX_INT = 2**256 - 1;

    address public immutable weth;

    constructor(
        address _weth,
        uint256 _partnerSharePercent,
        uint256 _maxFeePercent,
        uint256 _paraswapReferralShare,
        uint256 _paraswapSlippageShare,
        IFeeClaimer _feeClaimer
    ) FeeModel(_partnerSharePercent, _maxFeePercent, _paraswapReferralShare, _paraswapSlippageShare, _feeClaimer) {
        weth = _weth;
    }

    event SwappedDirect(
        bytes16 uuid,
        address partner,
        uint256 feePercent,
        address initiator,
        DirectSwapKind kind,
        address indexed beneficiary,
        address indexed srcToken,
        address indexed destToken,
        uint256 srcAmount,
        uint256 receivedAmount,
        uint256 expectedAmount
    );

    enum DirectSwapKind {
        UNIV3_SELL,
        UNIV3_BUY,
        CURVEV1,
        CURVEV2,
        BALV2_SELL,
        BALV2_BUY
    }

    function initialize(bytes calldata) external pure override {
        revert("METHOD NOT IMPLEMENTED");
    }

    function getKey() external pure override returns (bytes32) {
        return keccak256(abi.encodePacked("DIRECT_SWAP_ROUTER", "1.0.0"));
    }

    function directUniV3Swap(Utils.DirectUniV3 memory data) external payable {
        address fromToken = data.fromToken;
        uint256 fromAmount = data.fromAmount;
        uint256 expectedAmount = data.expectedAmount;
        require(msg.value == (fromToken == ETH_IDENTIFIER ? fromAmount : 0), "Incorrect msg.value");

        address payable beneficiary = data.beneficiary == address(0) ? msg.sender : data.beneficiary;

        transferTokensFromProxy(fromToken, fromAmount, data.permit);

        if (_isTakeFeeFromSrcToken(data.feePercent)) {
            // take fee from source token
            fromAmount = takeFromTokenFee(fromToken, fromAmount, data.partner, data.feePercent);
        }

        if (!data.isApproved) {
            Utils.approve(data.exchange, fromToken, fromAmount);
        }

        uint256 amountOut = ISwapRouterUniV3(data.exchange).exactInput{
            value: fromToken == ETH_IDENTIFIER ? fromAmount : 0
        }(
            ISwapRouterUniV3.ExactInputParams({
                path: data.path,
                recipient: address(this),
                deadline: data.deadline,
                amountIn: fromAmount,
                amountOutMinimum: 1
            })
        );

        if (data.toToken == ETH_IDENTIFIER) {
            IWETH(weth).withdraw(amountOut);
        }

        uint256 receivedAmount = afterSell(
            data.toToken,
            data.toAmount,
            beneficiary,
            data.feePercent,
            data.partner,
            data.expectedAmount,
            0
        );

        emit SwappedDirect(
            data.uuid,
            data.partner,
            data.feePercent,
            msg.sender,
            DirectSwapKind.UNIV3_SELL,
            beneficiary,
            fromToken,
            data.toToken,
            fromAmount,
            receivedAmount,
            expectedAmount
        );
    }

    function directUniV3Buy(Utils.DirectUniV3 memory data) external payable {
        address fromToken = data.fromToken;
        require(msg.value == (fromToken == ETH_IDENTIFIER ? data.fromAmount : 0), "Incorrect msg.value");

        address payable beneficiary = data.beneficiary == address(0) ? msg.sender : data.beneficiary;

        transferTokensFromProxy(fromToken, data.fromAmount, data.permit);

        if (!data.isApproved) {
            Utils.approve(data.exchange, fromToken, data.fromAmount);
        }

        ISwapRouterUniV3(data.exchange).exactOutput{ value: fromToken == ETH_IDENTIFIER ? data.fromAmount : 0 }(
            ISwapRouterUniV3.ExactOutputParams({
                path: data.path,
                recipient: address(this),
                deadline: data.deadline,
                amountOut: data.toAmount,
                amountInMaximum: MAX_INT
            })
        );

        if (data.fromToken == ETH_IDENTIFIER) {
            ISwapRouterUniV3(data.exchange).refundETH();
        }

        if (data.toToken == ETH_IDENTIFIER) {
            IWETH(weth).withdraw(data.toAmount);
        }

        (uint256 amountIn, uint256 receivedAmount) = afterBuy(
            fromToken,
            data.toToken,
            data.fromAmount,
            data.toAmount,
            beneficiary,
            data.feePercent,
            data.partner,
            data.expectedAmount
        );

        emit SwappedDirect(
            data.uuid,
            data.partner,
            data.feePercent,
            msg.sender,
            DirectSwapKind.UNIV3_BUY,
            beneficiary,
            data.fromToken,
            data.toToken,
            amountIn,
            receivedAmount,
            data.expectedAmount
        );
    }

    function directCurveV1Swap(Utils.DirectCurveV1 memory data) external payable {
        address fromToken = data.fromToken;
        uint256 fromAmount = data.fromAmount;
        uint256 expectedAmount = data.expectedAmount;
        require(msg.value == (fromToken == ETH_IDENTIFIER ? fromAmount : 0), "Incorrect msg.value");

        address payable beneficiary = data.beneficiary == address(0) ? msg.sender : data.beneficiary;

        transferTokensFromProxy(fromToken, fromAmount, data.permit);

        if (_isTakeFeeFromSrcToken(data.feePercent)) {
            // take fee from source token
            fromAmount = takeFromTokenFee(fromToken, fromAmount, data.partner, data.feePercent);
        }

        bool isFromTokenNativeAndNeedToWrap = fromToken == ETH_IDENTIFIER && data.needWrapNative == true;

        if (isFromTokenNativeAndNeedToWrap) {
            IWETH(weth).deposit{ value: fromAmount }();
        }

        if (!data.isApproved) {
            Utils.approve(data.exchange, isFromTokenNativeAndNeedToWrap ? weth : fromToken, fromAmount);
        }

        if (data.swapType == Utils.CurveSwapType.EXCHANGE_UNDERLYING) {
            ICurvePool(data.exchange).exchange_underlying(data.i, data.j, fromAmount, 1);
        } else {
            if (address(fromToken) == ETH_IDENTIFIER && data.needWrapNative == false) {
                ICurveEthPool(data.exchange).exchange{ value: fromAmount }(data.i, data.j, fromAmount, 1);
            } else {
                ICurvePool(data.exchange).exchange(data.i, data.j, fromAmount, 1);
            }
        }

        uint256 receivedAmount;
        if (address(data.toToken) == ETH_IDENTIFIER && data.needWrapNative == true) {
            receivedAmount = Utils.tokenBalance(weth, address(this));
            IWETH(weth).withdraw(receivedAmount);
        }

        receivedAmount = afterSell(
            data.toToken,
            data.toAmount,
            beneficiary,
            data.feePercent,
            data.partner,
            expectedAmount,
            receivedAmount
        );

        emit SwappedDirect(
            data.uuid,
            data.partner,
            data.feePercent,
            msg.sender,
            DirectSwapKind.CURVEV1,
            beneficiary,
            fromToken,
            data.toToken,
            fromAmount,
            receivedAmount,
            expectedAmount
        );
    }

    function directCurveV2Swap(Utils.DirectCurveV2 memory data) external payable {
        address fromToken = data.fromToken;
        uint256 fromAmount = data.fromAmount;
        uint256 expectedAmount = data.expectedAmount;
        require(msg.value == (fromToken == ETH_IDENTIFIER ? fromAmount : 0), "Incorrect msg.value");

        address payable beneficiary = data.beneficiary == address(0) ? msg.sender : data.beneficiary;

        transferTokensFromProxy(fromToken, fromAmount, data.permit);

        if (_isTakeFeeFromSrcToken(data.feePercent)) {
            // take fee from source token
            fromAmount = takeFromTokenFee(fromToken, fromAmount, data.partner, data.feePercent);
        }

        bool isFromTokenNativeAndNeedToWrap = fromToken == ETH_IDENTIFIER && data.needWrapNative == true;
        if (isFromTokenNativeAndNeedToWrap) {
            IWETH(weth).deposit{ value: fromAmount }();
        }

        if (!data.isApproved) {
            Utils.approve(data.exchange, isFromTokenNativeAndNeedToWrap ? weth : fromToken, fromAmount);
        }

        if (data.swapType == Utils.CurveSwapType.EXCHANGE_UNDERLYING) {
            ICurveV2Pool(data.exchange).exchange_underlying(data.i, data.j, fromAmount, 1);
        } else if (data.swapType == Utils.CurveSwapType.EXCHANGE_GENERIC_FACTORY_ZAP) {
            IGenericFactoryZap(data.exchange).exchange(data.poolAddress, data.i, data.j, fromAmount, 1);
        } else {
            if (address(fromToken) == ETH_IDENTIFIER && data.needWrapNative == false) {
                ICurveV2EthPool(data.exchange).exchange{ value: fromAmount }(data.i, data.j, fromAmount, 1, true);
            } else {
                ICurveV2Pool(data.exchange).exchange(data.i, data.j, fromAmount, 1);
            }
        }

        uint256 receivedAmount;
        if (address(data.toToken) == ETH_IDENTIFIER && data.needWrapNative == true) {
            receivedAmount = Utils.tokenBalance(weth, address(this));
            IWETH(weth).withdraw(receivedAmount);
        }

        receivedAmount = afterSell(
            data.toToken,
            data.toAmount,
            beneficiary,
            data.feePercent,
            data.partner,
            expectedAmount,
            receivedAmount
        );

        emit SwappedDirect(
            data.uuid,
            data.partner,
            data.feePercent,
            msg.sender,
            DirectSwapKind.CURVEV2,
            beneficiary,
            fromToken,
            data.toToken,
            fromAmount,
            receivedAmount,
            expectedAmount
        );
    }

    function directBalancerV2GivenInSwap(Utils.DirectBalancerV2 memory data) external payable {
        address fromToken = data.assets[data.swaps[0].assetInIndex];
        uint256 fromAmount = data.fromAmount;
        address toToken = data.assets[data.swaps[data.swaps.length - 1].assetOutIndex];
        uint256 expectedAmount = data.expectedAmount;

        if (fromToken == address(0)) fromToken = ETH_IDENTIFIER;
        if (toToken == address(0)) toToken = ETH_IDENTIFIER;
        require(msg.value == (fromToken == ETH_IDENTIFIER ? fromAmount : 0), "Incorrect msg.value");

        address payable beneficiary = data.beneficiary == address(0) ? msg.sender : data.beneficiary;

        transferTokensFromProxy(fromToken, fromAmount, data.permit);

        if (_isTakeFeeFromSrcToken(data.feePercent)) {
            // take fee from source token
            data.swaps[0].amount = takeFromTokenFee(fromToken, fromAmount, data.partner, data.feePercent);
            fromAmount = data.swaps[0].amount;
        }

        if (!data.isApproved) {
            Utils.approve(data.vault, fromToken, fromAmount);
        }

        IBalancerV2Vault(data.vault).batchSwap{ value: fromToken == ETH_IDENTIFIER ? fromAmount : 0 }(
            IBalancerV2Vault.SwapKind.GIVEN_IN,
            data.swaps,
            data.assets,
            data.funds,
            data.limits,
            data.deadline
        );

        uint256 receivedAmount = afterSell(
            toToken,
            data.toAmount,
            beneficiary,
            data.feePercent,
            data.partner,
            expectedAmount,
            0
        );

        emit SwappedDirect(
            data.uuid,
            data.partner,
            data.feePercent,
            msg.sender,
            DirectSwapKind.BALV2_SELL,
            beneficiary,
            fromToken,
            toToken,
            data.fromAmount,
            receivedAmount,
            expectedAmount
        );
    }

    function directBalancerV2GivenOutSwap(Utils.DirectBalancerV2 memory data) external payable {
        address fromToken = data.assets[data.swaps[data.swaps.length - 1].assetInIndex];
        address toToken = data.assets[data.swaps[0].assetOutIndex];
        uint256 expectedAmount = data.expectedAmount;

        if (fromToken == address(0)) fromToken = ETH_IDENTIFIER;
        if (toToken == address(0)) toToken = ETH_IDENTIFIER;
        require(msg.value == (fromToken == ETH_IDENTIFIER ? data.fromAmount : 0), "Incorrect msg.value");

        address payable beneficiary = data.beneficiary == address(0) ? msg.sender : data.beneficiary;

        transferTokensFromProxy(fromToken, data.fromAmount, data.permit);

        if (!data.isApproved) {
            Utils.approve(data.vault, fromToken, data.fromAmount);
        }

        IBalancerV2Vault(data.vault).batchSwap{ value: fromToken == ETH_IDENTIFIER ? data.fromAmount : 0 }(
            IBalancerV2Vault.SwapKind.GIVEN_OUT,
            data.swaps,
            data.assets,
            data.funds,
            data.limits,
            data.deadline
        );

        (uint256 amountIn, uint256 receivedAmount) = afterBuy(
            fromToken,
            toToken,
            data.fromAmount,
            data.toAmount,
            beneficiary,
            data.feePercent,
            data.partner,
            expectedAmount
        );

        emit SwappedDirect(
            data.uuid,
            data.partner,
            data.feePercent,
            msg.sender,
            DirectSwapKind.BALV2_BUY,
            beneficiary,
            fromToken,
            toToken,
            amountIn,
            receivedAmount,
            expectedAmount
        );
    }

    function afterSell(
        address toToken,
        uint256 toAmount,
        address payable beneficiary,
        uint256 feePercent,
        address payable partner,
        uint256 expectedAmount,
        uint256 proposedReceivedAmount
    ) private returns (uint256 receivedAmount) {
        receivedAmount = proposedReceivedAmount == 0
            ? Utils.tokenBalance(toToken, address(this))
            : proposedReceivedAmount;
        require(receivedAmount >= toAmount, "Received amount of tokens are less then expected");

        if (
            _getFixedFeeBps(partner, feePercent) != 0 && !_isTakeFeeFromSrcToken(feePercent) && !_isReferral(feePercent)
        ) {
            takeToTokenFeeAndTransfer(toToken, receivedAmount, beneficiary, partner, feePercent);
        } else if (receivedAmount > expectedAmount && !_isTakeFeeFromSrcToken(feePercent)) {
            takeSlippageAndTransferSell(toToken, beneficiary, partner, receivedAmount, expectedAmount, feePercent);
        } else {
            Utils.transferTokens(toToken, beneficiary, receivedAmount);
        }
    }

    function afterBuy(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address payable beneficiary,
        uint256 feePercent,
        address payable partner,
        uint256 expectedAmount
    ) private returns (uint256 amountIn, uint256 receivedAmount) {
        receivedAmount = Utils.tokenBalance(toToken, address(this));
        require(receivedAmount >= toAmount, "Received amount of tokens are less then expected");
        uint256 remainingAmount = Utils.tokenBalance(fromToken, address(this));
        amountIn = fromAmount.sub(remainingAmount);

        if (
            _getFixedFeeBps(partner, feePercent) != 0 && !_isTakeFeeFromSrcToken(feePercent) && !_isReferral(feePercent)
        ) {
            takeToTokenFeeAndTransfer(toToken, receivedAmount, beneficiary, partner, feePercent);
            // Transfer remaining token back to sender
            Utils.transferTokens(fromToken, msg.sender, remainingAmount);
        } else {
            Utils.transferTokens(toToken, beneficiary, receivedAmount);
            if (_getFixedFeeBps(partner, feePercent) != 0 && _isTakeFeeFromSrcToken(feePercent)) {
                //  take fee from source token and transfer remaining token back to sender
                takeFromTokenFeeAndTransfer(fromToken, amountIn, remainingAmount, partner, feePercent);
            } else if (amountIn < expectedAmount) {
                takeSlippageAndTransferBuy(fromToken, partner, expectedAmount, amountIn, remainingAmount, feePercent);
            } else {
                // Transfer remaining token back to sender
                Utils.transferTokens(fromToken, msg.sender, remainingAmount);
            }
        }
    }

    function transferTokensFromProxy(
        address token,
        uint256 amount,
        bytes memory permit
    ) private {
        if (token != ETH_IDENTIFIER) {
            Utils.permit(token, permit);
            tokenTransferProxy.transferFrom(token, msg.sender, address(this), amount);
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IWETH is IERC20 {
    function deposit() external payable virtual;

    function withdraw(uint256 amount) external virtual;
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "../Utils.sol";

interface ISwapRouterUniV3 {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);

    function refundETH() external;
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPool {
    function underlying_coins(int128 index) external view returns (address);

    function coins(int128 index) external view returns (address);
}

interface IPoolV3 {
    function underlying_coins(uint256 index) external view returns (address);

    function coins(uint256 index) external view returns (address);
}

interface ICurvePool {
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external;

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external;
}

interface ICurveEthPool {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external payable;
}

interface ICompoundPool {
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external;

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface ICurveV2Pool {
    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 minDy
    ) external;

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 minDy
    ) external;
}

interface IGenericFactoryZap {
    function exchange(
        address _pool,
        uint256 i,
        uint256 j,
        uint256 _dx,
        uint256 _min_dy
    ) external;
}

interface ICurveV2EthPool {
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 minDy,
        bool useEth
    ) external payable;
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "../Utils.sol";

interface IBalancerV2Vault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        address[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../AugustusStorage.sol";
import "../lib/Utils.sol";
import "./IFeeClaimer.sol";
// helpers
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FeeModel is AugustusStorage {
    using SafeMath for uint256;

    uint256 public immutable partnerSharePercent;
    uint256 public immutable maxFeePercent;
    uint256 public immutable paraswapReferralShare;
    uint256 public immutable paraswapSlippageShare;
    IFeeClaimer public immutable feeClaimer;

    constructor(
        uint256 _partnerSharePercent,
        uint256 _maxFeePercent,
        uint256 _paraswapReferralShare,
        uint256 _paraswapSlippageShare,
        IFeeClaimer _feeClaimer
    ) {
        partnerSharePercent = _partnerSharePercent;
        maxFeePercent = _maxFeePercent;
        paraswapReferralShare = _paraswapReferralShare;
        paraswapSlippageShare = _paraswapSlippageShare;
        feeClaimer = _feeClaimer;
    }

    // feePercent is a packed structure.
    // Bits 255-248 = 8-bit version field
    //
    // Version 0
    // =========
    // Entire structure is interpreted as the fee percent in basis points.
    // If set to 0 then partner will not receive any fees.
    //
    // Version 1
    // =========
    // Bits 13-0 = Fee percent in basis points
    // Bit 14 = positiveSlippageToUser (positive slippage to partner if not set)
    // Bit 15 = if set, take fee from fromToken, toToken otherwise
    // Bit 16 = if set, do fee distribution as per referral program

    function takeFromTokenFee(
        address fromToken,
        uint256 fromAmount,
        address payable partner,
        uint256 feePercent
    ) internal returns (uint256 newFromAmount) {
        uint256 fixedFeeBps = _getFixedFeeBps(partner, feePercent);
        if (fixedFeeBps == 0) return fromAmount;
        (uint256 partnerShare, uint256 paraswapShare) = _calcFixedFees(fromAmount, fixedFeeBps);
        return _distributeFees(fromAmount, fromToken, partner, partnerShare, paraswapShare);
    }

    function takeFromTokenFeeAndTransfer(
        address fromToken,
        uint256 fromAmount,
        uint256 remainingAmount,
        address payable partner,
        uint256 feePercent
    ) internal {
        uint256 fixedFeeBps = _getFixedFeeBps(partner, feePercent);
        (uint256 partnerShare, uint256 paraswapShare) = _calcFixedFees(fromAmount, fixedFeeBps);
        if (partnerShare.add(paraswapShare) <= remainingAmount) {
            remainingAmount = _distributeFees(remainingAmount, fromToken, partner, partnerShare, paraswapShare);
        }
        Utils.transferTokens(fromToken, msg.sender, remainingAmount);
    }

    function takeToTokenFeeAndTransfer(
        address toToken,
        uint256 receivedAmount,
        address payable beneficiary,
        address payable partner,
        uint256 feePercent
    ) internal {
        uint256 fixedFeeBps = _getFixedFeeBps(partner, feePercent);
        (uint256 partnerShare, uint256 paraswapShare) = _calcFixedFees(receivedAmount, fixedFeeBps);
        Utils.transferTokens(
            toToken,
            beneficiary,
            _distributeFees(receivedAmount, toToken, partner, partnerShare, paraswapShare)
        );
    }

    function takeSlippageAndTransferSell(
        address toToken,
        address payable beneficiary,
        address payable partner,
        uint256 positiveAmount,
        uint256 negativeAmount,
        uint256 feePercent
    ) internal {
        uint256 totalSlippage = positiveAmount.sub(negativeAmount);
        if (partner != address(0)) {
            (uint256 referrerShare, uint256 paraswapShare) = _calcSlippageFees(totalSlippage, feePercent);
            positiveAmount = _distributeFees(positiveAmount, toToken, partner, referrerShare, paraswapShare);
        } else {
            uint256 paraswapSlippage = totalSlippage.mul(paraswapSlippageShare).div(10000);
            Utils.transferTokens(toToken, feeWallet, paraswapSlippage);
            positiveAmount = positiveAmount.sub(paraswapSlippage);
        }
        Utils.transferTokens(toToken, beneficiary, positiveAmount);
    }

    function takeSlippageAndTransferBuy(
        address fromToken,
        address payable partner,
        uint256 positiveAmount,
        uint256 negativeAmount,
        uint256 remainingAmount,
        uint256 feePercent
    ) internal {
        uint256 totalSlippage = positiveAmount.sub(negativeAmount);
        if (partner != address(0)) {
            (uint256 referrerShare, uint256 paraswapShare) = _calcSlippageFees(totalSlippage, feePercent);
            remainingAmount = _distributeFees(remainingAmount, fromToken, partner, referrerShare, paraswapShare);
        } else {
            uint256 paraswapSlippage = totalSlippage.mul(paraswapSlippageShare).div(10000);
            Utils.transferTokens(fromToken, feeWallet, paraswapSlippage);
            remainingAmount = remainingAmount.sub(paraswapSlippage);
        }
        // Transfer remaining token back to sender
        Utils.transferTokens(fromToken, msg.sender, remainingAmount);
    }

    function _getFixedFeeBps(address partner, uint256 feePercent) internal view returns (uint256 fixedFeeBps) {
        if (partner == address(0)) return 0;
        uint256 version = feePercent >> 248;
        if (version == 0) {
            fixedFeeBps = feePercent;
        } else {
            fixedFeeBps = feePercent & 0x3FFF;
        }
        return fixedFeeBps > maxFeePercent ? maxFeePercent : fixedFeeBps;
    }

    function _calcFixedFees(uint256 amount, uint256 fixedFeeBps)
        private
        view
        returns (uint256 partnerShare, uint256 paraswapShare)
    {
        uint256 fee = amount.mul(fixedFeeBps).div(10000);
        partnerShare = fee.mul(partnerSharePercent).div(10000);
        paraswapShare = fee.sub(partnerShare);
    }

    function _calcSlippageFees(uint256 slippage, uint256 feePercent)
        private
        view
        returns (uint256 partnerShare, uint256 paraswapShare)
    {
        uint256 feeBps = feePercent & 0x3FFF;
        require(feeBps + paraswapReferralShare <= 10000, "Invalid fee percent");
        paraswapShare = slippage.mul(paraswapReferralShare).div(10000);
        partnerShare = slippage.mul(feeBps).div(10000);
    }

    function _distributeFees(
        uint256 currentBalance,
        address token,
        address payable partner,
        uint256 partnerShare,
        uint256 paraswapShare
    ) private returns (uint256 newBalance) {
        uint256 totalFees = partnerShare.add(paraswapShare);
        if (totalFees == 0) return currentBalance;

        require(totalFees <= currentBalance, "Insufficient balance to pay for fees");

        Utils.transferTokens(token, payable(address(feeClaimer)), totalFees);
        if (partnerShare != 0) {
            feeClaimer.registerFee(partner, IERC20(token), partnerShare);
        }
        if (paraswapShare != 0) {
            feeClaimer.registerFee(feeWallet, IERC20(token), paraswapShare);
        }
        return currentBalance.sub(totalFees);
    }

    function _isTakeFeeFromSrcToken(uint256 feePercent) internal pure returns (bool) {
        return feePercent >> 248 != 0 && (feePercent & (1 << 15)) != 0;
    }

    function _isReferral(uint256 feePercent) internal pure returns (bool) {
        return (feePercent & (1 << 16)) != 0;
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface IRouter {
    /**
     * @dev Certain routers/exchanges needs to be initialized.
     * This method will be called from Augustus
     */
    function initialize(bytes calldata data) external;

    /**
     * @dev Returns unique identifier for the router
     */
    function getKey() external pure returns (bytes32);

    event SwappedV3(
        bytes16 uuid,
        address partner,
        uint256 feePercent,
        address initiator,
        address indexed beneficiary,
        address indexed srcToken,
        address indexed destToken,
        uint256 srcAmount,
        uint256 receivedAmount,
        uint256 expectedAmount
    );

    event BoughtV3(
        bytes16 uuid,
        address partner,
        uint256 feePercent,
        address initiator,
        address indexed beneficiary,
        address indexed srcToken,
        address indexed destToken,
        uint256 srcAmount,
        uint256 receivedAmount,
        uint256 expectedAmount
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

/*solhint-disable avoid-low-level-calls */
// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../ITokenTransferProxy.sol";
import { IBalancerV2Vault } from "./balancerv2/IBalancerV2Vault.sol";

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IERC20PermitLegacy {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

library Utils {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    uint256 private constant MAX_UINT = type(uint256).max;

    enum CurveSwapType {
        EXCHANGE,
        EXCHANGE_UNDERLYING,
        EXCHANGE_GENERIC_FACTORY_ZAP
    }

    /**
     * @param fromToken Address of the source token
     * @param fromAmount Amount of source tokens to be swapped
     * @param toAmount Minimum destination token amount expected out of this swap
     * @param expectedAmount Expected amount of destination tokens without slippage
     * @param beneficiary Beneficiary address
     * 0 then 100% will be transferred to beneficiary. Pass 10000 for 100%
     * @param path Route to be taken for this swap to take place
     */
    struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.Path[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct BuyData {
        address adapter;
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.Route[] route;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct MegaSwapSellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.MegaSwapPath[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct SimpleData {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address[] callees;
        bytes exchangeData;
        uint256[] startIndexes;
        uint256[] values;
        address payable beneficiary;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct DirectUniV3 {
        address fromToken;
        address toToken;
        address exchange;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        uint256 feePercent;
        uint256 deadline;
        address payable partner;
        bool isApproved;
        address payable beneficiary;
        bytes path;
        bytes permit;
        bytes16 uuid;
    }

    struct DirectCurveV1 {
        address fromToken;
        address toToken;
        address exchange;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        uint256 feePercent;
        int128 i;
        int128 j;
        address payable partner;
        bool isApproved;
        CurveSwapType swapType;
        address payable beneficiary;
        bool needWrapNative;
        bytes permit;
        bytes16 uuid;
    }

    struct DirectCurveV2 {
        address fromToken;
        address toToken;
        address exchange;
        address poolAddress;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        uint256 feePercent;
        uint256 i;
        uint256 j;
        address payable partner;
        bool isApproved;
        CurveSwapType swapType;
        address payable beneficiary;
        bool needWrapNative;
        bytes permit;
        bytes16 uuid;
    }

    struct DirectBalancerV2 {
        IBalancerV2Vault.BatchSwapStep[] swaps;
        address[] assets;
        IBalancerV2Vault.FundManagement funds;
        int256[] limits;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        uint256 deadline;
        uint256 feePercent;
        address vault;
        address payable partner;
        bool isApproved;
        address payable beneficiary;
        bytes permit;
        bytes16 uuid;
    }

    struct Adapter {
        address payable adapter;
        uint256 percent;
        uint256 networkFee; //NOT USED
        Route[] route;
    }

    struct Route {
        uint256 index; //Adapter at which index needs to be used
        address targetExchange;
        uint256 percent;
        bytes payload;
        uint256 networkFee; //NOT USED - Network fee is associated with 0xv3 trades
    }

    struct MegaSwapPath {
        uint256 fromAmountPercent;
        Path[] path;
    }

    struct Path {
        address to;
        uint256 totalNetworkFee; //NOT USED - Network fee is associated with 0xv3 trades
        Adapter[] adapters;
    }

    function ethAddress() internal pure returns (address) {
        return ETH_ADDRESS;
    }

    function maxUint() internal pure returns (uint256) {
        return MAX_UINT;
    }

    function approve(
        address addressToApprove,
        address token,
        uint256 amount
    ) internal {
        if (token != ETH_ADDRESS) {
            IERC20 _token = IERC20(token);

            uint256 allowance = _token.allowance(address(this), addressToApprove);

            if (allowance < amount) {
                _token.safeApprove(addressToApprove, 0);
                _token.safeIncreaseAllowance(addressToApprove, MAX_UINT);
            }
        }
    }

    function transferTokens(
        address token,
        address payable destination,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (token == ETH_ADDRESS) {
                (bool result, ) = destination.call{ value: amount, gas: 10000 }("");
                require(result, "Failed to transfer Ether");
            } else {
                IERC20(token).safeTransfer(destination, amount);
            }
        }
    }

    function tokenBalance(address token, address account) internal view returns (uint256) {
        if (token == ETH_ADDRESS) {
            return account.balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }

    function permit(address token, bytes memory permit) internal {
        if (permit.length == 32 * 7) {
            (bool success, ) = token.call(abi.encodePacked(IERC20Permit.permit.selector, permit));
            require(success, "Permit failed");
        }

        if (permit.length == 32 * 8) {
            (bool success, ) = token.call(abi.encodePacked(IERC20PermitLegacy.permit.selector, permit));
            require(success, "Permit failed");
        }
    }

    function transferETH(address payable destination, uint256 amount) internal {
        if (amount > 0) {
            (bool result, ) = destination.call{ value: amount, gas: 10000 }("");
            require(result, "Transfer ETH failed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface ITokenTransferProxy {
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "./ITokenTransferProxy.sol";

contract AugustusStorage {
    struct FeeStructure {
        uint256 partnerShare;
        bool noPositiveSlippage;
        bool positiveSlippageToUser;
        uint16 feePercent;
        string partnerId;
        bytes data;
    }

    ITokenTransferProxy internal tokenTransferProxy;
    address payable internal feeWallet;

    mapping(address => FeeStructure) internal registeredPartners;

    mapping(bytes4 => address) internal selectorVsRouter;
    mapping(bytes32 => bool) internal adapterInitialized;
    mapping(bytes32 => bytes) internal adapterVsData;

    mapping(bytes32 => bytes) internal routerData;
    mapping(bytes32 => bool) internal routerInitialized;

    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");

    bytes32 public constant ROUTER_ROLE = keccak256("ROUTER_ROLE");
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFeeClaimer {
    /**
     * @notice register partner's, affiliate's and PP's fee
     * @dev only callable by AugustusSwapper contract
     * @param _account account address used to withdraw fees
     * @param _token token address
     * @param _fee fee amount in token
     */
    function registerFee(
        address _account,
        IERC20 _token,
        uint256 _fee
    ) external;

    /**
     * @notice claim partner share fee in ERC20 token
     * @dev transfers ERC20 token balance to the caller's account
     *      the call will fail if withdrawer have zero balance in the contract
     * @param _token address of the ERC20 token
     * @param _recipient address
     * @return true if the withdraw was successfull
     */
    function withdrawAllERC20(IERC20 _token, address _recipient) external returns (bool);

    /**
     * @notice batch claim whole balance of fee share amount
     * @dev transfers ERC20 token balance to the caller's account
     *      the call will fail if withdrawer have zero balance in the contract
     * @param _tokens list of addresses of the ERC20 token
     * @param _recipient address of recipient
     * @return true if the withdraw was successfull
     */
    function batchWithdrawAllERC20(IERC20[] calldata _tokens, address _recipient) external returns (bool);

    /**
     * @notice claim some partner share fee in ERC20 token
     * @dev transfers ERC20 token amount to the caller's account
     *      the call will fail if withdrawer have zero balance in the contract
     * @param _token address of the ERC20 token
     * @param _recipient address
     * @return true if the withdraw was successfull
     */
    function withdrawSomeERC20(
        IERC20 _token,
        uint256 _tokenAmount,
        address _recipient
    ) external returns (bool);

    /**
     * @notice batch claim some amount of fee share in ERC20 token
     * @dev transfers ERC20 token balance to the caller's account
     *      the call will fail if withdrawer have zero balance in the contract
     * @param _tokens address of the ERC20 tokens
     * @param _tokenAmounts array of amounts
     * @param _recipient destination account addresses
     * @return true if the withdraw was successfull
     */
    function batchWithdrawSomeERC20(
        IERC20[] calldata _tokens,
        uint256[] calldata _tokenAmounts,
        address _recipient
    ) external returns (bool);

    /**
     * @notice compute unallocated fee in token
     * @param _token address of the ERC20 token
     * @return amount of unallocated token in fees
     */
    function getUnallocatedFees(IERC20 _token) external view returns (uint256);

    /**
     * @notice returns unclaimed fee amount given the token
     * @dev retrieves the balance of ERC20 token fee amount for a partner
     * @param _token address of the ERC20 token
     * @param _partner account address of the partner
     * @return amount of balance
     */
    function getBalance(IERC20 _token, address _partner) external view returns (uint256);

    /**
     * @notice returns unclaimed fee amount given the token in batch
     * @dev retrieves the balance of ERC20 token fee amount for a partner in batch
     * @param _tokens list of ERC20 token addresses
     * @param _partner account address of the partner
     * @return _fees array of the token amount
     */
    function batchGetBalance(IERC20[] calldata _tokens, address _partner)
        external
        view
        returns (uint256[] memory _fees);
}