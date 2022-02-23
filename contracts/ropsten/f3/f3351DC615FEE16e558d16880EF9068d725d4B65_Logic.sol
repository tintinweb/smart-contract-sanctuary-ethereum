// SPDX-License-Identifier: MIT 

pragma solidity ^0.7.0;

contract Logic {
    
    event Added(uint256 result);
    event Fallback();
    
    function add(uint256 a, uint256 b) external returns (uint256 result) {
        result = a +b;
        emit Added(result);
    }
    
    fallback() external {
        emit Fallback();
    }
}