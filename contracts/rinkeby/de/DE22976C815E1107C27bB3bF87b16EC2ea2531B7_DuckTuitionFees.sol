// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract DuckTuitionFees {
  function TuitionFees(int OriginalFee) public pure returns (int){
    int NewFee = 0;
    NewFee = OriginalFee + 10000;
    return NewFee;
  }
}