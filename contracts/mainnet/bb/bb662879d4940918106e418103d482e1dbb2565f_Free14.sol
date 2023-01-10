/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

// SPDX-License-Identifier: CC0


/*
 /$$$$$$$$ /$$$$$$$  /$$$$$$$$ /$$$$$$$$         /$$ /$$   /$$
| $$_____/| $$__  $$| $$_____/| $$_____/       /$$$$| $$  | $$
| $$      | $$  \ $$| $$      | $$            |_  $$| $$  | $$
| $$$$$   | $$$$$$$/| $$$$$   | $$$$$           | $$| $$$$$$$$
| $$__/   | $$__  $$| $$__/   | $$__/           | $$|_____  $$
| $$      | $$  \ $$| $$      | $$              | $$      | $$
| $$      | $$  | $$| $$$$$$$$| $$$$$$$$       /$$$$$$    | $$
|__/      |__/  |__/|________/|________/      |______/    |__/



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

interface IPlottables {
  function transferFrom(address from, address to, uint256 tokenId) external;
  function tokenIdToProjectId(uint256 tokenId) external returns (uint256 projectId);
}


contract Free14 {
  IFree public immutable free;
  IPlottables public immutable plottables;
  mapping(uint256 => bool) public free0TokenIdUsed;
  mapping(uint256 => bool) public instructionsUsed;
  bool public seeded;

  uint256 public activeInstruction;

  constructor(address freeAddr, address plottablesAddr) {
    free = IFree(freeAddr);
    plottables = IPlottables(plottablesAddr);
  }

  function seed(uint256 instructionTokenId) external {
    require(!seeded, 'Free14 has already been seeded');
    seeded = true;
    activeInstruction = instructionTokenId;
    instructionsUsed[instructionTokenId] = true;
    plottables.transferFrom(msg.sender, address(this), instructionTokenId);
  }


  function claim(uint256 free0TokenId, uint256 instructionTokenId) external {
    require(free.tokenIdToCollectionId(free0TokenId) == 0, 'Invalid Free0');
    require(!free0TokenIdUsed[free0TokenId], 'This Free0 has already been used to mint a Free14');
    require(free.ownerOf(free0TokenId) == msg.sender, 'You must be the owner of this Free0');

    require(seeded, 'Free14 has not been seeded');
    require(!instructionsUsed[instructionTokenId], 'This Instruction has already been used');
    require(plottables.tokenIdToProjectId(instructionTokenId) == 0, 'Invalid Instruction for Defacement');

    plottables.transferFrom(msg.sender, address(this), instructionTokenId);
    plottables.transferFrom(address(this), msg.sender, activeInstruction);

    activeInstruction = instructionTokenId;
    instructionsUsed[instructionTokenId] = true;

    free0TokenIdUsed[free0TokenId] = true;
    free.appendAttributeToToken(free0TokenId, 'Used For Free14 Mint', 'true');
    free.mint(14, msg.sender);
  }
}