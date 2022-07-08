// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Test {
    event Fused(
        address sender,
        uint256 fusedId,
        uint256 burnedId,
        bytes32 fusionReceiptIPFSHash
    );

    function test(
        address sender,
        uint256 fusedId,
        uint256 burnedId,
        bytes32 fusionReceiptIPFSHash
    ) public {
        emit Fused(sender, fusedId, burnedId, fusionReceiptIPFSHash);
    }
}