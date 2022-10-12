// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

contract OnchainGasView {
  function blockGas() public view returns (uint256) {
    return block.basefee;
  }

  function blockGasDiv() public view returns (uint256) {
    return block.basefee / 1000000000;
  }
}