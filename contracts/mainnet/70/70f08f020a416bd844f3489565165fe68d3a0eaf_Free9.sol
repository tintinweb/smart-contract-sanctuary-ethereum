/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

// SPDX-License-Identifier: CC0


/*
 /$$$$$$$$ /$$$$$$$  /$$$$$$$$ /$$$$$$$$        /$$$$$$
| $$_____/| $$__  $$| $$_____/| $$_____/       /$$__  $$
| $$      | $$  \ $$| $$      | $$            | $$  \ $$
| $$$$$   | $$$$$$$/| $$$$$   | $$$$$         |  $$$$$$$
| $$__/   | $$__  $$| $$__/   | $$__/          \____  $$
| $$      | $$  \ $$| $$      | $$             /$$  \ $$
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

interface IEditions {
  function balanceOf(address account, uint256 id) external returns (uint256);
}


contract Free9 {
  IFree public immutable free;
  IEditions public immutable editions;
  mapping(uint256 => bool) public free0TokenIdUsed;

  constructor(address freeAddr, address editionsAddr) {
    free = IFree(freeAddr);
    editions = IEditions(editionsAddr);
  }

  function claim(uint256 free0TokenId) external {
    require(free.tokenIdToCollectionId(free0TokenId) == 0, 'Invalid Free0');
    require(!free0TokenIdUsed[free0TokenId], 'This Free0 has already been used to mint a Free9');
    require(free.ownerOf(free0TokenId) == msg.sender, 'You must be the owner of this Free0');

    require(editions.balanceOf(msg.sender, 1) >= 10, 'You must support the RPAA');

    free0TokenIdUsed[free0TokenId] = true;
    free.appendAttributeToToken(free0TokenId, 'Used For Free9 Mint', 'true');
    free.mint(9, msg.sender);
  }
}