// SPDX-License-Identifier: GPL-3.0
// 开源许可表示符 SPDX

pragma solidity ^0.8.11;  
contract ListeningEvents {      
   
   event NewEvent(address indexed newAddress, uint aValue);
   
   function emitEvent(uint val) public {          
      emit NewEvent(msg.sender, val);      
   }
}