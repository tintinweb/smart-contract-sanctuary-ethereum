// contracts/Test.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
contract Test {
    uint public c;
    
    function add(uint _num) external {
       c += _num;
    }

    function setC(uint _c) external {
        c = _c;
    }
}