// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

library Test {
    function hoge() external {

    }

    function hoge2(uint256 a) pure external returns(uint256) {
        return a + 1;
    }
}