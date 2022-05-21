/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

pragma solidity ^0.4.24;

contract Caller {
     address addr= 0x692a70d2e424a56d2c6c27aa97d1a86395877b3a;
    function someAction(address addr) returns(uint) {
        Callee c = Callee(addr);
        return c.getValue(100);
    }
    
    function storeAction(address addr) returns(uint) {
        Callee c = Callee(addr);
        c.storeValue(100);
        return c.getValues();
    }
    
    function someUnsafeAction(address addr) {
        addr.call(bytes4(keccak256("storeValue(uint256)")), 100);
    }
}

contract Callee {
    function getValue(uint initialValue) returns(uint);
    function storeValue(uint value);
    function getValues() returns(uint);
}