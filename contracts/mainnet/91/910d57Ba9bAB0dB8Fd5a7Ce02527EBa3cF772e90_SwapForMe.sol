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

interface IUniswapV2Pair {
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function token0() external view returns (address);
  function token1() external view returns (address);
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
    uint256[][] memory amounts,
    address[] memory pairs
  ) public {

    require(operators[msg.sender], "Helper: please register first");
    require(amounts.length == pairs.length, "Helper: input lengths mismatch");

    for (uint i=1; i < amounts.length; i++) {
      uint amount0 = amounts[i][0];
      uint amount1 = amounts[i][1];
      address pairAddress = pairs[i];

      IUniswapV2Pair v2Pair = IUniswapV2Pair(pairAddress);
      address tokenIn = address(0);
      address tokenOut = address(0);
      uint256 amountIn = 0;

      if (amount0 == uint(0)) {
        tokenIn = v2Pair.token1();
        tokenOut = v2Pair.token0();
        amountIn = amount1;
      } else {
        tokenIn = v2Pair.token0();
        tokenOut = v2Pair.token1();
        amountIn = amount0;
      }

      IERC20 iTokenIn = IERC20(tokenIn);
      iTokenIn.approve(address(v2Pair), MAX_INT);
      
      v2Pair.swap(amount0, amount1, address(this), new bytes(0));
    }
  }

  function withdraw(
    address token
  ) public {
    require(operators[msg.sender], "Helper: please register first");

    IERC20 iToken = IERC20(token);
    uint256 amount = iToken.balanceOf(address(this));
    iToken.transfer(msg.sender, amount);
  }
}