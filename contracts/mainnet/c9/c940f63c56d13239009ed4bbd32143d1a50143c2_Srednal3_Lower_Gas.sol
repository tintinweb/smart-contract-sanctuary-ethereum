pragma solidity >=0.7.0 <0.9.0;

import "ERC721.sol";
import "Counters.sol";
import "Ownable.sol";

contract Srednal3_Lower_Gas is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "ipfs://QmatdiEUrQWqhBbzpTJYwgrnnutjavJiqnhibrYBxCd3SZ/";
  string public uriSuffix = ".png";
  string public hiddenMetadataUri;
  
  uint256 public cost = 0.02 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmountPerTx = 20;
  uint256 public freeSupply = 1250;

  bool public paused = false;
  bool public revealed = false;

  constructor() ERC721("Srednal3", "SN3") {
    setHiddenMetadataUri("https://gateway.pinata.cloud/ipfs/QmUHq8u3LgdKG5fvZRqSqb8aFRKLZyJydKPbDAiiWRndzN");
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }
function contractURI() public view returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/QmUHq8u3LgdKG5fvZRqSqb8aFRKLZyJydKPbDAiiWRndzN";
    }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function isFree() public view returns (bool) {
      uint256 supply = totalSupply();
      return (supply < freeSupply);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");

    int256 freeLeft = int256(freeSupply) - int256(supply.current());
    if (freeLeft < 0) {
      freeLeft = 0;
    }

    if (_mintAmount + supply.current() >= freeSupply){
      require(msg.value >= cost * (_mintAmount - uint256(freeLeft)), "Insufficient funds!");
    }

    _mintLoop(msg.sender, _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
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
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}