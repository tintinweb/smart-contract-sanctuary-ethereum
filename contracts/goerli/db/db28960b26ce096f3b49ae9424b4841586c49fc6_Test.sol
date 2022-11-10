/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.3;


contract Test {
    address public a;
    bytes public data;

    function test(address _a, bytes calldata _data) public {
        a = _a;
        data = _data;
    }
}