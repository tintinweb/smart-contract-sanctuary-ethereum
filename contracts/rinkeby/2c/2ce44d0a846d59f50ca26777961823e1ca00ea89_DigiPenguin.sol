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

contract DigiPenguin is Ownable, ERC721A, ReentrancyGuard {
  uint256 public immutable maxPer;
  mapping(address => bool) public allowList;

  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_

  ) ERC721A("Digi Penguin", "digi", maxBatchSize_, collectionSize_) {
    maxPer = maxBatchSize_;
  }
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }
  uint256 price = 5000000000000000;
  
  function seedAllowlist(address[] memory addresses)
    external
    onlyOwner
  {  
    for (uint256 i = 0; i < addresses.length; i++) {
      allowList[addresses[i]] = true;
    }
  }

  function publicSaleMint(uint8 quantity)
    external
    payable
    callerIsUser
  {  
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(
      numberMinted(msg.sender) + quantity <= maxPer,
      "can not mint this many"
    );
    uint256 totalprice;
    if(totalSupply() + quantity <= 1000){
      _safeMint(msg.sender, quantity);
    }else{
      if(totalSupply() <= 1000){
        totalprice = (totalSupply() + quantity - 1000) * price;
        _safeMint(msg.sender, quantity);
        refundIfOver(totalprice);
      }else{
        totalprice = quantity * price;
        _safeMint(msg.sender, quantity);
        refundIfOver(totalprice);
      }
    }
  }
  function allowListMint()
    external
    payable
    callerIsUser
  {  
    require(totalSupply() + 1 <= collectionSize, "reached max supply");
    require(allowList[msg.sender] == true, "not eligible for allowlist mint");
    allowList[msg.sender] = false;
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