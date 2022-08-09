// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract GiftedTigers is ERC721A, Ownable {
  
  uint256 public mintPrice = 0.085 ether;
  uint256 public presalePrice = 0.075 ether;

  uint256 private reserveAtATime = 100;
  uint256 private reservedCount = 0;
  uint256 private maxReserveCount = 100;

  bytes32 public merkleRoot;
  string _baseTokenURI;

  bool public isActive = true;
  bool public isPresaleActive = false;

  uint256 public MAX_SUPPLY = 8888;
  uint256 public maximumAllowedTokensPerPurchase = 10;
  uint256 public maximumAllowedTokensPerWallet = 20;

  constructor(string memory baseURI) ERC721A("GiftedTigers", "GT") {
    setBaseURI(baseURI);
  }

  modifier saleIsOpen {
    require(totalSupply() <= MAX_SUPPLY, "Sale has ended.");
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

  function setMerkleRootHash(bytes32 _rootHash) public onlyOwner {
    merkleRoot = _rootHash;
  }

  function setMaxReserve(uint256 val) public onlyOwner {
    maxReserveCount = val;
  }

  function setReserveAtATime(uint256 val) public onlyOwner {
    reserveAtATime = val;
  }

  function getReserveAtATime() external view returns (uint256) {
    return reserveAtATime;
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
    uint256 counter = 0;
    

     if (msg.sender != owner()) {
      require(isActive, "Sale is not active currently.");
      require(balanceOf(msg.sender) + _count <= maximumAllowedTokensPerWallet, "Max holding cap reached.");
    }

    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require( _count <= maximumAllowedTokensPerPurchase, "Exceeds maximum allowed tokens");
    
    for(uint256 i = balanceOf(msg.sender) + 1; i <= balanceOf(msg.sender) + _count; i++) {
        if(i % 5 == 0) {
          counter++;
        }
    }

    require(msg.value >= (mintPrice * (_count - counter)), "Insufficient ETH amount sent.");

    _safeMint(msg.sender, _count);
    
  }

  function preSaleMint(bytes32[] calldata _merkleProof, uint256 _count) public payable isValidMerkleProof(_merkleProof) saleIsOpen {
    uint256 mintIndex = totalSupply();
    uint256 counter = 0;

    require(isPresaleActive, "Presale is not active");
    require(mintIndex < MAX_SUPPLY, "All tokens have been minted");
    require(balanceOf(msg.sender) + _count <= maximumAllowedTokensPerWallet, "Cannot purchase this many tokens");
    
    for(uint256 i = balanceOf(msg.sender) + 1; i <= balanceOf(msg.sender) + _count; i++) {
      if(i % 4 == 0) {
        counter++;
      }
    }

    require(msg.value >= (presalePrice * (_count - counter)), "Insufficient ETH amount sent.");
    _safeMint(msg.sender, _count);

  }

  function withdraw() external onlyOwner {
    uint balance = address(this).balance;
    payable(owner()).transfer(balance);
  }
}