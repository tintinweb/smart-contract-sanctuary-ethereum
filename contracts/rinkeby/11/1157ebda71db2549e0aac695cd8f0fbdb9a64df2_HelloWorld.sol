/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// File: contracts/nagaDao/HelloWorld.sol

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;


contract HelloWorld{
    string public hello = "Hello World!";


    string public fullName = "kathamas petcharat";
    string public nickName = "Kaii";

    uint public age = 45 ;
    uint public money = 0;



   function depositMoneys(uint _amount) public{
       money = _amount;
   }


    
}