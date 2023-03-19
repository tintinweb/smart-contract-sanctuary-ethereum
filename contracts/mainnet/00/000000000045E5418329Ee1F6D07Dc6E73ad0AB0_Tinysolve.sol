// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

contract Tinysolve {

    mapping(address => bytes32) public hashes;

    function setHash(bytes32 _hash) external {
        hashes[msg.sender] = _hash;
    }

    fallback(bytes calldata) external returns (bytes memory res) {
        res = abi.encode(
            hashes[tx.origin],
            uint8(28),
            bytes32(0x00000000000000000000003b78ce563f89a0ed9414f5aa28ad0d96d6795f9c63)
        );
    }
}