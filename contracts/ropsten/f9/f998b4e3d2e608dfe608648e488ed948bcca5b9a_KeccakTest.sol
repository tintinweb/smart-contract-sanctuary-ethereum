/**
 *Submitted for verification at Etherscan.io on 2022-04-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

contract KeccakTest {
    function getKeccak(string calldata input)
    external
    pure
    returns (bytes32)
    {
        return keccak256(bytes(input));
    }
}