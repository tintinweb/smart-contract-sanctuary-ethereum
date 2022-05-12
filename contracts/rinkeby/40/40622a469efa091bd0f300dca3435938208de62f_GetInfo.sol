/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IMNFT721 {
   function tokenURI(uint256 tokenId) external view returns(string memory);

   function ownerOf(uint256 tokenId) external view returns (address owner_);

   function mintNFT(string[] memory tokenURIs_, address owner_) external;

   function owner() external view returns(address);
}

contract GetInfo {
   struct NFTInfo {
      uint256 tokenID;
      address tokenOwner;
      string tokenURI;
   }

   function getNFTInfo(
      address tokenAddress_,
      uint256 point_,
      uint256 length_
   ) external view returns(NFTInfo[] memory) {
      (
         uint256 cnt,
         NFTInfo[] memory tmpInfos
      ) = _getExistsTokenIDCount(tokenAddress_, point_, length_);
      
      if (cnt == 0) {
         return new NFTInfo[](0);
      }

      uint256 index = 0;
      NFTInfo[] memory infos = new NFTInfo[](cnt);

      for (uint256 i = 0; i < length_; i ++) {
         if (tmpInfos[i].tokenID != 0) {
            infos[index ++] = tmpInfos[i];
         }
      }

      return infos;
   }

   function _getExistsTokenIDCount(
      address tokenAddress_,
      uint256 point_,
      uint256 length_
   ) internal view returns(uint256 cnt, NFTInfo[] memory ids) {
      ids = new NFTInfo[](length_);
      IMNFT721 token = IMNFT721(tokenAddress_);
      for (uint256 tokenID = point_; tokenID < point_ + length_; tokenID ++) {
         try token.ownerOf(tokenID) {
            ids[tokenID - point_] = NFTInfo({
               tokenID: tokenID ,
               tokenOwner: token.ownerOf(tokenID),
               tokenURI: token.tokenURI(tokenID)
            });
            cnt ++;
         } catch Error(string memory /*reason*/) {
            continue;   
         } catch (bytes memory _err) {
            continue;
         }
      }
   }
}