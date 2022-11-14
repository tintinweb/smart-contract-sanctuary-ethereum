/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract RentContractBetween_1Landlord_1Rentee {
    uint public rentDue=0; 
                     // here we are assuming that there is only 1 landlord and 1 Rentee only
    uint public DepositeRentBalance=0;
    mapping(address => uint) BALANCE;
    address owner;
    
    constructor() {
        owner = msg.sender; // address that deploys contract will be the owner
    }
    function setRent(uint _rent) public{ // only the landlord can set the rent
        require(msg.sender==owner,"Only landlord can set rent");
        rentDue=_rent;
    }
    
    function setWalletBalance(uint _toAdd) public returns(uint) {
        BALANCE[msg.sender] += _toAdd;    // setting the walletbalancing
        return BALANCE[msg.sender];
    }
    
    function getWalletBalance() public view returns(uint) {
        return BALANCE[msg.sender];   // for checking the users balance
    }
    
    function DepositeRent(uint amount) public {
        require(rentDue!=0,"No rent due");
        require(msg.sender != owner, "only rentee can depoite"); 

        require(rentDue==amount , "set proper amount  to transfer BALANCE");   // rentDue and amount to be transfer to the user should be same neither less nor more

        _transfer(msg.sender,amount);
    }
    
    function _transfer(address from, uint amount) private {  // transfer the wallet balance between the landlord and rentee
        BALANCE[from] -= amount;   // deducting amount from senders wallet
        DepositeRentBalance+=amount;     // adding amount to the receptient's wallet
        rentDue=0; // resetting the rent to 0;
    }


    function withdrawnRentAmount() public {
        require(msg.sender==owner,"only landlord can withdraw the rent");
        require(DepositeRentBalance!=0, "Insufficent amount to withdraw");   // rentDue and amount to be transfer to the user should be same neither less nor more
        BALANCE[msg.sender]+=DepositeRentBalance;
         DepositeRentBalance=0;
    }

}