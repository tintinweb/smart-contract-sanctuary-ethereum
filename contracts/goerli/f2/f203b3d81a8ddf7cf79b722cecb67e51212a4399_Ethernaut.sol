/**
 *Submitted for verification at Etherscan.io on 2023-02-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ethernaut {

  function selfImmolatate() public {
    selfdestruct(payable(0x5d0B4918236B17D7Df54D7FDD42519F0549B0e87));
  }

  receive() external payable {}
}