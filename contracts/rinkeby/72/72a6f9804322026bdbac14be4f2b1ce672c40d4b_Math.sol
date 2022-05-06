/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Math{

    function Addition(uint v1, uint v2) public view returns(uint){
        return v1+v2;
    }

    function Subtraktion(uint v1, uint v2) public view returns(uint){
        return v1-v2;
    }

    function Division(uint v1, uint v2) public view returns(uint){
        return v1/v2;
    }

    function Multiplikation(uint v1, uint v2) public view returns(uint){
        return v1*v2;
    }
}