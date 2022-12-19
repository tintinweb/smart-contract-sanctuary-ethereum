// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract CounterV2 {

uint public num ; 
 function setter(uint _num) public {
     num=_num;
 } 
function getter() public view returns(uint ) {
    return num; 
}
function increment() public {
    num++;
}
}