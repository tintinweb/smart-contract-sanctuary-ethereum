// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract NFT is ERC721, Ownable {
  using Strings for uint256;

  string public baseURI;
  uint public _totalSupply;

  constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
    
  }

  function mint(address _to, uint256 _mintAmount) public payable onlyOwner{
    uint256 supply = totalSupply();
    require(_mintAmount > 0);
    require(_totalSupply + _mintAmount <= 145, "Too much");
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
  
    }
    _totalSupply += _mintAmount;
  }

  function totalSupply() internal view returns(uint) {
    return _totalSupply;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
        : "";
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}