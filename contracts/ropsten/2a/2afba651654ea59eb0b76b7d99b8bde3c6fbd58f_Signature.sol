/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Signature {
    struct SignMessage {
        address signer;
        string signText;
        string signURI;
    }

    struct NFT {
        address nftContract;
        uint tokenId;
    }

    // Token dictionary
    mapping(bytes32 => NFT) public tokenDictionary;

    // User signed list
    mapping(address => bytes32[]) public signedList;

    // NFT signature list
    mapping(bytes32 => SignMessage[]) public signatureList;

    function hashToken(address nftContract, uint tokenId)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(nftContract, tokenId));
    }

    function sign(
        address nftContract,
        uint tokenId,
        string memory signText,
        string memory signURI
    ) public {
        bytes32 tokenHash = hashToken(nftContract, tokenId);

        // Check if token is already in the dictionary
        if (!_isTokenInDict(tokenHash)) {
            tokenDictionary[tokenHash] = NFT(nftContract, tokenId);
        }

        // Add to signed list
        signedList[msg.sender].push(tokenHash);

        // Add to NFT signature list
        signatureList[tokenHash].push(
            SignMessage(msg.sender, signText, signURI)
        );
    }

    function getSignedList(address singer)
        public
        view
        returns (bytes32[] memory)
    {
        return signedList[singer];
    }

    function getNFTSignatureList(address nftContract, uint tokenId)
        public
        view
        returns (SignMessage[] memory)
    {
        bytes32 tokenHash = hashToken(nftContract, tokenId);
        return signatureList[tokenHash];
    }

    function _isTokenInDict(bytes32 tokenHash) internal view returns (bool) {
        return tokenDictionary[tokenHash].tokenId != 0;
    }
}