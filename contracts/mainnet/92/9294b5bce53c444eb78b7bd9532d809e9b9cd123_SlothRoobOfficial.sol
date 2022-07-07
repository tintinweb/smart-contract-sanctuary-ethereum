// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract SlothRoobOfficial is ERC721A, Ownable {
  
  uint256 public mintPrice = 0.03 ether;
  uint256 public presalePrice = 0.02 ether;

  uint256 private reserveAtATime = 100;
  uint256 private reservedCount = 0;
  uint256 private maxReserveCount = 100;

  bytes32 public merkleRoot;
                              
  string _baseTokenURI;

  bool public isActive = false;
  bool public isPresaleActive = false;

  uint256 public MAX_SUPPLY = 5353;
  uint256 public maximumAllowedTokensPerPurchase = 5;
  uint256 public maximumAllowedTokensPerWallet = 10;
  uint256 public presaleMaximumTokensPerWallet = 5;

  constructor(string memory baseURI) ERC721A("Sloth Roob Official", "SRO") {
    setBaseURI(baseURI);
  }

  modifier saleIsOpen {
    require(totalSupply() <= MAX_SUPPLY, "Sale has ended.");
    _;
  }

  modifier onlyAuthorized() {
    require(owner() == msg.sender);
    _;
  }

  modifier isValidMerkleProof(bytes32[] calldata merkleProof) {
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
      _;
  }

  function setMerkleRootHash(bytes32 _rootHash) public onlyAuthorized {
    merkleRoot = _rootHash;
  }

  function setMaximumAllowedTokens(uint256 _count) public onlyAuthorized {
    maximumAllowedTokensPerPurchase = _count;
  }

  function setMaximumAllowedTokensPerWallet(uint256 _count) public onlyAuthorized {
    maximumAllowedTokensPerWallet = _count;
  }

  function setPresaleMaximumTokensPerWallet(uint256 maxMint) external  onlyAuthorized {
    presaleMaximumTokensPerWallet = maxMint;
  }

  function setMaxMintSupply(uint256 maxMintSupply) external  onlyAuthorized {
    MAX_SUPPLY = maxMintSupply;
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

  function toggleSaleStatus() public onlyAuthorized {
    isActive = !isActive;
  }

  function togglePresaleStatus() external onlyAuthorized {
    isPresaleActive = !isPresaleActive;
  }

  function setBaseURI(string memory baseURI) public onlyAuthorized {
    _baseTokenURI = baseURI;
  }


  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function reserveNft() public onlyAuthorized {
    require(reservedCount <= maxReserveCount, "Max Reserves taken already!");

    _safeMint(msg.sender, reserveAtATime);
    reservedCount += reserveAtATime;
    
  }

  function batchAirdrop(uint256 _count, address[] calldata addresses) external onlyAuthorized {
    uint256 supply = totalSupply();

    require(supply + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require(supply <= MAX_SUPPLY, "Total supply spent.");

    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add a null address");

      _safeMint(addresses[i], _count);

    }
  }

  function airdrop(uint256 _count, address _address) external onlyAuthorized {
    uint256 supply = totalSupply();

    require(supply + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require(supply <= MAX_SUPPLY, "Total supply spent.");

    _safeMint(_address, _count);
  }

  function mint(uint256 _count) public payable saleIsOpen {
    uint256 mintIndex = totalSupply();

    require(isActive, "Sale is not active currently.");
    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require(balanceOf(msg.sender) + _count <= maximumAllowedTokensPerWallet, "Max holding cap reached.");
    require( _count <= maximumAllowedTokensPerPurchase, "Exceeds maximum allowed tokens");
    require(msg.value >= mintPrice * _count, "Insufficient ETH amount sent.");

    _safeMint(msg.sender, _count);
    
  }

  function preSaleMint(bytes32[] calldata _merkleProof, uint256 _count) public payable isValidMerkleProof(_merkleProof) saleIsOpen {
    uint256 mintIndex = totalSupply();

    require(isPresaleActive, "Presale is not active");
    require(mintIndex < MAX_SUPPLY, "All tokens have been minted");
    require(balanceOf(msg.sender) + _count <= presaleMaximumTokensPerWallet, "Cannot purchase this many tokens");
    require(msg.value >= presalePrice * _count, "Insuffient ETH amount sent.");

    _safeMint(msg.sender, _count);
  }

  function withdraw() external onlyAuthorized {
    uint balance = address(this).balance;
    payable(owner()).transfer(balance);
  }
}