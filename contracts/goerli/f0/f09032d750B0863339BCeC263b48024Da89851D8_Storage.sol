/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract Storage {
    uint256 private _number;
    
    function set(uint256 num) public {
        _number = num;
    }
    
    function get() public view returns (uint256){
        return _number;
    }
}