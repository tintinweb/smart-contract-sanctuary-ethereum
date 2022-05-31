// SPDX-License-Identifier: MIT
// Made by: NFT Stack
//          https://nftstack.info
//

pragma solidity ^0.8.1;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract NFTStack721ARaffle is ERC721A, Ownable {
  using MerkleProof for bytes32[];

  bytes32 public root;
  uint256 public mintPrice = 0.3 ether;
  uint256 public raffleMintPrice = 0.15 ether;
  uint256 public raffleBreakPoint1 = 5;
  uint256 public raffleBreakPoint2 = 10;
  uint256 public raffleBreakPoint3 = 15;

  uint256 private reserveAtATime = 50;
  uint256 private reservedCount = 0;
  uint256 private maxReserveCount = 100;

  string _baseTokenURI;

  bool public isRaffleActive1 = false;
  bool public isRaffleActive2 = false;
  bool public isRaffleActive3 = false;
  bool public isMintActive = false;
  bool public isClosedMintForever = false;

  uint256 public maximumMintSupply = 8888;
  uint256 public maximumAllowedTokensPerPurchase = 5;
  uint256 public maximumAllowedTokensPerWallet = 5;
  uint256 public raffleMaxMint1 = 2;
  uint256 public raffleMaxMint2 = 3;
  uint256 public raffleMaxMint3 = 4;

  uint256 public immutable maxPerAddressDuringMint;

  address private OtherAddress1 = 0x9DbF14C79847D1566419dCddd5ad35DAf0382E05;
  address private OtherAddress2 = 0x9DbF14C79847D1566419dCddd5ad35DAf0382E05;

  mapping(address => bool) private _allowList;
  mapping(address => uint256) private _allowListClaimed;

  event AssetMinted(uint256 tokenId, address sender);
  event SaleActivation(bool isMintActive);

  constructor(
    string memory baseURI,
    uint256 maxBatchSize_,
    uint256 collectionSize_
   ) ERC721A("NFTStackTest", "NFTStackTest", maxBatchSize_, collectionSize_) {
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

  function setRaffleBreakPoint1(uint256 point) external  onlyAuthorized {
    raffleBreakPoint1 = point;
  }

  function setRaffleBreakPoint2(uint256 point) external  onlyAuthorized {
    raffleBreakPoint2 = point;
  }

  function setRaffleBreakPoint3(uint256 point) external  onlyAuthorized {
    raffleBreakPoint3 = point;
  }

  function setRaffleActive1(bool _isRaffleActive) public onlyAuthorized {
    isRaffleActive1 = _isRaffleActive;
  }

  function setRaffleActive2(bool _isRaffleActive) public onlyAuthorized {
    isRaffleActive2 = _isRaffleActive;
  }

  function setRaffleActive3(bool _isRaffleActive) public onlyAuthorized {
    isRaffleActive3 = _isRaffleActive;
  }

  function setRaffleMaxMint1(uint256 maxMint) external  onlyAuthorized {
    raffleMaxMint1 = maxMint;
  }

  function setRaffleMaxMint2(uint256 maxMint) external  onlyAuthorized {
    raffleMaxMint2 = maxMint;
  }

  function setRaffleMaxMint3(uint256 maxMint) external  onlyAuthorized {
    raffleMaxMint3 = maxMint;
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

  function setReserveAtATime(uint256 val) public onlyAuthorized {
    reserveAtATime = val;
  }

  function setMaxReserve(uint256 val) public onlyAuthorized {
    maxReserveCount = val;
  }

  function setMintPrice(uint256 _price) public onlyAuthorized {
    mintPrice = _price;
  }

  function setRaffleMintPrice(uint256 _price) public onlyAuthorized {
    raffleMintPrice = _price;
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

  function getRaffleMintPrice() external view returns (uint256) {
    return raffleMintPrice;
  }

  function getIsClosedMintForever() external view returns (bool) {
    return isClosedMintForever;
  }

  function setIsClosedMintForever() external onlyAuthorized {
    isClosedMintForever = true;
  }

  function setRoot(bytes32 _root) public onlyAuthorized {
    root = _root;
  }

  function getReserveAtATime() external view returns (uint256) {
    return reserveAtATime;
  }

  function getTotalSupply() external view returns (uint256) {
    return totalSupply();
  }

  function getRoot() external view returns (bytes32) {
    return root;
  }

  function getContractOwner() public view returns (address) {
    return owner();
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function reserveNft() public onlyAuthorized {
    require(reservedCount <= maxReserveCount, "Max Reserves taken already!");
    uint256 supply = totalSupply();
    uint256 i;

    for (i = 1; i <= reserveAtATime; i++) {
      emit AssetMinted(supply + i, msg.sender);
      _safeMint(msg.sender, supply + i);
      reservedCount++;
    }
  }

  function reserveToCustomWallet(address _walletAddress, uint256 _count) public onlyAuthorized {
    for (uint256 i = 0; i < _count; i++) {
      emit AssetMinted(totalSupply(), _walletAddress);
      _safeMint(_walletAddress, totalSupply());
    }
  }

  function mint(address _to, uint256 _count) public payable saleIsOpen callerIsUser {
    if (msg.sender != owner()) {
      require(isMintActive, "Sale is not active currently.");
    }

    if(_to != owner()) {
      require(balanceOf(_to) + _count <= maximumAllowedTokensPerWallet, "Max holding cap reached.");
    }

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

    _safeMint(_to, _count);
  }

  function raffleMint(uint256 _count) public payable saleIsOpen {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    uint256 supply = totalSupply();
    require(totalSupply() < maximumMintSupply, "All tokens have been minted");

    if(!isRaffleActive1 && !isRaffleActive2 && !isRaffleActive3) {
      require(false, "Raffle is not active");
    }

    if (isRaffleActive1) {
      require(_count <= raffleMaxMint1, "Cannot purchase this many tokens for this stage");
      require(isRaffleActive3 && _count + supply < raffleBreakPoint3, "No NFTs are left to mint for this stage");
    }

    if (isRaffleActive2) {
      require(_count <= raffleMaxMint2, "Cannot purchase this many tokens for this stage");
      require(isRaffleActive2 && _count + supply < raffleBreakPoint2, "No NFTs are left to mint for this stage");
    }

    if (isRaffleActive3) {
      require(_count <= raffleMaxMint3, "Cannot purchase this many tokens for this stage");
      require(_count + supply < raffleBreakPoint3, "No NFTs are left to mint for this stage");
    }

    if(supply + _count == raffleBreakPoint1) {
      isRaffleActive1 = false;
      raffleMintPrice = 0.175 ether;
    } else if(supply + _count == raffleBreakPoint2) {
      isRaffleActive2 = false;
      raffleMintPrice = 0.2 ether;
    } else if(supply + _count == raffleBreakPoint3) {
      isRaffleActive3 = false;
    }

    require(msg.value >= raffleMintPrice * _count, "Insuffient ETH amount sent.");
    require(!isClosedMintForever, "Mint Closed Forever");

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
    payable(OtherAddress1).transfer(balance * 5000 / 10000);
    payable(OtherAddress2).transfer(balance * 5000 / 10000);
    payable(owner()).transfer(balance * 0 / 10000);
  }
}