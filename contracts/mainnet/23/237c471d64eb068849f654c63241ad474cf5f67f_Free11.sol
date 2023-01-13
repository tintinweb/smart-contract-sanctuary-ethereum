/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

// SPDX-License-Identifier: CC0


/*
 /$$$$$$$$ /$$$$$$$  /$$$$$$$$ /$$$$$$$$         /$$     /$$
| $$_____/| $$__  $$| $$_____/| $$_____/       /$$$$   /$$$$
| $$      | $$  \ $$| $$      | $$            |_  $$  |_  $$
| $$$$$   | $$$$$$$/| $$$$$   | $$$$$           | $$    | $$
| $$__/   | $$__  $$| $$__/   | $$__/           | $$    | $$
| $$      | $$  \ $$| $$      | $$              | $$    | $$
| $$      | $$  | $$| $$$$$$$$| $$$$$$$$       /$$$$$$ /$$$$$$
|__/      |__/  |__/|________/|________/      |______/|______/



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
  function tokenIdToProjectId(uint256 tokenId) external returns (uint256 projectId);
  function ownerOf(uint256 tokenId) external returns (address owner);
}


contract Free11 {
  IFree public immutable free;
  IArtBlocks public immutable artBlocks;

  mapping(uint256 => bool) public free0TokenIdUsed;

  mapping(uint256 => address) public pointerToTarget;
  mapping(uint256 => uint256) public pointerCount;

  constructor(address freeAddr, address abAddr) {
    free = IFree(freeAddr);
    artBlocks = IArtBlocks(abAddr);
  }

  function point(uint256 tokenId, address target) external {
    require(artBlocks.tokenIdToProjectId(tokenId) == 387, 'Invalid Pointer');
    require(artBlocks.ownerOf(tokenId) == msg.sender, 'You must own this Pointer');
    pointerToTarget[tokenId] = target;
  }

  function claim(
    uint256 free0TokenId,
    uint256 topPointerTokenId,
    uint256 bottomPointerTokenId,
    uint256 leftPointerTokenId,
    uint256 rightPointerTokenId
  ) external {
    require(free.tokenIdToCollectionId(free0TokenId) == 0, 'Invalid Free0');
    require(!free0TokenIdUsed[free0TokenId], 'This Free0 has already been used to mint a Free11');
    require(free.ownerOf(free0TokenId) == msg.sender, 'You must be the owner of this Free0');

    require(
      pointerToTarget[topPointerTokenId] == msg.sender
      && pointerToTarget[bottomPointerTokenId] == msg.sender
      && pointerToTarget[leftPointerTokenId] == msg.sender
      && pointerToTarget[rightPointerTokenId] == msg.sender,
      'This target does not have enough Pointers'
    );

    require(
      topPointerTokenId != bottomPointerTokenId &&
      topPointerTokenId != leftPointerTokenId &&
      topPointerTokenId != rightPointerTokenId &&
      bottomPointerTokenId != leftPointerTokenId &&
      bottomPointerTokenId != rightPointerTokenId &&
      leftPointerTokenId != rightPointerTokenId,
      'All Pointers must be different'
    );

    pointerCount[topPointerTokenId] += 1;
    pointerCount[bottomPointerTokenId] += 1;
    pointerCount[leftPointerTokenId] += 1;
    pointerCount[rightPointerTokenId] += 1;

    free0TokenIdUsed[free0TokenId] = true;
    free.appendAttributeToToken(free0TokenId, 'Used For Free11 Mint', 'true');
    free.mint(11, msg.sender);
  }
}