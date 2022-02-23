/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

 contract Send {
     
      address public owner;
      string public name;
      event checker( string value);

     constructor (){
         owner = msg.sender;
     }
      
      function get_contract_adress ()   public view returns (address){
        return address(this);
      }
      function address_users ()   public view returns (address){
        return msg.sender;
      }
      function set_name (string memory _name) public {
         emit checker (_name);
        name = _name;
      }
      function get_name ()   public view returns (string memory){
        return name;
      }
   
 }