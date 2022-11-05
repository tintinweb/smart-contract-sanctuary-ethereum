/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract TestUniswapLiquidity {
    address private constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant TOKEN1 = 0xe89A194D366A3f18B06Ced6474DC7dAba66EFa83;
    address private constant TOKEN2 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function addLiquidity(
        uint _amountA,
        uint _amountB
    ) external {
        IERC20(TOKEN1).transferFrom(msg.sender, address(this), _amountA);
        IERC20(TOKEN2).transferFrom(msg.sender, address(this), _amountB);

        IERC20(TOKEN1).approve(ROUTER, _amountA);
        IERC20(TOKEN2).approve(ROUTER, _amountB);

        IUniswapV2Router(ROUTER)
            .addLiquidity(
                TOKEN1,
                TOKEN2,
                _amountA,
                _amountB,
                1,
                1,
                msg.sender,
                block.timestamp
            );
    }

    function removeLiquidity(uint _amount) external {
        address pair = IUniswapV2Factory(FACTORY).getPair(TOKEN1, TOKEN2);

        IERC20(pair).transferFrom(msg.sender, address(this), _amount);
        IERC20(pair).approve(ROUTER, _amount);

        IUniswapV2Router(ROUTER).removeLiquidity(
            TOKEN1,
            TOKEN2,
            _amount,
            1,
            1,
            msg.sender,
            block.timestamp
        );
    }
}

interface IUniswapV2Router {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}

interface IUniswapV2Factory {
    function getPair(address token0, address token1) external view returns (address);
}

interface IERC20 {
    function transfer(address recipient, uint amount) external returns (bool);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}