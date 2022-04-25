// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import './ERC721A.sol';
import "./Strings.sol"; 

contract WonderWoofs is ERC721A, Ownable, ReentrancyGuard {

  string public hiddenMetadataUri;
  string public baseExtension = ".json";

  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmount;
  uint256 public maxMintLimit;

  bool public paused = false;
  bool public revealed = false;

  mapping(address => uint256) public addressTotalMinted;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmount,
    uint256 _maxMintLimit,
    string memory _hiddenUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmount = _maxMintAmount;
    maxMintLimit = _maxMintLimit;
    setHiddenUri(_hiddenUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(!paused, "the contract is paused");
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded.');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Not enough funds.');
    _;
  }

  modifier additionalCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmount, 'Invalid mint amount.');
    require(addressTotalMinted[msg.sender] + _mintAmount <= maxMintLimit, 'Mint limit exceeded.');

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressTotalMinted[msg.sender]++;
    }
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) additionalCompliance(_mintAmount) {  
    _safeMint(_msgSender(), _mintAmount);
    }

  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function mintForOwner(uint256 _mintAmount) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_msgSender(), _mintAmount);
    }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned && ownership.addr != address(0)) {
        latestOwnerAddress = ownership.addr;
      }

      if (latestOwnerAddress == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }
  
  function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory tokenId = Strings.toString(_tokenId);
    string memory currentBaseURI = _baseURI();

    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId, baseExtension))
        : '';
  }
  
  function setBaseExtension(string memory _baseExtension) public onlyOwner {
    baseExtension = _baseExtension;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setmaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
    maxMintAmount = _maxMintAmount;
  }

  function setmaxMintLimit(uint256 _maxMintLimit) public onlyOwner {
    maxMintLimit = _maxMintLimit;
  }

  function setHiddenUri(string memory _hiddenUri) public onlyOwner {
    hiddenMetadataUri = _hiddenUri;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner nonReentrant {

    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }
}