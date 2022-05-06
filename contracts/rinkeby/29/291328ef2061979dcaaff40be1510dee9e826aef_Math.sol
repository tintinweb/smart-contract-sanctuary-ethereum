/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Math{
    function addition(uint a, uint b) public view returns(uint){
    return a+b;
    }

    function subtraktion(uint a, uint b) public view returns(uint){
        return a-b;
    }

    function division(int a, int b) public view returns(int){
        return a/b;
    }

    function multiplication(int a, int b) public view returns(int){
        return a*b;
    }
}