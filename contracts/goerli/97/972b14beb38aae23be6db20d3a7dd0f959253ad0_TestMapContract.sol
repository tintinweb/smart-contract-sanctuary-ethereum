/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract TestMapContract{
   mapping (address => string ) public userName;
   mapping (address=>uint)public userAge;
   function setName(address id,string memory name)public{
       userName[id]=name;
      
   }
   function setAge(address id,uint age)public{
 userAge[id]=age;
   }
  
        function getName(address id) public view  returns (string memory) {
        return userName[id];
    }
    function getAges(address id) public view returns (uint){
return userAge[id];
    }
    

}
// Mapping -UserNames
//address=>string
// 2) userAges  address=>uint
// function() name+age =msg.sender