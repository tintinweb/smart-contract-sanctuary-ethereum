/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

contract GatedCounter {
  bool public isOn;
  uint32 public value;
  uint32 public activationTimestamp = 0;
  address constant public owner = 0x26767625c1C4318bb7Ac3A1d8248C16937BfD03C;

  constructor() {
    value = 0;
  }

  function closeGate() external {
    isOn = false;
  }

  function openGate() external {
    isOn = true;
  }

  function increment() public  {
    require(isOn, "Contract needs to be turned on.");
    value += 1;
  }

  function setActivationTimestamp(uint32 newActivationTimestamp) public {
      activationTimestamp = newActivationTimestamp;
  }

  function timeGateIncrement() public {
    uint256 startGas = gasleft();
    require(block.timestamp >= activationTimestamp, 'too early!');

    while(startGas - gasleft() < 42000) {
      value += 1;
    }  
  }
}