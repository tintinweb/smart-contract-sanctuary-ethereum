/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Campaign {
    function randomTest(uint256 _revealBlockNumber, bytes32 _revealedSeed) public view returns(uint256) {
        uint256 rand = uint256(
            keccak256(
                abi.encodePacked(blockhash(_revealBlockNumber), _revealedSeed)
            )
        );
        return rand;
    }
    function hashCheck(uint256 _revealBlockNumber) public view returns(bytes32) {
        return blockhash(_revealBlockNumber);
    }
}