/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: GPL-3.0

contract Test01{






  function getBalance()public view returns(uint){
       return address(this).balance;
   }

   function inserisci() payable public{

   }

   function trasferisci(address payable owner, uint amount) payable public{
    owner.transfer(amount);
   }

  


}