/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Math{
    function add100(uint v) public pure returns(uint){
        return v + 100;
    }

    function divideBy2(uint v) public pure returns(uint){
        return v / 2;
    }
}