// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../interfaces/IERC20.sol";
import "../interfaces/IUniswapV2Callee.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Router.sol";

contract FlashSwapUniswap is IUniswapV2Callee {
  address private constant USER = 0x5845421cB45e5E75Ef14a7903AE689e6b5C1609b;
  address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; 
  address private constant PANCAKESWAP_V2_ROUTER = 0xEfF92A263d31888d860bD50809A8D171709b7b1c;
  address private constant UNISWAP_V2_FACTOTY_GOERLI = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; 
  address private constant WETH_GOERLI = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
  address private constant CELR_GOERLI = 0x5D3c0F4cA5EE99f8E8F59Ff9A5fAb04F6a7e007f;
  IUniswapV2Factory private constant factory = IUniswapV2Factory(UNISWAP_V2_FACTOTY_GOERLI);
  IERC20 private constant weth = IERC20(WETH_GOERLI);
  IUniswapV2Pair private immutable pair;
  uint public amountToRepay;
  constructor () public {
    pair = IUniswapV2Pair(factory.getPair(CELR_GOERLI, WETH_GOERLI));
  }
  // flashSwapUniswap
  function flashSwapUniswap ( uint _wethAmount ) public {
  // need to pass some data to trigger uniswapV2Call
    bytes memory data = abi.encode(WETH_GOERLI, msg.sender);
    pair.swap(0, _wethAmount, address(this), data);
  }

  function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external override {
    require(msg.sender == address(pair), "not pair");
    require(_sender == address(this), "not sender");
    (address tokenBorrow, address caller) = abi.decode(_data, (address, address));
    // Your custom code would go here. For example, code to arbitrage.
    require(tokenBorrow == WETH_GOERLI, "token borrow != WETH");
    // about 0.3% fee, +1 to round up
    uint fee = (_amount1 * 3) / 997 + 1;
    // doubleSwap start
    IERC20(WETH_GOERLI).approve(UNISWAP_V2_ROUTER, weth.balanceOf(address(this)));
    address[] memory path;
    address[] memory path_2;
    path = new address[](2);
    path_2 = new address[](2);
    path[0] = WETH_GOERLI;
    path[1] = CELR_GOERLI;
    path_2[0] = CELR_GOERLI;
    path_2[1] = WETH_GOERLI;
    uint[] memory amounts = IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_amount1, 0, path, address(this), block.timestamp);
    uint amountTokenOutswap = amounts[1];
    IERC20(CELR_GOERLI).approve(PANCAKESWAP_V2_ROUTER, amountTokenOutswap);
    IUniswapV2Router(PANCAKESWAP_V2_ROUTER).swapExactTokensForTokens(amountTokenOutswap, 0, path_2, address(this), block.timestamp + 300);
    weth.transfer(USER, amountTokenOutswap - _amount1 - fee);
    // doubleSwap end
    amountToRepay = _amount1 + fee;
    // Transfer flash swap fee from caller
    // Repay
    weth.transfer(address(pair), amountToRepay);
  }

  function doubleSwap(address _tokenIn, address _tokenOut, uint256 amountIn_, uint fee) public {
     IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, amountIn_);
     address[] memory path;
     address[] memory path_2;
     if (_tokenIn == WETH_GOERLI || _tokenOut == WETH_GOERLI) {
        path = new address[](2);
        path_2 = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        path_2[0] = _tokenOut;
        path_2[1] = _tokenIn;
     } else {
        path = new address[](3);
        path_2 = new address[](3);
        path[0] = _tokenIn;
        path[1] = WETH_GOERLI;
        path[2] = _tokenOut;

        path_2[0] = _tokenOut;
        path_2[1] = WETH_GOERLI;
        path_2[2] = _tokenIn;
     }
     uint[] memory amounts = IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(amountIn_, 0, path, address   (this), block.timestamp);
     uint amountTokenOutswap;
     if (_tokenIn == WETH_GOERLI || _tokenOut == WETH_GOERLI) {
       amountTokenOutswap = amounts[1];
      } else {
       amountTokenOutswap = amounts[2];
     }
     IERC20(_tokenOut).approve(PANCAKESWAP_V2_ROUTER, amountTokenOutswap);
     IUniswapV2Router(PANCAKESWAP_V2_ROUTER).swapExactTokensForTokens(amountTokenOutswap, 0, path_2, address(this), block.timestamp);
     weth.transfer(USER, amountTokenOutswap - amountIn_ - fee);
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

interface IUniswapV2Callee {
  function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
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

interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path)
    external view returns (uint256[] memory amounts);
  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}