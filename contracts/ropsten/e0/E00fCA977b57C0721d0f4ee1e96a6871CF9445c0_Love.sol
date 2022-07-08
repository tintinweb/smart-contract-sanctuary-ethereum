/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Love {
      address  public owner;
     constructor(){
         owner = msg.sender;
     }
      function deposit() public payable {}
     function  love() public view  returns(uint256){
             return  address(this).balance;
     }

     function change(address addr) public returns(address){
          owner = addr;
          return owner;
     }




}