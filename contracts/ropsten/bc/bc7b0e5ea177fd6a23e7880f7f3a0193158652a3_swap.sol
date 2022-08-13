/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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

interface IPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

library address_make_payable {
   function make_payable(address x) internal pure returns (address payable) {
      return address(uint160(x));
   }
}

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract swap{
    address private constant WETH =0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant unirouter =0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant sushirouter =0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address private constant superMan=0x05E1dA69f6CC3e6fe5C3a113972DffD9798Cc76a;
    using address_make_payable for address;


    function getReserves(address pool0,address pool1) external view returns (uint112 a1,uint112 b1,uint112 a2, uint112 b2){
        address token0=IPair(pool0).token0();
        (uint112 reserve0, uint112 reserve1, ) = IPair(pool0).getReserves();
        (a1,b1)=token0==WETH?(reserve0,reserve1):(reserve1,reserve0);
        address token1=IPair(pool1).token0();
        (uint112 reserve2, uint112 reserve3, ) = IPair(pool1).getReserves();
        (a2,b2)=token1==WETH?(reserve2,reserve3):(reserve3,reserve2);
    }
    
    function getprofit(address token, uint256 amount) external view returns (uint256 profit) {
        address[] memory path = new address[](2);
        path[0] =token;
        path[1] =WETH;
        uint[] memory swapamount=IRouter(sushirouter).getAmountsOut(amount,path);

        address[] memory path1 = new address[](2);
        path1[0] =WETH;
        path1[1] =token;
        uint[] memory backamount = IRouter(unirouter).getAmountsIn(amount,path1);
        if (swapamount[1]<backamount[0]){
            profit=0;
        } else{
            profit=swapamount[1]-backamount[0];
        }
    }   

    function Swap(address _pair,address _tokenBorrow, uint256 _amount) external {
        address token0 = IPair(_pair).token0();
        address token1 = IPair(_pair).token1();
        uint256 amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint256 amount1Out = _tokenBorrow == token1 ? _amount : 0;
        bytes memory data = abi.encode(_pair,_tokenBorrow, _amount);

        IPair(_pair).swap(amount0Out, amount1Out, address(this), data);
    }


    function uniswapV2Call(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        require(_sender == address(this), "!sender");
        (address pair,address tokenBorrow, uint amount) = abi.decode(_data, (address,address,uint));


        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = tokenBorrow;
        uint[] memory amounts = IRouter(unirouter).getAmountsIn(amount,path);

        uint256 WETHBefore = IERC20(WETH).balanceOf(address(this));

        address[] memory path1 = new address[](2);
        path1[0] = tokenBorrow;
        path1[1] = WETH;

        if (IERC20(tokenBorrow).allowance(address(this),sushirouter)<1579208923731619542357098500868790853269984665640564039457584007912963993){
            IERC20(tokenBorrow).approve(sushirouter,15792089237316195423570985008687907853269984665640564039457584007913129639936);
        }

        IRouter(sushirouter).swapExactTokensForETH(amount,1,path1,address(this),block.timestamp);
        uint256 balance = address(this).balance;
        IWETH(WETH).deposit{value:balance}();
        IERC20(WETH).transfer(pair, amounts[0]);

        uint256 WETHafter = IERC20(WETH).balanceOf(address(this));
        require(WETHafter>= WETHBefore, "avax not enough"); 
    }

     
    function moreETH() public payable {    
    }

    
    function turnOutWETH(uint256 amount) public onlyOwner {
        address payable addr = superMan.make_payable();
        addr.transfer(amount);
    }

    function turnOutToken(address token, uint256 amount) public onlyOwner{
        IERC20(token).transfer(superMan, amount);
    }

    modifier onlyOwner(){
    require(address(msg.sender) == superMan, "No authority");
    _;
    }
    receive() external payable{}
    }