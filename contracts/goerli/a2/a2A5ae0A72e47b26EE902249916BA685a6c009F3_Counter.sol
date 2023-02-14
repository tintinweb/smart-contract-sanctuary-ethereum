// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Counter {
    uint public count;

    //加
    function inc() external {
        count += 1;
    }

    //减
    function des() external {
        count -= 1;
    }
}