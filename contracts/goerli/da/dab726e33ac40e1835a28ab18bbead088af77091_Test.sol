/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Test {
    address immutable private owner; 
    uint public val;
    constructor (address _owner) {
        owner = _owner;
    }

    function setVal(uint _val) public {
        require(msg.sender == owner, "Not an owner!"); 
        val = _val;
    }
}