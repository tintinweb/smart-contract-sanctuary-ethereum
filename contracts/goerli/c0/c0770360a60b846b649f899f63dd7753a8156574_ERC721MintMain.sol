// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./Strings.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract ERC721MintMain is ERC721Enumerable, Ownable {

  using Strings for uint256;

  string baseURI = "https://ucdrzee7f7ylawis3opfsqprwwv3saegu6z34ozlgr4xbcxfl7da.arweave.net/";

  uint256 public maxSupply = 100;

  mapping(uint256 => string) private _tokenCids;

  constructor(
    string memory _name,
    string memory _symbol
  ) ERC721(_name, _symbol) {

  }



  // public
  function mint(string memory cid) public onlyOwner {
    uint256 currentSupply = totalSupply() + 1;
    require(currentSupply <= maxSupply);
    _tokenCids[currentSupply] = cid;
    _safeMint(msg.sender,currentSupply);
  }


  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
    string memory currentBaseURI = _baseURI();
    string memory cid = _tokenCids[tokenId];
    return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, cid)) : "";
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

}