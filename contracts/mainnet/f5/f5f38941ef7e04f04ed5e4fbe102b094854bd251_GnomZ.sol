// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";           

contract GnomZ is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;

  uint256 public cost = 0.0055 ether;
  uint256 public maxSupply = 5555;
  uint256 public maxMintAmount = 10;
  uint256 public maxFreeMintPerWalletAmount = 1;

  bool public revealed = true;
  bool public paused = true;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(!paused, "The contract is paused!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(tx.origin == msg.sender, "The caller is another contract");
    require(
      _mintAmount > 0 && numberMinted(msg.sender) + _mintAmount <= maxMintAmount,
       "Invalid mint amount!"
    );
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    uint256 costToSubtract = 0;
    
    if (numberMinted(msg.sender) < maxFreeMintPerWalletAmount) {
      uint256 freeMintsLeft = maxFreeMintPerWalletAmount - numberMinted(msg.sender);
      costToSubtract = cost * freeMintsLeft;
    }
   
    require(msg.value >= cost * _mintAmount - costToSubtract, "Insufficient funds!");
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
    maxMintAmount = _maxMintAmount;
  }

  function setmaxFreeMintPerWalletAmount(uint256 _maxFreeMintPerWalletAmount) public onlyOwner {
    maxFreeMintPerWalletAmount = _maxFreeMintPerWalletAmount;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
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

  function withdraw() public onlyOwner nonReentrant {
    uint256 artistPayment = address(this).balance * 43 / 100;
    uint256 marketerPayment = address(this).balance * 43 / 100;

    (bool artistSuccess, ) = payable(0xE17f470F2E6Fb137815959809eEaF082A927c361).call{value: artistPayment}('');
    require(artistSuccess);

    (bool marketerSuccess, ) = payable(0x0dfa2abD152fcc466f58ECfa772d9EDF9EF55F0a).call{value: marketerPayment}('');
    require(marketerSuccess);

    (bool devSuccess, ) = payable(0x728283D08eFB53f7314cB2c425090B43927A32ad).call{value: address(this).balance}('');
    require(devSuccess);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}