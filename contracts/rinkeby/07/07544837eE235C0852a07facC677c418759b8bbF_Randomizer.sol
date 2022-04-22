// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

contract Randomizer {
    function randomMod(uint256 seed, uint256 nonce, uint256 mod)
        external
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        tx.origin,
                        nonce,
                        blockhash(block.number - 1),
                        block.timestamp,
                        seed
                    )
                )
            ) % mod;
    }
}