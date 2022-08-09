// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "./Ownable.sol";

contract ArtBulls is ERC721A, Ownable {
  
  uint256 public mintPrice = 0.03 ether;
  uint256 private reserveAtATime = 5;
  
  uint256 private reservedCount = 0;
  uint256 private maxReserveCount = 5;
  string _baseTokenURI;
  bool public isActive = false;
  bool public isPresaleActive = false;
  uint256 public MAX_SUPPLY = 1111;

  mapping(address => bool) private _allowList;

  constructor(string memory baseURI) ERC721A("Art Bulls", "AB") {
    setBaseURI(baseURI);
  }

  modifier saleIsOpen {
    require(totalSupply() <= MAX_SUPPLY, "Sale has ended.");
    _;
  }

  function setMaxMintSupply(uint256 maxMintSupply) external  onlyOwner {
    MAX_SUPPLY = maxMintSupply;
  }

  function setPrice(uint256 _price) public onlyOwner {
    mintPrice = _price;
  }

  function toggleSaleStatus() public onlyOwner {
    isActive = !isActive;
  }

  function togglePresaleStatus() external onlyOwner {
    isPresaleActive = !isPresaleActive;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

   function reserveNft() public onlyOwner {
    require(reservedCount <= maxReserveCount, "Max Reserves taken already!");
    
    _safeMint(msg.sender, reserveAtATime);
    reservedCount += reserveAtATime;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function airdrop(uint256 _count, address _address) external onlyOwner {
    uint256 supply = totalSupply();
    require(supply + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require(supply <= MAX_SUPPLY, "Total supply spent.");
    _safeMint(_address, _count);
  }

  function batchAirdrop(uint256 _count, address[] calldata addresses) external onlyOwner {
    uint256 supply = totalSupply();
    require(supply + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require(supply <= MAX_SUPPLY, "Total supply spent.");
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add a null address");
      _safeMint(addresses[i], _count);
    }
  }

  function mint(uint256 _count) public payable saleIsOpen {
    uint256 mintIndex = totalSupply();
    require(isActive, "Sale is not active currently.");
    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require(msg.value >= mintPrice * _count, "Insufficient ETH amount sent.");
    _safeMint(msg.sender, _count);
    
  }

  function withdraw() external onlyOwner {
    uint balance = address(this).balance;
    payable(owner()).transfer(balance);
  }

}