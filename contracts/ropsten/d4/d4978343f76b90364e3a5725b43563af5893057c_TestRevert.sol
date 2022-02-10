/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface callee {
    function set() external returns(bool);

}

contract TestRevert {

    uint256 a;
    uint256 b;
    uint256 c;
    uint256 d;

    function set() public returns(bool) {
        a = 1;
        b = 2;
        c = 3;
        d = 4;

        return true;
    }

    function reset() public returns(bool) {
        a = 0;
        b = 0;
        c = 0;
        d = 0;

        callee cc = callee(0xC81E976063bb359b93044dEc024a8a3d633b09ec);
        cc.set();

        return true;
    }

    function get() public view returns(uint256) {
        return a + b + c + d;
    }

}