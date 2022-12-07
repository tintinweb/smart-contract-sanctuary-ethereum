// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./MerkelProof.sol";
import "./DefaultOperatorFilterer.sol";

contract CareNoMore is ERC721A, Ownable, DefaultOperatorFilterer {

  // MintPrice = "Free Mint"

  string _baseTokenURI;
  bytes32 public merkleRoot;

  bool public isActive = false;
  bool public isWhitelistSaleActive = false;

  uint256 public MAX_SUPPLY = 1000;
  uint256 public maximumAllowedTokensPerPurchase = 2;
  uint256 public whitelistWalletLimitation = 2;
  uint256 public publicWalletLimitation = 1;

  mapping(address => uint256) private _whitelistWalletMints;
  mapping(address => uint256) private _publicWalletMints;


  constructor(string memory baseURI) ERC721A("CARE NO MORE", "CNM") {
    setBaseURI(baseURI);
  }

  modifier saleIsOpen {
    require(totalSupply() <= MAX_SUPPLY, "Sale has ended.");
    _;
  }

  // Minting for devs to use in future giveaways and raffles and treasury

  function devMint(uint256 _count, address _address) external onlyOwner {
    uint256 supply = totalSupply();

    require(supply + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require(supply <= MAX_SUPPLY, "Total supply spent.");

    _safeMint(_address, _count);
  }

  // Free mint for whitelisted people

  function whitelistMint(bytes32[] calldata _merkleProof, uint256 _count) public payable isValidMerkleProof(_merkleProof) saleIsOpen {
    uint256 mintIndex = totalSupply();

    require(isWhitelistSaleActive, "Presale is not active");
    require(mintIndex < MAX_SUPPLY, "All tokens have been minted");
    require(balanceOf(msg.sender) + _count <= whitelistWalletLimitation, "Cannot purchase this many tokens");
    require(_whitelistWalletMints[msg.sender] + _count <= whitelistWalletLimitation, "You have already minted max");

    _whitelistWalletMints[msg.sender] += _count;

    _safeMint(msg.sender, _count);

  }

  // Free mint for public

  function mint(uint256 _count) public payable saleIsOpen {
    uint256 mintIndex = totalSupply();

    require(isActive, "Sale is not active currently.");
    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require( _count <= maximumAllowedTokensPerPurchase, "Exceeds maximum allowed tokens");
    require(_publicWalletMints[msg.sender] + _count <= publicWalletLimitation, "You have already minted or minting more than allowed.");


    _publicWalletMints[msg.sender] += _count;

    _safeMint(msg.sender, _count);
    
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
  
  function setWhitelistSaleWalletLimitation(uint256 _maxMint) external  onlyOwner {
    whitelistWalletLimitation = _maxMint;
  }

  function setPublicSaleWalletLimitation(uint256 _count) external  onlyOwner {
    publicWalletLimitation = _count;
  }

  function setMaximumAllowedTokensPerPurchase(uint256 _count) public onlyOwner {
    maximumAllowedTokensPerPurchase = _count;
  }

  function setMaxMintSupply(uint256 _maxMintSupply) external  onlyOwner {
    MAX_SUPPLY = _maxMintSupply;
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

  function withdraw() external onlyOwner {
    uint balance = address(this).balance;
    payable(owner()).transfer(balance);
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
      super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override payable onlyAllowedOperatorApproval(operator) {
      super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
      super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
      public
      payable
      override
      onlyAllowedOperator(from)
  {
      super.safeTransferFrom(from, to, tokenId, data);
  }
}