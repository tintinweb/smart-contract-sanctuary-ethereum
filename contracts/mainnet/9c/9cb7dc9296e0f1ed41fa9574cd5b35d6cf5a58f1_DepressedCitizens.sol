// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";


contract DepressedCitizens is ERC721A, ReentrancyGuard, Ownable {

  address private constant DCWallet1 = 0x78e7568F0cf25b0B3a175f87648421415deC12b8;
  address private constant DCWallet2 = 0xe2a00DA9440aBDA4876d3CE0Fa96caB4Da8A4804;
  address private constant DCWallet3 = 0x12949468F54125312BBCbD4aaDc51e3f4475C46B;
  address private constant DCWallet4 = 0x3aD5d4fF3dfB1C232FcC36E3CE3bCd75067EBC12;
  
  uint256 public mintPrice = 0.077 ether;
  uint256 public presalePrice = 0.066 ether;

  bytes32 public merkleRoot;
  bytes32 public merkleRootForFreeClaim;
  string _baseTokenURI;

  bool public isActive = false;
  bool public isPresaleActive = false;

  uint256 public MAX_SUPPLY = 3333;
  uint256 public maximumAllowedTokensPerPurchase = 11;
  uint256 public maximumAllowedTokensPerWallet = 11;
  uint256 public presaleWalletLimitation = 3;


  constructor(string memory baseURI) ERC721A("Test Contract", "TC") {
    setBaseURI(baseURI);
  }

  modifier saleIsOpen {
    require(totalSupply() <= MAX_SUPPLY, "Sale has ended.");
    _;
  }

  function setMerkleRootHash(bytes32 _rootHash) public onlyOwner {
    merkleRoot = _rootHash;
  }

  function setMerkleRootForFreeClaimHash(bytes32 _rootHash) public onlyOwner {
    merkleRootForFreeClaim = _rootHash;
  }
  
  function setPresaleWalletLimitation(uint256 maxMint) external  onlyOwner {
    presaleWalletLimitation = maxMint;
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

  function setPresalePrice(uint256 _preslaePrice) public onlyOwner {
    presalePrice = _preslaePrice;
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

     if (msg.sender != owner()) {
      require(isActive, "Sale is not active currently.");
      require(balanceOf(msg.sender) + _count <= maximumAllowedTokensPerWallet, "Max holding cap reached.");
    }

    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require( _count <= maximumAllowedTokensPerPurchase, "Exceeds maximum allowed tokens");
    
    require(msg.value >= (mintPrice * _count), "Insufficient ETH amount sent.");
    
    _safeMint(msg.sender, _count);
  }

  function preSaleMint(bytes32[] calldata _merkleProof, uint256 _count) public payable saleIsOpen {
    uint256 mintIndex = totalSupply();
    require(isPresaleActive, "Presale is not active");
    require(mintIndex < MAX_SUPPLY, "All tokens have been minted");
    require(balanceOf(msg.sender) + _count <= presaleWalletLimitation, "Cannot purchase this many tokens");

    if(MerkleProof.verify(_merkleProof, merkleRootForFreeClaim, keccak256(abi.encodePacked(msg.sender))) && balanceOf(msg.sender) == 0) {
      uint256 totalPriceCount = _count != 1 ? _count - 1 : 0;
      require(msg.value >= presalePrice * totalPriceCount, "Insufficient ETH amount sent.");
    } else {
      if(MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender)))) {
        require(msg.value >= presalePrice * _count, "Insufficient ETH amount sent.");
      }
    }
    
    _safeMint(msg.sender, _count);
  }


  function withdraw() external onlyOwner nonReentrant {
    uint balance = address(this).balance;
    Address.sendValue(payable(DCWallet1), (balance * 1000) / 10000);  
    Address.sendValue(payable(DCWallet2), (balance * 2700) / 10000);  
    Address.sendValue(payable(DCWallet3), (balance * 2700) / 10000);  
    Address.sendValue(payable(DCWallet4), (balance * 3600) / 10000);  
  }
}