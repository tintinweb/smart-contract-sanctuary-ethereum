/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.1 <0.9.0;

contract BinArbitrage {
    // Kovan
    address private constant UNISWAP_V2_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant SUSHISWAP_ROUTER_ADDRESS = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address public owner;

    function balance(
        address _token
    ) view public returns (uint256) {
        return IERC20(_token).balanceOf(msg.sender);
    }

    function transfer(
        address _token,
        uint256 _amount
    ) external {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
    }

    function approve(
        address _token,
        uint256 _amount
    ) external {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        IERC20(_token).approve(UNISWAP_V2_ROUTER_ADDRESS, _amount);
    }


    function swap(
        address _tokenIn,
        address _tokenOut,
        uint _amountIn,
        uint _amountOutMin,
        address _to
    ) external {
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER_ADDRESS, _amountIn);

        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;

        IUniswapV2Router(UNISWAP_V2_ROUTER_ADDRESS).swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            _to,
            block.timestamp
        );
    }
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}