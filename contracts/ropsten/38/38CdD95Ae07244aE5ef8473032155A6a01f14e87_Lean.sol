/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


  contract Lean{

      function SendEth() external payable{
           if(msg.value < 2030){
               revert();

           }
            
      }

      function blanaceOf()external view returns(uint){
          return address(this).balance;
      }
  
}