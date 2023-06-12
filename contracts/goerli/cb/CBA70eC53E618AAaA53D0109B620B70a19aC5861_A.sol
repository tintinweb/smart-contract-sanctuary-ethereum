/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.18;

contract A {

    uint public a;

    function getThis() public view returns(address) {
        return address(this);
    }

    function changeA(uint _a) public {
        a = _a;
    }

    function mul(uint _a, uint _b, uint _c) public pure returns(uint) {
        return _a*_b*_c;
    }
}