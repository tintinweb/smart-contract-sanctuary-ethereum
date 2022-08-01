/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract ContractTest{

    string arbString;
    uint arbInt;

    constructor(string memory _arbString, uint _arbInt){
        arbString = _arbString;
        arbInt = _arbInt;
    }

    function multiplyInt(uint _multiplier) external{
        arbInt = arbInt * _multiplier;
    }

    function getArbInt() public view returns(uint){
        return arbInt;
    }

    function getArbString() public view returns(string memory){
        return arbString;
    }



}