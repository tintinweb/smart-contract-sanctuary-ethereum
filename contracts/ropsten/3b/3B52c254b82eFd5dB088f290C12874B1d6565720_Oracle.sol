/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.5.10;



// File: Oracle.sol

contract Oracle{

  constructor() public {
  }

  function latestAnswer() external view returns (int256){
    return 200000000;
  }
}