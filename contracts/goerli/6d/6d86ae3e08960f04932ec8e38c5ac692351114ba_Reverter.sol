/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract Reverter {
  uint calls = 0;

  error NewRevert(uint reverts);

  function works() public {
    calls++;
  }

  function oldRevert() public {
    calls++;
    revert("oldRevert");
  }

  function newRevert() public {
    calls++;
    revert NewRevert(calls);
  }

}