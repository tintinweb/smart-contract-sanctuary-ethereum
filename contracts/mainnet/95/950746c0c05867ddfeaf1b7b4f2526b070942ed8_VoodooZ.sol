// SPDX-License-Identifier: Unlicensed

import './ReentrancyGuard.sol';
import './Ownable.sol';
import './Arrays.sol';
import './Strings.sol';
import './ERC721AQueryable.sol';
import './ERC721A.sol';


pragma solidity >=0.8.13 <0.9.0;

contract VoodooZ is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;
  string public uri;
  string public uriSuffix = ".json";
  uint256 public supplyLimit = 6666;
  uint256 public maxLimitPerWallet = 10;
  string public hiddenMetadata;
  bool public revealed = false;
  bool public saleIsActive = false;
  
  
  constructor(
  ) ERC721A("VoodooZ", "VDZ")  {
  }

  function Mint(uint256 _mintAmount) public payable {
    require(saleIsActive,'Mint is not live!');
    uint256 supply = totalSupply();
    require(balanceOf(msg.sender) + _mintAmount <= maxLimitPerWallet, 'Max mint per wallet exceeded!');
    require(supply + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    _safeMint(_msgSender(), _mintAmount); 
  }
  
  function TeamMint(uint256 _mintAmount) public onlyOwner {
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    _safeMint(_msgSender(), _mintAmount); 
  }
  

  function setUri(string memory _uri) public onlyOwner {
    uri = _uri;
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
    if (revealed == false) {
            return hiddenMetadata;
        }
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }
  
  function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }
    
   function setSaleActive(bool _state) public onlyOwner {
        saleIsActive = _state;
    }
    
  function setHiddenMetadata(string memory _hiddenmetadata) public onlyOwner {
        hiddenMetadata = _hiddenmetadata;
    }

  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }

}