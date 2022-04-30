// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC721Fat.sol";

contract FatHamster is ERC721Fat("Fat Test", "FATTEST") {
  constructor() {
    _setPrice(0.01 ether);
    _setMaxMintPerTransaction(5);
    _setTotal(100);
    _setRoyalty(500);
  }

  function setBaseUri(string memory baseUri) external {
    _setBaseUri(baseUri);
  }
}