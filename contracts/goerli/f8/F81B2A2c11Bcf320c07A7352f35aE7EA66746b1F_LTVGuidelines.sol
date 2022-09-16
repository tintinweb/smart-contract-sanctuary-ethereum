// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract LTVGuidelines {
    uint256 maxLoanToValue;

    constructor() {                  
        maxLoanToValue = 80;        
    } 
 
    // Defining function to 
    // return the value of 'str'  
    function getMaxLTV() public view returns (uint256) {        
        return maxLoanToValue;        
    } 
}