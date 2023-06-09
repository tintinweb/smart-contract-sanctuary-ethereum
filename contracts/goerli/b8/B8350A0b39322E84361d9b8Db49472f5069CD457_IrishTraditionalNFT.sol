/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IrishTraditionalNFT {
    string public constant TOKEN_NAME = "IrishTraditionalNFT";
    string public constant TOKEN_SYMBOL = "ITNFT";

    uint256 private _tokenIdCounter;
    mapping(uint256 => string) private _tokenABCs;
    mapping(uint256 => address) private _tokenOwners;

    constructor() {
        _tokenIdCounter = 0;
    }

    function TuneABC(string memory abc) public returns (uint256) {
        _tokenIdCounter++;
        uint256 newTokenId = _tokenIdCounter;

        _tokenABCs[newTokenId] = abc;
        _tokenOwners[newTokenId] = msg.sender;

        return newTokenId;
    }

    function getTokenABC(uint256 tokenId) public view returns (string memory) {
        require(tokenId <= _tokenIdCounter, "Invalid token ID");
        return _tokenABCs[tokenId];
    }

    function getTokenOwner(uint256 tokenId) public view returns (address) {
        require(tokenId <= _tokenIdCounter, "Invalid token ID");
        return _tokenOwners[tokenId];
    }

    function isTransferable(uint256) public pure returns (bool) {
        return false;
    }
}