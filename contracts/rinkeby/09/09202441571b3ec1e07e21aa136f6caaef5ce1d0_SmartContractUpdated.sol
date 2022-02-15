// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract SmartContractUpdated is ERC721, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenSupply;
  Counters.Counter private _nextTokenId;


  uint256 public mintPrice = 0.001 ether;

  uint256 private reserveAtATime = 2;
  uint256 private reservedCount = 0;
  uint256 private maxReserveCount = 100;

  string _baseTokenURI;

  bool public isActive = true;

  uint256 public MAX_SUPPLY = 100;
  uint256 public maximumAllowedTokensPerPurchase = 100;
  uint256 public maximumAllowedTokensPerWallet = 100;
  uint256 public presaleMaxMint = 5;

  mapping(address => bool) private _whiteList;
  mapping(address => uint256) private _whiteListClaimed;

  event SaleActivation(bool isActive);

  constructor(string memory baseURI) ERC721("Smart Contract", "SC") {
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


  function addToWhiteList(address[] calldata addresses) external onlyAuthorized {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add a null address");
      _whiteList[addresses[i]] = true;
      _whiteListClaimed[addresses[i]] > 0 ? _whiteListClaimed[addresses[i]] : 0;
    }
  }

  function checkIfOnAllowList(address _whiteListedAddress) external view returns (bool) {
    return _whiteList[_whiteListedAddress];
  }

  function removeFromAllowList(address[] calldata addresses) external onlyAuthorized {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add a null address");
      _whiteList[addresses[i]] = false;
    }
  }

  function whiteListClaimedBy(address owner) external view returns (uint256){
    require(owner != address(0), 'Zero address not on Allow List');
    return _whiteListClaimed[owner];
  }

  function setPrice(uint256 _price) public onlyAuthorized {
    mintPrice = _price;
  }

  function setBaseURI(string memory baseURI) public onlyAuthorized {
    _baseTokenURI = baseURI;
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

  function reserveToCustomWallet(address _walletAddress, uint256 _count) public onlyAuthorized {
    for (uint256 i = 0; i < _count; i++) {
      _tokenSupply.increment();
      _safeMint(_walletAddress, _tokenSupply.current());
    }
  }

  function mint(uint256 _count) public payable saleIsOpen {
    uint256 mintIndex = _tokenSupply.current();

    if (msg.sender != owner()) {
      require(balanceOf(msg.sender) + _count <= maximumAllowedTokensPerWallet, "Max holding cap reached.");
    }


    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require(
      _count <= maximumAllowedTokensPerPurchase,
      "Exceeds maximum allowed tokens"
    );

    require(msg.value >= mintPrice * _count, "Insufficient ETH amount sent.");

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