// SPDX-License-Identifier: MIT
/*
.__   __.  _______  _______   _______  _______ .______      
|  \ |  | |   ____||       \ |   ____||   ____||   _  \     
|   \|  | |  |__   |  .--.  ||  |__   |  |__   |  |_)  |    
|  . `  | |   __|  |  |  |  ||   __|  |   __|  |      /     
|  |\   | |  |     |  '--'  ||  |____ |  |____ |  |\  \----.
|__| \__| |__|     |_______/ |_______||_______|| _| `._____|                      
*/
pragma solidity >=0.8.9 <0.9.0;

import './ERC721AQueryable.sol';
import './Ownable.sol';
import './ReentrancyGuard.sol';
import './Pausable.sol';
import './ERC2981.sol';
import './DefaultOperatorFilterer.sol';
import './Strings.sol';

contract NFDeer is ERC721AQueryable, Ownable, ReentrancyGuard, Pausable, ERC2981, DefaultOperatorFilterer {

  uint256 public maxSupply = 5555;
  string public uriPrefix = '';

  uint256 public maxMintAmountPerTx = 1;
  bool public revealed = false;
  string public hiddenMetadataUri = "https://eyalgolannft.mypinata.cloud/ipfs/Qmeku1View9Fa9LoRxfgX5b4iReNUN9t4HgktrF7QRNcWC";
  mapping(bytes32 => bool) public minted;

  string private uriSuffix = '.json';
  event Minted(address owner, bytes32 hash);

  constructor() ERC721A("NFDeer", "NR") {
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  function mintOwner(address addr, bytes32 token, uint256 amount) public payable onlyOwner whenNotPaused mintCompliance(amount){
    require(!minted[token],"Already minted");
    _safeMint(addr, amount);
    minted[token]=true;
    emit Minted(addr, token);
  }

  function teamMint(uint256 _teamAmount) external onlyOwner {
    require(totalSupply() + _teamAmount <= maxSupply, 'Max supply exceeded!');
    _safeMint(_msgSender(), _teamAmount);
  }

  function airdrop(uint256 _mintAmount, address _receiver) public onlyOwner mintCompliance(_mintAmount){
    _safeMint(_receiver, _mintAmount);
  }

  function airdrops(address[] memory _addresses) public onlyOwner {
    for (uint i = 0; i < _addresses.length; i++) {
      airdrop(1, _addresses[i]);
    }
  }

  function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721A) returns(string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0 ?
      string(abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), uriSuffix)) :
      '';
  }

  function setPause() public onlyOwner {
    _pause();
  }

  function setUnpause() public onlyOwner {
    _unpause();
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call {value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns(string memory) {
    return uriPrefix;
  }

  function _startTokenId() internal view virtual override returns(uint256) {
    return 1;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
    return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }

  function setRoyaltyInfo(address payable receiver, uint96 numerator) public onlyOwner {
    _setDefaultRoyalty(receiver, numerator);
  }

    function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}