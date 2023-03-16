/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

contract Test {
    
    uint256 public x;
    string public str;
    address public adr;

    function f1(uint256 _x) public {
        x = _x;
    }
    
    function f2(uint256 _x, string calldata _str) public {
        x = _x;
        str = _str;
    }

    function f3(uint256 _x, string calldata _str, address _adr) public {
        x = _x;
        str = _str;
        adr = _adr;
    }
}