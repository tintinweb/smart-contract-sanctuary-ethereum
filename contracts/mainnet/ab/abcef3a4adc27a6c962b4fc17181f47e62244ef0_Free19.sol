/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

// SPDX-License-Identifier: CC0


/*
 /$$$$$$$$ /$$$$$$$  /$$$$$$$$ /$$$$$$$$         /$$    /$$$$$$
| $$_____/| $$__  $$| $$_____/| $$_____/       /$$$$   /$$__  $$
| $$      | $$  \ $$| $$      | $$            |_  $$  | $$  \ $$
| $$$$$   | $$$$$$$/| $$$$$   | $$$$$           | $$  |  $$$$$$$
| $$__/   | $$__  $$| $$__/   | $$__/           | $$   \____  $$
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
}


contract Free19 {
  IFree public immutable free;
  uint256 public lastAssigned;
  address public claimer;

  mapping(uint256 => bool) public free0TokenIdUsed;

  constructor(address freeAddr) {
    free = IFree(freeAddr);
  }

  function assign(address asignee) public {
    claimer = asignee;
    lastAssigned = block.timestamp;
  }

  function claim(uint256 free0TokenId) public {
    require(free.tokenIdToCollectionId(free0TokenId) == 0, 'Invalid Free0');
    require(!free0TokenIdUsed[free0TokenId], 'This Free0 has already been used to mint a Free19');
    require(free.ownerOf(free0TokenId) == msg.sender, 'You must be the owner of this Free0');

    require(msg.sender == claimer, 'You must be the claimer');
    require(block.timestamp >= lastAssigned + 1 days, 'You must wait at least 1 day after the most recent assignment');

    free0TokenIdUsed[free0TokenId] = true;
    free.appendAttributeToToken(free0TokenId, 'Used For Free19 Mint', 'true');
    free.mint(19, msg.sender);
  }
}