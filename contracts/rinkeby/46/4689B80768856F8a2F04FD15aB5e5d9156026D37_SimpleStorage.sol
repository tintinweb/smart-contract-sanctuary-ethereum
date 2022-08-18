// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract SimpleStorage{
    uint public a = 30;

    function set(uint c) public {
        a = c;
    }
}