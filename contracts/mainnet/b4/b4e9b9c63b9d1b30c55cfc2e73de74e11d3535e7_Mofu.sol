// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract Mofu is ERC721, ERC721Enumerable, Ownable {

    using Strings for uint256;

    string public PROVENANCE;
    string private _baseURIextended;
    
    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public constant PRICE_PER_TOKEN = 0.08 ether;
    uint256 public constant MAX_PUBLIC_MINT = 10;

    bool public saleIsActive = false;
    bool public preSaleActive = false;

    mapping(address => uint8) private _preSaleList;

    constructor() ERC721("MOFU MOFU GIRLS", "MFMF") {}

    function setPreSaleList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _preSaleList[addresses[i]] = numAllowedToMint;
        }
    }

    function numAvailablePreSale(address addr) external view returns (uint8) {
        return _preSaleList[addr];
    }

    function mintPreSaleList(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(preSaleActive, "PreSale  is not active");
        require(numberOfTokens <= _preSaleList[msg.sender], "Exceeded max available to purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");
        
        _preSaleList[msg.sender] -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }
  
    function mint(uint numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function toggleSale() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function togglePresale() external onlyOwner {
        preSaleActive = !preSaleActive;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function reserve(uint256 n) public onlyOwner {
      uint supply = totalSupply();
      uint i;
      for (i = 0; i < n; i++) {
          _safeMint(msg.sender, supply + i);
      }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}