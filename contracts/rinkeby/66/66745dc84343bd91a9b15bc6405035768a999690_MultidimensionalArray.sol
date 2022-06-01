/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

/**
 *Submitted for verification at Etherscan.io on 2020-07-08
*/

/**
 *Submitted for verification at Etherscan.io on 2020-06-11
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;


contract MultidimensionalArray {
    uint256[][][][] public trySomethingDumb;
    
    function callMe(uint256[] memory _a) public returns (uint256) {
        if(_a.length == 0) {
            return 0;
        } else {
            return _a.length;
        }
    } 
    
    function callMe(uint256[][] memory _a) public returns (uint256) {
        if(_a.length == 0) {
            return 0;
        } else {
            return _a.length;
        }
    } 
    
    function callMe(uint256[][][] memory _a) public returns (uint256) {
        if(_a.length == 0) {
            return 0;
        } else {
            return _a.length;
        }
    } 
    
    function callMe(uint256[][][][] memory _a) public returns (uint256) {
        if(_a.length == 0) {
            return 0;
        } else {
            trySomethingDumb = _a;
            return _a.length;
        }
    } 
}