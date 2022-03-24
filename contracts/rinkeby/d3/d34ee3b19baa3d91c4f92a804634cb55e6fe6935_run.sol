/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract run {
        int private number;

        function add(int a,int b) public returns(int c) {
            number = a + b;
            c = number;
        } 
        function min(int a,int b) public returns(int) {
            number = a - b;
            return number;
        }
        function mul(int a,int b) public returns(int){
            number = a * b;
            return number;
        }
        function div(int a,int b) public returns(int){
            number = a / b;
            return number;
        }
        function getnumber() public view returns(int){
            return number;
        } 
}