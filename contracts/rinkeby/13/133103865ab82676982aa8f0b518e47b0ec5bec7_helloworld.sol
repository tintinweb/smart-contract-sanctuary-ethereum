/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract helloworld {
    int private result;
function add(int a,int b) public returns(int c) {
    result=a+b;
    c=result;
}
function subtraction(int a,int b) public returns(int c) {
    result=a-b;
    c=result;
}
function multiplication(int a,int b) public returns (int c) {
    result=a*b;
    c=result;
}
function division(int a,int b) public returns (int ) {
    result=a/b;
    return result;
}
function getresult() public view returns(int) {
    return result;
}
}