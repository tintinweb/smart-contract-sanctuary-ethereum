/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

contract FeeCollectorJob {
    event MultiplierSetted(uint256 _collectMultiplier);
    
  function setMultiplier(uint256 _multiplier) external {
    emit MultiplierSetted(_multiplier);
  }
}