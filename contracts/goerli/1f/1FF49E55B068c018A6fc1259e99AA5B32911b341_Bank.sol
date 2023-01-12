/**
 *Submitted for verification at Etherscan.io on 2023-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;
contract Bank{
    
    address public Owner;
    mapping(address => uint256)public userBalance;


   constructor(){
    Owner = msg.sender;
   }

   modifier onlyOwner(){
       require(msg.sender == Owner,"only Owner can call this function");
       _;
       }


   function deposit() public payable returns(bool){

    require(msg.value >= 10 wei , "you can deposit more than 10 wei");
    userBalance[msg.sender] += msg.value;
    return true;
   }
   function withDraw(uint256 _amount)public payable returns(bool){
       require(_amount <= userBalance[msg.sender],"you dont have insufficient balance");
       userBalance[msg.sender] -= _amount;
       payable(msg.sender).transfer(_amount);
       return true;
   }
   function getBalance()public view returns(uint256){

   return userBalance[msg.sender];

   }
   function getBankBalance()public onlyOwner view returns(uint256){
 
    return address(this).balance;

   }
   function withDrawFunds(uint256 _amount)public payable returns(bool){
    payable(Owner).transfer(_amount);
    return true;
   }

}