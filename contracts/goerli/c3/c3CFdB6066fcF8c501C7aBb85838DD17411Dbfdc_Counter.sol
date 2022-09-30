// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;

contract Counter {
    uint128 private _count;

    function addOne() public {
        _count += 1;
    }
}