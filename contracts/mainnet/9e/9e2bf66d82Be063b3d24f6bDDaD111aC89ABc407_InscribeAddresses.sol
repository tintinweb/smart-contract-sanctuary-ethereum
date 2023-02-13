/**
 *Submitted for verification at Etherscan.io on 2023-02-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract InscribeAddresses {

    function InscribeAddress(bytes32 inscriptionTx) external pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(inscriptionTx)))));
    }

    function InscribeAddressWithString(string memory inscribeData) external pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(inscribeData)))));
    }

}