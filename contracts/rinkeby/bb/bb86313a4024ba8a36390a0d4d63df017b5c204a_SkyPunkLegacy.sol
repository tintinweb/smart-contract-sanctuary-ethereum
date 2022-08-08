// SPDX-License-Identifier: MIT
// Made by: NFT Stack
//          https://nftstack.info
//

pragma solidity ^0.8.1;

import "./Ownable.sol";
import "./ERC721A.sol";

contract SkyPunkLegacy is ERC721A, Ownable {
  uint256 public mintPrice = 0.25 ether;
  uint256 public preSaleMintPrice =  0.15 ether;

  uint256 public preSaleBreakPoint1 = 125;
  uint256 public preSaleBreakPoint2 = 1875;

  uint256 private reserveAtATime = 50;
  uint256 private reservedCount = 0;
  uint256 private maxReserveCount = 100;

  string _baseTokenURI;

  bool public isMintActive = false;
  bool public isPreSaleMintActive = false;
  bool public isClosedMintForever = false;
  bool public isSellOpen = false;

  uint256 public maximumMintSupply = 2000;
  uint256 public maximumAllowedTokensPerPurchase = 1;
  uint256 public maximumAllowedTokensPerWallet = 2;
  uint256 public allowListMaxMint = 1;
  uint256 public immutable maxPerAddressDuringMint;

  address private OtherAddress1 = 0x809F6DC33a408974d271D1D2F5890dA7f00D65Df;
  address private OtherAddress2 = 0x0Fc0F78fc939606db65F5BBF2F3715262C0b2F6E;
  address private OtherAddress3 = 0xE4a5510402E17AD8bEd1D5f891f9c4D8F104E11c;
  address private OtherAddress4 = 0xb302a97dB500f51A9fc2500c0864768aEb160972;
  address private OtherAddress5 = 0x4F6568396EA576555288295904e246eA9CE182C2;

  mapping(address => bool) private _allowList;
  mapping(address => uint256) private _allowListClaimed;
  mapping(address => uint256) private _publicMintClaimed;

  event AssetMinted(uint256 tokenId, address sender);
  event SaleActivation(bool isMintActive);

  constructor(
    string memory baseURI,
    uint256 maxBatchSize_,
    uint256 collectionSize_
  ) ERC721A("SkyPunk Legacy", "SkyPunk Legacy", maxBatchSize_, collectionSize_) {
    setBaseURI(baseURI);
    maxPerAddressDuringMint = maxBatchSize_;
  }

  modifier saleIsOpen {
    require(totalSupply() <= maximumMintSupply, "Sale has ended.");
    _;
  }

  modifier onlyAuthorized() {
    require(owner() == msg.sender);
    _;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function setMaximumAllowedTokens(uint256 _count) public onlyAuthorized {
    maximumAllowedTokensPerPurchase = _count;
  }

  function setMaximumAllowedTokensPerWallet(uint256 _count) public onlyAuthorized {
    maximumAllowedTokensPerWallet = _count;
  }

  function setMintActive(bool val) public onlyAuthorized {
    isMintActive = val;
    emit SaleActivation(val);
  }

  function setMaxMintSupply(uint256 maxMintSupply) external  onlyAuthorized {
    maximumMintSupply = maxMintSupply;
  }

  function setIsPreSaleMintActive(bool _isPreSaleMintActive) external onlyAuthorized {
    isPreSaleMintActive = _isPreSaleMintActive;
  }

  function setIsSellOpen(bool _isSellOpen) external onlyAuthorized {
    isSellOpen = _isSellOpen;
  }

  function setAllowListMaxMint(uint256 maxMint) external  onlyAuthorized {
    allowListMaxMint = maxMint;
  }

  function addToAllowList(address[] calldata addresses) external onlyAuthorized {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add a null address");
      _allowList[addresses[i]] = true;
      _allowListClaimed[addresses[i]] > 0 ? _allowListClaimed[addresses[i]] : 0;
    }
  }

  function checkIfOnAllowList(address addr) external view returns (bool) {
    return _allowList[addr];
  }

  function removeFromAllowList(address[] calldata addresses) external onlyAuthorized {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add a null address");
      _allowList[addresses[i]] = false;
    }
  }

  function allowListClaimedBy(address owner) external view returns (uint256){
    require(owner != address(0), 'Zero address not on Allow List');
    return _allowListClaimed[owner];
  }

  function publicMintClaimed(address owner) external view returns (uint256){
    require(owner != address(0), 'Zero address not on Allow List');
    return _publicMintClaimed[owner];
  }

  function setReserveAtATime(uint256 val) public onlyAuthorized {
    reserveAtATime = val;
  }

  function setMaxReserve(uint256 val) public onlyAuthorized {
    maxReserveCount = val;
  }

  function setMintPrice(uint256 _price) public onlyAuthorized {
    mintPrice = _price;
  }

  function setPreSaleMintPrice(uint256 _price) public onlyAuthorized {
    preSaleMintPrice = _price;
  }

  function setBaseURI(string memory baseURI) public onlyAuthorized {
    _baseTokenURI = baseURI;
  }

  function getMaximumAllowedTokens() public view onlyAuthorized returns (uint256) {
    return maximumAllowedTokensPerPurchase;
  }

  function getMintPrice() external view returns (uint256) {
    return mintPrice;
  }

  function getPreSaleMintPrice() external view returns (uint256) {
    return preSaleMintPrice;
  }

  function getIsClosedMintForever() external view returns (bool) {
    return isClosedMintForever;
  }

  function setIsClosedMintForever() external onlyAuthorized {
    isClosedMintForever = true;
  }

  function getReserveAtATime() external view returns (uint256) {
    return reserveAtATime;
  }

  function getTotalSupply() external view returns (uint256) {
    return totalSupply();
  }

  function getContractOwner() public view returns (address) {
    return owner();
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function reserveNft() public onlyAuthorized {
    require(reservedCount <= maxReserveCount, "Max Reserves taken already!");
    require(totalSupply() + reserveAtATime <= maximumMintSupply, "Total supply exceeded.");
    require(totalSupply() <= maximumMintSupply, "Total supply spent.");

    reservedCount += reserveAtATime;
    _safeMint(msg.sender, reserveAtATime);
  }

  function reserveToCustomWallet(address _walletAddress, uint256 _count) public onlyAuthorized {
    require(totalSupply() + _count <= maximumMintSupply, "Total supply exceeded.");
    require(totalSupply() <= maximumMintSupply, "Total supply spent.");

    _safeMint(_walletAddress, _count);
  }

  function mint(address _to, uint256 _count) public payable saleIsOpen callerIsUser {
    if (msg.sender != owner()) {
      require(isMintActive, "Sale is not active currently.");
    }

    if(_to != owner()) {
      require(balanceOf(_to) + _count <= maximumAllowedTokensPerWallet, "Max holding cap reached.");
    }

    require(_publicMintClaimed[msg.sender] + _count <= maximumAllowedTokensPerWallet, "Purchase exceeds max allowed");
    require(totalSupply() + _count <= maximumMintSupply, "Total supply exceeded.");
    require(totalSupply() <= maximumMintSupply, "Total supply spent.");
    require(
      _count <= maximumAllowedTokensPerPurchase,
      "Exceeds maximum allowed tokens"
    );
    require(
      numberMinted(msg.sender) + _count <= maxPerAddressDuringMint,
      "can not mint this many"
    );
    require(!isClosedMintForever, "Mint Closed Forever");
    require(msg.value >= mintPrice * _count, "Insuffient ETH amount sent.");

    _publicMintClaimed[msg.sender] += _count;
    _safeMint(_to, _count);
  }

  function preSaleMint(uint256 _count) public payable saleIsOpen {
    require(isPreSaleMintActive, 'Pre Sale Mint is not active');
    require(_allowList[msg.sender], 'You are not on the Allow List');
    require(totalSupply() < maximumMintSupply, 'All tokens have been minted');
    require(_count <= allowListMaxMint, 'Cannot purchase this many tokens');
    require(_allowListClaimed[msg.sender] + _count <= allowListMaxMint, 'Purchase exceeds max allowed');
    require(msg.value >= preSaleMintPrice * _count, 'Insuffient ETH amount sent.');
    require(!isClosedMintForever, 'Mint Closed Forever');
    _allowListClaimed[msg.sender] += _count;

    if(totalSupply() + _count == preSaleBreakPoint1) {
      isPreSaleMintActive = false;
      preSaleMintPrice = 0.2 ether;
    } else if(totalSupply() + _count == preSaleBreakPoint2) {
      isPreSaleMintActive = false;
    }

    _safeMint(msg.sender, _count);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function walletOfOwner(address _owner) external view returns(uint256[] memory) {
    uint tokenCount = balanceOf(_owner);
    uint256[] memory tokensId = new uint256[](tokenCount);

    for(uint i = 0; i < tokenCount; i++){
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
  }

  function withdraw() external onlyAuthorized {
    uint balance = address(this).balance;
    payable(OtherAddress1).transfer(balance * 500 / 10000);
    payable(OtherAddress2).transfer(balance * 500 / 10000);
    payable(OtherAddress3).transfer(balance * 500 / 10000);
    payable(OtherAddress4).transfer(balance * 1000 / 10000);
    payable(OtherAddress5).transfer(balance * 7500 / 10000);
    payable(owner()).transfer(balance * 0 / 10000);
  }
}