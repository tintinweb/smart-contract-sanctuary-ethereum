//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Sha {
    function hash(bytes memory x) public pure returns (bytes32) {
        bytes32 y = sha256(x);
        return y;
    }
}