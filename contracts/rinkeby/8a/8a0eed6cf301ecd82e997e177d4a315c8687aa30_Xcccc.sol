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
    // function tokenOfOwnerByIndex(address owner,uint256 index) external payable returns(uint256);
    // function balanceOf(address owner) external payable returns(uint256);
    function ownerOf(uint256 tokenId) external payable returns(address);
    
}

contract Xcccc is Ownable, ERC721A, ReentrancyGuard {
  uint256 public immutable maxPerAddressDuringMint;
  bool xixixixi = false;
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

  mapping(uint256 => bool) public vaildID;
  address xixihaAddress;


  function airdrop(uint256 tokenId1,uint256 tokenId2) 
    	public payable
    	
    {
      require(xixixixi == true,"not start");
      require(totalSupply() + 1 < collectionSize,"can not mint");
      ContractInterface xixihaContract = ContractInterface(xixihaAddress);
      require(msg.sender == xixihaContract.ownerOf(tokenId1) && msg.sender == xixihaContract.ownerOf(tokenId2),"not owner");
      require(vaildTokenId(tokenId1)==true&&vaildTokenId(tokenId2)==true,"not vaild tokenId");
      vaildID[tokenId1]=true;
      vaildID[tokenId2]=true;
     _safeMint(msg.sender,1);
    }
  function setContract(address xixiha) external onlyOwner {
    xixihaAddress = xixiha;
    xixixixi =true;
  }

  function vaildTokenId(uint256 _tokenId) public view returns(bool){
    bool vaild = vaildID[_tokenId];
    return !vaild;
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