/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract NFTContract {
  // Maps the NFT ID to the owner address
  mapping(uint256 => address) public nftOwners;

  // Array to store the NFT IDs
  uint256[] public nftIds;

  // Address of the authorized wallet
  address public authorizedWallet;

  // Transfer the NFTs to the contract
  function transferNFTs(uint256[] memory _nftIds) public {
    for (uint256 i = 0; i < _nftIds.length; i++) {
      // Ensure that the NFT is not already owned by the contract
      require(nftOwners[_nftIds[i]] != address(this), "NFT already owned by contract");
      // Update the NFT owner
      nftOwners[_nftIds[i]] = address(this);
      // Add the NFT ID to the array
      nftIds.push(_nftIds[i]);
    }
  }

  // Withdraw the NFTs from the contract
  function withdrawNFTs(uint256[] memory _nftIds) public {
    // Ensure that the caller is the authorized wallet
    require(msg.sender == authorizedWallet, "Unauthorized access");
    for (uint256 i = 0; i < _nftIds.length; i++) {
      // Ensure that the NFT is owned by the contract
      require(nftOwners[_nftIds[i]] == address(this), "NFT not owned by contract");
      // Update the NFT owner
      nftOwners[_nftIds[i]] = msg.sender;
      // Remove the NFT ID from the array
      delete nftIds[_nftIds[i]];
    }
  }

  // Set the authorized wallet
  function setAuthorizedWallet(address _authorizedWallet) public {
    authorizedWallet = _authorizedWallet;
  }
}