/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

//SPDX-License-Identifier:GPL-3.0
pragma solidity>=0.4.0<0.9.0 ;
contract HELLO{
   string message= "hello world";
      //  function setmessage(string memory _message)pure public {
      // string memory message="hello world";
      //  message = _message ;
 //  }}
   function getmessage()public view returns(string memory){
       return message ;}
   }