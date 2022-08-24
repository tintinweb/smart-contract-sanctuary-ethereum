// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Information {
    bytes internal secret;

    constructor(bytes memory _secret) {
        secret = _secret;
    }

    function reveal() public view returns (bytes memory) {
        return secret;
    }
}