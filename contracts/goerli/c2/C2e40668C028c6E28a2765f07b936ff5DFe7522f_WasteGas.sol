/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

contract WasteGas {
    event Waste(address sender, uint256 gas);
    uint256 constant GAS_REQUIRED_TO_FINISH_EXECUTION = 60;

  fallback() external {
      emit Waste(msg.sender, gasleft());
      while (gasleft() > GAS_REQUIRED_TO_FINISH_EXECUTION) {

      }
  }   
}