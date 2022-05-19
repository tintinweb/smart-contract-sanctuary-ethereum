/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
}

contract HPThtlc {
  IERC20 public token;
  uint balance;
  function _balanceOf (address _account, address _token) public returns (uint) {
    token = IERC20(_token);
    balance = token.balanceOf(_account);
    return balance;
  }

}