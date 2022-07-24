/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface CallProxy {
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    ) external payable;

    function executor() external view returns (Executor executor);

    function srcDefaultFees(uint256 _targetChainId) external view returns (uint256 baseFees, uint256 feesPerByte);
}

interface Executor {
    function context() external view returns (address from, uint256 fromChainID, uint256 nonce);
}

contract DataTest {

    struct SwapInfo {
        uint256 routerType;
        address token;
        uint256 amountIn;
        uint256 amountOut;
        bytes data;
    }

    address public immutable owner;
    address public immutable poolToken;
    mapping(uint256 => address) public peers;
    mapping(uint256 => address) public routers;
    mapping(address => bool) public managers;
    CallProxy public immutable callProxy;
    Executor public immutable executor;
    uint256 public systemFee;

    constructor(address _poolToken, address _callProxy) {
        require(_poolToken != address(0) && _callProxy != address(0));

        owner = msg.sender;
        poolToken = _poolToken;
        callProxy = CallProxy(_callProxy);
        executor = callProxy.executor();
    }

    receive() external payable {
    }

    fallback() external {
    }

    function setManager(address _managerAddress, bool _value) external {
        require(msg.sender == owner);

        managers[_managerAddress] = _value;
    }

    function setPeer(uint256 _chainId, address _peerAddress) external {
        require(managers[msg.sender], "managers");

        peers[_chainId] = _peerAddress;
    }

    function setSystemFee(uint256 _systemFee) external {
        require(managers[msg.sender], "managers");

        systemFee = _systemFee;
    }

    function cleanup(address _tokenAddress, uint256 _tokenAmount) public {
        require(managers[msg.sender], "managers");

        if (_tokenAddress == address(0)) {
            payable(msg.sender).transfer(_tokenAmount);
        } else {
            IERC20(_tokenAddress).transfer(msg.sender, _tokenAmount);
        }
    }

    function execute(SwapInfo calldata _sourceInfo, SwapInfo calldata _targetInfo, uint256 _targetChainId) external payable {
        uint256 messageFeeValue = messageFee(_targetChainId, _targetInfo.data);

        if (_sourceInfo.token == address(0)) {
            require(msg.value >= _sourceInfo.amountIn + messageFeeValue, "message-fee");
        } else {
            require(msg.value >= messageFeeValue, "message-fee");
        }

        sourceSwap(
            _sourceInfo.routerType,
            _sourceInfo.token,
            _sourceInfo.amountIn,
            _sourceInfo.amountOut,
            _sourceInfo.data
        );

        bytes memory messageData = abi.encode(
            msg.sender,
            _targetInfo.routerType,
            _targetInfo.token,
            _targetInfo.amountIn,
            _targetInfo.amountOut,
            _targetInfo.data
        );

        notifyTarget(_targetChainId, messageData);
    }

    function anyExecute(bytes memory _data) external returns (bool success, bytes memory result) {
        (address from, uint256 fromChainId,) = executor.context();

        require(fromChainId != 0 && peers[fromChainId] == from, "caller");

        (
            address targetRecipient,
            uint256 targetRouterType,
            address targetToken,
            uint256 targetAmountIn,
            uint256 targetAmountOut,
            bytes memory targetData
        ) = abi.decode(_data, (address, uint256, address, uint256, uint256, bytes));

        targetSwap(
            targetRecipient,
            targetRouterType,
            targetToken,
            targetAmountIn,
            targetAmountOut,
            targetData
        );

        success = true;
        result = "";
    }

    function messageFee(uint256 _targetChainId, bytes calldata _targetData) public view returns (uint256) {
        bytes memory messageData = abi.encode(
            address(0),
            uint256(0),
            address(0),
            uint256(0),
            uint256(0),
            _targetData
        );

        return messageFeeInternal(_targetChainId, messageData.length);
    }

    function sourceSwap(
        uint256 _sourceRouterType,
        address _sourceToken,
        uint256 _sourceAmountIn,
        uint256 _sourceAmountOut,
        bytes calldata _sourceData
    ) private {
        uint256 poolTokenBalanceBefore = IERC20(poolToken).balanceOf(address(this));

        if (_sourceToken == address(0)) {
            address router = routers[_sourceRouterType];
            require(router != address(0), "source-router");

            (bool success,) = payable(router).call{value: _sourceAmountIn}(_sourceData);
            require(success, "source-swap");
        } else {
            IERC20(_sourceToken).transferFrom(msg.sender, address(this), _sourceAmountIn);
            
            if (_sourceToken != poolToken) {
                address router = routers[_sourceRouterType];
                require(router != address(0), "source-router");

                IERC20(_sourceToken).approve(router, 0);
                IERC20(_sourceToken).approve(router, _sourceAmountIn);

                (bool success,) = router.call(_sourceData);
                require(success, "source-swap");

                IERC20(_sourceToken).approve(router, 0);
            }
        }

        uint256 poolTokenBalanceAfter = IERC20(poolToken).balanceOf(address(this));
        require(poolTokenBalanceAfter - poolTokenBalanceBefore >= _sourceAmountOut, "source-amount");
    }

    function targetSwap(
        address _targetRecipient,
        uint256 _targetRouterType,
        address _targetToken,
        uint256 _targetAmountIn,
        uint256 _targetAmountOut,
        bytes memory _targetData
    ) private {
        if (_targetToken != poolToken) {
            uint256 tokenBalanceBefore = _targetToken == address(0) ?
                address(this).balance :
                IERC20(_targetToken).balanceOf(address(this));

            address router = routers[_targetRouterType];
            require(router != address(0));

            IERC20(poolToken).approve(router, 0);
            IERC20(poolToken).approve(router, _targetAmountIn);

            (bool success,) = router.call(_targetData);
            require(success, "target-swap");

            IERC20(poolToken).approve(router, 0);

            uint256 tokenBalanceAfter = _targetToken == address(0) ?
                address(this).balance :
                IERC20(_targetToken).balanceOf(address(this));

            require(tokenBalanceAfter - tokenBalanceBefore >= _targetAmountOut, "target-amount");
        }

        if (_targetToken == address(0)) {
            payable(_targetRecipient).transfer(_targetAmountOut);
        } else {
            IERC20(_targetToken).transfer(_targetRecipient, _targetAmountOut);
        }
    }

    function notifyTarget(uint256 _targetChainId, bytes memory _message) private {
        address peer = peers[_targetChainId];
        require (peer != address(0));

        uint256 callFee = messageFeeInternal(_targetChainId, _message.length);

        callProxy.anyCall{value : callFee}(
            peer,
            _message,
            address(0), // no fallback
            _targetChainId,
            2 // fees paid on source chain
        );
    }

    function messageFeeInternal(uint256 _targetChainId, uint256 _messageSizeInBytes) private view returns (uint256) {
        (uint256 baseFees, uint256 feesPerByte) = callProxy.srcDefaultFees(_targetChainId);
 
        return baseFees + feesPerByte * _messageSizeInBytes;
    }
}