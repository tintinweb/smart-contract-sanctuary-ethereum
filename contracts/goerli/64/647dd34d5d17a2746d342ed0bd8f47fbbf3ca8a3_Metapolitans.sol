// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";

contract Metapolitans is ERC721A, ReentrancyGuard, Ownable  {

  event SetMaximumAllowedTokens(uint256 _count);
  event SetPrice(uint256 _price);
  event SetBaseUri(string baseURI);
  event Mint(address userAddress, uint256 _count);

  uint256 public mintPrice = 0.3 ether;

  bytes32 public merkleRoot;
  string  private _baseTokenURI;

  bool public isActive = false;

  uint256 public constant MAX_SUPPLY = 4400;
  uint256 public maximumAllowedTokensPerPurchase = 10;

  constructor(string memory baseURI) ERC721A("Metapolitans", "MP") {
    setBaseURI(baseURI);
  }

  modifier saleIsOpen {
    require(totalSupply() < MAX_SUPPLY, "Sale has ended.");
    _;
  }
  
  function setMaximumAllowedTokens(uint256 _count) external onlyOwner {
    maximumAllowedTokensPerPurchase = _count;
    emit SetMaximumAllowedTokens(_count);
  }

  function setPrice(uint256 _price) external onlyOwner {
    mintPrice = _price;
    emit SetPrice(_price);
  }

  function toggleSaleStatus() public onlyOwner {
    isActive = !isActive;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
    emit SetBaseUri(baseURI);
  }


  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function airdrop(uint256 _count, address _address) external onlyOwner saleIsOpen {
    uint256 supply = totalSupply();

    require(supply + _count <= MAX_SUPPLY, "Total supply exceeded.");
    _safeMint(_address, _count);
  }

  function batchAirdrop(uint256 _count, address[] calldata addresses) external onlyOwner saleIsOpen {
    uint256 supply = totalSupply();

    for (uint256 i = 0; i < addresses.length; i++) {
      require(supply + _count <= MAX_SUPPLY, "Total supply exceeded.");
      require(addresses[i] != address(0), "Can't add a null address");
      _safeMint(addresses[i], _count);
    }
  }

  function mint(uint256 _count) external payable saleIsOpen {
    uint256 mintIndex = totalSupply();

     if (msg.sender != owner()) {
      require(isActive, "Sale is not active currently.");
    }

    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require( _count <= maximumAllowedTokensPerPurchase, "Exceeds maximum allowed tokens");
    
    require(msg.value >= (mintPrice * _count), "Insufficient ETH amount sent.");

    _safeMint(msg.sender, _count);
    emit Mint(msg.sender, _count);
  }

  function withdraw() external onlyOwner nonReentrant {
    uint balance = address(this).balance;
    Address.sendValue(payable(owner()), balance);  
  }
}