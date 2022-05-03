/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

//SPDX-License-Identifier:MIT
pragma solidity>=0.7.0<0.9.0;
contract owneR{
  // address private owner;
    address public owner;
    event setowner(address indexed owner);
 function SETOWNER()public {
        owner=msg.sender;
        emit setowner(owner); 
    }
 //  function getcurrentowner()external view returns(address){
   //     return owner;
  //  }
}