/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

pragma solidity >=0.7.0 <0.9.0; //設定跟編譯器 相關的功能:對應語法的版本

  contract PiggyBank{

    uint public goal ;
    constructor  (uint _goal){
       goal=_goal;
     }

    receive() external payable{}

     function getMyBalance() public view returns (uint){
     return address(this).balance;
      }

     function withdraw() public{
     if ( getMyBalance()> goal) 
     {
            selfdestruct( payable(msg.sender));
         
         }
    }

  }