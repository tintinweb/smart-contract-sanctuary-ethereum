// SPDX-License-Identifier: MIT

import './ERC721AQueryable.sol';
import './Ownable.sol';
import './ReentrancyGuard.sol';
import './DefaultOperatorFilterer.sol';

pragma solidity >=0.8.9 <0.9.0;

contract Pilot is ERC721AQueryable, Ownable, ReentrancyGuard, DefaultOperatorFilterer {

  using Strings for uint256;
  string public uri;
  string public uriSuffix = ".json";
  uint256 public cost = 0.004 ether;
  uint256 public supplyLimit = 5555;
  uint256 public maxMintAmountPerTx = 20;
  bool public sale = false;
 
  constructor(
  )ERC721A("Pixel Pilots", "PP"){}  
  

  function Mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(sale, 'The sale is not active yet!');
    require(supply + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _safeMint(_msgSender(), _mintAmount);
  }  
  
  function FreeMint() public payable {
    uint256 supply = totalSupply();
    require(sale, 'The sale is not active yet!');
    require(supply + 1 <= supplyLimit, 'Max supply exceeded!');
    require(balanceOf(msg.sender) < 1, 'Already Claimed Free Token!');
    _safeMint(_msgSender(), 1);
  }  
  
  function TeamMint(uint256 _mintAmount) public onlyOwner {
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    _safeMint(_msgSender(), _mintAmount);
  }  

  function setUri(string memory _uri) public onlyOwner {
    uri = _uri;
  }

  function setSaleStatus(bool _sale) public onlyOwner {
    sale = _sale;
  }
  
  function withdraw() public onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "WITHDRAW FAILED.");
    
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721Metadata) returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }
  
  function transferFrom(address from, address to, uint256 tokenId) public override(ERC721A, IERC721) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721A, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721A, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}