// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

contract GatedCounter {
  bool public isOn;
  uint32 public value;
  address constant public owner = 0x26767625c1C4318bb7Ac3A1d8248C16937BfD03C;

  constructor() {
    value = 0;
  }

  function toggleGate() external {
    isOn = !isOn;
  }

  function increment() public  {
    require(isOn, "Contract needs to be turned on.");
    value += 1;
  }
}