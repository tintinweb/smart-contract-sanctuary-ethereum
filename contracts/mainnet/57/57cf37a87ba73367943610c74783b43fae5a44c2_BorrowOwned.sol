// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

// Owned by 0xG

contract BorrowOwned {
  IOwned private _owned;

  mapping(uint => uint) public borrowExpire;
  mapping(uint => uint) public borrowLength;

  constructor(address owned_) {
    _owned = IOwned(owned_);
  }

  function borrow(uint tokenId) external {
    require(block.timestamp > borrowExpire[tokenId], "Owned: token already borrowed. Retry later");
    (address owner, address holder, uint expire) = _owned.tokenInfo(tokenId);
    require(owner != msg.sender, "Owned: already owner");
    require(holder != msg.sender, "Owned: holder already borrowed");
    require(block.timestamp > expire, "Owned: token already borrowed. Retry later");
    borrowExpire[tokenId] = block.timestamp + borrowLength[tokenId];
    _owned.lend(msg.sender, tokenId, 0);
  }

  function setBorrowLength(uint tokenId, uint length) external {
    (address owner,,) = _owned.tokenInfo(tokenId);
    require(owner == msg.sender, "Owned: only owner can update borrow length");
    borrowLength[tokenId] = length;
  }
}

interface IOwned {
  function tokenInfo(uint tokenId) external view returns (address owner, address holder, uint expire);
  function lend(address to, uint tokenId, uint expire) external;
}