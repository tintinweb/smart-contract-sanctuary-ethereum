/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


//import the ERC20 interface

interface IERC20 {
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


//import the uniswap router
//the contract needs to use swapExactTokensForTokens
//this will allow us to import swapExactTokensForTokens into our contract

interface IUniswapV2Router {
  
  function swapExactTokensForETH(
  
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
  ) external returns (uint256[] memory amounts);
}
contract BrokenSwap {  

  address private constant ROUTER_ADDRESS = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
  IUniswapV2Router public constant uniswapRouter = IUniswapV2Router(ROUTER_ADDRESS);
  address private constant WETH = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
  
 function swapToETH(address token_in, uint amountIn) external {
    require(amountIn > 0, "Must pass non 0 token amount");
    uint amountOutMin = 0;
    address[] memory path = new address[](2);
    path[0] = token_in;
    path[1] = WETH;
    address to = msg.sender;
    uint256 deadline = block.timestamp + 15;

    IERC20(token_in).approve(ROUTER_ADDRESS, amountIn);
    IERC20(token_in).transferFrom(msg.sender, address(this), amountIn);
 
    uniswapRouter.swapExactTokensForETH(
      amountIn, 
      amountOutMin, 
      path, 
      to,
      deadline);
  }
}