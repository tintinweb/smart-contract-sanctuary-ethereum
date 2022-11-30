// SPDX-License-Identifier: MIT
// Created by Anime Aztecs

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ERC721Upgradeable.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";

contract AiNimeAztecs is Initializable, ERC721Upgradeable, OwnableUpgradeable, DefaultOperatorFiltererUpgradeable {

  uint256 public totalSupply;
  mapping(uint256 => string) internal URI;

  function initialize() initializer public {
    __ERC721_init("AiNime Aztecs", "AiNime");
    __Ownable_init();
    totalSupply = 0;
  }

  function initializeV2() reinitializer(2) public {
    __DefaultOperatorFilterer_init();
  }

  function mint(address _to, string calldata metadataCID) external onlyOwner {
    URI[totalSupply+1] = metadataCID;
    _mint(_to, totalSupply + 1);
    totalSupply++;
  }

  function batchMint(address[] calldata _to, string[] calldata metadataCID) external onlyOwner {
    require(_to.length == metadataCID.length);
    for (uint i = 1; i <= _to.length; i++) {
      URI[totalSupply+i] = metadataCID[i-1];
      _mint(_to[i-1], totalSupply + i);
    }
    totalSupply += _to.length;
  }
 
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "URI query for nonexistent token");
    return URI[tokenId];
  }

  function setURI(uint256 tokenId, string calldata metadataCID) external onlyOwner {
    URI[tokenId] = metadataCID;
  }

  function batchSetURI(uint256[] calldata tokenId, string[] calldata metadataCID) external onlyOwner {
    require(tokenId.length == metadataCID.length);
    for (uint i = 0; i < tokenId.length; i++) {
      URI[tokenId[i]] = metadataCID[i];
    }
  }

  // OpenSea DefaultOperatorFilterer
  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}