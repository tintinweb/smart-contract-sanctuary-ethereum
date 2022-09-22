/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract CAL {
    function jegop(uint a) public view returns(uint){
        a = a*a;
        return a;
    }
    function sejegop(uint a) public view returns(uint){
        a = a*a*a;
        return a;
    }
    function div(uint a, uint b) public view returns(uint, uint){
        return (a/b, a%b);
    }
}