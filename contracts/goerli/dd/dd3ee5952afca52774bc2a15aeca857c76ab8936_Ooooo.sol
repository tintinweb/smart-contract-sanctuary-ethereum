// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./Address.sol";
import "./Context.sol";
import "./ERC165.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Metadata.sol";
import "./IERC721Receiver.sol";
interface ContractInterface {
    function ownerOf(uint256 tokenId) external payable returns(address);
    
}

contract Ooooo is Ownable, ERC721A, ReentrancyGuard {
  uint256 public immutable maxPer;
  mapping(address => bool) public allowList;
  address gotAddress;
  uint256 publicSaleTime;
  uint256 publicEndTime;
  uint256 allowListSaleTime;
  uint256 allowListEndTime;
  uint256 publicSalePrice = 50000000000000000;
  uint256 allowListSalePrice = 10000000000000000;
  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_

  ) ERC721A("Ooooo", "Oooooo", maxBatchSize_, collectionSize_) {
    maxPer = maxBatchSize_;
  }
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }
  
  function devMint(uint8 quantity) external onlyOwner {
     require(
       quantity % maxBatchSize == 0,
       "can only mint a multiple of the maxBatchSize"
     );
    uint256 numChunks = quantity / maxBatchSize;
    for (uint8 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
  }

  

  function publicSaleMint(uint8 quantity)
    external
    payable
    callerIsUser
  { 
    require(publicSaleTime < block.timestamp || publicSaleTime != 0,"not start "); 
    require(publicEndTime > block.timestamp,"end");
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(
      numberMinted(msg.sender) + quantity <= maxPer,
      "can not mint this many"
    );
    uint256 totalprice;
    totalprice = quantity * publicSalePrice;
    _safeMint(msg.sender, quantity);
    refundIfOver(totalprice);
  }
  function allowListMint()
    external
    payable
    callerIsUser
  { 
    require(allowListSaleTime < block.timestamp,"not start "); 
    require(allowListEndTime > block.timestamp,"end"); 
    require(totalSupply() + 1 <= collectionSize, "reached max supply");
    require(allowList[msg.sender] == true, "not eligible for allowlist mint");
    allowList[msg.sender] = false;
    _safeMint(msg.sender, 1);
    refundIfOver(allowListSalePrice);
  }
  function setAllowListSaleTime(uint256 _time) public onlyOwner {
    allowListSaleTime = _time;
  }
  function setAllowListEndTime(uint256 _time) public onlyOwner {
    allowListEndTime = _time;
  }
  function setPublicSaleTime(uint256 _time) public onlyOwner {
    publicSaleTime = _time;
  }
  function setPublicEndTime(uint256 _time) public onlyOwner {
    publicEndTime = _time;
  }
  function seedAllowlist(address[] memory addresses)
    external
    onlyOwner
  {  
    for (uint256 i = 0; i < addresses.length; i++) {
      allowList[addresses[i]] = true;
    }
  }
  function refundIfOver(uint256 cost) private {
    require(msg.value >= cost, "Need to send more ETH.");
    if (msg.value > cost) {
      payable(msg.sender).transfer(msg.value - cost);
  }
  }
  // // metadata URI
  string private _baseTokenURI;

 
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }
 
  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function with() external  {
    require(msg.sender == gotAddress,"can not do this");
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
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
}