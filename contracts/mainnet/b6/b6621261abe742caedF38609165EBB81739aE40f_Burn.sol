// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// LightLink 2022

contract Burn {
  function burnTokens(address _nftContract, uint256[] calldata _tokenIds) external {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      IBurn(_nftContract).burn(_tokenIds[i]);
    }
  }
}

interface IBurn {
  function burn(uint256 tokenId) external;
}