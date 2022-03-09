/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract TestMapContract{
   mapping (address => string ) public userName;
   mapping (address=>uint)public userAge;
   function set_Name_Age(address id,string memory name,uint age)public{
       userName[id]=name;   
       userAge[id]=age;
   }
  
    function get_Name_Age(address id) public view  returns (string memory,uint) {
        return (userName[id],userAge[id]);
        }
}
// Mapping -UserNames
//address=>string
// 2) userAges  address=>uint
// function() name+age =msg.sender