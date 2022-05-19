/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.4.23;

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
}

contract HPThtlc {
  
  IERC20 public token;

  event Balance(uint256 _value);

  uint256 balance;

  function _balanceOf (address _account, address _token) public returns (bool success) {
    token = IERC20(_token);
    balance = token.balanceOf(_account);

    emit Balance(balance);

    return true;
  }

  function _balanceView () public view returns (uint256) {
    return balance;
  }
}