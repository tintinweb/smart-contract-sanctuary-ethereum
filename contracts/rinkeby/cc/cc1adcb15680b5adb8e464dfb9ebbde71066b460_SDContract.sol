// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract SDContract {
  address payable forceAddress; 

  constructor(address payable _forceAddress){
    forceAddress = _forceAddress;
  }

  function boom() external {
    selfdestruct(forceAddress);
  }
}