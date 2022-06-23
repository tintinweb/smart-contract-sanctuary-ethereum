/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IUniswapV2Router02 {
    function swapExactETHForTokensSupportingFeeOnTransferTokens (uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);

    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

interface ITotalQuery {
    function totalSupply() external view returns (uint);
}

contract UniswapV2RouterBuyer{
    uint    internal _amountOutMin;
    uint    internal _deadline;
    uint    internal _decimals;

    address public immutable weth;
    address public immutable usdc;
    address public immutable router;

    constructor(){
        router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        weth = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        usdc = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
        _decimals = 10**6;
        _deadline = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        _amountOutMin = 0;
    }

    function swapETHForTokens (address _token) external payable {
        address _to = msg.sender;
        address[] memory _path = new address[](2);
            _path[0]= weth;
            _path[1]=_token;
        IUniswapV2Router02(router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(_amountOutMin, _path, _to, _deadline);
    }

    function swapETHForExactTokens (address _token) external payable returns (uint[] memory _amounts){
        address _to = msg.sender;
        uint _totalSupply = ITotalQuery(_token).totalSupply();
        uint maxTx = _totalSupply / 200;
        address[] memory _path = new address[](2);
            _path[0] = weth;
            _path[1] = _token;   
        _amounts = IUniswapV2Router02(router).swapETHForExactTokens{value: msg.value}(maxTx, _path, _to, _deadline);

    }
    
    function swapUSDForTokens (address _token, uint usdValue) external returns (uint[] memory _amounts) {
        uint _amountIn = usdValue * _decimals;
        address _to = msg.sender;
        address[] memory _path = new address[](3);
            _path[0] = usdc;
            _path[1] = weth;
            _path[2] = _token;
        _amounts = IUniswapV2Router02(router).swapExactTokensForTokens(_amountIn, _amountOutMin, _path, _to, _deadline);
    }
}