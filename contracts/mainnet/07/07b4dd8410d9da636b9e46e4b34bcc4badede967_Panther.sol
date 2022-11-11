// SPDX-License-Identifier: Unlicensed

import './ReentrancyGuard.sol';
import './Ownable.sol';
import './Arrays.sol';
import './Strings.sol';
import './ERC721AQueryable.sol';
import './ERC721A.sol';


pragma solidity >=0.8.13 <0.9.0;

contract Panther is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;
  string public uri;
  string public uriSuffix = ".json";
  uint256 public cost = 0.0035 ether;
  uint256 public supplyLimit = 10000;
  uint256 public maxMintAmountPerTx = 10;
  bool public sale = false;
  address private constant dev = 0xeb9450e1FF848402f1eEfC00dBf2BCD51789Ba26;

 

  constructor(
  ) ERC721A("0xPanthers", "OXP")  {
  }

  
  function Mint(uint256 _mintAmount) public payable {

    uint256 supply = totalSupply();
    require(sale, 'The sale is not active yet!');
    require(supply + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');

    if(balanceOf(msg.sender)>0){
      require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    } else {
      require(msg.value >= (cost * _mintAmount) - cost, 'Insufficient funds, One is Free!');
    }

    _safeMint(_msgSender(), _mintAmount);
    
  }  

  function setUri(string memory _uri) public onlyOwner {
    uri = _uri;
  }

  function setSaleStatus(bool _sale) public onlyOwner {
    sale = _sale;
  }
  
  function withdraw() public onlyOwner nonReentrant {
    uint balance = address(this).balance;
    payable(dev).transfer(balance / 100 * 10);
    payable(msg.sender).transfer(balance / 100 * 90);
    
  }

 
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


}