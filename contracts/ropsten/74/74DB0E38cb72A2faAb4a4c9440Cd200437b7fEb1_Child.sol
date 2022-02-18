/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Child {
    uint256 public value;
    // address public owner;

    // constructor(address _owner, uint256  _value) payable {
    //     value = _value;
    //     owner = _owner;
        
    // }
    function inc()public returns(uint256){
        value = value+1; 
        return value;
    }
}