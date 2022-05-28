//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

import "./IUniswapV2Pair.sol";
import "./UniswapV2Library.sol";

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}
contract MultiCall is IUniswapV2Callee {
    address private immutable owner;
    address private immutable executor;
    address private constant factory = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IWETH private constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    modifier onlyExecutor() {
        require(msg.sender == executor);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address _executor) public payable {
        owner = msg.sender;
        executor = _executor;
        if (msg.value > 0) {
            WETH.deposit{value: msg.value}();
        }
    }

    receive() external payable {
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        address[] memory path = new address[](2);
        uint amountToken;
        uint amountETH;
        { // scope for token{0,1}, avoids stack too deep errors
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        assert(msg.sender == UniswapV2Library.pairFor(factory, token0, token1)); // ensure that msg.sender is actually a V2 pair
        assert(amount0 == 0 || amount1 == 0); // this strategy is unidirectional
        path[0] = amount0 == 0 ? token0 : token1;
        path[1] = amount0 == 0 ? token1 : token0;
        amountToken = token0 == address(WETH) ? amount1 : amount0;
        amountETH = token0 == address(WETH) ? amount0 : amount1;
        }

        assert(path[0] == address(WETH) || path[1] == address(WETH)); // this strategy only works with a V2 WETH pair
        IERC20 token = IERC20(path[0] == address(WETH) ? path[1] : path[0]);

        (address sellMarket) = abi.decode(data[:20], (address));
        require(token.approve(address(sellMarket), amountToken), 'approve failed.');
        (bool _success, bytes memory _response) = sellMarket.call(abi.decode(data[52:], (bytes)));
        require(_success); _response;

        (uint256 _ethAmountToCoinbase) = abi.decode(data[20:52], (uint256));

        uint amountRequired = UniswapV2Library.getAmountsIn(factory, amountToken, path)[0];
        uint256 _wethBalanceAfter = WETH.balanceOf(address(this));
        // TODO add balance before and coinbase to data
        require(_wethBalanceAfter > amountETH + _ethAmountToCoinbase + amountRequired);
        // don't think this line is necessary - the sell call will deposit weth
        assert(WETH.transfer(msg.sender, amountRequired)); // return WETH to V2 pair
        // (bool success,) = sender.call{value: amountReceived - amountRequired}(new bytes(0)); // keep the rest! (ETH)
        // assert(success);
    }

    // instead of transferring weth, flash swap for token
    function flashUniswapWeth(uint _amount0Out, uint _amount1Out, uint256 _ethAmountToCoinbase, address[] memory _targets, bytes[] memory _payloads) external onlyExecutor payable {
        IUniswapV2Pair _buyPair = IUniswapV2Pair(_targets[0]);
        
        // data will always be a single address followed by the coinbase followed by the payload
        uint _size = 52 + _payloads[1].length;
        bytes memory _data = new bytes(_size);

        uint counter=0;
        bytes20 targetBytes = bytes20(_targets[1]);
        for (uint i=0;i<20;i++)
        {
            _data[counter]=targetBytes[i];
            counter++;
        }

        bytes memory _coinbaseBytes = abi.encodePacked(_ethAmountToCoinbase);
        for(uint i=0;i<32;i++) {
            _data[counter] = _coinbaseBytes[i];
            counter++;
        }
        for (uint i=0;i<_payloads[1].length;i++)
        {
            _data[counter]=_payloads[1][i];
            counter++;
        }

        _buyPair.swap(
            _amount0Out,
            _amount1Out,
            address(this),
            _data
        );

        if (_ethAmountToCoinbase == 0) return;

        uint256 _ethBalance = address(this).balance;
        if (_ethBalance < _ethAmountToCoinbase) {
            WETH.withdraw(_ethAmountToCoinbase - _ethBalance);
        }
        block.coinbase.transfer(_ethAmountToCoinbase);
    }

    function uniswapWeth(uint256 _wethAmountToFirstMarket, uint256 _ethAmountToCoinbase, address[] memory _targets, bytes[] memory _payloads) external onlyExecutor payable {
        require (_targets.length == _payloads.length);
        uint256 _wethBalanceBefore = WETH.balanceOf(address(this));
        WETH.transfer(_targets[0], _wethAmountToFirstMarket);
        for (uint256 i = 0; i < _targets.length; i++) {
            (bool _success, bytes memory _response) = _targets[i].call(_payloads[i]);
            require(_success); _response;
        }

        uint256 _wethBalanceAfter = WETH.balanceOf(address(this));
        require(_wethBalanceAfter > _wethBalanceBefore + _ethAmountToCoinbase);
        if (_ethAmountToCoinbase == 0) return;

        uint256 _ethBalance = address(this).balance;
        if (_ethBalance < _ethAmountToCoinbase) {
            WETH.withdraw(_ethAmountToCoinbase - _ethBalance);
        }
        block.coinbase.transfer(_ethAmountToCoinbase);
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external onlyOwner payable returns (bytes memory) {
        require(_to != address(0));
        (bool _success, bytes memory _result) = _to.call{value: _value}(_data);
        require(_success);
        return _result;
    }
}