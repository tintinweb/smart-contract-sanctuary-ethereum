/**
 *Submitted for verification at Etherscan.io on 2022-03-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Storage
 */
contract Storage {
   
    uint256[] public arr;
    
    function addArr(uint256 i) external {
        arr.push(i);
    }
    
    function delArr() external {
        delete arr;
    }
    
    function popArr() external {
        arr.pop();
    }
}