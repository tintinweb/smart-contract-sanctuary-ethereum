// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma abicoder v2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IUniswapV2Router02.sol";
import "./IStargateReceiver.sol";
import "./IStargateRouter.sol";
import "./IWETH.sol";
import "./IFeeRegistry.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

contract OswapCoreV1 is Ownable, ReentrancyGuard, Pausable, IStargateReceiver {
    struct ERC20Infos {
        address[] tokenAddrs;
        uint256[] amounts;
    }

    struct OrderDetails {
        uint16 marketId;
        address targetToken;
        uint256 value;
        bytes orderData;
    }

    struct PaymentInfo {
        uint256 amountOutMinDest;
        address bridgeToken;
        uint256 srcPoolId;
        uint256 dstPoolId;
    }

    struct MarketInfo {
        address proxy;
        bool isLib;
        bool isActive;
    }

    using SafeMath for uint256;
    address public WETH;
    address public feeRecipient = 0xF28Ef4580f514Eca5c1B75d0Db9b0cB6d62d83ef;
    //1-openseav1 2-seaport 3-x2y2 4-looksrare
    MarketInfo[] public markets;
    address public swapRouter;
    address public stargateRouter;
    address public feeRegistry = 0xf718A7bd7CCa34843B5944D03f94405c0cFBD4Df;
    address public proxy;

    address public constant OUT_TO_NATIVE =
        0x0000000000000000000000000000000000000000;

    event ReceivedOnDestination(
        uint16 _chainId,
        bytes _srcAddress,
        uint256 _nonce,
        address token,
        uint256 amountLD
    );
    event SwapedOnDestination(bool _success, address _token, uint256 _amount);
    event SetTrustedRemote(uint16 _srcChainId, bytes _srcAddress);
    event TradeOnDestionation(
        bool _success,
        address targetToken,
        uint256 value
    );
    event ReturnDust(
        bool _success,
        address _to,
        address _token,
        uint256 _amount
    );

    constructor(
        address _weth,
        address _stargateRouter,
        address _swapRouter
    ) {
        WETH = _weth;
        swapRouter = _swapRouter;
        stargateRouter = _stargateRouter;
    }

    function crossBuy(
        uint16 dstChainId,
        ERC20Infos memory sourceTokenDetails,
        PaymentInfo memory payInfo,
        OrderDetails[] memory _orderDetails,
        address to,
        address destAddress,
        uint256 deadline
    ) external payable whenNotPaused {
        uint256 bridgeAmount;
        uint256 value = msg.value;
        _erc20TranasferHelper(sourceTokenDetails);
        {
            for (uint256 i = 0; i < sourceTokenDetails.tokenAddrs.length; i++) {
                address[] memory path = new address[](2);
                path[0] = sourceTokenDetails.tokenAddrs[i] == address(0x0)
                    ? IUniswapV2Router02(swapRouter).WETH()
                    : sourceTokenDetails.tokenAddrs[i];
                path[1] = payInfo.bridgeToken;
                uint256[] memory amounts;
                if (sourceTokenDetails.tokenAddrs[i] == payInfo.bridgeToken) {
                    bridgeAmount += sourceTokenDetails.amounts[i];
                    continue;
                }
                if (sourceTokenDetails.tokenAddrs[i] == address(0x0)) {
                    amounts = IUniswapV2Router02(swapRouter)
                        .swapExactETHForTokens{
                        value: sourceTokenDetails.amounts[i]
                    }(0, path, address(this), deadline);
                    value -= sourceTokenDetails.amounts[i];
                } else {
                    IERC20(sourceTokenDetails.tokenAddrs[i]).approve(
                        swapRouter,
                        sourceTokenDetails.amounts[i]
                    );
                    amounts = IUniswapV2Router02(swapRouter)
                        .swapExactTokensForTokens(
                            sourceTokenDetails.amounts[i],
                            0,
                            path,
                            address(this),
                            deadline
                        );
                }
                bridgeAmount += amounts[1];
            }
        }
        IERC20(payInfo.bridgeToken).approve(stargateRouter, bridgeAmount);
        require(
            bridgeAmount >= payInfo.amountOutMinDest,
            "Bridge amount not enough"
        );
        bytes memory data;
        {
            data = abi.encode(to, _orderDetails);
        }
        IStargateRouter(stargateRouter).swap{value: value}(
            dstChainId,
            payInfo.srcPoolId,
            payInfo.dstPoolId,
            payable(msg.sender),
            bridgeAmount,
            0,
            IStargateRouter.lzTxObj(500000, 0, "0x"),
            abi.encodePacked(destAddress),
            data
        );
    }

    function localBuyWithERC20(
        ERC20Infos memory sourceTokenDetails,
        OrderDetails[] memory _orderDetails
    ) external payable nonReentrant whenNotPaused {
        _erc20TranasferHelper(sourceTokenDetails);
        _swapHelper(sourceTokenDetails);
        uint256 total = _localTrade(_orderDetails);
        _collectLocalFee(msg.sender, total);
        _returnLocalDust(msg.sender, sourceTokenDetails);
    }

    function localBuyWithETH(OrderDetails[] memory _orderDetails)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        uint256 total = _localTrade(_orderDetails);
        _collectLocalFee(msg.sender, total);
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(
                    gas(),
                    caller(),
                    selfbalance(),
                    0,
                    0,
                    0,
                    0
                )
            }
        }
    }

    function _collectLocalFee(address _from, uint256 _amount) internal {
        uint256 _fee = _quoteFee(_amount, _from);
        if (_fee > 0) {
            _fee = _fee > address(this).balance ? address(this).balance : _fee;
            _transferEth(feeRecipient, _fee);
        }
    }

    function _erc20TranasferHelper(ERC20Infos memory erc20Infos) internal {
        for (uint256 i = 0; i < erc20Infos.tokenAddrs.length; i++) {
            (bool success, ) = erc20Infos.tokenAddrs[i].call(
                abi.encodeWithSelector(
                    0x23b872dd,
                    msg.sender,
                    address(this),
                    erc20Infos.amounts[i]
                )
            );
            _checkCallResult(success);
        }
    }

    function _swapHelper(ERC20Infos memory sourceTokenDetails) internal {
        for (uint256 i = 0; i < sourceTokenDetails.tokenAddrs.length; i++) {
            IERC20(sourceTokenDetails.tokenAddrs[i]).approve(
                swapRouter,
                sourceTokenDetails.amounts[i]
            );
            address[] memory path = new address[](2);
            path[0] = sourceTokenDetails.tokenAddrs[i];
            path[1] = IUniswapV2Router02(swapRouter).WETH();
            IUniswapV2Router02(swapRouter).swapExactTokensForETH(
                sourceTokenDetails.amounts[i],
                0, // for test
                path,
                address(this),
                block.timestamp + 900
            );
        }
    }

    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external override {
        require(
            msg.sender == address(stargateRouter),
            "only stargate router can call sgReceive!"
        );
        (address _toAddr, OrderDetails[] memory _orderDetails) = abi.decode(
            payload,
            (address, OrderDetails[])
        );
        emit ReceivedOnDestination(
            _chainId,
            _srcAddress,
            _nonce,
            _token,
            amountLD
        );
        IERC20(_token).approve(swapRouter, amountLD);
        uint256 _toBalancePreTransferOut = address(this).balance;
        uint256 swapEthAmount = 0;

        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = IUniswapV2Router02(swapRouter).WETH();
        try
            IUniswapV2Router02(swapRouter).swapExactTokensForETH(
                amountLD,
                0,
                path,
                address(this),
                block.timestamp + 900
            )
        {
            emit SwapedOnDestination(
                true,
                OUT_TO_NATIVE,
                _toAddr.balance.sub(_toBalancePreTransferOut)
            );
        } catch {
            IERC20(_token).transfer(_toAddr, amountLD);
            emit SwapedOnDestination(
                false,
                OUT_TO_NATIVE,
                _toAddr.balance.sub(_toBalancePreTransferOut)
            );
        }
        swapEthAmount += address(this).balance.sub(_toBalancePreTransferOut);

        uint256 total = _trade(_orderDetails);
        _collectLocalFee(_toAddr, total);
        _returnDust(_toAddr, _token);
    }

    function _trade(OrderDetails[] memory _orderDetails)
        internal
        returns (uint256 _total)
    {
        uint256 total = 0;
        for (uint256 i = 0; i < _orderDetails.length; i++) {
            MarketInfo memory marketInfo = markets[_orderDetails[i].marketId];
            require(marketInfo.isActive, "Market not support");
            (bool _success, ) = marketInfo.isLib
                ? marketInfo.proxy.delegatecall(_orderDetails[i].orderData)
                : marketInfo.proxy.call{value: _orderDetails[i].value}(
                    _orderDetails[i].orderData
                );
            if (_success) {
                total += _orderDetails[i].value;
                emit TradeOnDestionation(
                    true,
                    _orderDetails[i].targetToken,
                    _orderDetails[i].value
                );
            } else {
                emit TradeOnDestionation(
                    false,
                    _orderDetails[i].targetToken,
                    _orderDetails[i].value
                );
            }
        }
        return total;
    }

    function _localTrade(OrderDetails[] memory _orderDetails)
        internal
        returns (uint256 _total)
    {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < _orderDetails.length; i++) {
            MarketInfo memory marketInfo = markets[_orderDetails[i].marketId];
            require(marketInfo.isActive, "Market not support");
            (bool _success, ) = marketInfo.isLib
                ? marketInfo.proxy.delegatecall(_orderDetails[i].orderData)
                : marketInfo.proxy.call{value: _orderDetails[i].value}(
                    _orderDetails[i].orderData
                );
            _checkCallResult(_success);
            totalValue += _orderDetails[i].value;
        }
        return totalValue;
    }

    function _returnDust(address _toAddr, address _token) internal {
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(
                    gas(),
                    _toAddr,
                    selfbalance(),
                    0,
                    0,
                    0,
                    0
                )
            }
        }
        uint256 bridgeRemain = IERC20(_token).balanceOf(address(this));
        if (bridgeRemain > 0) {
            (bool _success, ) = _token.call(
                abi.encodeWithSelector(0xa9059cbb, _toAddr, bridgeRemain)
            );
            emit ReturnDust(_success, _toAddr, _token, bridgeRemain);
        }
    }

    function _returnLocalDust(
        address _toAddr,
        ERC20Infos memory targeTokenDetails
    ) internal {
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(
                    gas(),
                    _toAddr,
                    selfbalance(),
                    0,
                    0,
                    0,
                    0
                )
            }
        }
        // return remaining tokens (if any)
        for (uint256 i = 0; i < targeTokenDetails.tokenAddrs.length; i++) {
            if (targeTokenDetails.tokenAddrs[i] != address(0x0)) {
                uint256 amount = IERC20(targeTokenDetails.tokenAddrs[i])
                    .balanceOf(address(this));
                if (amount > 0) {
                    (bool _success, ) = targeTokenDetails.tokenAddrs[i].call(
                        abi.encodeWithSelector(0xa9059cbb, _toAddr, amount)
                    );
                    emit ReturnDust(
                        _success,
                        _toAddr,
                        targeTokenDetails.tokenAddrs[i],
                        amount
                    );
                }
            }
        }
    }

    function _checkCallResult(bool _success) internal pure {
        if (!_success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function _quoteFee(uint256 amount, address _from)
        internal
        view
        returns (uint256 _fee)
    {
        if (feeRegistry == address(0x0)) {
            return 0;
        }
        return IFeeRegistry(feeRegistry).getFee(amount, _from);
    }

    function supportsInterface(bytes4 interfaceId)
        external
        view
        virtual
        returns (bool)
    {
        return interfaceId == this.supportsInterface.selector;
    }

    receive() external payable {}

    fallback() external payable {}

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addMarket(address _proxy, bool _isLib) external onlyOwner {
        markets.push(MarketInfo(_proxy, _isLib, true));
    }

    function setMarket(
        uint16 _id,
        address _proxy,
        bool isLib,
        bool _active
    ) external onlyOwner {
        markets[_id] = MarketInfo(_proxy, isLib, _active);
    }

    function setFeeRegistry(address _feeRegistry) external onlyOwner {
        feeRegistry = _feeRegistry;
    }

    function setSwapRouter(address _swapRouter) external onlyOwner {
        swapRouter = _swapRouter;
    }

    function setStargateRouter(address _stargateRouter) external onlyOwner {
        stargateRouter = _stargateRouter;
    }

    function setWrapperAddress(address _weth) external onlyOwner {
        WETH = _weth;
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return 0x150b7a02;
    }

    // Used by ERC721BasicToken.sol
    function onERC721Received(
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return 0xf0b9e5ba;
    }

    function _transferEth(address _to, uint256 _amount) internal {
        bool callStatus;
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), _to, _amount, 0, 0, 0, 0)
        }
        require(callStatus, "Eth transfer failed");
    }

    function rescueETH(address recipient) external onlyOwner {
        _transferEth(recipient, address(this).balance);
    }

    //for Emergency
    function rescueERC20(address asset, address recipient) external onlyOwner {
        IERC20(asset).transfer(
            recipient,
            IERC20(asset).balanceOf(address(this))
        );
    }

    //for Emergency
    function rescueERC721(
        address asset,
        uint256[] calldata ids,
        address recipient
    ) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC721(asset).transferFrom(address(this), recipient, ids[i]);
        }
    }

    //for Emergency
    function rescueERC1155(
        address asset,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        address recipient
    ) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC1155(asset).safeTransferFrom(
                address(this),
                recipient,
                ids[i],
                amounts[i],
                ""
            );
        }
    }
}