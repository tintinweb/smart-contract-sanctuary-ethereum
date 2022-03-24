// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import "./TransferSwapV2.sol";
import "./TransferSwapV3.sol";
import "./TransferSwapInch.sol";
import "./BridgeSwap.sol";

contract SwapMain is TransferSwapV2, TransferSwapV3, TransferSwapInch {
    using SafeERC20 for IERC20;
    event SwapRequestDone(bytes32 id, uint256 dstAmount, SwapStatus status);

    constructor(
        address _messageBus,
        address _supportedDex,
        address _nativeWrap
    ) {
        messageBus = _messageBus;
        supportedDex[_supportedDex] = true;
        nativeWrap = _nativeWrap;
        dstCryptoFee[43114] = 10000000;
        // minSwapAmount[bridgeToken] = 8 * 10**decimals;
        feeRubic = 160000; // 0.16%
    }

    /**
     * @notice called by MessageBus when the tokens are checked to be arrived at this contract's address.
               sends the amount received to the receiver. swaps beforehand if swap behavior is defined in message
     * NOTE: if the swap fails, it sends the tokens received directly to the receiver as fallback behavior
     * @param _token the address of the token sent through the bridge
     * @param _amount the amount of tokens received at this contract through the cross-chain bridge
     * @param _srcChainId source chain ID
     * @param _message SwapRequestV2 message that defines the swap behavior on this destination chain
     */
    function executeMessageWithTransfer(
        address,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes memory _message
    ) external payable override returns (bool) {
        SwapRequestDest memory m = abi.decode((_message), (SwapRequestDest));
        bytes32 id = SwapBase._computeSwapRequestId(
            m.receiver,
            _srcChainId,
            uint64(block.chainid),
            _message
        );
        if (m.swap.version == SwapVersion.v3) {
            _executeDstSwapV3(_token, _amount, id, m);
        }
        if (m.swap.version == SwapVersion.v2) {
            _executeDstSwapV2(_token, _amount, id, m);
        } else {
            _executeDstSwapInch(_token, _amount, id, m);
        }
        // always return true since swap failure is already handled in-place
        return true;
    }

    function _executeDstSwapInch(
        address _token,
        uint256 _amount,
        bytes32 _id,
        SwapRequestDest memory _msgDst
    ) private {
        require(
            _token == _msgDst.swap.path[0],
            "bridged token must be the same as the first token in destination swap path"
        );

        uint256 dstAmount;
        SwapStatus status = SwapStatus.Succeeded;

        SwapInfoInch memory _dstSwap = SwapInfoInch({
            dex: _msgDst.swap.dex,
            path: _msgDst.swap.path,
            data: _msgDst.swap.data,
            amountOutMinimum: _msgDst.swap.amountOutMinimum
        });
        if (_dstSwap.path.length > 1) {
            bool success;
            if (_dstSwap.path[0] == nativeWrap) {
                (success, dstAmount) = _trySwapNativeInch(_dstSwap, _amount);
            } else {
                (success, dstAmount) = _trySwapInch(_dstSwap, _amount);
            }
            if (success) {
                _sendToken(
                    _dstSwap.path[_dstSwap.path.length - 1],
                    dstAmount,
                    _msgDst.receiver,
                    _msgDst.nativeOut
                );
                status = SwapStatus.Succeeded;
            } else {
                // handle swap failure, send the received token directly to receiver
                _sendToken(_token, _amount, _msgDst.receiver, false);
                dstAmount = _amount;
                status = SwapStatus.Fallback;
            }
        } else {
            // no need to swap, directly send the bridged token to user
            _sendToken(
                _dstSwap.path[0],
                _amount,
                _msgDst.receiver,
                _msgDst.nativeOut
            );
            dstAmount = _amount;
            status = SwapStatus.Succeeded;
        }
        emit SwapRequestDone(_id, dstAmount, status);
    }

    function _executeDstSwapV2(
        address _token,
        uint256 _amount,
        bytes32 _id,
        SwapRequestDest memory _msgDst
    ) private {
        require(
            _token == _msgDst.swap.path[0],
            "bridged token must be the same as the first token in destination swap path"
        );

        uint256 dstAmount;
        SwapStatus status = SwapStatus.Succeeded;

        SwapInfoV2 memory _dstSwap = SwapInfoV2({
            dex: _msgDst.swap.dex,
            path: _msgDst.swap.path,
            deadline: _msgDst.swap.deadline,
            amountOutMinimum: _msgDst.swap.amountOutMinimum
        });
        if (_dstSwap.path.length > 1) {
            bool success;
            (success, dstAmount) = _trySwapV2(_dstSwap, _amount);
            if (success) {
                _sendToken(
                    _dstSwap.path[_dstSwap.path.length - 1],
                    dstAmount,
                    _msgDst.receiver,
                    _msgDst.nativeOut
                );
                status = SwapStatus.Succeeded;
            } else {
                // handle swap failure, send the received token directly to receiver
                _sendToken(_token, _amount, _msgDst.receiver, false);
                dstAmount = _amount;
                status = SwapStatus.Fallback;
            }
        } else {
            // no need to swap, directly send the bridged token to user
            _sendToken(
                _dstSwap.path[0],
                _amount,
                _msgDst.receiver,
                _msgDst.nativeOut
            );
            dstAmount = _amount;
            status = SwapStatus.Succeeded;
        }
        emit SwapRequestDone(_id, dstAmount, status);
    }

    function _executeDstSwapV3(
        address _token,
        uint256 _amount,
        bytes32 _id,
        SwapRequestDest memory _msgDst
    ) private {
        require(
            _token == address(SwapBase._getFirstBytes20(_msgDst.swap.pathV3)),
            "bridged token must be the same as the first token in destination swap path"
        );

        uint256 dstAmount;
        SwapStatus status = SwapStatus.Succeeded;

        SwapInfoV3 memory _dstSwap = SwapInfoV3({
            dex: _msgDst.swap.dex,
            path: _msgDst.swap.pathV3,
            deadline: _msgDst.swap.deadline,
            amountOutMinimum: _msgDst.swap.amountOutMinimum
        });
        if (_dstSwap.path.length > 20) {
            bool success;
            (success, dstAmount) = _trySwapV3(_dstSwap, _amount);
            if (success) {
                _sendToken(
                    address(SwapBase._getLastBytes20(_dstSwap.path)),
                    dstAmount,
                    _msgDst.receiver,
                    _msgDst.nativeOut
                );
                status = SwapStatus.Succeeded;
            } else {
                // handle swap failure, send the received token directly to receiver
                _sendToken(_token, _amount, _msgDst.receiver, false);
                dstAmount = _amount;
                status = SwapStatus.Fallback;
            }
        } else {
            // no need to swap, directly send the bridged token to user
            _sendToken(
                address(SwapBase._getLastBytes20(_dstSwap.path)),
                _amount,
                _msgDst.receiver,
                _msgDst.nativeOut
            );
            dstAmount = _amount;
            status = SwapStatus.Succeeded;
        }
        emit SwapRequestDone(_id, dstAmount, status);
    }

    /**
     * @notice called by MessageBus when the executeMessageWithTransfer call fails. does nothing but emitting a "fail" event
     * @param _srcChainId source chain ID
     * @param _message SwapRequestDest message that defines the swap behavior on this destination chain
     */
    function executeMessageWithTransferFallback(
        address, // _sender (executor)
        address,
        uint256 _amount,
        uint64 _srcChainId,
        bytes memory _message
    ) external payable override returns (bool) {
        SwapRequestDest memory m = abi.decode((_message), (SwapRequestDest));

        bytes32 id = SwapBase._computeSwapRequestId(
            m.receiver,
            _srcChainId,
            uint64(block.chainid),
            _message
        );
        if (m.swap.version == SwapVersion.v3) {
            _sendToken(
                address(_getFirstBytes20(m.swap.pathV3)),
                _amount,
                m.receiver,
                false
            );
        } else {
            _sendToken(m.swap.path[0], _amount, m.receiver, false);
        }
        emit SwapRequestDone(id, 0, SwapStatus.Failed);
        // always return false to mark this transfer as failed since if this function is called then there nothing more
        // we can do in this app as the swap failures are already handled in executeMessageWithTransfer
        return false;
    }

    function executeMessageWithTransferRefund(
        address,
        uint256 _amount,
        bytes calldata _message
    ) external payable override returns (bool) {
        SwapRequestDest memory m = abi.decode((_message), (SwapRequestDest));
        if (m.swap.version == SwapVersion.v3) {
            _sendToken(
                address(_getLastBytes20(m.swap.pathV3)),
                _amount,
                m.receiver,
                false
            );
        } else {
            _sendToken(
                m.swap.path[m.swap.path.length - 1],
                _amount,
                m.receiver,
                false
            );
        }

        return true;
    }

    function _sendToken(
        address _token,
        uint256 _amount,
        address _receiver,
        bool _nativeOut
    ) private {
        if (_nativeOut) {
            require(_token == nativeWrap, "token mismatch");
            IWETH(nativeWrap).withdraw(_amount);
            (bool sent, ) = _receiver.call{value: _amount, gas: 50000}(""); //
            require(sent, "failed to send native");
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }
    }

    function setMinSwapAmount(uint256 _minSwapAmount) external onlyOwner {
        minSwapAmount = _minSwapAmount * 10**decimals;
    }

    function setRubicFee(uint256 _feeRubic) external onlyOwner {
        require(_feeRubic < 5000000);
        feeRubic = _feeRubic;
    }

    function setDecimalsUSD(uint8 _decimals) external onlyOwner {
        decimals = _decimals;
    }

    function setCryptoFee(uint64 _networkID, uint256 _amount)
        external
        onlyOwner
    {
        dstCryptoFee[_networkID] = _amount;
    }

    function setSupportedDex(address _dex, bool _enabled) external onlyOwner {
        supportedDex[_dex] = _enabled;
    }

    function sweepTokens(IERC20 token) external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function setNativeWrap(address _nativeWrap) external onlyOwner {
        nativeWrap = _nativeWrap;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import "./SwapBase.sol";
import "../../interfaces/IWETH.sol";
import "../../interfaces/IUniswapV2.sol";

contract TransferSwapV2 is SwapBase {
    using SafeERC20 for IERC20;

    // emitted when requested dstChainId == srcChainId, no bridging
    event DirectSwapV2(
        bytes32 id,
        uint64 srcChainId,
        uint256 amountIn,
        address tokenIn,
        uint256 amountOut,
        address tokenOut
    );

    event SwapRequestSentV2(
        bytes32 id,
        uint64 dstChainId,
        uint256 srcAmount,
        address srcToken
    );

    function transferWithSwapV2Native(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfoV2 calldata _srcSwap,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage,
        uint64 _nonce,
        bool _nativeOut
    ) external payable onlyEOA {
        require(_srcSwap.path[0] == nativeWrap, "token mismatch");
        require(msg.value >= _amountIn, "Amount insufficient");
        IWETH(nativeWrap).deposit{value: _amountIn}();
        _transferWithSwapV2(
            _receiver,
            _amountIn,
            _dstChainId,
            _srcSwap,
            _dstSwap,
            _maxBridgeSlippage,
            _nonce,
            _nativeOut,
            msg.value - _amountIn
        );
    }

    function transferWithSwapV2(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfoV2 calldata _srcSwap,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage,
        uint64 _nonce,
        bool _nativeOut
    ) external payable onlyEOA {
        IERC20(_srcSwap.path[0]).safeTransferFrom(
            msg.sender,
            address(this),
            _amountIn
        );
        _transferWithSwapV2(
            _receiver,
            _amountIn,
            _dstChainId,
            _srcSwap,
            _dstSwap,
            _maxBridgeSlippage,
            _nonce,
            _nativeOut,
            msg.value
        );
    }

    /**
     * @notice Sends a cross-chain transfer via the liquidity pool-based bridge and sends a message specifying a wanted swap action on the
               destination chain via the message bus
     * @param _receiver the app contract that implements the MessageReceiver abstract contract
     *        NOTE not to be confused with the receiver field in SwapInfoV2 which is an EOA address of a user
     * @param _amountIn the input amount that the user wants to swap and/or bridge
     * @param _dstChainId destination chain ID
     * @param _srcSwap a struct containing swap related requirements
     * @param _dstSwap a struct containing swap related requirements
     * @param _maxBridgeSlippage the max acceptable slippage at bridge, given as percentage in point (pip). Eg. 5000 means 0.5%.
     *        Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     *        transfer can be refunded.
     * @param _fee the fee to pay to MessageBus.
     */
    function _transferWithSwapV2(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfoV2 memory _srcSwap,
        SwapInfoDest memory _dstSwap,
        uint32 _maxBridgeSlippage,
        uint64 _nonce,
        bool _nativeOut,
        uint256 _fee
    ) private {
        uint64 chainId = uint64(block.chainid);

        require(
            _srcSwap.path.length > 1 && _dstChainId != chainId,
            "empty src swap path or same chain id"
        );

        address srcTokenOut = _srcSwap.path[_srcSwap.path.length - 1];
        uint256 srcAmtOut = _amountIn;

        // swap source token for intermediate token on the source DEX
        if (_srcSwap.path.length > 1) {
            bool success;
            (success, srcAmtOut) = _trySwapV2(_srcSwap, _amountIn);
            if (!success) revert("src swap failed");
        }

        require(
            srcAmtOut >= minSwapAmount,
            "amount must be greater than min swap amount"
        );

        _crossChainTransferWithSwapV2(
            _receiver,
            _amountIn,
            chainId,
            _dstChainId,
            _srcSwap,
            _dstSwap,
            _maxBridgeSlippage,
            _nonce,
            _nativeOut,
            _fee,
            srcTokenOut,
            srcAmtOut
        );
    }

    function _directSendV2(
        address _receiver,
        uint256 _amountIn,
        uint64 _chainId,
        SwapInfoV2 memory _srcSwap,
        uint64 _nonce,
        address srcTokenOut,
        uint256 srcAmtOut
    ) private {
        // no need to bridge, directly send the tokens to user
        IERC20(srcTokenOut).safeTransfer(_receiver, srcAmtOut);
        // use uint64 for chainid to be consistent with other components in the system
        bytes32 id = keccak256(
            abi.encode(msg.sender, _chainId, _receiver, _nonce, _srcSwap)
        );
        emit DirectSwapV2(
            id,
            _chainId,
            _amountIn,
            _srcSwap.path[0],
            srcAmtOut,
            srcTokenOut
        );
    }

    function _crossChainTransferWithSwapV2(
        address _receiver,
        uint256 _amountIn,
        uint64 _chainId,
        uint64 _dstChainId,
        SwapInfoV2 memory _srcSwap,
        SwapInfoDest memory _dstSwap,
        uint32 _maxBridgeSlippage,
        uint64 _nonce,
        bool _nativeOut,
        uint256 _fee,
        address srcTokenOut,
        uint256 srcAmtOut
    ) private {
        require(_dstSwap.path.length > 0, "empty dst swap path");
        bytes memory message = abi.encode(
            SwapRequestDest({
                swap: _dstSwap,
                receiver: msg.sender,
                nonce: _nonce,
                nativeOut: _nativeOut
            })
        );
        bytes32 id = SwapBase._computeSwapRequestId(
            msg.sender,
            _chainId,
            _dstChainId,
            message
        );
        _sendMessageWithTransferV2(
            _receiver,
            srcTokenOut,
            srcAmtOut,
            _dstChainId,
            _nonce,
            _maxBridgeSlippage,
            message,
            _fee
        );
        emit SwapRequestSentV2(id, _dstChainId, _amountIn, _srcSwap.path[0]);
    }

    function _sendMessageWithTransferV2(
        address _receiver,
        address srcTokenOut,
        uint256 srcAmtOut,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxBridgeSlippage,
        bytes memory _message,
        uint256 _fee
    ) private {
        // sends directly to msgBus
        sendMessageWithTransfer(
            _receiver,
            srcTokenOut,
            srcAmtOut * (1 - feeRubic / 1000000),
            _dstChainId,
            _nonce,
            _maxBridgeSlippage,
            _message,
            MessageSenderLib.BridgeType.Liquidity,
            _fee - dstCryptoFee[_dstChainId]
        );
    }

    function _trySwapV2(SwapInfoV2 memory _swap, uint256 _amount)
        internal
        returns (bool ok, uint256 amountOut)
    {
        uint256 zero;
        /*
        if (!supportedDex[_swap.dex]) {
            return (false, zero);
        }*/
        IERC20(_swap.path[0]).safeIncreaseAllowance(_swap.dex, _amount);
        try
            IUniswapV2(_swap.dex).swapExactTokensForTokens(
                _amount,
                _swap.amountOutMinimum,
                _swap.path,
                address(this),
                _swap.deadline
            )
        returns (uint256[] memory amounts) {
            return (true, amounts[amounts.length - 1]);
        } catch {
            return (false, zero);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import "./SwapBase.sol";
import "../../interfaces/IWETH.sol";
import "../../interfaces/ISwapRouter.sol";

contract TransferSwapV3 is SwapBase {
    using SafeERC20 for IERC20;

    // emitted when requested dstChainId == srcChainId, no bridging
    event DirectSwapV3(
        bytes32 id,
        uint64 srcChainId,
        uint256 amountIn,
        address tokenIn,
        uint256 amountOut,
        address tokenOut
    );

    event SwapRequestSentV3(
        bytes32 id,
        uint64 dstChainId,
        uint256 srcAmount,
        address srcToken
    );

    function transferWithSwapV3Native(
        address _receiver, // transfer swap contract in dst chain
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfoV3 calldata _srcSwap,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage,
        uint64 _nonce,
        bool _nativeOut
    ) external payable onlyEOA {
        require(
            address(_getFirstBytes20(_srcSwap.path)) == nativeWrap,
            "token mismatch"
        );
        require(msg.value >= _amountIn, "Amount insufficient");
        IWETH(nativeWrap).deposit{value: _amountIn}();
        _transferWithSwapV3(
            _receiver,
            _amountIn,
            _dstChainId,
            _srcSwap,
            _dstSwap,
            _maxBridgeSlippage,
            _nonce,
            _nativeOut,
            msg.value - _amountIn
        );
    }

    function transferWithSwapV3(
        address _receiver, // transfer swap contract in dst chain
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfoV3 calldata _srcSwap,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage,
        uint64 _nonce,
        bool _nativeOut
    ) external payable onlyEOA {
        IERC20(address(_getFirstBytes20(_srcSwap.path))).safeTransferFrom(
            msg.sender,
            address(this),
            _amountIn
        );
        _transferWithSwapV3(
            _receiver,
            _amountIn,
            _dstChainId,
            _srcSwap,
            _dstSwap,
            _maxBridgeSlippage,
            _nonce,
            _nativeOut,
            msg.value
        );
    }

    /**
     * @notice Sends a cross-chain transfer via the liquidity pool-based bridge and sends a message specifying a wanted swap action on the
               destination chain via the message bus
     * @param _receiver the app contract that implements the MessageReceiver abstract contract
     *        NOTE not to be confused with the receiver field in SwapInfoV2 which is an EOA address of a user
     * @param _amountIn the input amount that the user wants to swap and/or bridge
     * @param _dstChainId destination chain ID
     * @param _srcSwap a struct containing swap related requirements
     * @param _dstSwap a struct containing swap related requirements
     * @param _maxBridgeSlippage the max acceptable slippage at bridge, given as percentage in point (pip). Eg. 5000 means 0.5%.
     *        Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     *        transfer can be refunded.
     * @param _fee the fee to pay to MessageBus.
     */
    function _transferWithSwapV3(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfoV3 memory _srcSwap,
        SwapInfoDest memory _dstSwap,
        uint32 _maxBridgeSlippage,
        uint64 _nonce,
        bool _nativeOut,
        uint256 _fee
    ) private {
        uint64 chainId = uint64(block.chainid);

        require(
            _srcSwap.path.length > 20 && _dstChainId != chainId,
            "empty src swap path or same chain id"
        );

        address srcTokenOut = address(_getLastBytes20(_srcSwap.path));
        uint256 srcAmtOut = _amountIn;

        // swap source token for intermediate token on the source DEX
        if (_srcSwap.path.length > 20) {
            bool success;
            (success, srcAmtOut) = _trySwapV3(_srcSwap, _amountIn);
            if (!success) revert("src swap failed");
        }

        require(
            srcAmtOut >= minSwapAmount,
            "amount must be greater than min swap amount"
        );

        _crossChainTransferWithSwapV3(
                _receiver,
                _amountIn,
                chainId,
                _dstChainId,
                _srcSwap,
                _dstSwap,
                _maxBridgeSlippage,
                _nonce,
                _nativeOut,
                _fee,
                srcTokenOut,
                srcAmtOut
        );
    }

    function _directSendV3(
        address _receiver,
        uint256 _amountIn,
        uint64 _chainId,
        SwapInfoV3 memory _srcSwap,
        uint64 _nonce,
        address srcTokenOut,
        uint256 srcAmtOut
    ) private {
        // no need to bridge, directly send the tokens to user
        IERC20(srcTokenOut).safeTransfer(_receiver, srcAmtOut);
        // use uint64 for chainid to be consistent with other components in the system
        bytes32 id = keccak256(
            abi.encode(msg.sender, _chainId, _receiver, _nonce, _srcSwap)
        );
        emit DirectSwapV3(
            id,
            _chainId,
            _amountIn,
            address(_getFirstBytes20(_srcSwap.path)),
            srcAmtOut,
            srcTokenOut
        );
    }

    function _crossChainTransferWithSwapV3(
        address _receiver,
        uint256 _amountIn,
        uint64 _chainId,
        uint64 _dstChainId,
        SwapInfoV3 memory _srcSwap,
        SwapInfoDest memory _dstSwap,
        uint32 _maxBridgeSlippage,
        uint64 _nonce,
        bool _nativeOut,
        uint256 _fee,
        address srcTokenOut,
        uint256 srcAmtOut
    ) private {
        require(_dstSwap.path.length > 0, "empty dst swap path");
        bytes memory message = abi.encode(
            SwapRequestDest({
                swap: _dstSwap,
                receiver: msg.sender,
                nonce: _nonce,
                nativeOut: _nativeOut
            })
        );
        bytes32 id = _computeSwapRequestId(
            msg.sender,
            _chainId,
            _dstChainId,
            message
        );
        // bridge the intermediate token to destination chain along with the message
        // NOTE In production, it's better use a per-user per-transaction nonce so that it's less likely transferId collision
        // would happen at Bridge contract. Currently this nonce is a timestamp supplied by frontend
        _sendMessageWithTransferV3(
            _receiver,
            srcTokenOut,
            srcAmtOut,
            _dstChainId,
            _nonce,
            _maxBridgeSlippage,
            message,
            _fee
        );
        emit SwapRequestSentV3(
            id,
            _dstChainId,
            _amountIn,
            address(_getFirstBytes20(_srcSwap.path))
        );
    }

    function _sendMessageWithTransferV3(
        address _receiver,
        address srcTokenOut,
        uint256 srcAmtOut,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxBridgeSlippage,
        bytes memory _message,
        uint256 _fee
    ) private {
        // sends directly to msgBus
        sendMessageWithTransfer(
            _receiver,
            srcTokenOut,
            srcAmtOut * (1 - feeRubic / 1000000),
            _dstChainId,
            _nonce,
            _maxBridgeSlippage,
            _message,
            MessageSenderLib.BridgeType.Liquidity,
            _fee - dstCryptoFee[_dstChainId]
        );
    }

    function _trySwapV3(SwapInfoV3 memory _swap, uint256 _amount)
        internal
        returns (bool ok, uint256 amountOut)
    {
        uint256 zero;
        /*
        if (!supportedDex[_swap.dex]) {
            return (false, zero);
        }*/
        IERC20(address(_getFirstBytes20(_swap.path))).safeIncreaseAllowance(
            _swap.dex,
            _amount
        );

        IUniswapRouterV3.ExactInputParams memory paramsV3 = IUniswapRouterV3
            .ExactInputParams(
                _swap.path,
                address(this),
                _swap.deadline,
                _amount,
                _swap.amountOutMinimum
            );

        try IUniswapRouterV3(_swap.dex).exactInput(paramsV3) returns (
            uint256 _amountOut
        ) {
            return (true, _amountOut);
        } catch {
            return (false, zero);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import "./SwapBase.sol";
import "../../interfaces/IWETH.sol";

contract TransferSwapInch is SwapBase {
    using Address for address payable;
    using SafeERC20 for IERC20;

    // emitted when requested dstChainId == srcChainId, no bridging
    event DirectSwapInch(
        bytes32 id,
        uint64 srcChainId,
        uint256 amountIn,
        address tokenIn,
        uint256 amountOut,
        address tokenOut
    );

    event SwapRequestSentInch(
        bytes32 id,
        uint64 dstChainId,
        uint256 srcAmount,
        address srcToken
    );

    function transferWithSwapInchNative(
        address _receiver, // transfer swap contract in dst chain
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfoInch calldata _srcSwap,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage,
        uint64 _nonce,
        bool _nativeOut
    ) external payable onlyEOA {
        require(_srcSwap.path[0] == nativeWrap, "token mismatch");
        require(msg.value >= _amountIn, "Amount insufficient");
        IWETH(nativeWrap).deposit{value: _amountIn}();
        _transferWithSwapInch(
            _receiver,
            _amountIn,
            _dstChainId,
            _srcSwap,
            _dstSwap,
            _maxBridgeSlippage,
            _nonce,
            _nativeOut,
            msg.value - _amountIn
        );
    }

    function transferWithSwapInch(
        address _receiver, // transfer swap contract in dst chain
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfoInch calldata _srcSwap,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage,
        uint64 _nonce,
        bool _nativeOut
    ) external payable onlyEOA {
        IERC20(_srcSwap.path[0]).safeTransferFrom(
            msg.sender,
            address(this),
            _amountIn
        );
        _transferWithSwapInch(
            _receiver,
            _amountIn,
            _dstChainId,
            _srcSwap,
            _dstSwap,
            _maxBridgeSlippage,
            _nonce,
            _nativeOut,
            msg.value
        );
    }

    /**
     * @notice Sends a cross-chain transfer via the liquidity pool-based bridge and sends a message specifying a wanted swap action on the
               destination chain via the message bus
     * @param _receiver the app contract that implements the MessageReceiver abstract contract
     *        NOTE not to be confused with the receiver field in SwapInfoV2 which is an EOA address of a user
     * @param _amountIn the input amount that the user wants to swap and/or bridge
     * @param _dstChainId destination chain ID
     * @param _srcSwap a struct containing swap related requirements
     * @param _dstSwap a struct containing swap related requirements
     * @param _maxBridgeSlippage the max acceptable slippage at bridge, given as percentage in point (pip). Eg. 5000 means 0.5%.
     *        Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     *        transfer can be refunded.
     * @param _fee the fee to pay to MessageBus.
     */
    function _transferWithSwapInch(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfoInch memory _srcSwap,
        SwapInfoDest memory _dstSwap,
        uint32 _maxBridgeSlippage,
        uint64 _nonce,
        bool _nativeOut,
        uint256 _fee
    ) private {
        uint64 chainId = uint64(block.chainid);

        require(
            _srcSwap.path.length > 1 && _dstChainId != chainId,
            "empty src swap path or same chain id"
        );

        address srcTokenOut = _srcSwap.path[_srcSwap.path.length - 1];
        uint256 srcAmtOut = _amountIn;

        // swap source token for intermediate token on the source DEX
        if (_srcSwap.path.length > 1) {
            bool success;
            if (_srcSwap.path[0] == nativeWrap) {
                (success, srcAmtOut) = _trySwapNativeInch(_srcSwap, _amountIn);
            } else {
                (success, srcAmtOut) = _trySwapInch(_srcSwap, _amountIn);
            }
            if (!success) revert("src swap failed");
        }

        require(
            srcAmtOut >= minSwapAmount,
            "amount must be greater than min swap amount"
        );

        _crossChainTransferWithSwapInch(
                _receiver,
                _amountIn,
                chainId,
                _dstChainId,
                _srcSwap,
                _dstSwap,
                _maxBridgeSlippage,
                _nonce,
                _nativeOut,
                _fee,
                srcTokenOut,
                srcAmtOut
        );
    }

    function _directSendInch(
        address _receiver,
        uint256 _amountIn,
        uint64 _chainId,
        SwapInfoInch memory _srcSwap,
        uint64 _nonce,
        address srcTokenOut,
        uint256 srcAmtOut
    ) private {
        // no need to bridge, directly send the tokens to user
        IERC20(srcTokenOut).safeTransfer(_receiver, srcAmtOut);
        // use uint64 for chainid to be consistent with other components in the system
        bytes32 id = keccak256(
            abi.encode(msg.sender, _chainId, _receiver, _nonce, _srcSwap)
        );
        emit DirectSwapInch(
            id,
            _chainId,
            _amountIn,
            _srcSwap.path[0],
            srcAmtOut,
            srcTokenOut
        );
    }

    function _crossChainTransferWithSwapInch(
        address _receiver,
        uint256 _amountIn,
        uint64 _chainId,
        uint64 _dstChainId,
        SwapInfoInch memory _srcSwap,
        SwapInfoDest memory _dstSwap,
        uint32 _maxBridgeSlippage,
        uint64 _nonce,
        bool _nativeOut,
        uint256 _fee,
        address srcTokenOut,
        uint256 srcAmtOut
    ) private {
        require(_dstSwap.path.length > 0, "empty dst swap path");
        bytes memory message = abi.encode(
            SwapRequestDest({
                swap: _dstSwap,
                receiver: msg.sender,
                nonce: _nonce,
                nativeOut: _nativeOut
            })
        );
        bytes32 id = SwapBase._computeSwapRequestId(
            msg.sender,
            _chainId,
            _dstChainId,
            message
        );
        _sendMessageWithTransferInch(
            _receiver,
            srcTokenOut,
            srcAmtOut,
            _dstChainId,
            _nonce,
            _maxBridgeSlippage,
            message,
            _fee
        );
        emit SwapRequestSentInch(id, _dstChainId, _amountIn, _srcSwap.path[0]);
    }

    function _sendMessageWithTransferInch(
        address _receiver,
        address srcTokenOut,
        uint256 srcAmtOut,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxBridgeSlippage,
        bytes memory _message,
        uint256 _fee
    ) private {
        // sends directly to msgBus
        sendMessageWithTransfer(
            _receiver,
            srcTokenOut,
            srcAmtOut * (1 - feeRubic / 1000000),
            _dstChainId,
            _nonce,
            _maxBridgeSlippage,
            _message,
            MessageSenderLib.BridgeType.Liquidity,
            _fee - dstCryptoFee[_dstChainId]
        );
    }

    function _trySwapNativeInch(SwapInfoInch memory _swap, uint256 _amount)
        internal
        returns (bool ok, uint256 amountOut)
    {
        uint256 zero;
        if (!supportedDex[_swap.dex]) {
            return (false, zero);
        }
        IERC20(_swap.path[0]).safeIncreaseAllowance(_swap.dex, _amount);

        IERC20 Transit = IERC20(_swap.path[_swap.path.length - 1]);
        uint256 transitBalanceBefore = Transit.balanceOf(address(this));

        Address.functionCallWithValue(_swap.dex, _swap.data, _amount);

        uint256 balanceDif = Transit.balanceOf(address(this)) -
            transitBalanceBefore;

        if (balanceDif >= _swap.amountOutMinimum) {
            return (true, balanceDif);
        }

        return (false, zero);
    }

    function _trySwapInch(SwapInfoInch memory _swap, uint256 _amount)
        internal
        returns (bool ok, uint256 amountOut)
    {
        uint256 zero;
        if (!supportedDex[_swap.dex]) {
            return (false, zero);
        }
        IERC20(_swap.path[0]).safeIncreaseAllowance(_swap.dex, _amount);

        IERC20 Transit = IERC20(_swap.path[_swap.path.length - 1]);
        uint256 transitBalanceBefore = Transit.balanceOf(address(this));

        Address.functionCall(_swap.dex, _swap.data);

        uint256 balanceDif = Transit.balanceOf(address(this)) -
            transitBalanceBefore;

        if (balanceDif >= _swap.amountOutMinimum) {
            return (true, balanceDif);
        }

        return (false, zero);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import "./SwapBase.sol";

contract BridgeSwap is SwapBase {
    using SafeERC20 for IERC20;

    event BridgeRequestSent(
        bytes32 id,
        uint64 dstChainId,
        uint256 srcAmount,
        address srcToken
    );

    function bridgeWithSwap(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        address _srcBridgeToken,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage,
        uint64 _nonce,
        bool _nativeOut
    ) external payable onlyEOA {
        // require(tokensForBridging.contains(_srcBridgeToken));
        IERC20(_srcBridgeToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amountIn
        );
        _crossChainBridgeWithSwap(
            _receiver,
            _amountIn,
            _dstChainId,
            _srcBridgeToken,
            _dstSwap,
            _maxBridgeSlippage,
            _nonce,
            _nativeOut,
            msg.value
        );
    }

    function _crossChainBridgeWithSwap(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        address _srcBridgeToken,
        SwapInfoDest memory _dstSwap,
        uint32 _maxBridgeSlippage,
        uint64 _nonce,
        bool _nativeOut,
        uint256 _fee
    ) private {
        uint64 _chainId = uint64(block.chainid);
        require(_dstChainId != _chainId, "same chain id");
        require(
            _amountIn >= minSwapAmount,
            "amount must be greater than min swap amount"
        );
        require(_dstSwap.path.length > 0, "empty dst swap path");
        bytes memory message = abi.encode(
            SwapRequestDest({
                swap: _dstSwap,
                receiver: msg.sender,
                nonce: _nonce,
                nativeOut: _nativeOut
            })
        );
        bytes32 id = SwapBase._computeSwapRequestId(
            msg.sender,
            _chainId,
            _dstChainId,
            message
        );
        // bridge the intermediate token to destination chain along with the message
        // NOTE In production, it's better use a per-user per-transaction nonce so that it's less likely transferId collision
        // would happen at Bridge contract. Currently this nonce is a timestamp supplied by frontend
        _sendMessageWithBridge(
            _receiver,
            _srcBridgeToken,
            _amountIn,
            _dstChainId,
            _nonce,
            _maxBridgeSlippage,
            message,
            _fee
        );
        emit BridgeRequestSent(id, _dstChainId, _amountIn, _srcBridgeToken);
    }

    function _sendMessageWithBridge(
        address _receiver,
        address _srcBridgeToken,
        uint256 _amountIn,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxBridgeSlippage,
        bytes memory _message,
        uint256 _fee
    ) private {
        // sends directly to msgBus
        sendMessageWithTransfer(
            _receiver,
            _srcBridgeToken,
            _amountIn * (1 - feeRubic / 1000000),
            _dstChainId,
            _nonce,
            _maxBridgeSlippage,
            _message,
            MessageSenderLib.BridgeType.Liquidity,
            _fee - dstCryptoFee[_dstChainId]
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../framework/MessageBusAddress.sol";
import "../framework/MessageSenderApp.sol";
import "../framework/MessageReceiverApp.sol";

contract SwapBase is MessageSenderApp, MessageReceiverApp {
    mapping(address => bool) supportedDex;
    mapping(uint64 => uint256) public dstCryptoFee;

    // erc20 wrap of gas token of this chain, eg. WETH
    address public nativeWrap;

    uint256 public minSwapAmount;
    uint256 public feeRubic; // 1m is 100%
    uint8 public decimals = 18;

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Not EOA");
        _;
    }

    // ============== struct for V2 like dexes ==============

    struct SwapInfoV2 {
        address dex; // the DEX to use for the swap
        // if this array has only one element, it means no need to swap
        address[] path;
        // the following fields are only needed if path.length > 1
        uint256 deadline; // deadline for the swap
        uint256 amountOutMinimum; // minimum receive amount for the swap
    }

    // ============== struct for V3 like dexes ==============

    struct SwapInfoV3 {
        address dex; // the DEX to use for the swap
        bytes path;
        uint256 deadline;
        uint256 amountOutMinimum;
    }

    // ============== struct for inch swap ==============

    struct SwapInfoInch {
        address dex;
        // path is tokenIn, tokenOut
        address[] path;
        bytes data;
        uint256 amountOutMinimum;
    }

    // ============== struct dstSwap ==============
    // This is needed to make v2 -> SGN -> v3 swaps and etc.

    struct SwapInfoDest {
        address dex; // dex address
        address[] path; // path address for v2 and inch
        bytes pathV3; // path address for v3
        uint256 deadline; // for v2 and v3
        bytes data; // for inch only
        uint256 amountOutMinimum;
        SwapVersion version; // identifies swap type
    }

    struct SwapRequestDest {
        SwapInfoDest swap;
        address receiver; // EOA
        uint64 nonce;
        bool nativeOut;
    }

    enum SwapVersion {
        inch,
        v2,
        v3
    }

    enum SwapStatus {
        Null,
        Succeeded,
        Failed,
        Fallback
    }

    // returns address of first token for V3
    function _getFirstBytes20(bytes memory input)
        internal
        pure
        returns (bytes20 result)
    {
        assembly {
            result := mload(add(input, 32))
        }
    }

    // returns address of tokenOut for V3
    function _getLastBytes20(bytes memory input)
        internal
        pure
        returns (bytes20 result)
    {
        uint256 offset = input.length + 12;
        assembly {
            result := mload(add(input, offset))
        }
    }

    function _computeSwapRequestId(
        address _sender,
        uint64 _srcChainId,
        uint64 _dstChainId,
        bytes memory _message
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_sender, _srcChainId, _dstChainId, _message)
            );
    }

    // This is needed to receive ETH when calling `IWETH.withdraw`
    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

interface IUniswapV2 {
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import "../../safeguard/Ownable.sol";

abstract contract MessageBusAddress is Ownable {
    event MessageBusUpdated(address messageBus);

    address public messageBus;

    function setMessageBus(address _messageBus) public onlyOwner {
        messageBus = _messageBus;
        emit MessageBusUpdated(messageBus);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../libraries/MessageSenderLib.sol";
import "./MessageBusAddress.sol";
import "../messagebus/MessageBus.sol";

abstract contract MessageSenderApp is MessageBusAddress {
    using SafeERC20 for IERC20;

    // ============== Utility functions called by apps ==============

    /**
     * @notice Sends a message to an app on another chain via MessageBus without an associated transfer.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     * @param _fee The fee amount to pay to MessageBus.
     */
    function sendMessage(
        address _receiver,
        uint64 _dstChainId,
        bytes memory _message,
        uint256 _fee
    ) internal {
        MessageSenderLib.sendMessage(
            _receiver,
            _dstChainId,
            _message,
            messageBus,
            _fee
        );
    }

    /**
     * @notice Sends a message to an app on another chain via MessageBus with an associated transfer.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     * Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     * transfer can be refunded. Only applicable to the {BridgeType.Liquidity}.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     * @param _bridgeType One of the {BridgeType} enum.
     * @param _fee The fee amount to pay to MessageBus.
     * @return The transfer ID.
     */
    function sendMessageWithTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        bytes memory _message,
        MessageSenderLib.BridgeType _bridgeType,
        uint256 _fee
    ) internal returns (bytes32) {
        return
            MessageSenderLib.sendMessageWithTransfer(
                _receiver,
                _token,
                _amount,
                _dstChainId,
                _nonce,
                _maxSlippage,
                _message,
                _bridgeType,
                messageBus,
                _fee
            );
    }

    /**
     * @notice Sends a token transfer via a bridge.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     * Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     * transfer can be refunded.
     * @param _bridgeType One of the {BridgeType} enum.
     */
    function sendTokenTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        MessageSenderLib.BridgeType _bridgeType
    ) internal {
        address bridge;
        if (_bridgeType == MessageSenderLib.BridgeType.Liquidity) {
            bridge = MessageBus(messageBus).liquidityBridge();
        } else if (_bridgeType == MessageSenderLib.BridgeType.PegDeposit) {
            bridge = MessageBus(messageBus).pegVault();
        } else if (_bridgeType == MessageSenderLib.BridgeType.PegBurn) {
            bridge = MessageBus(messageBus).pegBridge();
        } else if (_bridgeType == MessageSenderLib.BridgeType.PegDepositV2) {
            bridge = MessageBus(messageBus).pegVaultV2();
        } else if (_bridgeType == MessageSenderLib.BridgeType.PegBurnV2) {
            bridge = MessageBus(messageBus).pegBridgeV2();
        } else {
            revert("bridge type not supported");
        }
        MessageSenderLib.sendTokenTransfer(
            _receiver,
            _token,
            _amount,
            _dstChainId,
            _nonce,
            _maxSlippage,
            _bridgeType,
            bridge
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import "../interfaces/IMessageReceiverApp.sol";
import "./MessageBusAddress.sol";

abstract contract MessageReceiverApp is IMessageReceiverApp, MessageBusAddress {
    modifier onlyMessageBus() {
        require(msg.sender == messageBus, "caller is not message bus");
        _;
    }

    /**
     * @notice Called by MessageBus (MessageBusReceiver) if the process is originated from MessageBus (MessageBusSender)'s
     *         sendMessageWithTransfer it is only called when the tokens are checked to be arrived at this contract's address.
     * @param _sender The address of the source app contract
     * @param _token The address of the token that comes out of the bridge
     * @param _amount The amount of tokens received at this contract through the cross-chain bridge.
     *        the contract that implements this contract can safely assume that the tokens will arrive before this
     *        function is called.
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     */
    function executeMessageWithTransfer(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message
    ) external payable virtual override onlyMessageBus returns (bool) {}

    /**
     * @notice Only called by MessageBus (MessageBusReceiver) if
     *         1. executeMessageWithTransfer reverts, or
     *         2. executeMessageWithTransfer returns false
     * @param _sender The address of the source app contract
     * @param _token The address of the token that comes out of the bridge
     * @param _amount The amount of tokens received at this contract through the cross-chain bridge.
     *        the contract that implements this contract can safely assume that the tokens will arrive before this
     *        function is called.
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     */
    function executeMessageWithTransferFallback(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message
    ) external payable virtual override onlyMessageBus returns (bool) {}

    /**
     * @notice Called by MessageBus (MessageBusReceiver) to process refund of the original transfer from this contract
     * @param _token The token address of the original transfer
     * @param _amount The amount of the original transfer
     * @param _message The same message associated with the original transfer
     */
    function executeMessageWithTransferRefund(
        address _token,
        uint256 _amount,
        bytes calldata _message
    ) external payable virtual override onlyMessageBus returns (bool) {}

    /**
     * @notice Called by MessageBus (MessageBusReceiver)
     * @param _sender The address of the source app contract
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     */
    function executeMessage(
        address _sender,
        uint64 _srcChainId,
        bytes calldata _message
    ) external payable virtual override onlyMessageBus returns (bool) {}
}

// SPDX-License-Identifier: MIT


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

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 *
 * This adds a normal func that setOwner if _owner is address(0). So we can't allow
 * renounceOwnership. So we can support Proxy based upgradable contract
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Only to be called by inherit contracts, in their init func called by Proxy
     * we require _owner == address(0), which is only possible when it's a delegateCall
     * because constructor sets _owner in contract state.
     */
    function initOwner() internal {
        require(_owner == address(0), "owner already set");
        _setOwner(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../interfaces/IBridge.sol";
import "../../interfaces/IOriginalTokenVault.sol";
import "../../interfaces/IOriginalTokenVaultV2.sol";
import "../../interfaces/IPeggedTokenBridge.sol";
import "../../interfaces/IPeggedTokenBridgeV2.sol";
import "../interfaces/IMessageBus.sol";

library MessageSenderLib {
    using SafeERC20 for IERC20;

    enum BridgeType {
        Null,
        Liquidity,
        PegDeposit,
        PegBurn,
        PegDepositV2,
        PegBurnV2
    }

    // ============== Internal library functions called by apps ==============

    /**
     * @notice Sends a message to an app on another chain via MessageBus without an associated transfer.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     * @param _messageBus The address of the MessageBus on this chain.
     * @param _fee The fee amount to pay to MessageBus.
     */
    function sendMessage(
        address _receiver,
        uint64 _dstChainId,
        bytes memory _message,
        address _messageBus,
        uint256 _fee
    ) internal {
        IMessageBus(_messageBus).sendMessage{value: _fee}(
            _receiver,
            _dstChainId,
            _message
        );
    }

    /**
     * @notice Sends a message to an app on another chain via MessageBus with an associated transfer.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     * Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     * transfer can be refunded. Only applicable to the {BridgeType.Liquidity}.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     * @param _bridgeType One of the {BridgeType} enum.
     * @param _messageBus The address of the MessageBus on this chain.
     * @param _fee The fee amount to pay to MessageBus.
     * @return The transfer ID.
     */
    function sendMessageWithTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        bytes memory _message,
        BridgeType _bridgeType,
        address _messageBus,
        uint256 _fee
    ) internal returns (bytes32) {
        if (_bridgeType == BridgeType.Liquidity) {
            return
                sendMessageWithLiquidityBridgeTransfer(
                    _receiver,
                    _token,
                    _amount,
                    _dstChainId,
                    _nonce,
                    _maxSlippage,
                    _message,
                    _messageBus,
                    _fee
                );
        } else if (
            _bridgeType == BridgeType.PegDeposit ||
            _bridgeType == BridgeType.PegDepositV2
        ) {
            return
                sendMessageWithPegVaultDeposit(
                    _bridgeType,
                    _receiver,
                    _token,
                    _amount,
                    _dstChainId,
                    _nonce,
                    _message,
                    _messageBus,
                    _fee
                );
        } else if (
            _bridgeType == BridgeType.PegBurn ||
            _bridgeType == BridgeType.PegBurnV2
        ) {
            return
                sendMessageWithPegBridgeBurn(
                    _bridgeType,
                    _receiver,
                    _token,
                    _amount,
                    _dstChainId,
                    _nonce,
                    _message,
                    _messageBus,
                    _fee
                );
        } else {
            revert("bridge type not supported");
        }
    }

    /**
     * @notice Sends a message to an app on another chain via MessageBus with an associated liquidity bridge transfer.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     * Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     * transfer can be refunded.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     * @param _messageBus The address of the MessageBus on this chain.
     * @param _fee The fee amount to pay to MessageBus.
     * @return The transfer ID.
     */
    function sendMessageWithLiquidityBridgeTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        bytes memory _message,
        address _messageBus,
        uint256 _fee
    ) internal returns (bytes32) {
        address bridge = IMessageBus(_messageBus).liquidityBridge();
        IERC20(_token).safeIncreaseAllowance(bridge, _amount);
        IBridge(bridge).send(
            _receiver,
            _token,
            _amount,
            _dstChainId,
            _nonce,
            _maxSlippage
        );
        bytes32 transferId = keccak256(
            abi.encodePacked(
                address(this),
                _receiver,
                _token,
                _amount,
                _dstChainId,
                _nonce,
                uint64(block.chainid)
            )
        );
        IMessageBus(_messageBus).sendMessageWithTransfer{value: _fee}(
            _receiver,
            _dstChainId,
            bridge,
            transferId,
            _message
        );
        return transferId;
    }

    /**
     * @notice Sends a message to an app on another chain via MessageBus with an associated OriginalTokenVault deposit.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     * @param _messageBus The address of the MessageBus on this chain.
     * @param _fee The fee amount to pay to MessageBus.
     * @return The transfer ID.
     */
    function sendMessageWithPegVaultDeposit(
        BridgeType _bridgeType,
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        bytes memory _message,
        address _messageBus,
        uint256 _fee
    ) internal returns (bytes32) {
        address pegVault;
        if (_bridgeType == BridgeType.PegDeposit) {
            pegVault = IMessageBus(_messageBus).pegVault();
        } else {
            pegVault = IMessageBus(_messageBus).pegVaultV2();
        }
        IERC20(_token).safeIncreaseAllowance(pegVault, _amount);
        bytes32 transferId;
        if (_bridgeType == BridgeType.PegDeposit) {
            IOriginalTokenVault(pegVault).deposit(
                _token,
                _amount,
                _dstChainId,
                _receiver,
                _nonce
            );
            transferId = keccak256(
                abi.encodePacked(
                    address(this),
                    _token,
                    _amount,
                    _dstChainId,
                    _receiver,
                    _nonce,
                    uint64(block.chainid)
                )
            );
        } else {
            transferId = IOriginalTokenVaultV2(pegVault).deposit(
                _token,
                _amount,
                _dstChainId,
                _receiver,
                _nonce
            );
        }
        IMessageBus(_messageBus).sendMessageWithTransfer{value: _fee}(
            _receiver,
            _dstChainId,
            pegVault,
            transferId,
            _message
        );
        return transferId;
    }

    /**
     * @notice Sends a message to an app on another chain via MessageBus with an associated PeggedTokenBridge burn.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     * @param _messageBus The address of the MessageBus on this chain.
     * @param _fee The fee amount to pay to MessageBus.
     * @return The transfer ID.
     */
    function sendMessageWithPegBridgeBurn(
        BridgeType _bridgeType,
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        bytes memory _message,
        address _messageBus,
        uint256 _fee
    ) internal returns (bytes32) {
        address pegBridge;
        if (_bridgeType == BridgeType.PegBurn) {
            pegBridge = IMessageBus(_messageBus).pegBridge();
        } else {
            pegBridge = IMessageBus(_messageBus).pegBridgeV2();
        }
        bytes32 transferId;
        if (_bridgeType == BridgeType.PegBurn) {
            IPeggedTokenBridge(pegBridge).burn(
                _token,
                _amount,
                _receiver,
                _nonce
            );
            transferId = keccak256(
                abi.encodePacked(
                    address(this),
                    _token,
                    _amount,
                    _receiver,
                    _nonce,
                    uint64(block.chainid)
                )
            );
        } else {
            transferId = IPeggedTokenBridgeV2(pegBridge).burn(
                _token,
                _amount,
                _dstChainId,
                _receiver,
                _nonce
            );
        }
        IMessageBus(_messageBus).sendMessageWithTransfer{value: _fee}(
            _receiver,
            _dstChainId,
            pegBridge,
            transferId,
            _message
        );
        return transferId;
    }

    /**
     * @notice Sends a token transfer via a bridge.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     * Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     * transfer can be refunded.
     * @param _bridgeType One of the {BridgeType} enum.
     */
    function sendTokenTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        BridgeType _bridgeType,
        address _bridge
    ) internal {
        if (_bridgeType == BridgeType.Liquidity) {
            IERC20(_token).safeIncreaseAllowance(_bridge, _amount);
            IBridge(_bridge).send(
                _receiver,
                _token,
                _amount,
                _dstChainId,
                _nonce,
                _maxSlippage
            );
        } else if (_bridgeType == BridgeType.PegDeposit) {
            IERC20(_token).safeIncreaseAllowance(_bridge, _amount);
            IOriginalTokenVault(_bridge).deposit(
                _token,
                _amount,
                _dstChainId,
                _receiver,
                _nonce
            );
        } else if (_bridgeType == BridgeType.PegBurn) {
            IPeggedTokenBridge(_bridge).burn(
                _token,
                _amount,
                _receiver,
                _nonce
            );
        } else if (_bridgeType == BridgeType.PegDepositV2) {
            IERC20(_token).safeIncreaseAllowance(_bridge, _amount);
            IOriginalTokenVaultV2(_bridge).deposit(
                _token,
                _amount,
                _dstChainId,
                _receiver,
                _nonce
            );
        } else if (_bridgeType == BridgeType.PegBurnV2) {
            IPeggedTokenBridgeV2(_bridge).burn(
                _token,
                _amount,
                _dstChainId,
                _receiver,
                _nonce
            );
        } else {
            revert("bridge type not supported");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import "./MessageBusSender.sol";
import "./MessageBusReceiver.sol";

contract MessageBus is MessageBusSender, MessageBusReceiver {
    constructor(
        ISigsVerifier _sigsVerifier,
        address _liquidityBridge,
        address _pegBridge,
        address _pegVault,
        address _pegBridgeV2,
        address _pegVaultV2
    )
        MessageBusSender(_sigsVerifier)
        MessageBusReceiver(
            _liquidityBridge,
            _pegBridge,
            _pegVault,
            _pegBridgeV2,
            _pegVaultV2
        )
    {}

    // this is only to be called by Proxy via delegateCall as initOwner will require _owner is 0.
    // so calling init on this contract directly will guarantee to fail
    function init(
        address _liquidityBridge,
        address _pegBridge,
        address _pegVault,
        address _pegBridgeV2,
        address _pegVaultV2
    ) external {
        // MUST manually call ownable init and must only call once
        initOwner();
        // we don't need sender init as _sigsVerifier is immutable so already in the deployed code
        initReceiver(
            _liquidityBridge,
            _pegBridge,
            _pegVault,
            _pegBridgeV2,
            _pegVaultV2
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IBridge {
    function send(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external;

    function relay(
        bytes calldata _relayRequest,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    function transfers(bytes32 transferId) external view returns (bool);

    function withdraws(bytes32 withdrawId) external view returns (bool);

    /**
     * @notice Verifies that a message is signed by a quorum among the signers.
     * @param _msg signed message
     * @param _sigs list of signatures sorted by signer addresses in ascending order
     * @param _signers sorted list of current signers
     * @param _powers powers of current signers
     */
    function verifySigs(
        bytes memory _msg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external view;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IOriginalTokenVault {
    /**
     * @notice Lock original tokens to trigger mint at a remote chain's PeggedTokenBridge
     * @param _token local token address
     * @param _amount locked token amount
     * @param _mintChainId destination chainId to mint tokens
     * @param _mintAccount destination account to receive minted tokens
     * @param _nonce user input to guarantee unique depositId
     */
    function deposit(
        address _token,
        uint256 _amount,
        uint64 _mintChainId,
        address _mintAccount,
        uint64 _nonce
    ) external;

    function records(bytes32 recordId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IOriginalTokenVaultV2 {
    /**
     * @notice Lock original tokens to trigger mint at a remote chain's PeggedTokenBridge
     * @param _token local token address
     * @param _amount locked token amount
     * @param _mintChainId destination chainId to mint tokens
     * @param _mintAccount destination account to receive minted tokens
     * @param _nonce user input to guarantee unique depositId
     */
    function deposit(
        address _token,
        uint256 _amount,
        uint64 _mintChainId,
        address _mintAccount,
        uint64 _nonce
    ) external returns (bytes32);

    function records(bytes32 recordId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IPeggedTokenBridge {
    /**
     * @notice Burn tokens to trigger withdrawal at a remote chain's OriginalTokenVault
     * @param _token local token address
     * @param _amount locked token amount
     * @param _withdrawAccount account who withdraw original tokens on the remote chain
     * @param _nonce user input to guarantee unique depositId
     */
    function burn(
        address _token,
        uint256 _amount,
        address _withdrawAccount,
        uint64 _nonce
    ) external;

    function records(bytes32 recordId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IPeggedTokenBridgeV2 {
    /**
     * @notice Burn pegged tokens to trigger a cross-chain withdrawal of the original tokens at a remote chain's
     * OriginalTokenVault, or mint at another remote chain
     * @param _token The pegged token address.
     * @param _amount The amount to burn.
     * @param _toChainId If zero, withdraw from original vault; otherwise, the remote chain to mint tokens.
     * @param _toAccount The account to receive tokens on the remote chain
     * @param _nonce A number to guarantee unique depositId. Can be timestamp in practice.
     */
    function burn(
        address _token,
        uint256 _amount,
        uint64 _toChainId,
        address _toAccount,
        uint64 _nonce
    ) external returns (bytes32);

    function records(bytes32 recordId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IMessageBus {
    enum TransferType {
        Null,
        LqSend, // send through liquidity bridge
        LqWithdraw, // withdraw from liquidity bridge
        PegMint, // mint through pegged token bridge
        PegWithdraw // withdraw from original token vault
    }

    struct TransferInfo {
        TransferType t;
        address sender;
        address receiver;
        address token;
        uint256 amount;
        uint64 seqnum; // only needed for LqWithdraw
        uint64 srcChainId;
        bytes32 refId;
    }

    struct RouteInfo {
        address sender;
        address receiver;
        uint64 srcChainId;
    }

    function liquidityBridge() external view returns (address);

    function pegBridge() external view returns (address);

    function pegBridgeV2() external view returns (address);

    function pegVault() external view returns (address);

    function pegVaultV2() external view returns (address);

    /**
     * @notice Calculates the required fee for the message.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     @ @return The required fee.
     */
    function calcFee(bytes calldata _message) external view returns (uint256);

    /**
     * @notice Sends a message to an app on another chain via MessageBus without an associated transfer.
     * A fee is charged in the native gas token.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     */
    function sendMessage(
        address _receiver,
        uint256 _dstChainId,
        bytes calldata _message
    ) external payable;

    /**
     * @notice Sends a message associated with a transfer to an app on another chain via MessageBus without an associated transfer.
     * A fee is charged in the native token.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _srcBridge The bridge contract to send the transfer with.
     * @param _srcTransferId The transfer ID.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     */
    function sendMessageWithTransfer(
        address _receiver,
        uint256 _dstChainId,
        address _srcBridge,
        bytes32 _srcTransferId,
        bytes calldata _message
    ) external payable;

    /**
     * @notice Withdraws message fee in the form of native gas token.
     * @param _account The address receiving the fee.
     * @param _cumulativeFee The cumulative fee credited to the account. Tracked by SGN.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A withdrawal must be
     * signed-off by +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function withdrawFee(
        address _account,
        uint256 _cumulativeFee,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    /**
     * @notice Execute a message with a successful transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _transfer The transfer info.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessageWithTransfer(
        bytes calldata _message,
        TransferInfo calldata _transfer,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable;

    /**
     * @notice Execute a message with a refunded transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _transfer The transfer info.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessageWithTransferRefund(
        bytes calldata _message, // the same message associated with the original transfer
        TransferInfo calldata _transfer,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable;

    /**
     * @notice Execute a message not associated with a transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessage(
        bytes calldata _message,
        RouteInfo calldata _route,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import "../../safeguard/Ownable.sol";
import "../../interfaces/ISigsVerifier.sol";

contract MessageBusSender is Ownable {
    ISigsVerifier public immutable sigsVerifier;

    uint256 public feeBase;
    uint256 public feePerByte;
    mapping(address => uint256) public withdrawnFees;

    event Message(
        address indexed sender,
        address receiver,
        uint256 dstChainId,
        bytes message,
        uint256 fee
    );

    event MessageWithTransfer(
        address indexed sender,
        address receiver,
        uint256 dstChainId,
        address bridge,
        bytes32 srcTransferId,
        bytes message,
        uint256 fee
    );

    event FeeBaseUpdated(uint256 feeBase);
    event FeePerByteUpdated(uint256 feePerByte);

    constructor(ISigsVerifier _sigsVerifier) {
        sigsVerifier = _sigsVerifier;
    }

    /**
     * @notice Sends a message to an app on another chain via MessageBus without an associated transfer.
     * A fee is charged in the native gas token.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     */
    function sendMessage(
        address _receiver,
        uint256 _dstChainId,
        bytes calldata _message
    ) external payable {
        uint256 minFee = calcFee(_message);
        require(msg.value >= minFee, "Insufficient fee");
        emit Message(msg.sender, _receiver, _dstChainId, _message, msg.value);
    }

    /**
     * @notice Sends a message associated with a transfer to an app on another chain via MessageBus without an associated transfer.
     * A fee is charged in the native token.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _srcBridge The bridge contract to send the transfer with.
     * @param _srcTransferId The transfer ID.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     */
    function sendMessageWithTransfer(
        address _receiver,
        uint256 _dstChainId,
        address _srcBridge,
        bytes32 _srcTransferId,
        bytes calldata _message
    ) external payable {
        uint256 minFee = calcFee(_message);
        require(msg.value >= minFee, "Insufficient fee");
        // SGN needs to verify
        // 1. msg.sender matches sender of the src transfer
        // 2. dstChainId matches dstChainId of the src transfer
        // 3. bridge is either liquidity bridge, peg src vault, or peg dst bridge
        emit MessageWithTransfer(
            msg.sender,
            _receiver,
            _dstChainId,
            _srcBridge,
            _srcTransferId,
            _message,
            msg.value
        );
    }

    /**
     * @notice Withdraws message fee in the form of native gas token.
     * @param _account The address receiving the fee.
     * @param _cumulativeFee The cumulative fee credited to the account. Tracked by SGN.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A withdrawal must be
     * signed-off by +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function withdrawFee(
        address _account,
        uint256 _cumulativeFee,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external {
        bytes32 domain = keccak256(
            abi.encodePacked(block.chainid, address(this), "withdrawFee")
        );
        sigsVerifier.verifySigs(
            abi.encodePacked(domain, _account, _cumulativeFee),
            _sigs,
            _signers,
            _powers
        );
        uint256 amount = _cumulativeFee - withdrawnFees[_account];
        require(amount > 0, "No new amount to withdraw");
        withdrawnFees[_account] = _cumulativeFee;
        (bool sent, ) = _account.call{value: amount, gas: 50000}("");
        require(sent, "failed to withdraw fee");
    }

    /**
     * @notice Calculates the required fee for the message.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     @ @return The required fee.
     */
    function calcFee(bytes calldata _message) public view returns (uint256) {
        return feeBase + _message.length * feePerByte;
    }

    // -------------------- Admin --------------------

    function setFeePerByte(uint256 _fee) external onlyOwner {
        feePerByte = _fee;
        emit FeePerByteUpdated(feePerByte);
    }

    function setFeeBase(uint256 _fee) external onlyOwner {
        feeBase = _fee;
        emit FeeBaseUpdated(feeBase);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import "../../interfaces/IBridge.sol";
import "../../interfaces/IOriginalTokenVault.sol";
import "../../interfaces/IOriginalTokenVaultV2.sol";
import "../../interfaces/IPeggedTokenBridge.sol";
import "../../interfaces/IPeggedTokenBridgeV2.sol";
import "../interfaces/IMessageReceiverApp.sol";
import "../../safeguard/Ownable.sol";

contract MessageBusReceiver is Ownable {
    enum TransferType {
        Null,
        LqSend, // send through liquidity bridge
        LqWithdraw, // withdraw from liquidity bridge
        PegMint, // mint through pegged token bridge
        PegWithdraw, // withdraw from original token vault
        PegMintV2, // mint through pegged token bridge v2
        PegWithdrawV2 // withdraw from original token vault v2
    }

    struct TransferInfo {
        TransferType t;
        address sender;
        address receiver;
        address token;
        uint256 amount;
        uint64 seqnum; // only needed for LqWithdraw
        uint64 srcChainId;
        bytes32 refId;
    }

    struct RouteInfo {
        address sender;
        address receiver;
        uint64 srcChainId;
    }

    enum TxStatus {
        Null,
        Success,
        Fail,
        Fallback,
        Pending
    }
    mapping(bytes32 => TxStatus) public executedMessages;

    address public liquidityBridge; // liquidity bridge address
    address public pegBridge; // peg bridge address
    address public pegVault; // peg original vault address
    address public pegBridgeV2; // peg bridge address
    address public pegVaultV2; // peg original vault address

    enum MsgType {
        MessageWithTransfer,
        MessageOnly
    }
    event Executed(MsgType msgType, bytes32 id, TxStatus status);
    event LiquidityBridgeUpdated(address liquidityBridge);
    event PegBridgeUpdated(address pegBridge);
    event PegVaultUpdated(address pegVault);
    event PegBridgeV2Updated(address pegBridgeV2);
    event PegVaultV2Updated(address pegVaultV2);

    constructor(
        address _liquidityBridge,
        address _pegBridge,
        address _pegVault,
        address _pegBridgeV2,
        address _pegVaultV2
    ) {
        liquidityBridge = _liquidityBridge;
        pegBridge = _pegBridge;
        pegVault = _pegVault;
        pegBridgeV2 = _pegBridgeV2;
        pegVaultV2 = _pegVaultV2;
    }

    function initReceiver(
        address _liquidityBridge,
        address _pegBridge,
        address _pegVault,
        address _pegBridgeV2,
        address _pegVaultV2
    ) internal {
        require(liquidityBridge == address(0), "liquidityBridge already set");
        liquidityBridge = _liquidityBridge;
        pegBridge = _pegBridge;
        pegVault = _pegVault;
        pegBridgeV2 = _pegBridgeV2;
        pegVaultV2 = _pegVaultV2;
    }

    // ============== functions called by executor ==============

    /**
     * @notice Execute a message with a successful transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _transfer The transfer info.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessageWithTransfer(
        bytes calldata _message,
        TransferInfo calldata _transfer,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable {
        // For message with token transfer, message Id is computed through transfer info
        // in order to guarantee that each transfer can only be used once.
        // This also indicates that different transfers can carry the exact same messages.
        bytes32 messageId = verifyTransfer(_transfer);
        require(
            executedMessages[messageId] == TxStatus.Null,
            "transfer already executed"
        );
        executedMessages[messageId] = TxStatus.Pending;

        bytes32 domain = keccak256(
            abi.encodePacked(
                block.chainid,
                address(this),
                "MessageWithTransfer"
            )
        );
        IBridge(liquidityBridge).verifySigs(
            abi.encodePacked(domain, messageId, _message),
            _sigs,
            _signers,
            _powers
        );
        TxStatus status;
        bool success = executeMessageWithTransfer(_transfer, _message);
        if (success) {
            status = TxStatus.Success;
        } else {
            success = executeMessageWithTransferFallback(_transfer, _message);
            if (success) {
                status = TxStatus.Fallback;
            } else {
                status = TxStatus.Fail;
            }
        }
        executedMessages[messageId] = status;
        emit Executed(MsgType.MessageWithTransfer, messageId, status);
    }

    /**
     * @notice Execute a message with a refunded transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _transfer The transfer info.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessageWithTransferRefund(
        bytes calldata _message, // the same message associated with the original transfer
        TransferInfo calldata _transfer,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable {
        // similar to executeMessageWithTransfer
        bytes32 messageId = verifyTransfer(_transfer);
        require(
            executedMessages[messageId] == TxStatus.Null,
            "transfer already executed"
        );
        executedMessages[messageId] = TxStatus.Pending;

        bytes32 domain = keccak256(
            abi.encodePacked(
                block.chainid,
                address(this),
                "MessageWithTransferRefund"
            )
        );
        IBridge(liquidityBridge).verifySigs(
            abi.encodePacked(domain, messageId, _message),
            _sigs,
            _signers,
            _powers
        );
        TxStatus status;
        bool success = executeMessageWithTransferRefund(_transfer, _message);
        if (success) {
            status = TxStatus.Success;
        } else {
            status = TxStatus.Fail;
        }
        executedMessages[messageId] = status;
        emit Executed(MsgType.MessageWithTransfer, messageId, status);
    }

    /**
     * @notice Execute a message not associated with a transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessage(
        bytes calldata _message,
        RouteInfo calldata _route,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable {
        // For message without associated token transfer, message Id is computed through message info,
        // in order to guarantee that each message can only be applied once
        bytes32 messageId = computeMessageOnlyId(_route, _message);
        require(
            executedMessages[messageId] == TxStatus.Null,
            "message already executed"
        );
        executedMessages[messageId] = TxStatus.Pending;

        bytes32 domain = keccak256(
            abi.encodePacked(block.chainid, address(this), "Message")
        );
        IBridge(liquidityBridge).verifySigs(
            abi.encodePacked(domain, messageId),
            _sigs,
            _signers,
            _powers
        );
        TxStatus status;
        bool success = executeMessage(_route, _message);
        if (success) {
            status = TxStatus.Success;
        } else {
            status = TxStatus.Fail;
        }
        executedMessages[messageId] = status;
        emit Executed(MsgType.MessageOnly, messageId, status);
    }

    // ================= utils (to avoid stack too deep) =================

    function executeMessageWithTransfer(
        TransferInfo calldata _transfer,
        bytes calldata _message
    ) private returns (bool) {
        (bool ok, bytes memory res) = address(_transfer.receiver).call{
            value: msg.value
        }(
            abi.encodeWithSelector(
                IMessageReceiverApp.executeMessageWithTransfer.selector,
                _transfer.sender,
                _transfer.token,
                _transfer.amount,
                _transfer.srcChainId,
                _message
            )
        );
        if (ok) {
            bool success = abi.decode((res), (bool));
            return success;
        }
        return false;
    }

    function executeMessageWithTransferFallback(
        TransferInfo calldata _transfer,
        bytes calldata _message
    ) private returns (bool) {
        (bool ok, bytes memory res) = address(_transfer.receiver).call{
            value: msg.value
        }(
            abi.encodeWithSelector(
                IMessageReceiverApp.executeMessageWithTransferFallback.selector,
                _transfer.sender,
                _transfer.token,
                _transfer.amount,
                _transfer.srcChainId,
                _message
            )
        );
        if (ok) {
            bool success = abi.decode((res), (bool));
            return success;
        }
        return false;
    }

    function executeMessageWithTransferRefund(
        TransferInfo calldata _transfer,
        bytes calldata _message
    ) private returns (bool) {
        (bool ok, bytes memory res) = address(_transfer.receiver).call{
            value: msg.value
        }(
            abi.encodeWithSelector(
                IMessageReceiverApp.executeMessageWithTransferRefund.selector,
                _transfer.token,
                _transfer.amount,
                _message
            )
        );
        if (ok) {
            bool success = abi.decode((res), (bool));
            return success;
        }
        return false;
    }

    function verifyTransfer(TransferInfo calldata _transfer)
        private
        view
        returns (bytes32)
    {
        bytes32 transferId;
        address bridgeAddr;
        if (_transfer.t == TransferType.LqSend) {
            transferId = keccak256(
                abi.encodePacked(
                    _transfer.sender,
                    _transfer.receiver,
                    _transfer.token,
                    _transfer.amount,
                    _transfer.srcChainId,
                    uint64(block.chainid),
                    _transfer.refId
                )
            );
            bridgeAddr = liquidityBridge;
            require(
                IBridge(bridgeAddr).transfers(transferId) == true,
                "bridge relay not exist"
            );
        } else if (_transfer.t == TransferType.LqWithdraw) {
            transferId = keccak256(
                abi.encodePacked(
                    uint64(block.chainid),
                    _transfer.seqnum,
                    _transfer.receiver,
                    _transfer.token,
                    _transfer.amount
                )
            );
            bridgeAddr = liquidityBridge;
            require(
                IBridge(bridgeAddr).withdraws(transferId) == true,
                "bridge withdraw not exist"
            );
        } else if (
            _transfer.t == TransferType.PegMint ||
            _transfer.t == TransferType.PegWithdraw
        ) {
            transferId = keccak256(
                abi.encodePacked(
                    _transfer.receiver,
                    _transfer.token,
                    _transfer.amount,
                    _transfer.sender,
                    _transfer.srcChainId,
                    _transfer.refId
                )
            );
            if (_transfer.t == TransferType.PegMint) {
                bridgeAddr = pegBridge;
                require(
                    IPeggedTokenBridge(bridgeAddr).records(transferId) == true,
                    "mint record not exist"
                );
            } else {
                // _transfer.t == TransferType.PegWithdraw
                bridgeAddr = pegVault;
                require(
                    IOriginalTokenVault(bridgeAddr).records(transferId) == true,
                    "withdraw record not exist"
                );
            }
        } else if (
            _transfer.t == TransferType.PegMintV2 ||
            _transfer.t == TransferType.PegWithdrawV2
        ) {
            if (_transfer.t == TransferType.PegMintV2) {
                bridgeAddr = pegBridgeV2;
            } else {
                // TransferType.PegWithdrawV2
                bridgeAddr = pegVaultV2;
            }
            transferId = keccak256(
                abi.encodePacked(
                    _transfer.receiver,
                    _transfer.token,
                    _transfer.amount,
                    _transfer.sender,
                    _transfer.srcChainId,
                    _transfer.refId,
                    bridgeAddr
                )
            );
            if (_transfer.t == TransferType.PegMintV2) {
                require(
                    IPeggedTokenBridgeV2(bridgeAddr).records(transferId) ==
                        true,
                    "mint record not exist"
                );
            } else {
                // TransferType.PegWithdrawV2
                require(
                    IOriginalTokenVaultV2(bridgeAddr).records(transferId) ==
                        true,
                    "withdraw record not exist"
                );
            }
        }
        return
            keccak256(
                abi.encodePacked(
                    MsgType.MessageWithTransfer,
                    bridgeAddr,
                    transferId
                )
            );
    }

    function computeMessageOnlyId(
        RouteInfo calldata _route,
        bytes calldata _message
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    MsgType.MessageOnly,
                    _route.sender,
                    _route.receiver,
                    _route.srcChainId,
                    _message
                )
            );
    }

    function executeMessage(RouteInfo calldata _route, bytes calldata _message)
        private
        returns (bool)
    {
        (bool ok, bytes memory res) = address(_route.receiver).call{
            value: msg.value
        }(
            abi.encodeWithSelector(
                IMessageReceiverApp.executeMessage.selector,
                _route.sender,
                _route.srcChainId,
                _message
            )
        );
        if (ok) {
            bool success = abi.decode((res), (bool));
            return success;
        }
        return false;
    }

    // ================= contract addr config =================

    function setLiquidityBridge(address _addr) public onlyOwner {
        require(_addr != address(0), "invalid address");
        liquidityBridge = _addr;
        emit LiquidityBridgeUpdated(liquidityBridge);
    }

    function setPegBridge(address _addr) public onlyOwner {
        require(_addr != address(0), "invalid address");
        pegBridge = _addr;
        emit PegBridgeUpdated(pegBridge);
    }

    function setPegVault(address _addr) public onlyOwner {
        require(_addr != address(0), "invalid address");
        pegVault = _addr;
        emit PegVaultUpdated(pegVault);
    }

    function setPegBridgeV2(address _addr) public onlyOwner {
        require(_addr != address(0), "invalid address");
        pegBridgeV2 = _addr;
        emit PegBridgeV2Updated(pegBridgeV2);
    }

    function setPegVaultV2(address _addr) public onlyOwner {
        require(_addr != address(0), "invalid address");
        pegVaultV2 = _addr;
        emit PegVaultV2Updated(pegVaultV2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

interface ISigsVerifier {
    /**
     * @notice Verifies that a message is signed by a quorum among the signers.
     * @param _msg signed message
     * @param _sigs list of signatures sorted by signer addresses in ascending order
     * @param _signers sorted list of current signers
     * @param _powers powers of current signers
     */
    function verifySigs(
        bytes memory _msg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external view;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IMessageReceiverApp {
    /**
     * @notice Called by MessageBus (MessageBusReceiver) if the process is originated from MessageBus (MessageBusSender)'s
     *         sendMessageWithTransfer it is only called when the tokens are checked to be arrived at this contract's address.
     * @param _sender The address of the source app contract
     * @param _token The address of the token that comes out of the bridge
     * @param _amount The amount of tokens received at this contract through the cross-chain bridge.
     *        the contract that implements this contract can safely assume that the tokens will arrive before this
     *        function is called.
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     */
    function executeMessageWithTransfer(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message
    ) external payable returns (bool);

    /**
     * @notice Only called by MessageBus (MessageBusReceiver) if
     *         1. executeMessageWithTransfer reverts, or
     *         2. executeMessageWithTransfer returns false
     * @param _sender The address of the source app contract
     * @param _token The address of the token that comes out of the bridge
     * @param _amount The amount of tokens received at this contract through the cross-chain bridge.
     *        the contract that implements this contract can safely assume that the tokens will arrive before this
     *        function is called.
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     */
    function executeMessageWithTransferFallback(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message
    ) external payable returns (bool);

    /**
     * @notice Called by MessageBus (MessageBusReceiver) to process refund of the original transfer from this contract
     * @param _token The token address of the original transfer
     * @param _amount The amount of the original transfer
     * @param _message The same message associated with the original transfer
     */
    function executeMessageWithTransferRefund(
        address _token,
        uint256 _amount,
        bytes calldata _message
    ) external payable returns (bool);

    /**
     * @notice Called by MessageBus (MessageBusReceiver)
     * @param _sender The address of the source app contract
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     */
    function executeMessage(
        address _sender,
        uint64 _srcChainId,
        bytes calldata _message
    ) external payable returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap Algebra
interface IUniswapRouterV3 {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    function WETH9() external view returns (address);

    function WNativeToken() external view returns (address);

    function refundETH() external payable;

    function refundNativeToken() external payable;

    function unwrapWETH9(uint256 amountMinimum, address recipient)
        external
        payable;

    function unwrapWNativeToken(uint256 amountMinimum, address recipient)
        external
        payable;
}