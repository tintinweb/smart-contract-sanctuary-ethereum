/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

// SPDX-License-Identifier: CC0


/*
 /$$$$$$$$ /$$$$$$$  /$$$$$$$$ /$$$$$$$$         /$$   /$$$$$$$
| $$_____/| $$__  $$| $$_____/| $$_____/       /$$$$  | $$____/
| $$      | $$  \ $$| $$      | $$            |_  $$  | $$
| $$$$$   | $$$$$$$/| $$$$$   | $$$$$           | $$  | $$$$$$$
| $$__/   | $$__  $$| $$__/   | $$__/           | $$  |_____  $$
| $$      | $$  \ $$| $$      | $$              | $$   /$$  \ $$
| $$      | $$  | $$| $$$$$$$$| $$$$$$$$       /$$$$$$|  $$$$$$/
|__/      |__/  |__/|________/|________/      |______/ \______/



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
  function totalSupply() external view returns (uint256);
}


contract Free15 {
  IFree public immutable free;

  mapping(uint256 => bool) public free0TokenIdUsed;

  constructor(address freeAddr) {
    free = IFree(freeAddr);
  }

  function claim(uint256 free0TokenId) public {
    require(free.tokenIdToCollectionId(free0TokenId) == 0, 'Invalid Free0');
    require(!free0TokenIdUsed[free0TokenId], 'This Free0 has already been used to mint a Free15');
    require(free.ownerOf(free0TokenId) == msg.sender, 'You must be the owner of this Free0');

    require((free.totalSupply() / 100) % 2 == 0, 'Invalid total Free count');
    require((block.number/ 100) % 2 == 0, 'Invalid block number');

    free0TokenIdUsed[free0TokenId] = true;
    free.appendAttributeToToken(free0TokenId, 'Used For Free15 Mint', 'true');
    free.mint(15, msg.sender);
  }
}