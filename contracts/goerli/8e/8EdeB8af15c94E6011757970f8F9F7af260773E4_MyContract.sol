/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;
  
contract MyContract{
      address public Owner;
         constructor(){
             Owner = msg.sender;
         }

     function transferOwnership(address _newOwner) public {
              require(msg.sender == Owner);
              Owner = _newOwner;  
          }
}