// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract DuckTuitionFees {
  int TuitionFees = 0;
  function setTuitionFees(int NewFee) public  {
    TuitionFees = NewFee;
  }
  function getTuitionFees() public view returns (int){
    return TuitionFees;
  }
}