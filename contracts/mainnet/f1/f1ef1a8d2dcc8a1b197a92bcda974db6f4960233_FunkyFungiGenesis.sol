// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract FunkyFungiGenesis is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;
  mapping(uint256 => string) public allTokenUris;
  Counters.Counter private supply;

  string public uriPrefix = "ipfs://";
  string public uriSuffix = ".json";
  uint256 public maxSupply = 50;

  constructor() ERC721("Funky Fungi Genesis", "FFGC") {
  }

  modifier mintCompliance() {
    require(supply.current() + 1 <= maxSupply, "Max supply exceeded!");
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function checkIsOwner(address _owner, uint256 _tokenId) public view returns (bool) {
    bool isHolder = false;
    address currentTokenOwner = ownerOf(_tokenId);
    if (currentTokenOwner == _owner) {
    isHolder = true;
    }
    return isHolder;
  }

  function mint(string memory _metadataUri) public mintCompliance() onlyOwner {
    supply.increment();
    allTokenUris[supply.current()] = _metadataUri;
    _safeMint(msg.sender, supply.current());
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "URI query for nonexistent token"
    );

    string memory currentBaseURI = allTokenUris[_tokenId];
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(uriPrefix, currentBaseURI, uriSuffix))
        : "";
  }


  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function updateTokenUri(uint256 _tokenId, string memory _newTokenUri) public onlyOwner {
    allTokenUris[_tokenId] = _newTokenUri;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}