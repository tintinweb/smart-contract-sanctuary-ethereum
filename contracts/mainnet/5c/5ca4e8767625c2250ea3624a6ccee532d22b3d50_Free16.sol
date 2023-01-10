/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

// SPDX-License-Identifier: CC0


/*
 /$$$$$$$$ /$$$$$$$  /$$$$$$$$ /$$$$$$$$         /$$    /$$$$$$
| $$_____/| $$__  $$| $$_____/| $$_____/       /$$$$   /$$__  $$
| $$      | $$  \ $$| $$      | $$            |_  $$  | $$  \__/
| $$$$$   | $$$$$$$/| $$$$$   | $$$$$           | $$  | $$$$$$$
| $$__/   | $$__  $$| $$__/   | $$__/           | $$  | $$__  $$
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

interface IERC1155 {
  function balanceOf(address owner, uint256 tokenId) external view returns (uint256);
}

interface IERC721 {
  function balanceOf(address owner) external view returns (uint256);
}


contract Free16 {
  IFree public immutable free;
  IERC1155 public immutable osStorefront;
  IERC721 public immutable nvc;
  IERC721 public immutable nf;
  IERC721 public immutable ufim;

  mapping(uint256 => bool) public free0TokenIdUsed;

  constructor(address freeAddr, address nvcAddr, address nfAddr, address ufimAddr, address osStorefrontAddr) {
    free = IFree(freeAddr);
    nvc = IERC721(nvcAddr);
    nf = IERC721(nfAddr);
    ufim = IERC721(ufimAddr);
    osStorefront = IERC1155(osStorefrontAddr);
  }

  function claim(uint256 free0TokenId) public {
    require(free.tokenIdToCollectionId(free0TokenId) == 0, 'Invalid Free0');
    require(!free0TokenIdUsed[free0TokenId], 'This Free0 has already been used to mint a Free16');
    require(free.ownerOf(free0TokenId) == msg.sender, 'You must be the owner of this Free0');

    require(nvc.balanceOf(msg.sender) >= 20, 'Must have at least 20 NVCs');
    require(nf.balanceOf(msg.sender) >= 5, 'Must have at least 5 NFs');
    require(ufim.balanceOf(msg.sender) >= 5, 'Must have at least 5 UFIMs');
    require(osStorefront.balanceOf(msg.sender, 108025279282686658453897007890629891637526310304717906993258638098494503518261) >= 3, 'Must have at least 3 WINNERs');
    require(osStorefront.balanceOf(msg.sender, 108025279282686658453897007890629891637526310304717906993258638097394991890485) >= 3, 'Must have at least 3 LOSERs');

    free0TokenIdUsed[free0TokenId] = true;
    free.appendAttributeToToken(free0TokenId, 'Used For Free16 Mint', 'true');
    free.mint(16, msg.sender);
  }
}