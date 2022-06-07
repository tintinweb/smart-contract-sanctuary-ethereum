// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract test {
  address public token1;
  address public token2;
  uint256 public amountIn;
  uint256 public amountOut;

  event swap(address,address,address,uint256,uint256);

  function setAddress(address a,address b) public{
    token1 = a;
    token2 = b;
  }

  function emitEvent(uint256 In,uint256 out) public {
    emit swap(msg.sender,token1,token2,In,out);
  }
}