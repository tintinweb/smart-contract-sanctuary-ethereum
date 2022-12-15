// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Counter {
    uint256 public counter;

    function plus(uint256 _amount) public {
        counter += _amount;
    }

    function minus(uint256 _amount) public {
        counter -= _amount;
    }
    
    function times(uint256 _amount) public {
        counter *= _amount;
    }
    
    function divide(uint256 _amount) public {
        counter /= _amount;
    }
}