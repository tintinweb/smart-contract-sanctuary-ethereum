/**
 *Submitted for verification at Etherscan.io on 2023-03-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract Hash {
    constructor(){}

    function hash(string memory input) pure external returns(bytes32) {
        bytes32 r = keccak256(abi.encodePacked(input));
        return r;
    }

    function hashByte(bytes memory input) pure external returns(bytes32) {
        return keccak256(input);
    }
}