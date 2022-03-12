// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";

 abstract contract MintingPass {
    function balanceOf(address owner, uint256 id) public view virtual returns (uint256 balance);
}

contract MurtiChor is Ownable, ERC721A, ReentrancyGuard {
 
  using SafeMath for uint256;

  MintingPass mintpass;

  using ECDSA for bytes32;

  string private _baseTokenURI;

  uint256 public presalePrice = 0.07 ether;
  uint256 public publicSalePrice = 0.08 ether;

  uint256 public presaleStartDate;
  uint256 public whitelistStartDate;
  uint256 public publicSaleDate;
  uint256 count;
  uint256 public maxPerTx;

  constructor( uint256 _maxPerTx, uint256 collectionSize_,address _address,string memory uri,uint256 _presaleStartDate,uint256 _whitelistStartDate,uint256 _publicSaleDate)
   ERC721A("MurtiChor", "MurtiChor",collectionSize_) {
      mintpass = MintingPass(_address);
      maxPerTx=_maxPerTx;
      _baseTokenURI=uri;
      presaleStartDate=_presaleStartDate;
      whitelistStartDate=_whitelistStartDate;
      publicSaleDate=_publicSaleDate;
  }

  function devMint(uint256 quantity,address _mintAddress) external onlyOwner {
    require(quantity>0 && quantity <= getMaxTx() , "Quantity greater than max mint allowed");
    _safeMint(_mintAddress, quantity);
  }

  function setPrice(uint256 _price) external onlyOwner {
    publicSalePrice = _price;
  }

  function getMaxPerTransaction(uint _id) public view returns (uint256) {
    if(block.timestamp > presaleStartDate && block.timestamp<whitelistStartDate)
    {
        if(_id==1)
        {
             return 100;
        }else if(_id==2)
        {
            return 25;
        }else{
            return 10;
        }
    }else{
        return maxPerTx;
    }
}

function getPhase() public view returns (uint256)
{
   if(block.timestamp<presaleStartDate)
  {
    return 0;
  }else if(block.timestamp>presaleStartDate && block.timestamp<whitelistStartDate)
  {
    return 1;
  }else if(block.timestamp>whitelistStartDate && block.timestamp<publicSaleDate)
  {
    return 2;
  }else{
    return 3;
  }
}

function presaleMint(uint256 quantity,uint256 passId) external payable
{
  require(getPhase()==1,"Presale closed");
  require(quantity>0 && quantity <= getMaxPerTransaction(passId) , "Quantity greater than max mint allowed");
  require(tx.origin == msg.sender, "The caller is another contract");
  address minter=msg.sender;
  uint256 tokenBalance=mintpass.balanceOf(minter, passId);
  require(passId > 0 && tokenBalance>0,"Missing mint pass");
  if(passId==1)
  {
    require(balanceOf(minter) <= 100,"You have already minted 100 elfs");
  }else if(passId==2)
  {
    require(balanceOf(minter) <= 25,"You have already minted 25 elfs");
  }else{
    require(balanceOf(minter) <= 10,"You have already minted 10 elfs");
  }
   _safeMint(msg.sender, quantity);
}

function verifySignature(bytes memory _signature) public view returns (bool)
{
  bytes32 messagehash = keccak256(abi.encodePacked(address(this), msg.sender));
  address signer = messagehash.toEthSignedMessageHash().recover( _signature);
  if (owner() == signer) {
      return true;
  } else {
    return false;
  }
}

function whitelistMint(uint256 quantity,bytes memory _signature) external payable
{
  require(getPhase()==2,"Whitelist phase closed");
  require(verifySignature(_signature),"Invalid address");
  require(quantity>0 && quantity <= 3, "Quantity greater than max mint allowed");
  require(msg.value == publicSalePrice.mul(quantity), "Invalid value");
  require(tx.origin == msg.sender, "The caller is another contract");
  require(balanceOf(msg.sender)<3,"Whitelist address can only contain upto 3 ELF's");
   _safeMint(msg.sender, quantity);
}

function mint(uint256 quantity) external payable {
  require(getPhase()==3,"Public sale closed");
  require(quantity>0 && quantity <= getMaxTx() , "Quantity greater than max mint allowed");
  require(tx.origin == msg.sender, "The caller is another contract");
  require(msg.value == publicSalePrice.mul(quantity), "Invalid value");
  _safeMint(msg.sender, quantity);
}

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function getMaxTx() internal view virtual override returns (uint256)
  {
      return maxPerTx;
  }

  function setMaxTx(uint256 _maxTx) public onlyOwner
  {
    maxPerTx=_maxTx;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawFund() external onlyOwner {
   payable(msg.sender).transfer(address(this).balance);
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