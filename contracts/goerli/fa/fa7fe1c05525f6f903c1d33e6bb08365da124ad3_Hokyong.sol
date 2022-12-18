/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract Hokyong{

 uint a = 1;
 uint b = 2;
 uint c = 0;

 function Hokyong_1() public view returns(uint){
     return c;
 }
 
 function Hokyong_2() public{
     c = a+b ;
 }

 function Hokyong_3() external payable{

     c = a+b ;
 }
}