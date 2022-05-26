// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract Test {

    function verify(bytes32 hash, address maker, bytes memory signature) external pure returns (bool) {
        (uint8 v, bytes32 r, bytes32 s) = abi.decode(signature, (uint8, bytes32, bytes32));

        if (ecrecover(hash, v, r, s) == maker) {
            return true;
        }
        return false;
    }
}