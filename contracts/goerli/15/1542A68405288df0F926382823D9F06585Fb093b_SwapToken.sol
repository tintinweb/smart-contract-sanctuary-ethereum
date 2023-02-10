// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../interfaces/IERC20.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IUniswapV2Router01.sol";

contract SwapToken {

  event SwapSuccess(
   address _router1,
   address _router2, 
   address _tokenIn, 
   address _tokenOut, 
   uint256 _amountIn, 
   address _to
  );

  function excuteSwap (
    address _router1, 
    address _router2, 
    address _tokenIn, 
    address _tokenOut, 
    address _to,
    address _weth,
    uint256 _amountIn
    ) public {

     IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
     IERC20(_tokenIn).approve(_router1, _amountIn);
     address[] memory path;
     address[] memory path_;

     if (_tokenIn == _weth || _tokenOut == _weth) {
        path = new address[](2);
        path_ = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        path_[0] = _tokenOut;
        path_[1] = _tokenIn;
     } else {
        path = new address[](3);
        path_ = new address[](3);
        path[0] = _tokenIn;
        path[1] = _weth;
        path[2] = _tokenOut;
        path_[0] = _tokenOut;
        path_[1] = _weth;
        path_[2] = _tokenIn;
     }
     uint[] memory amounts = IUniswapV2Router01(_router1).swapExactTokensForTokens(_amountIn, 0, path, address(this), block.timestamp);
     uint amountTokenOutswap;
     if (_tokenIn == _weth || _tokenOut == _weth) {
       amountTokenOutswap = amounts[1];
      } else {
       amountTokenOutswap = amounts[2];
     }
     IERC20(_tokenOut).approve(_router2, amountTokenOutswap);
     IUniswapV2Router01(_router2).swapExactTokensForTokens(amountTokenOutswap, 0, path_, _to, block.timestamp);
     emit SwapSuccess(_router1, _router2, _tokenIn, _tokenOut, _amountIn, _to);
    }
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
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

interface IUniswapV2Factory {
  function getPair(address token0, address token1) external returns (address);
}

interface IUniswapV2Pair  {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
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