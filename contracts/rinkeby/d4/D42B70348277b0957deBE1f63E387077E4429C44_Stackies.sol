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

    function multiply(uint valueY) public checkEven(valueY){
        valueX = valueX * valueY;
    }

}