/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PayReward {

    bool public state; // is the pay reward active?
    uint256 public minValue; // minimun Value that should unlock reward in Wei
    address private owner;  // contract owner


    constructor(){
        owner = msg.sender;
        state = false;
        minValue = 1000000000000000;
    }

    function setState() public {
        if (msg.sender == address(owner)){
            state = !state;
        }
    }

    function getState() public view returns(bool){
        return state;
    }

    /** _minValue is in Wei */
    function setMinValue(uint256 _minValue) public {
        if (msg.sender == address(owner)){
            minValue = _minValue;
        }
    }

    function getMinValue() public view returns(uint256){
        return minValue;
    }

}