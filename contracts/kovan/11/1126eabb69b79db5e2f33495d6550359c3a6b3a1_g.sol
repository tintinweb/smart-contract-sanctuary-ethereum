/**
 *Submitted for verification at Etherscan.io on 2022-04-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract g{
  constructor() {
}
uint24 n=0;
mapping (uint24 =>address) public e;
function plant(uint24 wood) payable  public{
    require(e[wood]==0x0000000000000000000000000000000000000000 && msg.value==1000000000000000 && wood<((2**24)-1));
    e[wood]=msg.sender;
    n++;
    payable(msg.sender).transfer(200000000000000);}

  

  function get (uint24 wood) public {
    if(e[wood]==msg.sender)
    if(e[(wood*2+1)]!=0x0000000000000000000000000000000000000000 && e[(wood*2+2)]!=0x0000000000000000000000000000000000000000 || (n==2**24-1 && wood>2**23-2)){
    e[wood]==0x0000000000000000000000000000000000000001;
    payable(msg.sender).transfer(200000000000000);}
   }

function p(uint24 w) public pure returns (uint24 y , uint24 z){
y=w*2+1;z=w*2+2;
}
  }