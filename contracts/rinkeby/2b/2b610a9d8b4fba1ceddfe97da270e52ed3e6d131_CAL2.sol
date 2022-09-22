/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract CAL2{
    function squared(int a) public view returns(int){
        return a*a;
    }

    function cubic(int a) public view returns(int){
        return a*a*a;
    }

    function divison(uint a, uint b) public view returns(uint,uint){
        return (a/b,a&b);
    }
}