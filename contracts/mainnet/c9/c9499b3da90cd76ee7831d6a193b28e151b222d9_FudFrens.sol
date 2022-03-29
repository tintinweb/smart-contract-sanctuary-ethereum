/*

  _____    _   _   ____         _____    ____    U _____ u _   _    ____     
 |" ___|U |"|u| | |  _"\       |" ___|U |  _"\ u \| ___"|/| \ |"|  / __"| u  
U| |_  u \| |\| |/| | | |     U| |_  u \| |_) |/  |  _|" <|  \| |><\___ \/   
\|  _|/   | |_| |U| |_| |\    \|  _|/   |  _ <    | |___ U| |\  |u u___) |   
 |_|     <<\___/  |____/ u     |_|      |_| \_\   |_____| |_| \_|  |____/>>  
 )(\\,- (__) )(    |||_        )(\\,-   //   \\_  <<   >> ||   \\,-.)(  (__) 
(__)(_/     (__)  (__)_)      (__)(_/  (__)  (__)(__) (__)(_")  (_/(__)     

*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";

contract FudFrens is Ownable, ERC721A {

  uint256 public immutable maxPerAddress;
  
  uint256 public maxFree = 3;

  uint256 public maxPerTransaction = 20; 

  uint256 public mintPrice = 0.01 ether;

  bool public mintActive = false;
  
  bool public claimingActive = false;

  string private _baseTokenURI;

  uint256 public maxFreeSupply = 3000;

  uint256 public maxGenesis = 3333;

  uint256 public startTime;

  mapping(address => uint256) public outstandingFud;

  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_
  ) ERC721A("Fud Frens", "FF", maxBatchSize_, collectionSize_) {
    maxPerAddress = maxBatchSize_;
    startTime = block.timestamp;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function freeMint(uint256 quantity) external callerIsUser {
    require(mintActive, "mint is not active");
    require(totalSupply() + quantity <= maxFreeSupply, "max supply has been reached");
    require(quantity + numberMinted(msg.sender) <= maxFree, "max 3 free per wallet");
    _safeMint(msg.sender, quantity);
  }

  function mint(uint256 quantity) external payable callerIsUser {
    require(mintActive, "mint is not active");
    require(totalSupply() + quantity <= maxGenesis, "max supply has been reached");
    require( quantity <= maxPerTransaction, "max 20 per address");
    require(msg.value >= mintPrice * quantity, "not enough eth sent");
    _safeMint(msg.sender, quantity);
  }

  function devMint(uint256 quantity) external onlyOwner {
    require(quantity % maxBatchSize == 0,"can only mint a multiple of the maxBatchSize");
    require(totalSupply() + quantity <= maxGenesis, "max supply has been reached");
    uint256 numChunks = quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawMoney() external onlyOwner {
    require(address(this).balance > 0);
    payable(msg.sender).transfer(address(this).balance);
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner {
    _setOwnersExplicit(quantity);
  }

  function setPrice(uint256 _price) external onlyOwner {
    mintPrice = _price;
  }

  function toggleMintActive() external onlyOwner {
    mintActive = !mintActive;
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