/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IUniswapV2Router02 {
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IToken {
    function comptroller() external view returns (address);
    function mint(uint mintAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
}

interface IComptroller {
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function getAccountLiquidity(address account) external view returns (uint, uint, uint);
    function oracle() external returns (address);
}

interface IOracle{
    function getUnderlyingPrice(address market) external view returns(uint);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient,uint256 amount ) external returns (bool);
}

contract BooKovan{
    uint constant MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    IUniswapV2Pair constant pair = IUniswapV2Pair(0x21686a089F1EA13D9B20e6332BbE41DD76145BAE);
    IUniswapV2Router02 public router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant sonic = 0x595C74D0F1871217a3b6C0071e006C249487dFdF;
    address constant usdt = 0x03be58b42E3eB619658EF2D1Ffd19c2B1D75C5AE;
    address constant lsonic = 0x797C74997c2F91AA0cA6DFA0aBC18210c606b855;
    address constant lusdt = 0xE64C036b180739C11716b865dac43D7cf84102b2;

    //token0 USDT token1 SONIC
    address public owner;
    
    constructor(address _owner) {
        owner = _owner;
    }

    function exec(uint amount) public {
        pair.swap(amount, 0, address(this), abi.encode(""));
    }

    function hswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external returns(uint balance) {
        sender;amount1;data;

        uint amount = amount0;

        IERC20(sonic).approve(lsonic,MAX_INT);
        IToken(lsonic).mint(amount);

        IComptroller comptroller = IComptroller(IToken(lsonic).comptroller());
        address[] memory markets = new address[](1);
        markets[0] = lsonic;
        comptroller.enterMarkets(markets);

        IOracle oracle = IOracle(comptroller.oracle());
        uint price = oracle.getUnderlyingPrice(lusdt);

        (,uint liquidate,) = comptroller.getAccountLiquidity(address(this));
        uint borrowAmount = (liquidate - 1) * 1e18 / price;
        IToken(lusdt).borrow(borrowAmount);
        
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (uint reserveIn, uint reserveOut) = pair.token0() == sonic ? (reserve1, reserve0) : (reserve0, reserve1);
        uint amountRequired = router.getAmountIn(amount, reserveIn, reserveOut);
        IERC20(usdt).transfer(address(pair), amountRequired);

        balance = IERC20(usdt).balanceOf(address(this));
        IERC20(usdt).transfer(owner, balance); 
        return  balance; 
    }
}