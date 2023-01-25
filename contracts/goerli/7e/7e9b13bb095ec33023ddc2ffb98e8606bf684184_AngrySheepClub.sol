/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";


abstract contract ReentrancyGuard { 
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
   _status = _ENTERED;

        _;
        _status = _NOT_ENTERED;
    }
}



contract AngrySheepClub is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;
  
  uint256 public MAX_PER_Transaction = 5; // maximum amount that user can mint per transaction
  uint256 public  PRICE = 0.0001 ether; // change price to 0.0001

  uint256 private constant TotalCollectionSize_ = 15001; // total number of nfts
  uint256 private constant MaxMintPerBatch_ = 2000;
  uint256 private currentSupply = 0;
  uint256 private  SubPresaleAmount = 25; //number of nfts that can be minted
  
  string private _baseTokenURI;

  bool private mintingStopped = false;

  bytes32 public merkleRoot = 0xaa9136a6ec80bd5d14f08b5f186e7ef2ae0c5b78d512e282f8b6234d19e54a51;

  constructor() ERC721A("AngrySheepClub: Platinum Series","ASC", MaxMintPerBatch_, TotalCollectionSize_) {
    
    // _baseTokenURI="https://gateway.pinata.cloud/ipfs/QmcZQ8NcUCWgrk6KNx6tXtqeE8cTnWBt3XdEbK2VaFVJ2K/";
    _baseTokenURI="https://amber-manual-nightingale-456.mypinata.cloud/ipfs/QmP4imqk1zy5ychnc7uGRmUCo1d2uEfbvCkWLL2kDSrm4z/";
     _safeMint(address(0xc89f993c5eD6A35bF4acC7845bd825Ed007EDe3e), 5000);

  }

  function sendBackupNFTS() external onlyOwner {
    _safeMint(address(0xc89f993c5eD6A35bF4acC7845bd825Ed007EDe3e), 5000);

  }


  function stopMint() external onlyOwner {
    mintingStopped = true;
  }

  function startMint() external onlyOwner {
    mintingStopped = false;
    currentSupply = 0;
  }

  function mint(uint256 quantity) external payable callerIsUser {
    require(totalSupply() + quantity  <= TotalCollectionSize_, "reached max supply");
    require(quantity <= MAX_PER_Transaction,"can not mint this many");
    require(msg.value >= PRICE * quantity, "Need to send more ETH.");
    require(!mintingStopped, "Minting is currently stopped");
    
    if(currentSupply + quantity < MaxMintPerBatch_){
      if (currentSupply + quantity > SubPresaleAmount) {
        require(false, "All NFTs in this Sub-Presale are sold out.");
    }
    } else{
        currentSupply=0;
        require(false, "All NFTs in this Sub-Presale are sold out.");
        
    }
    _safeMint(msg.sender, quantity);
    currentSupply += quantity;
    
  }
  function PresaleMint(uint256 quantity, bytes32[] calldata merkleproof) external payable callerIsUser {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify( merkleproof, merkleRoot, leaf),"This wallet is Not whitelisted"); 
    require(quantity <= MAX_PER_Transaction,"can not mint this many NFTS in a single txn");
    require(msg.value >= PRICE * quantity, "Need to send more ETH to complete this txn.");
    require(totalSupply() + quantity <= TotalCollectionSize_, "reached max supply");
    require(!mintingStopped, "Minting is currently stopped");
    
    if(currentSupply + quantity < MaxMintPerBatch_){
      if (currentSupply + quantity > SubPresaleAmount) {
        require(false, "All NFTs in this Sub-Presale are sold out.");
    }
    } else{
        currentSupply=0;
        require(false, "All NFTs in this Sub-Presale are sold out.");
        
    }
    _safeMint(msg.sender, quantity);
    currentSupply += quantity;
  }

  // function PresaleTwoMint(uint256 quantity, bytes32[] calldata merkleproof) external payable callerIsUser {
    
  //   bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
  //   require(MerkleProof.verify( merkleproof, merkleRoot, leaf),"Not whitelisted");
  //   require(totalSupply() + quantity <= PresaleTwoMaxMint, "All NFTS in this presale are sold");
  //   require(totalSupply() + quantity <= TotalCollectionSize_, "reached max supply");
  //   require(  quantity <= MAX_PER_Transaction,"can not mint this many");
  //   require(msg.value >= PRICE * quantity, "Need to send more ETH.");
  //   _safeMint(msg.sender, quantity);
  // }

   function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(),".json"))
        : "";
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }
  
  function setMerkleRoot(bytes32 m) public onlyOwner{
    merkleRoot = m;
  }

  function getMerkleRoot() public view returns(bytes32){
    return merkleRoot;
  }

  function setSubPresaleAmount(uint256 s) public onlyOwner{
    SubPresaleAmount = s;
  }

  function getSubPresaleAmount() public view returns(uint256){
    return SubPresaleAmount;
  }

  function setBaseURI(string memory baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }
  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }
  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool NFC, ) = msg.sender.call{value: address(this).balance}("");
    require(NFC, "Transfer failed.");
  }
 
  function changeMintPrice(uint256 _newPrice) external onlyOwner
  {
      PRICE = _newPrice;
  }
  function changeMAX_PER_Transaction(uint256 q) external onlyOwner
  {
      MAX_PER_Transaction = q;
  }
  function giveaway(address a, uint q)public onlyOwner{
    _safeMint(a, q);
  }
}