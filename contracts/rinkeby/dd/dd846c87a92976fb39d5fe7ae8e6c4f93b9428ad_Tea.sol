// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./SafeMath.sol";

 abstract contract MintingPass {
    function balanceOf(address owner, uint256 id)
        public
        view
        virtual
        returns (uint256 balance);
}

contract Tea is Ownable, ERC721A, ReentrancyGuard {
 
  using SafeMath for uint256;

  MintingPass mintpass;

  bool public presaleActive = true;

  string private _baseTokenURI;

  uint256 public presalePrice = 0.07 ether;
  uint256 public publicSalePrice = 0.08 ether;

  uint256 public maxPerTx;

  constructor( uint256 _maxPerTx, uint256 collectionSize_,address _address,string memory uri)
   ERC721A("Tea", "Tea",collectionSize_) {
       mintpass = MintingPass(_address);
       maxPerTx=_maxPerTx;
       _baseTokenURI=uri;
  }

  function setPrice(uint256 _price) external onlyOwner {
    publicSalePrice = _price;
  }

  function closePresale() external onlyOwner {
    presaleActive = false;
   }

  function getMaxPerTransaction(uint _id) public view returns (uint256) {
    if(presaleActive)
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


    function mint(uint256 quantity,uint256 passId) external payable {
        require(quantity>0 && quantity <= getMaxPerTransaction(passId) , "Quantity greater than max mint allowed");
        address minter=msg.sender;
      
        if(presaleActive)
        {
          uint256 tokenId=mintpass.balanceOf(minter, passId);
          require(passId > 0 && tokenId==passId,"Missing mint pass");
          if(passId==1)
          {
            require(balanceOf(minter) <= 100,"You have already minted 100 nfts");
          }else if(passId==2)
          {
            require(balanceOf(minter) <= 25,"You have already minted 25 nfts");
          }else{
            require(balanceOf(minter) <= 10,"You have already minted 10 nfts");
          }
          require(msg.value == presalePrice.mul(quantity), "Invalid value");
        }else
        {
            require(msg.value == publicSalePrice.mul(quantity), "Invalid value");
        }
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