// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface K9000 {
  function totalSupply() external view returns (uint256);
  function ownerOf(uint256 tokenId) external view returns (address);
  function balanceOf(address owner) external view returns (uint256);
  function builtK9000(uint256 index) external view returns (uint256);
}

contract K9000Listing {
  K9000 k9000;

  constructor(address _k9000) {
    k9000 = K9000(_k9000);
  }

  function getK9000(address account, uint256 index) public view returns (uint256, uint256) {
    uint256 totalSupply = k9000.totalSupply();
    for (uint256 i = index; i < totalSupply; i++) {
      uint256 tokenId = k9000.builtK9000(i);
      if (account == k9000.ownerOf(tokenId)) {
        return (tokenId, i);
      }
    }
    revert();
  }

  function listK9000(address account) public view returns (uint256[] memory) {
    uint256 lastIndex = 0;
    uint256 balance = k9000.balanceOf(account);
    uint256[] memory result = new uint256[](balance);
    for (uint256 i = 0; i < balance; i++) {
      (uint256 tokenId, uint256 index) = getK9000(account, lastIndex);
      result[i] = tokenId;
      lastIndex = index + 1;
    }
    return result;
  }
}