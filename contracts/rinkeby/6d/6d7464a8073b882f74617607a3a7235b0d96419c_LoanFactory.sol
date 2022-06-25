/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract LoanFactory{
   Loan[] loans;
   function createCloneLoan() public {
      Loan loan = new Loan();
      loans.push(loan);
   }
   function getLoans() public view returns(Loan[] memory) {
      return loans;
   }

}
contract Loan {
   uint amt;
    function setAmt(uint _amt) public {
        amt = _amt;
    }
   function checkAmt() public view returns(uint) {
      return amt;
   }
}