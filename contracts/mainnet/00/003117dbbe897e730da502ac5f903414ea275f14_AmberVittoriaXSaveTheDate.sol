// SPDX-License-Identifier: MIT
/***
 *  
 *  8""""8                      
 *  8      eeeee ee   e eeee    
 *  8eeeee 8   8 88   8 8       
 *      88 8eee8 88  e8 8eee    
 *  e   88 88  8  8  8  88      
 *  8eee88 88  8  8ee8  88ee    
 *  ""8""                       
 *    8   e   e eeee            
 *    8e  8   8 8               
 *    88  8eee8 8eee            
 *    88  88  8 88              
 *    88  88  8 88ee            
 *  8""""8                      
 *  8    8 eeeee eeeee eeee     
 *  8e   8 8   8   8   8        
 *  88   8 8eee8   8e  8eee     
 *  88   8 88  8   88  88       
 *  88eee8 88  8   88  88ee     
 *  
 */
pragma solidity >=0.8.9 <0.9.0;

import './ERC721AQueryable.sol';
import './MerkleProof.sol';
import './Ownable.sol';
import './ReentrancyGuard.sol';
import './RefundContract.sol';
import './ERC2981.sol';

contract AmberVittoriaXSaveTheDate is ERC721AQueryable, Ownable, ReentrancyGuard, ERC2981 {
  using Strings for uint256;

  event NftsMinted(address owner, uint256[] std_ids, uint256 currentIndex, uint256 mintAmount);

  mapping(uint256 => bool) public freelistClaimed;
  string public uriPrefix = '';
  uint256 public maxSupply = 18000;
  uint256 public maxMintAmountPerTx = 1;
  uint256 public cost = 0 ether;
  bytes32 public merkleRoot;

  string  public tokenName = "Amber Vittoria X Save The Date";
  string  public tokenSymbol = "AVXSTD";
  bool public paused = true;
  bool public whitelistMintEnabled = false;

  IERC721 internal saveTheDateContract;
  RefundContract internal refundContract;
  string internal uriSuffix = '.json';  

  constructor(string memory baseURI, address _saveTheDateContract, address _refundContract) ERC721A(tokenName, tokenSymbol) {
    setUriPrefix(baseURI);
    saveTheDateContract = IERC721(_saveTheDateContract);
    refundContract = RefundContract(_refundContract);
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

  function mint(uint256 std_id) public payable mintCompliance(1) mintPriceCompliance(1) {
    require(!paused, 'The contract is paused!');
    require(!freelistClaimed[std_id], 'Token already claimed!');
    address _owner = saveTheDateContract.ownerOf(std_id);
    require(_owner == msg.sender, "Must be an owner to mint");
    safeMint(_msgSender(), std_id);
    freelistClaimed[std_id] = true;
    refundContract.claimReward(std_id);
  }

  function safeMint(address to, uint256 std_id) internal {
    uint256[] memory tmp = new uint256[](1);
    tmp[0] = std_id;
    bulkSafeMint(to, tmp);
    delete tmp;
  }

  function bulkSafeMint(address to, uint256[] memory std_ids) internal {
    uint256 currentIndex = _currentIndex;
    uint256 amount = std_ids.length;
    _safeMint(to, amount);
    emit NftsMinted(to, std_ids, currentIndex, amount);
  }

 function internalMint(uint256[] memory std_ids) external onlyOwner  {
    require(totalSupply() + std_ids.length <= maxSupply, 'Max supply exceeded!');
    bulkSafeMint(_msgSender(), std_ids);
  }
   
  function mintForAddress(uint256[] memory std_ids, address _receiver) public onlyOwner {
    require(totalSupply() + std_ids.length <= maxSupply, 'Max supply exceeded!');
    bulkSafeMint(_receiver, std_ids);
  }

  function mintForAddresses(uint256[] memory std_ids, address[] memory _addresses) public onlyOwner {
    uint256[] memory tmp = new uint256[](1);
    for (uint i = 0; i < std_ids.length; i++) {
      tmp[0] = std_ids[i];
      mintForAddress(tmp, _addresses[i]);
    }
    delete tmp;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
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

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setRoyaltyInfo(address payable receiver, uint96 numerator) public onlyOwner {
    _setDefaultRoyalty(receiver, numerator);
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  } 

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
    return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }
}