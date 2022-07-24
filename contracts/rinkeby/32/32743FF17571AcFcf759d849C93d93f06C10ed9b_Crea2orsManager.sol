// SPDX-License-Identifier: MIT
// Author: [email protected]
pragma solidity >=0.8.0 <0.9.0;

interface ICrea2orsNFT {
  function transferNFT(
    uint256 id,
    uint256 amount,
    address from,
    address to
  ) external;

  function getRoyaltyFee(uint256) external returns (uint256);

  function getRoyaltyAddress(uint256) external returns (address);
}

interface ICrea2Crypto {
  function approve(address spender, uint256 fund) external;

  function balanceOf(address) external returns (uint256);

  function transfer(address, uint256) external;

  function transferFrom(
    address,
    address,
    uint256
  ) external;
}

contract Crea2orsManager {
  mapping(address => ICrea2orsNFT) public collections;
  ICrea2Crypto private cr2Contract;

  constructor(address tokenAddress) {
    cr2Contract = ICrea2Crypto(tokenAddress);
  }

  // add new collection to nft collection list
  function addCollection(address newAddress) public {
    ICrea2orsNFT nftContract = ICrea2orsNFT(newAddress);
    collections[newAddress] = nftContract;
  }

  function transferNFT(
    address collectionAddress,
    address from,
    address to,
    uint256 id,
    uint256 amount,
    uint256 fund
  ) public {
    require(fund < cr2Contract.balanceOf(msg.sender), "Insufficient fund of buyer");
    uint256 royalty = (fund * collections[collectionAddress].getRoyaltyFee(id)) / 100;
    // Send fee to contract owner
    cr2Contract.transferFrom(to, collections[collectionAddress].getRoyaltyAddress(id), royalty);
    // Send money to seller
    cr2Contract.transferFrom(to, from, fund - royalty);
    collections[collectionAddress].transferNFT(id, amount, from, to);
  }
}