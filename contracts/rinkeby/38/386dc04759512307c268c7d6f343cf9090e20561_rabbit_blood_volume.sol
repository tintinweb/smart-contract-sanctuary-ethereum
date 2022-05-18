/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;                 

contract rabbit_blood_volume/*玄兔的血量*/{            

    uint256 public blood_volume = 100; // HP有100                               
    
     function Injuried ( uint256 blood_loss ) public returns(uint256) { 
      blood_volume= blood_volume - blood_loss ;   
      return  blood_volume;
     }// 受傷流血

    function eating_herbs(uint256 blood_add ) public returns(uint256){          
      blood_volume = blood_volume + blood_add ;  
      return blood_volume;                                  
     }//吃草藥恢復

}