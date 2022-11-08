// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

contract msgvalue {
    function test() public payable returns (uint) {
        return msg.value;
    }
}