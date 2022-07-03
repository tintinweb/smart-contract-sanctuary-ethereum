/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


contract RandomNumberAttack {

    function guessTheNumber(
        bytes32 _block_number,
        uint256 _block_timestamp
    ) external pure returns(uint32)
    {
        uint32 guess = uint32(uint256(keccak256(abi.encodePacked(_block_number, _block_timestamp))));
        return guess;
    }
}