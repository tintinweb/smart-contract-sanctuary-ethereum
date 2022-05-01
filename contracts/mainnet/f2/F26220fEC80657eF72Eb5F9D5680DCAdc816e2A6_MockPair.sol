// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IERC20 {
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint);
  function approve(address spender, uint amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

contract MockPair {

  function lpToken(
    address _token
  ) pure external returns (address) {
    return _token;
  }
}