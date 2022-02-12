/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Caller {
    function someAction(address addr) public returns(uint) {
        ICallee c = ICallee(addr);
        return c.getValue(100);
    }
    
    function storeAction(address addr) public returns(uint) {
        ICallee c = ICallee(addr);
        c.storeValue(100);
        return c.getValues();
    }
    
    // function someUnsafeAction(address addr) public {
    //     addr.call(bytes4(keccak256("storeValue(uint256)")), 100);
    // }
}

interface ICallee {
    function getValue(uint initialValue) external returns(uint);
    function storeValue(uint value) external;
    function getValues() external returns(uint);
}