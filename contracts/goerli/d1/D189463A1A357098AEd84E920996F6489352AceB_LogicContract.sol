// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract LogicContract{
    
    function addSomething(uint256 _a, uint256 _b) public pure returns(uint256 result){
        return _a + _b;
    }
}