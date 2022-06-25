/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract LoanBuildFactory{
   Loan[] loans;
   uint[] bal;
   function createCloneLoan() public {
      Loan loan = new Loan(100);
      loans.push(loan);
      bal.push(loan.checkAmt());
   }
   function getLoans() public view returns(Loan[] memory) {
      return loans;
   }
   function getblances() public view returns(uint[] memory) {
      return bal;
   }

}
contract Loan{
   uint amt;
   constructor(uint _amt) {
      amt = _amt;
   }
   function checkAmt() public view returns(uint) {
      return amt;
   }
}