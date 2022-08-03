/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract marketMake {
    address private constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    //Adds liquidity to a position
function add(uint _numA, uint _numB, address _A, address _B, address myAccount) external {
    //Approval statements for testing
    IERC20(_A).approve(myAccount, _numA);
    IERC20(_B).approve(myAccount, _numB);
    IERC20(_A).approve(address(this), _numA);
    IERC20(_B).approve(address(this), _numB);
    IERC20(_A).transferFrom(myAccount, address(this), _numA);
    IERC20(_B).transferFrom(myAccount, address(this), _numB);    
    IERC20(_A).approve(ROUTER, _numA);
    IERC20(_B).approve(ROUTER, _numB);

    IUniswapV2Router(ROUTER).addLiquidity(_A, _B, _numA, _numB, 1, 1, myAccount, block.timestamp);
 }


    //Removes liquidity from the position
 function remove(address _A, address _B, address myAccount) external{
    address pair = IUniswapV2Factory(FACTORY).getPair(_A, _B);
    uint amount = IERC20(pair).balanceOf(myAccount);
    IERC20(pair).approve(ROUTER, amount);
    IERC20(pair).approve(myAccount, amount);
    IERC20(pair).approve(address(this), amount);

    IUniswapV2Router(ROUTER).removeLiquidity(_A, _B, amount, 1, 1, myAccount, block.timestamp);
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