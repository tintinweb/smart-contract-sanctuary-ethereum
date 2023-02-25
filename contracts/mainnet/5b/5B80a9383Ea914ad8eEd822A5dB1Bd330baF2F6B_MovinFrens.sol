// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import './ERC721AQueryable.sol';
import './ERC721A.sol';
import './Ownable.sol';
import './MerkleProof.sol';
import './ReentrancyGuard.sol';
import './DefaultOperatorFilterer.sol';

contract MovinFrens is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer  {

  using Strings for uint256;

  bytes32 public merkleRoot;
  bytes32 public OGMerkelRoot;

  mapping(address => uint256) public whitelistClaimed;
  mapping(address => bool) public OGClaimed;
  mapping(address => uint256) public publicMinted;
  uint256 public maxPerUser;
  string public revealedURI = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmtPerTx;

  bool public revealed = false;

  uint256 public mintPhase;

  constructor(
    uint256 _cost,
    uint256 _MaxPerTxn,
    uint256 _MaxPerUser,
    uint256 _maxSupply,
    string memory _uri
  ) ERC721A("Movin Frens", "MF") {
    maxMintAmtPerTx = _MaxPerTxn;
    maxPerUser = _MaxPerUser;
    cost = _cost;
    maxSupply = _maxSupply;
    hiddenMetadataUri = _uri;
  }


// modifiers
  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmtPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

// Mints 

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) { 
    require(mintPhase == 2,'Whitelist Mint Phase is Not Active');
    require((maxPerUser-whitelistClaimed[msg.sender])>=_mintAmount,"You have minted maximum allowed nfts or try to mint less");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] += _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }

    function OGMint(bytes32[] calldata _merkleProof) public payable mintCompliance(1) { 
    require(mintPhase == 1,'OG Mint Phase is Not Active');
    require(!OGClaimed[msg.sender],"OG Mint Already Claimed");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, OGMerkelRoot, leaf), 'Invalid proof!');
    OGClaimed[msg.sender] = true;
    _safeMint(_msgSender(), 1);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // require(publicEnabled, 'The contract is paused!');
    require(publicMinted[msg.sender]+_mintAmount<=maxMintAmtPerTx,"You have minted maximum allowed nfts or try to mint less");
    require(mintPhase == 3,'Public Mint Phase is Not Active');
    publicMinted[msg.sender] += _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

// internal 
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

// Cost , mint per address

  function setCost(uint256 _cost) public onlyOwner {  // _cost in wei
    cost = _cost;
  }

  function setMintAmtPerTx(uint256 _amount) public onlyOwner {
    maxMintAmtPerTx = _amount;
  }

  function setMaxPerUser(uint256 _amount) public onlyOwner {
    maxPerUser = _amount;
  }

// Token Base URI

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed() public onlyOwner returns(string memory) {
    revealed = !revealed;
    return revealed?"NFTs Are Revealed":"NFTs Are Hidden";
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setBaseUri(string memory _revealedURI) public onlyOwner {
    revealedURI = _revealedURI;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return revealedURI;
  }


// set merkel roots
  function setWLRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setOGRoot(bytes32 _OGRoot) public onlyOwner {
    OGMerkelRoot = _OGRoot;
  }

// set mint phase
  function setMintPhase(uint256 _phase) public onlyOwner returns(string memory) {
    require(_phase < 4, 'Invalid phase');
    mintPhase = _phase;
    return(_phase == 1?'OG mint enabled':_phase == 2?'Whitelist mint enabled':_phase == 3?'Public mint enabled':'Mint not enabled');
  } 

// check whitelisted / OG lists
  function isValidWL(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }
  
  function isValidOG(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, OGMerkelRoot, leaf);
    }
    
  
// Withdraw Function
  function withdraw() public onlyOwner nonReentrant {
   
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  // Overriding with opensea's open registry

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}