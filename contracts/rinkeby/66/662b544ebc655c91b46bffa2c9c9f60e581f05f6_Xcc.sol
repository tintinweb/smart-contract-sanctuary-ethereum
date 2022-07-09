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
abstract contract XixihaContract {
    function tokenOfOwnerByIndex(address ownerAddress,uint256 index) public virtual returns(uint256);
    function ownerOf(address ownerAddress) public virtual returns(uint256);
}
contract Xcc is Ownable, ERC721A, ReentrancyGuard {
  uint256 public immutable maxPerAddressDuringMint;

  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_

  ) ERC721A("xxxxxxxa", "hhhhhhi", maxBatchSize_, collectionSize_) {
    maxPerAddressDuringMint = maxBatchSize_;
  }
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  bool[10000] ownerOfxixiha;
  address xixihaAddress;

 

  function airdrop(uint8 quantity)
    external
    payable
    callerIsUser
  {  
    uint256 vaildNumber = 0;
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    XixihaContract xixihaContract = XixihaContract(xixihaAddress);
    require(quantity<=xixihaContract.ownerOf(msg.sender),"can get this many");
    for(uint256 i = 0; i < quantity; i++){
      uint256 _tokenId = xixihaContract.tokenOfOwnerByIndex(msg.sender,i);
      require(ownerOfxixiha[_tokenId]==false,"invaild token");
      ownerOfxixiha[_tokenId] = true;
      vaildNumber++;
    }
    _safeMint(msg.sender, vaildNumber);
  }
  function setContract(address xixiha) external onlyOwner {
    xixihaAddress = xixiha;
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