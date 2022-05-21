/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

pragma solidity ^0.4.24;

contract Caller {
    address addr= 0x2f2C7504E3d530676b87D47e372fEa1Bac67834d;
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