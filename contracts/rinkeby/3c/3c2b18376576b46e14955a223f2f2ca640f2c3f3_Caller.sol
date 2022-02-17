/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Caller {
    function someAction(address addr) public pure returns(uint) {
        Callee c = Callee(addr);
        return c.getValue(100);
    }
}

abstract contract Callee {
    function getValue(uint initialValue) public pure virtual returns(uint);
}