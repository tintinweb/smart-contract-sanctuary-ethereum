/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

// SPDX-License-Identifier: CC0


/*
 /$$$$$$$$ /$$$$$$$  /$$$$$$$$ /$$$$$$$$         /$$    /$$$$$$
| $$_____/| $$__  $$| $$_____/| $$_____/       /$$$$   /$$__  $$
| $$      | $$  \ $$| $$      | $$            |_  $$  | $$  \ $$
| $$$$$   | $$$$$$$/| $$$$$   | $$$$$           | $$  |  $$$$$$/
| $$__/   | $$__  $$| $$__/   | $$__/           | $$   >$$__  $$
| $$      | $$  \ $$| $$      | $$              | $$  | $$  \ $$
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

interface IEditions {
  function balanceOf(address owner, uint256 tokenId) external view returns (uint256);
}

contract Free18 {
  IFree public immutable free;
  IEditions public immutable editions;
  address public terminallyOnlineMultisig;

  uint256 public claimableTokensLeft;

  mapping(uint256 => bool) public free0TokenIdUsed;

  constructor(address freeAddr, address toMultisigAddr, address editionsAddr) {
    free = IFree(freeAddr);
    terminallyOnlineMultisig = toMultisigAddr;
    editions = IEditions(editionsAddr);
  }

  function incrementClaimableTokens(uint256 increment) external {
    require(msg.sender == terminallyOnlineMultisig, 'Can only be called by Terminally Online Multisig');
    claimableTokensLeft += increment;
  }

  function claim(uint256 free0TokenId) public {
    require(free.tokenIdToCollectionId(free0TokenId) == 0, 'Invalid Free0');
    require(!free0TokenIdUsed[free0TokenId], 'This Free0 has already been used to mint a Free18');
    require(free.ownerOf(free0TokenId) == msg.sender, 'You must be the owner of this Free0');

    require(editions.balanceOf(msg.sender, 0) >= 1, 'Must have at least 1 WOW token');
    require(claimableTokensLeft > 0, 'No tokens left to claim');
    claimableTokensLeft -= 1;


    free0TokenIdUsed[free0TokenId] = true;
    free.appendAttributeToToken(free0TokenId, 'Used For Free18 Mint', 'true');
    free.mint(18, msg.sender);
  }
}