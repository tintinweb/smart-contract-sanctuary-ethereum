// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StringTools {
    function equal(string memory s1, string memory s2) public pure returns (bool) {
        return (keccak256(abi.encode(s1)) == keccak256(abi.encode(s2)));
    }

    function empty(string memory s) public pure returns (bool) {
        return equal(s, "");
    }
}