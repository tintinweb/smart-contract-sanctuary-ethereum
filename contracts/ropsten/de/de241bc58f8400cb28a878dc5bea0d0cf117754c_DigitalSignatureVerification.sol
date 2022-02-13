/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DigitalSignatureVerification {

    mapping(string => bytes32) public documents;    

    function registerDocumentChecksum(string memory documentId, address author, bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s) external {
        address signer = VerifyMessage(_hashedMessage, _v, _r, _s);

        require(
            author == signer,
            "Document author signature required for the transaction."
        );

        documents[documentId] = _hashedMessage;
    } 

    function getDocumentChecksum(string memory documentId) public view returns (bytes32) {
        return documents[documentId];
    }

    function VerifyMessage(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s) internal pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

}