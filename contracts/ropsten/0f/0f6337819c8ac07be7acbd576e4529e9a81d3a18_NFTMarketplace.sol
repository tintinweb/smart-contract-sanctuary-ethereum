/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NFTMarketplace {
  // Maintain a mapping of Fake TokenID to Owner address
  mapping(uint256 => address) public tokens;
  // Set the purchase price for each Fake NFT
  uint256 nftPrice = 0.1 ether;

  // purchase() accepts ETH and marks the owner of the given tokenId
  // as the caller address
  // param _tokenId - the fake NFT token Id to purchase
  function purchase(uint256 _tokenId) external payable {
    require(msg.value == nftPrice, "This NFT costs 0.1 ether");
    tokens[_tokenId] = msg.sender;
  }

  function getPrice() external view returns (uint256) {
    return nftPrice;
  }

  // available() checks whether the given tokenId has already been sold or not
  // @params _tokenId - the tokenId to check for
  function available(uint256 _tokenId) external view returns (bool) {
    // address(0) = 0x0000000000000000000000000000000000000000
    // This is the default value for addresses in Solidity
    if (tokens[_tokenId] == address(0)) {
      return true;
    }
    return false;
  }
}