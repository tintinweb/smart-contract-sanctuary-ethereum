/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract { //contract's name 
   
   
//private


string _Contract_ID;  //contract ID
string _Borrower_Detial;  // รายละเอียดคนกู้
string _Lender_Detial; // รายละเอียดคนให้กู้
string _Contract_Detial; // รายละเอียดสัญญา


  function createContractLoan(string memory Contract_ID, string memory Borrower_Detial, 
   string memory Lender_Detial, string memory Contract_Detial) public {
  
     _Contract_ID = Contract_ID;
     _Borrower_Detial = Borrower_Detial;
     _Lender_Detial = Lender_Detial;
     _Contract_Detial = Contract_Detial;

              
  }
  
    function getContractID() public view returns(string memory Contract_ID){

      return _Contract_ID;
  }

  function getBor() public view returns(string memory Borrower_Detial){

      return _Borrower_Detial;
  }

    function getLen() public view returns(string memory Lender_Detial){

      return _Lender_Detial;
  }

    function getContractDetial() public view returns(string memory Contract_Detial){

      return _Contract_Detial;
  }




}