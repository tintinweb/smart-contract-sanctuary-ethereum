/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Advanced{
   string private _x;

   constructor(string memory x){
     _x = x;
   }

   function getInfo() public view returns(string memory){
        return _x;
   }
}