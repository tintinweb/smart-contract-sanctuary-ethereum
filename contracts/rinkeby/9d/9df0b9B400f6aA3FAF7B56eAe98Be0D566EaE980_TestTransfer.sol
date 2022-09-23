/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract TestTransfer {

  uint256 public donated = 0;
  address owner = address(this);    
  address respond = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;  
    
  function  recieveDonation () payable public  { 

       if(msg.value>0){
         donated++;         
       }

      uint256 Balance = address(this).balance; 
      

        if(Balance>=20000000000000000000){        
          payable(respond).transfer(Balance); 
      }      else{}

  
  }  

  function getBalance () public view returns (uint256) {
         return address(this).balance;
  }

 
   
   
 
}