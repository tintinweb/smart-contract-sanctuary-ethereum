// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC721.sol";
import "./ERC2981.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract OMeowCats is ERC721, ERC2981, ReentrancyGuard, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public contractURI;
  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
    
  uint256 public cost = 0.1 ether;
  uint256 public maxSupply = 5000;
  uint256 public maxMintAmountPerTx = 25;

  bool public paused = false;
  bool public revealed = false;

  constructor(
    address royalty_,
    uint96 royaltyFee_,
    string memory _contractURI
  ) ERC721("O Meow Cats", "OMC") {
    setHiddenMetadataUri("https://gateway.pinata.cloud/ipfs/QmWKnEao5UhthWismh6spEuj1vRB5tPABT9pBcJYYpNxKS");
    _setDefaultRoyalty(royalty_, royaltyFee_);
    contractURI = _contractURI;
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

// Public

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function _safeMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");

    _mintLoop(msg.sender, _mintAmount);
  }
  
  function mintForOwner(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
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
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

// Internal, Only Owner

  function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        internal
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

  function setContractURI(string calldata _contractURI) public onlyOwner {
       contractURI = _contractURI;
    }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
   }


  function _mintLoop(address _receiver, uint256 _mintAmount) internal onlyOwner {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

   // The following functions are overrides required by Solidity.

   function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

   function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}