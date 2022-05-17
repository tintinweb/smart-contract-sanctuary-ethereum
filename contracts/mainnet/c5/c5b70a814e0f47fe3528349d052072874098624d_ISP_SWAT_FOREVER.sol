/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ISP_SWAT_FOREVER {

  constructor()
  {
    emit Transfer(address(0), 0xbD7f8Cb7963B11078fc8e06ca5043815Ed93b16A, 0);
    emit Transfer(address(0), 0xc1222dD52f23eF4Fe7450dEC33Ea7519e340d9a9, 1);
    emit Transfer(address(0), 0x5d09Aef2979fB6A7C4A7AbFF66F6dBDcaaDDc1f5, 2);
    emit Transfer(address(0), 0x512d81C3d05FF7b67b9c3Ed07fc6D0E1EDb90119, 3);
    emit Transfer(address(0), 0xE98543df7A5c0FC4fF327878Ad7eF6843f5d72c1, 4);
  }

  // CONSTANTS
  string constant NAME = "ISP SWAT TEAM";
  string constant SYMBOL = "ISP";
  string constant ISP_CANNOT_BE_FORGOTTEN = "ISP cannot be forgotten";
  string constant INVALID_TOKEN = "invalid token";
  string constant TOKEN_URI = "ipfs://QmQezZWY6wqTVuNkkbmp4dLQ8bR2LHfSFiAr5LeB8EhRCv";

  // EVENTS
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

  // EXTERNALS (NO MODIFICATIONS ALLOWED)
  function safeTransferFrom(address, address, uint256) external payable { revert(ISP_CANNOT_BE_FORGOTTEN); }
  function safeTransferFrom(address, address, uint256, bytes calldata) external payable { revert(ISP_CANNOT_BE_FORGOTTEN); }
  function transferFrom(address, address, uint256) external payable { revert(ISP_CANNOT_BE_FORGOTTEN); }
  function approve(address, uint256) external payable { revert(ISP_CANNOT_BE_FORGOTTEN); }
  function setApprovalForAll(address, bool) external { revert(ISP_CANNOT_BE_FORGOTTEN); }

  // VIEWS
  function getApproved(uint256 _tokenId) external pure returns (address) {
    require(_tokenId < 5, INVALID_TOKEN);
    return address(0);
  }

  function isApprovedForAll(address, address) external pure returns (bool) { return false; }

  function balanceOf(address _owner) external pure returns (uint256) {
    if (_owner == 0xbD7f8Cb7963B11078fc8e06ca5043815Ed93b16A ||
        _owner == 0xc1222dD52f23eF4Fe7450dEC33Ea7519e340d9a9 ||
        _owner == 0x5d09Aef2979fB6A7C4A7AbFF66F6dBDcaaDDc1f5 ||
        _owner == 0x512d81C3d05FF7b67b9c3Ed07fc6D0E1EDb90119 ||
        _owner == 0xE98543df7A5c0FC4fF327878Ad7eF6843f5d72c1)
        return 1;
    require(_owner != address(0));
    return 0;
  }

  function ownerOf(uint256 _tokenId) external pure returns (address) {
    if (_tokenId == 0) return 0xbD7f8Cb7963B11078fc8e06ca5043815Ed93b16A;
    if (_tokenId == 1) return 0xc1222dD52f23eF4Fe7450dEC33Ea7519e340d9a9;
    if (_tokenId == 2) return 0x5d09Aef2979fB6A7C4A7AbFF66F6dBDcaaDDc1f5;
    if (_tokenId == 3) return 0x512d81C3d05FF7b67b9c3Ed07fc6D0E1EDb90119;
    if (_tokenId == 4) return 0xE98543df7A5c0FC4fF327878Ad7eF6843f5d72c1;
    revert(INVALID_TOKEN);
  }

  function name() external pure returns (string memory) {
    return NAME;
  }
  
  function symbol() external pure returns (string memory) {
    return SYMBOL;
  }
  
  function tokenURI(uint256 _tokenId) external pure returns (string memory) {
    require(_tokenId < 5, INVALID_TOKEN);
    return TOKEN_URI;
  }

  function totalSupply() external pure returns (uint256) {
    return 5;
  }

  function supportsInterface(bytes4 _interfaceID) external pure returns (bool)  {
    return (_interfaceID == 0x01ffc9a7 || _interfaceID == 0x5b5e139f);
  }

}