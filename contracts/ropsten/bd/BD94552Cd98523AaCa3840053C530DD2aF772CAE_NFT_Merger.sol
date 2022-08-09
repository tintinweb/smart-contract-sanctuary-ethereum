// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


contract NFT_Merger {

    uint8[] private tokenTypes;

    constructor(uint8[] memory _tokenTypes) 
    {
        tokenTypes = _tokenTypes;
    }

    function getTokenType(uint256 _tokenId) public view returns (uint8) 
    {
        return tokenTypes[_tokenId];
    }

    function mergeTokens(uint256 _tokenIdA, uint256 _tokenIdB, uint256 _tokenIdC) public view returns (string memory) 
    {
        require(_tokenIdA != _tokenIdB, "Duplicate token specified");
        require(_tokenIdA != _tokenIdC, "Duplicate token specified");
        require(_tokenIdB != _tokenIdC, "Duplicate token specified");

        uint8 tokenIdAType = tokenTypes[_tokenIdA];
        uint8 tokenIdBType = tokenTypes[_tokenIdB];
        uint8 tokenIdCType = tokenTypes[_tokenIdC];

        require(tokenIdAType + tokenIdBType + tokenIdCType == 14, "Invalid combination of tokens types");

        return "done";
    }
}