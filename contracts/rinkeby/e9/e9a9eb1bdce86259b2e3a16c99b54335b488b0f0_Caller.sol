/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Caller {
    function someAction(address addr) public returns(uint) {
        Callee c = Callee(addr);
        return c.getValue(100);
    }
    
    function storeAction(address addr) public returns(uint) {
        Callee c = Callee(addr);
        c.storeValue(100);
        return c.getValues();
    }
}

abstract contract Callee {
    function getValue(uint initialValue) public virtual returns(uint);
    function storeValue(uint value) public virtual;
    function getValues() public virtual returns(uint);
}