/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: UNLICENSED

contract Loan{
    
    address admin;
    mapping(string => debt) private debts;
    

    modifier onlyOwner(){
        require(msg.sender == admin);
        _;

    }

    // construct debt and send money to debtor 
    constructor() {
        admin = msg.sender;
        
    }

    struct debt{
        string debtName;
        string debtorName;
        string debtID;
        uint debtAmount;
        uint debtInterest;
        address payable debtorWalletID;
        address payable debtOwnerWallet;
        string debtType;


    }
    // pay down the debt
    function payDebt(string memory debtID,uint amount) payable public{
        debts[debtID].debtAmount -= amount;
        if (debts[debtID].debtAmount < 0){
            revert("too much");
        }else{

            debts[debtID].debtorWalletID.transfer(msg.value);
            if (debts[debtID].debtAmount == 0){
                delete debts[debtID];
            }
        }

        
        
    }

    function  createDebt(string memory debtID, uint debtAmount, uint debtInterest,string memory debtName,string memory debtorName,
        address payable debtOwnerWallet,address payable debtorWallet,string memory debtType) public payable{
            debts[debtID] = debt(debtName,debtorName,debtID,debtAmount,debtInterest,debtorWallet,debtOwnerWallet,debtType);
            debtorWallet.transfer(msg.value);
        }
    // view debt amount
    function viewDebtAmount(string memory debtID) public view returns (uint){
        return debts[debtID].debtAmount;

    }
    


}