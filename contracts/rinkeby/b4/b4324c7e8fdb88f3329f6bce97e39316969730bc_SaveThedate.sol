// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import './ERC721AQueryable.sol';
import './MerkleProof.sol';
import './Ownable.sol';
import './ReentrancyGuard.sol';

contract SaveThedate is ERC721AQueryable, Ownable, ReentrancyGuard {
  using Strings for uint256;

  event DatesMinted(string[] dates, uint256 currentIndex, uint256 mintAmount);
  event RandomDatesMinted(uint256 currentIndex, uint256 mintAmount);

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;
    
  string public uriPrefix = '';
  string public uriSuffix = '.json';  
  uint256 public cost = 0.1 ether;
  uint256 public randomDateCost = 0.05 ether;

  uint256 public maxSupply = 18000;
  uint256 public maxMintAmountPerTx = 4;
  string  public tokenName = "SaveTheDate";
  string  public tokenSymbol = "STD";

  bool public paused = true;
  bool public whitelistMintEnabled = false;

  constructor(string memory baseURI
  ) ERC721A(tokenName, tokenSymbol) {
      setUriPrefix(baseURI);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  modifier mintRandomDatePriceCompliance(uint256 _mintAmount) {
    require(msg.value >= randomDateCost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, string[] memory _dates, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    mintDates(_msgSender(), _mintAmount, _dates);
  }

  function whitelistRandomMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintRandomDatePriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    mintRandomDates(_msgSender(), _mintAmount);
  }

 function internalRandomMint(uint256 _teamAmount) external onlyOwner  {
    require(totalSupply() + _teamAmount <= maxSupply, 'Max supply exceeded!');
    mintRandomDates(_msgSender(), _teamAmount);
  }

 function internalMint(uint256 _teamAmount, string[] memory _dates) external onlyOwner  {
    require(totalSupply() + _teamAmount <= maxSupply, 'Max supply exceeded!');
    mintDates(_msgSender(), _teamAmount, _dates);
  }

  function mint(uint256 _mintAmount, string[] memory _dates) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    mintDates(_msgSender(), _mintAmount, _dates);
  }

  function randomDateMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintRandomDatePriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    mintRandomDates(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, string[] memory _dates, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    mintDates(_receiver, _mintAmount, _dates);
  }

  function mintDates(address to, uint256 _mintAmount, string[] memory _dates) internal {
    uint256 currentIndex = _currentIndex;
    _safeMint(to, _mintAmount);
    emit DatesMinted(_dates, currentIndex, _mintAmount);
  }

  function mintRandomDates(address to, uint256 _mintAmount) internal {
    uint256 currentIndex = _currentIndex;
    _safeMint(to, _mintAmount);
    emit RandomDatesMinted(currentIndex, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}