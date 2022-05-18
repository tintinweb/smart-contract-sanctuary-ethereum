/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.7.0;


//import the ERC20 interface

interface IERC20 {
  function totalSupply() external view returns(uint);

  function balanceOf(address account) external view returns(uint);

  function transfer(address recipient, uint amount) external returns(bool);

  function allowance(address owner, address spender) external view returns(uint);

  function approve(address spender, uint amount) external returns(bool);

  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns(bool);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


//import the uniswap router
//the contract needs to use swapExactTokensForTokens
//this will allow us to import swapExactTokensForTokens into our contract

interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path)
  external
  view
  returns(uint256[] memory amounts);

  function swapExactTokensForTokens(

    //amount of tokens we are sending in
    uint256 amountIn,
    //the minimum amount of tokens we want out of the trade
    uint256 amountOutMin,
    //list of token addresses we are going to trade in.  this is necessary to calculate amounts
    address[] calldata path,
    //this is the address we are going to send the output tokens to
    address to,
    //the last time that the trade is valid for
    uint256 deadline
  ) external returns(uint256[] memory amounts);
}

interface IUniswapV2Pair {
  function token0() external view returns(address);

  function token1() external view returns(address);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;
}

interface IUniswapV2Factory {
  function getPair(address token0, address token1) external returns(address);
}



contract tokenSwap {

  address private contractOwner;
  uint256 constant MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  uint256 blockTime = 60;

  constructor() {
    contractOwner = msg.sender;
  }

   fallback() external payable  {}
   receive() external payable  {}

  function approveToken(address token, address router) external {
    require(msg.sender == contractOwner);
    IERC20(token).approve(router, MAX_INT);
  }

  function withdrawToken(address token) external {
    require(msg.sender == contractOwner);
    uint256 balance = IERC20(token).balanceOf(address(this));
    IERC20(token).transfer(contractOwner, balance);
  }

  function withdrawCoin() external {
    require(msg.sender == contractOwner);
    payable(contractOwner).transfer(address(this).balance);
  }

  function changeContractOwner(address newOwner) external {
    require(msg.sender == contractOwner);
    contractOwner = newOwner;
  }

  function swap(address[] memory path, uint256 _amountIn, uint256 _amountOutMin, address router) external {
    require(msg.sender == contractOwner);
    IUniswapV2Router(router).swapExactTokensForTokens(_amountIn, _amountOutMin, path, address(this), block.timestamp + blockTime);
  }

  function getAmountOutMin(address[] memory path, uint256 _amountIn, address router) external view returns(uint256[] memory) {
    require(msg.sender == contractOwner);
    return IUniswapV2Router(router).getAmountsOut(_amountIn, path);
  }

  function _getAmountOutMin(address[] memory path, uint256 _amountIn, address router) internal view returns(uint256[] memory) {
    require(msg.sender == contractOwner);
    return IUniswapV2Router(router).getAmountsOut(_amountIn, path);
  }

  function getAmountOutMinInTwoRouter(address[] memory path, uint256 _amountIn, address router0, address router1) external view returns(uint256) {
    require(msg.sender == contractOwner);
    uint256 amountOutMin0 = _getAmountOutMin(path, _amountIn, router0)[0];
    uint256 amountOutMin1 = _getAmountOutMin(reverseArray(path), _amountIn, router1)[path.length - 1];
    return amountOutMin1 - amountOutMin0;
  }

  function _getAmountOutMinInTwoRouter(address[] memory path, uint256 _amountIn, address router0, address router1) internal view returns(uint256) {
    require(msg.sender == contractOwner);
    uint256 amountOutMin0 = _getAmountOutMin(path, _amountIn, router0)[0];
    uint256 amountOutMin1 = _getAmountOutMin(reverseArray(path), _amountIn, router1)[path.length - 1];
    return amountOutMin1 - amountOutMin0;
  }

  function swapTwoRouter(address[] memory path, uint256 _amountIn, uint256 _amountOutMin, address router0, address router1) external {
    require(msg.sender == contractOwner);
    require(_getAmountOutMinInTwoRouter(path, _amountIn, router0, router1) + _amountIn > _amountIn);
    uint256 first = _getAmountOutMin(path, _amountIn, router0)[path.length - 1];
    uint256 second = _getAmountOutMin(reverseArray(path), first, router1)[0];
    IUniswapV2Router(router0).swapExactTokensForTokens(_amountIn, first, path, address(this), block.timestamp + blockTime);
    IUniswapV2Router(router1).swapExactTokensForTokens(second, _amountOutMin, reverseArray(path), address(this), block.timestamp + blockTime);
  }

  function reverseArray(address[] memory arr)
  internal
  pure
  returns(address[] memory) {
    address temp;
    for (uint i = 0; i < arr.length / 2; i++) {
      temp = arr[i];
      arr[i] = arr[arr.length - i - 1];
      arr[arr.length - i - 1] = temp;
    }
    return arr;
  }
}


//