// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract wallet{

    mapping(address =>uint ) public accounts;
    function  addMoney(uint amount) public {
        accounts[msg.sender]+=amount;
        
    }
    function mintFunds (uint amount,address payable to) public payable{
 require(accounts[msg.sender]>=amount,"in sufficient amount");
         to.transfer(amount);
         accounts[msg.sender]-=amount;
        
    }
    function  amountCheck(address add) public view returns(uint){
      return(accounts[add]);  
    } 
}