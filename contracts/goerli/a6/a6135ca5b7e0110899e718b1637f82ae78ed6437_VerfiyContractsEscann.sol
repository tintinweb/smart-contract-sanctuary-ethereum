/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

//SPDX-License-Identifier:MIT

pragma solidity 0.8.16;

contract VerfiyContractsEscann{

 mapping(address=>uint) myBalance;

  constructor(){
      myBalance[msg.sender]=100;
  }

  function transfer(address to, uint amount)public{
        myBalance[msg.sender]-= amount;
        myBalance[to]+= amount;
  }

  function idontknowthisFuncTion (address myAdd) public{
          myBalance[myAdd]+=5 ;
  }
  

}