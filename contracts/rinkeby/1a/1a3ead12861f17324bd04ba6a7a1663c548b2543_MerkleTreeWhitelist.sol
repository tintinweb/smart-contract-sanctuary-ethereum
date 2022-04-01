// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./MerkleProof.sol";
import "./Counters.sol";
import "./Ownable.sol";


contract MerkleTreeWhitelist is ERC721, Ownable {

  using Counters for Counters.Counter;
  Counters.Counter private _tokenSupply;
  Counters.Counter private _nextTokenId;
  
  uint256 public mintPrice = 0.09 ether;
  uint256 public presalePrice = 0.12 ether;

  uint256 private reserveAtATime = 44;
  uint256 private reservedCount = 0;
  uint256 private maxReserveCount = 88;

  bytes32 public merkleRoot = 0x5d0dc210f03e0953339c3b529f4d1f316a49982a4f0ba3b6fd52e1c50a712493;

  address public syncAddress;

  string _baseTokenURI;

  bool public isActive = false;
  bool public isPresaleActive = false;

  uint256 public MAX_SUPPLY = 4444;
  uint256 public maximumAllowedTokensPerPurchase = 20;
  uint256 public maximumAllowedTokensPerWallet = 40;
  uint256 public allowListMaxMint = 20;


  mapping(address => bool) private _allowList;
  mapping(address => uint256) private _allowListClaimed;

  // Whitelisted
  mapping(address => bool) public whitelistClaimed;

  event AssetMinted(uint256 tokenId, address sender);
  event SaleActivation(bool isActive);

  constructor(string memory baseURI) ERC721("Merkle Tree Whitelist", "MTW") {
    setBaseURI(baseURI);
    setSyncAddress(0x8e08199EefF14f4B617Dc4B0802787f3431Ca006);
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
    maximumAllowedTokensPerPurchase = _count;
  }

  function setMaximumAllowedTokensPerWallet(uint256 _count) public onlyAuthorized {
    maximumAllowedTokensPerWallet = _count;
  }

  function setActive(bool val) public onlyAuthorized {
    isActive = val;
    emit SaleActivation(val);
  }

  function setMaxMintSupply(uint256 maxMintSupply) external  onlyAuthorized {
    MAX_SUPPLY = maxMintSupply;
  }

  function setIsPresaleActive(bool _isPresaleActive) external onlyAuthorized {
    isPresaleActive = _isPresaleActive;
  }

  function setAllowListMaxMint(uint256 maxMint) external  onlyAuthorized {
    allowListMaxMint = maxMint;
  }

  function setSyncAddress(address _newSyncAddress) public onlyOwner {
    syncAddress = _newSyncAddress;
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

  function setPrice(uint256 _price) public onlyAuthorized {
    mintPrice = _price;
  }

  function setPresalePrice(uint256 _preslaePrice) public onlyAuthorized {
    presalePrice = _preslaePrice;
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

  function reserveToCustomWallet(address _walletAddress, uint256 _count) public onlyAuthorized {
    for (uint256 i = 0; i < _count; i++) {
      _tokenSupply.increment();
      _safeMint(_walletAddress, _tokenSupply.current());
    }
  }

  function airdrop(uint256 _ownedTokenID) public payable saleIsOpen {
    IERC721 token =  IERC721(syncAddress);
    address isOwner = token.ownerOf(_ownedTokenID);
    require(isOwner == msg.sender, "You are not the holder of this NFT");
    _safeMint(msg.sender, _ownedTokenID);
  }

  function preSaleMintMerkle(bytes32[] calldata _merkleProof, uint256 _count) public payable saleIsOpen {
    uint256 mintIndex = _tokenSupply.current();

    require(isPresaleActive, 'Allow List is not active');
    
    // Make sure user has not already claimed the tokens
    require(!whitelistClaimed[msg.sender], 'Address already claimed');
    
    // Generate leaf node from callee
    bytes32 leaf = keccak256(abi.encode(msg.sender));

    // Check the proof
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid Merkle Proof");

    whitelistClaimed[msg.sender] = true;
    
    require(mintIndex < MAX_SUPPLY, 'All tokens have been minted');
    require(_count <= allowListMaxMint, 'Cannot purchase this many tokens');
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