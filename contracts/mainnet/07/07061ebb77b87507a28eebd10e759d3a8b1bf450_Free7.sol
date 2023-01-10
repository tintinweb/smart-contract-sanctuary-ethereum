/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

// SPDX-License-Identifier: CC0


/*
 /$$$$$$$$ /$$$$$$$  /$$$$$$$$ /$$$$$$$$       /$$$$$$$$
| $$_____/| $$__  $$| $$_____/| $$_____/      |_____ $$/
| $$      | $$  \ $$| $$      | $$                 /$$/
| $$$$$   | $$$$$$$/| $$$$$   | $$$$$             /$$/
| $$__/   | $$__  $$| $$__/   | $$__/            /$$/
| $$      | $$  \ $$| $$      | $$              /$$/
| $$      | $$  | $$| $$$$$$$$| $$$$$$$$       /$$/
|__/      |__/  |__/|________/|________/      |__/



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

interface IFreeClaimer {
  function free0TokenIdUsed(uint256) external returns (bool);
  function free0tokenIdUsed(uint256) external returns (bool);
}

contract Free7 {
  IFree public immutable free;
  mapping(uint256 => bool) public free0TokenIdUsed;

  IFreeClaimer public immutable free1;
  IFreeClaimer public immutable free2;
  IFreeClaimer public immutable free3;
  IFreeClaimer public immutable free4;
  IFreeClaimer public immutable free5;
  IFreeClaimer public immutable free6;

  constructor(
    address freeAddr,
    address freeAddr1,
    address freeAddr2,
    address freeAddr3,
    address freeAddr4,
    address freeAddr5,
    address freeAddr6
  ) {
    free = IFree(freeAddr);
    free1 = IFreeClaimer(freeAddr1);
    free2 = IFreeClaimer(freeAddr2);
    free3 = IFreeClaimer(freeAddr3);
    free4 = IFreeClaimer(freeAddr4);
    free5 = IFreeClaimer(freeAddr5);
    free6 = IFreeClaimer(freeAddr6);
  }

  function claim(uint256 free0TokenId, uint256 supportingFree0TokenId) external {
    require(free.tokenIdToCollectionId(free0TokenId) == 0, 'Invalid Free0');
    require(!free0TokenIdUsed[free0TokenId], 'This Free0 has already been used to mint a Free7');
    require(free.ownerOf(free0TokenId) == msg.sender, 'You must be the owner of this Free0');

    require((
      free1.free0TokenIdUsed(free0TokenId)
      && free2.free0TokenIdUsed(free0TokenId)
      && free3.free0TokenIdUsed(free0TokenId)
      && free4.free0TokenIdUsed(free0TokenId)
      && free5.free0tokenIdUsed(free0TokenId)
      && free6.free0tokenIdUsed(free0TokenId)
    ), 'Free0 has not been used for all previous Frees');

    require(free.tokenIdToCollectionId(supportingFree0TokenId) == 0, 'Invalid Free0');
    require(free.ownerOf(supportingFree0TokenId) == msg.sender, 'You must be the owner of the Supporting Free0');
    require((
      free1.free0TokenIdUsed(supportingFree0TokenId)
      && free2.free0TokenIdUsed(supportingFree0TokenId)
      && free3.free0TokenIdUsed(supportingFree0TokenId)
      && free4.free0TokenIdUsed(supportingFree0TokenId)
      && free5.free0tokenIdUsed(supportingFree0TokenId)
      && free6.free0tokenIdUsed(supportingFree0TokenId)
    ), 'Supporting Free0 has not been used for all previous Frees');


    free0TokenIdUsed[free0TokenId] = true;
    free.appendAttributeToToken(free0TokenId, 'Used For Free7 Mint', 'true');
    free.mint(7, msg.sender);
  }
}