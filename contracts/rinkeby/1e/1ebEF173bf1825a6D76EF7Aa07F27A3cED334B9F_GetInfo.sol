// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interfaces/IMNFT721.sol";

contract GetInfo {
   function getTokenURIs(
      address tokenAddress_,
      uint256 point_,
      uint256 length_
   ) external view returns(string[] memory) {
      string[] memory tokenURIs = new string[](length_);
      IMNFT721 token = IMNFT721(tokenAddress_);
      for (uint256 i = point_; i < point_ + length_; i ++) {
         tokenURIs[i - point_] = token.tokenURI(i);
      }

      return tokenURIs;
   }

   function getOwners(
      address tokenAddress_,
      uint256 point_,
      uint256 length_
   ) external view returns(address[] memory) {
      address[] memory owners = new address[](length_);
      IMNFT721 token = IMNFT721(tokenAddress_);
      for (uint256 i = 0; i < point_ + length_; i ++) {
         owners[i - point_] = token.ownerOf(i);
      }

      return owners;
   }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMNFT721 {
   function tokenURI(uint256 tokenId) external view returns(string memory);

   function ownerOf(uint256 tokenId) external view returns (address owner_);

   function mintNFT(string[] memory tokenURIs_, address owner_) external;

   function owner() external view returns(address);
}