// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract NFTBridge4BlackHole {
  uint256 public minimalAllowableToken;

  error TokenNotAllowed(uint256 tokenId);

  event SendTokenIntoBlackHole(uint256 tokenId, address sender);

  constructor(uint256 allowableToken) {
    minimalAllowableToken = allowableToken;
  }

  function sendMsg(
      uint64,
      address sender,
      address,
      uint256 tokenId,
      string calldata
  ) external {
    if (tokenId < minimalAllowableToken) {
      revert TokenNotAllowed(tokenId);
    }
    emit SendTokenIntoBlackHole(tokenId, sender);
  }
}