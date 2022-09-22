/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract A101{
    function squ(uint a) public returns(uint){
        return a*a;
    }
    function squ3(uint a) public returns(uint){
        return a*a*a;
    }
    function div_mod(uint a, uint b) public returns(uint, uint){
        return (a/b, a%b);
    }
}