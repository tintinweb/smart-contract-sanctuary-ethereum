// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../interfaces/IERC20.sol";
import "../interfaces/IUniswapV2Callee.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IUniswapV2Pair.sol";

contract FlashSwapUniswap is IUniswapV2Callee {
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

  function uniswapV2Call(address _sender,uint _amount0,uint _amount1,bytes calldata _data) external override {
    require(msg.sender == address(pair), "not pair");
    require(_sender == address(this), "not sender");
    (address tokenBorrow, address caller) = abi.decode(_data, (address, address));
    // Your custom code would go here. For example, code to arbitrage.
    require(tokenBorrow == WETH_GOERLI, "token borrow != WETH");
    // about 0.3% fee, +1 to round up
    uint fee = (_amount1 * 3) / 997 + 1;
    amountToRepay = _amount1 + fee;
    // Transfer flash swap fee from caller
    weth.transferFrom(caller, address(this), fee);
    // Repay
    weth.transfer(address(pair), amountToRepay);
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