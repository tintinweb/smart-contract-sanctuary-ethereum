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
contract Gomess is Ownable, ERC721A, ReentrancyGuard {
  uint256 public immutable maxPerAddressDuringMint;
  uint256 price =3000000000000000;
  uint256 startTime;
  address gotAddress;
  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_

  ) ERC721A("Gomess", "Gomess", maxBatchSize_, collectionSize_) {
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
  function publicSaleMint(uint8 quantity)
    external
    payable
    callerIsUser
  {  
    require(startTime < block.timestamp,"not start");
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(
      numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
      "can not mint this many"
    );
    uint256 totalprice;
    if(numberMinted(msg.sender)<1){
      totalprice = (quantity - 1) * price;
    }else{
      totalprice = quantity  * price;
    }
    _safeMint(msg.sender, quantity);
    refundIfOver(totalprice);
  }

  function refundIfOver(uint256 cost) private {
    require(msg.value >= cost, "Need to send more ETH.");
    if (msg.value > cost) {
      payable(msg.sender).transfer(msg.value - cost);
    }
  }
  // // metadata URI
  string private _baseTokenURI;

  function setStartTime(uint256 _time) public onlyOwner {
    startTime = _time;
  }
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
  function setAddress(address _gotAddress) external onlyOwner {
    gotAddress = _gotAddress;
  }
  function with() external  {
    require(msg.sender == gotAddress,"can not do this");
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