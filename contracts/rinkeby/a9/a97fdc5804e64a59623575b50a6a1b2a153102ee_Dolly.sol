// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import "./ERC721.sol"; // @openzeppelin/contracts/token/ERC721/ERC721.sol flatten
import "./Admin.sol";

contract Dolly is ERC721, Admin {
  uint cloneId;
  mapping(uint => uint) _originalIds;
  mapping(uint => address) _tokenAddresses;
  mapping(uint => uint) _lendingExpires;

  constructor() ERC721("Dolly", "DLLY") {}

  function clone(address tokenAddress, uint tokenId) external adminOnly {
    require(tokenAddress.code.length > 0, "Dolly: token address must be a contract");
    require(msg.sender == IERC721(tokenAddress).ownerOf(tokenId), "Dolly: caller must be owner token to clone does not exist");
    cloneId += 1;
    _originalIds[cloneId] = tokenId;
    _tokenAddresses[cloneId] = tokenAddress;
    _safeMint(msg.sender, cloneId);
  }

  function lend(uint tokenId, address to, uint expires) external {
    ERC721.safeTransferFrom(ERC721.ownerOf(tokenId), to, tokenId);
    _lendingExpires[tokenId] = expires;
  }

  function claim(uint tokenId) external {
    _transfer(ERC721.ownerOf(tokenId), msg.sender, tokenId);
    _lendingExpires[tokenId] = 0;
  }

  function burn(uint tokenId) external {
    _burn(tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    if (from != address(0)) {
      require(block.timestamp > _lendingExpires[tokenId], "Dolly: token locked until current lending expiration");
      require(_canTransfer(msg.sender, tokenId), "Dolly: caller is allowed to transfer token");
    }
  }

  function _originalOwnerOf(uint cloneId) internal view returns (address) {
    uint tokenId = _originalIds[cloneId];
    require(tokenId != 0, "Dolly: invalid token ID");
    address owner = IERC721(_tokenAddresses[cloneId]).ownerOf(tokenId);
    require(owner != address(0), "Dolly: owner for token not found");
    return owner;
  }

  function _canTransfer(address spender, uint256 cloneId) internal view virtual returns (bool) {
    address owner = _originalOwnerOf(cloneId);
    IERC721 token = IERC721(_tokenAddresses[cloneId]);
    return (spender == owner || token.isApprovedForAll(owner, spender) || token.getApproved(_originalIds[cloneId]) == spender);
  }

  function tokenURI(uint256 cloneId) public view virtual override returns (string memory) {
    return IERC721Metadata(_tokenAddresses[cloneId]).tokenURI(_originalIds[cloneId]);
  }
}