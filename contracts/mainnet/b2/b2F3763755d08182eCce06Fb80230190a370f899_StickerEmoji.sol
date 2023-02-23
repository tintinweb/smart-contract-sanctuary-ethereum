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
contract StickerEmoji is Ownable, ERC721A, ReentrancyGuard {
  uint256 public immutable maxPerAddressDuringMint;
  uint256 price =10000000000000000;
  mapping(address =>uint256) minted;
  mapping(address => bool) freeMint;
  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_

  ) ERC721A("StickerEmoji", "StickerEmoji", maxBatchSize_, collectionSize_) {
    maxPerAddressDuringMint = maxBatchSize_;
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
  function airdrop(address add,uint256 number) external onlyOwner {
    require(totalSupply() + number <= collectionSize, "reached max supply");
    _safeMint(add, number);
  }
  function publicSaleMint(uint256 quantity)
    external
    payable
    callerIsUser
  {  
    require(
       quantity % maxBatchSize == 0,
       "can only mint a multiple of the BatchSize"
     );
     require(minted[msg.sender] + quantity <=10,"can not mint this many");
     require(quantity <=100,"can not mint this many for once");
     
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    minted[msg.sender] = minted[msg.sender] +quantity;
    uint256 number = quantity/5;
    for(uint8 i = 0; i < number; i++){
      _safeMint(msg.sender, 5);
    }
    refundIfOver(price*number);
  }
function publicFreeMint()
    external
    payable
    callerIsUser
  {  
    require(totalSupply() + 1 <= collectionSize, "reached max supply");
    require(
      freeMint[msg.sender] == false,
      "can not freemint again"
    );
    freeMint[msg.sender] = true;
    _safeMint(msg.sender, 1);
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