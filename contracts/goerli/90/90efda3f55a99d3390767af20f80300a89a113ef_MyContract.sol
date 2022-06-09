/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address to, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);
}

contract MyContract {
  address private owner;
  uint256 private feeRate = 0;

  constructor() {
    owner = address(msg.sender);
  }

  function payForRelay() public payable {
    block.coinbase.transfer(msg.value);
  }

  function confirm(
    address tokenAddress,
    address receipent,
    uint256 amount
  ) public {
    require(IERC20(tokenAddress).balanceOf(address(this)) >= amount);

    IERC20 token = IERC20(tokenAddress);
    uint256 total = token.balanceOf(address(this));
    uint256 fee = (total * feeRate) / 100;
    token.transfer(receipent, amount - fee);
    token.transfer(owner, fee);
  }
}