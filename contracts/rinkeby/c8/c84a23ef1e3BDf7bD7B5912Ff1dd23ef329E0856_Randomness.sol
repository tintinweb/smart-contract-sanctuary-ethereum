// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


contract Randomness {

    function getRandomNumber(bytes memory input) external view returns(uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty, 
                    block.timestamp, 
                    block.gaslimit,
                    blockhash(block.number-1),
                    input
                )
            )
        );
    }

}