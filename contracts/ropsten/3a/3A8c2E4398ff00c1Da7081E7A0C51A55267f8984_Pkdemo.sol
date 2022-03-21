/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;
 contract Pkdemo {
     uint number;
     function set(uint _number) public {
         number = _number+1;
     }
     function get() public view returns(uint){
         return number;
     }
 }