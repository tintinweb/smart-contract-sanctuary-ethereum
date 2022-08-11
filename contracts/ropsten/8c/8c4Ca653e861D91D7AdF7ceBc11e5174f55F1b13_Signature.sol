/**
 *Submitted for verification at Etherscan.io on 2022-08-11
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

    function hashToken(address _nftContract, uint _tokenId)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_nftContract, _tokenId));
    }

    event SignEvent(
        address signer,
        bytes32 tokenHash,
        string signText,
        string signURI
    );

    function sign(
        address _nftContract,
        uint _tokenId,
        string memory _signText,
        string memory _signURI
    ) public {
        bytes32 tokenHash = hashToken(_nftContract, _tokenId);

        // Check if token is already in the dictionary
        if (!_isTokenInDict(tokenHash)) {
            tokenDictionary[tokenHash] = NFT(_nftContract, _tokenId);
        }

        // Add to signed list
        signedList[msg.sender].push(tokenHash);

        // Add to NFT signature list
        signatureList[tokenHash].push(
            SignMessage(msg.sender, _signText, _signURI)
        );

        emit SignEvent(msg.sender, tokenHash, _signText, _signURI);
    }

    function getSignedList(address _signer)
        public
        view
        returns (bytes32[] memory)
    {
        return signedList[_signer];
    }

    function getNFTSignatureList(address _nftContract, uint _tokenId)
        public
        view
        returns (SignMessage[] memory)
    {
        bytes32 tokenHash = hashToken(_nftContract, _tokenId);
        return signatureList[tokenHash];
    }

    function _isTokenInDict(bytes32 _tokenHash) internal view returns (bool) {
        return tokenDictionary[_tokenHash].tokenId != 0;
    }
}