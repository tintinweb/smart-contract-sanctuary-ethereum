// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract WBOTESToken is ERC721, ERC721URIStorage, Pausable, Ownable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdCounter;

  string private _baseTokenURI;

  uint256 public price = 70000000000000000;

  uint256 public MAX_TOKENS = 12;

  mapping (address => bool) public whitelist;

  constructor() ERC721("Les Winkybottes", "WBOTTE") {}

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function setBaseTokenURI(string memory _uri) public onlyOwner {
    _baseTokenURI = _uri;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setPrice(uint _price) public onlyOwner {
    price = _price;
  }

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

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function mint(uint numberOfTokens) public payable {
    require(!paused(), "Address must not be paused");
    require(msg.value >= price.mul(numberOfTokens), "Ether value sent is not correct");
    mintTokens(msg.sender, numberOfTokens);
  }

  function mintTokens(address to, uint numberOfTokens) private {
    require(_tokenIdCounter.current().add(numberOfTokens) <= MAX_TOKENS, "Purchase would exceed MAX_TOKENS");

    for(uint i = 0; i < numberOfTokens; i++) {
      uint256 mintIndex = _tokenIdCounter.current();
      if (mintIndex < MAX_TOKENS) {
	      _safeMint(to, mintIndex);
        _tokenIdCounter.increment();
      }
    }
  }

  function mintByOwner(address[] memory tos, uint[] memory amounts) public onlyOwner {
    for(uint i = 0; i < tos.length; i++) {
      mintTokens(tos[i], amounts[i]);
    }
  }
}