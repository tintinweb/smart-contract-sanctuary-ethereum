/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File contracts/AnyCallDst.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AnyCallDst{
  event NewMsg(string msg);

  //this function is supposed to be executed by mpc address and anycall contract
  function step2_createMsg(string calldata _msg) external {
    emit NewMsg(_msg);
  }
}