// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

interface IUniswapV2Router {

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract SushiSwapTokenSwap {
    
    address private constant SUSHISWAP_V2_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

   function swapEthForToken(address _tokenOut) external payable {
       address[] memory path = new address[](2);
       path[0] = WETH;
       path[1] = _tokenOut;
       
       IUniswapV2Router(SUSHISWAP_V2_ROUTER).swapExactETHForTokens{value: msg.value}(
           0, path, msg.sender, block.timestamp + 120);
    }

    // function swapTokenForToken(address _tokenIn, address _tokenOut, uint _tokenAmountIn) external {
    function swapTokenForToken(address _tokenIn, uint _tokenAmountIn) external {

        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _tokenAmountIn);
        // IERC20(_tokenIn).approve(SUSHISWAP_V2_ROUTER, _tokenAmountIn);
        
        // address[] memory path;
        // if (_tokenIn == WETH || _tokenOut == WETH) {
        //     path = new address[](2);
        //     path[0] = _tokenIn;
        //     path[1] = _tokenOut;
        // } else {
        //     path = new address[](3);
        //     path[0] = _tokenIn;
        //     path[1] = WETH;
        //     path[2] = _tokenOut;
        // }

        // IUniswapV2Router(SUSHISWAP_V2_ROUTER).swapExactTokensForTokens(_tokenAmountIn, 0, path, msg.sender, block.timestamp + 120);

    }
}