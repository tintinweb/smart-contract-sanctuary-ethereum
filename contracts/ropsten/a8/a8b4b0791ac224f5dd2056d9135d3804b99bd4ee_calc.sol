/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

pragma solidity >=0.4.22 <=0.8.0;
// SPDX-License-Identifier: SimPL-2.0

contract calc{

int private num;

function add(int a , int b) public returns (int){
    num=a+b;
    return num;
}

function min(int a, int b) public returns(int){
    num=a-b;
    return num;
}

function mul(int a ,int b) public returns(int){
num=a*b;
return num;
}

function div(int a ,int b) public returns(int){
num=a/b;
return num;
}

function getNum() public view returns(int){
  return num;
}



}