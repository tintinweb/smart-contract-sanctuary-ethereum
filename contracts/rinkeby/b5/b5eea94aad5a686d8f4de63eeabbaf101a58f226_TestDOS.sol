/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract TestDOS {
    uint x;

    event Result(uint _x);

    constructor() {
        x = 1;
    }

    function test() external returns (uint256) {
        address(this).call{gas: gasleft()}(abi.encodeCall(TestDOS.inner, ()));
        return x;
    }

    function inner() external {
        uint i = 0;
        while (gasleft() > 3500) {
            x = ++i;
        }
        revert();
    }
}