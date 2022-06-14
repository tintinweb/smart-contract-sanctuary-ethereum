// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract GuardiansOfSumantria is ERC721, Ownable {

  using Counters for Counters.Counter;
  Counters.Counter private _tokenSupply;
  Counters.Counter private _nextTokenId;
  
  uint256 public mintPrice = 0.12 ether;
  uint256 public presalePrice = 0.1 ether;

  uint256 private reserveAtATime = 125;
  uint256 private reservedCount = 0;
  uint256 private maxReserveCount = 250;

  string _baseTokenURI;

  bool public isActive = false;
  bool public isPresaleActive = false;

  uint256 public MAX_SUPPLY = 6777;
  uint256 public maxAllowedTokensPerPurchase = 6777;
  uint256 public maxAllowedTokensPerWallet = 6777;
  uint256 public presaleWalletLimitation = 6777;


  mapping(address => bool) private _allowList;
  mapping(address => uint256) private _allowListClaimed;

  event AssetMinted(uint256 tokenId, address sender);
  event SaleActivation(bool isActive);

  constructor(string memory baseURI) ERC721("Guardians of Sumantria", "GS") {
    setBaseURI(baseURI);
  }

  modifier saleIsOpen {
    require(_tokenSupply.current() <= MAX_SUPPLY, "Sale has ended.");
    _;
  }

  modifier onlyAuthorized() {
    require(owner() == msg.sender);
    _;
  }

  function tokensMinted() public view returns (uint256) {
    return _tokenSupply.current();
  }

  function setMaximumAllowedTokens(uint256 _count) public onlyAuthorized {
    maxAllowedTokensPerPurchase = _count;
  }

  function setMaxAllowedTokensPerWallet(uint256 _count) public onlyAuthorized {
    maxAllowedTokensPerWallet = _count;
  }

  function togglePublicSale() public onlyAuthorized {
    isActive = !isActive;
  }

  function setMaxMintSupply(uint256 maxMintSupply) external  onlyAuthorized {
    MAX_SUPPLY = maxMintSupply;
  }

  function togglePresaleActive() external onlyAuthorized {
    isPresaleActive = !isPresaleActive;
  }

  function setPresaleWalletLimitation(uint256 maxMint) external  onlyAuthorized {
    presaleWalletLimitation = maxMint;
  }

  function addToWhiteList(address[] calldata addresses) external onlyAuthorized {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add a null address");
      _allowList[addresses[i]] = true;
      _allowListClaimed[addresses[i]] > 0 ? _allowListClaimed[addresses[i]] : 0;
    }
  }

  function checkIfOnWhiteList(address addr) external view returns (bool) {
    return _allowList[addr];
  }

  function removeFromWhiteList(address[] calldata addresses) external onlyAuthorized {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add a null address");
      _allowList[addresses[i]] = false;
    }
  }

  function allowListClaimedBy(address owner) external view returns (uint256){
    require(owner != address(0), 'Zero address not on Allow List');
    return _allowListClaimed[owner];
  }

  function setReserveAtATime(uint256 val) public onlyAuthorized {
    reserveAtATime = val;
  }

  function setMaxReserve(uint256 val) public onlyAuthorized {
    maxReserveCount = val;
  }

  function setPrice(uint256 _price) public onlyAuthorized {
    mintPrice = _price;
  }

  function setPresalePrice(uint256 _presalePrice) public onlyAuthorized {
    presalePrice = _presalePrice;
  }

  function setBaseURI(string memory baseURI) public onlyAuthorized {
    _baseTokenURI = baseURI;
  }

  function getReserveAtATime() external view returns (uint256) {
    return reserveAtATime;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

 function reserveNft() public onlyAuthorized {
    require(reservedCount <= maxReserveCount, "Max Reserves taken already!");

    uint256 i;

    for (i = 0; i < reserveAtATime; i++) {
      _tokenSupply.increment();
      _safeMint(msg.sender, _tokenSupply.current());
      reservedCount++;
    }
  }

  function adminAirdrop(address _walletAddress, uint256 _count) public onlyAuthorized {
    uint256 supply = _tokenSupply.current();

    require(supply + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require(supply <= MAX_SUPPLY, "Total supply spent.");
    
    for (uint256 i = 0; i < _count; i++) {
      _tokenSupply.increment();
      _safeMint(_walletAddress, _tokenSupply.current());
    }
  }

  function batchAirdropToMultipleAddresses(uint256 _count, address[] calldata addresses) external onlyAuthorized {
    uint256 supply = _tokenSupply.current();

    require(supply + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require(supply <= MAX_SUPPLY, "Total supply spent.");

    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add a null address");

      for(uint256 j = 0; j < _count; j++) {
        _tokenSupply.increment();
        _safeMint(addresses[i], _tokenSupply.current());
      }
    }
  }

  function mint(uint256 _count) public payable saleIsOpen {
    uint256 mintIndex = _tokenSupply.current();

    if (msg.sender != owner()) {
      require(isActive, "Sale is not active currently.");
      require(balanceOf(msg.sender) + _count <= maxAllowedTokensPerWallet, "Max holding cap reached.");
    }


    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require(
      _count <= maxAllowedTokensPerPurchase,
      "Exceeds maximum allowed tokens"
    );

    require(msg.value >= mintPrice * _count, "Insufficient ETH amount sent.");

    for (uint256 i = 0; i < _count; i++) {
      _tokenSupply.increment();
      _safeMint(msg.sender, _tokenSupply.current());
    }
  }

  function preSaleMint(uint256 _count) public payable saleIsOpen {
    uint256 mintIndex = _tokenSupply.current();

    require(isPresaleActive, 'Presale is not active');
    require(_allowList[msg.sender], 'You are not on the White List');
    
    require(mintIndex < MAX_SUPPLY, 'All tokens have been minted');
    require(_count <= presaleWalletLimitation, 'Cannot purchase this many tokens');
    require(_allowListClaimed[msg.sender] + _count <= presaleWalletLimitation, 'Purchase exceeds max allowed');
    require(msg.value >= presalePrice * _count, 'Insuffient ETH amount sent.');

    for (uint256 i = 0; i < _count; i++) {
      _tokenSupply.increment();
      _safeMint(msg.sender, _tokenSupply.current());
    }
  }

  function withdraw() external onlyAuthorized {
    uint balance = address(this).balance;
    payable(owner()).transfer(balance);
  }
}