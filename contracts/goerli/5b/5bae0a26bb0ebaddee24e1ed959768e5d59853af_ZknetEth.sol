/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


abstract contract  ZknetEthStorage {
  function withdraw(uint256 amount, address recipient) external virtual;
}


contract ZknetEth is ZknetEthStorage {


  function depositETH() external payable {

  }

  function deposit(uint256 l2Recipient) external payable {

  }

  function withdraw(uint256 amount, address recipient) external override {
    // Make sure we don't accidentally burn funds.
    require(recipient != address(0x0), "INVALID_RECIPIENT");
    payable(recipient).transfer(amount);
  }

}