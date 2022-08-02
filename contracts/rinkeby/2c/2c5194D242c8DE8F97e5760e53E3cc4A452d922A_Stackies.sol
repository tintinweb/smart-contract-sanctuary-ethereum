/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;



// File: stackies.sol

contract Stackies {
    uint public valueX;
    uint public valueY;
    uint public minFee;
    uint public result;

    constructor(uint _minFee, uint _valueX, uint _valueY){
        minFee = _minFee;
        valueX = _valueX;
        valueY = _valueY;        
    }

    modifier checkEven(uint valueY){
        if(valueY % 2 == 0){
            _;
        }
    }

    function multiply(uint valueX, uint valueY) public checkEven(valueY){
        result = valueX * valueY;
    }

    function multiplyValues(uint valueX, uint valueY) public returns (uint result){
        result = valueX * valueY;
        return result;
    }

}