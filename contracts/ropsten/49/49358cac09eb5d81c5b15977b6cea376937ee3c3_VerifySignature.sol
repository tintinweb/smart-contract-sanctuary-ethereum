/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// This contract verifies a signature, it takes in the message, the signature, and the Ethereum address of the signer.
contract VerifySignature {
    function verify(
        bytes memory message,
        bytes memory signature,
        address signer
    ) public view returns (bool) {
        return verifySignature(message, signature, signer);
    }

    function verifySignature(
        bytes memory message,
        bytes memory signature,
        address signer
    ) public view returns (bool) {
        return verify(message, signature, signer);
    }
}