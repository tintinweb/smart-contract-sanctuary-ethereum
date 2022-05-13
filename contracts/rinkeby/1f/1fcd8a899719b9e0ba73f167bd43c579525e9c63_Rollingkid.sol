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
contract Rollingkid is Ownable, ERC721A, ReentrancyGuard {
  uint256 public immutable maxPerAddressDuringMint;
  
  uint256 public  allowListStartTime;
  uint256 public  allowListOvertTime;
  uint256 public  publicStartTime;
  
  

  mapping(address => allowlistdata) public allowlist;
  struct allowlistdata{
    uint256 allowNumber;
    uint256 publicNumber ;
  }

  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_
  ) ERC721A("Rolling kid (Offical)", "Rolling Kid", maxBatchSize_, collectionSize_) {
    maxPerAddressDuringMint = maxBatchSize_;
  
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }



  function allowlistMint() external payable callerIsUser {
    
    require(allowlist[msg.sender].allowNumber > 0, "not eligible for allowlist mint");
    require(totalSupply() + 1 <= collectionSize, "reached max supply");
    require(allowListStartTime <= block.timestamp && allowListStartTime!=0,"sale has not started yet");
    require(allowListOvertTime > block.timestamp,"allowlist mint is over");
    
    allowlist[msg.sender].allowNumber--;
    _safeMint(msg.sender, 1);
   
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
    require(
      publicStartTime <= block.timestamp && publicStartTime!=0,
      "public mint is over"
    );
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    if(numberMinted(msg.sender) + quantity > maxPerAddressDuringMint){
        require(allowlist[msg.sender].publicNumber - quantity >= 0,"can not mint this many");
        allowlist[msg.sender].publicNumber=allowlist[msg.sender].publicNumber - quantity;
        _safeMint(msg.sender,quantity);
      
    }else{
      _safeMint(msg.sender,quantity);
    }
    
  }
 
  function setAllowListStartTime(
    uint32 startTime_
  ) external onlyOwner {
    allowListStartTime =  startTime_;
  }
  function setAllowListOvertTime(
    uint32 overTime_
  ) external onlyOwner {
    allowListOvertTime =  overTime_;
  }
  
  function setPublicStartTime(
    uint32 startTime_
  ) external onlyOwner {
    publicStartTime =  startTime_;
  }

 
  function seedAllowlist(address[] memory addresses, uint256[] memory numSlots)
    external
    onlyOwner
  {
    require(
      addresses.length == numSlots.length,
      "addresses does not match numSlots length"
    );
    for (uint256 i = 0; i < addresses.length; i++) {
      allowlist[addresses[i]].allowNumber = numSlots[i];
      allowlist[addresses[i]].publicNumber = 5;
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

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
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