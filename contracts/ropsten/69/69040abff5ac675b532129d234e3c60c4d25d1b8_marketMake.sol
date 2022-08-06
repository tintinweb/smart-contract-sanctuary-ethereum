/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract marketMake {
    address private constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

function add(uint _numA, uint _numB, address _A, address _B, address _account) external {
    IERC20(_A).approve(_account, _numA);
    IERC20(_B).approve(_account, _numB);
    IERC20(_A).approve(address(this), _numA);
    IERC20(_B).approve(address(this), _numB);
    IERC20(_A).approve(ROUTER, _numA);
    IERC20(_B).approve(ROUTER, _numB);

    IERC20(_A).transferFrom(_account, address(this), _numA);
    IERC20(_B).transferFrom(_account, address(this), _numB);    

    IUniswapV2Router(ROUTER).addLiquidity(_A, _B, _numA, _numB, 1, 1, _account, block.timestamp);
 }


 function remove(address _A, address _B, address _account) external{
    address pair = IUniswapV2Factory(FACTORY).getPair(_A, _B);
    uint amount = IERC20(pair).balanceOf(_account);
    IERC20(pair).approve(ROUTER, amount);
    IERC20(pair).approve(_account, amount);
    IERC20(pair).approve(address(this), amount);

    IUniswapV2Router(ROUTER).removeLiquidity(_A, _B, amount, 1, 1, _account, block.timestamp);
 }
} 

//Interfaces
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