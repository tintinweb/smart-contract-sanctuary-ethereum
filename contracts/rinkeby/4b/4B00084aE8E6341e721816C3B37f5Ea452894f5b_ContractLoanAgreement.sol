/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract ContractLoanAgreement { //contract's name 
    //private
    string _Contract_ID;  //contract ID
    string _Borrower_Detail;  // รายละเอียดคนกู้
    string _Lender_Detail; // รายละเอียดคนให้กู้
    string _Contract_Detail; // รายละเอียดสัญญา

    function createContractLoan(string memory Contract_ID, string memory Borrower_Detail, 
    string memory Lender_Detail, string memory Contract_Detail) public {
        _Contract_ID = Contract_ID;
        _Borrower_Detail = Borrower_Detail;
        _Lender_Detail = Lender_Detail;
        _Contract_Detail = Contract_Detail;
    }

    function getContractID() public view returns(string memory Contract_ID){
        return _Contract_ID;
    }

    function getBorrowerDetail() public view returns(string memory Borrower_Detail){
        return _Borrower_Detail;
    }

    function getLenderDetail() public view returns(string memory Lender_Detail){
        return _Lender_Detail;
    }

    function getContractDetial() public view returns(string memory Contract_Detail){
        return _Contract_Detail;
    }
}