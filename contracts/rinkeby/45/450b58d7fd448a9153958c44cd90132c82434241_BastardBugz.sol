// SPDX-License-Identifier: Unlicensed

import './ReentrancyGuard.sol';
import './Ownable.sol';
import './Arrays.sol';
import './Strings.sol';
import './ERC721AQueryable.sol';
import './ERC721A.sol';


pragma solidity >=0.8.13 <0.9.0;

contract BastardBugz is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  string public uri;
  string public uriSuffix = ".json";
  uint256 public cost1 = 0 ether;
  uint256 public cost2 = 0.01 ether;
  uint256 public supplyLimit = 10;
  uint256 public maxMintAmountPerTx = 3;
  uint256 public maxLimitPerWallet = 3;
  uint256 public maxMintAmountPerTxPaid = 20;
  bool public sale = false;
 

  constructor(
  ) ERC721A("BastardBugz.Wtf", "BZZZ")  {
  }

  
  function Mint(uint256 _mintAmount) public payable {
    //Dynamic Price
    uint256 supply = totalSupply();
    require(sale, 'The Sale is paused!');
    require(supply + _mintAmount <= supplyLimit - 5, 'Max free supply exceeded!');
    require(balanceOf(msg.sender) + _mintAmount <= maxLimitPerWallet, 'Max mint per wallet exceeded!');
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(msg.value >= cost1 * _mintAmount, 'Insufficient funds!');
      
    // Mint
      _safeMint(_msgSender(), _mintAmount);
    

  }  

  function MintPaid(uint256 _mintAmount) public payable {
    //Dynamic Price
    uint256 supply = totalSupply();
    require(sale, 'The Sale is paused!');
    require(supply + _mintAmount <= supplyLimit, 'Sold out!');
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTxPaid, 'Invalid mint amount!');
    require(msg.value >= cost2 * _mintAmount, 'Insufficient funds!');
      
    // Mint
     _safeMint(_msgSender(), _mintAmount);
  }  



  function Airdrop(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    _safeMint(_receiver, _mintAmount);
  }

// ================== Mint Functions End =======================  

// ================== Set Functions Start =======================


// uri
  function seturi(string memory _uri) public onlyOwner {
    uri = _uri;
  }

// sales toggle
  function setSaleStatus(bool _sale) public onlyOwner {
    sale = _sale;
  }



// set new price
  function setNewPrice(uint256 _cost2) public onlyOwner {
    cost2 = _cost2;
  }  

// ================== Set Functions End =======================

// ================== Withdraw Function Start =======================
  
  function withdraw() public onlyOwner nonReentrant {
    //owner withdraw
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

// ================== Withdraw Function End=======================  

// ================== Read Functions Start =======================
 
function tokensOfOwner(address owner) external view returns (uint256[] memory) {
    unchecked {
        uint256[] memory a = new uint256[](balanceOf(owner)); 
        uint256 end = _nextTokenId();
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        for (uint256 i; i < end; i++) {
            TokenOwnership memory ownership = _ownershipAt(i);
            if (ownership.burned) {
                continue;
            }
            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }
            if (currOwnershipAddr == owner) {
                a[tokenIdsIdx++] = i;
            }
        }
        return a;    
    }
}

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }

// ================== Read Functions End =======================  

}