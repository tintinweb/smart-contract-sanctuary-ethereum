// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./IERC5192.sol";
import "./ReentrancyGuard.sol";

contract SoulBind is ERC721,IERC5192,ERC721URIStorage,ReentrancyGuard {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdCounter;

  mapping (uint256 => bool) public lockedTOkens;
  constructor(string memory name_, string memory symbol_) ERC721(name_,symbol_) {}

  function safeMint(
    address to, 
    string memory uri
  ) public nonReentrant returns(uint256) {
    _tokenIdCounter.increment();
    uint256 tokenId = _tokenIdCounter.current();
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, uri);
    return tokenId;
  }

  function lockMint(
    address to, 
    string memory uri
  ) public nonReentrant returns(uint256) {
    uint256 tokenId = safeMint(to, uri);
    lockToken(tokenId);

    return tokenId;
  }

  function batchMint(
    address[] memory to, 
    string[] memory uri,
    bool[] memory islock
  ) public nonReentrant {

    require(to.length == uri.length,"Invalid parameter uri");
    require(to.length == islock.length,"Invalid parameter islock");

    for(uint i = 0; i < to.length; i++) {
      uint256 tokenId = safeMint(to[i], uri[i]);
      if(islock[i]) {
        lockToken(tokenId);
      }
    }

  }

  // The following functions are overrides required by Solidity.
  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function locked(uint256 tokenId) 
    external 
    view 
    override(IERC5192) 
    returns (bool) 
  {
    return lockedTOkens[tokenId];
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) 
    internal
    virtual 
    override(ERC721)
  {
    require(lockedTOkens[tokenId] == false, "Locked token");
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function lockToken(uint256 tokenId) public {
    require(ownerOf(tokenId) == msg.sender, "Not token owner");
    lockedTOkens[tokenId] = true;
    emit Locked(tokenId);
  }
}