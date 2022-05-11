// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Bytes {
    bytes16 public a;

    function convert(bytes32 b) public {
        a = bytes16(b);
    }
}