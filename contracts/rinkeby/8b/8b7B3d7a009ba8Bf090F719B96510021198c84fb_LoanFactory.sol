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
      // loan.setAge(41);
   }
   function getLoans() public view returns(Loan[] memory) {
      return loans;
   }
   function getAge() public view returns(uint){
      Loan loan = Loan(loans[0]);
      return loan.getAge();
   }
   function setAge(uint _age) public {
      Loan loan = Loan(loans[0]);
      loan.setAge(_age);
   }

}
contract Loan {

   address admin;
   uint age;

   constructor() {
      admin = msg.sender;
    }
   function getMsgSender() public view returns(address){
      return admin;
    }
   function setAge(uint _age) public {
      require(msg.sender == admin);
      age = _age;
   }
   function getAge() public view returns(uint) {
      return age;
   }
}