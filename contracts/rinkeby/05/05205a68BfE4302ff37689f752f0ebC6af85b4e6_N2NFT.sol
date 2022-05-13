// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";


contract N2NFT is Ownable, ERC721A {
  using Strings for uint256;
  uint256 public maxSupply;
  string private _blindTokenURI;
  uint256 private _price = 0.02 ether;
  bool private _isSaleActive = false;
  bool private _blindBoxOpened = false;
  

  constructor( uint256   maxSupply_,string memory baseURI_,string memory blindTokenURI_,string memory name_,string memory symbol_) ERC721A(name_, symbol_) {
    maxSupply = maxSupply_;
    _baseURI = baseURI_;
    _blindTokenURI = blindTokenURI_;
  }


  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseURI = baseURI;
  }

  function getPrice() public view returns (uint256) {
      return _price;
  }


  function setPrice(uint256 newPrice) external onlyOwner {
      _price = newPrice;
  }

  function isSaleAtive() public view returns (bool) {
      return _isSaleActive;
  }

   function flipSaleAtive() external onlyOwner {
      _isSaleActive = !_isSaleActive;
  }


function isBlindBoxOpened() public view returns (bool) {
      return _blindBoxOpened;
  }

 function flipBlindBox() external onlyOwner {
      _blindBoxOpened = !_blindBoxOpened;
  }


function mint(uint256 quantity) external payable {

    require(quantity > 0, "You cannot mint less than 1 Tokens at once.");
    require(quantity  <= (maxSupply - currentIndex) , "Purchase would exceed max supply");

    if (owner() != msg.sender) {
        require(quantity * _price <= msg.value, "Inconsistent amount sent!");
        require(_isSaleActive, "public sale has not begun yet");
    }

    _safeMint(msg.sender, quantity);

  }


 /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory){

    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    
    if (_blindBoxOpened == false) {
       return _blindTokenURI;
     }
    else{
      return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString())) : "";
     }

  }


  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0,'Nothing to withdraw');
    require(payable(owner()).send(balance));
  }



}