// SPDX-License-Identifier: Unlicensed

import './ReentrancyGuard.sol';
import './Ownable.sol';
import './Arrays.sol';
import './Strings.sol';
import './ERC721AQueryable.sol';
import './ERC721A.sol';
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";
import './OperatorFilterer.sol';


pragma solidity >=0.8.13 <0.9.0;

contract X is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {

  using Strings for uint256;
  string public uri;
  uint256 public cost = 0.0042 ether;
  uint256 public supplyLimit = 16027;
  bool public sale = false;

 
  constructor(
  ) ERC721A("X's - DD Edition", "XDE")  {
  }

  function Mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(sale, 'The sale is not active yet!');
    require(supply + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _safeMint(_msgSender(), _mintAmount);
  }  

  //Burn Function revealed in new collection tokens will be sent to 0x000000000000000000000000000000000000dEaD
  
  function setUri(string memory _uri) public onlyOwner {
    uri = _uri;
  }

  function setSaleStatus(bool _sale) public onlyOwner {
    sale = _sale;
  }
  
  function withdraw() public onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "WITHDRAW FAILED.");
    
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
    return currentBaseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }
  
  //DefaultOperator

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public payable
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}