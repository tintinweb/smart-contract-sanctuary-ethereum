/**
 *Submitted for verification at Etherscan.io on 2022-07-12
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
    function accrueInterest() external returns (uint);
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

// loan token1 to get token0
contract BooKovan{
    uint constant MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    IUniswapV2Pair public pair;
    IUniswapV2Router02 public router;

    // address token0;
    // address token1;
    // address ctoken0;
    // address ctoken1;
    event LogBalance(uint amount);

    address tokenMint;
    address tokenBorrow;
    address lptokenMint;
    address lptokenBorrow;
    // pair = IUniswapV2Pair(0x21686a089F1EA13D9B20e6332BbE41DD76145BAE);
    // router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    // address constant sonic = 0x595C74D0F1871217a3b6C0071e006C249487dFdF;
    // address constant usdt = 0x03be58b42E3eB619658EF2D1Ffd19c2B1D75C5AE;
    // address constant lsonic = 0x797C74997c2F91AA0cA6DFA0aBC18210c606b855;
    // address constant lusdt = 0xE64C036b180739C11716b865dac43D7cf84102b2;

    //IUniswapV2Pair constant pair = IUniswapV2Pair(0x9dbe263c92faaEC700980089E73d2764614Ed8EE);
    //IUniswapV2Router02 public router = IUniswapV2Router02(0xED7d5F38C79115ca12fe6C0041abb22F0A06C300);
    //address constant xrp = 0xA2F3C2446a3E20049708838a779Ff8782cE6645a;
    //address constant usdt = 0xa71EdC38d189767582C38A3145b5873052c3e47a;
    //address constant lxrp = 0x366CE3630bC2691Bbf3eB29DD6E4DD3D11c25E11;
    //address constant lusdt = 0xc502F3f6f1b71CB7d856E70B574D27d942C2993C;



    uint balance;

    //token0 USDT token1 SONIC
    address public owner;
    
    //amount1 是指通过swap换出来的币，用来在合约里mint最后从合约borrow出amount0
    constructor(address _owner) {
        owner = _owner;
    }

    function exec(uint amount0 ,uint amount1 ,address _pairAddress ,address _routerAddress,address _token0,address _token1,address _ctoken0,address _ctoken1) public returns(uint){
        pair = IUniswapV2Pair(_pairAddress);
        router = IUniswapV2Router02(_routerAddress);

        if(amount0 > 0) {
         tokenMint = _token0;
         tokenBorrow = _token1;
         lptokenMint = _ctoken0;
         lptokenBorrow = _ctoken1;
        }else {
         tokenMint = _token1;
         tokenBorrow = _token0;
         lptokenMint = _ctoken1;
         lptokenBorrow = _ctoken0;
        }

        pair.swap(amount0, amount1, address(this), abi.encode(""));

        return balance;
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {
        sender;data;

      
        uint amount = amount0 > 0 ? amount0 : amount1 ;

      
        IERC20(tokenMint).approve(lptokenMint,MAX_INT);
        IToken(lptokenMint).mint(amount);

        IComptroller comptroller = IComptroller(IToken(lptokenMint).comptroller());
        address[] memory markets = new address[](1);
        markets[0] = lptokenMint;
        comptroller.enterMarkets(markets);

        IOracle oracle = IOracle(comptroller.oracle());
        uint price = oracle.getUnderlyingPrice(lptokenBorrow);

        IToken(lptokenBorrow).accrueInterest();
        (,uint liquidate,) = comptroller.getAccountLiquidity(address(this));
        uint borrowAmount = (liquidate - 1) * 1e18 / price;
        IToken(lptokenBorrow).borrow(borrowAmount);
        

        // reserve0 usdt reserve1 sonic
        // 借出的usdt数量=  getAmountIn(amount,  _reserve1 , _reserve0 )
        // 借出的sonic数量= getAmountIn(amount,  _reserve0 , _reserve1 )
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (uint reserveIn, uint reserveOut) = pair.token0() == tokenMint ? (reserve1, reserve0) : (reserve0, reserve1);

        uint amountRequired = router.getAmountIn(amount, reserveIn, reserveOut);
        IERC20(tokenBorrow).approve(address(pair),MAX_INT);
        IERC20(tokenBorrow).transfer(address(pair), amountRequired);
        balance = IERC20(tokenBorrow).balanceOf(address(this));
        IERC20(tokenBorrow).transfer(owner, IERC20(tokenBorrow).balanceOf(address(this))); 
    }
}