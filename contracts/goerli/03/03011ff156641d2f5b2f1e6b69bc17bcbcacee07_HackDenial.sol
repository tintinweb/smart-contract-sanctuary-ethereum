// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract HackDenial {
    receive() payable external {
        assert(false);
    }
}