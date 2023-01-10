/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

// SPDX-License-Identifier: CC0


/*
 /$$$$$$$$ /$$$$$$$  /$$$$$$$$ /$$$$$$$$        /$$$$$$
| $$_____/| $$__  $$| $$_____/| $$_____/       /$$__  $$
| $$      | $$  \ $$| $$      | $$            | $$  \ $$
| $$$$$   | $$$$$$$/| $$$$$   | $$$$$         |  $$$$$$/
| $$__/   | $$__  $$| $$__/   | $$__/          >$$__  $$
| $$      | $$  \ $$| $$      | $$            | $$  \ $$
| $$      | $$  | $$| $$$$$$$$| $$$$$$$$      |  $$$$$$/
|__/      |__/  |__/|________/|________/       \______/



 /$$
| $$
| $$$$$$$  /$$   /$$
| $$__  $$| $$  | $$
| $$  \ $$| $$  | $$
| $$  | $$| $$  | $$
| $$$$$$$/|  $$$$$$$
|_______/  \____  $$
           /$$  | $$
          |  $$$$$$/
           \______/
  /$$$$$$  /$$$$$$$$ /$$$$$$$$ /$$    /$$ /$$$$$$ /$$$$$$$$ /$$$$$$$
 /$$__  $$|__  $$__/| $$_____/| $$   | $$|_  $$_/| $$_____/| $$__  $$
| $$  \__/   | $$   | $$      | $$   | $$  | $$  | $$      | $$  \ $$
|  $$$$$$    | $$   | $$$$$   |  $$ / $$/  | $$  | $$$$$   | $$$$$$$/
 \____  $$   | $$   | $$__/    \  $$ $$/   | $$  | $$__/   | $$____/
 /$$  \ $$   | $$   | $$        \  $$$/    | $$  | $$      | $$
|  $$$$$$/   | $$   | $$$$$$$$   \  $/    /$$$$$$| $$$$$$$$| $$
 \______/    |__/   |________/    \_/    |______/|________/|__/


CC0 2022
*/


pragma solidity ^0.8.17;


interface IFree {
  function mint(uint256 collectionId, address to) external;
  function ownerOf(uint256 tokenId) external returns (address owner);
  function tokenIdToCollectionId(uint256 tokenId) external returns (uint256 collectionId);
  function appendAttributeToToken(uint256 tokenId, string memory attrKey, string memory attrValue) external;
}

interface IArtBlocks {
  function tokensOfOwner(address owner) external view returns (uint256[] memory);
  function tokenIdToProjectId(uint256 tokenId) external returns (uint256 projectId);
}


contract Free8 {
  IFree public immutable free;
  IArtBlocks public immutable artBlocks;

  mapping(uint256 => bool) public free0TokenIdUsed;

  constructor(address freeAddr, address abAddr) {
    free = IFree(freeAddr);
    artBlocks = IArtBlocks(abAddr);
  }

  function claim(uint256 free0TokenId) public {
    require(free.tokenIdToCollectionId(free0TokenId) == 0, 'Invalid Free0');
    require(!free0TokenIdUsed[free0TokenId], 'This Free0 has already been used to mint a Free8');
    require(free.ownerOf(free0TokenId) == msg.sender, 'You must be the owner of this Free0');

    // enumerate over all AB tokens to make sure none of them are Maps
    uint256[] memory tokensOfOwner = artBlocks.tokensOfOwner(msg.sender);

    for (uint256 i; i < tokensOfOwner.length; i++) {
      require(artBlocks.tokenIdToProjectId(tokensOfOwner[i]) != 316, 'You cannot own a Map of Nothing');
    }

    free0TokenIdUsed[free0TokenId] = true;
    free.appendAttributeToToken(free0TokenId, 'Used For Free8 Mint', 'true');
    free.mint(8, msg.sender);
  }
}