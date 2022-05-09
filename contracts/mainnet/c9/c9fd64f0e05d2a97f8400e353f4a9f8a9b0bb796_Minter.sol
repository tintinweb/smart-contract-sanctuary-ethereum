/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;


interface IUncirculatedFIMContract {
  function mint(address to, uint256 tokenId) external;
  function owner() external view returns (address);
}


contract Minter {
  uint256 public priceInWei;
  bool public isLocked;

  IUncirculatedFIMContract public uFIMContract;

  constructor(address _uFIMContract) {
    uFIMContract = IUncirculatedFIMContract(_uFIMContract);
    priceInWei = 99500000000000000;
    isLocked = false;
  }

  modifier onlyOwner() {
    require(msg.sender == uFIMContract.owner(), "Ownable: caller is not the owner");
    _;
  }

  function updatePrice(uint256 _newPrice) external onlyOwner {
     priceInWei = _newPrice;
  }


  function flipIsLocked() external onlyOwner {
     isLocked = !isLocked;
  }

  function mint(uint256 tokenId) external payable {
    require(!isLocked, "Minting contract is locked");
    require(msg.value >= priceInWei, "Insufficient payment");
    uFIMContract.mint(msg.sender, tokenId);
  }

  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
}