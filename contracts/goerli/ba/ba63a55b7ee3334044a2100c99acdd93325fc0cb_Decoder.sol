// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Decoder {
    function decode(address to, bytes memory data) public returns (bytes memory) {
        (bool success, bytes memory result) = to.call(data);
            require(!success, "Shit happens");
                return result;
        }
 }