// SPDX-License-Identifier: MIT

// Copyright (c) 2021 0xdev0 - All rights reserved
// https://twitter.com/0xdev0

pragma solidity ^0.8.0;

interface IUniswapRouter {

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function getAmountsOut(
    uint amountIn,
    address[] memory path
  ) external view returns (uint[] memory amounts);
}

interface IWETH {
  function withdraw(uint wad) external;
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint amount) external returns (bool);
  function approve(address spender, uint amount) external returns (bool);
}

interface IERC20 {
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function approve(address spender, uint amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract SwapForMe {

  event LogInt(uint _index, uint _value);

  // Mainnet
  IWETH public constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  uint MAX_INT = 2**256 - 1;

  IUniswapRouter public uniswap;

  mapping(address => bool) public operators;

  receive() external payable {}

  constructor(IUniswapRouter _uniswap) {
    uniswap = _uniswap;

    operators[msg.sender] = true;
  }

  function swap(
    uint256[] memory amounts,
    address[] memory path,
    uint256 deadline
  ) public {

    require(operators[msg.sender], "Helper: please register first");
    require(amounts.length == path.length, "Helper: input lengths mismatch");

    address[] memory swapPath = new address[](2);

    uint256 amountIn = amounts[0];
    address tokenIn = path[0];

    IERC20 iTokenIn = IERC20(tokenIn);
    iTokenIn.transferFrom(msg.sender, address(this), amountIn);
    

    for (uint i=1; i < amounts.length; i++) {
      emit LogInt(i, amountIn);
      uint256 amountOutMin = amounts[i];
      address tokenOut = path[i];

      swapPath[0] = tokenIn;
      swapPath[1] = tokenOut;

      IERC20(tokenIn).approve(address(uniswap), MAX_INT);
      uniswap.swapExactTokensForTokens(amountIn, amountOutMin, swapPath, address(this), deadline);

      IERC20 iTokenOut = IERC20(tokenOut);
      amountIn = iTokenOut.balanceOf(msg.sender);
      tokenIn = tokenOut;
    }

    
    IERC20 finalTokenOut = IERC20(tokenIn);
    uint finalBalance = finalTokenOut.balanceOf(address(this));
    finalTokenOut.transfer(msg.sender, finalBalance);
  }
}