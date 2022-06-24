/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IERC20 {
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  function approve(address spender, uint256 amount) external returns (bool);
}

interface IWETH9 {
  function deposit() external payable;

  function withdraw(uint256) external;

  function balanceOf(address account) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);
}

interface ISwapRouter {
  struct ExactInputParams {
    bytes path;
    address recipient;
    uint256 deadline;
    uint256 amountIn;
    uint256 amountOutMinimum;
  }

  function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

  struct ExactOutputParams {
    bytes path;
    address recipient;
    uint256 deadline;
    uint256 amountOut;
    uint256 amountInMaximum;
  }

  function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

contract TRADE {
  ISwapRouter public Router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
  IWETH9 public WETH = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  address public owner;

  constructor() {
    owner = msg.sender;
    WETH.approve(address(Router), type(uint256).max);
  }

  function approveToken(address token) external {
    require(msg.sender == owner);
    IERC20(token).approve(address(Router), type(uint256).max);
  }

  function exactInput_outputETH(
    bytes calldata path,
    address tokenIn,
    address recipient,
    uint256 amountIn,
    uint256 amountOutMin
  ) external {
    require(msg.sender == owner);
    IERC20(tokenIn).transferFrom(owner, address(this), amountIn);
    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      path: path,
      recipient: address(this),
      deadline: block.timestamp,
      amountIn: amountIn,
      amountOutMinimum: amountOutMin
    });
    Router.exactInput(params);
    uint256 balance = WETH.balanceOf(address(this));
    WETH.withdraw(balance);
    payable(recipient).transfer(balance);
  }

  function exactOutput_inputETH(
    bytes calldata path,
    address recipient,
    uint256 amountOut,
    uint256 amountInMax
  ) external payable {
    require(msg.sender == owner);
    if (msg.value > 0) {
      amountInMax += msg.value;
      WETH.deposit{value: msg.value}();
    }
    ISwapRouter.ExactOutputParams memory params = ISwapRouter.ExactOutputParams({
      path: path,
      recipient: recipient,
      deadline: block.timestamp,
      amountOut: amountOut,
      amountInMaximum: amountInMax
    });
    Router.exactOutput(params);
  }

  function getETH() external {
    uint256 balance = WETH.balanceOf(address(this));
    WETH.withdraw(balance);
    payable(owner).transfer(balance);
  }

  receive() external payable {}
}