// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract ERC721A_Cont is ERC721A, Ownable {
  
  uint256 public mintPrice = 0.1 ether;
  uint256 public whitelistSaletPrice = 0.01 ether;

  string _baseTokenURI;

  bool public isActive = false;
  bool public isWhitelistSaleActive = false;

  uint256 public MAX_SUPPLY = 1000;
  uint256 public maximumAllowedTokensPerPurchase = 3;
  uint256 public maximumAllowedTokensPerWallet = 3;
  uint256 public whitelistWalletLimitation = 3;

  address[] public whitelistedAddresses;

  constructor(string memory baseURI) ERC721A("ERC721A", "E7") {
    setBaseURI(baseURI);
  }

  modifier saleIsOpen {
    require(totalSupply() <= MAX_SUPPLY, "Sale has ended.");
    _;
  }
  
  function setWhitelistSaleWalletLimitation(uint256 maxMint) external  onlyOwner {
    whitelistWalletLimitation = maxMint;
  }

  function setMaximumAllowedTokens(uint256 _count) public onlyOwner {
    maximumAllowedTokensPerPurchase = _count;
  }

  function setMaximumAllowedTokensPerWallet(uint256 _count) public onlyOwner {
    maximumAllowedTokensPerWallet = _count;
  }

  function setMaxMintSupply(uint256 maxMintSupply) external  onlyOwner {
    MAX_SUPPLY = maxMintSupply;
  }

  function setPrice(uint256 _price) public onlyOwner {
    mintPrice = _price;
  }

  function setWhitelistSalePrice(uint256 _whiteslistSalePrice) public onlyOwner {
    whitelistSaletPrice = _whiteslistSalePrice;
  }

  function toggleSaleStatus() public onlyOwner {
    isActive = !isActive;
  }

  function toggleWhiteslistSaleStatus() external onlyOwner {
    isWhitelistSaleActive = !isWhitelistSaleActive;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }


  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function whitelistUsers(address[] calldata _users) public onlyOwner {
      delete whitelistedAddresses;
      whitelistedAddresses = _users;
  }

  function isWhitelisted(address _user) public view returns (bool) {
        for (uint i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

  function devMint(uint256 _count, address _address) external onlyOwner {
    uint256 supply = totalSupply();

    require(supply + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require(supply <= MAX_SUPPLY, "Total supply spent.");

    _safeMint(_address, _count);
  }


  function mint(uint256 _count) public payable saleIsOpen {
    uint256 mintIndex = totalSupply();

     if (msg.sender != owner()) {
      require(isActive, "Sale is not active currently.");
      require(balanceOf(msg.sender) + _count <= maximumAllowedTokensPerWallet, "Max holding cap reached.");
    }

    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require( _count <= maximumAllowedTokensPerPurchase, "Exceeds maximum allowed tokens");
    
    require(msg.value >= (mintPrice * _count), "Insufficient ETH amount sent.");

    _safeMint(msg.sender, _count);
    
  }

  function whitelistSaleMint( uint256 _count) public payable saleIsOpen {
    uint256 mintIndex = totalSupply();
    uint256 discountPrice = _count;

    require(isWhitelistSaleActive, "Presale is not active");
    require(isWhitelisted(msg.sender));
    require(mintIndex < MAX_SUPPLY, "All tokens have been minted");
    require(balanceOf(msg.sender) + _count <= whitelistWalletLimitation, "Cannot purchase this many tokens");

    if(balanceOf(msg.sender) < 1){
      discountPrice = _count - 1;
    }

    require(msg.value >= whitelistSaletPrice * discountPrice, "Insufficient ETH amount sent.");
    
    _safeMint(msg.sender, _count);

  }

  function withdraw() external onlyOwner {
    uint balance = address(this).balance;
    payable(owner()).transfer(balance);
  }
}