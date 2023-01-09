/**
 *Submitted for verification at Etherscan.io on 2023-01-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISignatureVerifier {
    function validateSignature(bytes32 message, uint[2] memory rs, uint[2] memory Q) external pure returns (bool);
}

contract Verify {
    ISignatureVerifier public signatureVerifier;
    bool public result;

    constructor(address _signatureVerifier) {
        signatureVerifier = ISignatureVerifier(_signatureVerifier);
    }

    function validateSignature(bytes32 message, uint[2] memory rs, uint[2] memory Q) external {
        result = ISignatureVerifier(signatureVerifier).validateSignature(message, rs, Q);
    }
}