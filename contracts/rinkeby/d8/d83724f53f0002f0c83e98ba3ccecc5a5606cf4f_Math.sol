/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Math {
function multplyBy20(uint v) public pure returns(uint){
   return v*20;
}

function add20(uint v) public pure returns(uint){
   return v+20;
}
function sub20(uint v) public pure returns(uint){
   return v-20;
}
function div20(uint v) public pure returns(uint){
   return v/20;
}

}